`timescale 1ns / 1ps
import Types::e_ipv4_section;
import Types::st_ipv4_header;
import Types::st_eth_header;

module ipv4_handler(
    input wire          eth_clk,            // Clock signal (50 mhz)
    input wire          rst_in,
    input wire          active,             // If we're reading the IPV4 packet
    input st_eth_header eth_header,         // Ethernet header
    input wire [7:0]    data_rxd,           // Decoded byte (from the ethernet MSB-first scheme)
    input wire          data_new,           // Pulled high when the data_rxd is valid
    
    output logic        finished);          // Pull high when handler is finished
    
    e_ipv4_section ipv4_section;
    logic [15:0] counter;
    
    // Data
    st_ipv4_header ipv4_header;
    
    logic [3:0]     ipv4_version;
    logic [3:0]     ipv4_ihl;
    logic [5:0]     ipv4_dscp;
    logic [1:0]     ipv4_ecn;
    logic [15:0]    ipv4_length;
    logic [15:0]    ipv4_ident;
    logic [2:0]     ipv4_flags;
    logic [12:0]    ipv4_offset;
    logic [7:0]     ipv4_ttl;
    logic [7:0]     ipv4_protocol;
    logic [15:0]    ipv4_checksum;
    logic [31:0]    ipv4_source_addr;
    logic [31:0]    ipv4_destination_addr;
    
    always_ff @(posedge eth_clk) begin
        // Reset if it is not active. We start over
        // reading the IPV4 header
        if (!active || rst_in) begin
            ipv4_section <= Types::IPV4_HEADER;
            counter      <= 0;
            finished     <= 0;
            
            ipv4_header.version             <= 0;
            ipv4_header.ihl                 <= 0;
            ipv4_header.dscp                <= 0;
            ipv4_header.ecn                 <= 0;
            ipv4_header.length              <= 0;
            ipv4_header.ident               <= 0;
            ipv4_header.flags               <= 0;
            ipv4_header.offset              <= 0;
            ipv4_header.ttl                 <= 0;
            ipv4_header.protocol            <= 0;
            ipv4_header.checksum            <= 0;
            ipv4_header.source_addr         <= 0;
            ipv4_header.destination_addr    <= 0;

        // If we're reading the header we know the 
        // first 20 bytes are going to be specific fields
        // We fill those in
        end else if (ipv4_section == Types::IPV4_HEADER) begin
            if (data_new) begin 
                counter <= counter + 1;
                finished <= 0;
            
                case (counter)
                    16'h00: begin
                        ipv4_header.version <= data_rxd[7-:4];
                        ipv4_header.ihl     <= data_rxd[3-:4];
                    end
                    
                    16'h01: begin
                        ipv4_header.dscp    <= data_rxd[5-:6];
                        ipv4_header.ecn     <= data_rxd[7-:2];
                    end
                    
                    16'h02: ipv4_header.length[15-:8] <= data_rxd;
                    16'h03: ipv4_header.length[7-:8]  <= data_rxd;
                    16'h04: ipv4_header.ident[15-:8]  <= data_rxd;
                    16'h05: ipv4_header.ident[7-:8]   <= data_rxd;
                    
                    16'h06: begin
                        ipv4_header.flags         <= data_rxd[7-:3];
                        ipv4_header.offset[12-:5] <= data_rxd[4-:5];
                    end
                    
                    16'h07: ipv4_header.offset[7-:8]    <= data_rxd;
                    16'h08: ipv4_header.ttl             <= data_rxd;
                    16'h09: ipv4_header.protocol        <= data_rxd;
                    16'h0a: ipv4_header.checksum[15-:8] <= data_rxd;
                    16'h0b: ipv4_header.checksum[7-:8]  <= data_rxd;
                    
                    16'h0c: ipv4_header.source_addr[31-:8]    <= data_rxd;
                    16'h0d: ipv4_header.source_addr[23-:8]    <= data_rxd;
                    16'h0e: ipv4_header.source_addr[15-:8]    <= data_rxd;
                    16'h0f: ipv4_header.source_addr[7-:8]     <= data_rxd;
                    
                    16'h10: ipv4_header.destination_addr[31-:8]    <= data_rxd;
                    16'h11: ipv4_header.destination_addr[23-:8]    <= data_rxd;
                    16'h12: ipv4_header.destination_addr[15-:8]    <= data_rxd;
                    16'h13: ipv4_header.destination_addr[7-:8]     <= data_rxd;
                endcase
            end
          
            // Transition to payload when we read in IHL 32-bit words
            if ((counter > 16'h13) && (counter == (ipv4_header.ihl << 2)))
                 ipv4_section <= Types::IPV4_PAYLOAD;
        
        // Handle IPV4 payload
        end else if (ipv4_section == Types::IPV4_PAYLOAD) begin
            if (data_new)
                counter <= counter + 1;
            
            // Check if we're on the final byte
            if (counter >= ipv4_header.length - 1)
                finished <= 1'b1;
            else
                finished <= 1'b0;
        end
    end
    
    logic [15:0] ipv4_ihl_bytes;
    assign ipv4_ihl_bytes = (ipv4_header.ihl << 2);
    
    ila_ipv4 ila(
        .clk(eth_clk),
        .probe0(active),
        .probe1(data_rxd),
        .probe2(data_new),
        .probe3(finished),
        .probe4(ipv4_section),
        .probe5(counter),
        .probe6(ipv4_header.version),
        .probe7(ipv4_header.ihl),
        .probe8(ipv4_header.dscp),
        .probe9(ipv4_header.ecn),
        .probe10(ipv4_header.length),
        .probe11(ipv4_header.ident),
        .probe12(ipv4_header.flags),
        .probe13(ipv4_header.offset),
        .probe14(ipv4_header.ttl),
        .probe15(ipv4_header.protocol),
        .probe16(ipv4_header.checksum),
        .probe17(ipv4_header.source_addr),
        .probe18(ipv4_header.destination_addr),
        .probe19(ipv4_ihl_bytes));
endmodule
