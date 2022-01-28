`timescale 1ns / 1ps
module buffer_ra_instant_tb;
    
    logic           clk;
    logic           rst;
    logic           trigger;
    logic [1:0]     data_in;
    logic [7:0]     data_out_nor;
    logic [7:0]     data_out_rev;
    
    always begin
        #5;
        clk = !clk;
    end
    
    buffer_ra_instant #(.BUFFER_SIZE(8), .INPUT_SIZE(2), .REVERSE(0)) uut_nor(
        .clk_in(clk), .rst_in(rst), .data_in(data_in),
        .trigger(trigger), .data_out(data_out_nor));
        
    buffer_ra_instant #(.BUFFER_SIZE(8), .INPUT_SIZE(2), .REVERSE(1)) uut_rev(
        .clk_in(clk), .rst_in(rst), .data_in(data_in),
        .trigger(trigger), .data_out(data_out_rev));
    
    initial begin
        $display("Starting buffer_ra_instant_tb simulation");
        clk = 0;
        rst = 0;
        data_in  = 2'b0;
        trigger = 0;
        
        // Reset buffer
        #20; rst = 1; #20 rst = 0; #20;
        
        assert(data_out_nor == 8'b0000_0000) else $error("Buffer invalid data");
        assert(data_out_rev == 8'b0000_0000) else $error("Buffer rev invalid data");
        data_in = 2'b01; #10;
        assert(data_out_nor == 8'b0000_0001) else $error("Buffer invalid data");
        assert(data_out_rev == 8'b0100_0000) else $error("Buffer rev invalid data");
        trigger = 1'b1; #10; trigger = 1'b0; #10;
        
        assert(data_out_nor == 8'b0000_0101) else $error("Buffer invalid data");
        assert(data_out_rev == 8'b0101_0000) else $error("Buffer rev invalid data");
        data_in = 3'b10; #10;
        assert(data_out_nor == 8'b0000_0110) else $error("Buffer invalid data");
        assert(data_out_rev == 8'b1001_0000) else $error("Buffer rev invalid data");
        trigger = 1'b1; #10; trigger = 1'b0; #10;
        
        assert(data_out_nor == 8'b0001_1010) else $error("Buffer invalid data");
        assert(data_out_rev == 8'b1010_0100) else $error("Buffer rev invalid data");
        data_in = 2'b11; #10;
        assert(data_out_nor == 8'b0001_1011) else $error("Buffer invalid data");
        assert(data_out_rev == 8'b1110_0100) else $error("Buffer rev invalid data");
        trigger = 1'b1; #10; trigger = 1'b0; #10;
        
        assert(data_out_nor == 8'b0110_1111) else $error("Buffer invalid data");
        assert(data_out_rev == 8'b1111_1001) else $error("Buffer rev invalid data");
        data_in = 2'b00; #10;
        assert(data_out_nor == 8'b0110_1100) else $error("Buffer invalid data");
        assert(data_out_rev == 8'b0011_1001) else $error("Buffer rev invalid data");
        trigger = 1'b1; #10; trigger = 1'b0; #10;
        
        assert(data_out_nor == 8'b1011_0000) else $error("Buffer invalid data");
        assert(data_out_rev == 8'b0000_1110) else $error("Buffer rev invalid data");
        data_in = 2'b01; #10;
        assert(data_out_nor == 8'b1011_0001) else $error("Buffer invalid data");
        assert(data_out_rev == 8'b0100_1110) else $error("Buffer rev invalid data");
        trigger = 1'b1; #10; trigger = 1'b0; #10;
        
        assert(data_out_nor == 8'b1100_0101) else $error("Buffer invalid data");
        assert(data_out_rev == 8'b0101_0011) else $error("Buffer rev invalid data");
        $finish;
    end
endmodule //buffer_ra_instant_tb