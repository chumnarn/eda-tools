#=====================================================================
# run_batch.do  --  LAB 06 : dataflow / finding the source of X
#=====================================================================

onerror {puts "!! ERROR : step failed"; quit -code 90}

if {![file exists src/x_demo.vhd]} {
    puts "!! wrong folder : [pwd]"
    quit -code 2
}

puts "===================================================================="
puts " LAB 06 : dataflow -- finding the source of X"
puts "===================================================================="

if {[file exists work]} { file delete -force work }
vlib work
vmap work work

vcom -2008 src/x_demo.vhd
vcom -2008 tb/tb_x.vhd

vsim work.tb_x

if {[catch {add wave -r /*} err]} {
    puts "  (no wave window in console mode: $err)"
}

if {[catch {run -all} err]} {
    puts "---- simulation stopped by an assertion : $err ----"
}

#---------------------------------------------------------------------
# ไล่หาต้นเหตุของ X : ดูสัญญาณภายในทีละชั้นของ hierarchy
#---------------------------------------------------------------------
puts "---- internal signals of the DUT ----"
foreach s {acc never_driven} {
    set v [examine -radix hex -value /tb_x/dut/$s]
    puts "  /tb_x/dut/$s = $v"
}
foreach s {eq eq2 sum} {
    set v [examine -radix hex -value /tb_x/$s]
    puts "  /tb_x/$s = $v"
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
