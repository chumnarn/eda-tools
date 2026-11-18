#=====================================================================
#  run.do  --  LAB 10 : code coverage for VHDL  (GUI variant)
#---------------------------------------------------------------------
#  How to use
#    1) open QuestaSim
#    2) File > Change Directory...  ->  choose the folder lab10_coverage
#    3) type at the Transcript prompt :   do run.do
#
#  Scenario : edit the line  set SCEN "basic"  below, or export the
#  environment variable LAB10_SCEN before starting QuestaSim.
#
#       basic / extra / edge
#
#  The script does NOT quit, so the waveform and the Coverage window can
#  be explored afterwards.
#=====================================================================

onerror {puts "!! ERROR : a step failed"; quit -code 90}

if {![file exists src/alu_fsm.vhd]} {
    puts "!! wrong folder : [pwd]"
    puts "!! please change the directory to lab10_coverage"
    quit -code 2
}

# --- choose the scenario --------------------------------------------
set SCEN "basic"
if {[info exists ::env(LAB10_SCEN)]} {
    set SCEN $::env(LAB10_SCEN)
}
if {[lsearch -exact {basic extra edge} $SCEN] < 0} {
    puts "!! unknown scenario : $SCEN"
    quit -code 2
}

puts "===================================================================="
puts " LAB 10 : code coverage for VHDL -- scenario $SCEN"
puts " cwd    : [pwd]"
puts "===================================================================="

# --- build a fresh work library -------------------------------------
if {[file exists work]} { file delete -force work }
vlib work
vmap work work

# --- compile : the DUT WITH coverage, the testbench WITHOUT ---------
puts "---- compile : the DUT is instrumented with +cover=bcesft ----"
vcom -2008 src/alu_fsm.vhd +cover=bcesft
vcom -2008 tb/tb_alu_fsm.vhd

# --- elaborate and run ----------------------------------------------
puts "---- run ----"
vsim -coverage work.tb_alu_fsm -gTEST=$SCEN

if {[catch {add wave -r /tb_alu_fsm/*} err]} {
    puts "no wave window: $err"
}

run -all

# ---- the coverage of this single test -------------------------------
puts ""
puts "---- coverage of test '$SCEN' alone ----"
coverage report -summary -codeAll

puts ""
puts "===================================================================="
puts " to save this test   :  coverage save results/$SCEN.ucdb -codeAll -testname $SCEN"
puts " to merge the tests  :  do merge.do"
puts " to make the reports :  do report.do"
puts "===================================================================="
# intentionally no quit, so that the waveform can be explored
