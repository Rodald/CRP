module SimpleMemory #(
    parameter ADDR_WIDTH = 15,
    parameter DATA_WIDTH = 8,
    parameter MEM_DEPTH  = 1 << ADDR_WIDTH
)(
    input  wire                  clk, reset,
    input  wire                  memWriteReq,
    input  wire [ADDR_WIDTH-1:0] memReqBus,
    output reg  [DATA_WIDTH-1:0] read_data
);

    reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];
    integer i;
    reg [DATA_WIDTH-1:0] writeDataReg;
    reg                  writeState;

    // memory
    initial begin
        // mov reg0, 11111111
        mem[0] = 8'b11111111;
        mem[1] = 8'b0111_0000;

        // rcall
        mem[2] = 8'b00001000;
        mem[3] = 8'b1010_0000;

        // addi reg0, 1
        mem[4] = 8'b00000001;
        mem[5] = 8'b0010_0000;




        // addi reg0, 2
        mem[20] = 8'b00000010;
        mem[21] = 8'b0010_0000;

        // ret
        mem[22] = 8'b11010000;
        mem[23] = 8'b1001_1101;


        // add r0, r1
   //     mem[10] = 8'b00010001;
     //   mem[11] = 8'b0000_0000;

        // subi r2, 1
      //  mem[12] = 8'b00000001;
      //  mem[13] = 8'b0011_0010;

        // rjmp loop
      //  mem[14] = 8'b11111011;
    //    mem[15] = 8'b1000_1111;
    end

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            for (i = 0; i < MEM_DEPTH; i = i + 1)
                mem[i] <= 8'bx;
            writeState <= 1'b0;
        end else if (memWriteReq) begin
            // store 8 bits in writeDataReg
            writeDataReg <= memReqBus[7:0];
            writeState  <= 1'b1; // update current state
        end else if (writeState) begin
            mem[memReqBus] <= writeDataReg;
            writeState    <= 1'b0; // reset
        end
    end

    // Reading
    always @(*) begin
        read_data = mem[memReqBus];
    end

endmodule
