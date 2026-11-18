# =====================================================================
# nexys_a7_100t.xdc — ข้อจำกัดการจัดวางพินสำหรับบอร์ด Digilent Nexys A7-100T
#
# แหล่งอ้างอิงพินหลัก: ไฟล์ Master ของ Digilent
#   https://github.com/Digilent/digilent-xdc (Nexys-A7-100T-Master.xdc)
# ไฟล์นี้ตัดเฉพาะพินที่โปรเจกต์ top_alu8 ใช้จริง และเปลี่ยนชื่อพอร์ต
# ให้ตรงกับระดับบนสุดของ top_alu8.vhd
#
# ท่านี้ใช้ "แทน" ไฟล์ SDC ของ Precision ในขั้นตอน Place & Route
# เพราะ Vivado ใช้รูปแบบ XDC (ส่วนข้อกำหนดเวลาใช้ไวยากรรมเดียวกับ SDC)
#
# ข้อควรรู้
#   - พิน LED/SW/BTN ทั้งหมดเป็น LVCMOS33 ยกเว้น SW[8], SW[9] ที่เป็น LVCMOS18
#   - ชื่อบอร์ดใน Vivado: digilentinc.com/nexys-a7-100T
#     part: xc7a100tcsg324-1
# =====================================================================

# ---------------------------------------------------------------------
# นาฬิกาหลัก 100 MHz
# ---------------------------------------------------------------------
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports {CLK100MHZ}]

# ---------------------------------------------------------------------
# ปุ่มรีเซ็ต (active low)
# ---------------------------------------------------------------------
set_property -dict { PACKAGE_PIN C12   IOSTANDARD LVCMOS33 } [get_ports {CPU_RESETN}]

# ---------------------------------------------------------------------
# ปุ่มกด: BTN[0]=BTNU, BTN[1]=BTNL, BTN[2]=BTNR
# ---------------------------------------------------------------------
set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports {BTN[0]}]
set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33 } [get_ports {BTN[1]}]
set_property -dict { PACKAGE_PIN M17   IOSTANDARD LVCMOS33 } [get_ports {BTN[2]}]

# ---------------------------------------------------------------------
# สวิตช์ 16 ตัว
# ---------------------------------------------------------------------
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports {SW[0]}]
set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports {SW[1]}]
set_property -dict { PACKAGE_PIN M13   IOSTANDARD LVCMOS33 } [get_ports {SW[2]}]
set_property -dict { PACKAGE_PIN R15   IOSTANDARD LVCMOS33 } [get_ports {SW[3]}]
set_property -dict { PACKAGE_PIN R17   IOSTANDARD LVCMOS33 } [get_ports {SW[4]}]
set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports {SW[5]}]
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports {SW[6]}]
set_property -dict { PACKAGE_PIN R13   IOSTANDARD LVCMOS33 } [get_ports {SW[7]}]
set_property -dict { PACKAGE_PIN T8    IOSTANDARD LVCMOS18 } [get_ports {SW[8]}]
set_property -dict { PACKAGE_PIN U8    IOSTANDARD LVCMOS18 } [get_ports {SW[9]}]
set_property -dict { PACKAGE_PIN R16   IOSTANDARD LVCMOS33 } [get_ports {SW[10]}]
set_property -dict { PACKAGE_PIN T13   IOSTANDARD LVCMOS33 } [get_ports {SW[11]}]
set_property -dict { PACKAGE_PIN H6    IOSTANDARD LVCMOS33 } [get_ports {SW[12]}]
set_property -dict { PACKAGE_PIN U12   IOSTANDARD LVCMOS33 } [get_ports {SW[13]}]
set_property -dict { PACKAGE_PIN U11   IOSTANDARD LVCMOS33 } [get_ports {SW[14]}]
set_property -dict { PACKAGE_PIN V10   IOSTANDARD LVCMOS33 } [get_ports {SW[15]}]

# ---------------------------------------------------------------------
# LED 16 ดวง
# ---------------------------------------------------------------------
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports {LED[0]}]
set_property -dict { PACKAGE_PIN K15   IOSTANDARD LVCMOS33 } [get_ports {LED[1]}]
set_property -dict { PACKAGE_PIN J13   IOSTANDARD LVCMOS33 } [get_ports {LED[2]}]
set_property -dict { PACKAGE_PIN N14   IOSTANDARD LVCMOS33 } [get_ports {LED[3]}]
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports {LED[4]}]
set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports {LED[5]}]
set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports {LED[6]}]
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports {LED[7]}]
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports {LED[8]}]
set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS33 } [get_ports {LED[9]}]
set_property -dict { PACKAGE_PIN U14   IOSTANDARD LVCMOS33 } [get_ports {LED[10]}]
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports {LED[11]}]
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports {LED[12]}]
set_property -dict { PACKAGE_PIN V14   IOSTANDARD LVCMOS33 } [get_ports {LED[13]}]
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports {LED[14]}]
set_property -dict { PACKAGE_PIN V11   IOSTANDARD LVCMOS33 } [get_ports {LED[15]}]

# ---------------------------------------------------------------------
# จอ 7 ส่วน: ตัวเลือกหลัก AN[0..3] (common anode)
# ---------------------------------------------------------------------
set_property -dict { PACKAGE_PIN J17   IOSTANDARD LVCMOS33 } [get_ports {AN[0]}]
set_property -dict { PACKAGE_PIN J18   IOSTANDARD LVCMOS33 } [get_ports {AN[1]}]
set_property -dict { PACKAGE_PIN T9    IOSTANDARD LVCMOS33 } [get_ports {AN[2]}]
set_property -dict { PACKAGE_PIN J14   IOSTANDARD LVCMOS33 } [get_ports {AN[3]}]

# ---------------------------------------------------------------------
# จอ 7 ส่วน: ข้อมูลส่วน SEG[0..6] = a,b,c,d,e,f,g
# ---------------------------------------------------------------------
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports {SEG[0]}]
set_property -dict { PACKAGE_PIN R10   IOSTANDARD LVCMOS33 } [get_ports {SEG[1]}]
set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS33 } [get_ports {SEG[2]}]
set_property -dict { PACKAGE_PIN K13   IOSTANDARD LVCMOS33 } [get_ports {SEG[3]}]
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports {SEG[4]}]
set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33 } [get_ports {SEG[5]}]
set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports {SEG[6]}]

# ---------------------------------------------------------------------
# ข้อกำหนดเวลา: เหมือนไฟล์ SDC ใน labs/sdc/top_alu8.sdc
# ---------------------------------------------------------------------
create_clock -name sys_clk -period 10.000 -waveform {0.000 5.000} \
             [get_ports {CLK100MHZ}]

set_input_delay  -clock sys_clk -max 2.000 [get_ports {SW[*]}]
set_input_delay  -clock sys_clk -max 2.000 [get_ports {BTN[*]}]

set_output_delay -clock sys_clk -max 2.000 [get_ports {LED[*]}]
set_output_delay -clock sys_clk -max 2.000 [get_ports {AN[*]}]
set_output_delay -clock sys_clk -max 2.000 [get_ports {SEG[*]}]

set_false_path -from [get_ports {CPU_RESETN}]
