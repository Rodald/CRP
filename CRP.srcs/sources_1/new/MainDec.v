module MainDecoder #(
    parameter OPCODE_WIDTH = 4,
    parameter FUNC_WIDTH = 4,
    parameter FLAGS_WIDTH = 4,
    parameter CONTROL_WIDTH = 20
)(
    input wire [OPCODE_WIDTH-1:0] opcode,
    input wire [OPCODE_WIDTH-1:0] func,
    input wire [FLAGS_WIDTH-1:0] flags,
    input wire [2:0] state,
    output wire resetState, // set if the current instruction is completed

    // control signals
    output wire dataAddrSel,
    output wire iOrD,
    output wire readMemAddrFromReg,   // controls if the register file should read the targeted memory addr.
    output wire flagSrcSel,
    output wire regsOrAluSel, // done
    output wire byteSwapEn,   // done HorL

    output wire [1:0] regWriteSrcSel, // done memToReg
    output wire [1:0] aluSrc1Sel, // done
    output wire [1:0] aluSrc2Sel, // done


    // write signals
    output wire pcWriteEn, // done
    output wire spWriteEn, // done
    output wire instrRegLowWriteEn, // fetching
    output wire instrRegHighWriteEn, // fetching
    output wire regsWriteEn, // done
    output wire flagsWriteEn,
    output wire memWriteReq
);

    localparam [2*CONTROL_WIDTH-1:0] FETCH_DATA = {
        20'b0_x_0_x_x_1_0_xx_00_01_1_0_0_1_0_0_0,
        20'b0_x_0_x_x_1_0_xx_00_01_1_0_1_0_0_0_0
    };
    localparam [1*CONTROL_WIDTH-1:0] ALU_IMM_COMMON = 20'b1_x_x_0_0_x_x_00_10_10_0_0_0_0_1_1_0; // make this work
    localparam [1*CONTROL_WIDTH-1:0] CMPI_DATA = 20'b1_x_x_0_0_x_x_xx_10_10_0_0_0_0_0_1_0;
    localparam [1*CONTROL_WIDTH-1:0] MOVI_DATA = 20'b1_x_x_0_x_x_x_10_xx_xx_0_0_0_0_1_0_0;
    localparam [1*CONTROL_WIDTH-1:0] RJMP_DATA = 20'b1_x_x_x_x_1_x_xx_00_11_1_0_0_0_0_0_0;
    localparam [5*CONTROL_WIDTH-1:0] RET_DATA = {
        20'b1_x_x_0_x_0_x_xx_00_xx_1_0_0_0_0_0_0, // write pc lower & trashReg in pc
        20'b0_x_x_0_x_0_x_01_10_xx_1_0_0_0_1_0_0, // write from dataReadReg in trash reg
        20'b0_1_1_x_x_x_0_01_xx_xx_0_0_0_0_1_0_0, // write from dataReadReg in trash reg & read
        20'b0_1_1_x_x_1_0_xx_01_01_0_1_0_0_0_0_0, // add sp + 1 & read
        20'b0_x_x_x_x_1_x_xx_01_01_0_1_0_0_0_0_0 // add sp + 1
    };
    localparam [4*CONTROL_WIDTH-1:0] RCALL_DATA = {
        20'b1_1_1_x_x_1_0_xx_01_01_0_1_0_0_0_0_0, // sub (sp - 1)
        20'b0_0_0_x_x_1_0_xx_00_11_1_0_0_0_0_0_1, // ADD(jmp)
        20'b0_1_1_x_x_1_0_xx_01_01_0_1_0_0_0_0_0, // sub (sp - 1)
        20'b0_0_0_x_x_x_1_xx_xx_xx_0_0_0_0_0_0_1
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
    assign {resetState, dataAddrSel, iOrD, readMemAddrFromReg, flagSrcSel,
        regsOrAluSel, byteSwapEn, regWriteSrcSel, aluSrc1Sel, aluSrc2Sel,
        pcWriteEn, spWriteEn, instrRegLowWriteEn,
        instrRegHighWriteEn, regsWriteEn, flagsWriteEn, memWriteReq
    } = controls;

    wire [CONTROL_WIDTH-1:0] rTypeControl;
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
                            3'd6: controls = RET_DATA[4*CONTROL_WIDTH +:CONTROL_WIDTH];
                            default: controls = {CONTROL_WIDTH{1'b0}};
                        endcase
                    end
                    RCALL: begin
                        case (state)
                            3'd2: controls = RCALL_DATA[0*CONTROL_WIDTH +:CONTROL_WIDTH];
                            3'd3: controls = RCALL_DATA[1*CONTROL_WIDTH +:CONTROL_WIDTH];
                            3'd4: controls = RCALL_DATA[2*CONTROL_WIDTH +:CONTROL_WIDTH];
                            3'd5: controls = RCALL_DATA[3*CONTROL_WIDTH +:CONTROL_WIDTH];
                            default: controls = {CONTROL_WIDTH{1'b0}};
                        endcase
                    end
                    JE: begin
                        case ({flags[0], state})
                            {1'd1, 3'd2}: controls = rjmpDataWire;
                            default: controls = 20'b1_x_x_x_x_x_x_xx_xx_xx_0_0_0_0_0_0_0;
                        endcase
                    end
                    JNE: begin
                        case ({flags[0], state})
                            {1'd0, 3'd2}: controls = rjmpDataWire;
                            default: controls = 20'b1_x_x_x_x_x_x_xx_xx_xx_0_0_0_0_0_0_0;
                        endcase
                    end
                    JB: begin
                        case ({flags[2], state})
                            {1'd1, 3'd2}: controls = rjmpDataWire;
                            default: controls = 20'b1_x_x_x_x_x_x_xx_xx_xx_0_0_0_0_0_0_0;
                        endcase
                    end
                    JAE: begin
                        case ({flags[2], state})
                            {1'd0, 3'd2}: controls = rjmpDataWire;
                            default: controls = 20'b1_x_x_x_x_x_x_xx_xx_xx_0_0_0_0_0_0_0;
                        endcase
                    end
                    JL: begin
                        case ({flags[1] ^ flags[3], state})
                            {1'd1, 3'd2}: controls = rjmpDataWire;
                            default: controls = 20'b1_x_x_x_x_x_x_xx_xx_xx_0_0_0_0_0_0_0;
                        endcase
                    end
                    default: controls = {CONTROL_WIDTH{1'bx}};
                endcase
            end
        endcase
    end
endmodule





module RTypeDecoder # (
    parameter FUNC_WIDTH = 4,
    parameter CONTROL_WIDTH = 22
) (
    input [FUNC_WIDTH-1:0] func,
    input [2:0] state,
    output reg [CONTROL_WIDTH-1:0] controls
);
    localparam [1*CONTROL_WIDTH-1:0] ALU_REG_COMMON = {20'b1_x_x_0_0_x_x_00_10_00_0_0_0_0_1_1_0};
    localparam [1*CONTROL_WIDTH-1:0] MOV_DATA = {20'b1_x_x_0_x_x_x_11_xx_xx_0_0_0_0_1_0_0};
    localparam [2*CONTROL_WIDTH-1:0] LD_DATA = {
        20'b1_x_x_x_x_x_x_01_xx_xx_0_0_0_0_1_0_0,
        20'b0_0_1_1_x_0_0_xx_10_00_0_0_0_0_0_0_0
    };
    localparam [2*CONTROL_WIDTH-1:0] ST_DATA = {
        20'b1_0_1_1_x_0_0_xx_10_00_0_0_0_0_0_0_0,
        20'b0_0_1_0_x_0_0_xx_10_xx_0_0_0_0_0_0_1
    };
    localparam [2*CONTROL_WIDTH-1:0] PUSH_DATA = {
        20'b1_1_1_x_x_1_0_xx_01_01_0_1_0_0_0_0_0,
        20'b0_0_1_0_x_0_0_xx_10_xx_0_0_0_0_0_0_1
    };
    localparam [3*CONTROL_WIDTH-1:0] POP_DATA = {
        20'b1_x_x_x_x_x_x_01_xx_xx_0_0_0_0_1_0_0,
        20'b0_1_1_x_x_x_0_xx_xx_xx_0_0_0_0_0_0_0,
        20'b0_x_x_x_x_1_x_xx_01_01_0_1_0_0_0_0_0
    };
    localparam [2*CONTROL_WIDTH-1:0] PUSHF_DATA = {
        20'b1_1_1_x_x_1_0_xx_01_01_0_1_0_0_0_0_0,
        20'b0_0_1_x_x_0_0_xx_11_xx_0_0_0_0_0_0_1
    };
    localparam [2*CONTROL_WIDTH-1:0] POPF_DATA = {
        20'b1_1_1_x_1_x_0_xx_xx_xx_0_0_0_0_0_1_0,
        20'b0_x_x_x_x_1_x_xx_01_01_0_1_0_0_0_0_0
    };
    localparam [1*CONTROL_WIDTH-1:0] CMP_DATA  = {20'b1_x_x_0_0_x_x_xx_10_00_0_0_0_0_0_1_0};

    localparam MOV   = 4'b0000;
    localparam ADD   = 4'b0001;
    localparam SUB   = 4'b0010;
    localparam AND   = 4'b0011;
    localparam OR    = 4'b0100;
    localparam XOR   = 4'b0101;
    localparam LD    = 4'b0110;
    localparam ST    = 4'b0111;
    localparam PUSH  = 4'b1000;
    localparam POP   = 4'b1001;
    localparam PUSHF = 4'b1010;
    localparam POPF  = 4'b1011;
    localparam LSR   = 4'b1100;
    localparam LSL   = 4'b1101;
    localparam ASR   = 4'b1110;
    localparam CMP   = 4'b1111;

    always @(*) begin
        case (func)
            ADD, SUB, AND, OR, XOR, LSR, LSL, ASR: begin
                case (state)
                    3'd2: controls = ALU_REG_COMMON[0*CONTROL_WIDTH +:CONTROL_WIDTH];
                    default: controls = {CONTROL_WIDTH{1'b0}};
                endcase
            end
            MOV: begin
                case (state)
                    3'd2: controls = MOV_DATA[0*CONTROL_WIDTH +:CONTROL_WIDTH];
                    default: controls = {CONTROL_WIDTH{1'b0}};
                endcase
            end
            LD: begin
                case (state)
                    3'd2: controls = LD_DATA[0*CONTROL_WIDTH +:CONTROL_WIDTH];
                    3'd3: controls = LD_DATA[1*CONTROL_WIDTH +:CONTROL_WIDTH];
                    default: controls = {CONTROL_WIDTH{1'b0}};
                endcase
            end
            ST: begin
                case (state)
                    3'd2: controls = ST_DATA[0*CONTROL_WIDTH +:CONTROL_WIDTH];
                    3'd3: controls = ST_DATA[1*CONTROL_WIDTH +:CONTROL_WIDTH];
                    default: controls = {CONTROL_WIDTH{1'b0}};
                endcase
            end
            PUSH: begin
                case (state)
                    3'd2: controls = PUSH_DATA[0*CONTROL_WIDTH +:CONTROL_WIDTH];
                    3'd3: controls = PUSH_DATA[1*CONTROL_WIDTH +:CONTROL_WIDTH];
                    default: controls = {CONTROL_WIDTH{1'b0}};
                endcase
            end
            POP: begin
                case (state)
                    3'd2: controls = POP_DATA[0*CONTROL_WIDTH +:CONTROL_WIDTH];
                    3'd3: controls = POP_DATA[1*CONTROL_WIDTH +:CONTROL_WIDTH];
                    3'd4: controls = POP_DATA[2*CONTROL_WIDTH +:CONTROL_WIDTH];
                    default: controls = {CONTROL_WIDTH{1'b0}};
                endcase
            end
            PUSHF: begin
                case (state)
                    3'd2: controls = PUSHF_DATA[0*CONTROL_WIDTH +:CONTROL_WIDTH];
                    3'd3: controls = PUSHF_DATA[1*CONTROL_WIDTH +:CONTROL_WIDTH];
                    default: controls = {CONTROL_WIDTH{1'b0}};
                endcase
            end
            POPF: begin
                case (state)
                    3'd2: controls = POPF_DATA[0*CONTROL_WIDTH +:CONTROL_WIDTH];
                    3'd3: controls = POPF_DATA[1*CONTROL_WIDTH +:CONTROL_WIDTH];
                    default: controls = {CONTROL_WIDTH{1'b0}};
                endcase
            end
            CMP: begin
                case (state)
                    3'd2: controls = CMP_DATA[0*CONTROL_WIDTH +:CONTROL_WIDTH];
                    default: controls = {CONTROL_WIDTH{1'b0}};
                endcase
            end
            default: controls = {CONTROL_WIDTH{1'b0}};
        endcase
    end
endmodule