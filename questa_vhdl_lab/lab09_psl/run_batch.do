#=====================================================================
#  run_batch.do  --  LAB 09 : PSL assertions in VHDL  (batch)
#---------------------------------------------------------------------
#  Scenario : the CORRECT design, embedded PSL parsing ENABLED.
#             PSL parsing is ON by default in Questa 2026.1, so there
#             is NO extra vcom option here.
#  Expect  : the simulation passes and NO PSL assertion fires.
#
#  Run     :  vsim -c -onfinish stop -do "do run_batch.do"
#             (run.cmd does exactly this)
#=====================================================================

onerror {puts "!! ERROR : a step failed"; quit -code 90}

if {![file exists src/handshake.vhd]} {
    puts "!! wrong folder : [pwd]"
    quit -code 2
}

puts "===================================================================="
puts " LAB 09 : PSL assertions in VHDL -- scenario GOOD"
puts " cwd    : [pwd]"
puts "===================================================================="

# --- build a fresh work library -------------------------------------
if {[file exists work]} { file delete -force work }
vlib work
vmap work work

# --- compile ---------------------------------------------------------
# NOTE : no -psl / -nopsl option is needed, embedded PSL is parsed by
#        default.  (vcom only offers -nopsl, -pslext and -pslfile.)
puts "---- compile : embedded PSL parsing is ON by default ----"
vcom -2008 src/handshake.vhd
vcom -2008 tb/tb_handshake.vhd

# --- elaborate and run ----------------------------------------------
# -gBUGGY=false : select the correct DUT variant
puts "---- elaborate and run ----"
vsim work.tb_handshake -gBUGGY=false
run -all

# --- collect the transcript -----------------------------------------
set fh [open transcript r]
set txt [read $fh]
close $fh

if {![file exists results]} { file mkdir results }
set th [open results/good_transcript.txt w]
puts -nonewline $th $txt
close $th

# --- verdict ---------------------------------------------------------
# PASS = the testbench printed TEST_PASSED
#       AND no embedded PSL assertion fired
set tb_ok     [regexp {TEST_PASSED}    $txt]
set psl_error [regexp {Assertion failed} $txt]

set rf [open result.txt w]
if {$tb_ok && !$psl_error} {
    puts $rf "PASS"
    close $rf
    puts "---- no PSL assertion fired, as expected ----"
    puts "RESULT: PASS"
    quit -code 0
} else {
    puts $rf "FAIL"
    close $rf
    if {!$tb_ok}    { puts "!! the testbench did not print TEST_PASSED" }
    if {$psl_error} { puts "!! a PSL assertion fired although the design is correct" }
    puts "RESULT: FAIL"
    quit -code 1
}
