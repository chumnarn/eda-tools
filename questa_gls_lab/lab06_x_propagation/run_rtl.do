#=====================================================================
# run_rtl.do  --  LAB 06 : the RTL level run
#---------------------------------------------------------------------
#  The FIRST of two simulator processes.  The testbench only OBSERVES
#  what happens when 'x' is driven into the enable of the counter.
#=====================================================================

onerror {puts "!! ERROR : step failed"; quit -code 90}

if {![file exists ../rtl/cnt4.v]} {
    puts "!! wrong folder : [pwd]"
    puts "!! this script must be run from lab06_x_propagation"
    quit -code 2
}

source ../tools/gls_common.do

puts "===================================================================="
puts " LAB 06 : step 1 -- the RTL level run with an 'x' on the enable"
puts "===================================================================="

file mkdir results

gls_prepare_lib work
vlog -work work ../rtl/cnt4.v
vlog -work work ../tb/tb_cnt4_x.v

vsim -voptargs=+acc work.tb_cnt4_x +obsfile=results/obs_rtl.txt +resultfile=results/result_rtl.txt
if {[catch {run -all} err]} {
    puts "---- the simulation stopped : $err ----"
}

puts "   the RTL saw : [string trim [gls_read_file results/obs_rtl.txt]]"
quit -code 0
