# =====================================================================
# run_pnr.tcl — ส่งต่อจากเน็ตลิสต์ของ Precision ไปทำ Place & Route ใน Vivado
#                แล้วตรวจเกณฑ์ก่อนสร้าง bitstream
#
# วิธีรัน (โหมด non-project / in-memory)
#   vivado -mode batch -source run_pnr.tcl
#
# ตัวแปรที่ต้องแก้ก่อนรัน
#   - edif_file : เน็ตลิสต์ EDIF ที่ได้จาก Precision
#   - out_dir   : โฟลเดอร์เก็บรายงาน
#
# ข้อสำคัญ
#   - Vivado ไม่ได้อ่านไฟล์ SDC โดยตรง ต้องแปลงเป็น XDC
#     (ในที่นี้ใช้ไฟล์ nexys_a7_100t.xdc ที่เขียนข้อกำหนดเวลาไว้แล้ว)
#   - เมื่ออ่าน EDIF เข้ามา Vivado จะไม่มี RTL ให้ debug จึงควรเก็บ
#     โปรเจกต์ RTL ไว้คู่กันเสมอ
# =====================================================================

set part       "xc7a100tcsg324-1"
set top        "top_alu8"
set edif_file  "../netlist/top_alu8.edif"
set xdc_file   "nexys_a7_100t.xdc"
set out_dir    "vivado_out"

file mkdir $out_dir

# ---------------------------------------------------------------------
# 1) อ่านเน็ตลิสต์และข้อจำกัด
# ---------------------------------------------------------------------
read_edif $edif_file
read_xdc  $xdc_file

# ผูกเน็ตลิสต์เข้ากับข้อจำกัดและเลือกพอร์ตบนสุด
link_design -part $part -top $top

# ---------------------------------------------------------------------
# 2) ขั้นตอนการทำให้ดีที่สุด
#    ลำดับนี้ตรงกับค่าเริ่มต้นของ Vivado ในโหมด "Performance_Explore"
# ---------------------------------------------------------------------
opt_design
place_design
phys_opt_design
route_design

# ---------------------------------------------------------------------
# 3) รายงานผล
# ---------------------------------------------------------------------
report_timing_summary -file $out_dir/timing_summary.rpt
report_utilization   -file $out_dir/utilization.rpt
report_drc           -file $out_dir/drc.rpt
report_methodology   -file $out_dir/methodology.rpt
report_clock_utilization -file $out_dir/clock_utilization.rpt

# สร้าง bitstream เฉพาะเมื่อผ่านเกณฑ์เท่านั้น (ดู check_signoff.tcl)
source check_signoff.tcl

if {$signoff_ok} {
    write_bitstream -force $out_dir/${top}.bit
    puts "---- SIGNOFF PASSED: bitstream written ----"
} else {
    puts "---- SIGNOFF FAILED: bitstream NOT written ----"
    error "Sign-off checks failed. See $out_dir/signoff_report.txt"
}
