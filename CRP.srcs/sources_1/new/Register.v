module Register #(
    parameter WIDTH = 8,
    parameter RESET_VALUE = {WIDTH{1'b0}}
)(
    input wire clk,
    input wire reset,
    input wire writeEn,
    input wire [WIDTH-1:0] dataIn,
    output reg [WIDTH-1:0] dataOut
);

    always @ (posedge clk) begin
        if (reset) dataOut <= RESET_VALUE;
        else if (writeEn) dataOut <= dataIn;
    end
endmodule