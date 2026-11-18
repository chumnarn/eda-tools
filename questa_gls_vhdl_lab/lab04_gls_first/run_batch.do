#=====================================================================
# run_batch.do  --  LAB 04 : the first gate level simulation
#---------------------------------------------------------------------
#  Called by :  run.cmd
#
#  THE SAME tb_cnt4.vhd AS IN LAB 01 IS USED HERE.
#  Only the files compiled into "work" change :
#
#      RTL  :  vcom ../rtl/cnt4.vhd                 + vcom ../tb/tb_cnt4.vhd
#      GLS  :  vlog ../cells/sg13g2_stdcell.v
#              vlog ../netlist/cnt4_net.v           + vcom ../tb/tb_cnt4.vhd
#=====================================================================

onerror {puts "!! ERROR : step failed"; quit -code 90}

if {![file exists ../netlist/cnt4_net.v]} {
    puts "!! wrong folder : [pwd]"
    puts "!! this script must be run from lab04_gls_first"
    quit -code 2
}

source ../tools/gls_common.do

puts "===================================================================="
puts " LAB 04 : step 2 -- the gate level run"
puts "===================================================================="

file mkdir results

puts "---- 1. compile the cells, the netlist and the testbench ----"
gls_prepare_lib work
gls_compile_cells work
gls_compile_netlist work cnt4
gls_compile_tb work tb_cnt4

puts "---- 2. simulate ----"
#  -t 10ps : the cell models declare "timescale 1ns/10ps".  Without this
#            the simulator says :
#            ** Fatal: (vsim-3693) The minimum time resolution limit (10ps)
#               in the Verilog source is smaller than the one chosen for
#               SystemC or VHDL units in the design.
vsim -t 10ps -voptargs=+acc work.tb_cnt4 \
     -gTRACEFILE=results/trace_gls.txt \
     -gRESULTFILE=results/result_gls.txt \
     -gGATE=true
if {[catch {run -all} err]} {
    puts "---- the simulation stopped : $err ----"
}

puts "---- 3. the verdict ----"
set v [gls_verdict_from results/result_gls.txt]
puts "   the GLS verdict : $v"
puts "   the trace file  : results/trace_gls.txt"

if {$v eq "PASS"} {
    gls_write_verdict result.txt "PASS"
    puts "RESULT: PASS"
    quit -code 0
}
gls_write_verdict result.txt "FAIL"
puts "RESULT: FAIL"
quit -code 1
