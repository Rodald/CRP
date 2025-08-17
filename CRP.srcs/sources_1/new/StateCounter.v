module StateCounter #(
    parameter COUNTER_WIDTH = 3
)(
    input  wire clk,
    input  wire reset,
    // resets the sate on the next clk neg edge
    input  wire resetState,
    output reg  [COUNTER_WIDTH-1:0] count
);

    always @(negedge clk, posedge reset) begin
        if (reset | resetState)
            count <= 0;
        else
            count <= count + 1;
    end

endmodule
