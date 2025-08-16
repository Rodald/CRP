module ShiftLeft1 #(
    parameter DATA_WIDTH = 8
) (
    input [DATA_WIDTH-1:0] in,
    output [DATA_WIDTH-1:0] out
);
    assign out = {in[DATA_WIDTH-2:0], 1'b0};
endmodule
