`timescale 1ns / 1ps

module SCPU_TOP(
    input         clk,
    input         rstn,
    input  [15:0] sw_i,
    output [7:0]  disp_an_o,
    output [7:0]  disp_seg_o
);
    wire rst = ~rstn;

    // Word-address width of dist_mem_im.
    // 6 -> depth 64, a[5:0] = PC[7:2] (task1 / beq / jal).
    // 9 -> depth 512, a[8:0] = PC[10:2] (full Test_all.coe).
    localparam IM_AW = 6;

    // 1. Clock divider: SW[15]=1 -> 2^27 (slow), SW[15]=0 -> 2^25 (fast)
    reg [31:0] clkdiv;
    always @(posedge clk or posedge rst) begin
        if (rst) clkdiv <= 32'b0;
        else     clkdiv <= clkdiv + 1'b1;
    end

`ifdef SIMULATION
    wire Clk_CPU = clk;
`else
    wire Clk_CPU = sw_i[15] ? clkdiv[27] : clkdiv[25];
`endif

    // 2. Byte-addressed PC (reset 0, sequential +4).
    //    SW[1]=1 freezes PC (debug) as well as RF writes.
    reg  [31:0] PC;
    wire [31:0] pc_plus4 = PC + 32'd4;
    wire [31:0] NPC;

    always @(posedge Clk_CPU or posedge rst) begin
        if (rst)
            PC <= 32'h0000_0000;
        else if (!sw_i[1])
            PC <= NPC;
    end

    // 3. Instruction Memory (Vivado Distributed ROM IP: dist_mem_im)
    wire [31:0] instr;
    dist_mem_im U_IM(
        .a   (PC[IM_AW+1:2]),
        .spo (instr)
    );

    // Instruction fields
    wire [6:0]  Op     = instr[6:0];
    wire [6:0]  Funct7 = instr[31:25];
    wire [2:0]  Funct3 = instr[14:12];
    wire [4:0]  rs1    = instr[19:15];
    wire [4:0]  rs2    = instr[24:20];
    wire [4:0]  rd     = instr[11:7];
    wire [11:0] iimm   = instr[31:20];
    wire [11:0] simm   = {instr[31:25], instr[11:7]};
    // B-type: {imm[12], imm[11], imm[10:5], imm[4:1], 0}
    wire [12:0] bimm   = {instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
    // J-type: {imm[20], imm[19:12], imm[11], imm[10:1], 0}
    wire [20:0] jimm   = {instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

    // 4. Control Unit
    wire       RegWrite, MemWrite, ALUSrc;
    wire [2:0] EXTOp, DMType;
    wire [4:0] ALUOp;
    wire [1:0] WDSel, NPCOp;

    ctrl U_CTRL(
        .Op       (Op),
        .Funct7   (Funct7),
        .Funct3   (Funct3),
        .RegWrite (RegWrite),
        .MemWrite (MemWrite),
        .EXTOp    (EXTOp),
        .ALUOp    (ALUOp),
        .ALUSrc   (ALUSrc),
        .DMType   (DMType),
        .WDSel    (WDSel),
        .NPCOp    (NPCOp)
    );

    // 5. Immediate Extender
    wire [31:0] immout;
    EXT U_EXT(
        .iimm   (iimm),
        .simm   (simm),
        .bimm   (bimm),
        .jimm   (jimm),
        .EXTOp  (EXTOp),
        .immout (immout)
    );

    // 6. Register File
    wire [31:0] RD1, RD2, WD;
    RF U_RF(
        .clk  (Clk_CPU),
        .rst  (rst),
        .RFWr (RegWrite),
        .sw_i (sw_i),
        .A1   (rs1),
        .A2   (rs2),
        .A3   (rd),
        .WD   (WD),
        .RD1  (RD1),
        .RD2  (RD2)
    );

    // 7. ALU & ALUSrc MUX
    wire signed [31:0] B_in   = ALUSrc ? immout : RD2;
    wire signed [31:0] aluout;
    wire        [7:0]  Zero;

    alu U_alu(
        .A     (RD1),
        .B     (B_in),
        .ALUOp (ALUOp),
        .C     (aluout),
        .Zero  (Zero)
    );

    // 8. Data Memory
    wire [31:0] dout;
    dm U_DM(
        .clk    (Clk_CPU),
        .DMWr   (MemWrite),
        .addr   (aluout[5:0]),
        .din    (RD2),
        .DMType (DMType),
        .dout   (dout)
    );

    // 9. Next PC
    //    NPCOp 00: PC+4    01: beq (PC+imm when Zero)    10: jal (PC+imm)
    assign NPC = (NPCOp == 2'b10)                ? (PC + immout) :
                 (NPCOp == 2'b01 && Zero[0])     ? (PC + immout) :
                                                   pc_plus4;

    // 10. Write-Back MUX: 00 ALU, 01 DM, 10 PC+4 (jal link)
    assign WD = (WDSel == 2'b10) ? pc_plus4 :
                (WDSel == 2'b01) ? dout     :
                                   aluout;

    // 11. 7-Segment Display Mux (SW[14]=ROM, SW[13]=RF, SW[12]=ALU, SW[11]=DM)
    reg [31:0] disp_data;
    always @(*) begin
        if      (sw_i[14]) disp_data = instr;
        else if (sw_i[13]) disp_data = WD;
        else if (sw_i[12]) disp_data = aluout;
        else if (sw_i[11]) disp_data = dout;
        else               disp_data = instr;
    end

    seg7x16 u_seg7x16(
        .clk       (clk),
        .reset     (rst),
        .disp_mode (sw_i[0]),
        .i_data    ({32'b0, disp_data}),
        .o_seg     (disp_seg_o),
        .o_sel     (disp_an_o)
    );
endmodule
