`timescale 1ns / 1ps
module buffer_ra_tb;
    
    logic           clk;
    logic           rst;
    logic [1:0]     data_in;
    logic           trigger;
    logic [9:0]     data_out_nor;
    logic [9:0]     data_out_rev;
    
    always begin
        #5;
        clk = !clk;
    end
    
    buffer_ra #(.BUFFER_SIZE(10), .INPUT_SIZE(2), .REVERSE(0)) buffer_nor(
        .clk_in(clk), .rst_in(rst), .data_in(data_in),
        .trigger(trigger), .data_out(data_out_nor),
        .default_value(10'b10_0000_0000));
        
    buffer_ra #(.BUFFER_SIZE(10), .INPUT_SIZE(2), .REVERSE(1)) buffer_rev(
        .clk_in(clk), .rst_in(rst), .data_in(data_in),
        .trigger(trigger), .data_out(data_out_rev));
    
    initial begin
        $display("Starting buffer_ra_tb simulation");
        clk = 0;
        rst = 0;
        data_in = 2'b0;
        trigger = 0;
        
        // Reset buffer
        #20; rst = 1; #20 rst = 0; #20;
        
        assert(data_out_nor == 10'b10_0000_0000) else $error("Buffer_nor invalid data"); 
        assert(data_out_rev == 10'b00_0000_0000) else $error("Buffer_rev invalid data"); 
        data_in = 2'b10; #10;
        trigger = 1'b1; #10; trigger = 1'b0; #10;
        
        assert(data_out_nor == 10'b00_0000_0010) else $error("Buffer_nor invalid data"); 
        assert(data_out_rev == 10'b10_0000_0000) else $error("Buffer_rev invalid data"); 
        data_in = 2'b01; #10;
        trigger = 1'b1; #10; trigger = 1'b0; #10;

        assert(data_out_nor == 10'b00_0000_1001) else $error("Buffer_nor invalid data");
        assert(data_out_rev == 10'b01_1000_0000) else $error("Buffer_rev invalid data"); 
        data_in = 2'b10; #10;
        trigger = 1'b1; #10; trigger = 1'b0; #10;

        assert(data_out_nor == 10'b00_0010_0110) else $error("Buffer_nor invalid data"); 
        assert(data_out_rev == 10'b10_0110_0000) else $error("Buffer_rev invalid data");
        data_in = 2'b11; #10;
        trigger = 1'b1; #10; trigger = 1'b0; #10;
        
        assert(data_out_nor == 10'b00_1001_1011) else $error("Buffer_nor invalid data");
        assert(data_out_rev == 10'b11_1001_1000) else $error("Buffer_rev invalid data"); 
        data_in = 2'b00; #10;
        trigger = 1'b1; #10; trigger = 1'b0; #10;
        
        assert(data_out_nor == 10'b10_0110_1100) else $error("Buffer_nor invalid data");
        assert(data_out_rev == 10'b00_1110_0110) else $error("Buffer_rev invalid data"); 
        data_in = 2'b10; #10;
        trigger = 1'b1; #10; trigger = 1'b0; #10;

        assert(data_out_nor == 10'b01_1011_0010) else $error("Buffer_nor invalid data");
        assert(data_out_rev == 10'b10_0011_1001) else $error("Buffer_rev invalid data"); 
        $finish;
    end
endmodule
