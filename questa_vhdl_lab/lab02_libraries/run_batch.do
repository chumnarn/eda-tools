#=====================================================================
# run_batch.do  --  LAB 02 : design libraries
#=====================================================================

onerror {puts "!! ERROR : ขั้นตอนล้มเหลว -- ดูข้อความข้างบน"; quit -code 90}

if {![file exists src/adder_pkg.vhd]} {
    puts "!! ผิดโฟลเดอร์ : [pwd]"
    quit -code 2
}

puts "===================================================================="
puts " LAB 02 : design libraries"
puts "===================================================================="

#--- 1. ลบไลบรารีเก่าทิ้ง (ให้เริ่มจากศูนย์เสมอ) -------------------------
#    ห้ามลบ modelsim.ini !!  ตัว simulator โหลดไฟล์นี้ไว้ตั้งแต่ตอนเริ่ม
#    ถ้าลบทิ้ง แล้วคอมไพล์ใน session เดียวกันจะหา mapping ของไลบรารี
#    อื่นไม่เจอ และขึ้น error "Unknown identifier <lib>"
if {[file exists work]}       { file delete -force work }
if {[file exists lib/ip_lib]} { file delete -force lib/ip_lib }

file mkdir lib

#--- 2. สร้างไลบรารี -----------------------------------------------------
#    vlib <path>        สร้างไลบรารีจริง (โฟลเดอร์เก็บ design unit)
#    vmap <name> <path> ผูก "ชื่อเชิงตรรกะ" (logical) เข้ากับโฟลเดอร์จริง
#                      แล้วบันทึกการผูกไว้ใน modelsim.ini
vlib work
vmap work work
vlib lib/ip_lib
vmap ip_lib lib/ip_lib

puts "---- mappings in modelsim.ini ----"
set fh [open modelsim.ini r]
set inlib 0
while {[gets $fh line] >= 0} {
    if {[string match "\[*" $line]} {
        set inlib [expr {[string equal "[Library]" $line]}]
        continue
    }
    if {$inlib && [regexp {^[A-Za-z_][A-Za-z0-9_]*\s*=} $line]} {
        puts "  [Library] $line"
    }
}
close $fh

#--- 3. คอมไพล์แยกตามไลบรารี -------------------------------------------
#    -work <lib> เลือกปลายทางของ design unit
vcom -2008 -work work   src/adder_pkg.vhd
vcom -2008 -work ip_lib src/ip_core.vhd
vcom -2008 -work work   src/counter_top.vhd
vcom -2008 -work work   tb/tb_libraries.vhd

puts "---- contents of ip_lib ----"
if {[catch {vdir -lib ip_lib} m]} {
    puts "  (vdir -lib not available: $m)"
} else {
    puts $m
}

#--- 4. โหลดและรัน ------------------------------------------------------
#    สังเกตว่า tb_libraries อยู่ใน work แต่ข้างในมีการอ้าง ip_lib
#    ตัว simulator หา ip_lib ได้จากการผูกใน modelsim.ini
vsim work.tb_libraries

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
