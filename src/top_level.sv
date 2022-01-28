`default_nettype none
import Types::st_eth_packet;

module top_level(
    input wire clk_100mhz,
    input wire btnc, btnu,
    input wire btnl, btnd,
    
    output logic [15:0] led,
    
    // ETHERNET
    input wire          eth_mdio,
    input wire          eth_crsdv,
    input wire          eth_rxerr,
    input wire [1:0]    eth_rxd,
    
    output logic        eth_txen,
    output logic [1:0]  eth_txd,
    output logic        eth_rstn,
    output logic        eth_mdc,
    output logic        eth_refclk);

    clk_wiz_0 eth_clk_module (
        .clk_out(eth_refclk),       // output clk_out
        .reset(btnc),              // input reset
        .clk_in(clk_100mhz));      // input clk_in

    logic           eth_send_packet;
    st_eth_packet   eth_packet;
    eth_rx(
        .rst_in(btnl),
        .eth_clk(eth_refclk),
        .eth_rxd(eth_rxd),
        .eth_mdio(eth_mdio),
        .eth_crsdv(eth_crsdv),
        .eth_rxerr(eth_rxerr),
        .eth_send_packet(eth_send_packet),
        .eth_packet(eth_packet));

    logic eth_send_packet_delayed;
    queue_fifo #(.BUFFER_LENGTH(100), .INPUT_WIDTH(1)) transmit_queue(
        .clk_in(eth_refclk),
        .rst_in(btnl),
        .trigger(1'b1),
        .data_in(eth_send_packet),
        .data_out(eth_send_packet_delayed));

    logic btnu_clean;
    debounce debounce_btnu(
        .clk_in(clk_100mhz),
        .rst_in(btnl),
        .bouncey_in(btnu),
        .clean_out(btnu_clean));
        
    logic btnu_edge;
    rising_edge_detector edge_btnu(
        .clk_in(eth_refclk),
        .rst_in(btnl),
        .clean_in(btnu_clean),
        .edge_out(btnu_edge));
    
    eth_tx(
        .eth_clk(eth_refclk),
        .rst_in(btnl),
        .transmit(btnu_clean || eth_send_packet_delayed),
        .eth_txd(eth_txd),
        .eth_txen(eth_txen),
        .eth_packet(eth_packet));

    //{
    //    48'h106530703d6d,
    //    48'h123456789abc,
    //    Types::ARP,
    //    { 368'h0001080006040001704d7b63188f0a1f556a0000000000000a1f55ff_000000000000000000000000000000000000 }
    //}

    //ila_0 ila(
    //    .clk(clk_100mhz),
    //    .probe0(eth_rxd),
    //    .probe1(eth_mdio),
    //    .probe2(eth_crsdv),
    //    .probe3(eth_rxerr),
    //    .probe4(eth_refclk));
        

    assign led[4:0] = { eth_rxd, eth_rxerr, eth_crsdv, eth_mdio };
    assign led[9:5] = { eth_txd, eth_txen,  btnu_clean, btnu_edge};

endmodule // top_level
`default_nettype wire
