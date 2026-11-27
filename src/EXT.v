`timescale 1ns / 1ps

module EXT(
    input      [11:0] iimm,
    input      [11:0] simm,
    input      [2:0]  EXTOp,
    output reg [31:0] immout
);
    always @(*) begin
        case (EXTOp)
            3'b010:  immout = {{20{iimm[11]}}, iimm}; // I-type sign-extend
            3'b001:  immout = {{20{simm[11]}}, simm}; // S-type sign-extend
            default: immout = 32'b0;
        endcase
    end
endmodule
