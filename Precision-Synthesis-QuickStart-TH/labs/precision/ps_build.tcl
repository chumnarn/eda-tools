# =====================================================================
# ps_build.tcl — สคริปต์ Precision Synthesis สำหรับโปรเจกต์ top_alu8
#
# ลำดับคำสั่งในไฟล์นี้ตรงกับลำดับงานในคู่มือ PS2018.1 ทุกขั้น:
#   1) Set-Up Precision  -> สร้างโปรเจกต์ / เพิ่มไฟล์ / เลือกอุปกรณ์ / ตั้งความถี่
#   2) Run Synthesis     -> compile แล้ว synthesize
#   3) Analyze           -> รายงานเวลา/พื้นที่ และส่งต่อเน็ตลิสต์
#
# วิธีใช้
#   ps_shell -f ps_build.tcl            (บน Linux/macOS)
#   precision_synthesis -f ps_build.tcl (ตามชื่อไฟล์เรียกของรุ่นที่ใช้)
#
# ข้อสำคัญมาก
#   ชื่อคำสั่งใน Precision เปลี่ยนแปลงได้ตามรุ่น (PS2018.1 กับรุ่นใหม่กว่า
#   อาจต่างกัน) วิธีที่ปลอดภัยที่สุดสำหรับผู้เรียนคือ
#       1) ทำขั้นตอนทั้งหมดใน GUI ครั้งแรก
#       2) ใช้ File > Save Command File เพื่อเก็บคำสั่งที่คุณทำจริง
#          ลงเป็นสคริปต์ แล้วใช้สคริปต์นั้นเป็นหลักในการรันซ้ำ
#   คำสั่งในไฟล์นี้จัดทำขึ้นตามรูปแบบของ Precision RTL Synthesis
#   (add_input_file / setup_design / compile / synthesize) ซึ่งเป็นรูปแบบ
#   เดียวกับที่เอกสารของ Xilinx แนะนำไว้ โปรดเทียบกับ Command Reference
#   ของรุ่นที่ติดตั้งจริงก่อนใช้งาน
# =====================================================================

# ---------------------------------------------------------------------
# ตัวแปรที่ต้องตั้งค่า (แก้ได้ที่บรรทัดเดียวเพื่อสลับการทดลอง)
# ---------------------------------------------------------------------
set design_name "top_alu8"
set rtl_dir     "../rtl"
set sdc_file    "../sdc/top_alu8.sdc"
set out_dir     "out_10ns"

# ข้อมูลอุปกรณ์เป้าหมาย: Digilent Nexys A7-100T
#   ตรวจสอบชื่อ family/part ที่รองรับในรุ่นที่ใช้ก่อนใช้งาน
set manufacturer "xilinx"
set family      "artix7"
set part        "xc7a100tcsg324"
set speed       "-1"

# ---------------------------------------------------------------------
# เตรียมโฟลเดอร์ผลลัพธ์
# ---------------------------------------------------------------------
file mkdir $out_dir

# =====================================================================
# ขั้นที่ 1: Set-Up Precision
# =====================================================================

# (1a) สร้างโปรเจกต์
#     GUI: File > New Project...  ตั้งชื่อและเลือกโฟลเดอร์
new_project $design_name -force -output $out_dir

# (1b) เพิ่มไฟล์ออกแบบ (VHDL)
#     GUI: File > Add Files... เลือกชนิดไฟล์ VHDL แล้วเลือกไฟล์
#     ลำดับการเพิ่มไฟล์สำคัญ: ต้องเพิ่ม "leaf" ก่อน "top"
add_input_file $rtl_dir/alu8.vhd      -vhdl
add_input_file $rtl_dir/hex2seg.vhd   -vhdl
add_input_file $rtl_dir/top_alu8.vhd  -vhdl

# (1c) เลือกอุปกรณ์ (FPGA part)
#     GUI: Design > Environment Settings > Setup Design
#     เลือก Xilinx > 7-Series > Artix-7 > XC7A100T > CSG324 > speed -1
setup_design -manufacturer $manufacturer $family -part $part -speed $speed

# (1d) กำหนดความถี่นาฬิกา
#     วิธีที่ 1 (GUI): Setup Timing > Add Clock... ใส่ 100 MHz
#     วิธีที่ 2 (ไฟล์ SDC): ใช้ไฟล์ด้านล่าง ซึ่งเป็นวิธีที่แนะนำ
#                      เพราะเก็บเงื่อนไขไว้กับโปรเจกต์และทำซ้ำได้
read_sdc $sdc_file

# ตรวจสอบว่ามีเส้นทางที่ไม่ถูกจำกัดเวลาหรือไม่
# ถ้าพบเส้นทาง unconstrained ให้กลับไปแก้ SDC ก่อนสังเคราะห์
report_timing -unconstrained_paths

# =====================================================================
# ขั้นที่ 2: Run Synthesis
# =====================================================================

# (2a) Compile — อ่านและตรวจ syntax/การเชื่อมต่อของ RTL
#     GUI: ปุ่ม Compile บนแถบเครื่องมือ
compile

# (2b) Synthesize — แปลง RTL เป็นเน็ตลิสต์และประมาณการเวลา
#     GUI: ปุ่ม Synthesize
#     ตัวเลือกที่ควรลองเปรียบเทียบ:
#       - Retiming (เปิด/ปิด) เพื่อดูผลต่อพื้นที่และเวลา
#       - Optimization effort (เพิ่มเวลาทำงาน อาจได้ QoR ที่ดีขึ้น)
synthesize

# =====================================================================
# ขั้นที่ 3: Analyze และส่งต่อ
# =====================================================================

# (3a) รายงานเวลา: setup slack ของเส้นทางวิกฤต และเส้นทางที่ไม่ถูกจำกัด
report_timing -max_paths 20          > $out_dir/timing.rpt
report_timing -unconstrained_paths    > $out_dir/unconstrained.rpt

# (3b) รายงานพื้นที่/การใช้ทรัพยากร (LUT, FF, DSP, BRAM ...)
report_area                          > $out_dir/area.rpt

# (3c) ส่งต่อไปยัง Vivado
#     EDIF  : เน็ตลิสต์กลอกลัย (เลือกชนิดไฟล์ตามรุ่น)
#     SDC   : เงื่อนไขเวลา (ต้องแปลงเป็น XDC ใน Vivado ตามบทที่ 4)
write_edif $out_dir/$design_name.edif
write_sdc  $out_dir/$design_name.sdc

# บันทึกสถานะการทำงานไว้ เพื่อเปรียบเทียบระหว่างรอบทดลอง
puts "---- PS build finished: $design_name ($sdc_file) ----"
puts "---- output directory: $out_dir ----"

# ออกจาก Precision
exit
