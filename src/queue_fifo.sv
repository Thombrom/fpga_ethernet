`default_nettype none
module queue_fifo
    #(parameter BUFFER_LENGTH,        // Number of elements
                INPUT_WIDTH)          // Width of input 

    (   input wire clk_in,
        input wire rst_in,
        input wire trigger,
        input wire [BUFFER_LENGTH * INPUT_WIDTH - 1:0] default_value,
        input wire [INPUT_WIDTH - 1:0] data_in,
        
        output logic [INPUT_WIDTH - 1:0] data_out);

    logic [BUFFER_LENGTH * INPUT_WIDTH - 1:0] internal_storage; 
    assign data_out = internal_storage[BUFFER_LENGTH * INPUT_WIDTH - 1 -: INPUT_WIDTH];
        
    buffer_ra #(
        .BUFFER_SIZE(BUFFER_LENGTH * INPUT_WIDTH), 
        .INPUT_SIZE(INPUT_WIDTH)) buffer(
            .clk_in(clk_in),
            .rst_in(rst_in),
            .trigger(trigger),
            .default_value(default_value),
            .data_in(data_in),
            .data_out(internal_storage));
endmodule // queue_fifo

`default_nettype wire