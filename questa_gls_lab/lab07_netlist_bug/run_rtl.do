#=====================================================================
# run_rtl.do  --  LAB 07 : the RTL level run
#---------------------------------------------------------------------
#  The FIRST of two simulator processes.  The RTL source is correct, so
#  this run must pass.
#=====================================================================

onerror {puts "!! ERROR : step failed"; quit -code 90}

if {![file exists ../rtl/cnt4.v]} {
    puts "!! wrong folder : [pwd]"
    puts "!! this script must be run from lab07_netlist_bug"
    quit -code 2
}

source ../tools/gls_common.do

puts "===================================================================="
puts " LAB 07 : step 1 -- the RTL level run (the RTL source is correct)"
puts "===================================================================="

file mkdir results

gls_prepare_lib work
vlog -work work ../rtl/cnt4.v
vlog -work work ../tb/tb_cnt4.v

vsim -voptargs=+acc work.tb_cnt4 +tracefile=results/trace_rtl.txt +resultfile=results/result_rtl.txt
if {[catch {run -all} err]} {
    puts "---- the simulation stopped : $err ----"
}

puts "   the RTL verdict : [gls_verdict_from results/result_rtl.txt]   (expected : PASS)"
quit -code 0
