`default_nettype none
import Types::e_ether_type;
import Types::st_eth_header;
import Types::st_eth_packet;

module eth_frame_payload_handler(
    input wire          eth_clk,            // Clock signal (50 mhz)
    input wire          rst_in,             // Reset
    input wire          active,             // High if we're in the payload segment of the ethernet frame
    input st_eth_header eth_header,         // The ethernet header
    
    input wire [7:0]    data_rxd,           // Decoded byte (from the ethernet MSB-first scheme)
    input wire          data_new,           // Pulled high when the data_rxd is valid
    
    output logic        finished,           // Pull high when handler is finished  
    output logic         send_packet,
    output st_eth_packet eth_packet);

    logic [1:0]     handler_finished;
    ipv4_handler ipv4_handler(
        .eth_clk(eth_clk), .active(eth_header.ether_type == Types::IPV4 && active), .rst_in(rst_in),
        .eth_header(eth_header),
        .data_rxd(data_rxd), .data_new(data_new),
        .finished(handler_finished[0]));
        
    logic           arp_send_packet;
    st_eth_packet   arp_eth_packet;
    arp_handler arp_handler(
        .eth_clk(eth_clk), .active(eth_header.ether_type == Types::ARP && active), .rst_in(rst_in),
        .eth_header(eth_header),
        .data_rxd(data_rxd), .data_new(data_new),
        .finished(handler_finished[1]),
        .send_packet(arp_send_packet),
        .eth_packet(arp_eth_packet));
    
    always_comb begin
        case (eth_header.ether_type) 
            Types::IPV4: begin
                finished    = handler_finished[0];
                send_packet = 0;
                eth_packet  = 0;
            end
            
            Types::ARP:  begin
                finished = handler_finished[1];
                send_packet = arp_send_packet;
                eth_packet  = arp_eth_packet;
            end
            
            default:     begin
                finished    = 1'b1;
                send_packet = 1'b0;
                //send_packet = 1'b1;
                //eth_packet  = {
                //    48'hffffffffffff,
                //    48'h106530703d6d,
                //    Types::ARP,
                //    { 368'h0001080006040001704d7b63188f0a1f556a000000000000c0a80001_000000000000000000000000000000000000 }
                //}; 
            end
        endcase
    end
endmodule
`default_nettype wire

