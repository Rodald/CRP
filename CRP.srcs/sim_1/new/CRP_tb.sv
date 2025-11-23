`timescale 1ns / 1ps

module CRP_tb;
    localparam ADDR_WIDTH  = 15;
    localparam DATA_WIDTH  = 8;

    reg clk;
    reg reset;

    wire [DATA_WIDTH-1:0] memReadBus;
    wire [ADDR_WIDTH-1:0] memReqBus;
    wire memWriteReq;

    initial clk = 1;
    always #10 clk = ~clk;

    // DUT: CPU
//    CRP dut (
//        .clk(clk),
//        .reset(reset),
//        .memReadBus(memReadBus),
//        .memReqBus(memReqBus),
//        .memWriteReq(memWriteReq)
//    );
    wire [7:0] uio_oe;
    assign uio_oe = 8'b11111111;

    synth dut(
        .clk(clk),
        .ena(1'b1),
        .rst_n(~reset),
        .ui_in(memReadBus),
        .uio_in(8'b00000000),
        .uio_oe(uio_oe),
        .uio_out({memWriteReq, memReqBus[14:8]}),
        .uo_out(memReqBus[7:0])
    );
    
    SimpleMemory #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) mem (
        .clk(clk),
        .reset(reset),
        .memWriteReq(memWriteReq),
        .memReqBus(memReqBus),
        .read_data(memReadBus)
    );

    initial begin
        $display("=== START TESTS ===");
        testMovRegCheck();
        testAddCheck();
        testSubCheck();
        testAndCheck();
        testOrCheck();
        testXorCheck();
        testLdStCheck();
        testPushCheck();
        testPushPopCheck();
        testPushfCheck();
        testPopfCheck();
        testLsrCheck();
        testLslCheck();
        testAsrCheck();
        testCmpCheck();
        testCmpiCheck();
        testAddiCheck();
        testSubiCheck();
        testAndiCheck();
        testOriCheck();
        testXoriCheck();
        testRcallRetCheck();
        testMulCheck();
        testMul2Check();
        testMul3Check();
        testJeCheck();
        testJneCheck();
        testJmp1Check();
        testJmp2Check();
        testJmp3Check();
        testJmp4Check();
        testJmp5Check();
        testJmp6Check();
        testJmp7Check();
        testJmp8Check();
        testJmp9Check();
        testJmp10Check();
        testJmp11Check();
        testJmp12Check();

        $display("=== FINISHED TESTS ===");
        #20 $finish;
    end

    // GENERIC RUNNER TASK
    task runTest;
        input string testName;
        input int pulses;
        begin
            reset = 1;
            #15
            reset = 0;
            $display("--- Running test: %s ---", testName);



            // load file
            $readmemb({ "C:/Users/David/Desktop/Develop/programming/Vivado/CRP/CRP.srcs/sim_1/new/tests/", testName, ".mem" }, mem.mem);

            // has to stop at posedge or reset will be missaligned.
            // So just repeat posedge 35 times(every test gets 35 posedges)
            repeat (pulses) @(posedge clk);
        end
    endtask

    task assertRegister;
        input integer regIndex;
        input [DATA_WIDTH-1:0] expectedValue;
        begin
//            if (dut.datapath.registerFile.regs[regIndex] !== expectedValue) begin
//                $display("FAILED: R%0d Expected: %b (%0h), Got: %b (%0h)",
//                          regIndex, expectedValue, expectedValue,
//                          dut.datapath.registerFile.regs[regIndex],
//                          dut.datapath.registerFile.regs[regIndex]);
//            end else begin
//                $display("SUCCESS: R%0d = %b (%0h)", regIndex, expectedValue, expectedValue);
//            end
        end
    endtask

    task assertFlags;
        input [3:0] expectedFlags;
        begin
//            if (dut.datapath.flagRegOut !== expectedFlags) begin
//                $display("FAILED: Flags Expected: %b, Got: %b",
//                          expectedFlags, dut.datapath.flagRegOut);
//            end else begin
//                $display("SUCCESS: Flags = %b", expectedFlags);
//            end
        end
    endtask

    task assertSP;
        input [ADDR_WIDTH-1:0] expectedValue;
        begin
//            if (dut.datapath.spOut !== expectedValue) begin
//                $display("FAILED: SP Expected: %b, Got: %b",
//                          expectedValue, dut.datapath.spOut);
//            end else begin
//                $display("SUCCESS: SP = %b", expectedValue);
//            end
        end
    endtask

    task assertMem;
        input [ADDR_WIDTH-1:0] memAddr;
        input [DATA_WIDTH-1:0] expectedValue;
        begin
            if (mem.mem[memAddr] !== expectedValue) begin
                $display("FAILED: mem[%0d] Expected: %b (%0h), Got: %b (%0h)",
                          memAddr, expectedValue, expectedValue,
                          mem.mem[memAddr],
                          mem.mem[memAddr]);
            end else begin
                $display("SUCCESS: mem[%0d] = %b (%0h)", memAddr, expectedValue, expectedValue);
            end
        end
    endtask

    task testMovRegCheck;
        begin
            runTest("testMovReg", 25);
            assertMem(15'hff0, 8'b11111111);
        end
    endtask
    task testAddCheck;
        begin
            runTest("testAdd", 25);
            assertMem(15'hff0, 8'b11111110);
            assertMem(15'h7fff, 8'b00000110);
        end
    endtask
    task testSubCheck;
        begin
            runTest("testSub", 25);
            assertMem(15'hff0, 8'b00000000);
            assertMem(15'h7fff, 8'b00000001);
        end
    endtask
    task testAndCheck;
        begin
            runTest("testAnd", 25);
            assertMem(15'hff0, 8'b10001000);
            assertMem(15'h7fff, 8'b00000010);
        end
    endtask
    task testOrCheck;
        begin
            runTest("testOr", 25);
            assertMem(15'hff0, 8'b11101110);
            assertMem(15'h7fff, 8'b00000010);
        end
    endtask

    task testXorCheck;
        begin
            runTest("testXor", 25);

            assertMem(15'hff0, 8'b01100110);
            assertMem(15'h7fff, 8'b00000000);
        end
    endtask

    task testLdStCheck;
        begin
            runTest("testLdSt", 25);

            assertMem(15'h00FD, 8'h0c);
            assertRegister(4, 8'h0c);
        end
    endtask

    task testPushCheck;
        begin
            runTest("testPush", 25);

            assertMem(15'h7FFF, 8'hFF);
            assertSP(15'h7FFE);
        end
    endtask

    task testPushPopCheck;
        begin
            runTest("testPushPop", 25);

            assertMem(15'h7FFF, 8'd127);
            assertSP(15'h7FFF);

            assertRegister(0, 8'd127);
            assertRegister(1, 8'd127);
        end
    endtask

    task testPushfCheck;
        begin
            runTest("testPushf", 25);

            assertMem(15'h7FFF, 8'b00000101);
            assertSP(15'h7FFE);
        end
    endtask

    task testPopfCheck;
        begin
            runTest("testPopf", 25);

            assertMem(15'h7FFF, 8'b11111010);
            assertSP(15'h7FFF);
            assertFlags(4'b1010);
        end
    endtask

    task testLsrCheck;
        begin
            runTest("testLsr", 25);
            assertMem(15'hff0, 8'b00000011);
            assertMem(15'h7fff, 8'b00000000);
        end
    endtask
    task testLslCheck;
        begin
            runTest("testLsl", 25);

            assertMem(15'hff0, 8'b00000110);
            assertMem(15'h7fff, 8'b00000000);
        end
    endtask
    task testAsrCheck;
        begin
            runTest("testAsr", 40);

            assertMem(15'hff0, 8'b11000000);
            assertMem(15'h10f0, 8'hfa);

            assertMem(15'h7fff, 8'b00000010);
         end
    endtask
    task testCmpCheck;
        begin
            runTest("testCmp", 35);
            assertMem(15'hff0, 8'd10);
            assertMem(15'h10f0, 8'd20);

            assertMem(15'h7fff, 8'b00000110);
        end
    endtask
    task testCmpiCheck;
        begin
            runTest("testCmpi", 30);
            assertMem(15'hff0, 8'd50);

            assertMem(15'h7fff, 8'b00000001);
        end
    endtask
    task testAddiCheck;
        begin
            runTest("testAddi", 25);
            assertMem(15'hff0, 8'b11111111);
            assertMem(15'h7fff, 8'b00000010);
        end
    endtask
    task testSubiCheck;
        begin
            runTest("testSubi", 25);

            assertMem(15'hff0, 8'd206);
            assertMem(15'h7fff, 8'b00001110);
        end
    endtask
    task testAndiCheck;
        begin
            runTest("testAndi", 25);

            assertMem(15'hff0, 8'b00001010);
            assertMem(15'h7fff, 8'b00000000);
        end
    endtask
    task testOriCheck;
        begin
            runTest("testOri", 25);

            assertMem(15'hff0, 8'b00001011);
            assertMem(15'h7fff, 8'b00000000);
        end
    endtask
    task testXoriCheck;
        begin
            runTest("testXori", 25);

            assertMem(15'hff0, 8'b00000110);
            assertMem(15'h7fff, 8'b00000000);
        end
    endtask
    task testRcallRetCheck;
        begin
            runTest("testRcallRet", 30);

            assertMem(15'h7fff, 8'b00000010);
        end
    endtask
    task testMulCheck;
        begin
            runTest("testMul", 50);
            assertMem(15'h7fff, 8'b01010000);
        end
    endtask
    task testMul2Check;
        begin
            runTest("testMul2", 50);
            assertMem(15'h7fff, 8'b01010000);
        end
    endtask
    task testMul3Check;
        begin
            runTest("testMul3", 50);
            assertMem(15'h7fff, 8'b01010000);
        end
    endtask
    task testJeCheck;
        begin
            runTest("testJe", 50);
            assertMem(15'h7fff, 8'b00000000);
        end
    endtask

    task testJneCheck;
        begin
            runTest("testJne", 50);
            assertMem(15'h7fff, 8'b00000000);
        end
    endtask
    task testJmp1Check;
        begin
            runTest("testJmp1", 60);
            assertMem(15'h7fff, 8'b00001101);
        end
    endtask

    task testJmp2Check;
        begin
            runTest("testJmp2", 55);
            assertMem(15'h7fff, 8'b00010010);
        end
    endtask
    task testJmp3Check;
        begin
            runTest("testJmp3", 55);
            assertMem(15'h7fff, 8'b00010100);
        end
    endtask
    task testJmp4Check;
        begin
            runTest("testJmp4", 55);
            assertMem(15'h7fff, 8'b00010010);
        end
    endtask
    task testJmp5Check;
        begin
            runTest("testJmp5", 55);
            assertMem(15'h7fff, 8'b00001101);
        end
    endtask
    task testJmp6Check;
        begin
            runTest("testJmp6", 55);
            assertMem(15'h7fff, 8'b00010101);
        end
    endtask
    task testJmp7Check;
        begin
            runTest("testJmp7", 55);
            assertMem(15'h7fff, 8'b00010010);
        end
    endtask
    task testJmp8Check;
        begin
            runTest("testJmp8", 55);
            assertMem(15'h7fff, 8'b00010100);
        end
    endtask
    task testJmp9Check;
        begin
            runTest("testJmp9", 55);
            assertMem(15'h7fff, 8'b00010011);
        end
    endtask
    task testJmp10Check;
        begin
            runTest("testJmp10", 55);
            assertMem(15'h7fff, 8'b00001101);
        end
    endtask
    task testJmp11Check;
        begin
            runTest("testJmp11", 55);
            assertMem(15'h7fff, 8'b00010011);
        end
    endtask
    task testJmp12Check;
        begin
            runTest("testJmp12", 55);
            assertMem(15'h7fff, 8'b00010100);
        end
    endtask
endmodule