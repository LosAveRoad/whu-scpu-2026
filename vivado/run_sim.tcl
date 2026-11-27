# Vivado batch behavioral simulation for SCPU_TOP.
# Usage (from the repo root):
#   vivado -mode batch -source vivado/run_sim.tcl -tclargs task1
#   vivado -mode batch -source vivado/run_sim.tcl -tclargs beq
#   vivado -mode batch -source vivado/run_sim.tcl -tclargs jal
#
# Device: Nexys4 / Nexys4 DDR Artix-7 xc7a100tcsg324-1.
# `SIMULATION` is defined only for the sim fileset, so the clock divider
# is bypassed in xsim and kept for bitstream generation.
# Do NOT add sim/dist_mem_im_stub.v — the Distributed Memory Generator IP
# (ports a / spo, async ROM, depth 64, width 32) supplies dist_mem_im.

set script_dir [file dirname [file normalize [info script]]]
set root_dir   [file normalize ${script_dir}/..]
set which      [lindex $argv 0]
if {$which eq ""} {
    set which task1
}

switch $which {
    task1 {
        set coe_file [file normalize ${root_dir}/coe/test_2026.coe]
        set tb_file  [file normalize ${root_dir}/sim/SCPU_TOP_tb.v]
        set tb_top   SCPU_TOP_tb
    }
    beq {
        set coe_file [file normalize ${root_dir}/coe/test_beq.coe]
        set tb_file  [file normalize ${root_dir}/sim/SCPU_BEQ_tb.v]
        set tb_top   SCPU_BEQ_tb
    }
    jal {
        set coe_file [file normalize ${root_dir}/coe/test_jal.coe]
        set tb_file  [file normalize ${root_dir}/sim/SCPU_JAL_tb.v]
        set tb_top   SCPU_JAL_tb
    }
    default {
        error "unknown target '$which' (use task1, beq, or jal)"
    }
}

set proj_dir ${root_dir}/vivado_proj/${which}
file mkdir $proj_dir

create_project -force scpu_${which} $proj_dir -part xc7a100tcsg324-1
set_property target_language Verilog [current_project]

add_files [glob ${root_dir}/src/*.v]
set_property top SCPU_TOP [current_fileset]

add_files -fileset sim_1 $tb_file
set_property top $tb_top [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Macro for xsim only. Bitstream synthesis does not see SIMULATION.
set_property -name {xsim.compile.xvlog.more_options} -value {-d SIMULATION} -objects [get_filesets sim_1]
catch { set_property verilog_define {SIMULATION} [get_filesets sim_1] }

create_ip -name dist_mem_gen -vendor xilinx.com -library ip -module_name dist_mem_im
set_property -dict [list \
    CONFIG.Component_Name       {dist_mem_im} \
    CONFIG.memory_type          {rom} \
    CONFIG.data_width           {32} \
    CONFIG.depth                {64} \
    CONFIG.input_options        {non_registered} \
    CONFIG.output_options       {non_registered} \
    CONFIG.coefficient_file     $coe_file \
] [get_ips dist_mem_im]

generate_target all [get_files dist_mem_im.xci]
export_ip_user_files -of_objects [get_ips dist_mem_im] -no_script -sync -force -quiet
set_property generate_synth_checkpoint false [get_files dist_mem_im.xci]

set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]
launch_simulation
set sim_rc [catch {run all} sim_msg]
puts $sim_msg
if {$sim_rc != 0} {
    catch {close_sim -force}
    exit 1
}
close_sim -force
exit 0
