module Datapath #(
    parameter ADDR_WIDTH = 15,
    parameter PC_WIDTH = ADDR_WIDTH,
    parameter SP_WIDTH = ADDR_WIDTH,
    parameter DATA_WIDTH = 8,
    parameter INSTR_WIDTH = 16
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
    input wire instrRegLowWriteEn,
    input wire instrRegHighWriteEn,
    input wire regsWriteEn,
    input wire flagsWriteEn,
    input wire aluOutWriteEn,

    // memory
    input wire [DATA_WIDTH-1:0] memReadBus,
    output wire [ADDR_WIDTH-1:0] memReqBus,

    // flags
    output wire [3:0] flagsOut,
    output wire [INSTR_WIDTH-1:0] instrBusOut
);
    wire [14:0] mainBus;

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

    wire [ADDR_WIDTH-1:0] iOrDMuxOut;
    Mux2 #(ADDR_WIDTH) iOrDMux(
        .d0(pcOut),
        .d1(dataAddr),
        .sel(iOrD),
        .out(iOrDMuxOut)
    );


    Mux2 #(ADDR_WIDTH) swapBytesMux(
        .d0(iOrDMuxOut[ADDR_WIDTH-1:0]),
        .d1({iOrDMuxOut[6:0], 1'b0, iOrDMuxOut[14:8]}),
        // also try this:
        //.d1({iOrDMuxOut[7:0], iOrDMuxOut[14:8]}),
        .sel(byteSwapEn),
        .out(memReqBus)
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
        .d2(instrBus[DATA_WIDTH-1:0]),
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

    wire [14:0] aluSrc1;
    wire [3:0] flagRegOut;
    Mux4 #(15) aluSrc1SelMux(
        .d0(pcOut),
        .d1(spOut),
        .d2({7'b0, reg1Out}),
        .d3({11'b0, flagRegOut}),
        .sel(aluSrc1Sel),
        .out(aluSrc1)
    );

    wire [ADDR_WIDTH-1:0] signExtOut;
    SignExt #(.IN_WIDTH(12), .OUT_WIDTH(ADDR_WIDTH)) signExt(
        .in(instrBus[11:0]),
        .out(signExtOut)
    );

    wire [ADDR_WIDTH-1:0] shiftLeftOut;
    ShiftLeft1 #(.DATA_WIDTH(ADDR_WIDTH)) shiftLeft1(
        .in(signExtOut),
        .out(shiftLeftOut)
    );

    wire [14:0] aluSrc2;
    Mux4 #(15) aluSrc2SelMux(
        .d0({7'b0, reg2Out}),
        .d1(15'd1),
        .d2({7'b0, instrBus[7:0]}),
        .d3(shiftLeftOut),
        .sel(aluSrc2Sel),
        .out(aluSrc2)
    );

    wire [3:0] aluFlagsOut;
    wire [14:0] aluResult;
    ALU #(15, DATA_WIDTH) alu(
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

    Register #(4, 4'b0) flagReg(
        .clk(clk),
        .reset(reset),
        .writeEn(flagsWriteEn),
        .dataIn(flagSrc),
        .dataOut(flagRegOut)
    );

    assign flagsOut = flagRegOut;

    wire [14:0] aluOutRegOut;
    Register #(15, 15'b0) aluOutReg(
        .clk(clk),
        .reset(reset),
        .writeEn(aluOutWriteEn),
        .dataIn(aluResult),
        .dataOut(aluOutRegOut)
    );

    wire [14:0] aluOutBus;
    Mux2 #(15) aluOutSrcSelMux(
        .d0(aluResult),
        .d1(aluOutRegOut),
        .sel(aluOutSrcSel),
        .out(aluOutBus)
    );

    wire [14:0] regBus;
    // chop off last bit from reg2 (addrWidth is only 15 bit)
    assign regBus = {reg2Out[DATA_WIDTH-2:0], aluSrc1[DATA_WIDTH-1:0]};
    Mux2 #(15) regsOrAluSelMux(
        .d0(regBus),
        .d1(aluOutBus),
        .sel(regsOrAluSel),
        .out(mainBus)
    );
endmodule