#=====================================================================
# run.do  --  LAB 08 : advanced stimulus (GUI variant)
#---------------------------------------------------------------------
#  How to use
#    1) start QuestaSim
#    2) File > Change Directory...  ->  choose lab08_stimulus
#    3) type this at the Transcript prompt :
#           source run.do
#
#  The generics of the testbench can be changed here or on the vsim
#  command line, for example :
#           vsim -gNUM_RANDOM=16 -gSEED1=1 -gSEED2=2 work.tb_stimulus
#=====================================================================

onerror {puts "!! ERROR : step failed -- see the message above"; quit -code 90}

if {![file exists src/ram8.vhd]} {
    puts "!! wrong folder : [pwd]"
    puts "!! this script must be run from lab08_stimulus"
    quit -code 2
}

puts "===================================================================="
puts " LAB 08 : advanced stimulus"
puts " cwd : [pwd]"
puts "===================================================================="

#--- 1. build the library ------------------------------------------------
if {[file exists work]} { file delete -force work }
vlib work
vmap work work

#--- 2. compile (always with the VHDL-2008 standard) --------------------
vcom -2008 src/ram8.vhd
vcom -2008 tb/tb_stimulus.vhd

#--- 3. elaborate, the generics are the parameters of the lab ----------
vsim -gVECTOR_FILE=vectors.txt -gNUM_RANDOM=8 -gSEED1=12345 -gSEED2=67890 work.tb_stimulus

#--- 4. wave window ------------------------------------------------------
if {[catch {add wave -r /tb_stimulus/*} err]} {
    puts "no wave window: $err"
} else {
    add wave -r /tb_stimulus/dut/mem(0)
}

#--- 5. run ---------------------------------------------------------------
run -all

puts "===================================================================="
puts " simulation stopped at [time]"
puts " ---- the vectors of the file are in vectors.txt ---------------"
puts "   edit vectors.txt and run again to see the checker react"
puts " ---- to use other parameters, re-elaborate : -----------------"
puts "   vsim -gNUM_RANDOM=16 -gSEED1=1 -gSEED2=2 work.tb_stimulus"
puts "   run -all"
puts "===================================================================="
puts " (the simulator is left open -- type quit -f to close it)"
