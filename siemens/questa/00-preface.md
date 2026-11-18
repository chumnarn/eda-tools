# บทที่ 0: บทนำ — คู่มือ Questa SIM สำหรับ VHDL Simulation

> คู่มือนี้สอนการใช้ Questa SIM (และ ModelSim รุ่นก่อนหน้า) ให้ครอบคลุมทั้ง
> flow การทำงาน การ debug และการรันแบบอัตโนมัติ สำหรับงาน VHDL
> โดยเน้นจุดที่ผู้ออกแบบ RTL ต้องรู้ ไม่ใช่ความสามารถทั้งหมดของเครื่องมือ

**เครื่องมือที่เกี่ยวข้อง:** Questa SIM (Siemens EDA) หรือ ModelSim
**เอกสารอ้างอิงหลัก:** Questa SIM Tutorial 2026.1

---

## สารบัญบท

- [1. คู่มือนี้ให้อะไร](#1-คู่มือนี้ให้อะไร)
- [2. สิ่งที่คู่มือนี้ไม่ครอบคลุม](#2-สิ่งที่คู่มือนี้ไม่ครอบคลุม)
- [3. สถานะการทดสอบ — อ่านก่อนใช้คำสั่ง](#3-สถานะการทดสอบ--อ่านก่อนใช้คำสั่ง)
- [4. วิธีใช้คู่มือนี้](#4-วิธีใช้คู่มือนี้)
- [5. ชุดตัวอย่างโค้ด](#5-ชุดตัวอย่างโค้ด)
- [6. เครื่องมือที่ใช้ตรวจสอบ](#6-เครื่องมือที่ใช้ตรวจสอบ)

---

## 1. คู่มือนี้ให้อะไร

คู่มือนี้ครอบคลุมการใช้ Questa SIM สำหรับงาน VHDL ใน 5 ด้าน

| ด้าน | ได้อะไร |
|---|---|
| **การเตรียมระบบ** | ติดตั้ง ตั้งค่า `PATH` ตั้งค่าไฟล์ `.ini` และตรวจเวอร์ชัน |
| **flow การทำงาน** | library, working library, resource library, project flow และลำดับการคอมไพล์ |
| **การ debug** | breakpoint, step, waveform, การอ่านค่า และการบังคับค่าสัญญาณ |
| **การตรวจผล** | `severity` ของ VHDL, `onerror`/`onbreak` และการทำให้รหัสออกถูกต้องสำหรับ CI |
| **การรันอัตโนมัติ** | Tcl, ไฟล์ `.do`, โหมด batch และวิธีเปรียบเทียบกับ GHDL |

ทุกบทในคู่มือนี้มีตัวอย่างที่อ้างอิงไปยังชุดตัวอย่างโค้ดจริงที่อยู่ใน
[`code/reference/questa/`](../../../code/reference/questa/README.md)
จึงตรวจสอบได้ว่าตัวอย่างในคู่มือทำงานจริง ไม่ใช่ตัวอย่างที่แต่งขึ้น

---

## 2. สิ่งที่คู่มือนี้ไม่ครอบคลุม

- **ไม่ใช่คู่มือภาษา VHDL** — ดูที่
  [VHDL Golden Reference](../vhdl/README.md) สำหรับเรื่องภาษา
- **ไม่ครอบคลุม Verilog / SystemVerilog / UPF / SystemC**
  รวมถึง coverage, PSL, assertion ของ SystemVerilog และ DPI
  แม้ Questa จะรองรับครบ แต่เป็นคนละหัวข้อกับคู่มือนี้
- **ไม่ครอบคลุมการสังเคราะห์และการวิเคราะห์ timing** — เป็นเครื่องมืออื่น
- **ไม่มีตัวเลขประสิทธิภาพจากการวัดจริง** — ไม่มีการวัดเวลาจำลองหรือ
  ขนาดไฟล์ waveform ของงานจริงที่ผ่าน sign-off

---

## 3. สถานะการทดสอบ — อ่านก่อนใช้คำสั่ง

> หัวข้อนี้สำคัญที่สุดของคู่มือ เพราะคำสั่งของ Qesta ไม่ได้ถูกรันบนเครื่องที่
> จัดทำคู่มือนี้ ผู้เรียนจึงต้องทราบว่าข้อมูลส่วนใดมาจากการวัดจริง
> และข้อมูลส่วนใดมาจากเอกสารทางการ

### 3.1 สิ่งที่ยืนยันแล้วด้วยการรันจริง

เครื่องมือที่ใช้คือ **GHDL 1.0.0 (Dunoon, mcode)** ใน WSL2 Ubuntu 22.04
ไม่ใช่ Questa แต่เป็นตัวตรวจว่า "โค้ด VHDL ถูกต้องและทำงานตามที่อธิบาย"

| สิ่งที่ตรวจ | ผล | หลักฐาน |
|---|---|---|
| โค้ดตัวอย่างทั้ง 4 ตัวคอมไพล์ผ่าน VHDL-2008 | ผ่าน | `reports/*_analyze_08.log` |
| โค้ดตัวอย่างทั้ง 4 ตัวคอมไพล์ผ่าน VHDL-2002 | ผ่าน | `reports/*_analyze_02.log` |
| testbench ทั้ง 4 ตัวจำลองผ่าน พร้อม marker ครบ | ผ่าน | `reports/*_run.log` |
| RTL ทั้ง 4 ตัวสังเคราะห์เป็น netlist ได้ | ผ่าน | `reports/*_synth.log` |
| การ override generic มีผลจริง | ผ่าน — ได้ `INIT_VALUE=0` และ `INIT_VALUE=100` ตามคำสั่ง | ดู [ex01](../../../code/reference/questa/examples/ex01_generic_override/README.md) |
| พฤติกรรมของ `severity` ทั้ง 4 ระดับของ GHDL | ผ่าน — วัดได้ตามตารางใน[บทที่ 9](09-assertions-and-severity.md) | `reports/ex03_assert_severity_tb_assert_severity_run.log` |
| เวลาจริงของช่วง `PHASE_FORCE_WINDOW` | ผ่าน — วัดได้ 46 ns และ 76 ns | ดู [ex02](../../../code/reference/questa/examples/ex02_force_release/README.md) |

### 3.2 สิ่งที่ยังไม่ได้ยืนยันบนเครื่องนี้

> **ห้ามอ้างว่าคำสั่งของ Questa ในคู่มือนี้ผ่านการทดสอบ**
> เครื่องที่จัดทำคู่มือนี้ไม่มี license ของ Questa หรือ ModelSim
> คำสั่งทั้งหมดมาจาก **Questa SIM Tutorial 2026.1** ที่แนบมา
> และจากเอกสาร ModelSim/Questa ของ Siemens EDA

| สิ่งที่ยังไม่ได้ยืนยัน | วิธีตรวจสอบด้วยตัวเอง |
|---|---|
| คำสั่ง `vlib` `vmap` `vcom` `vsim` ทำงานตามที่อธิบาย | รัน `bash scripts/questa_run.sh ex00_counter_tutorial tb_counter_tut` ใน `code/reference/questa/` |
| ไฟล์ `.do` ทั้ง 5 ไฟล์ทำงานไม่ผิด syntax | เปิดแบบ GUI ตาม[บทที่ 5](05-gui-workflow.md) |
| พฤติกรรมของ `severity error` ใน Questa หยุด simulation หรือไม่ | ทดลองด้วย `ex03_assert_severity` ตาม[บทที่ 9](09-assertions-and-severity.md) |
| พฤติกรรมของ `force` / `release` ใน VHDL ตรงกับที่คาด | ทดลองด้วย `ex02_force_release` ตาม[บทที่ 8](08-stimulus-and-forcing.md) |
| ตำแหน่งของ breakpoint ในไฟล์ `.vhd` ตรงกับเลขบรรทัด | ทำตาม[บทที่ 7](07-debugging.md) แล้วเทียบกับเลขบรรทัดในไฟล์ |

### 3.3 เหตุผลที่ยังเขียนคู่มือนี้ได้แม้ยังไม่ได้รันบน Questa

1. **คำสั่งทุกคำสั่งมีที่มา** — เป็นคำสั่งที่ปรากฏใน Questa SIM Tutorial 2026.1
   หรือในเอกสาร ModelSim/Questa ทางการ ไม่มีคำสั่งที่แต่งขึ้น
2. **โค้ด VHDL ถูกพิสูจน์แล้ว** — สิ่งที่ทำให้คำสั่งล้มเหลวมักเป็นตัวโค้ด
   ไม่ใช่คำสั่ง การพิสูจน์โค้ดด้วย GHDL จึงตัดปัญหาส่วนใหญ่ออกไป
3. **มีการออกแบบให้ตรวจสอบย้อนกลับได้** — ทุกคำสั่งที่คู่มือแนะนำ
   มีคำสั่งตรวจผลกำกับ เพื่อให้ผู้เรียนรู้ว่า "รันแล้วได้ผลถูกต้อง"

---

## 4. วิธีใช้คู่มือนี้

### ถ้าเพิ่งเริ่มใช้ Questa กับ VHDL

[01](01-install-and-setup.md) → [02](02-concepts-and-flows.md) →
[03](03-compile-vhdl.md) → [04](04-load-and-elaborate.md) →
[05](05-gui-workflow.md) แล้วทำ `ex00` ถึง `ex02`

### ถ้าเคยใช้ Verilog มาก่อนแล้ว

[04](04-load-and-elaborate.md) → [07](07-debugging.md) →
[09](09-assertions-and-severity.md) → [14](14-checklists.md)

### ถ้าต้องทำ CI หรือรันจำนวนมาก

[10](10-tcl-and-batch.md) → [09](09-assertions-and-severity.md) →
[11](11-ghdl-cross-reference.md)

### ถ้าต้องสอนหรืออธิบายความต่างระหว่าง simulator

[11](11-ghdl-cross-reference.md) → [12](12-troubleshooting.md)

---

## 5. ชุดตัวอย่างโค้ด

ทุกตัวอย่างอยู่ใน [`code/reference/questa/`](../../../code/reference/questa/README.md)
และผ่านเกณฑ์การตรวจสอบ 6 ข้อด้วย GHDL (คอมไพล์และจำลองด้วย VHDL-2008,
คอมไพล์ด้วย VHDL-2002 และสังเคราะห์ด้วย `ghdl --synth`)

| ตัวอย่าง | เนื้อหา | marker |
|---|---|---|
| `ex00_counter_tutorial` | flow พื้นฐาน: สร้าง library คอมไพล์ โหลด และรัน | `GOLDEN_COUNTER_TUT_PASS` |
| `ex01_generic_override` | การ override generic และข้อจำกัดของสวิตช์ `-g` | `GOLDEN_GENERIC_OVERRIDE_PASS` |
| `ex02_force_release` | การให้ stimulus ด้วย `force` / `release` | `GOLDEN_FORCE_RELEASE_PASS` |
| `ex03_assert_severity` | ระดับ `severity` ของ assertion และการทำ negative test | `GOLDEN_ASSERT_SEVERITY_PASS` |

ตรวจทุกตัวอย่างด้วยคำสั่งเดียว

```bash
cd code/reference/questa
bash run.sh
```

ผลที่ต้องเห็น

```text
  สรุป: ผ่าน 4 ตัวอย่าง, ไม่ผ่าน 0 ตัวอย่าง
```

---

## 6. เครื่องมือที่ใช้ตรวจสอบ

| เครื่องมือ | รุ่น | บทบาทในคู่มือนี้ |
|---|---|---|
| **Questa SIM** | 2026.1 (ตามเอกสาร Questa SIM Tutorial ที่แนบมา) | เครื่องมือหลักที่คู่มือนี้อธิบาย |
| **ModelSim** | รุ่นก่อนหน้า | ใช้คำสั่งเดียวกันเป็นส่วนใหญ่ แต่ไฟล์ `.ini` ต่างกัน |
| **GHDL** | 1.0.0 (Dunoon, mcode) | ใช้พิสูจน์ว่าโค้ด VHDL ในชุดตัวอย่างถูกต้อง และเป็นทางเลือกสำรองเมื่อไม่มี license |

> คำสั่งของ ModelSim และ Questa แทบทั้งหมดเหมือนกัน
> ต่างกันที่ไฟล์ตั้งค่า (`modelsim.ini` กับ `questasim.ini`)
> และความสามารถเพิ่มเติมของ Questa ด้าน coverage, assertion และ debug
> ดูรายละเอียดใน[บทที่ 1](01-install-and-setup.md)

---

## แบบฝึกหัดท้ายบท

1. ติดตั้ง Questa SIM หรือ ModelSim แล้วรัน `vsim -version` จดค่าเวอร์ชันที่ได้
   พร้อมระบุว่าใช้ไฟล์ `.ini` แบบใด
2. รัน `bash scripts/check_example.sh ex00_counter_tutorial counter_tut tb_counter_tut`
   ใน `code/reference/questa/` แล้วบันทึกผลลัพธ์ทั้ง 6 บรรทัด
3. ถ้ามี license ของ Questa ให้รัน
   `bash scripts/questa_run.sh ex00_counter_tutorial tb_counter_tut`
   แล้วเปรียบเทียบผลกับข้อ 2 อธิบายว่าต่างกันตรงไหน
4. ถ้ายังไม่มี license ให้เขียนขั้นตอนของข้อ 3 ลงในบันทึก เพื่อนำไปรันภายหลัง
5. ตรวจว่า `vsim -version` รายงานเวอร์ชันใด และเทียบกับตารางใน
   [ภาคผนวก B](appendix-b-references.md) ว่ารุ่นที่ใช้อยู่ในช่วงเวลาใด

---

## คำถามท้ายบท

1. คำสั่งในคู่มือนี้ที่ยืนยันด้วยการรันจริงมาจากเครื่องมือใด และข้อมูลส่วนใด
   ยังต้องให้ผู้เรียนตรวจสอบเอง
2. เหตุใดตัวอย่างทั้ง 4 ต้องคอมไพล์ผ่านทั้ง VHDL-2008 และ VHDL-2002
3. ผลของ `ghdl --synth` บอกอะไรและไม่บอกอะไร
4. ถ้าคำสั่งของ Questa ที่คัดลอกจากคู่มือนี้ทำงานไม่ถูกต้อง
   ขั้นตอนแรกที่ควรทำคืออะไร และเพราะอะไร
5. ความต่างระหว่าง ModelSim กับ Questa ที่กระทบผู้ใช้ VHDL คืออะไร

---

**อ่านต่อ:** [บทที่ 1 — การติดตั้งและตั้งค่า](01-install-and-setup.md) →
[บทที่ 2 — แนวคิดและ flow การทำงาน](02-concepts-and-flows.md) →
[คู่มือ VHDL Golden Reference](../vhdl/README.md)
