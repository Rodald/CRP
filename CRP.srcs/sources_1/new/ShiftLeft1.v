module ShiftLeft1 #(
    parameter DATA_WIDTH = 8
) (
    input [DATA_WIDTH-1:0] in,
    output [DATA_WIDTH-1:0] out
);
    assign out = in << 1;
endmodule
