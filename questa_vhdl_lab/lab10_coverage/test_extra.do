#=====================================================================
#  test_extra.do  --  LAB 10 : run test 'extra' with coverage enabled
#---------------------------------------------------------------------
#   vsim -c -coverage -onfinish stop work.tb_alu_fsm -gTEST=extra \
#        -do "do test_extra.do"
#
# This test covers what test 'basic' deliberately left out : the bitwise
# AND and XOR paths of the ALU and the unsigned underflow of the SUB.
#
# NOTE : the testbench is the SAME module as in test_basic.do, so the
# instance path is the same (/tb_alu_fsm/dut).  That is what makes the
# merge in merge.do add the hits instead of adding the bins.
#=====================================================================

onerror {puts "!! ERROR : a step failed"; quit -code 90}

if {![file exists src/alu_fsm.vhd]} {
    puts "!! wrong folder : [pwd]"
    quit -code 2
}

if {![file exists results]} { file mkdir results }

puts "===================================================================="
puts " LAB 10 : test 'extra'"
puts "===================================================================="

vsim -coverage work.tb_alu_fsm -gTEST=extra
run -all

set fh [open transcript r]
set txt [read $fh]
close $fh
set th [open results/test_extra_transcript.txt w]
puts -nonewline $th $txt
close $th

coverage save results/extra.ucdb -codeAll -testname extra

exec vcover report -summary -codeAll -output results/extra_report.txt results/extra.ucdb

puts ""
puts "---- coverage of test 'extra' alone ----"
puts [exec vcover report -summary -codeAll results/extra.ucdb]

puts "== LAB 10 : test 'extra' done =="
