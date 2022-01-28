`timescale 1ns / 1ps
import Types::e_ether_type;
import Types::st_eth_packet;

module top_level_tb;
    logic eth_clk;
    logic rst;
    logic transmit;
    
    logic [1:0] eth_txd;
    logic [1:0] eth_rxd;
    logic       eth_txen;
    
    assign eth_rxd = eth_txd;           // Loopback 

    logic           eth_send_packet;
    st_eth_packet   eth_packet;
    eth_rx eth_rx(
        .rst_in(rst),
        .eth_clk(eth_clk),
        .eth_rxd(eth_rxd),
        .eth_mdio(eth_txen),
        .eth_crsdv(eth_txen),
        .eth_rxerr(eth_rxerr),
        .eth_send_packet(eth_send_packet),
        .eth_packet(eth_packet));
    
    logic eth_send_packet_delayed;
    queue_fifo #(.BUFFER_LENGTH(100), .INPUT_WIDTH(1)) transmit_queue(
        .clk_in(eth_clk),
        .rst_in(rst),
        .trigger(1'b1),
        .data_in(eth_send_packet),
        .data_out(eth_send_packet_delayed));
    
    eth_tx eth_tx(
        .eth_clk(eth_clk), .rst_in(rst), .transmit(transmit | eth_send_packet_delayed),
        .eth_txd(eth_txd), .eth_txen(eth_txen),
        .eth_packet(eth_packet));
        
    always begin        // 50 Mhz clock
        #10;
        eth_clk = !eth_clk;
    end

    initial begin
        $display("Starting eth_tx_tb testbench simulation");
        eth_clk = 0;
        rst = 0;
        transmit = 0;
        eth_packet = {
            48'h106530703d6d,
            48'h123456789abc,
            Types::ARP,
            { 368'h0001080006040001704d7b63188f0a1f556a0000000000000a1f55ff_000000000000000000000000000000000000 }
        }; #20;
        
        // Reset module
        rst = 1; #20; rst = 0; #20;
        
        // Start transmitting
        #1000;
        transmit = 1; #20; transmit = 0; #20;
        #10000; 
    end
endmodule // eth_tx_tb
