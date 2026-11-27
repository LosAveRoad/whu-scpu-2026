`timescale 1ns / 1ps

module EXT(
    input      [11:0] iimm,
    input      [11:0] simm,
    input      [12:0] bimm,
    input      [20:0] jimm,
    input      [2:0]  EXTOp,
    output reg [31:0] immout
);
    always @(*) begin
        case (EXTOp)
            3'b010:  immout = {{20{iimm[11]}}, iimm}; // I-type sign-extend
            3'b001:  immout = {{20{simm[11]}}, simm}; // S-type sign-extend
            3'b011:  immout = {{19{bimm[12]}}, bimm}; // B-type (low bit already 0)
            3'b100:  immout = {{11{jimm[20]}}, jimm}; // J-type (low bit already 0)
            default: immout = 32'b0;
        endcase
    end
endmodule
