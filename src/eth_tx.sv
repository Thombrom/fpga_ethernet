`default_nettype none
import Types::e_eth_frame_section;
import Types::e_ether_type;
import Types::st_eth_packet;

module eth_tx(
    input wire eth_clk,
    input wire rst_in,
    input wire transmit,
    
    input st_eth_packet eth_packet,
    
    output logic [1:0] eth_txd,
    output logic       eth_txen);
    
    e_eth_frame_section eth_frame_section;
    logic [15:0] counter;
    logic [7:0]  data_out;
    
    logic [7:0] preamble_data;
    buffer_ra #(.BUFFER_SIZE(64), .INPUT_SIZE(8)) preamble_buffer( 
        .default_value(64'h5555_5555_5555_55d5),
        .clk_in(eth_clk),
        .rst_in(rst_in || eth_frame_section != Types::ETH_PREAMBLE),
        .trigger(eth_frame_section == Types::ETH_PREAMBLE && counter % 4 == 3),
        .data_in(preamble_data),
        .slice_out(preamble_data));
        
    logic [7:0] mac_destination_data;
    buffer_ra #(.BUFFER_SIZE(48), .INPUT_SIZE(8)) mac_destination_buffer(
        .clk_in(eth_clk),
        .default_value(eth_packet.destination_addr),
        .rst_in(rst_in || eth_frame_section != Types::ETH_MAC_DESTINATION),
        .trigger(eth_frame_section == Types::ETH_MAC_DESTINATION && counter % 4 == 3),
        .data_in(mac_destination_data),
        .slice_out(mac_destination_data));   
        
    logic [7:0] mac_source_data;
    buffer_ra #(.BUFFER_SIZE(48), .INPUT_SIZE(8)) mac_source_buffer(
        .clk_in(eth_clk),
        .default_value(eth_packet.source_addr),
        .rst_in(rst_in || eth_frame_section != Types::ETH_MAC_SOURCE),
        .trigger(eth_frame_section == Types::ETH_MAC_SOURCE && counter % 4 == 3),
        .data_in(mac_source_data),
        .slice_out(mac_source_data));   
        
    logic [7:0] ether_type_data;
    buffer_ra #(.BUFFER_SIZE(16), .INPUT_SIZE(8)) ether_type_buffer(
        .clk_in(eth_clk),
        .default_value(eth_packet.eth_type),
        .rst_in(rst_in || eth_frame_section != Types::ETH_ETHER_TYPE),
        .trigger(eth_frame_section == Types::ETH_ETHER_TYPE && counter % 4 == 3),
        .data_in(ether_type_data),
        .slice_out(ether_type_data));  
        
    // ARP Packet
    logic [7:0] payload_data;
    buffer_ra #(.BUFFER_SIZE(368), .INPUT_SIZE(8)) payload_buffer(
        .clk_in(eth_clk),
        .default_value(eth_packet.payload),
        .rst_in(rst_in || eth_frame_section != Types::ETH_PAYLOAD),
        .trigger(eth_frame_section == Types::ETH_PAYLOAD && counter % 4 == 3),
        .data_in(8'b0),
        .slice_out(payload_data)); 
    
    logic [31:0] crc;
    logic [31:0] crc_storage;
    logic [2:0]  eth_frame_section_delayed;
    eth_crc32 crc_calculator(
        .eth_clk(eth_clk),
        .rst_in(rst_in),
        .active(eth_frame_section_delayed != Types::ETH_INTERPACKET_GAP && eth_frame_section_delayed != Types::ETH_CRC && eth_frame_section_delayed != Types::ETH_PREAMBLE),
        .eth_rxd({ eth_txd[0], eth_txd[1] }),
        .crc_out(crc));
        
    queue_fifo #(.BUFFER_LENGTH(1), .INPUT_WIDTH(3)) eth_frame_queue(
        .clk_in(eth_clk),
        .rst_in(rst_in),
        .trigger(1'b1),
        .data_in(eth_frame_section),
        .data_out(eth_frame_section_delayed));
        
    always_ff @(posedge eth_clk) begin
        if (rst_in) begin
            eth_frame_section <= Types::ETH_INTERPACKET_GAP;
            counter           <= 0;
        end else if (eth_frame_section == Types::ETH_INTERPACKET_GAP && transmit && counter > 16'd47) begin
            eth_frame_section <= Types::ETH_PREAMBLE;
            counter           <= 0;
        end else if (eth_frame_section == Types::ETH_INTERPACKET_GAP) begin
            counter <= counter + 1;
        end else begin        
            case (eth_frame_section)
                Types::ETH_PREAMBLE: begin
                     data_out = preamble_data;
                     
                     if (counter == 16'd31) begin
                        eth_frame_section <= Types::ETH_MAC_DESTINATION;
                        counter           <= 0;
                     end else
                        counter       <= counter + 1;
                end
                
                Types::ETH_MAC_DESTINATION: begin
                    data_out = mac_destination_data;
                     
                     if (counter == 16'd23) begin
                        eth_frame_section <= Types::ETH_MAC_SOURCE;
                        counter           <= 0;
                     end else
                        counter <= counter + 1;
                end
                
                Types::ETH_MAC_SOURCE: begin
                    data_out = mac_source_data;
                     
                    if (counter == 16'd23) begin
                       eth_frame_section <= Types::ETH_ETHER_TYPE;
                       counter           <= 0;
                    end else
                       counter <= counter + 1;
                end
                
                Types::ETH_ETHER_TYPE: begin
                    data_out = ether_type_data;
                     
                    if (counter == 16'd7) begin
                       eth_frame_section <= Types::ETH_PAYLOAD;
                       counter           <= 0;
                    end else
                       counter <= counter + 1;
                end
                
                Types::ETH_PAYLOAD: begin
                    data_out = payload_data;
                     
                    if (counter == 16'd183) begin
                       eth_frame_section <= Types::ETH_CRC;
                       counter           <= 0;
                    end else
                       counter <= counter + 1;
                end
                
                Types::ETH_CRC: begin
                    if (counter == 0) begin
                        crc_storage       <= { 2'b0, crc[31-:30] };
                        counter <= counter + 1;
                    end else if (counter == 16'd15) begin
                        eth_frame_section <= Types::ETH_INTERPACKET_GAP;
                        counter           <= 0;
                    end else begin
                        counter <= counter + 1;
                        crc_storage       <= { 2'b0, crc_storage[31-:30] };
                    end
                end
            endcase
        end
        
        if (rst_in || eth_frame_section == Types::ETH_INTERPACKET_GAP) begin
            eth_txd <= 2'b0;
            eth_txen = 1'b0;
        end else if(eth_frame_section == Types::ETH_CRC) begin
            eth_txen = 1'b1;
            if (counter == 0)
                eth_txd <= { crc[1-:1], crc[0-:1] };
            else
                eth_txd <= { crc_storage[1-:1], crc_storage[0-:1] };
        end else begin
            eth_txen = 1'b1;
            
            case (counter % 4)
                2'b00: eth_txd = data_out[1-:2];
                2'b01: eth_txd = data_out[3-:2];
                2'b10: eth_txd = data_out[5-:2];
                2'b11: eth_txd = data_out[7-:2];
            endcase
        end        
    end
    
    ila_eth_tx ila_tx(
        .clk(eth_clk),
        .probe0(transmit),
        .probe1(eth_txd),
        .probe2(eth_txen),
        .probe3(counter),
        .probe4(eth_frame_section),
        .probe5(crc),
        .probe6(crc_storage),
        .probe7(data_out));
endmodule // eth_tx

`default_nettype wire
