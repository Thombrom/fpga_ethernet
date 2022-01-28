`timescale 1ns / 1ps
module queue_fifo_tb;
    
    logic           clk;
    logic           rst;
    logic           trigger;
    logic [2:0]     data_in;
    logic [2:0]     data_out;
    
    always begin
        #5;
        clk = !clk;
    end
    
    queue_fifo #(.BUFFER_LENGTH(3), .INPUT_WIDTH(3)) queue(
        .clk_in(clk), .rst_in(rst), .data_in(data_in),
        .trigger(trigger), .data_out(data_out));
    
    initial begin
        $display("Starting buffer_ra_tb simulation");
        clk = 0;
        rst = 0;
        data_in = 2'b0;
        trigger = 0;
        
        // Reset buffer
        #20; rst = 1; #20 rst = 0; #20;
        
        assert(data_out == 3'b000) else $error("Queue invalid data");
        data_in = 3'b101; #10;
        trigger = 1'b1; #10; trigger = 1'b0; #10;
        
        assert(data_out == 3'b000) else $error("Queue invalid data");
        data_in = 3'b001; #10;
        trigger = 1'b1; #10; trigger = 1'b0; #10;
        
        assert(data_out == 3'b000) else $error("Queue invalid data");
        data_in = 3'b110; #10;
        trigger = 1'b1; #10; trigger = 1'b0; #10;
        
        assert(data_out == 3'b101) else $error("Queue invalid data");
        data_in = 3'b000; #10;
        trigger = 1'b1; #10; trigger = 1'b0; #10;
        
        assert(data_out == 3'b001) else $error("Queue invalid data");
        data_in = 3'b000; #10;
        trigger = 1'b1; #10; trigger = 1'b0; #10;
        
        assert(data_out == 3'b110) else $error("Queue invalid data");
        data_in = 3'b000; #10;
        trigger = 1'b1; #10; trigger = 1'b0; #10;
        
        assert(data_out == 3'b000) else $error("Queue invalid data");
        $finish;
    end
endmodule //queue_fifo_tb
