#=====================================================================
# run_noacc.do  --  LAB 07 : what happens WITHOUT "+acc" ?
#---------------------------------------------------------------------
#  Called by hand :  vsim -c -onfinish stop -do "do run_noacc.do"
#
#  It elaborates the same testbench WITHOUT the +acc switch and then
#  repeats the memory commands, so that the difference (if there is
#  one) can be seen with the own eyes.
#  The outcome is written to noacc_result.txt.
#=====================================================================

onerror {puts "!! ERROR : step failed"; quit -code 90}

if {![file exists src/ram.vhd]} {
    puts "!! wrong folder : [pwd]"
    quit -code 2
}

if {[file exists work]} { file delete -force work }
vlib work
vmap work work
vcom -2008 src/ram.vhd
vcom -2008 tb/tb_ram.vhd

puts "===================================================================="
puts " LAB 07 : the same run WITHOUT -voptargs=+acc"
puts "===================================================================="

vsim work.tb_ram

puts "--- mem list -r ---"
set t [mem list -r]
puts $t

puts "--- mem load -format hex -infile mem_init.txt ... ---"
set load_ok 0
if {[catch {mem load -format hex -infile mem_init.txt -startaddress 0 -endaddress 255 /tb_ram/dut/mem} e]} {
    puts "MEM LOAD FAILED : $e"
} else {
    set load_ok 1
    puts "MEM LOAD : no error message"
}

puts "--- mem display ---"
set t [mem display -dataradix hexadecimal -wordsperline 16 /tb_ram/dut/mem]
puts $t
set fh [open noacc_display.txt w]
puts $fh $t
close $fh

puts "--- mem save / mem search ---"
if {[catch {mem save -outfile noacc_saved.txt -format hex /tb_ram/dut/mem} e]} {
    puts "MEM SAVE FAILED : $e"
} else {
    puts "MEM SAVE : no error message"
}
if {[catch {mem search -glob 3F /tb_ram/dut/mem} e]} {
    puts "MEM SEARCH FAILED : $e"
} else {
    puts "MEM SEARCH : no error message"
}

run -all

set fh [open transcript r]
set txt [read $fh]
close $fh

set rf [open noacc_result.txt w]
if {[regexp {TEST_PASSED} $txt]} {
    puts $rf "PASS without +acc : the testbench found all 256 words"
} else {
    puts $rf "FAIL without +acc"
}
close $rf
puts "noacc_result.txt written"
quit -code 0
