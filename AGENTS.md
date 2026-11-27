# AGENTS.md — Cursor 云端/本地编码任务指令

你正在协助完成 **武汉大学（WHU）2026 秋计算机组成原理课间实验（单周期 RISC-V CPU `SCPU_TOP`）**。
请严格遵循以下目标、硬件约束与验收要求开展工作。

---

## 一、核心背景与文件约定

- **详细验收标准与报告规范**：见 `docs/CHECKOFF_REQUIREMENTS.md`
- **基础版源码**：`src/`（`SCPU_TOP.v`, `ctrl.v`, `EXT.v`, `RF.v`, `alu.v`, `dm.v`, `seg7x16.v`）
- **核文件**：
  - `coe/test_2026.coe`：任务 1 官方 12 条顺序执行指令
  - `coe/Test_all.coe`：任务 2 / 任务 3 全指令测试文件（共 277 条，分块索引见 `docs/CHECKOFF_REQUIREMENTS.md`）
- **仿真环境**：已通过 `.cursor/environment.json` 安装 `iverilog` 和 `make`，**每次修改 RTL 后必须运行 `make sim` 验证通过**。

---

## 二、当前编码任务清单（按优先级执行）

### Step 1：验证任务 1 基线
1. 运行 `make sim`，确认当前 `src/` + `sim/SCPU_TOP_tb.v` 在 `iverilog -DSIMULATION -Wall` 下无报错且全部断言 PASS（`x1=1, x2=2, x3=3, x4=00030201, x5=00000302, x6=00000003`）。
2. 检查 `src/SCPU_TOP.v` 的开关显示逻辑是否完全对齐 2026 手册与第一讲/第二讲 4.4 节要求：
   - `sw_i[15]`：`1` = 慢速时钟（`2^27` 分频），`0` = 快速时钟（`2^25` 分频）
   - `sw_i[1]`：`1` = 调试模式（冻结 `RF` 写入与 `PC` 推进），`0` = 正常模式
   - `sw_i[14:11]`：`4'b1000` 显示 ROM 指令、`4'b0100` 显示 RF 数据、`4'b0010` 显示 ALU 数据、`4'b0001` 显示 DM 数据
   - `sw_i[0]`：`0` 显示模块数据 `display_data`，`1` 显示测试动画/图案 `led_disp_data`

### Step 2：升级支持任务 3（`jal` 跳转，最高加分）与任务 2（`beq` 分支）
在不破坏任务 1 接口兼容性的前提下，扩展单周期 CPU 以支持 `jal`（任务 3）与 `beq`（任务 2）：

1. **字节编址 `PC` 与 `NPC`（`SCPU_TOP.v`）**：
   - 将顺序 `rom_addr` 升级为字节地址寄存器 `PC`（复位为 `32'h0000_0000`，每拍正常 `+ 32'd4`）。
   - `dist_mem_im` 的地址输入接字地址 `PC[7:2]`（若 ROM 深度为 64；若加载完整 277 条 `Test_all.coe` 需扩展为 9 位 `PC[10:2]`，请在 `README.md` 注明 Vivado IP 深度配置）。
   - 新增下一条指令地址计算（`NPC`）：
     - 顺序：`PC + 4`
     - `beq` 且 `Zero == 1`：`PC + immout`
     - `jal`：`PC + immout`
2. **扩展 `EXT.v`**：
   - 保留 I-type、S-type 符号扩展；
   - 新增 **B-type**（13 位符号扩展，最低位补 `1'b0`）：`bimm = {instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}` → `{{19{bimm[12]}}, bimm}`；
   - 新增 **J-type**（21 位符号扩展，最低位补 `1'b0`）：`jimm = {instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}` → `{{11{jimm[20]}}, jimm}`。
3. **扩展 `ctrl.v`**：
   - 新增 `jal`（`Op == 7'b1101111`）：`RegWrite = 1`、`WDSel = 2'b10`（选择 `PC + 4` 写回 `rd`）、`EXTOp` 选 J-type、`NPCOp` 选跳转。
   - 新增 `beq`（`Op == 7'b1100011 && Funct3 == 3'b000`）：`ALUSrc = 0`、`ALUOp = 5'b00100`（`SUB`）、`EXTOp` 选 B-type、`NPCOp` 选分支（结合 `Zero`）。
4. **写回多路器（`SCPU_TOP.v`）**：
   - `WDSel == 2'b00` → `aluout`
   - `WDSel == 2'b01` → `dout`
   - `WDSel == 2'b10` → `PC + 4`

### Step 3：从 `coe/Test_all.coe` 筛选生成专项验证工程
1. 根据 `docs/CHECKOFF_REQUIREMENTS.md` 中 `Test_all.coe` 的分块索引：
   - Block 6（`idx 192..223`）为 `jal` 专项测试块（含 `jal x1, +16` 与 `jal x1, -20`）；
   - Block 0（`idx 0..31`）为 `beq` 专项测试块。
2. 在 `coe/` 下生成筛选后的精简 `.coe`（例如 `coe/test_jal.coe` 与 `coe/test_beq.coe`，注意重算/保持相对偏移一致，并保留原 `coe/test_2026.coe` 与 `coe/Test_all.coe` 不动）。
3. 在 `sim/` 下新增对应自检 Testbench 与 `Makefile` 目标（如 `make sim-jal`、`make sim-beq`），**必须自动断言跳转前后 `PC`、`x1`（返回地址）以及目标寄存器结果**，确保 `make sim`、`make sim-jal`、`make sim-beq` 全部零错误通过。

---

## 三、交付硬性约束

- **Vivado 兼容性**：保持 `src/` 内所有代码为标准 Verilog-2001，**禁止**在 `src/` 中使用 SystemVerilog 专属语法（如 `logic`、`always_ff`）或 `$display` 等不可综合语句；`dist_mem_im` 接口名称与端口名（`.a`, `.spo`）保持不变。
- **不提交仿真产物**：不要提交 `*.vvp`、`*.vcd` 等临时文件。
- **汇报要求**：完成后给出每条 `make sim*` 命令的实际运行输出、修改文件清单，以及导入 Vivado 生成 `.bit` 时的 ROM 深度/端口注意事项。
