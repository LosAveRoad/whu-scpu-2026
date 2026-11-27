`timescale 1ns / 1ps

// Behavioral ROM stub for iverilog (replaces Vivado dist_mem_im).
//   default   : coe/test_2026.coe   (task 1)
//   -DROM_BEQ : coe/test_beq.coe    (task 2, Block 0)
//   -DROM_JAL : coe/test_jal.coe    (task 3, Block 6 rebased to PC 0)
// Port names match the Distributed Memory Generator ROM (async read): a, spo.
module dist_mem_im(
    input      [5:0]  a,
    output reg [31:0] spo
);
    always @(*) begin
        case (a)
`ifdef ROM_JAL
`include "rom_jal.vh"
`elsif ROM_BEQ
`include "rom_beq.vh"
`else
`include "rom_task1.vh"
`endif
            default: spo = 32'h00000000;
        endcase
    end
endmodule
