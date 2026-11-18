#=====================================================================
#  test_basic.do  --  LAB 10 : run test 'basic' with coverage enabled
#---------------------------------------------------------------------
#   vsim -c -coverage -onfinish stop work.tb_alu_fsm -gTEST=basic \
#        -do "do test_basic.do"
#
#   -coverage        keep the coverage statistics
#   -onfinish stop   do NOT quit the session when the simulation ends,
#                    otherwise the commands after "run -all" are silently
#                    skipped (a classic batch mode trap, see pitfall.do)
#   -gTEST=basic     which stimulus the testbench applies
#=====================================================================

onerror {puts "!! ERROR : a step failed"; quit -code 90}

if {![file exists src/alu_fsm.vhd]} {
    puts "!! wrong folder : [pwd]"
    quit -code 2
}

if {![file exists results]} { file mkdir results }

puts "===================================================================="
puts " LAB 10 : test 'basic'"
puts "===================================================================="

vsim -coverage work.tb_alu_fsm -gTEST=basic
run -all

# ---- keep a copy of the transcript of this test ----------------------
set fh [open transcript r]
set txt [read $fh]
close $fh
set th [open results/test_basic_transcript.txt w]
puts -nonewline $th $txt
close $th

# ---- save the coverage database of this test --------------------------
coverage save results/basic.ucdb -codeAll -testname basic

# ---- the report of this single test -----------------------------------
exec vcover report -summary -codeAll -output results/basic_report.txt results/basic.ucdb

puts ""
puts "---- coverage of test 'basic' alone ----"
puts [exec vcover report -summary -codeAll results/basic.ucdb]

puts "== LAB 10 : test 'basic' done =="
