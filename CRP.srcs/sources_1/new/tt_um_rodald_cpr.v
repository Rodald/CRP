module tt_um_rodald_cpr (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    wire [14:0] memReqBus;
    wire memWriteReq;

    CRP crp (
        .clk(clk),
        .reset(~rst_n),  // TinyTapeout uses inverted reset
        .memReadBus(ui_in),
        .memReqBus(memReqBus),
        .memWriteReq(memWriteReq)
    );

    assign uo_out      = memReqBus[7:0];
    assign uio_out[6:0] = memReqBus[14:8];
    assign uio_out[7]  = memWriteReq;
    assign uio_oe = 8'b11111111;

endmodule
