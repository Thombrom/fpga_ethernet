`default_nettype none
module eth_crc32_tb;
    logic clk;
    logic active;
    logic rst;
    
    logic [1:0]  rxd;
    logic [31:0] crc;

    eth_crc32 uut(
        .eth_clk(clk), .rst_in(rst), .active(active),
        .eth_rxd(rxd), .crc_out(crc));
        
    always begin
        #5;
        clk = !clk;
    end
    
    initial begin
        clk = 0;
        active = 0;
        rst = 0;
        rxd = 2'b0;
        #10;
        
        // Reset module
        rst = 1; #10; rst = 0; #10;
        
        active = 1;
        rxd = 2'b01; #10;
        rxd = 2'b00; #10;
        rxd = 2'b10; #10;
        rxd = 2'b00; #10;
        
        rxd = 2'b00; #10;
        rxd = 2'b10; #10;
        rxd = 2'b11; #10;
        rxd = 2'b00; #10;
        
        rxd = 2'b01; #10;
        rxd = 2'b10; #10;
        rxd = 2'b10; #10;
        rxd = 2'b10; #10;
        
        rxd = 2'b00; #10;
        rxd = 2'b01; #10;
        rxd = 2'b11; #10;
        rxd = 2'b10; #10;
        assert(crc == 32'h4a090e98) else $error("Wrong crc value");
        active = 0;
        #50;

        $finish;
    end
endmodule

`default_nettype wire