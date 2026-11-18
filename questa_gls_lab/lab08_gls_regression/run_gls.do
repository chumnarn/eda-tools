#=====================================================================
# run_gls.do  --  LAB 08 : the gate level run of one design
#---------------------------------------------------------------------
#  The design is taken from the command line :
#
#      vsim -c -onfinish stop +TOP=alu4 -do "do run_gls.do"
#
#  The testbench is called tb_<TOP> and it is NOT changed between the
#  two levels -- only the file that is compiled into "work" changes.
#=====================================================================

onerror {puts "!! ERROR : step failed"; quit -code 90}

set top "cnt4"
foreach a [split $::argv " "] {
    if {[regexp {^\+TOP=(.*)$} $a -> v]} { set top $v }
}
set tb "tb_$top"

if {![file exists "../netlist/${top}_net.v"]} {
    puts "!! wrong folder or no netlist for $top : [pwd]"
    quit -code 2
}

source ../tools/gls_common.do

puts "===================================================================="
puts " LAB 08 : the gate level run of $top"
puts "===================================================================="

file mkdir results

gls_prepare_lib work
vlog -work work ../cells/sg13g2_stdcell.v
vlog -work work "../netlist/${top}_net.v"
vlog -work work "../tb/$tb.v"

vsim -voptargs=+acc "work.$tb" +GATE "+tracefile=results/${top}_gls.txt" "+resultfile=results/${top}_res_gls.txt"
if {[catch {run -all} err]} {
    puts "---- the simulation stopped : $err ----"
}

set v_rtl [gls_verdict_from "results/${top}_res_rtl.txt"]
set v_gls [gls_verdict_from "results/${top}_res_gls.txt"]
puts "   the RTL verdict : $v_rtl"
puts "   the GLS verdict : $v_gls"

set diff [gls_diff_lines "results/${top}_rtl.txt" "results/${top}_gls.txt"]
set n [llength [split [gls_read_file "results/${top}_rtl.txt"] "\n"]]
puts "   $n trace lines , [llength $diff] difference(s)"
foreach d [lrange $diff 0 4] {
    puts "      line [lindex $d 0] : RTL '[lindex $d 1]'  vs  GLS '[lindex $d 2]'"
}

if {$v_rtl eq "PASS" && $v_gls eq "PASS" && [llength $diff] == 0} {
    gls_write_verdict result.txt "PASS"
    gls_write_verdict "results/${top}_verdict.txt" "PASS"
    puts "RESULT: PASS"
    quit -code 0
}
gls_write_verdict result.txt "FAIL"
gls_write_verdict "results/${top}_verdict.txt" "FAIL"
puts "RESULT: FAIL"
quit -code 1
