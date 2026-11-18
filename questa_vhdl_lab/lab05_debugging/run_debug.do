#=====================================================================
# run_debug.do  --  LAB 05 : debugging session (แบบ batch)
#---------------------------------------------------------------------
# สิ่งที่สคริปต์นี้ทำ (ตรงกับที่นักเรียนจะทำใน GUI)
#   1. โหลด design
#   2. ตั้ง breakpoint ที่บรรทัดที่น่าสงสัย
#   3. รันจนกว่าจะติด breakpoint
#   4. ดูค่าของสัญญาณด้วยคำสั่ง examine
#   5. พิสูจน์ว่าผลลัพธ์ผิด แล้วสรุปว่าพบบั๊ก
#=====================================================================

onerror {puts "!! ERROR : step failed"; quit -code 90}

if {![file exists src/alu.vhd]} {
    puts "!! wrong folder : [pwd]"
    quit -code 2
}

puts "===================================================================="
puts " LAB 05 : debugging session"
puts "===================================================================="

if {[file exists work]} { file delete -force work }
vlib work
vmap work work

vcom -2008 src/alu.vhd
vcom -2008 tb/tb_alu.vhd

vsim work.tb_alu

#---------------------------------------------------------------------
# 1. ตั้ง breakpoint ที่บรรทัด 36 ของ src/alu.vhd
#    (บรรทัดที่ทำ A + B ในกรณี op = "01" ซึ่งควรเป็น A - B)
#---------------------------------------------------------------------
bp src/alu.vhd 36
puts "---- breakpoints ----"
puts [bp]

#---------------------------------------------------------------------
# 2. รันจนกว่าจะติด breakpoint
#    หมายเหตุ : เวลาจำลองปัจจุบันอยู่ในตัวแปร Tcl $::now
#              ห้ามใช้ [time] เพราะจะชนกับคำสั่ง time ของ Tcl
#---------------------------------------------------------------------
run -all
puts "---- simulation stopped at $::now ----"

#---------------------------------------------------------------------
# 3. ดูค่าของสัญญาณที่จุดที่หยุด
#    ข้อสำคัญ : ในโหมด console (vsim -c) เอาต์พุตของ examine ไม่ถูก
#              พิมพ์ออกมา ต้องเก็บค่าที่คืนมาแล้ว puts เอง
#---------------------------------------------------------------------
puts "---- values at the breakpoint ----"
foreach s {a b op y} {
    set v [examine -radix hex -value /tb_alu/dut/$s]
    puts "  $s = $v"
}

#---------------------------------------------------------------------
# 4. ตรวจว่าผลลัพธ์เป็น 0F แทนที่จะเป็น 05 -> ยืนยันว่าเป็นบั๊ก
#---------------------------------------------------------------------
set yval ""
if {[catch {set yval [examine -radix hex -value /tb_alu/dut/y]} err]} {
    puts "  (examine -value failed: $err)"
}
puts "---- y = $yval ----"

if {[regexp {0F|0f} $yval]} {
    puts "BUG CONFIRMED : y = 0F but A - B should be 05"
    set rf [open result.txt w]
    puts $rf "PASS"
    close $rf
    puts "RESULT: PASS"
    quit -code 0
} else {
    puts "BUG NOT CONFIRMED : y = $yval"
    set rf [open result.txt w]
    puts $rf "FAIL"
    close $rf
    puts "RESULT: FAIL"
    quit -code 1
}
