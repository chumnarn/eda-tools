# ภาคผนวก ก — คลังคำสั่ง Tcl และคำสั่ง SDC

> **คำเตือนเรื่องชื่อคำสั่ง**: คำสั่งของ Precision เปลี่ยนแปลงได้ตามรุ่น
> ให้เทียบกับ *Command Reference* ของรุ่นที่ใช้เสมอ
> วิธีที่ปลอดภัยที่สุดคือใช้ `File > Save Command File` ใน GUI เพื่อเก็บคำสั่งจริง

---

## ก.1 คำสั่ง Precision Synthesis (ตามรูปแบบ PS2018.1)

### ก.1.1 การจัดการโปรเจกต์และไฟล์

| คำสั่ง | หน้าที่ | ตรงกับ GUI |
|---|---|---|
| `new_project <name> -force -output <dir>` | สร้างโปรเจกต์ใหม่ | File > New Project |
| `add_input_file <file> -vhdl` | เพิ่มไฟล์ VHDL | File > Add Files |
| `add_input_file <file> -verilog` | เพิ่มไฟล์ Verilog | File > Add Files |
| `add_input_file <file> -edif` | เพิ่มเน็ตลิสต์ EDIF | File > Add Files |
| `add_input_file <file> -sdc` | เพิ่มไฟล์ SDC | File > Add Files |
| `read_sdc <file>` | อ่านเงื่อนไขเวลา | Setup Constraints |
| `save_project` | บันทึกโปรเจกต์ | File > Save Project |

### ก.1.2 การตั้งค่าอุปกรณ์และตัวเลือก

```tcl
setup_design -manufacturer xilinx artix7 -part xc7a100tcsg324 -speed -1
```

รูปแบบทั่วไปของ `setup_design`

```tcl
setup_design -manufacturer <ผู้ผลิต> <ตระกูล> -part <ชื่อ part> -speed <คลาสความเร็ว>
```

ตัวเลือกที่พบบ่อยในไฟล์คอนฟิกของ PS

| ตัวเลือก | ความหมาย |
|---|---|
| `retiming` | เปิด/ปิดการย้ายรีจิสเตอร์เพื่อปรับปรุงเวลา |
| `optimize` / effort | ระดับความพยายามในการปรับปรุง (ต่ำ/กลาง/สูง) |
| `resource_sharing` | ใช้ทรัพยากรร่วมกันระหว่างบล็อกเพื่อลดพื้นที่ |
| `hierarchy` | วิธีจัดการ hierarchy (auto / flatten / คงเดิม) |

### ก.1.3 การสังเคราะห์

```tcl
compile        # ขั้นที่ 2a: อ่านและตรวจ RTL
synthesize     # ขั้นที่ 2b: สังเคราะห์เป็นเน็ตลิสต์
```

### ก.1.4 การรายงานผล

```tcl
report_timing                     > timing.rpt          # เส้นทางวิกฤต
report_timing -max_paths 20       > timing.rpt          # 20 เส้นทาง
report_timing -unconstrained_paths > unconstrained.rpt  # เส้นทางที่ไม่ถูกจำกัด
report_area                        > area.rpt            # พื้นที่/ทรัพยากร
report_schematic                                     # เปิด schematic
```

### ก.1.5 การส่งต่อผลลัพธ์

```tcl
write_edif out/top_alu8.edif      # เน็ตลิสต์ EDIF ไปยัง Vivado
write_sdc  out/top_alu8.sdc       # เงื่อนไขเวลา
```

### ก.1.6 โครงสร้างสคริปต์ตัวอย่างที่ใช้ได้จริง

```tcl
# ---- ตัวแปร ----
set design_name "top_alu8"
set rtl_dir     "../rtl"
set sdc_file    "../sdc/top_alu8.sdc"
set out_dir     "out_10ns"

file mkdir $out_dir

# ---- ขั้นที่ 1: Set-Up ----
new_project $design_name -force -output $out_dir

add_input_file $rtl_dir/alu8.vhd     -vhdl
add_input_file $rtl_dir/hex2seg.vhd  -vhdl
add_input_file $rtl_dir/top_alu8.vhd -vhdl

setup_design -manufacturer xilinx artix7 -part xc7a100tcsg324 -speed -1

read_sdc $sdc_file
report_timing -unconstrained_paths

# ---- ขั้นที่ 2: Run Synthesis ----
compile
synthesize

# ---- ขั้นที่ 3: Analyze ----
report_timing -max_paths 20        > $out_dir/timing.rpt
report_timing -unconstrained_paths > $out_dir/unconstrained.rpt
report_area                        > $out_dir/area.rpt

write_edif $out_dir/$design_name.edif
write_sdc  $out_dir/$design_name.sdc

exit
```

---

## ก.2 คำสั่ง SDC / XDC ที่ใช้ในคู่มือนี้

| คำสั่ง | หน้าที่ | ตัวอย่าง |
|---|---|---|
| `create_clock` | สร้างนาฬิกาหลัก | `create_clock -name sys_clk -period 10.000 [get_ports {CLK100MHZ}]` |
| `create_generated_clock` | สร้างนาฬิกาที่ derive จากนาฬิกาอื่น | `create_generated_clock -name div2 -divide_by 2 -source [get_ports {clk}] [get_pins {div/Q}]` |
| `set_input_delay` | เวลาหน่วงของอินพุต | `set_input_delay -clock sys_clk -max 2.000 [get_ports {SW[*]}]` |
| `set_output_delay` | เวลาที่ต้องใช้ขับเอาต์พุต | `set_output_delay -clock sys_clk -max 2.000 [get_ports {LED[*]}]` |
| `set_false_path` | ตัดเส้นทางออกจากการวิเคราะห์ | `set_false_path -from [get_ports {CPU_RESETN}]` |
| `set_multicycle_path` | อนุญาตให้ใช้หลายรอบนาฬิกา | `set_multicycle_path -setup 2 -from [get_ports {a}]` |
| `set_clock_uncertainty` | เพิ่มความไม่แน่นอนของนาฬิกา | `set_clock_uncertainty -setup 0.150 [get_clocks {sys_clk}]` |
| `set_max_delay` / `set_min_delay` | จำกัดเวลาสูงสุด/ต่ำสุดโดยตรง | `set_max_delay 8.0 -from [get_ports {a}] -to [get_ports {b}]` |
| `get_ports` | เลือกพอร์ต | `[get_ports {SW[*]}]` |
| `get_clocks` | เลือกนาฬิกา | `[get_clocks {sys_clk}]` |
| `get_pins` | เลือกขาเซลล์ | `[get_pins {u_ff/D}]` |
| `get_cells` | เลือกเซลล์ | `[get_cells {u_alu}]` |

### ก.2.1 รูปแบบ wildcard ที่ต้องระวัง

```tcl
[get_ports {SW[*]}]      # ถูก: ใช้วงเล็บปีกกาแบบ Tcl
[get_ports {SW[*]}]      # ถูก
[get_ports SW[*]]        # ผิด: Tcl จะพยายามขยาย [*] เป็นรายการคำสั่ง
```

**กฎ**: ควรอยู่ในเครื่องหมาย `{ }` เสมอ

---

## ก.3 คำสั่ง Vivado สำหรับ Place & Route

### ก.3.1 การจัดการโปรเจกต์

```tcl
create_project -part xc7a100tcsg324-1 -force top_alu8_prj
set_property board_part digilentinc.com/nexys-a7-100T [current_project]
add_files -norecurse netlist/top_alu8.edif
add_files -norecurse nexys_a7_100t.xdc
set_property top top_alu8 [current_fileset]
```

### ก.3.2 การอ่านอินพุต

```tcl
read_edif netlist/top_alu8.edif      # เน็ตลิสต์ EDIF
read_xdc  nexys_a7_100t.xdc          # ข้อจำกัดพินและเวลา
read_verilog rtl/top.v               # RTL สำหรับ debug
read_vhdl    rtl/top.vhd
```

### ก.3.3 การทำให้ดีที่สุด

```tcl
link_design -part xc7a100tcsg324-1 -top top_alu8
opt_design
place_design
phys_opt_design
route_design
```

ตัวเลือกที่ควรรู้

```tcl
opt_design -directive ExploreWithRemap
place_design -directive ExtraNetDelay_high
phys_opt_design -directive AggressiveFanoutOpt
route_design -directive AggressiveExplore
```

### ก.3.4 การรายงานผล

```tcl
report_timing_summary -file timing_summary.rpt
report_utilization   -file utilization.rpt
report_drc           -file drc.rpt
report_methodology   -file methodology.rpt
report_clock_utilization -file clock_utilization.rpt
report_route_status  -file route_status.rpt
report_io            -file io.rpt
report_power         -file power.rpt
```

### ก.3.5 การสร้าง bitstream

```tcl
write_bitstream -force top_alu8.bit
write_checkpoint -force top_alu8_routed.dcp
```

### ก.3.6 การดึงค่าจากรายงานเวลา (สำหรับเกณฑ์ sign-off)

```tcl
# setup slack ที่แย่ที่สุด
set paths [get_timing_paths -delay_type max -max_paths 1 -nworst 1]
set setup_slack [get_property SLACK [lindex $paths 0]]

# hold slack ที่แย่ที่สุด
set paths [get_timing_paths -delay_type min -max_paths 1 -nworst 1]
set hold_slack [get_property SLACK [lindex $paths 0]]

# เส้นทางที่ไม่ถูกจำกัด
set unconstrained [get_timing_paths -unconstrained -nworst 100]
set n [llength $unconstrained]

# จำนวนข้อผิดพลาดของ DRC
set drc_text [report_drc -return_string]
set n_err [regexp -count -nocase {ERROR} $drc_text]
```

### ก.3.7 การเปิดดีไซน์ที่ route แล้วเพื่อ debug

```tcl
open_checkpoint top_alu8_routed.dcp
report_timing -to [get_cells {top_alu8/y_r_reg[3]}] -max_paths 10
```

---

## ก.4 สคริปต์เกณฑ์ sign-off ฉบับสมบูรณ์

```tcl
# check_signoff.tcl
set min_setup_slack 0.0
set min_hold_slack  0.0
set max_drc_errors  0

proc worst_slack {dt} {
    set paths [get_timing_paths -delay_type $dt -max_paths 1 -nworst 1]
    if {[llength $paths] == 0} { return "NA" }
    return [get_property SLACK [lindex $paths 0]]
}

set setup_slack [worst_slack max]
set hold_slack  [worst_slack min]
set n_unconstrained [llength [get_timing_paths -unconstrained -nworst 100]]
set n_drc_error [regexp -count -nocase {ERROR} [report_drc -return_string]]

set signoff_ok 1
set reasons {}
if {$setup_slack eq "NA" || $setup_slack < $min_setup_slack} {
    lappend reasons "setup slack $setup_slack"; set signoff_ok 0 }
if {$hold_slack eq "NA" || $hold_slack < $min_hold_slack} {
    lappend reasons "hold slack $hold_slack"; set signoff_ok 0 }
if {$n_drc_error > $max_drc_errors} {
    lappend reasons "DRC errors $n_drc_error"; set signoff_ok 0 }
if {$n_unconstrained > 0} {
    lappend reasons "unconstrained paths $n_unconstrained"; set signoff_ok 0 }

set fh [open $out_dir/signoff_report.txt w]
puts $fh "setup slack (worst) : $setup_slack ns"
puts $fh "hold  slack (worst) : $hold_slack ns"
puts $fh "DRC errors          : $n_drc_error"
puts $fh "unconstrained paths : $n_unconstrained"
if {$signoff_ok} { puts $fh "RESULT: PASS" } else {
    puts $fh "RESULT: FAIL"
    foreach r $reasons { puts $fh "  - $r" } }
close $fh
```

---

## ก.5 คำสั่งที่ใช้บ่อยในการจำลอง (ModelSim/QuestaSim)

| คำสั่ง | หน้าที่ |
|---|---|
| `vlib work` | สร้าง work library |
| `vmap work ./work` | จับคู่ library กับโฟลเดอร์ |
| `vcom -2008 file.vhd` | คอมไพล์ VHDL-2008 |
| `vlog -sv file.sv` | คอมไพล์ SystemVerilog |
| `vsim -c work.tb -do "run -all; quit -f"` | จำลองแบบ console |
| `vsim work.tb -view` | เปิดหน้าต่าง waveform |
| `add wave -r sim:/tb/*` | เพิ่มสัญญาณทั้งหมดลง waveform |
| `run -all` | จำลองจนจบเวลา |
| `quit -f` | ออกโดยไม่ถาม |

---

## ก.6 คำสั่ง GHDL

| คำสั่ง | หน้าที่ |
|---|---|
| `ghdl -a --std=08 file.vhd` | วิเคราะห์ (compile) ไฟล์ |
| `ghdl -e --std=08 top` | เอลาโบเรตเป็น executable |
| `ghdl -r --std=08 top` | จำลอง |
| `ghdl -r --std=08 top --assert-level=error` | หยุดทันทีเมื่อพบข้อผิดพลาด |
| `--workdir=<dir>` | กำหนดตำแหน่งเก็บ work library |
| `ghdl --clean --workdir=<dir>` | ล้าง work library |

> **อย่าลืม**: พาธของ workdir และไฟล์ต้นทางต้องเป็น ASCII ล้วน (ดูหัวข้อ 0.3.3)

---

## ก.7 คำสั่งโปรแกรมบอร์ด

```bash
# openFPGALoader
openFPGALoader -b top_alu8.bit -c ft232

# Vivado Hardware Manager แบบไม่ใช้ GUI
open_hw_manager
connect_hw_server
open_hw_target
set devices [get_hw_devices]
current_hw_device $devices
set_property PROGRAM.FILE {top_alu8.bit} $devices
program_hw_devices $devices
refresh_hw_device $devices
```

---

## ก.8 พินสำคัญของ Nexys A7-100T ที่ใช้ในคู่มือนี้

| สัญญาณ | พิน | หมายเหตุ |
|---|---|---|
| CLK100MHZ | E3 | นาฬิกา 100 MHz (MRCC, bank 35) |
| CPU_RESETN | C12 | รีเซ็ต active low |
| BTN[0] (BTNU) | M18 | |
| BTN[1] (BTNL) | P17 | |
| BTN[2] (BTNR) | M17 | |
| SW[0]–SW[7] | J15, L16, M13, R15, R17, T18, U18, R13 | LVCMOS33 |
| SW[8]–SW[9] | T8, U8 | **LVCMOS18** |
| SW[10]–SW[15] | R16, T13, H6, U12, U11, V10 | LVCMOS33 |
| LED[0]–LED[15] | H17, K15, J13, N14, R18, V17, U17, U16, V16, T15, U14, T16, V15, V14, V12, V11 | |
| AN[0]–AN[3] | J17, J18, T9, J14 | ตัวเลือกหลักจอ (common anode) |
| SEG[0]–SEG[6] | T10, R10, K16, K13, P15, T11, L18 | a,b,c,d,e,f,g |

แหล่งอ้างอิงหลัก: [Digilent digilent-xdc](https://github.com/Digilent/digilent-xdc) (Nexys-A7-100T-Master.xdc)
