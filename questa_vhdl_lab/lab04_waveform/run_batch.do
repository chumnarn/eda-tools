#=====================================================================
# run_batch.do  --  LAB 04 : waveform analysis (WLF + VCD)
#=====================================================================

onerror {puts "!! ERROR : step failed"; quit -code 90}

if {![file exists src/clock_div.vhd]} {
    puts "!! wrong folder : [pwd]"
    quit -code 2
}

puts "===================================================================="
puts " LAB 04 : waveform analysis"
puts "===================================================================="

if {[file exists work]} { file delete -force work }
vlib work
vmap work work

vcom -2008 src/clock_div.vhd
vcom -2008 tb/tb_divider.vhd

vsim work.tb_divider

#---------------------------------------------------------------------
# 1. บันทึกทุกสัญญาณลงไฟล์ WLF (รูปแบบ native ของ QuestaSim)
#    ไฟล์จะชื่อ vsim.wlf ในโฟลเดอร์ปัจจุบัน
#---------------------------------------------------------------------
log -recursive /*

#---------------------------------------------------------------------
# 2. เปิดหน้าต่าง Wave (ถ้าเป็นโหมด console จะไม่มีหน้าต่าง)
#---------------------------------------------------------------------
if {[catch {add wave -r /*} err]} {
    puts "  (no wave window in console mode: $err)"
}

#---------------------------------------------------------------------
# 3. เตรียมส่งออก VCD  -- ต้องทำ "ก่อน" run มิฉะนั้นไฟล์จะได้แค่
#    ส่วนหัว (var declarations) แต่ไม่มีค่าที่เปลี่ยนแปลงเลย
#---------------------------------------------------------------------
file mkdir results
if {[catch {
    vcd file results/waveform.vcd
    vcd add -r /*
} err]} {
    puts "  (vcd setup failed: $err)"
}

if {[catch {run -all} err]} {
    puts "---- simulation stopped by an assertion : $err ----"
}

#---------------------------------------------------------------------
# 4. ปิดและ flush ไฟล์ VCD
#---------------------------------------------------------------------
if {[catch {vcd flush} err]} {
    puts "  (vcd flush failed: $err)"
}

foreach f {vsim.wlf results/waveform.vcd} {
    if {[file exists $f]} {
        puts [format "  %-34s %8d bytes" $f [file size $f]]
    } else {
        puts "  $f : NOT CREATED"
    }
}
# หมายเหตุ : การแปลง WLF -> VCD ด้วย wlf2vcd ต้องทำหลัง simulator
#            ปิดตัวลงแล้ว เพราะไฟล์ WLF ถูกล็อกไว้ระหว่างจำลอง

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
