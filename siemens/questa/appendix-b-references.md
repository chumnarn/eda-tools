# ภาคผนวก B: แหล่งอ้างอิง

> เอกสารและเว็บไซต์ที่คู่มือนี้อ้างอิง
> ทุกลิงก์ภายนอกผ่านการตรวจสอบแล้วว่าเปิดได้

---

## สารบัญ

- [1. เอกสารประจำเครื่องมือ](#1-เอกสารประจำเครื่องมือ)
- [2. เว็บไซต์ผู้ผลิต](#2-เว็บไซต์ผู้ผลิต)
- [3. มาตรฐานภาษา](#3-มาตรฐานภาษา)
- [4. เครื่องมืออื่น](#4-เครื่องมืออื่น)
- [5. เอกสารของคอร์ส](#5-เอกสารของคอร์ส)

---

## 1. เอกสารประจำเครื่องมือ

| รหัส | เอกสาร | ลิงก์ |
|---|---|---|
| [SIM-01] | **Questa SIM Tutorial 2026.1** — เอกสารหลักของคู่มือนี้ | [questa_sim_tut_2026_1.pdf](https://ww1.microchip.com/downloads/aemDocuments/documents/FPGA/swdocs/questasim/questa_sim_tut_2026_1.pdf) |
| [SIM-02] | **Questa SIM User's Manual** — คู่มือผู้ใช้ฉบับเต็ม | [questa_sim_user_2024_2.pdf](https://ww1.microchip.com/downloads/aemDocuments/documents/FPGA/swdocs/questasim/questa_sim_user_2024_2.pdf) |
| [SIM-03] | **Questa SIM Command Reference Manual** — รายละเอียดตัวเลือกของคำสั่งทุกคำสั่ง | [questa_sim_ref_2026_1.pdf](https://ww1.microchip.com/downloads/aemDocuments/documents/FPGA/swdocs/questasim/questa_sim_ref_2026_1.pdf) |
| [SIM-04] | **ModelSim User's Manual** — สำหรับผู้ที่ใช้ ModelSim รุ่นก่อนหน้า | [modelsim_user_2024_2.pdf](https://ww1.microchip.com/downloads/aemDocuments/documents/FPGA/swdocs/modelsim/modelsim_user_2024_2.pdf) |

> เอกสาร [SIM-01] คือไฟล์เดียวกับที่แนบมาให้กับคู่มือนี้
> หัวข้อ 2 และหัวข้อ 3 ของเอกสารนั้นเป็นที่มาของ
> [บทที่ 2](02-concepts-and-flows.md), [บทที่ 5](05-gui-workflow.md)
> และข้อมูลเรื่องการตั้ง breakpoint ที่เลขบรรทัดของ VHDL ต่างจาก Verilog

### 1.1 วิธีเปิดเอกสารในเครื่องมือ

เอกสารทั้งหมดติดตั้งมากับเครื่องมือแล้ว

| ระบบ | ตำแหน่ง |
|---|---|
| Windows | `<install_dir>/docs/pdf_docs` |
| Linux | `<install_dir>/docs/pdf_docs` |

เปิดจากเมนู **Help → PDF Bookcase** ในหน้าต่างหลักของ Questa SIM

---

## 2. เว็บไซต์ผู้ผลิต

| รหัส | เอกสาร | ลิงก์ |
|---|---|---|
| [SIM-05] | หน้าผลิตภัณฑ์ Questa ของ Siemens EDA | [eda.sw.siemens.com/en-US/products/ic/questa](https://eda.sw.siemens.com/en-US/products/ic/questa/) |
| [SIM-06] | Siemens EDA Support Center — ใบอนุญาตและการสนับสนุน | [support.sw.siemens.com](https://support.sw.siemens.com/) |

---

## 3. มาตรฐานภาษา

| รหัส | เอกสาร | ลิงก์ |
|---|---|---|
| [LANG-01] | **IEEE 1076-2008** — IEEE Standard for VHDL Language | [standards.ieee.org/ieee/1076/5693](https://standards.ieee.org/ieee/1076/5693/) |
| [LANG-02] | **IEEE 1076-2002** — IEEE Standard for VHDL Language | [standards.ieee.org/ieee/1076/10360](https://standards.ieee.org/ieee/1076/10360/) |
| [LANG-03] | **IEEE 1076-2019** — IEEE Standard for VHDL Language | [standards.ieee.org/ieee/1076/7338](https://standards.ieee.org/ieee/1076/7338/) |
| [LANG-04] | **IEEE 1364** — IEEE Standard for Verilog Language | [standards.ieee.org/ieee/1364](https://standards.ieee.org/ieee/1364/) |
| [LANG-05] | Accellera — เอกสารมาตรฐาน IEEE ที่ให้ดาวน์โหลด | [accellera.org/downloads/ieee](https://www.accellera.org/downloads/ieee) |

> [LANG-02] คือมาตรฐานที่ห้องเรียนใช้
> เนื่องจาก ModelSim/Questa ตั้งค่า `VHDL93 = 2002`
> จึงต้องหลีกเลี่ยงฟีเจอร์ของ VHDL-2008 ในโค้ดของคอร์สนี้

---

## 4. เครื่องมืออื่น

| รหัส | เอกสาร | ลิงก์ |
|---|---|---|
| [TOOL-01] | **GHDL** — เครื่องมือจำลอง VHDL แบบโอเพนซอร์ส | [ghdl.github.io/ghdl](https://ghdl.github.io/ghdl/) |
| [TOOL-02] | GHDL — คู่มือการจำลอง | [Simulation](https://ghdl.github.io/ghdl/using/Simulation.html) |
| [TOOL-03] | GHDL — คู่มือการสังเคราะห์ | [Synthesis](https://ghdl.github.io/ghdl/using/Synthesis.html) |
| [TOOL-04] | GHDL — ซอร์สโค้ดและ release | [github.com/ghdl/ghdl](https://github.com/ghdl/ghdl) |
| [TOOL-05] | **GTKWave** — เครื่องมือดู waveform ที่ใช้ร่วมกับ GHDL | [gtkwave.sourceforge.net](https://gtkwave.sourceforge.net/) |

---

## 5. เอกสารของคอร์ส

| รหัส | เอกสาร | ลิงก์ |
|---|---|---|
| [REF-01] | คู่มือ VHDL Golden Reference for RTL Designers | [docs/reference/vhdl/README.md](../vhdl/README.md) |
| [REF-02] | สัญญารูปแบบโค้ดของคอร์ส | [code/reference/vhdl/STYLE-CONTRACT.md](../../../code/reference/vhdl/STYLE-CONTRACT.md) |
| [REF-03] | สัญญารูปแบบโค้ดของชุดคู่มือ Questa | [code/reference/questa/STYLE-CONTRACT.md](../../../code/reference/questa/STYLE-CONTRACT.md) |
| [REF-04] | ข้อตกลงการเขียนเอกสารของคอร์ส | [docs/STYLE-GUIDE.md](../../STYLE-GUIDE.md) |

---

## หมายเหตุเรื่องเวอร์ชัน

- เอกสาร [SIM-01] และ [SIM-03] เป็นของซอฟต์แวร์รุ่น **2026.1**
- เอกสาร [SIM-02] และ [SIM-04] เป็นของรุ่น **2024.2**
  รายละเอียดของตัวเลือกบางตัวอาจต่างกันระหว่างรุ่น
- เอกสารทั้งหมดระบุชัดเจนว่าเอกสารเป็นทรัพย์สินทางปัญญาของ Siemens
  การเผยแพร่ต่อในห้องเรียนต้องเป็นไปตามข้อกำหนดการอนุญาตใบอนุญาตขององค์กร
- เอกสารที่ติดตั้งมากับเครื่องมือของห้องเรียนเป็นแหล่งอ้างอิงหลัก
  เพราะเป็นเวอร์ชันเดียวกับที่ใช้งานจริง

---

**อ่านต่อ:** [ดัชนีคู่มือ](README.md) →
[คู่มือ VHDL Golden Reference](../vhdl/README.md)
