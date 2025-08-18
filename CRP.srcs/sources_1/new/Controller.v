module Controller #(
    parameter OPCODE_WIDTH = 4,
    parameter FUNC_WIDTH = 4,
    parameter FLAGS_WIDTH = 4,
    parameter CONTROL_WIDTH = 20
)(
    input clk, reset,
    input wire [OPCODE_WIDTH-1:0] opcode,
    input wire [OPCODE_WIDTH-1:0] func,
    input wire [FLAGS_WIDTH-1:0] flags,

    // control signals
    output wire dataAddrSel,
    output wire iOrD,
    output wire readMemAddrFromReg,   // controls if the register file should read the targeted memory addr.
    output wire flagSrcSel,
    output wire regsOrAluSel,
    output wire byteSwapEn,

    output wire [1:0] regWriteSrcSel,
    output wire [1:0] aluSrc1Sel,
    output wire [1:0] aluSrc2Sel,


    // write signals
    output wire pcWriteEn,
    output wire spWriteEn,
    output wire instrRegLowWriteEn,
    output wire instrRegHighWriteEn,
    output wire regsWriteEn,
    output wire flagsWriteEn,
    output wire memWriteReq,

    output wire [2:0] aluControl
);
    wire [2:0] state;
    wire resetState;
    StateCounter #(
        .COUNTER_WIDTH(3)
    ) stateCounter(
        .clk(clk),
        .reset(reset),
        .resetState(resetState),
        .count(state)
    );

    MainDecoder #(.OPCODE_WIDTH(OPCODE_WIDTH),
        .FUNC_WIDTH(FUNC_WIDTH),
        .FLAGS_WIDTH(FLAGS_WIDTH),
        .CONTROL_WIDTH(CONTROL_WIDTH)
    ) mainDecoder (
        .opcode(opcode),
        .func(func),
        .flags(flags),
        .state(state),
        .resetState(resetState),
        .dataAddrSel(dataAddrSel),
        .iOrD(iOrD),
        .readMemAddrFromReg(readMemAddrFromReg),
        .flagSrcSel(flagSrcSel),
        .regsOrAluSel(regsOrAluSel),
        .byteSwapEn(byteSwapEn),
        .regWriteSrcSel(regWriteSrcSel),
        .aluSrc1Sel(aluSrc1Sel),
        .aluSrc2Sel(aluSrc2Sel),
        .pcWriteEn(pcWriteEn),
        .spWriteEn(spWriteEn),
        .instrRegLowWriteEn(instrRegLowWriteEn),
        .instrRegHighWriteEn(instrRegHighWriteEn),
        .regsWriteEn(regsWriteEn),
        .flagsWriteEn(flagsWriteEn),
        .memWriteReq(memWriteReq)
    );

    ALUDec #(
        .OPCODE_WIDTH(OPCODE_WIDTH),
        .FUNC_WIDTH(FUNC_WIDTH)
    ) aluDec(
        .opcode(opcode),
        .func(func),
        .state(state),
        .aluControl(aluControl)
    );
endmodule