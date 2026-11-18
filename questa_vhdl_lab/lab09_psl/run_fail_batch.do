#=====================================================================
#  run_fail_batch.do  --  LAB 09 : the DELIBERATELY BUGGY variant
#---------------------------------------------------------------------
#  Scenario : the buggy DUT (BUGGY=true).  The embedded PSL property
#             "req_ack"  ( always (req -> next ack) )  must FAIL,
#             because the buggy design answers one cycle too late.
#
#  This script is EXPECTED to end with a non zero exit code.
#  It writes
#      result.txt              -> "FAIL"   (the design really did fail)
#      results/psl_check.txt   -> "DETECTED" or "NOT_DETECTED"
#      results/psl_failure.txt -> the raw PSL error lines
#
#  Run     :  vsim -c -onfinish stop -do "do run_fail_batch.do"
#             (run_fail.cmd does exactly this)
#=====================================================================

onerror {puts "!! ERROR : a step failed"; quit -code 90}

if {![file exists src/handshake.vhd]} {
    puts "!! wrong folder : [pwd]"
    quit -code 2
}

puts "===================================================================="
puts " LAB 09 : PSL assertions in VHDL -- scenario BUGGY"
puts " THIS SCENARIO IS EXPECTED TO FAIL -- the PSL assertion must fire"
puts " cwd    : [pwd]"
puts "===================================================================="

if {[file exists work]} { file delete -force work }
vlib work
vmap work work

puts "---- compile : embedded PSL parsing is ON by default ----"
vcom -2008 src/handshake.vhd
vcom -2008 tb/tb_handshake.vhd

puts "---- elaborate and run (BUGGY=true) ----"
vsim work.tb_handshake -gBUGGY=true
run -all

# --- collect the transcript -----------------------------------------
set fh [open transcript r]
set txt [read $fh]
close $fh

if {![file exists results]} { file mkdir results }
set th [open results/buggy_transcript.txt w]
puts -nonewline $th $txt
close $th

# --- pull out the PSL error lines -----------------------------------
set psl_lines {}
foreach l [split $txt "\n"] {
    if {[string match "*Assertion failed*" $l] || [string match "*req_ack*" $l]} {
        lappend psl_lines $l
    }
}

set pf [open results/psl_failure.txt w]
foreach l $psl_lines { puts $pf $l }
close $pf

if {[llength $psl_lines] > 0} {
    set detected "DETECTED"
} else {
    set detected "NOT_DETECTED"
}

set pc [open results/psl_check.txt w]
puts $pc $detected
close $pc

# --- verdict ---------------------------------------------------------
# The design failed, therefore result.txt is FAIL on purpose.
set rf [open result.txt w]
puts $rf "FAIL"
close $rf

puts ""
puts "---- the embedded PSL assertion fired like this ----"
foreach l $psl_lines { puts $l }
puts "---------------------------------------------------"
puts "PSL assertion : $detected"

if {$detected eq "DETECTED"} {
    puts "RESULT: FAIL   (this is the EXPECTED outcome of this scenario)"
    quit -code 1
} else {
    puts "RESULT: FAIL   (UNEXPECTED : the PSL assertion did not fire)"
    quit -code 2
}
