#=====================================================================
# run_rtl.do  --  LAB 05 : the RTL level run
#---------------------------------------------------------------------
#  The FIRST of two simulator processes.  It only produces the RTL
#  trace; the comparison is done by run_gls.do.
#=====================================================================

onerror {puts "!! ERROR : step failed"; quit -code 90}

if {![file exists ../rtl/cnt4.vhd]} {
    puts "!! wrong folder : [pwd]"
    puts "!! this script must be run from lab05_rtl_vs_gate"
    quit -code 2
}

source ../tools/gls_common.do

puts "===================================================================="
puts " LAB 05 : step 1 -- the RTL level run"
puts "===================================================================="

file mkdir results

puts "---- compile the VHDL RTL and the testbench ----"
gls_prepare_lib work
gls_compile_rtl work cnt4
gls_compile_tb work tb_cnt4

vsim -t 10ps -voptargs=+acc work.tb_cnt4 \
     -gTRACEFILE=results/trace_rtl.txt \
     -gRESULTFILE=results/result_rtl.txt \
     -gGATE=false
if {[catch {run -all} err]} {
    puts "---- the simulation stopped : $err ----"
}

puts "   the RTL verdict : [gls_verdict_from results/result_rtl.txt]"
quit -code 0
