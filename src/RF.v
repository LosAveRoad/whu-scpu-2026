`timescale 1ns / 1ps

module RF(
    input         clk,
    input         rst,
    input         RFWr,
    input  [15:0] sw_i,
    input  [4:0]  A1,
    input  [4:0]  A2,
    input  [4:0]  A3,
    input  [31:0] WD,
    output [31:0] RD1,
    output [31:0] RD2
);
    reg [31:0] rf [31:0];
    integer i;

    // Combinational read; x0 is hardwired to 0
    assign RD1 = (A1 != 5'b0) ? rf[A1] : 32'b0;
    assign RD2 = (A2 != 5'b0) ? rf[A2] : 32'b0;

    // Synchronous write on posedge clk (active-high or active-low reset handled in top; here rst=1 resets)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                rf[i] <= 32'b0;
            end
        end else if (RFWr && (!sw_i[1]) && (A3 != 5'b0)) begin
            rf[A3] <= WD;
        end
    end
endmodule
