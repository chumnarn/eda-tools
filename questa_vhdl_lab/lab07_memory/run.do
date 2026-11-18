#=====================================================================
# run.do  --  LAB 07 : memory / RAM debugging (GUI variant)
#---------------------------------------------------------------------
#  How to use
#    1) start QuestaSim
#    2) File > Change Directory...  ->  choose lab07_memory
#    3) type this at the Transcript prompt :
#           source run.do
#       ("source" and not "do", so that the path of the script is
#        passed correctly)
#
#  The script leaves the simulator open so that the memory can be
#  inspected by hand with the "mem" commands listed at the end.
#=====================================================================

onerror {puts "!! ERROR : step failed -- see the message above"; quit -code 90}

if {![file exists src/ram.vhd]} {
    puts "!! wrong folder : [pwd]"
    puts "!! this script must be run from lab07_memory"
    quit -code 2
}

puts "===================================================================="
puts " LAB 07 : memory / RAM debugging"
puts " cwd : [pwd]"
puts "===================================================================="

#--- 1. build the library ------------------------------------------------
if {[file exists work]} { file delete -force work }
vlib work
vmap work work

#--- 2. compile (always with the VHDL-2008 standard) --------------------
vcom -2008 src/ram.vhd
vcom -2008 tb/tb_ram.vhd

#--- 3. elaborate with +acc ---------------------------------------------
vsim -voptargs=+acc work.tb_ram

#--- 4. wave window ------------------------------------------------------
if {[catch {add wave -r /tb_ram/*} err]} {
    puts "no wave window: $err"
} else {
    add wave -r /tb_ram/dut/mem(0)
    add wave -r /tb_ram/dut/mem(1)
}

#--- 5. put the data file into the memory -------------------------------
mem load -format hex -infile mem_init.txt -startaddress 0 -endaddress 255 /tb_ram/dut/mem

#--- 6. show the memory --------------------------------------------------
mem list -r
mem display -dataradix hexadecimal -wordsperline 16 /tb_ram/dut/mem
mem search -glob 3F /tb_ram/dut/mem

#--- 7. run the testbench ------------------------------------------------
run -all

puts "===================================================================="
puts " simulation stopped at [time]"
puts " ---- try these commands by hand -------------------------------"
puts "   mem list -r"
puts "   mem display -dataradix hexadecimal /tb_ram/dut/mem"
puts "   mem save -outfile my_dump.txt -format hex /tb_ram/dut/mem"
puts "   mem search -glob 3F /tb_ram/dut/mem"
puts "   examine /tb_ram/dut/mem"
puts "===================================================================="
puts " (the simulator is left open -- type quit -f to close it)"
