#=====================================================================
# run_batch.do  --  LAB 05 : debugging (run the failing test)
#=====================================================================
# ผลลัพธ์ที่คาดหวัง : FAIL เพราะ ALU มีบั๊กอยู่จริง
# ใช้ run_debug.do เพื่อไล่หาบั๊ก
#=====================================================================

onerror {puts "!! ERROR : step failed"; quit -code 90}

if {![file exists src/alu.vhd]} {
    puts "!! wrong folder : [pwd]"
    quit -code 2
}

puts "===================================================================="
puts " LAB 05 : debugging -- run the failing test"
puts "===================================================================="

if {[file exists work]} { file delete -force work }
vlib work
vmap work work

vcom -2008 src/alu.vhd
vcom -2008 tb/tb_alu.vhd

vsim work.tb_alu

if {[catch {add wave -r /*} err]} {
    puts "  (no wave window in console mode: $err)"
}

if {[catch {run -all} err]} {
    puts "---- simulation stopped by an assertion : $err ----"
}

proc lab_verdict {} {
    if {[file exists result.txt]} {
        set fh [open result.txt r]
        set v [string trim [read $fh]]
        close $fh
        return [string toupper $v]
    }
    return "FAIL"
}

if {[lab_verdict] eq "PASS"} {
    puts "RESULT: PASS"
    quit -code 0
} else {
    puts "RESULT: FAIL"
    quit -code 1
}
