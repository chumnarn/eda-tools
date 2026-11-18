#=====================================================================
# run_batch.do  --  LAB 01 : แบบ batch (ไม่มีหน้าต่าง) ใช้กับ CI
#---------------------------------------------------------------------
# เรียกด้วย :  run.cmd
#
# หลักการ :  testbench จะพิมพ์ "TEST_PASSED" เมื่อผ่าน
#            script นี้อ่านไฟล์ transcript แล้วตัดสิน pass/fail
#            แล้วส่งรหัสจบการทำงานกลับให้ Windows ด้วย quit -code
#=====================================================================

onerror {puts "!! ERROR : ขั้นตอนล้มเหลว"; quit -code 90}

if {![file exists src/counter.vhd]} {
    puts "!! ผิดโฟลเดอร์ : [pwd]"
    quit -code 2
}

puts "===================================================================="
puts " LAB 01 : first simulation (batch)"
puts "===================================================================="

if {[file exists work]} { file delete -force work }
vlib work
vmap work work

vcom -2008 src/counter.vhd
vcom -2008 tb/tb_counter.vhd

vsim work.tb_counter

#---------------------------------------------------------------------
# run -all อาจถูกหยุดกลางคันโดย severity failure ของ testbench
# ต้องห่อด้วย catch ไม่งั้น ModelSim จะ "รันสคริปต์นี้ซ้ำอีกรอบ"
#---------------------------------------------------------------------
if {[catch {run -all} err]} {
    puts "---- simulation stopped by an assertion : $err ----"
}

#--- ตัดสิน PASS/FAIL --------------------------------------------------
#  1) ถ้า testbench เขียนไฟล์ result.txt เอง ให้เชื่อไฟล์นั้น (ปลอดภัยที่สุด)
#  2) ถ้าไม่มี ให้ fallback ไป scan transcript ดูว่ามีคำว่า TEST_PASSED
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
