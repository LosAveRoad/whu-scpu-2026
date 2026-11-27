# WHU 2026 计算机组成原理实验 — 单周期 RISC-V CPU (`SCPU_TOP`)

本仓库已按《2026 计组课间实验指导手册》五讲架构完成初始化，并配置了 Cursor 云端 Linux 环境（`.cursor/environment.json`）与硬件规范（`.cursor/rules/whu-2026-scpu.mdc`）。

## 目录结构

- `src/`：可直接导入 Vivado 的全部 RTL 源码
  - `SCPU_TOP.v`（顶层单步串行 CPU，含 `SW[15]` 快慢时钟与 `SW[1]` 调试锁）
  - `ctrl.v`（已补全 `stype`/`i_sw` 并修正 `i_sh` 的 `&`）
  - `EXT.v`、`RF.v`、`alu.v`、`dm.v`、`seg7x16.v`
- `coe/test_2026.coe`：2026 官方 12 条测试指令机器码
- `sim/`：`iverilog` / Linux 仿真桩（`dist_mem_im_stub.v`）与自检测试平台（`SCPU_TOP_tb.v`）
- `constraints/`：NEXYS4 物理引脚 `.xdc` 放置说明

## 在 Linux / Cursor 云端运行仿真

```bash
make sim
```

预期通过结果：
`x1 = 0x00000001`, `x2 = 0x00000002`, `x3 = 0x00000003`, `x4 = 0x00030201`, `x5 = 0x00000302`, `x6 = 0x00000003`。

## 导入 Vivado 上板步骤

1. 在 Vivado 新建工程并导入 `src/*.v`（**不要**导入 `sim/dist_mem_im_stub.v`）；
2. 在 IP Catalog 创建 `Distributed Memory Generator`（选 **ROM**，深度 64、位宽 32），命名为 `dist_mem_im`，加载 `coe/test_2026.coe`；
3. 添加 NEXYS4 的 `.xdc` 物理引脚约束文件，生成 `.bit` 并烧录。
