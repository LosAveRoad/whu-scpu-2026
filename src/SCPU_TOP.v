`timescale 1ns / 1ps

module SCPU_TOP(
    input         clk,
    input         rstn,
    input  [15:0] sw_i,
    output [7:0]  disp_an_o,
    output [7:0]  disp_seg_o
);
    wire rst = ~rstn;

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

    // 2. Instruction address counter (12 official COE instructions: 0..11)
    reg [5:0] rom_addr;
    always @(posedge Clk_CPU or posedge rst) begin
        if (rst) begin
            rom_addr <= 6'd0;
        end else if (!sw_i[1]) begin
            if (rom_addr == 6'd11) rom_addr <= 6'd11; // Hold at end of 12-instr test
            else                   rom_addr <= rom_addr + 6'd1;
        end
    end

    // 3. Instruction Memory (Vivado Distributed ROM IP: dist_mem_im)
    wire [31:0] instr;
    dist_mem_im U_IM(
        .a   (rom_addr),
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

    // 4. Control Unit
    wire       RegWrite, MemWrite, ALUSrc;
    wire [2:0] EXTOp, DMType;
    wire [4:0] ALUOp;
    wire [1:0] WDSel;

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
        .WDSel    (WDSel)
    );

    // 5. Immediate Extender
    wire [31:0] immout;
    EXT U_EXT(
        .iimm   (iimm),
        .simm   (simm),
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

    // 9. Write-Back MUX
    assign WD = (WDSel[0]) ? dout : aluout;

    // 10. 7-Segment Display Mux (SW[14]=ROM, SW[13]=RF, SW[12]=ALU, SW[11]=DM)
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
