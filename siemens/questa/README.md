# Questa SIM for RTL Designers — คู่มือการใช้งานสำหรับ VHDL Simulation

> คู่มือสำหรับผู้เรียนและผู้ออกแบบ RTL ที่ต้องใช้ Questa SIM (หรือ ModelSim)
> จำลองโค้ด VHDL ได้อย่างมั่นใจ รู้ว่าอะไรคือปัญหา และรู้ว่าอะไรทำงานไม่ได้

**เครื่องมือที่ใช้ตรวจสอบตัวอย่างทั้งหมด:** GHDL 1.0.0 (Dunoon, mcode) ใน WSL2 Ubuntu 22.04
**เอกสารอ้างอิงหลัก:** [Questa SIM Tutorial 2026.1](appendix-b-references.md#1-เอกสารประจำเครื่องมือ)
**ชุดตัวอย่างโค้ด:** [`code/reference/questa/`](../../../code/reference/questa/README.md)

---

## คู่มือนี้เหมาะกับใคร

- นักศึกษาวิศวกรรมดิจิทัลไอซีที่ต้องใช้ Questa SIM กับงาน VHDL
- ผู้ประกอบงานที่เคยใช้ Verilog มาก่อนแล้วต้องดูแลโค้ด VHDL
- อาจารย์ที่ต้องการคู่มือที่ทดสอบแล้วจริง ไม่ใช่ตัวอย่างที่แต่งขึ้น

## คู่มือนี้ไม่ใช่อะไร

- ไม่ใช่คู่มือภาษา VHDL — ดูที่
  [VHDL Golden Reference](../vhdl/README.md) สำหรับเรื่องภาษา
- ไม่ครอบคลุม Verilog, SystemVerilog, UPF, SystemC, coverage และ PSL
  แบบละเอียด
- **ไม่ได้ยืนยันว่าคำสั่งของ Questa ทุกคำสั่งผ่านการรันจริง**
  เพราะเครื่องที่จัดทำคู่มือนี้ไม่มี license ของ Questa
  ดูหัวข้อ "สถานะการทดสอบ" ใน[บทนำ](00-preface.md#3-สถานะการทดสอบ--อ่านก่อนใช้คำสั่ง)

---

## สารบัญ

### ภาคเริ่มต้น

| บท | ชื่อ | สิ่งที่จะได้ |
|---|---|---|
| [00](00-preface.md) | บทนำ | ขอบเขตคู่มือ สถานะการทดสอบ และเส้นทางการอ่าน |
| [01](01-install-and-setup.md) | การติดตั้งและตั้งค่า | PATH, ใบอนุญาต, ไฟล์ `.ini` และการตรวจเวอร์ชัน |
| [02](02-concepts-and-flows.md) | แนวคิดและ flow | library, project, resource library และการ optimize |

### ภาคหลัก

| บท | ชื่อ | สิ่งที่จะได้ |
|---|---|---|
| [03](03-compile-vhdl.md) | คอมไพล์ VHDL | `vcom`, มาตรฐาน `-93`/`-2002`/`-2008`, ลำดับการคอมไพล์ |
| [04](04-load-and-elaborate.md) | โหลดและ elaborate | `vsim`, top-level, architecture, configuration, generic |
| [05](05-gui-workflow.md) | การทำงานแบบ GUI | หน้าต่าง Transcript, Library, Structure, Objects, Source |
| [06](06-waveform.md) | การวิเคราะห์ waveform | การเพิ่มสัญญาณ, cursor, การวัดเวลา, ค่า X/U/Z ของ VHDL |
| [07](07-debugging.md) | การ debug | breakpoint, step, `examine`, `watch` และ delta cycle |
| [08](08-stimulus-and-forcing.md) | การให้ stimulus | `force`/`release`/`deposit` และกฎเฉพาะของ VHDL |
| [09](09-assertions-and-severity.md) | assertion และ severity | สี่ระดับ severity, `onerror`, รหัสออก และ negative test |
| [10](10-tcl-and-batch.md) | Tcl และ batch | ไฟล์ `.do`, โหมดไม่เปิด GUI และการเชื่อมกับ CI |

### ภาคเทียบเทียบและอ้างอิง

| บท | ชื่อ | สิ่งที่จะได้ |
|---|---|---|
| [11](11-ghdl-cross-reference.md) | เทียบเทียบ GHDL ↔ Questa | ตารางคำสั่งเทียบเท่าและความต่างที่วัดได้จริง |
| [12](12-troubleshooting.md) | ปัญหาที่พบบ่อย | ตารางอาการ → สาเหตุ → วิธีแก้ |
| [13](13-command-reference.md) | ตารางคำสั่งทั้งหมด | คลังค้นคำสั่งที่ใช้ในคู่มือนี้ |
| [14](14-checklists.md) | เช็กลิสต์ | เช็กลิสต์ก่อนเริ่มงาน ก่อนรัน และก่อนส่งงาน |

### ภาคผนวก

| ภาคผนวก | ชื่อ | สิ่งที่จะได้ |
|---|---|---|
| [A](appendix-a-glossary.md) | ศัพท์อ้างอิง | ศัพท์ VHDL, simulator และการทดสอบ |
| [B](appendix-b-references.md) | แหล่งอ้างอิง | มาตรฐาน IEEE และเอกสารเครื่องมือที่ตรวจลิงก์แล้ว |

---

## ชุดตัวอย่างโค้ด

ทุกตัวอย่างอยู่ใน
[`code/reference/questa/examples/`](../../../code/reference/questa/README.md)
และผ่านเกณฑ์ 6 ข้อด้วย GHDL (คอมไพล์และจำลองด้วย VHDL-2008,
คอมไพล์ด้วย VHDL-2002 และสังเคราะห์ด้วย `ghdl --synth`)

| ตัวอย่าง | บทที่อธิบาย | เนื้อหา | marker |
|---|---|---|---|
| `ex00_counter_tutorial` | 02, 03, 04 | flow พื้นฐานของ Questa ตั้งแต่สร้าง library จนรัน | `GOLDEN_COUNTER_TUT_PASS` |
| `ex01_generic_override` | 04 | การ override generic และข้อจำกัดของสวิตช์ `-g` | `GOLDEN_GENERIC_OVERRIDE_PASS` |
| `ex02_force_release` | 07, 08 | การให้ stimulus ด้วย `force` และ `release` | `GOLDEN_FORCE_RELEASE_PASS` |
| `ex03_assert_severity` | 09, 10 | ระดับ `severity` ของ assertion และการทำ negative test | `GOLDEN_ASSERT_SEVERITY_PASS` |

ตรวจทุกตัวอย่างด้วยคำสั่งเดียว

```bash
cd code/reference/questa
bash run.sh
```

ผลที่ต้องเห็น

```text
  สรุป: ผ่าน 4 ตัวอย่าง, ไม่ผ่าน 0 ตัวอย่าง
```

> สคริปต์จะตรวจด้วย GHDL เสมอ
> และจะตรวจด้วย Questa เพิ่มเติมเมื่อพบ `vlib`/`vcom`/`vsim` ใน `PATH`

---

## เส้นทางการอ่านที่แนะนำ

### ถ้าเพิ่งเริ่มใช้ Questa กับ VHDL

[01](01-install-and-setup.md) → [02](02-concepts-and-flows.md) →
[03](03-compile-vhdl.md) → [04](04-load-and-elaborate.md) →
[05](05-gui-workflow.md) แล้วทำ `ex00` ถึง `ex02`

### ถ้าเคยใช้ Verilog มาก่อนแล้ว

[04](04-load-and-elaborate.md) → [08](08-stimulus-and-forcing.md) →
[07](07-debugging.md) → [14](14-checklists.md)

### ถ้าต้องทำ CI หรือรันจำนวนมาก

[10](10-tcl-and-batch.md) → [09](09-assertions-and-severity.md) →
[11](11-ghdl-cross-reference.md)

### ถ้าไม่มี license ของ Questa

[11](11-ghdl-cross-reference.md) → [02](02-concepts-and-flows.md) →
[คู่มือ VHDL Golden Reference](../vhdl/README.md)

---

## ข้อตกลงที่ใช้ทั้งคู่มือและตัวอย่างโค้ด

สัญญารูปแบบฉบับเต็มอยู่ที่
[`code/reference/questa/STYLE-CONTRACT.md`](../../../code/reference/questa/STYLE-CONTRACT.md)
สรุปสั้น ๆ

1. คอมไพล์ผ่านทั้ง VHDL-2008 และ VHDL-2002
   เพราะ ModelSim/Questa ของห้องเรียนตั้ง `VHDL93 = 2002`
2. ใช้ `ieee.numeric_std` เท่านั้น ห้ามใช้ `ieee.std_logic_arith`
3. ทุก design unit ต้องมี context clause ของตัวเอง
4. ห้ามใช้ `std.env.stop`, `process (all)` และ bit string literal แบบ `x"FF"`
   (เหตุผลที่ถูกต้องของข้อ 4 อยู่ใน [บทที่ 3](03-compile-vhdl.md))
5. testbench ต้องเป็น self-checking มี marker `GOLDEN_<ชื่อ>_PASS` และ watchdog
6. นาฬิกาใน testbench ต้องหยุดเมื่อ `done` เป็นจริง
7. ข้อความใน `report "..."` ต้องเป็น ASCII เท่านั้น
8. ไฟล์ `.do` ต้องมี `onerror` และ `onbreak` และห้ามมี `quit`

---

## ข้อจำกัดของคู่มือนี้

- คำสั่งของ Qesta มาจาก Questa SIM Tutorial 2026.1 และเอกสาร ModelSim/Questa
  แต่**ยังไม่ได้รันบนเครื่องที่จัดทำคู่มือ** เพราะไม่มี license
  ดู[บทนำ](00-preface.md#32-สิ่งที่ยังไม่ได้ยืนยันบนเครื่องนี้) สำหรับรายการที่ต้องทดสอบเอง
- ข้อมูลพฤติกรรมของ GHDL วัดด้วย GHDL 1.0.0 เท่านั้น รุ่นอื่นอาจต่างกัน
- ไม่มีผลการสังเคราะห์กับ PDK จริง (IHP SG13G2 หรือ SKY130)
  จึงไม่มีตัวเลขด้านพื้นที่ กำลังไฟ หรือ timing
- เอกสารประจำเครื่องมือเป็นทรัพย์สินทางปัญญาของ Siemens
  ให้ใช้เอกสารที่ติดตั้งมากับเครื่องมือของห้องเรียนเป็นหลัก

---

**อ่านต่อ:** [บทที่ 0 — บทนำ](00-preface.md) →
[บทที่ 1 — การติดตั้งและตั้งค่า](01-install-and-setup.md) →
[คู่มือ VHDL Golden Reference](../vhdl/README.md)
