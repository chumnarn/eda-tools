#=====================================================================
# run_batch.do  --  LAB 07 : memory / RAM debugging (batch, no windows)
#---------------------------------------------------------------------
#  Called by :  run.cmd
#
#  The flow is:
#     1. compile src/ram.vhd and tb/tb_ram.vhd with vcom -2008
#     2. elaborate the testbench with +acc
#     3. put the content of mem_init.txt into the memory with "mem load"
#     4. look at the memory with "mem display" / "mem search" / "mem save"
#     5. run the testbench, it checks the memory and prints TEST_PASSED
#     6. write PASS / FAIL into result.txt for run.cmd
#=====================================================================

onerror {puts "!! ERROR : step failed"; quit -code 90}

if {![file exists src/ram.vhd]} {
    puts "!! wrong folder : [pwd]"
    puts "!! this script must be run from lab07_memory"
    quit -code 2
}

puts "===================================================================="
puts " LAB 07 : memory / RAM debugging (batch)"
puts "===================================================================="

#--- 1. build the library ------------------------------------------------
if {[file exists work]} { file delete -force work }
vlib work
vmap work work

vcom -2008 src/ram.vhd
vcom -2008 tb/tb_ram.vhd

#--- 2. elaborate the testbench -----------------------------------------
# +acc gives the simulator read/write access to the signals, so that the
# "mem" commands can look into the array and write into it.
vsim -voptargs=+acc work.tb_ram

#--- 3. list every memory of the design ---------------------------------
set txt [mem list -r]
puts "--- mem list -r ---"
puts $txt
set fh [open mem_list.txt w]
puts $fh $txt
close $fh

#--- 4. initialise the memory from the data file ------------------------
#     (done at time 0, before the testbench starts)
mem load -format hex -infile mem_init.txt -startaddress 0 -endaddress 255 /tb_ram/dut/mem

#--- 5. look at the memory ----------------------------------------------
set txt [mem display -dataradix hexadecimal -wordsperline 16 /tb_ram/dut/mem]
puts "--- mem display (after mem load) ---"
puts $txt
set fh [open mem_display_loaded.txt w]
puts $fh $txt
close $fh

set txt [mem save -outfile mem_saved.txt -format hex /tb_ram/dut/mem]
set fh [open mem_save.txt w]
puts $fh $txt
close $fh

set txt [mem search -glob 3F /tb_ram/dut/mem]
puts "--- mem search -glob 3F ---"
puts $txt
set fh [open mem_search.txt w]
puts $fh $txt
close $fh

#--- 6. run the testbench ------------------------------------------------
run -all

#--- 7. the memory after the testbench wrote its own pattern ------------
set txt [mem display -dataradix hexadecimal -wordsperline 16 /tb_ram/dut/mem]
puts "--- mem display (after the run) ---"
puts $txt
set fh [open mem_display_final.txt w]
puts $fh $txt
close $fh

#--- 8. judge the result -------------------------------------------------
set fh [open transcript r]
set txt [read $fh]
close $fh

set rf [open result.txt w]
if {[regexp {TEST_PASSED} $txt]} {
    puts $rf "PASS"
    close $rf
    puts "RESULT: PASS"
    quit -code 0
} else {
    puts $rf "FAIL"
    close $rf
    puts "RESULT: FAIL"
    quit -code 1
}
