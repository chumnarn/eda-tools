#=====================================================================
# run_batch.do  --  LAB 04 : the first gate level simulation
#---------------------------------------------------------------------
#  Called by :  run.cmd
#
#  The cells AND the netlist have to be in the SAME library, exactly
#  like in a real gate level simulation.  The wrong way (the cells in
#  another library) is shown by run_wrong.cmd, which fails with
#
#      ** Error: (vsim-3033) Instantiation of 'sg13g2_inv_1' failed.
#                 The design unit was not found.
#=====================================================================

onerror {puts "!! ERROR : step failed"; quit -code 90}

if {![file exists ../netlist/cnt4_net.v]} {
    puts "!! wrong folder : [pwd]"
    puts "!! this script must be run from lab04_gls_first"
    quit -code 2
}

source ../tools/gls_common.do

puts "===================================================================="
puts " LAB 04 : the first gate level simulation"
puts "===================================================================="

file mkdir results

#--- 1. build the library : the cells AND the netlist go into "work" ---
puts "---- 1. the cells and the netlist in the same library ----"
gls_prepare_lib work
vlog -work work ../cells/sg13g2_stdcell.v
vlog -work work ../netlist/cnt4_net.v
vlog -work work ../tb/tb_cnt4.v

#--- 2. elaborate and run ------------------------------------------------
puts "---- 2. the gate level run ----"
vsim -voptargs=+acc work.tb_cnt4 +GATE +tracefile=results/trace_gls.txt +resultfile=result.txt
if {[catch {run -all} err]} {
    puts "---- the simulation stopped : $err ----"
}

#--- 3. the verdict ------------------------------------------------------
set v [gls_verdict_from result.txt]
if {$v eq "PASS"} {
    puts "RESULT: PASS"
    quit -code 0
}
puts "RESULT: FAIL"
quit -code 1
