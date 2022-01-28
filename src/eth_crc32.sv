`default_nettype none
module eth_crc32(
    input wire eth_clk,
    input wire rst_in,
    input wire active,
    input wire [1:0] eth_rxd,
    
    output logic [31:0] crc_out);
    
    localparam CRC_INIT = 32'hffff_ffff;
    localparam CRC_POLY = 32'hedb8_8320;
    
    logic [31:0] crc;
    logic [31:0] crc_bit1, crc_bit2;
    
    assign crc_bit1 = (crc  >> 1) ^ (eth_rxd[1] ^ crc [0] ? CRC_POLY : 32'b0);
    assign crc_bit2 = (crc_bit1 >> 1) ^ (eth_rxd[0] ^ crc_bit1[0] ? CRC_POLY : 32'b0);
    assign crc_out = ~(active ? crc_bit2 : crc);
    
    always_ff @(posedge eth_clk) begin
        if (rst_in || !active) 
            crc <= CRC_INIT;
        else begin
            crc <= crc_bit2;
        end 
    end
    
endmodule // eth_crc
`default_nettype wire
