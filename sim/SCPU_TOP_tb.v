`timescale 1ns / 1ps

module SCPU_TOP_tb;
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

    // 40 ns clock period (20 ns high, 20 ns low)
    initial clk = 1'b0;
    always #20 clk = ~clk;

    integer errors = 0;

    initial begin
        $dumpfile("scpu_sim.vcd");
        $dumpvars(0, SCPU_TOP_tb);

        sw_i = 16'h0000;
        rstn = 1'b1;
        #5;
        rstn = 1'b0;
        #20;
        rstn = 1'b1;

        // Run through 12 instructions + margin
        repeat (14) @(posedge clk);
        #1;

        if (uut.U_RF.rf[1] !== 32'h00000001) begin $display("FAIL x1=%h", uut.U_RF.rf[1]); errors = errors + 1; end
        if (uut.U_RF.rf[2] !== 32'h00000002) begin $display("FAIL x2=%h", uut.U_RF.rf[2]); errors = errors + 1; end
        if (uut.U_RF.rf[3] !== 32'h00000003) begin $display("FAIL x3=%h", uut.U_RF.rf[3]); errors = errors + 1; end
        if (uut.U_RF.rf[4] !== 32'h00030201) begin $display("FAIL x4=%h", uut.U_RF.rf[4]); errors = errors + 1; end
        if (uut.U_RF.rf[5] !== 32'h00000302) begin $display("FAIL x5=%h", uut.U_RF.rf[5]); errors = errors + 1; end
        if (uut.U_RF.rf[6] !== 32'h00000003) begin $display("FAIL x6=%h", uut.U_RF.rf[6]); errors = errors + 1; end
        // repeat(14) starts after reset release, so 14 instructions retire.
        // PC = 14*4 = 0x38 (two NOPs past the 12-instruction program).
        if (uut.PC !== 32'h00000038) begin $display("FAIL PC=%h exp 00000038", uut.PC); errors = errors + 1; end

        // SW[14:11] display mux (combinational, no extra clock)
        sw_i = 16'h4000; #1;
        if (uut.disp_data !== uut.instr) begin $display("FAIL SW[14] ROM disp"); errors = errors + 1; end
        sw_i = 16'h2000; #1;
        if (uut.disp_data !== uut.WD) begin $display("FAIL SW[13] RF disp"); errors = errors + 1; end
        sw_i = 16'h1000; #1;
        if (uut.disp_data !== uut.aluout) begin $display("FAIL SW[12] ALU disp"); errors = errors + 1; end
        sw_i = 16'h0800; #1;
        if (uut.disp_data !== uut.dout) begin $display("FAIL SW[11] DM disp"); errors = errors + 1; end

        // SW[1]=1 freezes PC and RF writes
        begin : freeze_check
            reg [31:0] pc_freeze;
            reg [31:0] x1_freeze;
            sw_i = 16'h0002;
            #1;
            pc_freeze = uut.PC;
            x1_freeze = uut.U_RF.rf[1];
            repeat (4) @(posedge clk);
            #1;
            if (uut.PC !== pc_freeze) begin
                $display("FAIL debug freeze PC %h -> %h", pc_freeze, uut.PC);
                errors = errors + 1;
            end
            if (uut.U_RF.rf[1] !== x1_freeze) begin
                $display("FAIL debug freeze x1 changed");
                errors = errors + 1;
            end
        end

        if (errors == 0) begin
            $display("PASS: All 12 COE instructions verified! x1=1, x2=2, x3=3, x4=00030201, x5=00000302, x6=00000003; PC=00000038; SW[14:11] mux OK; SW[1] freeze OK");
        end else begin
            $display("FAILED with %0d errors.", errors);
            $fatal(1);
        end
        $finish;
    end
endmodule
