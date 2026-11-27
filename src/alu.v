`timescale 1ns / 1ps

`define ALUOp_add 5'b00011
`define ALUOp_sub 5'b00100

module alu(
    input  signed [31:0] A,
    input  signed [31:0] B,
    input         [4:0]  ALUOp,
    output reg signed [31:0] C,
    output        [7:0]  Zero
);
    always @(*) begin
        case (ALUOp)
            `ALUOp_add: C = A + B;
            `ALUOp_sub: C = A - B;
            default:    C = 32'b0;
        endcase
    end

    assign Zero = (C == 32'b0) ? 8'h01 : 8'h00;
endmodule
