`timescale 1ns / 1ps

// Minimal NEXYS4 8-digit 7-segment display controller
module seg7x16(
    input             clk,
    input             reset,
    input             disp_mode,
    input      [63:0] i_data,
    output reg [7:0]  o_seg,
    output reg [7:0]  o_sel
);
    reg [14:0] cnt;
    wire       seg7_clk = cnt[14];

    always @(posedge clk or posedge reset) begin
        if (reset) cnt <= 15'b0;
        else       cnt <= cnt + 1'b1;
    end

    reg [2:0] seg7_addr;
    always @(posedge seg7_clk or posedge reset) begin
        if (reset) seg7_addr <= 3'b0;
        else       seg7_addr <= seg7_addr + 1'b1;
    end

    always @(*) begin
        o_sel = ~(8'b0000_0001 << seg7_addr);
    end

    reg [3:0] seg_data_r;
    always @(*) begin
        case (seg7_addr)
            3'd0: seg_data_r = i_data[3:0];
            3'd1: seg_data_r = i_data[7:4];
            3'd2: seg_data_r = i_data[11:8];
            3'd3: seg_data_r = i_data[15:12];
            3'd4: seg_data_r = i_data[19:16];
            3'd5: seg_data_r = i_data[23:20];
            3'd6: seg_data_r = i_data[27:24];
            3'd7: seg_data_r = i_data[31:28];
            default: seg_data_r = 4'h0;
        endcase
    end

    // Active-low 7-segment encoding (gfedcba + dp)
    always @(*) begin
        if (disp_mode) begin
            o_seg = 8'hFF;
        end else begin
            case (seg_data_r)
                4'h0: o_seg = 8'hC0;
                4'h1: o_seg = 8'hF9;
                4'h2: o_seg = 8'hA4;
                4'h3: o_seg = 8'hB0;
                4'h4: o_seg = 8'h99;
                4'h5: o_seg = 8'h92;
                4'h6: o_seg = 8'h82;
                4'h7: o_seg = 8'hF8;
                4'h8: o_seg = 8'h80;
                4'h9: o_seg = 8'h90;
                4'hA: o_seg = 8'h88;
                4'hB: o_seg = 8'h83;
                4'hC: o_seg = 8'hC6;
                4'hD: o_seg = 8'hA1;
                4'hE: o_seg = 8'h86;
                4'hF: o_seg = 8'h8E;
                default: o_seg = 8'hFF;
            endcase
        end
    end
endmodule
