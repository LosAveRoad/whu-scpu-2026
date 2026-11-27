IVERILOG ?= iverilog
VVP ?= vvp
OUT = scpu_sim.vvp

SRCS = \
	src/ctrl.v \
	src/EXT.v \
	src/RF.v \
	src/alu.v \
	src/dm.v \
	src/seg7x16.v \
	src/SCPU_TOP.v \
	sim/dist_mem_im_stub.v \
	sim/SCPU_TOP_tb.v

.PHONY: sim wave clean

sim:
	$(IVERILOG) -DSIMULATION -Wall -o $(OUT) $(SRCS)
	$(VVP) $(OUT)

clean:
	rm -f $(OUT) scpu_sim.vcd
