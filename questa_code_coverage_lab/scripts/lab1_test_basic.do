#=====================================================================
# lab1_test_basic.do  --  Lab 1 : run test 1 with coverage enabled
#---------------------------------------------------------------------
#   vsim -c -coverage -onfinish stop work.tb_cmd_fsm +TEST=basic \
#        -do "do scripts/lab1_test_basic.do"
#
#   -coverage          : keep the coverage statistics
#   -onfinish stop     : do NOT quit the session when $finish is hit,
#                        otherwise the commands after "run -all" are
#                        silently skipped (a classic batch-mode trap).
#   +TEST=basic        : which stimulus the testbench should apply
#=====================================================================

if {[file exists ./modelsim.ini] == 0} {
    cd [file normalize [file join [file dirname [info script]] ..]]
}

puts "== Lab 1 : test 'basic' =="

vsim -coverage work.tb_cmd_fsm +TEST=basic
run -all

# ---- report what this single test achieved ----------------------------
puts ""
puts "---- coverage of test 1 (basic) alone ----"
coverage report -summary -codeAll -instance=/tb_cmd_fsm/dut

# ---- save the coverage database of this test -------------------------
if {![file exists results]} { file mkdir results }
coverage save results/basic.ucdb -codeAll -testname basic

puts "== Lab 1 : done =="
