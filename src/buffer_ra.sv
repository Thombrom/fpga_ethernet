`default_nettype none

// Shift buffer. Takes input and shifts everything,
// in a FIFO manner.
// REVERSE toggles whether new data is most or least
// significant
module buffer_ra
    #(parameter BUFFER_SIZE,
                INPUT_SIZE,
                REVERSE = 0) 
    (   input wire clk_in,
        input wire trigger,
        input wire rst_in,
        input wire [BUFFER_SIZE-1:0] default_value,
        input wire [INPUT_SIZE-1:0]  data_in,
        
        output logic [BUFFER_SIZE-1:0] data_out,
        output logic [INPUT_SIZE-1:0]  slice_out);
                
    assign slice_out = REVERSE ?
        data_out[INPUT_SIZE-1:0] : 
        data_out[BUFFER_SIZE - 1:BUFFER_SIZE - INPUT_SIZE];
                
    always_ff @(posedge clk_in) begin
        if (rst_in)
            data_out <= default_value;
        else if (trigger) begin
            if (BUFFER_SIZE == INPUT_SIZE) // Special case
                data_out  <= data_in;        
            else if (!REVERSE)
                data_out  <= { data_out[BUFFER_SIZE - INPUT_SIZE - 1:0], data_in };
            else
                data_out  <= { data_in, data_out[BUFFER_SIZE - 1:INPUT_SIZE] };
        end
    end
endmodule // buffer_ra

module buffer_ra_instant 
    #(parameter BUFFER_SIZE,
                INPUT_SIZE,
                REVERSE = 0) 
    (   input wire clk_in,
        input wire trigger,
        input wire rst_in,
        input wire [INPUT_SIZE-1:0] data_in,
        
        output logic [BUFFER_SIZE-1:0] data_out);
        
    reg [BUFFER_SIZE - INPUT_SIZE - 1:0] data_buffer;
    assign data_out = REVERSE ?
        { data_in, data_buffer[BUFFER_SIZE - INPUT_SIZE - 1:0] } : 
        { data_buffer[BUFFER_SIZE - INPUT_SIZE - 1:0], data_in };
        
    always_ff @(posedge clk_in) begin
        if (rst_in)
            data_buffer <= 0;
        else if (trigger) begin
            if (!REVERSE)
                data_buffer <= { data_buffer[BUFFER_SIZE - INPUT_SIZE - 1:0], data_in };
            else
                data_buffer <= { data_in, data_buffer[BUFFER_SIZE - INPUT_SIZE - 1:INPUT_SIZE] };
        end
    end
endmodule // buffer_ra_instant
`default_nettype wire