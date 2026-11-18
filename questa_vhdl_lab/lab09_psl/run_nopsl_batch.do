#=====================================================================
#  run_nopsl_batch.do  --  LAB 09 : the same buggy design, but with the
#                                  embedded PSL parser switched OFF
#---------------------------------------------------------------------
#  Scenario : BUGGY=true, but the DUT is compiled with  vcom -nopsl.
#             vcom -nopsl disables the embedded PSL language parsing, so
#             the "-- psl" comments are treated as ordinary comments and
#             NO checker is built into the design.
#
#  Expect  : the simulation runs exactly as before, but the PSL error
#            messages are GONE.  The bug is still in the RTL, the tool
#            simply does not look at it any more.
#
#  Run     :  vsim -c -onfinish stop -do "do run_nopsl_batch.do"
#             (run_nopsl.cmd does exactly this)
#=====================================================================

onerror {puts "!! ERROR : a step failed"; quit -code 90}

if {![file exists src/handshake.vhd]} {
    puts "!! wrong folder : [pwd]"
    quit -code 2
}

puts "===================================================================="
puts " LAB 09 : PSL assertions in VHDL -- scenario BUGGY without PSL"
puts " the DUT is compiled with 'vcom -2008 -nopsl'"
puts " cwd    : [pwd]"
puts "===================================================================="

if {[file exists work]} { file delete -force work }
vlib work
vmap work work

puts "---- compile : -nopsl disables the embedded PSL parsing ----"
vcom -2008 -nopsl src/handshake.vhd
vcom -2008 tb/tb_handshake.vhd

puts "---- elaborate and run (BUGGY=true) ----"
vsim work.tb_handshake -gBUGGY=true
run -all

# --- collect the transcript -----------------------------------------
set fh [open transcript r]
set txt [read $fh]
close $fh

if {![file exists results]} { file mkdir results }
set th [open results/nopsl_transcript.txt w]
puts -nonewline $th $txt
close $th

# --- verdict ---------------------------------------------------------
# PASS = the simulation completed AND no PSL assertion fired, which proves
#        that the -nopsl option really switched the checker off.
set psl_error [regexp {Assertion failed} $txt]
set sim_done  [regexp {handshake testbench finished} $txt]

set rf [open result.txt w]
if {!$psl_error && $sim_done} {
    puts $rf "PASS"
    close $rf
    puts "---- no PSL assertion fired : the checker is switched off ----"
    puts "RESULT: PASS"
    quit -code 0
} else {
    puts $rf "FAIL"
    close $rf
    if {$psl_error} { puts "!! a PSL assertion fired although -nopsl was used" }
    if {!$sim_done} { puts "!! the simulation did not run to the end" }
    puts "RESULT: FAIL"
    quit -code 1
}
