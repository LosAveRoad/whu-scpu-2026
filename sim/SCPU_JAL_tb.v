`timescale 1ns / 1ps

// Task 3: jal block from Test_all.coe (indices 192..222), rebased at PC 0.
// Relative byte offsets are unchanged, so:
//   jal x1,+16 at 0x034 -> 0x044, x1 = 0x038
//   jal x1,-20 at 0x058 -> 0x044, x1 = 0x05C
module SCPU_JAL_tb;
    reg         clk;
    reg         rstn;
    reg  [15:0] sw_i;
    wire [7:0]  disp_an_o;
    wire [7:0]  disp_seg_o;

    SCPU_TOP uut(
        .clk        (clk),
        .rstn       (rstn),
        .sw_i       (sw_i),
        .disp_an_o  (disp_an_o),
        .disp_seg_o (disp_seg_o)
    );

    initial clk = 1'b0;
    always #20 clk = ~clk;

    integer errors;
    integer ci;
    integer land44;
    reg [31:0] pc_q;
    reg [31:0] exp_pc [0:25];

    initial begin
        exp_pc[0]  = 32'h000; exp_pc[1]  = 32'h004; exp_pc[2]  = 32'h008; exp_pc[3]  = 32'h00C;
        exp_pc[4]  = 32'h010; exp_pc[5]  = 32'h014; exp_pc[6]  = 32'h018; exp_pc[7]  = 32'h01C;
        exp_pc[8]  = 32'h020; exp_pc[9]  = 32'h024; exp_pc[10] = 32'h028; exp_pc[11] = 32'h02C;
        exp_pc[12] = 32'h030; exp_pc[13] = 32'h034;
        exp_pc[14] = 32'h044; exp_pc[15] = 32'h048; exp_pc[16] = 32'h04C; exp_pc[17] = 32'h050;
        exp_pc[18] = 32'h054; exp_pc[19] = 32'h058;
        exp_pc[20] = 32'h044; exp_pc[21] = 32'h048; exp_pc[22] = 32'h04C; exp_pc[23] = 32'h050;
        exp_pc[24] = 32'h054; exp_pc[25] = 32'h058;
    end

    initial begin
        $dumpfile("scpu_jal.vcd");
        $dumpvars(0, SCPU_JAL_tb);

        errors = 0;
        land44 = 0;
        sw_i   = 16'h0000;
        rstn   = 1'b0;
        repeat (2) @(posedge clk);
        rstn = 1'b1;
        @(negedge clk);

        for (ci = 0; ci < 26; ci = ci + 1) begin
            if (uut.PC !== exp_pc[ci]) begin
                $display("FAIL cyc %0d PC=%h exp=%h instr=%h", ci, uut.PC, exp_pc[ci], uut.instr);
                errors = errors + 1;
            end
            pc_q = uut.PC;
            @(posedge clk);
            #1;

            if (pc_q == 32'h034) begin
                if (uut.PC !== 32'h044) begin
                    $display("FAIL jal +16 next PC=%h", uut.PC);
                    errors = errors + 1;
                end
                if (uut.U_RF.rf[1] !== 32'h038) begin
                    $display("FAIL jal link x1=%h exp 00000038", uut.U_RF.rf[1]);
                    errors = errors + 1;
                end
                if (uut.U_RF.rf[10] !== 32'h0) begin
                    $display("FAIL skipped addi wrote x10=%h", uut.U_RF.rf[10]);
                    errors = errors + 1;
                end
            end
            if (pc_q == 32'h044) begin
                land44 = land44 + 1;
                if (uut.U_RF.rf[7] !== land44) begin
                    $display("FAIL x7=%h after landing addi, exp %0d", uut.U_RF.rf[7], land44);
                    errors = errors + 1;
                end
            end
            if (pc_q == 32'h04C) begin
                if (uut.U_RF.rf[8] !== 32'd8) begin
                    $display("FAIL x8=%h", uut.U_RF.rf[8]);
                    errors = errors + 1;
                end
            end
            if (pc_q == 32'h054) begin
                if (uut.U_RF.rf[9] !== 32'd9) begin
                    $display("FAIL x9=%h", uut.U_RF.rf[9]);
                    errors = errors + 1;
                end
            end
            if (pc_q == 32'h058) begin
                if (uut.PC !== 32'h044) begin
                    $display("FAIL jal -20 next PC=%h", uut.PC);
                    errors = errors + 1;
                end
                if (uut.U_RF.rf[1] !== 32'h05C) begin
                    $display("FAIL jal link x1=%h exp 0000005C", uut.U_RF.rf[1]);
                    errors = errors + 1;
                end
                if (uut.U_RF.rf[31] !== 32'h0) begin
                    $display("FAIL x31 executed past jal, x31=%h", uut.U_RF.rf[31]);
                    errors = errors + 1;
                end
            end
        end

        if (uut.U_RF.rf[1] !== 32'h05C)       begin $display("FAIL x1=%h", uut.U_RF.rf[1]); errors = errors + 1; end
        if (uut.U_RF.rf[2] !== 32'h7)         begin $display("FAIL x2=%h", uut.U_RF.rf[2]); errors = errors + 1; end
        if (uut.U_RF.rf[3] !== 32'h3)         begin $display("FAIL x3=%h", uut.U_RF.rf[3]); errors = errors + 1; end
        if (uut.U_RF.rf[4] !== 32'h00030701)  begin $display("FAIL x4=%h", uut.U_RF.rf[4]); errors = errors + 1; end
        if (uut.U_RF.rf[5] !== 32'h00000307)  begin $display("FAIL x5=%h", uut.U_RF.rf[5]); errors = errors + 1; end
        if (uut.U_RF.rf[6] !== 32'h00000003)  begin $display("FAIL x6=%h", uut.U_RF.rf[6]); errors = errors + 1; end
        if (uut.U_RF.rf[10] !== 32'h0)        begin $display("FAIL x10=%h", uut.U_RF.rf[10]); errors = errors + 1; end
        if (uut.U_RF.rf[31] !== 32'h0)        begin $display("FAIL x31=%h", uut.U_RF.rf[31]); errors = errors + 1; end
        if (land44 < 2) begin
            $display("FAIL only saw %0d landings at 0x044", land44);
            errors = errors + 1;
        end

        if (errors == 0) begin
            $display("PASS jal: +16 0x034->0x044 x1=00000038, -20 0x058->0x044 x1=0000005C, x10 skipped, x2=7 x3=3 x4=00030701 x5=00000307 x6=00000003 x31=0");
        end else begin
            $display("FAILED jal with %0d errors.", errors);
            $fatal(1);
        end
        $finish;
    end
endmodule
