#=====================================================================
# run_gls.do  --  LAB 05 : the gate level run and the comparison
#---------------------------------------------------------------------
#  The SECOND of two simulator processes.
#
#  The testbench file is NOT changed : only the file that is compiled
#  into "work" changes.
#
#      RTL :  vcom ../rtl/cnt4.vhd                     ../tb/tb_cnt4.vhd
#      GLS :  vlog ../cells/sg13g2_stdcell.v
#             vlog ../netlist/cnt4_net.v               ../tb/tb_cnt4.vhd
#
#  Both runs write a trace file and the traces are compared line by
#  line.  A gate level simulation that gives exactly the same trace as
#  the RTL simulation is the normal, expected result.
#=====================================================================

onerror {puts "!! ERROR : step failed"; quit -code 90}

if {![file exists ../netlist/cnt4_net.v]} {
    puts "!! wrong folder : [pwd]"
    puts "!! this script must be run from lab05_rtl_vs_gate"
    quit -code 2
}

source ../tools/gls_common.do

puts "===================================================================="
puts " LAB 05 : step 2 -- the gate level run"
puts "===================================================================="

file mkdir results

puts "---- compile the cells, the netlist and the testbench ----"
gls_prepare_lib work
gls_compile_cells work
gls_compile_netlist work cnt4
gls_compile_tb work tb_cnt4

vsim -t 10ps -voptargs=+acc work.tb_cnt4 \
     -gTRACEFILE=results/trace_gls.txt \
     -gRESULTFILE=results/result_gls.txt \
     -gGATE=true
if {[catch {run -all} err]} {
    puts "---- the simulation stopped : $err ----"
}

set v_rtl [gls_verdict_from results/result_rtl.txt]
set v_gls [gls_verdict_from results/result_gls.txt]
puts "   the RTL verdict : $v_rtl"
puts "   the GLS verdict : $v_gls"

puts "---- compare the two traces line by line ----"
set diff [gls_diff_lines results/trace_rtl.txt results/trace_gls.txt]
set n_rtl [llength [split [gls_read_file results/trace_rtl.txt] "\n"]]
puts "   the RTL trace has $n_rtl lines"
if {[llength $diff] == 0} {
    puts "   OK : the two traces are IDENTICAL"
} else {
    puts "   !! the traces differ in [llength $diff] line(s) :"
    foreach d [lrange $diff 0 9] {
        puts "      line [lindex $d 0] : RTL '[lindex $d 1]'  vs  GLS '[lindex $d 2]'"
    }
}

if {$v_rtl eq "PASS" && $v_gls eq "PASS" && [llength $diff] == 0} {
    gls_write_verdict result.txt "PASS"
    puts "RESULT: PASS"
    quit -code 0
}
gls_write_verdict result.txt "FAIL"
puts "RESULT: FAIL"
quit -code 1
