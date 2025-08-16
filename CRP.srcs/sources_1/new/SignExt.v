module SignExt #(
    parameter IN_WIDTH = 12,
    parameter OUT_WIDTH = 16
)(
    input [IN_WIDTH-1:0] in,
    output [OUT_WIDTH-1:0] out
);
    assign out = {{OUT_WIDTH-IN_WIDTH{in[IN_WIDTH-1]}}, in};
endmodule