#=====================================================================
# run_gls.do  --  LAB 07 : the gate level run with the broken netlist
#---------------------------------------------------------------------
#  The SECOND of two simulator processes.
#
#  The netlist in ../netlist/cnt4_bug_net.v has ONE injected defect :
#  the D inputs of the flip-flops q[1] and q[2] are swapped.  The VHDL
#  source ../rtl/cnt4.vhd is untouched.
#
#  Expected result of this lab :
#      the RTL simulation  -> PASS
#      the gate simulation -> FAIL      (the counter does not count by 1)
#
#  This is the reason why a gate level simulation exists.
#=====================================================================

onerror {puts "!! ERROR : step failed"; quit -code 90}

if {![file exists ../netlist/cnt4_bug_net.v]} {
    puts "!! wrong folder : [pwd]"
    puts "!! this script must be run from lab07_netlist_bug"
    quit -code 2
}

source ../tools/gls_common.do

puts "===================================================================="
puts " LAB 07 : step 2 -- the gate level run with the broken netlist"
puts "===================================================================="

file mkdir results

puts "---- compile the cells, the broken netlist and the testbench ----"
gls_prepare_lib work
gls_compile_cells work
gls_compile_netlist work cnt4_bug
gls_compile_tb work tb_cnt4

vsim -t 10ps -voptargs=+acc work.tb_cnt4 \
     -gTRACEFILE=results/trace_bug.txt \
     -gRESULTFILE=results/result_bug.txt \
     -gGATE=true
if {[catch {run -all} err]} {
    puts "---- the simulation stopped : $err ----"
}

set v_rtl [gls_verdict_from results/result_rtl.txt]
set v_bug [gls_verdict_from results/result_bug.txt]
puts "   the RTL verdict : $v_rtl   (expected : PASS)"
puts "   the GLS verdict : $v_bug   (expected : FAIL)"

puts "---- the two traces next to each other ----"
set a [split [gls_read_file results/trace_rtl.txt] "\n"]
set b [split [gls_read_file results/trace_bug.txt] "\n"]
set n [expr {[llength $a] > [llength $b] ? [llength $a] : [llength $b]}]
set shown 0
for {set i 0} {$i < $n} {incr i} {
    set la [lindex $a $i]
    set lb [lindex $b $i]
    if {$la ne $lb} {
        puts "   line [expr {$i+1}] : RTL '[lindex $a $i]'   vs   GLS '[lindex $b $i]'"
        incr shown
        if {$shown >= 6} { break }
    }
}

if {$v_rtl eq "PASS" && $v_bug eq "FAIL"} {
    gls_write_verdict result.txt "PASS"
    puts "RESULT: PASS"
    puts "  -> the RTL simulation cannot see the defect, the gate level simulation can"
    quit -code 0
}
puts "RESULT: FAIL"
puts "  -> expected : RTL = PASS and GLS = FAIL"
quit -code 1
