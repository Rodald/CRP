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
