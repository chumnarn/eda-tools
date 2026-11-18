#=====================================================================
# run_batch.do  --  LAB 01 : the RTL baseline
#---------------------------------------------------------------------
#  Called by :  run.cmd
#
#  This is the starting point of the whole guide : a normal RTL
#  simulation of cnt4 with the self checking testbench.  Everything
#  that follows compares this result with the gate level result.
#=====================================================================

onerror {puts "!! ERROR : step failed"; quit -code 90}

if {![file exists ../rtl/cnt4.v]} {
    puts "!! wrong folder : [pwd]"
    puts "!! this script must be run from lab01_rtl_baseline"
    quit -code 2
}

source ../tools/gls_common.do

puts "===================================================================="
puts " LAB 01 : the RTL baseline"
puts "===================================================================="

file mkdir results

#--- 1. build the library ------------------------------------------------
gls_prepare_lib work

vlog -work work ../rtl/cnt4.v
vlog -work work ../tb/tb_cnt4.v

#--- 2. elaborate and run ------------------------------------------------
vsim -voptargs=+acc work.tb_cnt4 +tracefile=results/trace_rtl.txt +resultfile=result.txt
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
