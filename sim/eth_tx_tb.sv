`timescale 1ns / 1ps
import Types::e_ether_type;
import Types::st_eth_packet;

module eth_tx_tb;
    logic eth_clk;
    logic rst;
    logic transmit;
    logic trigger;
    
    logic [1:0] eth_txd;
    logic       eth_txen; 

    
    
    eth_tx uut(
        .eth_clk(eth_clk), .rst_in(rst), .transmit(transmit),
        .eth_txd(eth_txd), .eth_txen(eth_txen),
        .eth_packet({
            48'h106530703d6d,
            48'h123456789abc,
            Types::ARP,
            { 368'h0001080006040001704d7b63188f0a1f556a0000000000000a1f55ff_000000000000000000000000000000000000 }
        }));
        
    always begin        // 50 Mhz clock
        #10;
        eth_clk = !eth_clk;
    end

    initial begin
        $display("Starting eth_tx_tb testbench simulation");
        eth_clk = 0;
        rst = 0;
        transmit = 0;
        #20;
        
        // Reset module
        rst = 1; #20; rst = 0; #20;
        
        // Start transmitting
        #1000;
        transmit = 1;// #20; transmit = 0; #20;
        #10000; 
    end
endmodule // eth_tx_tb
