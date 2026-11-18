#=====================================================================
# run_rtl.do  --  LAB 05 : the RTL level run
#---------------------------------------------------------------------
#  The FIRST of two simulator processes.  It only produces the RTL
#  trace; the comparison is done by run_gls.do.
#=====================================================================

onerror {puts "!! ERROR : step failed"; quit -code 90}

if {![file exists ../rtl/cnt4.v]} {
    puts "!! wrong folder : [pwd]"
    puts "!! this script must be run from lab05_rtl_vs_gate"
    quit -code 2
}

source ../tools/gls_common.do

puts "===================================================================="
puts " LAB 05 : step 1 -- the RTL level run"
puts "===================================================================="

file mkdir results

gls_prepare_lib work
vlog -work work ../rtl/cnt4.v
vlog -work work ../tb/tb_cnt4.v

vsim -voptargs=+acc work.tb_cnt4 +tracefile=results/trace_rtl.txt +resultfile=results/result_rtl.txt
if {[catch {run -all} err]} {
    puts "---- the simulation stopped : $err ----"
}

puts "   the RTL verdict : [gls_verdict_from results/result_rtl.txt]"
quit -code 0
