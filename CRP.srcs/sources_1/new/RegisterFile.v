module RegisterFile #(
    parameter REG_COUNT = 16,
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = $clog2(REG_COUNT)
)(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] readAddr1,
    input wire [ADDR_WIDTH-1:0] readAddr2,
    input wire [ADDR_WIDTH-1:0] writeAddr,
    input wire [DATA_WIDTH-1:0] writeData,
    input wire writeEn,
    output wire [DATA_WIDTH-1:0] reg1,
    output wire [DATA_WIDTH-1:0] reg2
);
    reg [DATA_WIDTH-1:0] regs[REG_COUNT-1:0];

    always @ (posedge clk) begin
        if (writeEn) regs[writeAddr] <= writeData;
    end

    assign reg1 = regs[readAddr1];
    assign reg2 = regs[readAddr2];
endmodule