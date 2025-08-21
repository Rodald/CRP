`timescale 1ns / 1ps

`timescale 1ns / 1ps

module alu_crp_tb;

    parameter DATA_WIDTH = 8;

    reg  [3:0] aluControl;
    reg  [DATA_WIDTH-1:0] src1;
    reg  [DATA_WIDTH-1:0] src2;
    wire [3:0] flags; // use 4 bits only
    wire [DATA_WIDTH-1:0] result;

    ALU #(DATA_WIDTH) uut (
        .aluControl(aluControl),
        .src1(src1),
        .src2(src2),
        .flags(flags),
        .result(result)
    );

    task test_case(
        input [3:0] ctrl,
        input [DATA_WIDTH-1:0] a,
        input [DATA_WIDTH-1:0] b,
        input [DATA_WIDTH-1:0] expected_result,
        input [3:0] expected_flags,
        input [255:0] name
    );
        reg je, jne, jb, jae, jvc;
        begin
            aluControl = ctrl;
            src1 = a;
            src2 = b;
            #1;
            // compute jump conditions from flags (flags = {V,C,S,Z})
            je  = flags[0];          // Z == 1
            jne = ~flags[0];         // Z == 0
            jb  = flags[2];          // carry/borrow == 1  (unsigned a < b)
            jae = ~flags[2];         // carry == 0 (unsigned a >= b)
            jvc = ~flags[3];         // overflow clear

            $display("Test: %-28s A=%3d B=%3d => Result=%3d Flags=%b (Expect=%b) => %s",
                      name, a, b, result, flags, expected_flags,
                      (result === expected_result && flags === expected_flags) ? "correct" : "incorrect");

            $display("       Flags decode: Z=%b S=%b C=%b V=%b", flags[0], flags[1], flags[2], flags[3]);
            $display("       Jumps: JE=%b (%s), JNE=%b (%s), JB=%b (%s), JAE=%b (%s), JVC=%b (%s)",
                     je,  je  ? "jump" : "no",
                     jne, jne ? "jump" : "no",
                     jb,  jb  ? "jump" : "no",
                     jae, jae ? "jump" : "no",
                     jvc, jvc ? "jump" : "no");
            $display("");
        end
    endtask

    initial begin
        $display("Starting ALU Tests...\n");

        // === ADDITION (keep your original ones) ===
        test_case(4'b0000, 8'd0,   8'd0,   8'd0,   4'b0001, "ADD: 0 + 0");
        test_case(4'b0000, 8'd10,  8'd20,  8'd30,  4'b0000, "ADD: 10 + 20");
        test_case(4'b0000, 8'd255, 8'd1,   8'd0,   4'b0101, "ADD: 255 + 1 (carry, zero)");
        test_case(4'b0000, 8'd127, 8'd1,   8'd128, 4'b1010, "ADD: 127 + 1 (signed overflow + sign)");
        test_case(4'b0000, 8'd200, 8'd100, 8'd44,  4'b0100, "ADD: 200 + 100 (carry)");

        // === ORIGINAL SUBTESTS ===
        test_case(4'b0001, 8'd10,  8'd10,  8'd0,   4'b0001, "SUB: 10 - 10 = 0");
        test_case(4'b0001, 8'd20,  8'd30,  8'd246, 4'b0110, "SUB: 20 - 30 (borrow, negative)");
        test_case(4'b0001, 8'd128, 8'd1,   8'd127, 4'b1000, "SUB: 128 - 1 (signed overflow)");
        test_case(4'b0001, 8'd0,   8'd1,   8'd255, 4'b0110, "SUB: 0 - 1 (underflow to -1)");
        test_case(4'b0001, 8'd255, 8'd255, 8'd0,   4'b0001, "SUB: 255 - 255 = 0");

        // === ADDITIONAL SUB / CMP TESTS (unsigned + signed edge cases) ===

        // small positive no borrow, no overflow
        test_case(4'b0001, 8'd5,   8'd3,   8'd2,   4'b0000, "SUB: 5 - 3 (2)"); 
        // unsigned: borrow because 3>5? no -> C=0; JE=0,JNE=1,JB=0,JAE=1,JVC=1

        // unsigned borrow (a < b)
        test_case(4'b0001, 8'd3,   8'd5,   8'd254, 4'b0110, "SUB: 3 - 5 (254) (borrow, negative)");
        // here: Z=0,S=1,C=1,V=0 -> JE=0,JNE=1,JB=1,JAE=0,JVC=1

        // signed overflow: -128 - 1 => +127 with V=1
        test_case(4'b0001, 8'd128, 8'd1,   8'd127, 4'b1000, "SUB: -128 - 1 -> overflow (128-1)"); 
        // Z=0,S=0,C=0,V=1 -> JE=0,JNE=1,JB=0,JAE=1,JVC=0

        // signed overflow other direction: 127 - 255 => -128 (overflow)
        test_case(4'b0001, 8'd127, 8'd255, 8'd128, 4'b1110, "SUB: 127 - 255 -> -128 (overflow + carry)");
        // flags: V=1,C=1,S=1,Z=0 -> JE=0,JNE=1,JB=1,JAE=0,JVC=0

        // zero result
        test_case(4'b0001, 8'd7,   8'd7,   8'd0,   4'b0001, "SUB: 7 - 7 = 0 (zero)");

        // edge: 0 - 255 => 1 borrow, negative
        test_case(4'b0001, 8'd0,   8'd255, 8'd1,   4'b0100, "SUB: 0 - 255 -> 1? (unsigned wrap 1) actually 0 - 255 = 1 (borrow)"); 
        // note: 0 - 255 = 1 (0x00 - 0xFF = 0x01), flags show borrow etc.

        // edge: 200 - 100 (no overflow, carry depends)
        test_case(4'b0001, 8'd200, 8'd100, 8'd100, 4'b1000, "SUB: 200 - 100 (100) (carry?)");

        // === BITWISE & SHIFT tests (kept original ones) ===
        test_case(4'b0010, 8'b10101010, 8'b11001100, 8'b10001000, 4'b0010, "AND");
        test_case(4'b0011, 8'b10101010, 8'b11001100, 8'b11101110, 4'b0010, "OR");
        test_case(4'b0100, 8'b10101010, 8'b11001100, 8'b01100110, 4'b0000, "XOR");

        test_case(4'b0101, 8'b00000011, 8'd1, 8'b00000110, 4'b0000, "LSL");
        test_case(4'b0110, 8'b00000110, 8'd1, 8'b00000011, 4'b0000, "LSR");
        test_case(4'b0111, 8'b10000000, 8'd1, 8'b11000000, 4'b0010, "ASR");
        test_case(4'b0111, 8'b10101010, 8'd4, 8'hfa, 4'b0010, "ASR");

        $display("\nALU Tests finished.");
        $stop;
    end

endmodule

