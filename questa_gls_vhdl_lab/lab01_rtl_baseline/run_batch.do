#=====================================================================
# run_batch.do  --  LAB 01 : RTL baseline (VHDL)
#---------------------------------------------------------------------
#  Called by :  run.cmd
#
#  This is the reference point of the whole guide : the same testbench
#  will later be run against the gate netlist (LAB 04 onwards) and the
#  two traces must come out identical.
#
#  The DUT is declared as a COMPONENT, not as "entity work.cnt4".
#  That is what makes ONE testbench file work at both levels :
#  ModelSim binds the component name to whichever design unit with that
#  name is in the library "work".
#=====================================================================

onerror {puts "!! ERROR : step failed"; quit -code 90}

if {![file exists ../rtl/cnt4.vhd]} {
    puts "!! wrong folder : [pwd]"
    puts "!! this script must be run from lab01_rtl_baseline"
    quit -code 2
}

source ../tools/gls_common.do

puts "===================================================================="
puts " LAB 01 : RTL baseline (VHDL)"
puts "===================================================================="

file mkdir results

#--- 1. compile ----------------------------------------------------------
puts "---- 1. compile the VHDL RTL and the testbench ----"
gls_prepare_lib work
gls_compile_rtl work cnt4
gls_compile_tb work tb_cnt4

#--- 2. simulate ---------------------------------------------------------
#  -t 10ps : the Verilog cell models use "timescale 1ns/10ps", so the
#            simulator resolution must be at least 10 ps (see LAB 04)
puts "---- 2. simulate ----"
vsim -t 10ps -voptargs=+acc work.tb_cnt4 \
     -gTRACEFILE=results/trace_rtl.txt \
     -gRESULTFILE=results/result_rtl.txt \
     -gGATE=false
if {[catch {run -all} err]} {
    puts "---- the simulation stopped : $err ----"
}

#--- 3. the verdict ------------------------------------------------------
puts "---- 3. the verdict ----"
set v [gls_verdict_from results/result_rtl.txt]
puts "   the RTL verdict : $v"
puts "   the trace file  : results/trace_rtl.txt"

if {$v eq "PASS"} {
    gls_write_verdict result.txt "PASS"
    puts "RESULT: PASS"
    quit -code 0
}
gls_write_verdict result.txt "FAIL"
puts "RESULT: FAIL"
quit -code 1
