#=====================================================================
#  compile.do  --  LAB 10 : compile the DUT with code coverage
#---------------------------------------------------------------------
#  Run from the GUI :  File > Change Directory -> lab10_coverage
#                     then                do compile.do
#  Run from the CLI :  vsim -c -do compile.do
#
#  NOTE 1 : only the DUT is instrumented (+cover=bcesft).
#           The testbench is compiled WITHOUT coverage, so every number
#           in the reports belongs to the DUT and not to the stimulus.
#
#  NOTE 2 : +cover is a plusarg.  The spec is given explicitly:
#              s = statement   b = branch    c = condition
#              e = expression  f = FSM       t = toggle
#           The tool's own default (when no spec is given) is "sbceft",
#           see pitfall.do for the measurement of that.
#=====================================================================

onerror {puts "!! ERROR : a step failed"; quit -code 90}

if {![file exists src/alu_fsm.vhd]} {
    puts "!! wrong folder : [pwd]"
    quit -code 2
}

puts "===================================================================="
puts " LAB 10 : compile"
puts " cwd    : [pwd]"
puts "===================================================================="

# ---- (re)create the work library ------------------------------------
if {[file exists work]} { file delete -force work }
vlib work
vmap work work

# ---- the DUT : instrumented for code coverage ------------------------
vcom -2008 src/alu_fsm.vhd +cover=bcesft

# ---- the testbench : NO coverage instrumentation ---------------------
# ONE single testbench, the test is selected with a generic (+TEST=...).
# Keeping the name identical keeps the instance path identical, which is
# what makes the merge in merge.do work.
vcom -2008 tb/tb_alu_fsm.vhd

# ---- the two testbenches of the "pitfall" demo ------------------------
vcom -2008 tb/pitfall/tb_alu_fsm_alt.vhd
vcom -2008 tb/pitfall/tb_alu_fsm_finish.vhd

puts "== LAB 10 : compile done =="
