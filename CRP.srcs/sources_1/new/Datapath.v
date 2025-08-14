module Datapath #(
    parameter PC_WIDTH = 16,
    parameter SP_WIDTH = 16,
    parameter DATA_WIDTH = 8,
    parameter INSTR_WIDTH = 16,
    parameter ADDR_WIDTH = 16
)(
    // control
    input wire clk, reset,
    // mux
    input wire dataAddrSel,
    input wire iOrD,
    input wire readMemAddrFromReg,   // controls if the register file should read the targeted memory addr.
    input wire flagSrcSel,
    input wire aluOutSrcSel,
    input wire regsOrAluSel,
    input wire byteSwapEn,

    input wire [1:0] regWriteSrcSel,
    input wire [1:0] aluSrc1Sel,
    input wire [1:0] aluSrc2Sel,

    input wire [2:0] aluControl,

    // write signals
    input wire pcWriteEn,
    input wire spWriteEn,
    input wire dataRegWriteEn,
    input wire instrRegLowWriteEn,
    input wire instrRegHighWriteEn,
    input wire regsWriteEn,
    input wire flagsWriteEn,
    input wire aluOutWriteEn,

    // memory
    input wire [DATA_WIDTH-1:0] memReadBus,
    output wire [ADDR_WIDTH-1:0] memAddrBus,
    output wire [DATA_WIDTH-1:0] memWriteBus,

    // flags
    output wire [3:0] flagsOut,
    output wire [INSTR_WIDTH-1:0] instrBusOut
);
    wire [15:0] mainBus;

    wire [PC_WIDTH-1:0] pcOut;
    Register #(PC_WIDTH, {PC_WIDTH{1'b0}}) pc(
        clk,
        reset,
        pcWriteEn,
        mainBus,
        pcOut
    );

    wire [SP_WIDTH-1:0] spOut;
    Register #(SP_WIDTH, {SP_WIDTH{1'b1}}) sp(
        clk,
        reset,
        spWriteEn,
        mainBus,
        spOut
    );

    wire [ADDR_WIDTH-1:0] dataAddr;
    Mux2 #(ADDR_WIDTH) dataAddrSelMux(
        .d0(mainBus),
        .d1(spOut),
        .sel(dataAddrSel),
        .out(dataAddr)
    );

    Mux2 #(ADDR_WIDTH) iOrDMux(
        .d0(pcOut),
        .d1(dataAddr),
        .sel(iOrD),
        .out(memAddrBus)
    );

    wire [DATA_WIDTH-1:0] memWriteRegIn;
    Mux2 #(DATA_WIDTH) swapBytesMux(
        .d0(mainBus[DATA_WIDTH-1:0]),
        .d1(mainBus[15:DATA_WIDTH]),
        .sel(byteSwapEn),
        .out(memWriteRegIn)
    );

    Register #(DATA_WIDTH, {DATA_WIDTH{1'b0}}) memWriteReg(
        .clk(clk),
        .reset(reset),
        .writeEn(dataRegWriteEn),
        .dataIn(memWriteRegIn),
        .dataOut(memWriteBus)
    );

    wire [INSTR_WIDTH-1:0] instrBus;
    assign instrBusOut = instrBus;
    Reg16ByteWrite instrReg(
        .clk(clk),
        .reset(reset),
        .reg1WriteEn(instrRegLowWriteEn),
        .reg2WriteEn(instrRegHighWriteEn),
        .dataIn(memReadBus),
        .dataOut(instrBus)
    );

    wire [DATA_WIDTH-1:0] memReadData;
    Register #(DATA_WIDTH, {DATA_WIDTH{1'b0}}) memReadReg(
        clk,
        reset,
        1'b1,
        memReadBus,
        memReadData
    );

    wire [7:0] reg1Out, reg2Out;
    wire [DATA_WIDTH-1:0] regWriteData;
    Mux4 #(DATA_WIDTH) regWriteDataMux(
        .d0(aluOutBus[DATA_WIDTH-1:0]),
        .d1(memReadData),
        .d2(instrBus[7:0]),
        .d3(reg2Out),
        .sel(regWriteSrcSel),
        .out(regWriteData)
    );

    wire [3:0] readAddr1;
    Mux2 #(4) regAddrSel1Mux(
        .d0(instrBus[11:8]),
        .d1(4'd14),
        .sel(readMemAddrFromReg),
        .out(readAddr1)
    );

    wire [3:0] readAddr2;
    Mux2 #(4) regAddrSel2Mux(
        .d0(instrBus[7:4]),
        .d1(4'd15),
        .sel(readMemAddrFromReg),
        .out(readAddr2)
    );

    RegisterFile #(
        .REG_COUNT(16),
        .DATA_WIDTH(DATA_WIDTH)
    ) registerFile(
        .clk(clk),
        .readAddr1(readAddr1),
        .readAddr2(readAddr2),
        .writeAddr(instrBus[11:8]),
        .writeData(regWriteData),
        .writeEn(regsWriteEn),
        .reg1(reg1Out),
        .reg2(reg2Out)
    );

    wire [15:0] aluSrc1;
    wire [3:0] flagRegOut;
    Mux4 #(16) aluSrc1SelMux(
        .d0(pcOut),
        .d1(spOut),
        .d2({8'b0, reg1Out}),
        .d3(flagRegOut),
        .sel(aluSrc1Sel),
        .out(aluSrc1)
    );

    wire [15:0] aluSrc2;
    Mux4 #(16) aluSrc2SelMux(
        .d0({8'b0, reg2Out}),
        .d1(16'd1),
        .d2(instrBus[7:0]),
        .d3(instrBus[11:0]),
        .sel(aluSrc2Sel),
        .out(aluSrc2)
    );

    wire [3:0] aluFlagsOut;
    wire [15:0] aluResult;
    ALU #(16, DATA_WIDTH) alu(
        .aluControl(aluControl),
        .src1(aluSrc1),
        .src2(aluSrc2),
        .flags(aluFlagsOut),
        .result(aluResult)
    );

    wire [3:0] flagSrc;
    Mux2 #(4) flagSrcSelMux(
        .d0(aluFlagsOut),
        .d1(memReadBus[3:0]),
        .sel(flagSrcSel),
        .out(flagSrc)
    );

    Register #(4, 8'b0) flagReg(
        .clk(clk),
        .reset(reset),
        .writeEn(flagsWriteEn),
        .dataIn(flagSrc),
        .dataOut(flagsOut)
    );

    assign flagsOut = flagRegOut;

    wire [15:0] aluOutRegOut;
    Register #(16, 8'b0) aluOutReg(
        .clk(clk),
        .reset(reset),
        .writeEn(aluOutWriteEn),
        .dataIn(aluResult),
        .dataOut(aluOutRegOut)
    );

    wire [15:0] aluOutBus;
    Mux2 #(16) aluOutSrcSelMux(
        .d0(aluResult),
        .d1(aluOutRegOut),
        .sel(aluOutSrcSel),
        .out(aluOutBus)
    );

    wire [15:0] regBus;
    assign regBus = {reg2Out[DATA_WIDTH-1:0], aluSrc1[DATA_WIDTH-1:0]};
    Mux2 #(16) regsOrAluSelMux(
        .d0(regBus),
        .d1(aluOutBus),
        .sel(regsOrAluSel),
        .out(mainBus)
    );
endmodule