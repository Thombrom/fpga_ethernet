`default_nettype none

import Types::st_arp_packet;
import Types::st_eth_header;
import Types::e_link_protocol;
import Types::e_ether_type;
import Types::e_arp_oper;
import Types::st_eth_packet;

module arp_handler(    
    input wire          eth_clk,            // Clock signal (50 mhz)
    input wire          rst_in,
    input wire          active,             // If we're reading the IPV4 packet
    input st_eth_header eth_header,         // Ethernet header
    input wire [7:0]    data_rxd,           // Decoded byte (from the ethernet MSB-first scheme)
    input wire          data_new,           // Pulled high when the data_rxd is valid
    
    output logic        finished,           // Pull high when handler is finished
    output logic         send_packet,
    output st_eth_packet eth_packet);

    localparam MY_MAC_ADDR = 48'h12_34_56_78_9a_bc;
    localparam MY_IP_ADDR  = 32'hc0_a8_00_01;
    
    logic [15:0] counter;
    st_arp_packet arp_packet;
    
    always_ff @(posedge eth_clk) begin
        if (!active || rst_in) begin
            counter      <= 0;
            finished     <= 0;
            
            arp_packet.htype <= 0;
            arp_packet.ptype <= 0;
            arp_packet.hlen  <= 0;
            arp_packet.plen  <= 0;
            arp_packet.oper  <= 0;
            
            arp_packet.sender_hardware_address <= 0;
            arp_packet.sender_protocol_address <= 0;
            arp_packet.target_hardware_address <= 0;
            arp_packet.target_protocol_address <= 0;
        end else if (counter < 16'd28) begin
            if (data_new) begin
                counter <= counter + 1;
            
                case (counter) 
                    16'h00: arp_packet.htype[15-:8] <= data_rxd;
                    16'h01: arp_packet.htype[7-:8]  <= data_rxd;
                    16'h02: arp_packet.ptype[15-:8] <= data_rxd;
                    16'h03: arp_packet.ptype[7-:8]  <= data_rxd;
                    16'h04: arp_packet.hlen         <= data_rxd;
                    16'h05: arp_packet.plen         <= data_rxd;
                    16'h06: arp_packet.oper[15-:8]  <= data_rxd;
                    16'h07: arp_packet.oper[7-:8]   <= data_rxd;
                    
                    16'h08: arp_packet.sender_hardware_address[47-:8] <= data_rxd;
                    16'h09: arp_packet.sender_hardware_address[39-:8] <= data_rxd;
                    16'h0a: arp_packet.sender_hardware_address[31-:8] <= data_rxd;
                    16'h0b: arp_packet.sender_hardware_address[23-:8] <= data_rxd;
                    16'h0c: arp_packet.sender_hardware_address[15-:8] <= data_rxd;
                    16'h0d: arp_packet.sender_hardware_address[7-:8]  <= data_rxd;
                    
                    16'h0e: arp_packet.sender_protocol_address[31-:8] <= data_rxd;
                    16'h0f: arp_packet.sender_protocol_address[23-:8] <= data_rxd;
                    16'h10: arp_packet.sender_protocol_address[15-:8] <= data_rxd;
                    16'h11: arp_packet.sender_protocol_address[7-:8]  <= data_rxd;
                    
                    16'h12: arp_packet.target_hardware_address[47-:8] <= data_rxd;
                    16'h13: arp_packet.target_hardware_address[39-:8] <= data_rxd;
                    16'h14: arp_packet.target_hardware_address[31-:8] <= data_rxd;
                    16'h15: arp_packet.target_hardware_address[23-:8] <= data_rxd;
                    16'h16: arp_packet.target_hardware_address[15-:8] <= data_rxd;
                    16'h17: arp_packet.target_hardware_address[7-:8]  <= data_rxd;
                    
                    16'h18: arp_packet.target_protocol_address[31-:8] <= data_rxd;
                    16'h19: arp_packet.target_protocol_address[23-:8] <= data_rxd;
                    16'h1a: arp_packet.target_protocol_address[15-:8] <= data_rxd;
                    16'h1b: arp_packet.target_protocol_address[7-:8]  <= data_rxd;                    
                endcase
            end
        end else begin
            finished <= 1'b1;
            
            if ((arp_packet.target_hardware_address == 48'h00_00_00_00_00_00) &&  // Ask for hardware address
                (arp_packet.target_protocol_address == MY_IP_ADDR) &&             // Are we targeting me?
                (eth_header.mac_destination == 48'hff_ff_ff_ff_ff_ff) &&          // Are we broadcasting this packet
                (arp_packet.oper == Types::ARP_OPER_REQUEST)) begin               // Do not respond to replies
                
                send_packet = 1'b1;
                eth_packet = {
                    eth_header.mac_source,
                    MY_MAC_ADDR,
                    Types::ARP,
                    {
                        16'h0001,
                        16'h0800,
                        8'h06, 8'h04,
                        16'h0002,
                        MY_MAC_ADDR,
                        MY_IP_ADDR,
                        arp_packet.sender_hardware_address,
                        arp_packet.sender_protocol_address,
                        144'h00000000_00000000_00000000_00000000_0000
                    }
                };
            end else begin
            
            end
        end 
    end
    
    ila_arp ila_arp(
        .clk(eth_clk),
        .probe0(active),
        .probe1(data_rxd),
        .probe2(data_new),
        .probe3(finished),
        .probe4(arp_packet.htype),
        .probe5(arp_packet.ptype),
        .probe6(arp_packet.hlen),
        .probe7(arp_packet.plen),
        .probe8(arp_packet.oper),
        .probe9(arp_packet.sender_hardware_address),
        .probe10(arp_packet.sender_protocol_address),
        .probe11(arp_packet.target_hardware_address),
        .probe12(arp_packet.target_protocol_address));
endmodule
`default_nettype wire