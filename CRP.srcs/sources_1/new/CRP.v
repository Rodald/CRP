module CRP #(
    parameter OPCODE_WIDTH = 4,
    parameter FUNC_WIDTH = 4,
    parameter FLAGS_WIDTH = 4,
    parameter CONTROL_WIDTH = 22,

    parameter ADDR_WIDTH = 15,
    parameter PC_WIDTH = ADDR_WIDTH,
    parameter SP_WIDTH = ADDR_WIDTH,
    parameter DATA_WIDTH = 8,
    parameter INSTR_WIDTH = 16
)(
    input clk, reset,

    input [DATA_WIDTH-1:0] memReadBus,
    output [ADDR_WIDTH-1:0] memReqBus,
    output memWriteReq
);
    wire dataAddrSel;
    wire iOrD;
    wire readMemAddrFromReg;
    wire flagSrcSel;
    wire aluOutSrcSel;
    wire regsOrAluSel;
    wire byteSwapEn;
    wire [1:0] regWriteSrcSel;
    wire [1:0] aluSrc1Sel;
    wire [1:0] aluSrc2Sel;
    wire pcWriteEn;
    wire spWriteEn;
    wire instrRegLowWriteEn;
    wire instrRegHighWriteEn;
    wire regsWriteEn;
    wire flagsWriteEn;
    wire aluOutWriteEn;
    wire [FLAGS_WIDTH-1:0] flagsOut;
    wire [INSTR_WIDTH-1:0] instrBus;

    wire [2:0] aluControl;
    Controller #(
        .OPCODE_WIDTH(OPCODE_WIDTH),
        .FUNC_WIDTH(FUNC_WIDTH),
        .FLAGS_WIDTH(FLAGS_WIDTH),
        .CONTROL_WIDTH(CONTROL_WIDTH)
    ) controller (
        .clk(clk),
        .reset(reset),
        .opcode(instrBus[INSTR_WIDTH-1 -:4]),
        .func(instrBus[3:0]),
        .flags(flagsOut),
        .dataAddrSel(dataAddrSel),
        .iOrD(iOrD),
        .readMemAddrFromReg(readMemAddrFromReg),
        .flagSrcSel(flagSrcSel),
        .aluOutSrcSel(aluOutSrcSel),
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
        .aluOutWriteEn(aluOutWriteEn),
        .memWriteReq(memWriteReq),
        .aluControl(aluControl)
    );

    Datapath #(
        .PC_WIDTH(PC_WIDTH),
        .SP_WIDTH(SP_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .INSTR_WIDTH(INSTR_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) datapath(
        .clk(clk),
        .reset(reset),
        .dataAddrSel(dataAddrSel),
        .iOrD(iOrD),
        .readMemAddrFromReg(readMemAddrFromReg),
        .flagSrcSel(flagSrcSel),
        .aluOutSrcSel(aluOutSrcSel),
        .regsOrAluSel(regsOrAluSel),
        .byteSwapEn(byteSwapEn),
        .regWriteSrcSel(regWriteSrcSel),
        .aluSrc1Sel(aluSrc1Sel),
        .aluSrc2Sel(aluSrc2Sel),
        .aluControl(aluControl),
        .pcWriteEn(pcWriteEn),
        .spWriteEn(spWriteEn),
        .instrRegLowWriteEn(instrRegLowWriteEn),
        .instrRegHighWriteEn(instrRegHighWriteEn),
        .regsWriteEn(regsWriteEn),
        .flagsWriteEn(flagsWriteEn),
        .aluOutWriteEn(aluOutWriteEn),
        .memReadBus(memReadBus),
        .memReqBus(memReqBus),
        .flagsOut(flagsOut),
        .instrBusOut(instrBus)
    );
endmodule

