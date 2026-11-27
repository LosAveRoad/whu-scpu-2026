`timescale 1ns / 1ps

module dm(
    input             clk,
    input             DMWr,
    input      [5:0]  addr,
    input      [31:0] din,
    input      [2:0]  DMType,
    output reg [31:0] dout
);
    reg [7:0] dmem [127:0];
    integer i;

    initial begin
        for (i = 0; i < 128; i = i + 1) begin
            dmem[i] = 8'b0;
        end
    end

    // Synchronous write (little-endian)
    always @(posedge clk) begin
        if (DMWr) begin
            case (DMType)
                3'b000: begin // sw
                    dmem[addr]     <= din[7:0];
                    dmem[addr + 1] <= din[15:8];
                    dmem[addr + 2] <= din[23:16];
                    dmem[addr + 3] <= din[31:24];
                end
                3'b001: begin // sh
                    dmem[addr]     <= din[7:0];
                    dmem[addr + 1] <= din[15:8];
                end
                3'b011: begin // sb
                    dmem[addr]     <= din[7:0];
                end
                default: ;
            endcase
        end
    end

    // Combinational read (little-endian)
    always @(*) begin
        case (DMType)
            3'b000: dout = {dmem[addr + 3], dmem[addr + 2], dmem[addr + 1], dmem[addr]};     // lw
            3'b001: dout = {{16{dmem[addr + 1][7]}}, dmem[addr + 1], dmem[addr]};            // lh
            3'b010: dout = {16'b0, dmem[addr + 1], dmem[addr]};                              // lhu
            3'b011: dout = {{24{dmem[addr][7]}}, dmem[addr]};                                // lb
            3'b100: dout = {24'b0, dmem[addr]};                                              // lbu
            default: dout = 32'b0;
        endcase
    end
endmodule
