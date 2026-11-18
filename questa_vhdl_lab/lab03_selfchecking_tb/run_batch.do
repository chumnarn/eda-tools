#=====================================================================
# run_batch.do  --  LAB 03 : self-checking testbench
#---------------------------------------------------------------------
# เรียกแบบปกติ      :  run.cmd
# เรียกแบบ "ตั้งใจให้ fail" :  run_fail.cmd
#   (ส่งตัวแปร FAILMODE=1 เข้ามาก่อน do ไฟล์นี้)
#=====================================================================

onerror {puts "!! ERROR : step failed"; quit -code 90}

if {![file exists src/fsm_timer.vhd]} {
    puts "!! wrong folder : [pwd]"
    quit -code 2
}

puts "===================================================================="
puts " LAB 03 : self-checking testbench"
puts "===================================================================="

if {[file exists work]} { file delete -force work }
vlib work
vmap work work

vcom -2008 src/fsm_timer.vhd
vcom -2008 tb/tb_timer.vhd

if {[info exists FAILMODE] && $FAILMODE} {
    puts "---- FAILMODE : inject an intentional error ----"
    vsim work.tb_timer -gINJECT_ERROR=true
} else {
    vsim work.tb_timer
}

#---------------------------------------------------------------------
# run -all อาจถูกหยุดกลางคันโดย severity failure ของ testbench
# ต้องห่อด้วย catch ไม่งั้น ModelSim จะ "รันสคริปต์นี้ซ้ำอีกรอบ"
# (พฤติกรรมจริงที่วัดได้บน ModelSim DE-64 2026.1)
#---------------------------------------------------------------------
if {[catch {run -all} err]} {
    puts "---- simulation stopped by an assertion : $err ----"
}

#--- ตัดสิน PASS/FAIL --------------------------------------------------
proc lab_verdict {} {
    if {[file exists result.txt]} {
        set fh [open result.txt r]
        set v [string trim [read $fh]]
        close $fh
        return [string toupper $v]
    }
    if {[file exists transcript]} {
        set fh [open transcript r]
        set t [read $fh]
        close $fh
        if {[regexp {TEST_PASSED} $t]} { return "PASS" }
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
