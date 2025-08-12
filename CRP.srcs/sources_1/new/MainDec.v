


module MainDecoder #(
    parameter OPCODE_WIDTH = 4,
    parameter FUNC_WIDTH = 4,
    parameter FLAGS_WIDTH = 4,
    parameter CONTROL_WIDTH = 27
)(
    input wire [OPCODE_WIDTH-1:0] opcode,
    input wire [OPCODE_WIDTH-1:0] func,
    input wire [FLAGS_WIDTH-1:0] flags,
    input wire [2:0] state,

    // control signals
    output wire dataAddrSel,
    output wire iOrD,
    output wire readMemAddrReg,   // controls if the register file should read the targeted memory addr.
    output wire flagSrcSel,
    output wire aluOutSrcSel,
    output wire regsOrAluSel, // done
    output wire byteSwapEn,   // done HorL

    output wire [1:0] regWriteSrcSel, // done memToReg
    output wire [1:0] aluSrc1Sel, // done
    output wire [1:0] aluSrc2Sel, // done


    // write signals
    output wire pcWriteEn, // done
    output wire spWriteEn, // done
    output wire dataRegWriteEn, // done
    output wire instrRegLowWriteEn, // fetching
    output wire instrRegHighWriteEn, // fetching
    output wire regsWriteEn, // done
    output wire flagsWriteEn,
    output wire aluOutWriteEn,
    output wire memWriteEn
);

    localparam [2*CONTROL_WIDTH-1:0] FETCH_DATA = {
        27'bxx_xxxx_xxx_xx_xx_xx_x_x_x_x_x_1_x_x,
        27'bxx_xxxx_xxx_xx_xx_xx_x_x_x_x_1_0_x_x
    };
    localparam [1*CONTROL_WIDTH-1:0] ALU_IMM_COMMON = 27'bxx_11xx_xxx_10_10_00_x_x_0_0_x_x_x;
    localparam [1*CONTROL_WIDTH-1:0] CMPI_DATA = 27'bxx_1xxx_xxx_10_10_xx_x_x_x_0_x_x_x;
    localparam [1*CONTROL_WIDTH-1:0] MOVI_DATA = 27'bxx_x1xx_xxx_xx_xx_10_x_x_x_x_x_x_x;
    localparam [1*CONTROL_WIDTH-1:0] RJMP_DATA = 27'bxx_xxxx_xx1_11_00_xx_x_1_0_x_x_x_x;
    localparam [5*CONTROL_WIDTH-1:0] RET_DATA = {
        27'bxx_xxxx_xx1_xx_01_xx_x_0_x_x_0_x_x,
        27'bxx_xxxx_xx1_xx_10_01_x_0_x_x_0_x_x,
        27'bxx_x1xx_xxx_xx_xx_01_x_x_x_x_x_1_1,
        27'bxx_xxxx_x1x_01_01_xx_x_1_0_x_x_1_1,
        27'bxx_xxxx_x1x_01_01_xx_x_1_0_x_x_x_x
    };
    localparam [4*CONTROL_WIDTH-1:0] RCALL_DATA = {
        27'bx1_xxxx_1xx_01_01_xx_1_1_0_x_x_x_x,
        27'b1x_xxxx_x1x_01_01_xx_x_1_0_x_x_1_1,
        27'bxx_xxxx_1xx_xx_xx_xx_0_1_1_x_x_x_x,
        27'b1x_x1xx_x1x_01_01_xx_x_1_0_x_x_1_1
    };

    localparam RTYPE = 4'b0000;
    localparam CMPI  = 4'b0001;
    localparam ADDI  = 4'b0010;
    localparam SUBI  = 4'b0011;
    localparam ANDI  = 4'b0100;
    localparam ORI   = 4'b0101;
    localparam XORI  = 4'b0110;
    localparam MOV   = 4'b0111;
    localparam RJMP  = 4'b1000;
    localparam RET   = 4'b1001;
    localparam RCALL = 4'b1010;
    localparam JE    = 4'b1011; // jmp equal
    localparam JNE   = 4'b1100; // jmp not equal
    localparam JB    = 4'b1101; // jmp below (unsigned)
    localparam JAE   = 4'b1110; // jmp above or equal (unsigned)
    localparam JL    = 4'b1111; // jmp lower (signed)

    reg [CONTROL_WIDTH-1:0] controls;
    assign {dataAddrSel, iOrD, readMemAddrReg, flagSrcSel, aluOutSrcSel,
        regsOrAluSel, byteSwapEn, regWriteSrcSel, aluSrc1Sel, aluSrc2Sel,
        pcWriteEn, spWriteEn, dataRegWriteEn, instrRegLowWriteEn,
        instrRegHighWriteEn, regsWriteEn, flagsWriteEn, aluOutWriteEn, memWriteEn
    } = controls;

    wire rTypeControl;
    RTypeDecoder #(.FUNC_WIDTH(FUNC_WIDTH), .CONTROL_WIDTH(CONTROL_WIDTH)) rTypeDecoder(func, state, rTypeControl);

    wire [CONTROL_WIDTH-1:0] rjmpDataWire;
    assign rjmpDataWire = RJMP_DATA[0*CONTROL_WIDTH +:CONTROL_WIDTH];

    always @(*) begin

        case (state)
            3'd0: controls = FETCH_DATA[0*CONTROL_WIDTH +:CONTROL_WIDTH];
            3'd1: controls = FETCH_DATA[1*CONTROL_WIDTH +:CONTROL_WIDTH];
            default: begin
                case (opcode)
                    RTYPE: controls = rTypeControl;
                    ADDI, SUBI, ANDI, ORI, XORI: begin
                        case (state)
                            3'd2: controls = ALU_IMM_COMMON[0*CONTROL_WIDTH +:CONTROL_WIDTH];
                            default: controls = {CONTROL_WIDTH{1'b0}};
                        endcase
                    end
                    CMPI: begin
                        case (state)
                            3'd2: controls = CMPI_DATA[0*CONTROL_WIDTH +:CONTROL_WIDTH];
                            default: controls = {CONTROL_WIDTH{1'b0}};
                        endcase
                    end
                    MOV: begin
                        case (state)
                            3'd2: controls = MOVI_DATA[0*CONTROL_WIDTH +:CONTROL_WIDTH];
                            default: controls = {CONTROL_WIDTH{1'b0}};
                        endcase
                    end
                    RJMP: begin
                        case (state)
                            3'd2: controls = rjmpDataWire;
                            default: controls = {CONTROL_WIDTH{1'b0}};
                        endcase
                    end
                    RET: begin
                        case (state)
                            3'd2: controls = RET_DATA[0*CONTROL_WIDTH +:CONTROL_WIDTH];
                            3'd3: controls = RET_DATA[1*CONTROL_WIDTH +:CONTROL_WIDTH];
                            3'd4: controls = RET_DATA[2*CONTROL_WIDTH +:CONTROL_WIDTH];
                            3'd5: controls = RET_DATA[3*CONTROL_WIDTH +:CONTROL_WIDTH];
                            default: controls = {CONTROL_WIDTH{1'b0}};
                        endcase
                    end
                    RCALL: begin
                        case (state)
                            3'd2: controls = RCALL_DATA[0*CONTROL_WIDTH +:CONTROL_WIDTH];
                            3'd3: controls = RCALL_DATA[1*CONTROL_WIDTH +:CONTROL_WIDTH];
                            3'd4: controls = RCALL_DATA[2*CONTROL_WIDTH +:CONTROL_WIDTH];
                            default: controls = {CONTROL_WIDTH{1'b0}};
                        endcase
                    end
                    JE: begin
                        case ({flags[0], state})
                            {1'd1, 3'd2}: controls = rjmpDataWire;
                            default: controls = {CONTROL_WIDTH{1'b0}};
                        endcase
                    end
                    JNE: begin
                        case ({flags[0], state})
                            {1'd0, 3'd2}: controls = rjmpDataWire;
                            default: controls = {CONTROL_WIDTH{1'b0}};
                        endcase
                    end
                    JB: begin
                        case ({flags[2], state})
                            {1'd1, 3'd2}: controls = rjmpDataWire;
                            default: controls = {CONTROL_WIDTH{1'b0}};
                        endcase
                    end
                    JAE: begin
                        case ({flags[2], state})
                            {1'd0, 3'd2}: controls = rjmpDataWire;
                            default: controls = {CONTROL_WIDTH{1'b0}};
                        endcase
                    end
                    JL: begin
                        case ({flags[1] ^ flags[3], state})
                            {1'd1, 3'd2}: controls = rjmpDataWire;
                            default: controls = {CONTROL_WIDTH{1'b0}};
                        endcase
                    end
                    default: controls = {CONTROL_WIDTH{1'bx}};
                endcase
            end
        endcase
    end
endmodule