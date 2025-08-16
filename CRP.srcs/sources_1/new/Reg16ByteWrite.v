module Reg16ByteWrite(
    input wire clk,
    input wire reset,
    input wire reg1WriteEn,
    input wire reg2WriteEn,
    input wire [7:0] dataIn,
    output wire [15:0] dataOut
);
    Register #(8, 8'b0) reg1(
        clk,
        reset,
        reg1WriteEn,
        dataIn,
        dataOut[7:0]
    );

    Register #(8, 8'b0) reg2(
        clk,
        reset,
        reg2WriteEn,
        dataIn,
        dataOut[15:8]
    );
endmodule