IVERILOG ?= iverilog
VVP ?= vvp
VIVADO ?= vivado

RTL = \
	src/ctrl.v \
	src/EXT.v \
	src/RF.v \
	src/alu.v \
	src/dm.v \
	src/seg7x16.v \
	src/SCPU_TOP.v

.PHONY: sim sim-beq sim-jal sim-all clean vivado-sim vivado-sim-beq vivado-sim-jal

sim:
	$(IVERILOG) -DSIMULATION -Wall -I sim -o scpu_sim.vvp $(RTL) sim/dist_mem_im_stub.v sim/SCPU_TOP_tb.v
	$(VVP) scpu_sim.vvp

sim-beq:
	$(IVERILOG) -DSIMULATION -DROM_BEQ -Wall -I sim -o scpu_beq.vvp $(RTL) sim/dist_mem_im_stub.v sim/SCPU_BEQ_tb.v
	$(VVP) scpu_beq.vvp

sim-jal:
	$(IVERILOG) -DSIMULATION -DROM_JAL -Wall -I sim -o scpu_jal.vvp $(RTL) sim/dist_mem_im_stub.v sim/SCPU_JAL_tb.v
	$(VVP) scpu_jal.vvp

sim-all: sim sim-beq sim-jal

vivado-sim:
	$(VIVADO) -mode batch -source vivado/run_sim.tcl -tclargs task1

vivado-sim-beq:
	$(VIVADO) -mode batch -source vivado/run_sim.tcl -tclargs beq

vivado-sim-jal:
	$(VIVADO) -mode batch -source vivado/run_sim.tcl -tclargs jal

clean:
	rm -f scpu_sim.vvp scpu_beq.vvp scpu_jal.vvp scpu_sim.vcd scpu_beq.vcd scpu_jal.vcd
