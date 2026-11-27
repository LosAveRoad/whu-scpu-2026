`timescale 1ns / 1ps

// Behavioral ROM stub for iverilog/Linux simulation (mirrors Vivado dist_mem_im IP)
module dist_mem_im(
    input      [5:0]  a,
    output reg [31:0] spo
);
    always @(*) begin
        case (a)
            6'd0:  spo = 32'h000000b3; // add  x1, x0, x0
            6'd1:  spo = 32'h00108093; // addi x1, x1, 1
            6'd2:  spo = 32'h00000133; // add  x2, x0, x0
            6'd3:  spo = 32'h00210113; // addi x2, x2, 2
            6'd4:  spo = 32'h000001b3; // add  x3, x0, x0
            6'd5:  spo = 32'h00318193; // addi x3, x3, 3
            6'd6:  spo = 32'h001020a3; // sw   x1, 1(x0)
            6'd7:  spo = 32'h00202123; // sw   x2, 2(x0)
            6'd8:  spo = 32'h003021a3; // sw   x3, 3(x0)
            6'd9:  spo = 32'h00102203; // lw   x4, 1(x0) -> 0x00030201
            6'd10: spo = 32'h00202283; // lw   x5, 2(x0) -> 0x00000302
            6'd11: spo = 32'h00302303; // lw   x6, 3(x0) -> 0x00000003
            default: spo = 32'h00000000;
        endcase
    end
endmodule
