#=====================================================================
#  test_edge.do  --  LAB 10 : run test 'edge' with coverage enabled
#---------------------------------------------------------------------
#   vsim -c -coverage -onfinish stop work.tb_alu_fsm -gTEST=edge \
#        -do "do test_edge.do"
#
# This test covers the corner cases : the abort path of the FSM, the
# ADD with an overflow (the lane sum is added to the result) and a reset
# in the middle of a transaction.
#=====================================================================

onerror {puts "!! ERROR : a step failed"; quit -code 90}

if {![file exists src/alu_fsm.vhd]} {
    puts "!! wrong folder : [pwd]"
    quit -code 2
}

if {![file exists results]} { file mkdir results }

puts "===================================================================="
puts " LAB 10 : test 'edge'"
puts "===================================================================="

vsim -coverage work.tb_alu_fsm -gTEST=edge
run -all

set fh [open transcript r]
set txt [read $fh]
close $fh
set th [open results/test_edge_transcript.txt w]
puts -nonewline $th $txt
close $th

coverage save results/edge.ucdb -codeAll -testname edge

exec vcover report -summary -codeAll -output results/edge_report.txt results/edge.ucdb

puts ""
puts "---- coverage of test 'edge' alone ----"
puts [exec vcover report -summary -codeAll results/edge.ucdb]

puts "== LAB 10 : test 'edge' done =="
