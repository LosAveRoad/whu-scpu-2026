`timescale 1ns / 1ps

module ctrl(
    input  [6:0] Op,
    input  [6:0] Funct7,
    input  [2:0] Funct3,
    output       RegWrite,
    output       MemWrite,
    output [2:0] EXTOp,
    output [4:0] ALUOp,
    output       ALUSrc,
    output [2:0] DMType,
    output [1:0] WDSel,
    output [1:0] NPCOp
);
    // R-type: add, sub
    wire rtype   = ~Op[6] &  Op[5] &  Op[4] & ~Op[3] & ~Op[2] & Op[1] & Op[0]; // 0110011
    wire i_add   = rtype & (Funct7 == 7'b0000000) & (Funct3 == 3'b000);
    wire i_sub   = rtype & (Funct7 == 7'b0100000) & (Funct3 == 3'b000);

    // I-type Load: lb, lh, lw, lbu, lhu
    wire itype_l = ~Op[6] & ~Op[5] & ~Op[4] & ~Op[3] & ~Op[2] & Op[1] & Op[0]; // 0000011
    wire i_lb    = itype_l & (Funct3 == 3'b000);
    wire i_lh    = itype_l & (Funct3 == 3'b001);
    wire i_lw    = itype_l & (Funct3 == 3'b010);
    wire i_lbu   = itype_l & (Funct3 == 3'b100);
    wire i_lhu   = itype_l & (Funct3 == 3'b101);

    // I-type Arithmetic: addi
    wire itype_r = ~Op[6] & ~Op[5] &  Op[4] & ~Op[3] & ~Op[2] & Op[1] & Op[0]; // 0010011
    wire i_addi  = itype_r & (Funct3 == 3'b000);

    // S-type Store: sb, sh, sw
    wire stype   = ~Op[6] &  Op[5] & ~Op[4] & ~Op[3] & ~Op[2] & Op[1] & Op[0]; // 0100011
    wire i_sb    = stype & (Funct3 == 3'b000);
    wire i_sh    = stype & (Funct3 == 3'b001);
    wire i_sw    = stype & (Funct3 == 3'b010);

    // B-type branch: beq. J-type jump: jal.
    wire btype   = (Op == 7'b1100011);
    wire i_beq   = btype & (Funct3 == 3'b000);
    wire i_jal   = (Op == 7'b1101111);

    // Control signals
    assign RegWrite  = rtype | itype_r | itype_l | i_jal;
    assign MemWrite  = stype;
    assign ALUSrc    = itype_r | stype | itype_l; // beq compares rs1/rs2 (ALUSrc=0)
    assign WDSel[0]  = itype_l;                   // 01: DM(dout)
    assign WDSel[1]  = i_jal;                     // 10: PC+4

    // NPCOp: 00 sequential, 01 beq (qualified by Zero), 10 jal
    assign NPCOp     = i_jal ? 2'b10 : (i_beq ? 2'b01 : 2'b00);

    // ALUOp: 5'b00011 = ADD, 5'b00100 = SUB (aligned with 2026 Lecture 5 manual)
    assign ALUOp[4]  = 1'b0;
    assign ALUOp[3]  = 1'b0;
    assign ALUOp[2]  = i_sub | i_beq;
    assign ALUOp[1]  = i_add | i_addi | stype | itype_l;
    assign ALUOp[0]  = i_add | i_addi | stype | itype_l;

    // EXTOp: 001 S-type, 010 I-type, 011 B-type, 100 J-type
    assign EXTOp[2]  = i_jal;
    assign EXTOp[1]  = itype_l | itype_r | i_beq;
    assign EXTOp[0]  = stype | i_beq;

    // DMType: 000=lw/sw, 001=lh/sh, 010=lhu, 011=lb/sb, 100=lbu
    assign DMType[2] = i_lbu;
    assign DMType[1] = i_lb | i_sb | i_lhu;
    assign DMType[0] = i_lh | i_sh | i_lb | i_sb;

    // Keep i_lw/i_sw referenced to avoid unused-wire warnings
    wire _unused_ok = &{1'b0, i_lw, i_sw};
endmodule
