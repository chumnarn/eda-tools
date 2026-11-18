#=====================================================================
# compile.do  --  Lab 0 : create library and compile with coverage
#---------------------------------------------------------------------
# Run from the GUI :  File > Change Directory  ->  questa_code_coverage_lab
#                    then            do compile.do
# Run from the CLI :  vsim -c -do compile.do
#
# NOTE: only the RTL is instrumented (+cover=bcesft).  The testbench is
#       compiled WITHOUT coverage so that every number in the reports
#       belongs to the DUT and not to the stimulus code.
#=====================================================================

# ---- go to the lab root regardless of where vsim was started ----------
if {[file exists ./modelsim.ini] == 0} {
    cd [file normalize [file join [file dirname [info script]] ..]]
}

puts "== Lab 0 : compile =="
puts "   cwd = [pwd]"

# ---- (re)create the work library -------------------------------------
if {[file exists work]} {
    file delete -force work
}
vlib work
vmap work work

# ---- DUT : instrumented for code coverage ----------------------------
#    +cover=bcesft  ->  b=branch c=condition e=expression s=statement
#                       f=FSM t=toggle
vlog -work work rtl/cmd_fsm.v +cover=bcesft

# ---- Testbench : no coverage instrumentation --------------------------
#    One single testbench, the test is selected with a plusarg (+TEST=).
#    Keeping the name identical keeps the instance path identical, which
#    is what makes the merge in Lab 4 work.
vlog -work work tb/tb_cmd_fsm.v

# ---- (optional) the two testbenches used by the "Pitfall" demo ---------
vlog -work work tb/pitfall/tb_cmd_fsm_basic.v
vlog -work work tb/pitfall/tb_cmd_fsm_extra.v

puts "== Lab 0 : compile done =="
