#=====================================================================
# lab2_test_extra.do  --  Lab 2 : run test 2 with coverage enabled
#---------------------------------------------------------------------
#   vsim -c -coverage -onfinish stop work.tb_cmd_fsm +TEST=extra \
#        -do "do scripts/lab2_test_extra.do"
#
# This test covers the part of the design that lab 1 deliberately left
# out:  commands 4'h3 / 4'h4 / default, the "a < b" condition row and
# the FSM states ST_DONE / transitions WAIT->DONE and DONE->IDLE.
#
# Note: the testbench is the SAME module as in lab 1, so the instance
# path is the same (/tb_cmd_fsm/dut).  That is what makes the merge in
# lab 3 add the hits together instead of adding the bins.
#=====================================================================

if {[file exists ./modelsim.ini] == 0} {
    cd [file normalize [file join [file dirname [info script]] ..]]
}

puts "== Lab 2 : test 'extra' =="

vsim -coverage work.tb_cmd_fsm +TEST=extra
run -all

puts ""
puts "---- coverage of test 2 (extra) alone ----"
coverage report -summary -codeAll -instance=/tb_cmd_fsm/dut

if {![file exists results]} { file mkdir results }
coverage save results/extra.ucdb -codeAll -testname extra

puts "== Lab 2 : done =="
