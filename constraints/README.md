# 物理引脚约束说明（上板前必看）

本目录用于存放 NEXYS4 FPGA 开发板的 `.xdc` 引脚约束文件（通常由老师下发，如 `icf.xdc` 或 `Nexys4DDR_Master.xdc`）。

在 Vivado 中生成 `.bit` 上板前，请确保 `.xdc` 中的端口名与 `src/SCPU_TOP.v` 顶层端口完全一致：
- `clk`（100 MHz 系统时钟）
- `rstn`（低电平有效复位按键）
- `sw_i[15:0]`（16 位拨码开关）
- `disp_an_o[7:0]`（8 位数码管位选）
- `disp_seg_o[7:0]`（8 位数码管段选）
