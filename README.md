# WHU 2026 计算机组成原理实验 — 单周期 RISC-V CPU (`SCPU_TOP`)

本仓库按《2026 计组课间实验指导手册》实现单周期 CPU，可直接导入 AMD Xilinx Vivado（Nexys4 / Nexys4 DDR，器件 `xc7a100tcsg324-1`）。Linux 下用 Icarus Verilog 做与上板相同的指令级自检。

## 目录结构

- `src/`：可综合 Verilog-2001，直接加入 Vivado
  - `SCPU_TOP.v`：字节地址 `PC`、`beq` / `jal` 的下一条地址、`PC+4` 写回
  - `ctrl.v`：`beq`（`ALUOp = SUB`）与 `jal`（`WDSel = 2'b10`，`NPCOp = 2'b10`）
  - `EXT.v`：I / S / B / J 立即数
  - `RF.v`、`alu.v`、`dm.v`、`seg7x16.v`
- `coe/`
  - `test_2026.coe`：任务 1，官方 12 条顺序指令
  - `test_beq.coe`：任务 2，`Test_all.coe` 字 0..31（`beq` 块），相对偏移不变
  - `test_jal.coe`：任务 3，`Test_all.coe` 字 192..222（`jal` 块）平移到 `PC = 0`，相对偏移不变
  - `Test_all.coe`：全指令核（276 条），原文件未改
- `sim/`：Icarus 用的 `dist_mem_im` 行为模型与三个自检 testbench（不要加入 Vivado 工程）
- `vivado/run_sim.tcl`：Vivado batch 行为仿真（生成 `dist_mem_im` IP 并跑对应 testbench）
- `docs/CHECKOFF_REQUIREMENTS.md`：验收标准

## Linux 仿真（与 Vivado xsim 同一套 RTL / testbench）

```bash
make sim       # 任务 1
make sim-beq   # 任务 2 beq
make sim-jal   # 任务 3 jal
make sim-all
```

`SIMULATION` 宏把 `Clk_CPU` 直接接到 `clk`，绕过 `2^25` / `2^27` 分频，便于仿真。综合、生成 bitstream 时不要定义该宏。

通过时的输出：

- 任务 1：`x1=1, x2=2, x3=3, x4=00030201, x5=00000302, x6=00000003`，顺序 `PC` 走到 `0x38`，`SW[14:11]` 显示切换与 `SW[1]` 冻结通过
- 任务 2：`beq +16` 从 `0x034` 到 `0x044`（跳过 `addi x10, 666`），`beq x9,x8` 不跳（`0x058 -> 0x05C`），`beq -24` 从 `0x05C` 回到 `0x044`；`x4=00030101, x5=00000301, x6=00000003`
- 任务 3：`jal +16` 从 `0x034` 到 `0x044` 且 `x1=0x038`；`jal -20` 从 `0x058` 回到 `0x044` 且 `x1=0x05C`；`x2=7, x4=00030701, x5=00000307, x6=00000003`

`test_beq.coe` / `test_jal.coe` 里的后向跳转会循环，这是核文件本身的行为，上板时数码管会重复显示这段路径。testbench 检查前两轮的 `PC`、返回地址和目标寄存器。

本仓库 `Test_all.coe` 共 276 条。`beq` 关键指令在字 13 / 22 / 23，`jal` 关键指令在字 205 / 214（`PC 0x334` 与 `0x358`）。筛选后整段放到地址 0，字节相对偏移保持不变。

## 导入 Vivado 生成 bitstream

1. 器件选 **xc7a100tcsg324-1**（Nexys4 / Nexys4 DDR Artix-7）。
2. 只加入 `src/*.v`。不要加入 `sim/dist_mem_im_stub.v`，也不要在综合时定义 `SIMULATION`。
3. IP Catalog → **Distributed Memory Generator**，模块名必须是 `dist_mem_im`：
   - Memory Type：**ROM**
   - Data Width：**32**
   - Depth：**64**（任务 1 / `test_beq.coe` / `test_jal.coe`）
   - Input Options 与 Output Options 都选 **Non Registered**（异步读）。生成端口只有 `a[5:0]` 和 `spo[31:0]`，与 `SCPU_TOP` 里的 `.a(PC[7:2])`、`.spo(instr)` 一致
   - Coefficient File：按验收任务选 `coe/test_2026.coe`、`coe/test_beq.coe` 或 `coe/test_jal.coe`
4. 加入老师下发的 Nexys4 `.xdc`。顶层端口为 `clk`、`rstn`、`sw_i[15:0]`、`disp_an_o[7:0]`、`disp_seg_o[7:0]`（见 `constraints/README.md`）。
5. 生成 bitstream 时确认综合宏列表里没有 `SIMULATION`，这样 `SW[15]=1` 为 `clkdiv[27]` 慢时钟，`SW[15]=0` 为 `clkdiv[25]` 快时钟。

若要加载完整 `coe/Test_all.coe`（276 条）：把 IP 深度改为 **512**（地址 9 位，`a[8:0]`），并把 `src/SCPU_TOP.v` 顶部的 `localparam IM_AW` 从 `6` 改为 `9`（取指地址变为 `PC[10:2]`）。筛选后的三个 COE 保持 `IM_AW = 6`。

### Vivado 行为仿真

已安装 Vivado 时，在仓库根目录执行（脚本会建工程、生成 ROM IP、定义 `SIMULATION` 并跑到 `$finish`）：

```bash
make vivado-sim       # 任务 1，coe/test_2026.coe
make vivado-sim-beq   # 任务 2
make vivado-sim-jal   # 任务 3
```

等价命令：

```bash
vivado -mode batch -source vivado/run_sim.tcl -tclargs task1
```

`tclargs` 还可为 `beq` 或 `jal`。工程写在 `vivado_proj/`（已 gitignore）。xsim 使用与 `make sim*` 相同的 testbench，断言失败时脚本返回非 0。

开关约定与 2026 手册一致：`SW[15]` 快慢时钟，`SW[1]=1` 冻结 `PC` 与寄存器堆写入，`SW[14:11]` 依次显示 ROM / RF 写回 / ALU / DM，`SW[0]=1` 显示测试图案。
