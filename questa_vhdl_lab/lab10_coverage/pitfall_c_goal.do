#=====================================================================
#  pitfall_c_goal.do  --  LAB 10 : PITFALL 3
#---------------------------------------------------------------------
#  The command "coverage goal" only works in the COVERAGE VIEW, it is
#  not available during a normal simulation.  In a normal simulation it
#  answers with
#
#      Coverage sub-command 'goal' may be used in viewcov mode only.
#
#  The Coverage View is started with
#      vsim -viewcov <file>.ucdb
#  (run.cmd starts it once and stores the output in
#   results/pitfall_goal_viewcov.txt)
#
#  NOTE : outside the Coverage View the command really FAILS, it raises
#  an error of severity error.  The onerror handler of this script
#  therefore only reports, it must not quit, otherwise the whole lab
#  would stop right here.
#=====================================================================

onerror {puts "---- 'coverage goal' is not available here -- that is the point of this lab ----"}

if {![file exists src/alu_fsm.vhd]} {
    puts "!! wrong folder : [pwd]"
    quit -code 2
}

if {![file exists results]} { file mkdir results }

puts "===================================================================="
puts " LAB 10 : PITFALL 3 -- 'coverage goal' outside the Coverage View"
puts "===================================================================="

vsim -coverage work.tb_alu_fsm -gTEST=basic
run -all

puts ""
puts "---- now calling 'coverage goal' in a NORMAL simulation ----"
coverage goal

# ---- keep the transcript, it holds the exact message -----------------
set fh [open transcript r]
set txt [read $fh]
close $fh
set th [open results/pitfall_goal_normal.txt w]
puts -nonewline $th $txt
close $th

puts ""
puts "---- the exact answer is stored in results/pitfall_goal_normal.txt ----"

puts "== LAB 10 : pitfall 3 done =="
