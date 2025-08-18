module ALUDec #(
    parameter OPCODE_WIDTH = 4,
    parameter FUNC_WIDTH = 4
)(
    input wire [OPCODE_WIDTH-1:0] opcode,
    input wire [FUNC_WIDTH-1:0] func,
    input wire [2:0] state,

    output reg [2:0] aluControl
);
    localparam RTYPE = 4'b0000;
    localparam CMPI  = 4'b0001;
    localparam ADDI  = 4'b0010;
    localparam SUBI  = 4'b0011;
    localparam ANDI  = 4'b0100;
    localparam ORI   = 4'b0101;
    localparam XORI  = 4'b0110;
    localparam RJMP  = 4'b1000;
    localparam RET   = 4'b1001;
    localparam RCALL = 4'b1010;
    localparam JE    = 4'b1011; // jmp equal
    localparam JNE   = 4'b1100; // jmp not equal
    localparam JB    = 4'b1101; // jmp below (unsigned)
    localparam JAE   = 4'b1110; // jmp above or equal (unsigned)
    localparam JL    = 4'b1111; // jmp lower (signed)

    localparam ADD_CTRL = 3'b000;
    localparam SUB_CTRL = 3'b001;
    localparam AND_CTRL = 3'b010;
    localparam OR_CTRL  = 3'b011;
    localparam XOR_CTRL = 3'b100;

    wire [2:0] rTypeControl;
    ALURtypeDec #(.FUNC_WIDTH(FUNC_WIDTH)) aluRtypeDec (func, state, rTypeControl);
    always @(*) begin
        case (opcode)
            RTYPE: aluControl = rTypeControl;
            CMPI, SUBI: begin
                case (state)
                    3'd2: aluControl = SUB_CTRL;
                    default: aluControl = 3'b000;
                endcase
            end
            ADDI, RJMP, JE, JNE, JB, JAE, JL: begin
                case (state)
                    3'd2: aluControl = ADD_CTRL;
                    default: aluControl = 3'b000;
                endcase
            end
            ANDI: begin
                case (state)
                    3'd2: aluControl = AND_CTRL;
                    default: aluControl = 3'b000;
                endcase
            end
            ORI: begin
                case (state)
                    3'd2: aluControl = OR_CTRL;
                    default: aluControl = 3'b000;
                endcase
            end
            XORI: begin
                case (state)
                    3'd2: aluControl = XOR_CTRL;
                    default: aluControl = 3'b000;
                endcase
            end
            RET: begin
                case (state)
                    3'd2: aluControl = ADD_CTRL;
                    3'd3: aluControl = ADD_CTRL;
                    default: aluControl = 3'b000;
                endcase
            end
            RCALL: begin
                case (state)
                    3'd3: aluControl = SUB_CTRL;
                    3'd4: aluControl = ADD_CTRL;
                    3'd5: aluControl = SUB_CTRL;
                    default: aluControl = 3'b000;
                endcase
            end

            default: aluControl = 3'b000;
        endcase
    end
endmodule


module ALURtypeDec #(
    parameter FUNC_WIDTH = 4
)(
    input [FUNC_WIDTH-1:0] func,
    input [2:0] state,
    output reg [2:0] aluControl
);
    localparam ADD   = 4'b0001;
    localparam SUB   = 4'b0010;
    localparam AND   = 4'b0011;
    localparam OR    = 4'b0100;
    localparam XOR   = 4'b0101;
    localparam PUSH  = 4'b1000;
    localparam POP   = 4'b1001;
    localparam PUSHF = 4'b1010;
    localparam POPF  = 4'b1011;
    localparam LSR   = 4'b1100;
    localparam LSL   = 4'b1101;
    localparam ASR   = 4'b1110;
    localparam CMP   = 4'b1111;

    localparam ADD_CTRL = 3'b000;
    localparam SUB_CTRL = 3'b001;
    localparam AND_CTRL = 3'b010;
    localparam OR_CTRL  = 3'b011;
    localparam XOR_CTRL = 3'b100;
    localparam LSL_CTRL = 3'b101;
    localparam LSR_CTRL = 3'b110;
    localparam ASR_CTRL = 3'b111;

    always @(*) begin
        case (func)
            ADD: begin
                case (state)
                    3'd2: aluControl = ADD_CTRL;
                    default: aluControl = 3'b000;
                endcase
            end
            SUB, CMP: begin
                case (state)
                    3'd2: aluControl = SUB_CTRL;
                    default: aluControl = 3'b000;
                endcase
            end
            AND: begin
                case (state)
                    3'd2: aluControl = AND_CTRL;
                    default: aluControl = 3'b000;
                endcase
            end
            OR: begin
                case (state)
                    3'd2: aluControl = OR_CTRL;
                    default: aluControl = 3'b000;
                endcase
            end
            XOR: begin
                case (state)
                    3'd2: aluControl = XOR_CTRL;
                    default: aluControl = 3'b000;
                endcase
            end
            PUSH, PUSHF: begin
                case (state)
                    3'd3: aluControl = SUB_CTRL;
                    default: aluControl = 3'b000;
                endcase
            end
            POP, POPF: begin
                case (state)
                    3'd2: aluControl = ADD_CTRL;
                    default: aluControl = 3'b000;
                endcase
            end
            LSR: begin
                case (state)
                    3'd2: aluControl = LSR_CTRL;
                    default: aluControl = 3'b000;
                endcase
            end
            LSL: begin
                case (state)
                    3'd2: aluControl = LSL_CTRL;
                    default: aluControl = 3'b000;
                endcase
            end
            ASR: begin
                case (state)
                    3'd2: aluControl = ASR_CTRL;
                    default: aluControl = 3'b000;
                endcase
            end
            default: aluControl = 3'b000;
        endcase
    end
endmodule