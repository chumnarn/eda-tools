# บทที่ 4 — ส่งต่อไปยัง Vivado ด้วย EDIF, XDC และ Tcl

> **จุดยืนของบทนี้**: ตรงกับขั้นที่ 3b ของคู่มือ PS2018.1 ("Run integrated Place and Route
> and review reports") ในเชิงหลักการ และเป็นขั้นตอนที่ใช้จริงกับ FPGA
> เพราะ Precision Synthesis ส่งต่อเน็ตลิสต์ให้ Vivado ทำ Place & Route

---

## 4.1 ทำไมต้องส่งต่อ

| งาน | ใครทำ | เหตุผล |
|---|---|---|
| สังเคราะห์ RTL → เน็ตลิสต์ | Precision | เลือกไลบรารีของอุปกรณ์ได้, วิเคราะห์ QoR ได้ละเอียด |
| เลือกอุปกรณ์และตั้งค่าเงื่อนไข | Precision | รวมไว้ในขั้นตอนเดียว |
| วางวาง (place) | Vivado | ต้องใช้ข้อมูลภายในของอุปกรณ์ที่ครบถ้วน |
| ปรับแต่งการเดินสาย (phys_opt) | Vivado | ต้องเห็น routing จริง |
| เดินสาย (route) | Vivado | เป็นขั้นตอนที่ให้คำตัดเวลา |
| ตรวจ DRC และสร้าง bitstream | Vivado | ต้องใช้ตัวสร้าง bitstream ของผู้ผลิต |

**ข้อสรุป**: ตัวเลขเวลาที่ "ผ่าน" จริง ๆ ต้องมาจาก Vivado หลัง route เสร็จเท่านั้น

---

## 4.2 สิ่งที่ต้องส่งต่ออะไรบ้าง

| สิ่งที่ส่ง | รูปแบบ | ทำหน้าที่ |
|---|---|---|
| เน็ตลิสต์ตรรกะ | **EDIF** (`.edif`) | โครงสร้างวงจรที่สังเคราะห์แล้ว พร้อมชื่อเซลล์จริง |
| ข้อจำกัดการจัดวางพิน | **XDC** (`.xdc`) | ผูกพอร์ตกับพินจริงบนบอร์ด |
| ข้อกำหนดเวลา | **XDC** (ส่วนของ SDC) | นาฬิกาและหน่วง I/O |
| ขั้นตอนการทำงาน | **Tcl** (`.tcl`) | สั่ง place/route/report อัตโนมัติ |
| ข้อกำหนดอุปกรณ์ | part / board part | บอก Vivado ว่าสร้างสำหรับชิปอะไร |

> **ทำไมต้องมีทั้ง EDIF และ XDC**: EDIF บอก "วงจรเป็นอย่างไร" ส่วน XDC บอก "วงจรนี้อยู่ตรงไหนในชิป"
> และ "ต้องเร็วแค่ไหน" ขาดส่วนใดส่วนหนึ่งไม่ได้

---

## 4.3 ขั้นตอนส่งต่อ

### 4.3.1 ขั้นที่ 1 — สร้างเน็ตลิสต์ EDIF จาก Precision

**วิธีที่ 1 — ใน GUI**

```text
Design > Export > EDIF...
  File name : netlist/top_alu8.edif
  [Export]
```

**วิธีที่ 2 — ในสคริปต์**

```tcl
write_edif netlist/top_alu8.edif
```

### 4.3.2 ขั้นที่ 2 — เตรียม XDC

ไฟล์ `labs/vivado/nexys_a7_100t.xdc` ในคู่มือนี้ทำสองหน้าที่พร้อมกัน

1. ผูกพอร์ตกับพินจริงบน Nexys A7-100T
2. ประกาศข้อกำหนดเวลา (เหมือน SDC)

ถ้าต้องการแยกไฟล์ ให้แยกเป็น `nexys_a7_100t_pins.xdc` (พิน) กับ `top_alu8.xdc` (เวลา)
ซึ่งเป็นแนวปฏิบัติที่ดีกว่าเมื่อมีหลายดีไซน์ใช้บอร์ดเดียวกัน

### 4.3.3 ขั้นที่ 3 — สร้างโปรเจกต์ Vivado

**แนวทาง A — โหมดโปรเจกต์ (เหมาะกับการเรียนรู้และการ debug)**

```text
File > Project > New Project
  Project name : top_alu8_prj
  Project location : <โฟลเดอร์>
  [Create Project]

  Project type : RTL Project        (เลือกเฉพาะตอนสร้างโปรเจกต์เปล่า)
  [Next]

  Boards       : digilentinc.com/nexys-a7-100T
  [Next]

  ⚠ ตรวจสอบว่าเลือก part ถูก: xc7a100tcsg324-1

  Add Sources... > Add or create constraints  →  Add Files  →  nexys_a7_100t.xdc
  [Next]

  ⚠ อย่าเพิ่ม RTL ที่นี่ ถ้าจะใช้ EDIF

  Finish
```

**แนวทาง B — โหมดสคริปต์ (non-project / in-memory)** ตามไฟล์ `labs/vivado/run_pnr.tcl`

```tcl
read_edif netlist/top_alu8.edif
read_xdc  nexys_a7_100t.xdc
link_design -part xc7a100tcsg324-1 -top top_alu8

opt_design
place_design
phys_opt_design
route_design

report_timing_summary -file vivado_out/timing_summary.rpt
report_utilization   -file vivado_out/utilization.rpt
report_drc           -file vivado_out/drc.rpt
write_bitstream -force vivado_out/top_alu8.bit
```

รันด้วย

```bash
vivado -mode batch -source run_pnr.tcl
```

### 4.3.4 ขั้นที่ 4 — ใส่เน็ตลิสต์ EDIF ในโหมดโปรเจกต์

เมื่อใช้โหมดโปรเจกต์ ต้องบอก Vivado ว่า "ไม่ต้องสังเคราะห์ใหม่ ใช้ netlist ที่ให้มา"

```tcl
# เพิ่ม EDIF เป็นแหล่งข้อมูลระดับ synthesis
add_files -norecurse netlist/top_alu8.edif

# ปิดขั้นตอนการสังเคราะห์ และใช้ netlist ที่มีอยู่
set_property source_mgmt_mode None [get_runs synth_1]
set_property design_mode GateLvl [current_design]
```

> *(คำสั่งด้านบนอาจต่างกันเล็กน้อยตามรุ่นของ Vivado
> ให้ยืนยันกับเอกสารของรุ่นที่ใช้ และถ้าโปรเจกต์ทำงานไม่ผ่าน ให้ใช้แนวทาง B แทน)*

### 4.3.5 ขั้นที่ 5 — รัน Place & Route

**ใน GUI**

```text
Flow Navigator > Run Implementation
  ตรวจสอบว่า:
    - Target Language : Verilog / VHDL (ไม่สำคัญสำหรับ EDIF)
    - Target Part     : xc7a100tcsg324-1
  [Launch Implementation
```

หรือรันทีละขั้นเพื่อดูผลกลางทาง

```text
Tools > Run Flow > Synthesis      (ถ้าใช้ RTL)
Tools > Run Flow > Implementation
```

**ในโหมดสคริปต์**

```tcl
opt_design        # ปรับปรุงตรรกะหลังสังเคราะห์
place_design      # วางวางเซลล์
phys_opt_design   # ปรับปรุงการเดินสายหลังวางวาง
route_design      # เดินสาย
```

### 4.3.6 ขั้นที่ 6 — ตรวจสอบผล

```text
Report > Report Timing Summary
Report > Report Utilization
Report > Report DRC
Report > Report Clock Interaction
```

---

## 4.4 เกณฑ์ตรวจรับงาน (sign-off gate) ก่อนสร้าง bitstream

### 4.4.1 เกณฑ์มาตรฐาน

| เกณฑ์ | ค่าที่ต้องการ | ตรวจที่ไหน |
|---|---|---|
| Setup timing | WNS ≥ 0 และ TNS = 0 | `Report > Timing Summary` |
| Hold timing | WNS ≥ 0 และ TNS = 0 | `Report > Timing Summary` (ส่วน min delay) |
| Unconstrained paths | 0 | `Report > Clock Interaction` |
| DRC error | 0 | `Report > DRC` |
| เงื่อนไขครบถ้วน | ไม่มี critical warning ว่าพอร์ตไม่ถูกจำกัด | `Report > Methodology` |

### 4.4.2 สคริปต์ตรวจอัตโนมัติ

ไฟล์ `labs/vivado/check_signoff.tcl` ทำหน้าที่ดังนี้

```tcl
proc worst_slack {dt} {
    set paths [get_timing_paths -delay_type $dt -max_paths 1 -nworst 1]
    if {[llength $paths] == 0} { return "NA" }
    return [get_property SLACK [lindex $paths 0]]
}

set setup_slack [worst_slack max]
set hold_slack  [worst_slack min]

set unconstrained [get_timing_paths -unconstrained -nworst 100]
set n_unconstrained [llength $unconstrained]

set drc_text [report_drc -return_string]
set n_drc_error [regexp -count -nocase {ERROR} $drc_text]
```

แล้วตรวจเงื่อนไขและเขียนรายงาน

```text
Sign-off report
================================================
setup slack (worst) : 0.831 ns
hold  slack (worst) : 0.124 ns
DRC errors          : 0
unconstrained paths : 0
------------------------------------------------
RESULT: PASS
```

ถ้าไม่ผ่าน สคริปต์จะ **ไม่สร้าง bitstream** และจบด้วยข้อความแสดงเหตุผล

```text
RESULT: FAIL
  - setup slack -0.230 < 0.0
```

### 4.4.3 การตีความเมื่อไม่ผ่าน

| อาการ | สาเหตุที่เป็นไปได้ | ทางแก้ |
|---|---|---|
| Setup ไม่ผ่าน | เวลาจริงหลังเดินสายนานกว่าที่คาด | ปรับ RTL / เพิ่ม effort / ใช้ phys_opt |
| Hold ไม่ผ่าน | เส้นทางสั้นเกินไปหลังเดินสาย | ใส่ delay buffer, `phys_opt_design -directive` |
| DRC error | ขัดแย้งกับข้อกำหนดการจัดวาง | แก้ XDC เช่น พินชนกัน |
| Unconstrained > 0 | พอร์ตที่ไม่ได้จำกัดเวลา | เติมเงื่อนไขใน XDC |

> **บทเรียนสำคัญ**: งานที่ผ่านทุกเกณฑ์หลัง route มักจะผ่านได้
> แต่งานที่ "ผ่าน" หลังสังเคราะห์อย่างเดียว อาจพังตอน route
> เพราะ **ความหน่วงการเดินสายจริงอาจมากกว่าที่คาดไว้หลายเท่า**

---

## 4.5 ตรวจ hold violation และแก้

hold เป็นปัญหาที่ **ต้องแก้หลังเดินสาย** เพราะต้องรู้ความหน่วงจริงของสาย

### 4.5.1 วิธีตรวจ

```text
Report > Report Timing Summary
  ดูส่วน "Min Delay" / ช่อง "WNS(ns)" ในตาราง "Intra Clock Table"
  หรือ
Report > Report Timing
  เลือก "Hold" / delay_type = min
```

### 4.5.2 วิธีแก้ตามลำดับที่เหมาะสม

1. **ให้ Vivado แก้เองก่อน** — `phys_opt_design` มีกลไกจัดการ hold อัตโนมัติ
2. **ปรับ directive**

   ```tcl
   phys_opt_design -directive AggressiveFanoutOpt
   ```

3. **ใส่ delay buffer เอง** — เพิ่มเซลล์หน่วงในเส้นทางที่สั้นเกินไป
4. **ตัดเส้นทางที่ไม่จำเป็นด้วย `set_false_path`** — ใช้ได้เฉพาะกรณีที่แน่ใจว่าไม่มีความเสี่ยง
   (เช่นเส้นทางข้อมูลที่ไม่มีเงื่อนไขการถือครองข้อมูล)

> **ข้อควรระวัง**: การใช้ `set_false_path` เพื่อ "แก้" hold ที่เกิดจริง
> คือการซ่อนปัญหา ไม่ใช่การแก้ ต้องใช้เฉพาะเมื่อมีเหตุผลทางระบบรองรับ

---

## 4.6 ทดสอบบนฮาร์ดแวร์จริง

### 4.6.1 โปรแกรม bitstream

```text
Hardware Manager > Open Target > Auto Connect
  เลือกโปรแกรมเมอร์ Digilent USB-JTAG
  Program Device → เลือกไฟล์ .bit
```

หรือใช้เครื่องมือบรรทัดคำสั่ง

```bash
openFPGALoader -b vivado_out/top_alu8.bit -c ft232
```

### 4.6.2 วิธีทดสอบบน Nexys A7-100T

| ทดสอบ | วิธีทำ | ผลที่คาดหวัง |
|---|---|---|
| นาฬิกา | ดูจอ 7 ส่วนเปลี่ยนไปเรื่อย ๆ | เปลี่ยนประมาณ 1,526 ครั้งต่อวินาที (100 MHz ÷ 2¹⁶) |
| ตัวคำนวณ | ตั้ง SW[7:0] = 5, SW[15:8] = 3, BTN = ADD | LED[7:0] แสดง 8 (0x08) บนจอแสดง "08" |
| ลบ | BTN = SUB | LED[7:0] แสดง 2 (0x02) |
| zero | ตั้ง operand เป็น 0 | LED[8] ติด |
| overflow | ตั้ง 127 + 1 | LED[9] ติด และผลเป็น 0x80 |
| รีเซ็ต | กดปุ่ม CPU RESET (C12) | LED และจอถูกล้างเป็นศูนย์ |

### 4.6.3 วิธีตรวจว่าความถี่จอถูกต้อง

จอเปลี่ยนทุก 2¹⁶ รอบนาฬิกา = 100,000,000 ÷ 65,536 ≈ **1,526 ครั้งต่อวินาที**
ถ้าตาไม่จับได้แม้แต่กะพริบ แสดงว่าตัวนับหรือนาฬิกามีปัญหา — ให้ตรวจรายงาน timing ของเส้นทางนั้น

---

## 4.7 แนวทางสำรองเมื่อ EDIF ใช้ไม่ได้

อาจพบปัญหาที่ Vivado อ่าน EDIF ที่ส่งมาจาก PS ไม่ได้ เนื่องจากปัญหาเรื่องชื่อเซลล์
หรือไลบรารี มีแนวทางสำรอง 3 ทาง เรียงตามลำดับความสะดวก

| ทาง | วิธี | ข้อดี/ข้อเสีย |
|---|---|---|
| **1** | ให้ PS ส่งเน็ตลิสต์เป็น **VHDL/Verilog** แล้วให้ Vivado อ่านเป็น source | ง่าย แต่เสียข้อได้เปรียบของการใช้ไลบรารีอุปกรณ์ใน PS |
| **2** | เก็บ RTL ไว้ในโปรเจกต์ Vivado แล้วให้ Vivado สังเคราะห์เอง | ได้ debug ง่าย แต่ไม่ได้ทดสอบคุณภาพของเน็ตลิสต์จาก PS |
| **3** | ตรวจไลบรารีที่ PS ใช้ แล้วจัดการให้ถูกต้อง | แก้ที่ต้นเหตุ แต่ต้องเข้าใจรูปแบบ EDIF ของอุปกรณ์ |

> **คำแนะนำสำหรับการอบรม**: ให้ทำแบบทาง 2 ควบคู่กับทาง 1 เสมอ
> เพราะผลลัพธ์ของบทที่ 5 (เปรียบเทียบ 10 ns กับ 8 ns) ต้องเปรียบเทียบ
> **เน็ตลิสต์ที่สังเคราะห์ด้วยเป้าหมายต่างกัน** ถ้าให้ Vivado สังเคราะห์ใหม่ทั้งคู่
> ก็จะไม่ได้ทดสอบสิ่งที่ต้องการทดสอบจริง

---

## 4.8 แบบฝึกหัดบทที่ 4

### Lab 4.1 — ส่งต่อเน็ตลิสต์ไป Vivado

1. ส่งออก EDIF จาก Precision ไปที่ `netlist/top_alu8.edif`
2. สร้างโปรเจกต์ Vivado แล้วเพิ่ม EDIF + XDC
3. ตรวจสอบว่า Vivado อ่านเน็ตลิสต์ได้ (ดูจำนวนเซลล์ใน Report Utilization)

**เกณฑ์ผ่าน**: Vivado แสดงจำนวน LUT/FF ใกล้เคียงกับที่ PS รายงาน

### Lab 4.2 — รัน Place & Route และตรวจ timing

1. รัน implementation จนจบ
2. เปิด Timing Summary บันทึก WNS setup, WNS hold, TNS
3. เปิด DRC report บันทึกจำนวน error/warning
4. เปิด Clock Interaction บันทึกจำนวน unconstrained paths

**เกณฑ์ผ่าน**: มีตัวเลขครบทุกช่อง และไม่มี unconstrained path

### Lab 4.3 — ทดลองเกณฑ์ sign-off อัตโนมัติ

1. ใช้ `labs/vivado/run_pnr.tcl` รันแบบ batch
2. ตรวจว่าไฟล์ `vivado_out/signoff_report.txt` ถูกสร้าง
3. **ทดลองทำให้ไม่ผ่าน**: แก้ XDC ให้คาบเวลานาฬิกาเป็น 2 ns แล้วรันซ้ำ
   ตรวจว่าสคริปต์รายงาน FAIL และ **ไม่สร้าง bitstream**
4. คืนค่าเดิม

**เกณฑ์ผ่าน**: เกณฑ์ทำงานถูกต้องทั้งสองกรณี

### Lab 4.4 — สร้าง bitstream และทดสอบบนบอร์ด

1. เมื่อผ่านเกณฑ์ ให้เขียน bitstream
2. โปรแกรมลงบอร์ด
3. ทดสอบตามตารางในหัวข้อ 4.6.2 ทุกแถว
4. ถ่ายรูปหน้าจอบอร์ดพร้อมตารางผล

**เกณฑ์ผ่าน**: ผลลัพธ์บนบอร์ดตรงกับที่คำนวณจากตารางในหัวข้อ 4.6.2

### Lab 4.5 — ทำให้ hold violation เพื่อเรียนรู้การแก้

1. ตั้งค่าให้ Vivado วางวางแบบเร่งรีบจน hold violation (ลดค่า effort หรือใช้ directive ที่เร็วขึ้น)
2. ตรวจพบ hold violation ใน Timing Summary
3. แก้ด้วย `phys_opt_design` แล้วตรวจว่าหาย
4. บันทึกว่าการแก้ที่ต่างกันให้ผลต่างกันอย่างไร

**เกณฑ์ผ่าน**: เข้าใจว่ากลไกการแก้ hold ของ Vivado ทำงานอย่างไร

---

## 4.9 สรุปบท

- สิ่งที่ส่งต่อ Vivado มี 4 อย่าง: EDIF (วงจร), XDC (พิน + เวลา), part, และขั้นตอน Tcl
- เกณฑ์ sign-off ต้องตรวจ 4 อย่าง: setup, hold, unconstrained paths, DRC
- **hold ตรวจได้จริงหลัง route เท่านั้น**
- ควรเก็บ RTL ในโปรเจกต์ Vivado ไว้เสมอ เพื่อการ debug และการทำ cross-probe
- สคริปต์เกณฑ์ sign-off ทำให้กระบวนการ "ตรวจก่อนปล่อย" เป็นระบบ ไม่ต้องพึ่งความจำ

**เตรียมตัวก่อนบทถัดไป**: มีผล post-route รอบ 10 ns และ 8 ns สำหรับเปรียบเทียบ (บทที่ 5)
