`default_nettype none
import Types::e_eth_frame_section;
import Types::st_eth_header;
import Types::st_eth_packet;

module eth_rx(
    input wire           rst_in,

    input wire           eth_clk,     // 50 mhz clock
    input wire [1:0]     eth_rxd,
    input wire           eth_mdio,
    input wire           eth_crsdv,
    input wire           eth_rxerr,
    
    output logic         eth_frame_valid, // CRC validation
    output logic         eth_send_packet,
    output st_eth_packet eth_packet);  
    
    logic [15:0]         counter;
    e_eth_frame_section  eth_frame_section = Types::ETH_INTERPACKET_GAP;
    st_eth_header        eth_header;
    
    logic [7:0] byte_inverted;
    buffer_ra_instant #(.BUFFER_SIZE(8), .INPUT_SIZE(2), .REVERSE(1)) byte_inverted_buffer(
        .clk_in(eth_clk),
        .rst_in(rst_in),
        .data_in({ eth_rxd[1], eth_rxd[0] }),
        .trigger(1'b1),
        .data_out(byte_inverted));
        
    buffer_ra #(.BUFFER_SIZE(48), .INPUT_SIZE(8)) mac_destination_buffer(
        .clk_in(eth_clk),
        .rst_in(rst_in),
        .data_in(byte_inverted),
        .trigger(eth_frame_section == Types::ETH_MAC_DESTINATION && counter % 4 == 3),
        .data_out(eth_header.mac_destination));
        
    buffer_ra #(.BUFFER_SIZE(48), .INPUT_SIZE(8)) mac_source_buffer(
        .clk_in(eth_clk),
        .rst_in(rst_in),
        .data_in(byte_inverted),
        .trigger(eth_frame_section == Types::ETH_MAC_SOURCE && counter % 4 == 3),
        .data_out(eth_header.mac_source));
        
    buffer_ra #(.BUFFER_SIZE(16), .INPUT_SIZE(8)) ether_type_buffer(
        .clk_in(eth_clk),
        .rst_in(rst_in),
        .data_in(byte_inverted),
        .trigger(eth_frame_section == Types::ETH_ETHER_TYPE && counter % 4 == 3),
        .data_out(eth_header.ether_type));
    
    logic payload_finished;
    logic send_packet;    
    eth_frame_payload_handler payload_handler(
        .eth_clk(eth_clk),
        .rst_in(rst_in),
        .active(eth_frame_section == Types::ETH_PAYLOAD),
        .eth_header(eth_header),
        .data_rxd(byte_inverted),
        .data_new(counter % 4 == 3),
        .finished(payload_finished),
        .send_packet(send_packet),
        .eth_packet(eth_packet));
    assign eth_send_packet = eth_frame_valid && send_packet;

    logic [31:0] crc;
    logic [31:0] crc_storage;
    eth_crc32 crc_calculator(
        .eth_clk(eth_clk),
        .rst_in(rst_in),
        .active(eth_frame_section != Types::ETH_INTERPACKET_GAP && eth_frame_section != Types::ETH_CRC && eth_frame_section != Types::ETH_PREAMBLE),
        .eth_rxd({ eth_rxd[0], eth_rxd[1] }),
        .crc_out(crc));
        
    logic [31:0] crc_frame;
    buffer_ra_instant #(.BUFFER_SIZE(32), .INPUT_SIZE(2), .REVERSE(1)) crc_buffer(
        .clk_in(eth_clk),
        .rst_in(rst_in),
        .trigger(eth_frame_section == Types::ETH_CRC),
        .data_in(eth_rxd),
        .data_out(crc_frame));
        
    // Statemachine Logic
    always_ff @(posedge eth_clk) begin
        case (eth_frame_section)
            
            
            Types::ETH_INTERPACKET_GAP: begin
                eth_frame_valid <= 1'b0;
            
               if (eth_crsdv) begin                 // eth_crsdv marks line is in use and we are recieving
                    eth_frame_section <= Types::ETH_PREAMBLE;
                    counter           <= 16'b0;
               end
            end
            
            
            Types::ETH_PREAMBLE: begin
                // Reset back to interpacket gap
                if (!eth_crsdv || rst_in)           
                    eth_frame_section <= Types::ETH_INTERPACKET_GAP;
                
                // If preamble is correct, count number of 1-0 repeats
                else if (!eth_rxd[1] && eth_rxd[0]) 
                    counter <= counter + 1;
            
                // If we reach the desired number of repeats and see preamble end,
                // the next step is 6 bytes of MAC adress
                else if (counter == 16'h001f && eth_rxd == 2'b11) begin 
                    counter <= 16'b0;
                    eth_frame_section <= Types::ETH_MAC_DESTINATION;
                
                // If preamble sequence breaks, go back to interpacket gap
                end else
                    counter <= 16'b0;
            end
            
            Types::ETH_MAC_DESTINATION: begin
                // Reset back to interpacket gap
                if (!eth_crsdv || rst_in)           
                    eth_frame_section <= Types::ETH_INTERPACKET_GAP;
                    
                // Increment counter if we're still reading 
                // destination mac address
                else if (counter != 16'd23)
                    counter <= counter + 1;
                
                // We must have reached the end of the destionation
                // mac adress. We move on to source mac adress
                else begin
                    counter <= 16'b0;
                    eth_frame_section <= Types::ETH_MAC_SOURCE;
                end
            end
            
            Types::ETH_MAC_SOURCE: begin
                // Reset back to interpacket gap
                if (!eth_crsdv || rst_in)           
                    eth_frame_section <= Types::ETH_INTERPACKET_GAP;
                    
                // Increment counter if we're still reading 
                // source mac address
                else if (counter != 16'd23)
                    counter <= counter + 1;
                
                // We must have reached the end of the source
                // mac adress. For now we reset back to interpacket gap TODO: do payload and crc
                else begin
                    counter <= 16'b0;
                    eth_frame_section <= Types::ETH_ETHER_TYPE;
                end
            end     
            
            
            Types::ETH_ETHER_TYPE: begin
                // Reset back to interpacket gap
                if (!eth_crsdv || rst_in)           
                    eth_frame_section <= Types::ETH_INTERPACKET_GAP;
                    
                // Increment counteri
                else if (counter != 16'd07)
                    counter <= counter + 1;
                
                else begin
                    counter <= 0;
                    eth_frame_section <= Types::ETH_PAYLOAD;
                end
            end
            
            
            Types::ETH_PAYLOAD: begin
                if (!eth_crsdv || rst_in)           
                    eth_frame_section <= Types::ETH_INTERPACKET_GAP;
            
                if (!(payload_finished && counter % 4 == 3) || counter < 16'd180)   // Payload is minimum 46 bytes (184 2-bits) long
                    counter <= counter + 1;
                    
                else begin
                    counter <= 0;
                    eth_frame_section <= Types::ETH_CRC;
                end
            end
            
            
            Types::ETH_CRC: begin
                if (counter == 16'h00)
                    crc_storage <= crc;
            
                if (!eth_crsdv || rst_in)           
                    eth_frame_section <= Types::ETH_INTERPACKET_GAP;
                
                if (counter != 16'h0f)
                    counter <= counter + 1;
                    
                else begin
                    counter <= 0;
                    eth_frame_section <= Types::ETH_INTERPACKET_GAP;
                    eth_frame_valid <= (crc_storage == crc_frame);
                end
            end
        endcase
    end


    ila_1 ila(
        .clk(eth_clk),
        .probe0(eth_rxd),
        .probe1(eth_crsdv),
        .probe2(counter),
        .probe3(eth_frame_section),
        .probe4(eth_header.mac_destination),
        .probe5(eth_header.mac_source),
        .probe6(byte_inverted),
        .probe7(eth_header.ether_type),
        .probe8(eth_frame_valid),
        .probe9(crc),
        .probe10(crc_storage),
        .probe11(crc_frame));
endmodule // eth_rx

`default_nettype wire