module ALU #(
    parameter DATA_WIDTH = 15, // has to be higher than REG_DATA_WIDTH
    parameter REG_DATA_WIDTH = 8
)(
    input [2:0] aluControl,
    input [DATA_WIDTH-1:0] src1,
    input [DATA_WIDTH-1:0] src2,
    output reg [4-1:0] flags,
    output reg [DATA_WIDTH-1:0] result
);
    localparam ADD = 3'b000;
    localparam SUB_CMP = 3'b001;
    localparam AND = 3'b010;
    localparam OR  = 3'b011;
    localparam XOR = 3'b100;
    localparam LSL = 3'b101;
    localparam LSR = 3'b110;
    localparam ASR = 3'b111;

    wire sign_a = src1[REG_DATA_WIDTH-1];
    wire sign_b = src2[REG_DATA_WIDTH-1];
    wire sign_r = result[REG_DATA_WIDTH-1];

    // output wire contrains 8 data bits and the 9th carry/borrow bit
    reg signed [DATA_WIDTH-1:0] outputWire;

    always @(*) begin
        outputWire = 0;
        flags = 0;

        case (aluControl)
            ADD: outputWire = src1 + src2;
            SUB_CMP: outputWire = src1 - src2;
            AND: outputWire = src1[REG_DATA_WIDTH-1:0] & src2[REG_DATA_WIDTH-1:0];
            OR:  outputWire = src1[REG_DATA_WIDTH-1:0] | src2[REG_DATA_WIDTH-1:0];
            XOR: outputWire = src1[REG_DATA_WIDTH-1:0] ^ src2[REG_DATA_WIDTH-1:0];
            // only use first 3 bits for shiftig. No need to shift a num 255x
            LSL: outputWire[REG_DATA_WIDTH-1:0] = src1[REG_DATA_WIDTH-1:0] << src2[2:0];
            LSR: outputWire[REG_DATA_WIDTH-1:0] = src1[REG_DATA_WIDTH-1:0] >> src2[2:0];
            ASR: outputWire[REG_DATA_WIDTH-1:0] = $signed(src1[REG_DATA_WIDTH-1:0]) >>> src2[2:0];
            default: outputWire = {DATA_WIDTH{1'bx}};

        endcase

        result = outputWire[DATA_WIDTH-1:0];

        flags[0] = (result[REG_DATA_WIDTH-1:0] == 0);
        flags[1] = result[REG_DATA_WIDTH-1];
        flags[2] = outputWire[REG_DATA_WIDTH];
        // Overflow ADD: (+) + (+) = (-) or (-) + (-) = (+)
        // Overflow SUB: (+) - (-) = (-) or (-) - (+) = (+)
        flags[3] = (aluControl == ADD) ? (~sign_a & ~sign_b & sign_r) | (sign_a & sign_b & ~sign_r)
            : (aluControl == SUB_CMP) ? ( sign_a & ~sign_b & ~sign_r) | (~sign_a &  sign_b &  sign_r)
            : 1'b0;
    end
endmodule