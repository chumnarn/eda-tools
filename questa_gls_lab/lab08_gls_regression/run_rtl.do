#=====================================================================
# run_rtl.do  --  LAB 08 : the RTL level run of one design
#---------------------------------------------------------------------
#  The design is taken from the command line :
#
#      vsim -c -onfinish stop +TOP=alu4 -do "do run_rtl.do"
#
#  The testbench is called tb_<TOP>.
#=====================================================================

onerror {puts "!! ERROR : step failed"; quit -code 90}

set top "cnt4"
foreach a [split $::argv " "] {
    if {[regexp {^\+TOP=(.*)$} $a -> v]} { set top $v }
}
set tb "tb_$top"

if {![file exists "../rtl/$top.v"]} {
    puts "!! wrong folder or unknown design : [pwd] , TOP = $top"
    quit -code 2
}

source ../tools/gls_common.do

puts "===================================================================="
puts " LAB 08 : the RTL level run of $top"
puts "===================================================================="

file mkdir results

gls_prepare_lib work
vlog -work work "../rtl/$top.v"
vlog -work work "../tb/$tb.v"

vsim -voptargs=+acc "work.$tb" "+tracefile=results/${top}_rtl.txt" "+resultfile=results/${top}_res_rtl.txt"
if {[catch {run -all} err]} {
    puts "---- the simulation stopped : $err ----"
}

puts "   the RTL verdict : [gls_verdict_from results/${top}_res_rtl.txt]"
quit -code 0
