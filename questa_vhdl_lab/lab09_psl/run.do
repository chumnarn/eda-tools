#=====================================================================
#  run.do  --  LAB 09 : PSL assertions in VHDL  (GUI variant)
#---------------------------------------------------------------------
#  How to use
#    1) open QuestaSim
#    2) File > Change Directory...  ->  choose the folder lab09_psl
#    3) type at the Transcript prompt :   do run.do
#
#  Scenario -- edit the line  set SCEN "good"  below, or export the
#  environment variable LAB09_SCEN before starting QuestaSim :
#
#       good    the correct design, embedded PSL enabled     (default)
#       buggy   the deliberately broken design, embedded PSL enabled
#                -> the property "req_ack" fires and an error is printed
#       nopsl   the deliberately broken design, compiled with -nopsl
#                -> the embedded PSL checker is switched off
#
#  The Wave window is opened automatically so that req / ack / busy can
#  be inspected.  The script does NOT quit, so the simulation stays open.
#=====================================================================

onerror {puts "!! ERROR : a step failed"; quit -code 90}

if {![file exists src/handshake.vhd]} {
    puts "!! wrong folder : [pwd]"
    puts "!! please change the directory to lab09_psl"
    quit -code 2
}

# --- choose the scenario --------------------------------------------
set SCEN "good"
if {[info exists ::env(LAB09_SCEN)]} {
    set SCEN $::env(LAB09_SCEN)
}

switch -- $SCEN {
    good  { set PSLOPT ""      ; set BUG false }
    buggy { set PSLOPT ""      ; set BUG true  }
    nopsl { set PSLOPT "-nopsl" ; set BUG true  }
    default {
        puts "!! unknown scenario : $SCEN"
        quit -code 2
    }
}

puts "===================================================================="
puts " LAB 09 : PSL assertions in VHDL -- scenario $SCEN"
puts " cwd    : [pwd]"
puts "===================================================================="

# --- build a fresh work library -------------------------------------
if {[file exists work]} { file delete -force work }
vlib work
vmap work work

# --- compile ---------------------------------------------------------
# embedded PSL parsing is ON by default, "-nopsl" switches it off
puts "---- compile ----"
if {$PSLOPT eq ""} {
    vcom -2008 src/handshake.vhd
} else {
    vcom -2008 $PSLOPT src/handshake.vhd
}
vcom -2008 tb/tb_handshake.vhd

# --- elaborate --------------------------------------------------------
if {$BUG} {
    vsim work.tb_handshake -gBUGGY=true
} else {
    vsim work.tb_handshake -gBUGGY=false
}

# --- wave window ------------------------------------------------------
# in "vsim -c" (batch) mode there is no wave window, so catch the error
if {[catch {add wave -r /tb_handshake/*} err]} {
    puts "no wave window: $err"
}

# --- run --------------------------------------------------------------
run -all

puts "===================================================================="
puts " simulation finished"
puts " scenario : $SCEN"
puts " -> look at the Transcript for the PSL messages"
puts " -> the Wave window shows the time line"
puts "===================================================================="
# intentionally no quit, so that the waveform can be explored
# type "quit -f" at the prompt when you are done
