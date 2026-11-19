## ภาคนำ

### คู่มือนี้คืออะไร

คู่มือนี้สอน **Tanner Digital Implementer (TDI)** — เครื่องมือที่นำ RTL ดิจิทัล
เข้าไปวางและเดินสาย (place and route) ภายในเลย์เอาต์ของวงจรอนุกรม-อนาล็อกที่ออกแบบ
ด้วย L-Edit

TDI ประกอบด้วยเครื่องยนต์สองตัวที่ทำงานอยู่คนละฝั่งกัน

| ส่วน | เครื่องยนต์ | ทำอะไร |
|---|---|---|
| การสังเคราะห์ (synthesis) | **Oasys AMS** | RTL → netlist ระดับ gate |
| การวางและเดินสาย (P&R) | **Nitro AMS** | netlist ระดับ gate → เลย์เอาต์ |

ส่วนที่คุณตั้งค่าอยู่ในหน้าต่าง **Setup TDI** ของ L-Edit เป็นแค่ตัวกรอกข้อมูล
หน้าต่างนี้ **ไม่ได้รันอะไรเอง** — มันเขียนไฟล์ตั้งค่าออกมาเป็น TCL
แล้วส่งไฟล์นั้นไปยังเครื่อง Linux ที่ติดตั้ง Nitro เพื่อให้ไปรันที่นั่น

> **สิ่งที่ทำให้คู่มือนี้ต่างจากคู่มือทั่วไป**
>
> คู่มือนี้เขียนจากการ **อ่านสคริปต์จริงในเครื่อง** ไม่ใช่จากการเล่าเรื่อง
> ไฟล์ที่อ้างอิงทุกอย่างอยู่ใน `C:\Siemens\Custom IC\Custom IC 2025.4\x64`
> และตัวอย่าง ADC8 ที่ติดตั้งมาพร้อมผลิตภัณฑ์
>
> ตัวเลขทุกตัวในคู่มือนี้มาจากการรันบนเครื่องนี้จริง
> ตัวอย่างเช่น ขนาดบล็อก 177.800 × 53.000 µm ความหนาแน่นพอร์ต 15.200 µm
> และความกว้าง power ring ที่ flow คำนวณได้ 4.1 µm

### ผู้เรียนจะได้อะไร

เมื่อทำครบทุก lab ผู้เรียนจะทำสิ่งเหล่านี้ได้ด้วยตัวเอง

1. อธิบายได้ว่า **TDI, Oasys และ Nitro อยู่ตรงไหนของกระบวนการ**
   และไฟล์ไหนถูกส่งข้ามไปยังเครื่อง Linux
2. ตั้งค่า **หน้า Setup TDI ทั้ง 7 หน้า** ได้อย่างถูกต้อง ตั้งแต่ไฟล์เทคโนโลยี
   ไปจนถึงแผน power และ floorplan
3. อ่าน **สัญญาระหว่างหน้าต่าง Setup TDI กับ flow** ได้
   คือรู้ว่าค่าที่กรอกในแต่ละช่องไปอยู่ในตัวแปร TCL ตัวไหน
   และถูกสคริปต์ไฟล์ไหนอ่าน
4. **ตรวจความถูกต้องของอินพุตทั้งหมดก่อนรันจริง** ได้ด้วยตัวเอง
   โดยไม่ต้องรอให้ flow พังแล้วค่อยหาสาเหตุ
5. แก้ปัญหาที่พบบ่อยของการรัน TDI ได้ ทั้งจากฝั่งข้อมูลนำเข้า
   (LEF/Liberty/PTF ไม่ตรงกัน, DEF ไม่ตรงกับ RTL) และจากฝั่งแผนที่
   (power ring ชิดเกิน spacing, จำนวน spacing ของ ring ไม่ถูกต้อง)
6. อ่าน **ผลลัพธ์ของการวางและเดินสาย** ได้ และรู้ว่าไฟล์ไหนอยู่ตรงไหน

### ขอบเขตของคู่มือนี้

คู่มือนี้ครอบคลุม **การเตรียมอินพุต การตั้งค่า และการตรวจสอบ**
ของกระบวนการ TDI ตั้งแต่ไฟล์ LEF/Liberty/PTF จนถึงการอ่านรายงานผลลัพธ์

สิ่งที่ **อยู่นอกขอบเขต** เพราะต้องมีเครื่อง Linux ที่ติดตั้ง Nitro และมี license:

- การสังเคราะห์และวางเดินสายจริง ๆ (บทที่ 5 อธิบายขั้นตอนและผลลัพธ์ที่คาดว่าจะได้)
- การแก้ ECO หลังวางเดินสาย และการทำ LVS / DRC / signoff

เนื่องจากเครื่องนี้ไม่มี Nitro ทุก lab ในคู่มือนี้จึงทำงานในส่วนที่
**ตรวจสอบได้จริงบนเครื่อง Windows** โดยไม่ต้องใช้ Nitro เลย
ผลของแต่ละ lab คือ PASS/FAIL จริง ไม่ใช่ตัวอย่างที่แต่งขึ้น

### สิ่งที่ต้องมี

| ต้องมี | หมายเหตุ |
|---|---|
| **Custom IC Platform 2025.4** | ติดตั้งอยู่ที่ `C:\Siemens\Custom IC\Custom IC 2025.4\x64` แล้ว |
| **ไฟล์ตัวอย่าง ADC8** | อยู่ที่ `...\Documents\SiemensEDA\CustomIC_2025.4\Designs\ADC8` แล้ว |
| **Node.js 18 ขึ้นไป** | ใช้รันตัวตรวจสอบใน lab — ตรวจ `node -v` |
| **Generic 250 nm libraries** | คัดลอกมาไว้ใน `design/files/` แล้ว ไม่ต้องติดตั้ง PDK เพิ่ม |
| **pandoc + Google Chrome** | ใช้สร้าง HTML/PDF ของคู่มือ — ต้องมีเฉพาะตอนจะสร้างเอกสารใหม่ |

> **เรื่องการรัน Nitro จริง**
>
> Nitro เป็นเครื่องยนต์ของ Mentor/Siemens ที่ทำงานบน Linux เท่านั้น
> ไฟล์ตัวอย่างทั้งหมดในคู่มือนี้เตรียมไว้ครบแล้ว
> ส่วนที่เหลือคือการส่งไฟล์ไปรันบนเครื่อง Linux ของคุณ
> ซึ่งอธิบายไว้ในบทที่ 5

### โครงสร้างโปรเจกต์

```text
tdi_lab/
├── README.md                     หน้าหน้าแรกของโปรเจกต์
├── docs/
│   ├── parts/                    ต้นฉบับที่แยกเป็นส่วน ๆ
│   ├── Lab_Guide_TDI.md          คู่มือฉบับเต็ม (Markdown)
│   ├── Lab_Guide_TDI.html        คู่มือฉบับเต็ม (HTML)
│   └── Lab_Guide_TDI.pdf         คู่มือฉบับเต็ม (PDF)
├── tools/
│   ├── checks/                   ตัวตรวจสอบที่ lab 01..06 เรียกใช้ (Node.js)
│   ├── run_template.cmd          เทมเพลต run.cmd ของแต่ละ lab
│   ├── make-runners.ps1          ตัวสร้าง run.cmd ของทุก lab
│   ├── build-docs.ps1            รวม Markdown แล้วสร้าง HTML + PDF
│   └── make-zip.ps1              สร้างไฟล์ ZIP ส่งมอบ
├── design/
│   ├── from_ledit.def            boundary + พอร์ตที่ L-Edit export ออกมา
│   ├── scanchain.tcl             สคริปต์ตั้งค่า scan chain
│   ├── nitro_settings_ADCCtrl.tcl  ตัวอย่างไฟล์ตั้งค่าที่ Setup TDI เขียนออกมา
│   └── files/                    LEF / Liberty / PTF / SDC / RTL ที่ต้องส่งไป Linux
├── lab01_rtl_ports/    ...  lab06_settings/
└── lab07_regression/            รันทุก lab พร้อมกันและสรุปผล
```

### วิธีใช้คู่มือนี้

รัน lab เดียวด้วย

```bat
cd tdi_lab\lab01_rtl_ports
run.cmd
```

รันทั้งชุดด้วย

```bat
cd tdi_lab\lab07_regression
run.cmd
```

แล้วดูรหัสจบของ `cmd.exe`

| รหัส | ความหมาย |
|---|---|
| `0` | ผ่าน (PASS) |
| `1` | ไม่ผ่าน (FAIL) |
| `2` | หาเครื่องมือหรือโฟลเดอร์ไม่เจอ |

ผลลัพธ์ของแต่ละ lab จะอยู่ใน `<lab>/results/output.txt`
และไฟล์ `result.txt` จะมีคำว่า `PASS` หรือ `FAIL`

### ข้อตกลงเบื้องต้น

- **ตัวเลขทุกตัวในคู่มือนี้มาจากการรันจริง** ถ้าคุณทำตามแล้วได้ตัวเลข
  ที่ต่างจากที่เขียนไว้ แปลว่ามีอะไรเปลี่ยนไป — ให้ตรวจสอบก่อน
- **ลำดับของไฟล์ LEF สำคัญ**: tech LEF ต้องมาก่อน standard cell LEF เสมอ
  (หัวข้อ 2.2)
- **ตัวแปร TCL ที่หายไปไม่ใช่ข้อผิดพลาด**: TCL อ่านตัวแปรที่ไม่มีได้เป็นค่าว่าง
  flow จะไม่หยุด แต่จะผลิตผลลัพธ์ที่ผิด (lab 06)
- **ไฟล์ `.cmd` ในโปรเจกต์นี้เป็น ASCII ล้วน** เพราะ Thai หรือ UTF-8
  ในไฟล์ `.cmd` ทำให้ `cmd.exe` อ่านโครงสร้างบรรทัดผิด

---

## บทที่ 1 — TDI อยู่ตรงไหนของกระบวนการ

### 1.1 ภาพรวมสามชั้น

TDI ไม่ใช่เครื่องมือเดียว แต่เป็น **กลไกเชื่อม** ระหว่างเครื่องมือสองฝั่ง

```text
   เครื่อง Windows (L-Edit)                  เครื่อง Linux (Nitro / Oasys)
   ┌────────────────────────────┐            ┌──────────────────────────────┐
   │  S-Edit / L-Edit           │            │  Oasys AMS   (synthesis)     │
   │   ├ วาด boundary           │            │   └ อ่าน LEF / Liberty / PTF  │
   │   ├ วาดพอร์ต                │            │   └ อ่าน RTL                  │
   │   └ โหลด design            │            │                              │
   │                            │  คัดลอกไฟล์  │  Nitro AMS  (place & route)  │
   │  ┌──────────────────────┐  │ ──────────► │   └ floorplan, powerplan     │
   │  │  Setup TDI (7 หน้า)   │  │   /tmp/     │   └ place, cts, route        │
   │  │  ↓ เขียนไฟล์ตั้งค่า       │  │  <user>_    │   └ export                   │
   │  │  nitro_settings.tcl  │  │  nitro_data │                              │
   │  └──────────────────────┘  │             └──────────────────────────────┘
   └────────────────────────────┘
```

**สิ่งที่ต้องจำ**

1. หน้าต่าง Setup TDI อยู่ฝั่ง Windows แต่ **เครื่องยนต์รันอยู่ฝั่ง Linux**
2. ไฟล์ทั้งหมดในโฟลเดอร์ข้อมูลของ TDI จะถูกคัดลอกไปที่
   `/tmp/<ชื่อผู้ใช้>_nitro_data` บนเครื่อง Linux
3. ผลลัพธ์จะถูกดึงกลับมาที่โฟลเดอร์ `results/` ของโฟลเดอร์ข้อมูลเดิม

หลักการข้อ 2 ไม่ใช่ข้อสันนิษฐาน แต่มาจากสคริปต์จริง
`LinuxUtils/nitro_worker` ในตัวผลิตภัณฑ์:

```python
self.defaultWorkDir = getpass.getuser() + "_nitro_data"
self.jobpath = os.path.abspath(os.path.join(basejobpath, self.defaultWorkDir))
```

โดย `basejobpath = tempfile.gettempdir()` บน Linux ก็คือ `/tmp`

### 1.2 โปรโตคอลการส่งไฟล์

สคริปต์ `nitro_worker` เป็นตัวกลางที่ L-Edit ใช้คุยกับเครื่อง Linux
คำสั่งที่รองรับ (ดูจากโค้ดจริงในไฟล์):

| คำสั่ง | หน้าที่ |
|---|---|
| `NITRO_INITJOB` | สร้างโฟลเดอร์ทำงาน |
| `ATTACHJOB` | เข้าต่อกับงานที่ค้างอยู่ด้วย job id |
| `PUT` / `GET` / `GETFILE` | ส่งและดึงไฟล์ |
| `MKDIR` / `DELDIR` / `DEL_FILE_REC` | จัดการโฟลเดอร์ |
| `GSTAT` / `STAT` | ดูขนาดไฟล์เพื่อเทียบว่าอัปเดตแล้วหรือยัง |
| `POSTP` | งานหลังประมวลผล เช่น รวมรายงานและย้ายไฟล์ KPI |

งานหลังประมวลผล `POSTP` มีสามแบบที่ต้องรู้ เพราะเป็นเหตุผลว่า
**ทำไมถึงหาไฟล์รายงานไม่เจอในบางครั้ง**

| คำสั่งย่อย | ผลลัพธ์ที่ได้ |
|---|---|
| `merge_reports` | โฟลเดอร์ `reports/` ถูกคัดลอกเข้า `results/reports/` |
| `kpi_reports` | โฟลเดอร์ `.kpi_files/` และไฟล์ `Kpi.html` ถูกย้ายเข้า `results/` |
| `synthesized_sdc` | ไฟล์ SDC ที่ synthesis เขียนได้ถูกคัดลอกเข้า `results/` |

> **เคล็ดลับในการหาไฟล์ที่หาย**
>
> ถ้าคุณหาไฟล์รายงานไม่เจอ ให้ดู `results/reports/` ก่อนเสมอ
> เพราะรายงานหลักจะอยู่ในโฟลเดอร์ `reports/` บนเครื่อง Linux
> แล้วถึงถูกคัดลอกมาอยู่ `results/reports/` ตอนปิดงาน

### 1.3 สิบขั้นตอนของ flow

สคริปต์ตัวขับคือ `ap_ref_flows/aprisa_ams.tcl` ในตัวผลิตภัณฑ์
มันเลือกขั้นตอนจากตัวแปร `ams_run_control`

| ค่า | ขั้นตอนที่ทำ |
|---|---|
| `synpnr` | ทั้งสิบขั้นตอน |
| `syn` | `data_prep` → `rtl_synthesis` → `floorplan` → `powerplan` → `physical_synthesis` |
| `pnr` | ตั้งแต่ `data_prep` จนถึง `export` (รวมขั้น `rtl_synthesis` ด้วย) |

รายชื่อขั้นตอนตามลำดับ:

```text
data_prep → rtl_synthesis → floorplan → powerplan → physical_synthesis
          → place → cts → post_cts → route → export
```

> **ข้อสังเกตที่ต้องระวัง**
>
> โหมด `pnr` ก็ยังรันขั้น `rtl_synthesis` อยู่
> ดังนั้นถ้าคุณเตรียม netlist ระดับ gate ไว้แล้วแล้วเลือก `pnr`
> ขั้นนี้จะทำงานกับ netlist ที่คุณให้ ไม่ใช่ RTL เดิม

### 1.4 ไฟล์ที่ flow เขียนออกมา

จาก `tanner_oasys.tcl` (ขั้น synthesis) และ `ap_ref_flows/9_export.tcl`
(ขั้น export) ไฟล์ผลลัพธ์หลักคือ

| ไฟล์ | มาจาก | ใช้ทำอะไร |
|---|---|---|
| `results/<top>_syn.v` | ขั้น synthesis | netlist ระดับ gate |
| `dbs/<top>_syn` | ขั้น synthesis | ฐานข้อมูลของ Oasys (ไว้ต่อยอด) |
| `<top>_syn.sdc` | ขั้น synthesis | SDC ที่ synthesis เขียนกลับมา |
| `results/<top>_scan.def` | ขั้น synthesis | นิยาม scan chain (มีเมื่อเปิด scan) |
| `results/reports/` | ทุกขั้น | รายงานทั้งหมด |
| `results/Kpi.html` | ขั้น export | สรุปตัวชี้วัดหลัก |

### 1.5 ไฟล์ติดตั้งของผลิตภัณฑ์ที่คู่มือนี้อ้างถึง

ทั้งหมดอยู่ที่ `C:\Siemens\Custom IC\Custom IC 2025.4\x64`

| ไฟล์ | หน้าที่ |
|---|---|
| `tanner_oasys.tcl` | สคริปต์ขั้น synthesis — อ่าน LEF/Liberty/PTF/RTL แล้วสังเคราะห์ |
| `nitro.tcl` | จุดเข้าสู่ flow ของ Nitro |
| `ap_ref_flows/aprisa_ams.tcl` | ตัวขับ flow สิบขั้นตอน |
| `ap_ref_flows/flow_variables.tcl` | ค่าปริยายของตัวแปรทั้งหมดของ flow |
| `ap_ref_flows/0..9_*.tcl` | สคริปต์ของแต่ละขั้นตอน |
| `ap_ref_flows/tcl_procs/` | กระบวนการช่วยเหลือของ flow |
| `LinuxUtils/nitro_worker` | ตัวกลางส่งไฟล์ไปยังเครื่อง Linux |

---


## บทที่ 2 — หน้าต่าง Setup TDI ทั้ง 7 หน้า

หน้าต่าง Setup TDI มี 7 หน้า แต่ละหน้าคือการกรอกกลุ่มของตัวแปรที่ flow อ่าน
หัวข้อนี้อธิบายแต่ละหน้าว่า **ถามอะไร เก็บลงตัวแปรอะไร และ flow เอาไปทำอะไร**

หมายเหตุเรื่องชื่อ: ในตัวเครื่องมือชื่อเลเยอร์ที่ใช้ทำ P&R boundary
เขียนว่า `prBoundray:drawing` (พิมพ์ผิดจาก Boundary) — ให้จำไว้เพราะต้องกำหนด
เป็น Icon Layer ให้ตรงชื่อพอดี

### 2.1 หน้า Run File

| ช่อง | ความหมาย |
|---|---|
| Data Directory | โฟลเดอร์ที่เก็บผลลัพธ์ของแต่ละรอบ (มี timestamp) |
| Use Custom Run Script | ใช้สคริปต์ TCL ของตัวเองแทนสคริปต์ที่ TDI สร้างให้ |

**สิ่งที่ flow เอาไปทำ**

- โฟลเดอร์ข้อมูลจะถูกคัดลอกไปที่ `/tmp/<user>_nitro_data` บนเครื่อง Linux
  (ยกเว้นโฟลเดอร์ `results/` ที่เก็บผลลัพธ์ที่ดึงกลับมา)
- ถ้าไม่เลือก Custom Run Script TDI จะสร้างสคริปต์ขับ Nitro จากค่าที่กรอก
  คุณจึงไม่ต้องเขียน TCL เอง — แต่ถ้าอยากควบคุมลำดับขั้นตอนเอง
  ให้เขียนสคริปต์แล้วชี้ที่นี่

**ตัวแปรที่เกี่ยวข้อง**

| ตัวแปร | อ่านที่ | ความหมาย |
|---|---|---|
| `ams_run_control` | `aprisa_ams.tcl:42` | `synpnr` / `syn` / `pnr` |

### 2.2 หน้า Tech and Lib

หน้านี้รวบรวมไฟล์สี่ชนิดที่ต้องให้กับ flow

| ชนิดไฟล์ | สกุล | ให้ข้อมูลอะไร |
|---|---|---|
| **LEF** | `.lef` | รูปทรงและ layout ของเซลล์ + ชั้นโลหะของเทคโนโลยี |
| **Liberty** | `.lib` | เวลา กำลัง และพื้นที่ของเซลล์ |
| **PTF** | `.ptf` | ความต้านทานและความจุของชั้นโลหะ (Nitro ใช้เท่านั้น) |
| **Corner** | — | มุมของกระบวนการ ได้สูงสุด 3: `fast` / `nominal` / `slow` |

**สิ่งที่ flow เอาไปทำ — และนี่คือจุดที่ทำให้สับสน**

หน้าเดียวกันนี้ถูกอ่านโดย **สองชุดสคริปต์ที่ใช้ชื่อตัวแปรต่างกัน**

| ผู้อ่าน | ตัวแปรที่อ่าน | ใช้ทำอะไร |
|---|---|---|
| `tanner_oasys.tcl` (synthesis) | `lef_file_list` | `read_lef` ทีละไฟล์ |
| `tanner_oasys.tcl` (synthesis) | `lib_file_list` | `read_library` ทีละไฟล์ |
| `tanner_oasys.tcl` (synthesis) | `ptf_file_list` + `tanner_ptf_file_corner_list` | `read_ptf` |
| `0_data_prep.tcl` (P&R) | `tech_file_list` | นำเข้าเทคโนโลยี |
| `0_data_prep.tcl` (P&R) | `cell_lef_file_list` | `import_lef -lib_cell_only` |
| `0_data_prep.tcl` (P&R) | `corner_list` | ลูปผ่านมุมของกระบวนการ |
| `0_data_prep.tcl` (P&R) | `rlc_file_list` | โมเดล RLC (เว้นว่างได้ถ้าใช้ PTF) |

> **บันทึกไว้เลย**
>
> ไฟล์ LEF เดียวกันถูกส่งเข้า flow **สองชื่อที่ต่างกัน**
> `lef_file_list` สำหรับขั้นสังเคราะห์ และ
> `tech_file_list` + `cell_lef_file_list` สำหรับขั้นวางเดินสาย
> ถ้าตั้งแต่ในหน้าต่างแล้วสองชุดนี้จะถูกเขียนให้อัตโนมัติ
> แต่ถ้าคุณเขียนไฟล์ตั้งค่าเอง (ดู lab 06) ต้องใส่ให้ครบทั้งสองชุด

**กฎสามข้อที่ต้องไม่ผิด**

1. **tech LEF ต้องมาก่อน standard cell LEF เสมอ**
   เพราะ tech LEF เป็นตัวกำหนดชั้นโลหะและ via ที่เซลล์ LEF อ้างถึง
   ผิดลำดับแล้ว LEF ที่สองจะอ่านไม่ผ่าน
2. **PTF อ่านเข้าได้แค่ไฟล์เดียว**
   ดู `tanner_oasys.tcl:33-50` — flow จะเลือกไฟล์ PTF ไฟล์เดียว
   ตามลำดับความสำคัญ `slow` → `nominal` → `fast`
   แล้วอ่านเฉพาะไฟล์นั้น (ถ้าตั้ง PTF ไว้สามไฟล์ ก็ยังถูกอ่านแค่ไฟล์เดียว)
3. **LEF กับ Liberty ต้องตรงกัน**
   ไม่ตรงกันแล้วจะพังตอนสังเคราะห์ และข้อความแจ้งเตือนมักไม่ชี้ว่าเป็นเรื่องนี้
   (lab 03 มีตัวอย่างจริงที่เจอในชุด Generic 250 nm)

### 2.3 หน้า Netlist/RTL

| ช่อง | ความหมาย |
|---|---|
| Run control | สังเคราะห์+วางเดินสายพร้อมกัน หรือแยกทีละขั้น |
| Netlist/RTL files for synthesis | ไฟล์ RTL ที่จะสังเคราะห์ |
| Top Cell | ชื่อโมดูลบนสุด |
| Power Net / Ground Net | ชื่อเน็ตของแหล่งจ่ายและกราวด์ |

**สิ่งที่ flow เอาไปทำ**

- `tanner_oasys.tcl` อ่านไฟล์ตามนามสกุลอัตโนมัติ:
  `.vhd`/`.vhdl` → `read_vhdl`, `.sv` → `read_verilog -sv`, อื่น ๆ → `read_verilog`
- ถ้ามีไฟล์ scan configuration ก็จะสังเคราะห์แบบ `-map_to_scan`
- ผลลัพธ์คือ `results/<top>_syn.v`

**ตัวแปรที่เกี่ยวข้อง**

| ตัวแปร | อ่านที่ | ความหมาย |
|---|---|---|
| `tanner_cell` | `tanner_oasys.tcl:96` | โมดูลเป้าหมายของการสังเคราะห์ |
| `top_cell` | `2_floorplan.tcl` | โมดูลเป้าหมายของการวางเดินสาย |
| `verilog_file_list` | `tanner_oasys.tcl:65` | รายการไฟล์ RTL |
| `is_list_file` / `list_file` | `tanner_oasys.tcl:57` | โหมดอ่านไฟล์จาก list file |
| `is_Verilog` | `tanner_oasys.tcl:59` | list file นั้นเป็น Verilog หรือ VHDL |
| `use_list_file` | `0_data_prep.tcl:113` | สลับโหมด list file ของขั้น data prep |
| `enable_scan` | `1_rtl_synthesis.tcl:50` | เปิดการทำ scan หรือไม่ |
| `syn_netlist` | ขั้น export | ที่เก็บ netlist ระดับ gate |

> **Top Cell ต้องตรงกับชื่อใน DEF**
>
> ในตัวอย่าง ADC8 ทั้ง RTL (`module ADCCtrl`) และ DEF (`DESIGN ADCCtrl;`)
> ต้องเป็นชื่อเดียวกัน lab 01 ตรวจเรื่องนี้โดยตรง

### 2.4 หน้า Timing

หน้านี้มีสองทางเลือก และความต่างระหว่างมัน **สำคัญมาก**

| ทางเลือก | ข้อมูลที่มี | เหมาะกับ |
|---|---|---|
| **Define clocks** | มีแค่นามคล็อกและคาบเวลา ไม่มี delay, load, fanout | ลองเล่น สำรวจ flow |
| **SDC file** | ข้อจำกัดเวลา กำลัง และพื้นที่ครบ | งานที่จะส่งผลิต |

**สิ่งที่ flow เอาไปทำ — อ่านจากโค้ดจริง**

โหมด `clocks` (`tanner_oasys.tcl:104-116`):

```tcl
create_clock -name $clk -period $period -waveform $waveform [get_ports $clk]
set_input_delay  -clock $clk 1 [all_inputs]
set_output_delay -clock $clk 1 [all_outputs]
```

สังเกตว่า delay ที่ใส่ให้คือ **ค่า 1 หน่วยเวลา** ไม่ใช่งบประมาณจริง
คือการบอก flow ว่า "ตัวเลขนี้เอาไปคิด" ไม่ใช่ความต้องการจริงของดีไซน์

โหมด `sdc` (`tanner_oasys.tcl:117-125`):

```tcl
foreach mode $MGC_modes {
    set_timing_mode $mode
    foreach sdc_file $oasys_importConstraintsFile($mode) {
        read_sdc $sdc_file -mode $mode
    }
}
```

โหมดนี้อ่าน SDC ได้หลายไฟล์ต่อหนึ่ง mode จึงรองรับการตั้งหลายมุมได้

> **สำหรับงานจริง ให้ใช้หน้า SDC เสมอ**
>
> ตัวอย่างที่แนบมามี SDC แบบครบแล้วที่
> `design/files/timing_constraints_full.sdc`
> และ lab 04 จะเปรียบเทียบกับแบบที่มากับตัวอย่างให้

**ตัวแปรที่เกี่ยวข้อง**

| ตัวแปร | อ่านที่ | ความหมาย |
|---|---|---|
| `tanner_timing_mode` | `tanner_oasys.tcl:104` | `clocks` หรือ `sdc` |
| `tanner_clock_spec` | `tanner_oasys.tcl:105` | รายการคล็อก ในโหมด clocks |
| `MGC_modes` | `tanner_oasys.tcl:118` | รายการ mode วิเคราะห์ ในโหมด sdc |
| `oasys_importConstraintsFile` | `tanner_oasys.tcl:120` | ไฟล์ SDC ของแต่ละ mode |

### 2.5 หน้า Floorplan

TDI ให้เลือก floorplan ได้สามวิธี

| วิธี | ตัวแปร | ลักษณะ |
|---|---|---|
| Specify Block Details | `floorplan_mode` = `block` | กำหนด Die Area และ Row Margins ด้วยตัวเลข |
| Export from layout | `floorplan_mode` = `layout` | ดึง boundary และตำแหน่งพอร์ตจากเลย์เอาต์ใน L-Edit |
| Use Def floorplan file | `floorplan_mode` = `def` | อ่านจากไฟล์ DEF |

**สิ่งที่ flow เอาไปทำ**

- `2_floorplan.tcl` เลือกวิธีตาม `floorplan_mode` แล้วสร้างรายการ layer ที่จะวาง
- ถ้าเป็นโหมด `layout` หรือ `def` flow จะ **วางพอร์ตให้ตรงตำแหน่งที่กำหนดไว้**
  ซึ่งเป็นสิ่งที่ต้องการเมื่อนำบล็อกดิจิทัลไปต่อกับส่วนอนาล็อก

**ตัวแปรที่เกี่ยวข้อง**

| ตัวแปร | อ่านที่ | ความหมาย |
|---|---|---|
| `floorplan_mode` | `2_floorplan.tcl` | `block` / `layout` / `def` |
| `def_floorplan_file` | `2_floorplan.tcl` | ไฟล์ DEF ในโหมด `def` |
| `chip_width` / `chip_height` | `2_floorplan.tcl` | ขนาด die ในหน่วย DBU |
| `chip_origin_x` / `chip_origin_y` | `2_floorplan.tcl` | จุดเริ่มของ die |
| `core_site` | `2_floorplan.tcl` | ชื่อ site ของแถวเซลล์มาตรฐาน |
| `core_yb_spacing` / `core_xl_spacing` / `core_yt_spacing` / `core_xr_spacing` | `compute_floorplan_details.tcl:87` | **ระยะจาก power ring ถึงแถวเซลล์แรก** |
| `highest_routing_layer` | `2_floorplan.tcl` | ชั้นโลหะสูงสุดที่อนุญาตให้เดินสาย |
| `fp_utilization` | `2_floorplan.tcl` | เป้าหมายความหนาแน่น |
| `fp_aspect_ratio` | `2_floorplan.tcl` | อัตราส่วนกว้าง:ยาวของบล็อก |

> **Row Margins ไม่ใช่ระยะจากขอบ die**
>
> ค่าที่ TDI เรียกว่า Row Margins ถูกส่งไปเป็น `core_*_spacing`
> ซึ่งคือ **ระยะจากขอบของ power ring ถึงแถวเซลล์แรก**
> ส่วนระยะจากขอบ die จริง ๆ จะถูกคำนวณโดย flow เอง:
>
> ```tcl
> set core_to_bottom [expr $ring_offset_bottom + $core_yb_spacing]
> ```
>
> โดย `ring_offset_*` มาจากความกว้างของ ring ที่คำนวณจากแผน power
> (ดูหัวข้อ 2.6)

### 2.6 หน้า Power Plan

หน้านี้ตั้งค่าแหวนและแถบจ่ายไฟ

**สิ่งที่ flow เอาไปทำ — อ่านจาก `3_powerplan.tcl`**

| ตัวแปร | ความหมาย |
|---|---|
| `power_nets` | รายชื่อแหล่งจ่าย **อันแรกคือแหล่งจ่ายหลัก** |
| `ground_nets` | รายชื่อกราวด์ **อันแรกคือกราวด์หลัก** |
| `enable_pg_ring` | เปิด/ปิดแหวนจ่ายไฟ |
| `enable_pg_stripe` | เปิด/ปิดแถบจ่ายไฟ |
| `pg_ring_vlayer` / `pg_ring_hlayer` | ชั้นโลหะของเส้นแนวตั้ง / แนวนอน |
| `pg_ring_net_order` | **ลำดับวงแหวนจากนอกเข้าใน** |
| `pg_ring_widths` | ความกว้างของแต่ละวง |
| `pg_ring_spacing` | ระยะห่างระหว่างวง |
| `pg_ring_offset_top/right/bottom/left` | ระยะเพิ่มจาก ring ถึงขอบ die |
| `pg_stripe_list` / `num_of_stripes` | รายการแถบจ่ายไฟ |

**กฎสองข้อที่ flow บังคับ** (จาก `compute_floorplan_details.tcl:36-45`)

```tcl
# จำนวน spacing ต้องเป็น 1 หรือ (จำนวนแหล่งจ่าย - 1)
if {$size_of_ring_spacing != "1" && ($size_of_ring_spacing != [expr $nb_of_supplies -1])} {
    puts "FLOW-ERROR : Nb of ring spacing values does not match number of intervals between supplies"
}
# จำนวน width ต้องเป็น 1 หรือ จำนวนแหล่งจ่าย
if {$size_of_ring_width != "1" && ($size_of_ring_width != $nb_of_supplies)} {
    puts "FLOW-ERROR : Nb of ring width values does not match number of supplies"
}
```

> **ตัวอย่างที่พลาดง่าย**
>
> มีแหล่งจ่าย 2 ตัว (Vdd, Gnd) และใส่ spacing ไป 2 ค่า
> ค่าที่สองไม่จำเป็นต้องมี เพราะมีแค่ช่องว่างระหว่างวงเพียงช่องเดียว
> ถ้าใส่เกิน flow จะหยุดพร้อมข้อความ `FLOW-ERROR`
> lab 06 ตรวจกฎนี้ด้วย

**ข้อจำกัดที่ flow ตรวจเองอีกข้อ** (จาก `3_powerplan.tcl`)

spacing ของ ring ต้องไม่น้อยกว่า min spacing ของชั้นโลหะที่ใช้
ไม่อย่างนั้น flow จะพิมพ์

```text
FLOW-ERROR : PG ring spacing constraint is smaller than Metal4 or Metal3
min_spacing DRC constraint. Please revisit your constraint...
```

**ตัวอย่างจริงจากชุด Generic 250 nm**

| ค่า | ตัวเลข |
|---|---|
| แหล่งจ่าย | Vdd (นอกสุด), Gnd (ข้างใน) |
| เส้นแนวตั้ง / แนวนอน | Metal4 / Metal3 |
| ความกว้าง | 2.0 µm (Vdd), 1.5 µm (Gnd) |
| spacing | 0.6 µm (ค่าเดียว) |
| min spacing ของ Metal4 / Metal3 | 0.5 µm |

และเมื่อคำนวณด้วยสูตรของ flow จะได้

| ปริมาณ | ค่า | สูตร |
|---|---|---|
| ความกว้าง ring รวม | 4.1 µm | ผลรวม width (3.5) + spacing (0.6) |
| `width_contrib` | 3.5 µm | width ของ Vdd + width ของ Gnd |
| `spacing_contrib` | 1.2 µm | 2 × spacing |
| `macro_ring_spacing` | 16.2 µm | 2 × ความสูง site (8.10 µm) |
| `oversize_m2m` | 41.8 µm | 2 × (width_contrib + spacing_contrib + macro_ring_spacing) |
| `oversize_b2m` | 45.9 µm | max(offset ทั้งสี่ด้าน) + oversize_m2m |

### 2.7 หน้า Additional Commands

ช่องแก้ไขในหน้านี้คือ **ตัวแปรที่เขียนทับค่าเริ่มต้นของ flow**

ค่าที่ตั้งไว้ในนี้จะถูกเขียนลงไฟล์ `additional_commands.tcl`
แล้วถูก `source` เข้าไปใน flow ตามโค้ดใน `aprisa_ams.tcl`:

```tcl
# Source Customization
if {[file exists additional_commands.tcl]} {
    puts "\nFLOW-INFO: Loading Aprisa customization"
    source additional_commands.tcl
}
```

**ตัวแปรที่ควรรู้** (จาก `flow_variables.tcl`)

| ตัวแปร | ค่าเริ่มต้น | ผลของการเปลี่ยน |
|---|---|---|
| `rtl_max_util` | 85 | เปอร์เซ็นต์ความหนาแน่นสูงสุดของ netlist ที่สังเคราะห์ |
| `enable_clock_gating` | 0 | เปิดการใส่ clock gating ให้อัตโนมัติ |
| `DFT_flow` | `native` | วิธีทำ scan (`native` / `tessent`) |
| `force_io_placement` | 1 | บังคับให้วางพอร์ตตามตำแหน่งที่กำหนด |
| `delete_unconnected_phys_pins` | 0 | ลบรูปพอร์ตที่ไม่ได้ต่อ |
| `well_tap_cell` | *(ว่าง)* | เซลล์ well tap |
| `physical_effort` | `low` | ความพยายามของ physical synthesis |
| `tie_high_libcell` / `tie_low_libcell` | *(ว่าง)* | เซลล์สำหรับ tie logic |
| `delay_cells` | *(ว่าง)* | เซลล์ delay |
| `filler_libcells` | *(ว่าง)* | เซลล์ filler |
| `decap_libcells` | *(ว่าง)* | เซลล์ decap |
| `antenna_diodes` | *(ว่าง)* | เซลล์ antenna diode |
| `route_optimize_effort` | `low` | ความพยายามของ router |
| `repair_after_filler` | 1 | ซ่อม DRC หลังใส่ filler |
| `exit_on_flow_error` | 0 | หยุดทันทีเมื่อเจอ error |

> **ข้อควรระวัง**
>
> การตั้งค่า `tie_high_libcell` หรือ `tie_low_libcell` ต้องดูว่าเซลล์นั้น
> **มี LEF ด้วย** ไม่ใช่มีแค่ใน Liberty
> ในชุด Generic 250 nm ที่แนบมา `TIELOW` และ `TIEHIGH`
> มีอยู่ใน Liberty แต่ **ไม่มีใน LEF** (lab 03)
> ถ้าตั้งค่านี้แล้ว flow จะพังตอนใส่ tie cell

---


## บทที่ 3 — Lab 01 ถึง Lab 03: อินพุตของ flow

สาม lab แรกตรวจ **อินพุต** ทั้งหมดที่ต้องไปถึง Nitro
ทุก lab รันได้บน Windows ล้วน ๆ ไม่ต้องใช้ Nitro

---

### Lab 01 — RTL กับพอร์ตใน DEF ต้องตรงกัน

**เป้าหมาย**

พิสูจน์ว่า interface ของบล็อกที่ L-Edit export ออกมาเป็น DEF
ตรงกับ RTL ที่จะส่งเข้า synthesis ทุกประการ

**ทำไมต้องตรวจ**

TDI ไม่เห็นพอร์ตของ RTL โดยตรง สิ่งที่ Nitro เห็นคือ **DEF**
ถ้าสองอย่างไม่ตรงกัน flow จะพังตอนวางเซลล์หรือตอนต่อสายสัญญาณ
และข้อความแจ้งเตือนมักไม่ได้บอกว่าต้นเหตุคือ interface ไม่ตรงกัน

**วิธีรัน**

```bat
cd tdi_lab\lab01_rtl_ports
run.cmd
```

**ผลที่คาดหวัง**

```text
========================================================================
  LAB 01 : RTL ports vs DEF pins  (ADC8 / ADCCtrl)
========================================================================
  [INFO] rtl file        : ADCCtrl_rtl.v
  [INFO] def file        : from_ledit.def
  [INFO] rtl module      : ADCCtrl
  [INFO] rtl header ports: 8 (before bus expansion)
  [INFO] def pins        : 15
  [INFO] def nets        : 15
  [PASS] RTL declares the 8 bit output bus B
         B[0:7] -> width 8, direction output
  [PASS] the expanded RTL port list and the DEF pin list are the same set
         rtl = 15 ports, def = 15 pins
  [PASS] every DEF pin carries a DIRECTION attribute
         all 15 pins carry a direction
  [PASS] every DEF pin has the same direction as the RTL port
         all 15 pins agree (INPUT/OUTPUT)
  [PASS] every pin is backed by a NET entry
         15 pin nets / 15 net entries
  [PASS] the DEF top cell name matches the RTL module name
         DEF DESIGN = ADCCtrl, RTL module = ADCCtrl
  [NOTE] port mix: 4 input / 11 output
  [NOTE] the 8 bit bus B[7:0] is 8 of the 15 physical pins
------------------------------------------------------------------------
  6/6 checks passed
  RESULT: PASS
========================================================================
```

**สิ่งที่ผลนี้บอกเรา**

- RTL เขียนพอร์ตไว้ 8 ชื่อ แต่ `B` เป็นบัส 8 บิต
  เมื่อกระจายออกเป็นรายบิตจะได้ **15 พอร์ต** ตรงกับ DEF พอดี
- สัดส่วนทิศทาง: input 4 (clr, clk, Compare, Start) output 11
  (LoadReg, DataMark, SerialOutput และ B[0]..B[7])
- ชื่อโมดูลต้องตรงกับ `DESIGN` ใน DEF

> **บันทึกที่ได้จากการอ่านไฟล์จริง**
>
> ในโค้ด RTL พอร์ตถูกประกาศแยกเป็นชุด:
>
> ```verilog
> module ADCCtrl (clr,clk,Compare,Start,DataMark,B,LoadReg,SerialOutput);
> input clr,clk,Compare,Start;
> output LoadReg,DataMark,SerialOutput;
> output [7:0] B;
> ```
>
> โปรดสังเกตว่า **บัส `B` ไม่ได้อยู่ในรายการ input**
> ถ้าคุณมองผิดวิธี อาจนับพอร์ตได้ 15 แต่สรุปผิดว่าเป็นบัสอินพุต

**ถ้าไม่ผ่าน**

| อาการ | สาเหตุที่เป็นไปได้ |
|---|---|
| `only in RTL` มีชื่อ | เพิ่มพอร์ตในเลย์เอาต์แล้ว export DEF ใหม่ |
| `only in DEF` มีชื่อ | ยังไม่ได้ export ใหม่ หรือ export ผิดเซลล์ |
| `direction` ไม่ตรง | ทิศทางพอร์ตใน layout ไม่ตรงกับ RTL — ตรวจที่เลย์เอาต์ |
| `DEF DESIGN` ไม่ตรง | สลับเซลล์ผิดตอน export |

---

### Lab 02 — Boundary และตำแหน่งพอร์ต

**เป้าหมาย**

พิสูจน์ว่า P&R boundary ที่ export มาเป็นรูปทรงที่ Nitro ใช้วางได้จริง
และทุกพอร์ตอยู่ในขอบเขตบนชั้นที่เดินสายได้

**วิธีรัน**

```bat
cd tdi_lab\lab02_def_boundary
run.cmd
```

**ผลที่คาดหวัง**

```text
========================================================================
  LAB 02 : P&R boundary and pin geometry  (from_ledit.def)
========================================================================
  [INFO] def file        : from_ledit.def
  [PASS] the DEF declares its distance unit
         UNITS DISTANCE MICRONS 1000  (1 um = 1000 DBU)
  [PASS] the DEF contains a DIEAREA
         DIEAREA (0 0) (177800 53000) DBU
  [PASS] the block has a non degenerate size
         die area = 177.800 um x 53.000 um
  [PASS] the DEF carries a full pin list
         15 pins
  [PASS] every pin has a FIXED location
         all pins are fixed
  [PASS] every pin lies inside the die area
         all 15 pins are inside the boundary
  [PASS] all pins are on one routable layer
         pin layer = Metal4
  [PASS] no two pins share the same location
         15 unique locations
  [PASS] the pins sit on the boundary edges, not in the middle of the block
         bottom=6, top=9
  [NOTE] bottom edge pins are 0.050 um above the die edge, top edge pins are 0.300 um below the die edge
  [PASS] neighbouring pins on an edge are spaced apart
         minimum pitch = 15.200 um on the top edge
  [PASS] the DEF contains no placed components yet
         COMPONENTS 0 -- this is the empty block that Nitro will fill
------------------------------------------------------------------------
  11/11 checks passed
  RESULT: PASS
========================================================================
```

**สิ่งที่ผลนี้บอกเรา**

- บล็อกนี้กว้าง **177.800 µm** สูง **53.000 µm**
  (ไฟล์ DEF ใช้หน่วย 1000 DBU = 1 µm)
- พอร์ตทั้ง 15 ตัวอยู่บน **Metal4** ชั้นเดียวกันทั้งหมด
  โดยขอบล่างมี 6 พอร์ต ขอบบนมี 9 พอร์ต
- ระยะห่างต่ำสุดระหว่างพอร์ตที่อยู่ติดกันคือ **15.200 µm** บนขอบบน
- `COMPONENTS 0` แปลว่านี่คือบล็อกว่างที่ Nitro จะเติมเซลล์เข้าไป

**เรื่องที่ควรสังเกต**

> **ตัวเลขในคู่มือกับไฟล์จริงไม่ตรงกัน**
>
> คู่มือของผลิตภัณฑ์บอกว่า boundary ของ ADCCtrl อยู่ที่
> (0,0) ถึง (177.8, 49.0) µm
> แต่ไฟล์ DEF ที่มาพร้อม Custom IC 2025.4 ระบุว่า
> **177.800 × 53.000 µm**
>
> เหตุผลที่เป็นไปได้คือเลย์เอาต์ถูกแก้ไขหลังคู่มือเขียนเสร็จ
> **ข้อสรุปที่ใช้ได้: อย่าเชื่อตัวเลขในคู่มือ ต้องวัดจากเลย์เอาต์ของตัวเอง**
> คู่มือนี้ยึดหลักเดียวกันทุกครั้ง — ทุกตัวเลขมาจากการรันจริง

**ถ้าไม่ผ่าน**

| อาการ | สาเหตุที่เป็นไปได้ |
|---|---|
| ไม่มี `DIEAREA` | ยังไม่ได้วาด boundary ในเลย์เอาต์ |
| พอร์ตอยู่นอกขอบเขต | วาด boundary ไม่ครอบพอร์ต |
| พอร์ตบนชั้นที่ไม่ใช่โลหะ | เลือกชั้นโลหะให้พอร์ต |
| `COMPONENTS` ไม่ใช่ 0 | export จากเซลล์ที่วางเซลล์ไว้แล้ว |

---

### Lab 03 — เทคโนโลยีและชุดเซลล์มาตรฐาน

**เป้าหมาย**

ตรวจว่าไฟล์ LEF, Liberty และ PTF ที่จะส่งเข้า flow
สอดคล้องกันและครบถ้วนพอที่จะเริ่มงานได้

**วิธีรัน**

```bat
cd tdi_lab\lab03_tech_libs
run.cmd
```

**ผลที่คาดหวัง**

```text
========================================================================
  LAB 03 : technology and standard cell libraries  (Generic 250 nm)
========================================================================
  [PASS] the tech LEF declares its database unit
         DATABASE MICRONS 1000  (1 um = 1000 DBU)
  [PASS] the tech LEF defines exactly the four routing layers Metal1..Metal4
         routing layers: Metal1, Metal2, Metal3, Metal4 | cut layers: Via1, Via2, Via3
  [PASS] the standard cell LEF contains MACRO definitions
         22 macros
  [PASS] the standard cell LEF uses the same database unit as the tech LEF
         tech LEF = 1000, cell LEF = 1000
  [PASS] the standard cell LEF defines the standard cell row site
         SITE CORE, SIZE 1.15 BY 8.1 um
  [PASS] the nominal Liberty parses and names its library
         library "Generic250nm_TT_2P50V_25C", 22 cells, 2.5 V, 25 C
  [PASS] the three Liberty files map to the three TDI corners
         Generic250nm_FF_2P75V_M40C.lib -> fast; Generic250nm_TT_2P50V_25C.lib -> nominal; Generic250nm_SS_2P25V_125C.lib -> slow
  [PASS] every Liberty cell that is not a tie or filler cell also exists in the LEF
         timing-only cells (tie cells): TIELOW, TIEHIGH
  [PASS] every LEF macro that is not a tie, a filler or a scan variant also exists in the Liberty
         physical-only macros: FILLER, DFFPC
  [PASS] the LEF and the Liberty describe the same number of cells
         22 macros in the LEF, 22 cells in the Liberty
  [NOTE] LEF macros without a Liberty model: FILLER, DFFPC  -- a filler cell needs no timing model; a scan flavoured macro needs one of its own
  [NOTE] Liberty cells without a LEF macro: TIELOW, TIEHIGH  -- a tie cell cannot be tied if it has no physical macro
  [PASS] the PTF parses and names its process technology
         process_technology "Generic250_MET4_typ", capacitance unit ff, resistance unit ohm
  [PASS] the PTF covers every routing layer of the technology
         PTF covers Metal4, Metal3, Metal2, Metal1
  [NOTE] files and sizes:
  [INFO]   Generic250nm_tech.lef  (6900 bytes)
  [INFO]   Generic250nm_StdCells.lef  (62591 bytes)
  [INFO]   Generic250nm_TT_2P50V_25C.lib  (377228 bytes)
  [INFO]   Generic250nm_typ.ptf  (159458 bytes)
  [INFO]   Generic250nm_FF_2P75V_M40C.lib  (330089 bytes)
  [INFO]   Generic250nm_SS_2P25V_125C.lib  (330351 bytes)
------------------------------------------------------------------------
  12/12 checks passed
  RESULT: PASS
========================================================================
```

**สิ่งที่ผลนี้บอกเรา**

1. เทคโนโลยีมีชั้นโลหะ 4 ชั้น (Metal1..Metal4) และ via 3 ชั้น
2. แถวเซลล์มาตรฐานคือ **SITE CORE** ขนาด 1.15 × 8.10 µm
   ค่า 8.10 µm นี้ถูกใช้ต่อไปในการคำนวณ power ring (หัวข้อ 2.6)
3. Liberty ทั้งสามไฟล์แยกกันเป็นมุม fast / nominal / slow ได้ถูกต้อง

**ข้อค้นพบที่สำคัญ — LEF กับ Liberty ไม่ได้ตรงกันทุกตัว**

ทั้งสองไฟล์มี 22 เซลล์ เท่ากัน แต่ไม่ใช่ชุดเดียวกัน

| เซลล์ | มีใน LEF | มีใน Liberty | ผลของมัน |
|---|---|---|---|
| `FILLER` | ✔ | ✘ | ปกติ — filler ไม่ต้องมี timing model |
| `DFFPC` | ✔ | ✘ | **ต้องระวัง** — เป็น scan flop ที่ไม่มี timing model |
| `TIELOW` | ✘ | ✔ | **ต้องระวัง** — tie cell ที่ไม่มีรูปใน LEF |
| `TIEHIGH` | ✘ | ✔ | **ต้องระวัง** — tie cell ที่ไม่มีรูปใน LEF |

> **ทำไมต้องสนใจ**
>
> 1. ถ้าตั้ง `tie_high_libcell` หรือ `tie_low_libcell` เป็น `TIELOW`/`TIEHIGH`
>    ในหน้า Additional Commands flow จะหาเซลล์นี้ใน LEF ไม่เจอ
>    แล้วพังตอนใส่ tie cell
> 2. ถ้า scan flow map ไปที่ `DFFPC` จะไม่มี timing model ให้วิเคราะห์เวลา
>    เซลล์ scan ต้องมี Liberty ของตัวเองเสมอ
>
> ทั้งสองกรณีเป็นข้อผิดพลาดระดับชุดไฟล์ที่มาพร้อมผลิตภัณฑ์
> **การตรวจแบบนี้ก่อนรันช่วยเวลาได้มากกว่าการรอให้ flow พัง**

---


## บทที่ 4 — Lab 04 ถึง Lab 06: เงื่อนไขเวลา scan และสัญญาของไฟล์ตั้งค่า

---

### Lab 04 — เงื่อนไขเวลา และสองโหมดของหน้า Timing

**เป้าหมาย**

ตรวจว่าไฟล์ SDC ที่จะใช้อ้างถึงพอร์ตที่มีอยู่จริง
และเข้าใจว่า flow ทำอะไรกับข้อมูลในแต่ละโหมดของหน้า Timing

**ไฟล์ที่เกี่ยวข้อง**

| ไฟล์ | ที่มา |
|---|---|
| `design/files/timing_constraints.sdc` | มาพร้อมตัวอย่าง ADC8 — มีบรรทัดเดียว |
| `design/files/timing_constraints_full.sdc` | ฉบับครบที่คู่มือนี้เขียนเพิ่มให้ |

**วิธีรัน**

```bat
cd tdi_lab\lab04_timing
run.cmd
```

**ผลที่คาดหวัง**

```text
========================================================================
  LAB 04 : timing constraints  (SDC and the two TDI modes)
========================================================================
  [INFO] sdc file        : timing_constraints.sdc
  [INFO] def file        : from_ledit.def
  [PASS] the shipped SDC defines exactly one clock
         1 clock(s): clk
  [PASS] the clock period is positive and the waveform is a valid duty cycle
         period = 10000 ns (10.000 us), waveform = {0 5000} -> duty 50.0%
  [PASS] the port the clock is attached to exists in the layout
         get_ports clk -> found in the DEF pin list
  [PASS] the port the clock is attached to exists in the RTL
         get_ports clk -> found in the RTL port list
  [INFO] rtl timescale   : 100ns per 1ps  (1 time unit = 100 ns)
  [PASS] the SDC clock period is a whole number of RTL clock cycles
         10000 ns / 100 ns = 100 clock cycles
  [PASS] the complete SDC defines the same clock as the shipped one
         clk on clk, period 10000 ns
  [PASS] the complete SDC states the input and the output delays
         set_input_delay present, set_output_delay present
  [NOTE] the shipped SDC has no interface delays: the clock alone does not constrain the inputs or the outputs
  [PASS] every port that the complete SDC constrains exists in the layout
         7 constrained port references, all present
  [INFO] install         : C:\Siemens\Custom IC\Custom IC 2025.4\x64
  [PASS] the installed synthesis script offers both timing modes
         tanner_timing_mode = "clocks" | "sdc"
  [PASS] the "Define clocks" mode applies a fixed input and output delay
         set_input_delay 1 / set_output_delay 1 -- a placeholder, not a real budget
  [PASS] the "sdc" mode reads one SDC file per analysis mode
         read_sdc $sdc_file -mode $mode, for every mode in MGC_modes
  [NOTE] "Define clocks" is a shortcut for exploration. For a tape out run, use the SDC page so that the delays, loads and false paths are real.
------------------------------------------------------------------------
  11/11 checks passed
  RESULT: PASS
========================================================================
```

**สิ่งที่ผลนี้บอกเรา**

1. คล็อกมีคาบเวลา 10000 ns = 10 µs duty cycle 50%
2. พอร์ต `clk` ที่ SDC อ้างถึงมีอยู่จริง ทั้งใน DEF และใน RTL
3. RTL ประกาศ `` `timescale 100ns/1ps ``
   แปลว่า 1 time unit = 100 ns และคาบเวลาคล็อกคือ **100 รอบของเวลา**
4. SDC ที่มาพร้อมตัวอย่าง **ไม่มี** input/output delay
   คือมีแต่คล็อก ส่วนอินพุตและเอาต์พุตยังไม่ถูกจำกัดเวลาเลย
5. โหมด Define clocks ของ TDI ใส่ delay ให้เท่ากับ **1 หน่วยเวลา**
   ซึ่งเป็นค่าแทน ไม่ใช่งบประมาณจริง

**ไฟล์ SDC ฉบับครบที่คู่มือนี้เพิ่มให้**

```tcl
create_clock -name clk -period 10000 -waveform {0 5000} [get_ports clk]

set_input_delay  -clock clk 2500 [get_ports {clr Compare Start}]
set_output_delay -clock clk 2500 [get_ports {LoadReg DataMark SerialOutput B[*]}]

# the asynchronous clear is not timed against the clock
set_false_path -from [get_ports clr]
```

> **ข้อควรระวังเรื่องหน่วย**
>
> คาบเวลาใน SDC คือ **นาโนวินาที** ไม่ว่าหน่วยเวลาของ RTL
> `10000` ในไฟล์นี้จึงเท่ากับ 10 µs
> ไม่ใช่ 10000 รอบเวลาของ RTL ซึ่งใช้ 100 ns ต่อหน่วย
> lab นี้ตรวจให้ว่าค่าที่ใส่เป็นจำนวนรอบเวลาของ RTL พอดี (100 รอบ)
> เพื่อจับกรณีที่หน่วยไม่ตรงกัน

---

### Lab 05 — การตั้งค่า scan

**เป้าหมาย**

อ่านและตรวจสคริปต์ตั้งค่า scan chain ของตัวอย่าง
และเข้าใจผลกระทบของมันที่มีต่อฝั่งเลย์เอาต์

**วิธีรัน**

```bat
cd tdi_lab\lab05_scan
run.cmd
```

**ผลที่คาดหวัง**

```text
========================================================================
  LAB 05 : scan configuration  (scanchain.tcl)
========================================================================
  [INFO] scan file       : scanchain.tcl
  [INFO] twochains flag  : false (the "if" branch is not taken)
  [PASS] the script configures exactly one scan chain
         1 active chain(s)
  [PASS] the chain names its scan in, scan out and scan enable
         scan_in = Scan_In, scan_out = Scan_Out, scan_enable = Scan_Enable
  [PASS] the chain asks the tool to create the ports it needs
         -create_port is set, so Scan_In, Scan_Out and Scan_Enable will be added to the design
  [PASS] the scan enable pin is created as a port
         define_test_pin -pin Scan_Enable -scan 1 -create_port
  [PASS] a test clock is defined on the functional clock
         define_test_clock -name clk -pin clk
  [PASS] the DEF does not contain a scan port that the configuration does not create
         the DEF has no stray scan port
  [INFO] the scan configuration creates 3 ports (Scan_In, Scan_Out, Scan_Enable)
  [INFO] the exported DEF contains 0 of them
  [NOTE] the DEF was exported before the scan flow was enabled. Add Scan_In, Scan_Out, Scan_Enable to the layout and export the DEF again before running TDI with the scan configuration turned on.
  [PASS] the synthesis script switches to scan mapping when a scan file is given
         synthesize -module $tanner_cell -map_to_scan
  [PASS] the synthesis script writes a scan DEF into the results folder
         write_scandef results/${tanner_cell}_scan.def
  [PASS] the synthesis script connects and reports the scan chains
         check_dft -> connect_scan_chains -> report_scan_chains -detail
------------------------------------------------------------------------
  9/9 checks passed
  RESULT: PASS
========================================================================
```

**สิ่งที่ผลนี้บอกเรา — และเป็นประเด็นสำคัญของบทนี้**

สคริปต์ scan ของตัวอย่างเขียนแบบนี้

```tcl
# false: create one scan chain, true: create two scan chains
set twochains false

define_test_clock -name clk -pin clk
define_test_pin  -pin Scan_Enable -scan 1 -create_port
define_test_pin  -pin clr -scan_mode 1

if {$twochains} then {
    for {set i 1} {$i <= 2} {incr i} {
        define_scan_chain -name C$i -scan_in SI_$i -scan_out SO_$i \
            -scan_enable Scan_Enable -create_port -max_length 8
    }
} else {
    define_scan_chain -scan_in Scan_In -scan_out Scan_Out \
        -scan_enable Scan_Enable -create_port
}
```

lab นี้จะ **ตีความสคริปต์ตามค่าของตัวแปรจริง** ไม่ใช่นับบรรทัด
เพราะฉบับนี้มีการกำหนด chain ไว้สองชุดในไฟล์เดียว
เมื่อ `twochains` เป็น `false` สคริปต์ที่ทำงานจริงคือสาขา `else`
ซึ่งเป็น chain เดียว

**ผลกระทบต่อฝั่งเลย์เอาต์**

การทำ scan สร้างพอร์ตใหม่ 3 ตัว — `Scan_In`, `Scan_Out`, `Scan_Enable`
แต่ DEF ที่มาพร้อมตัวอย่าง **ไม่มีพอร์ตเหล่านี้**

> **ขั้นตอนที่ต้องทำก่อนรัน TDI ด้วย scan**
>
> 1. เปิดการทำ scan ในหน้า Netlist/RTL หรือชี้ `tanner_scan_configuration_file`
> 2. **เพิ่มพอร์ต Scan_In, Scan_Out, Scan_Enable ลงในเลย์เอาต์ของ ADCCtrl**
> 3. export DEF ใหม่
> 4. ค่อยกด Run
>
> ถ้าข้ามขั้นตอน 2-3 flow จะเจอ DEF ที่ไม่มีพอร์ตเหล่านี้
> และจะล้มที่ขั้นการเชื่อมต่อพอร์ต

**เรื่องที่ต้องระวังอีกเรื่อง**

จาก lab 03 เรารู้ว่า `DFFPC` มีใน LEF แต่ไม่มีใน Liberty
ถ้า scan flow ของคุณ map ไปที่เซลล์ตัวนี้ จะไม่มี timing model
ให้วิเคราะห์เวลาของเซลล์ scan

---

### Lab 06 — สัญญาระหว่างหน้า Setup TDI กับ flow

**เป้าหมาย**

นี่คือ lab ที่สำคัญที่สุดของคู่มือนี้
เพราะมันเผยให้เห็นว่า **ค่าที่กรอกในหน้าต่างไปอยู่ที่ไหนใน flow จริง**

**เป้าหมายรอง**

1. พิสูจน์ว่าตัวแปรทุกตัวในสัญญาถูกอ่านโดยสคริปต์ที่ติดตั้งอยู่จริง
   พร้อมแสดง **ไฟล์และบรรทัด** ที่อ่าน
2. ตรวจว่าไฟล์ตั้งค่าตัวอย่างกำหนดตัวแปรครบ
3. ตรวจค่าของแผน power ตามกฎที่ flow ใช้จริง รวมถึงคำนวณ
   geometric ที่ flow จะคำนวณ

**วิธีรัน**

```bat
cd tdi_lab\lab06_settings
run.cmd
```

**ผลที่คาดหวัง**

```text
========================================================================
  LAB 06 : the TDI settings contract  (nitro_settings.tcl)
========================================================================
  [INFO] install         : C:\Siemens\Custom IC\Custom IC 2025.4\x64
  [INFO] timing mode     : sdc
  [PASS] every variable of the contract is read by a script that is installed
         51 contract variables, all found in the installed flow
  [PASS] the settings file defines every variable the contract
         all contract variables are defined (51 names in the file)
  [PASS] the technology LEF is the first entry of the LEF list
         order: files/Generic250nm_tech.lef -> files/Generic250nm_StdCells.lef
  [PASS] every file the settings file refers to is present
         8 referenced files, all present
  [PASS] the top cell in the settings file matches the top cell of the DEF
         settings tanner_cell = ADCCtrl, DEF DESIGN = ADCCtrl
  [PASS] the number of ring widths matches the number of supplies
         2 supplies (Vdd, Gnd), 2 widths
  [PASS] the number of ring spacings matches the number of intervals between the supplies
         2 supplies -> 1 interval(s), 1 spacing(s) given
  [PASS] the power ring layers exist in the technology LEF
         Metal4 (min spacing 0.5 um), Metal3 (min spacing 0.5 um)
  [PASS] the power ring spacing is not tighter than the layer spacing
         ring spacing 0.6 um vs layer spacing 0.5 um -- the flow stops with FLOW-ERROR otherwise
  [NOTE] the geometry that the flow derives from the ring settings:
  [INFO]   total ring width  = 3.5 + 0.6 = 4.1 um
  [INFO]   width_contrib     = 3.5 um
  [INFO]   spacing_contrib   = 1.2 um
  [INFO]   macro_ring_spacing= 16.2 um  (2 x site height 8.1 um)
  [INFO]   oversize_m2m      = 41.8 um
  [INFO]   ring offsets      = 4.1 um on every side
  [INFO]   oversize_b2m      = 45.9 um
  [PASS] the core margins are larger than the power ring that surrounds them
         core_yb_spacing 2.0 um + ring offset 4.1 um = the distance from the die edge to the first row
  [PASS] the timing mode is one that the flow understands
         tanner_timing_mode = sdc
  [PASS] every analysis mode has an SDC file
         modes: nominal | sdc arrays: nominal
  [PASS] the run control is one of the three modes the flow understands
         ams_run_control = synpnr
  [NOTE] where the flow reads the contract variables:
  [INFO]   $ams_run_control  <- 0_data_prep.tcl:109
  [INFO]   $lef_file_list  <- tanner_oasys.tcl:23
  [INFO]   $lib_file_list  <- tanner_oasys.tcl:13
  ...
```

ท้ายด้วยข้อความสำคัญ

```text
  [NOTE] a missing variable is not an error in TCL: it reads as an empty string,
         and the flow produces a wrong result instead of stopping.
```

**ทำไม lab นี้สำคัญ**

เพราะใน TCL **ตัวแปรที่ไม่มีอยู่ไม่ใช่ข้อผิดพลาด**
มันอ่านได้เป็นค่าว่างโดยไม่เตือนอะไรเลย

ตัวอย่าง: ถ้าพลาดไปตั้ง `pg_ring_spacing` เป็นชื่ออื่น
flow จะเห็น `pg_ring_spacing` เป็นค่าว่าง
แล้วเดินต่อไปจนพังที่จุดที่ไม่เกี่ยวกับต้นเหตุเลย
หรือแย่กว่านั้นคือ **ไม่พังเลย แต่ได้ผลลัพธ์ที่ผิด**

lab นี้จึงทำสองอย่าง

1. พิสูจน์ว่าตัวแปรที่เราใช้ **มีคนอ่านจริง** พร้อมชี้ตำแหน่ง
2. ตรวจว่าไฟล์ตั้งค่าตัวอย่าง **ครบตามสัญญา**

**ไฟล์ตั้งค่าตัวอย่าง**

อยู่ที่ `design/nitro_settings_ADCCtrl.tcl`
เป็นตัวแทนของสิ่งที่หน้าต่าง Setup TDI เขียนออกมา
มีคำอธิบายทีละกลุ่มว่าตัวแปรแต่ละตัวอยู่หน้าไหนของ Setup TDI

> **ทำไมถึงต้องมีไฟล์ตั้งค่าเป็นลายลักษณ์อักษร**
>
> 1. ถ้า flow พังและข้อความบอกแค่ "missing variable"
>    คุณจะหาไม่เจอว่าตัวแปรชื่ออะไร
> 2. เมื่อคุณต้องทำงานกับเครื่องที่ใช้ flow เวอร์ชันอื่น
>    หรือเขียนสคริปต์เอง คุณต้องรู้ชื่อตัวแปรอยู่แล้ว
> 3. ใช้เป็น **เอกสารประกอบ** ของหน้าต่าง Setup TDI ได้เลย
>    ตารางเต็มอยู่ในภาคผนวก หัวข้อ 6

---


## บทที่ 5 — การรัน TDI จริง และการแก้ปัญหา

บทนี้เป็นส่วนที่ต้องมีเครื่อง Linux ที่ติดตั้ง Nitro
แต่ขั้นตอนการเตรียมทั้งหมดก่อนกด Run สามารถทำบนเครื่อง Windows ได้

### 5.1 ขั้นตอนใน L-Edit ตั้งแต่ต้นจนจบ

#### ขั้นที่ 1 — เปิดดีไซน์และดู RTL

1. เปิด S-Edit
2. `File > Open > Open Design...` แล้วเลือกไฟล์
   `Documents\SiemensEDA\CustomIC_2025.4\Designs\ADC8\lib.defs`
3. เปิด view ชื่อ `verilog_rtl` ของ cell `ADCCtrl` ใน library `ADC8`
4. ตรวจดูพอร์ตของโมดูล — สังเกตว่า `B` เป็นบัส 8 บิต

> ขั้นนี้เป็นแค่การดู ไม่ต้องทำอะไรกับไฟล์
> ใช้เพื่อยืนยันว่า interface ที่คุณเห็นตรงกับที่ lab 01 ตรวจได้

#### ขั้นที่ 2 — เตรียม boundary และพอร์ตในเลย์เอาต์

1. เปิด L-Edit แล้วเปิดดีไซน์เดิม (`Designs\ADC8\lib.defs`)
2. เปิด view ชื่อ `layout` ของ cell `ADCCtrl`
3. กด `Ctrl+A` เพื่อเลือกทั้งหมด จะเห็นกรอบสี่เหลี่ยมบนเลเยอร์
   `prBoundray:drawing` คือ boundary ของบล็อก
4. ยืนยันว่าเลเยอร์นี้ถูกตั้งเป็น **Icon Layer**
   โดยไปที่ `Setup > Special Layers...` ดูค่า Icon Layer
5. หาพอร์ต: กด `Ctrl+F` (Find) ให้ติ๊กที่ `Port` และเว้นช่องว่าง
   แล้วกด `Find Next` จะซูมไปที่พอร์ต `clk`

> **ทำไมต้องเป็น Icon Layer**
>
> เพราะนี่คือสัญญาที่บอก L-Edit ว่า "รูปนี้คือขอบเขตที่ให้วางได้"
> ไม่ใช่แค่เส้นหรือรูปที่วาดไว้เฉย ๆ
> ถ้าเปลี่ยนชื่อเลเยอร์ ต้องไปแก้ค่า Icon Layer ตามด้วยเสมอ

#### ขั้นที่ 3 — เปิดหน้าต่าง Setup TDI

กดปุ่ม **Setup TDI** บนแถบเครื่องมือ Nitro ใน L-Edit
จะเปิดหน้าต่างที่มี 7 หน้า ดูรายละเอียดของแต่ละหน้าในบทที่ 2

#### ขั้นที่ 4 — กรอกค่า

สรุปค่าที่ต้องใส่สำหรับตัวอย่าง ADC8 / ADCCtrl

| หน้า | ค่า |
|---|---|
| **Run File** | Data Directory = โฟลเดอร์ข้อมูลของ run |
| **Tech and Lib** | LEF: `Generic250nm_tech.lef` แล้วค่อย `Generic250nm_StdCells.lef`<br>Liberty: `Generic250nm_TT_2P50V_25C.lib`<br>PTF: `Generic250nm_typ.ptf` |
| **Netlist/RTL** | RTL: `ADCCtrl_rtl.v`<br>Top Cell: `ADCCtrl`<br>Power Net: `Vdd` / Ground Net: `Gnd` |
| **Timing** | โหมด SDC พร้อมไฟล์ `timing_constraints_full.sdc` |
| **Floorplan** | Export from layout (ใช้ boundary ที่วาดไว้) |
| **Power Plan** | แนวตั้ง Metal4, แนวนอน Metal3<br>ลำดับวง: Vdd นอก, Gnd ใน<br>width 2.0 / 1.5 µm, spacing 0.6 µm |
| **Additional Commands** | ว่างไว้ก่อน (ค่าเริ่มต้นของ flow ใช้ได้) |

#### ขั้นที่ 5 — กด Run

กดปุ่ม **Run** จะมีหน้าต่างแสดง log ความคืบหน้า
เมื่อเสร็จแล้วกด **Close** แล้วเลย์เอาต์ที่วางเสร็จจะปรากฏ

### 5.2 สิ่งที่เกิดขึ้นบนเครื่อง Linux

หลังกด Run ไฟล์ทั้งหมดในโฟลเดอร์ข้อมูลจะถูกคัดลอกไปที่

```bash
/tmp/<ชื่อผู้ใช้>_nitro_data
```

จากนั้น flow จะทำงานตามขั้นตอนนี้

```text
data_prep → rtl_synthesis → floorplan → powerplan → physical_synthesis
          → place → cts → post_cts → route → export
```

ตรวจสอบงานบนเครื่อง Linux ได้ด้วย

```bash
ls -la /tmp/$USER_nitro_data
ls -la /tmp/$USER_nitro_data/results
cat /tmp/$USER_nitro_data/results/reports/*.rpt | head -50
```

### 5.3 ผลลัพธ์ที่ได้กลับมา

| ไฟล์ใน `results/` | เนื้อหา |
|---|---|
| `<top>_syn.v` | netlist ระดับ gate ที่ synthesis สร้าง |
| `<top>_scan.def` | นิยาม scan chain (เมื่อเปิด scan) |
| `reports/` | รายงานของทุกขั้นตอน |
| `Kpi.html` | สรุปตัวชี้วัดหลัก เปิดด้วยเบราว์เซอร์ได้ |

**รายงานที่ควรดูก่อนเสมอ**

| ไฟล์ | บอกอะไร |
|---|---|
| `results/reports/*timing*.rpt` | slack ของเส้นทางเวลาที่แย่ที่สุด |
| `results/reports/*place*.rpt` | ผลวางเซลล์ ความหนาแน่นจริงที่ได้ |
| `results/reports/*route*.rpt` | ผลเดินสาย จำนวน violation |
| `results/reports/*power*.rpt` | รายงานแผนจ่ายไฟและ IR drop |

### 5.4 ตารางแก้ปัญหา

อาการ → สาเหตุที่เป็นไปได้ → ทำอะไร

| อาการ | สาเหตุที่เป็นไปได้ | วิธีแก้ |
|---|---|---|
| `FLOW-ERROR : Nb of ring spacing values does not match number of intervals between supplies` | ใส่ `pg_ring_spacing` ผิดจำนวน | ใส่ 1 ค่า หรือ จำนวนแหล่งจ่าย − 1 (หัวข้อ 2.6) |
| `FLOW-ERROR : Nb of ring width values does not match number of supplies` | ใส่ `pg_ring_widths` ผิดจำนวน | ใส่ 1 ค่า หรือ จำนวนแหล่งจ่าย |
| `FLOW-ERROR : PG ring spacing constraint is smaller than ... min_spacing` | spacing ของ ring ชิดเกินกฎของชั้นโลหะ | เพิ่ม `pg_ring_spacing` ให้มากกว่า min spacing ใน LEF (lab 03) |
| `FLOW-ERROR: Number of RLC models ... does not match number of RLC files` | `rlc_file_list` กับไฟล์ RLC ไม่ตรงกัน | ล้าง `rlc_file_list` ให้ว่าง ถ้าใช้ PTF อยู่แล้ว |
| flow อ่าน LEF ล้มเหลว | tech LEF ไม่ได้มาก่อน standard cell LEF | สลับลำดับในหน้า Tech and Lib (lab 06) |
| synthesis หาเซลล์ไม่เจอ | Liberty กับ LEF ไม่ตรงกัน | เทียบรายชื่อเซลล์ทั้งสองไฟล์ (lab 03) |
| พังตอนใส่ tie cell | `tie_high_libcell` / `tie_low_libcell` ชี้เซลล์ที่ไม่มีใน LEF | ตรวจว่าเซลล์ tie มีทั้งใน LEF และ Liberty |
| flow ทำงานแต่ผลลัพธ์ผิด | ตัวแปรหายไป → TCL อ่านเป็นค่าว่าง | รัน lab 06 เพื่อเช็กสัญญา |
| หาไฟล์รายงานไม่เจอ | รายงานอยู่ใน `reports/` แล้วถูกย้ายตอนปิดงาน | ดูทั้ง `results/reports/` และ `reports/` |
| ไม่เจอพอร์ตของ scan | DEF ถูก export ก่อนเพิ่มพอร์ต scan | เพิ่มพอร์ตแล้ว export DEF ใหม่ (lab 05) |
| `nit_write.lock` ค้าง | งานก่อนหน้าถูกปิดไม่สะอาด | ลบไฟล์ lock ใน `/tmp/<user>_nitro_data` แล้วรันใหม่ |

### 5.5 ลำดับที่แนะนำในการทำงานจริง

```text
  1. แก้ RTL ให้เสร็จ
        ↓
  2. วาง boundary + พอร์ตในเลย์เอาต์ แล้ว export DEF
        ↓
  3. รัน lab 01–05 เพื่อตรวจอินพุตทั้งหมด   ← ตรงนี้ที่เสียเวลาน้อยที่สุด
        ↓
  4. ตั้งค่า Setup TDI ตามบทที่ 2
        ↓
  5. ตรวจอีกครั้งด้วย lab 06 (ถ้าแก้ไฟล์ตั้งค่าเอง)
        ↓
  6. กด Run แล้วรอ
        ↓
  7. อ่านรายงาน: timing → place → route → power
        ↓
  8. แก้แล้ววนกลับไปที่ข้อ 2 (ต้อง export DEF ใหม่ทุกครั้ง)
```

> **ข้อควรจำข้อสุดท้าย**
>
> ทุกครั้งที่แก้เลย์เอาต์ ต้อง **export DEF ใหม่** ก่อนกด Run
> DEF คือสัญญาระหว่างเลย์เอาต์กับ flow
> ถ้าไม่ export ใหม่ flow จะทำงานกับเลย์เอาต์เก่าโดยไม่บอก

---


## ภาคผนวก

### 6.1 สัญญาตัวแปรฉบับเต็ม

ตารางนี้ได้จากการรัน lab 06 บนเครื่องนี้
คอลัมน์ "อ่านที่" คือ **ไฟล์และบรรทัดจริง** ที่อ่านตัวแปรนั้น

| ตัวแปร | หน้า Setup TDI | อ่านที่ | ความหมาย |
|---|---|---|---|
| `ams_run_control` | Run File | `0_data_prep.tcl:109` | `synpnr` / `syn` / `pnr` |
| `lef_file_list` | Tech and Lib | `tanner_oasys.tcl:23` | รายการ LEF ของขั้นสังเคราะห์ |
| `lib_file_list` | Tech and Lib | `tanner_oasys.tcl:13` | รายการ Liberty |
| `ptf_file_list` | Tech and Lib | `tanner_oasys.tcl:41` | รายการ PTF |
| `tanner_ptf_file_corner_list` | Tech and Lib | `tanner_oasys.tcl:33` | ชื่อมุมของแต่ละ PTF |
| `tech_file_list` | Tech and Lib | `0_data_prep.tcl:18` | เทคโนโลยี LEF ของขั้นวางเดินสาย |
| `cell_lef_file_list` | Tech and Lib | `0_data_prep.tcl:100` | standard cell LEF ของขั้นวางเดินสาย |
| `corner_list` | Tech and Lib | `0_data_prep.tcl:37` | รายการมุมของกระบวนการ |
| `rlc_file_list` | Tech and Lib | `0_data_prep.tcl:35` | ไฟล์โมเดล RLC |
| `top_cell` | Netlist/RTL | `0_data_prep.tcl:160` | โมดูลเป้าหมายของขั้นวางเดินสาย |
| `tanner_cell` | Netlist/RTL | `tanner_oasys.tcl:93` | โมดูลเป้าหมายของขั้นสังเคราะห์ |
| `verilog_file_list` | Netlist/RTL | `tanner_oasys.tcl:65` | รายการไฟล์ RTL |
| `is_list_file` | Netlist/RTL | `tanner_oasys.tcl:57` | อ่านรายการไฟล์จาก list file |
| `is_Verilog` | Netlist/RTL | `tanner_oasys.tcl:59` | list file เป็น Verilog หรือ VHDL |
| `list_file` | Netlist/RTL | `tanner_oasys.tcl:60` | พาธของ list file |
| `use_list_file` | Netlist/RTL | `0_data_prep.tcl:113` | สลับโหมด list file ของขั้น data prep |
| `enable_scan` | Netlist/RTL | `1_rtl_synthesis.tcl:50` | เปิดการทำ scan |
| `syn_netlist` | Netlist/RTL | `0_data_prep.tcl:159` | ที่เก็บ netlist ระดับ gate |
| `tanner_timing_mode` | Timing | `tanner_oasys.tcl:104` | `clocks` หรือ `sdc` |
| `tanner_clock_spec` | Timing | `tanner_oasys.tcl:105` | รายการคล็อก — **ใช้เฉพาะโหมด `clocks`** |
| `MGC_modes` | Timing | `tanner_oasys.tcl:118` | รายการ mode — **ใช้เฉพาะโหมด `sdc`** |
| `oasys_importConstraintsFile` | Timing | `tanner_oasys.tcl:120` | ไฟล์ SDC ของแต่ละ mode — **โหมด `sdc`** |
| `floorplan_mode` | Floorplan | `2_floorplan.tcl:42` | `block` / `layout` / `def` |
| `def_floorplan_file` | Floorplan | `2_floorplan.tcl:82` | ไฟล์ DEF ในโหมด `def` |
| `chip_width` | Floorplan | `2_floorplan.tcl:48` | ความกว้างของ die (DBU) |
| `chip_height` | Floorplan | `2_floorplan.tcl:48` | ความสูงของ die (DBU) |
| `chip_origin_x` | Floorplan | `2_floorplan.tcl:55` | จุดเริ่ม X ของ die |
| `chip_origin_y` | Floorplan | `2_floorplan.tcl:55` | จุดเริ่ม Y ของ die |
| `core_site` | Floorplan | `2_floorplan.tcl:178` | ชื่อ site ของแถวเซลล์ |
| `core_yb_spacing` | Floorplan | `compute_floorplan_details.tcl:87` | ระยะใต้แถวเซลล์จาก ring |
| `core_xl_spacing` | Floorplan | `compute_floorplan_details.tcl:88` | ระยะซ้ายแถวเซลล์จาก ring |
| `core_yt_spacing` | Floorplan | `compute_floorplan_details.tcl:89` | ระยะบนแถวเซลล์จาก ring |
| `core_xr_spacing` | Floorplan | `compute_floorplan_details.tcl:90` | ระยะขวาแถวเซลล์จาก ring |
| `highest_routing_layer` | Floorplan | `2_floorplan.tcl:37` | ชั้นโลหะสูงสุดที่เดินสายได้ |
| `fp_utilization` | Floorplan | `2_floorplan.tcl:63` | เป้าหมายความหนาแน่น |
| `fp_aspect_ratio` | Floorplan | `2_floorplan.tcl:64` | อัตราส่วนกว้าง:ยาว |
| `power_nets` | Power Plan | `2_floorplan.tcl:29` | ชื่อแหล่งจ่าย |
| `ground_nets` | Power Plan | `2_floorplan.tcl:29` | ชื่อกราวด์ |
| `enable_pg_ring` | Power Plan | `2_floorplan.tcl:104` | เปิด/ปิดแหวนจ่ายไฟ |
| `enable_pg_stripe` | Power Plan | `3_powerplan.tcl:149` | เปิด/ปิดแถบจ่ายไฟ |
| `pg_ring_vlayer` | Power Plan | `2_floorplan.tcl:105` | ชั้นของเส้นแนวตั้งของ ring |
| `pg_ring_hlayer` | Power Plan | `2_floorplan.tcl:106` | ชั้นของเส้นแนวนอนของ ring |
| `pg_ring_net_order` | Power Plan | `3_powerplan.tcl:71` | ลำดับวงจากนอกเข้าใน |
| `pg_ring_widths` | Power Plan | `3_powerplan.tcl:73` | ความกว้างของแต่ละวง |
| `pg_ring_spacing` | Power Plan | `3_powerplan.tcl:61` | ระยะห่างระหว่างวง |
| `pg_ring_offset_top` | Power Plan | `3_powerplan.tcl:101` | ระยะเพิ่มด้านบน |
| `pg_ring_offset_right` | Power Plan | `3_powerplan.tcl:100` | ระยะเพิ่มด้านขวา |
| `pg_ring_offset_bottom` | Power Plan | `3_powerplan.tcl:99` | ระยะเพิ่มด้านล่าง |
| `pg_ring_offset_left` | Power Plan | `3_powerplan.tcl:98` | ระยะเพิ่มด้านซ้าย |
| `pg_stripe_list` | Power Plan | `3_powerplan.tcl:153` | รายการแถบจ่ายไฟ |
| `num_of_stripes` | Power Plan | `3_powerplan.tcl:195` | จำนวนแถบ |

### 6.2 ตัวแปรของ flow ที่ตั้งค่าได้จากหน้า Additional Commands

จาก `ap_ref_flows/flow_variables.tcl`

| ตัวแปร | ค่าเริ่มต้น | ผลของการเปลี่ยน |
|---|---|---|
| `exit_on_flow_error` | 0 | หยุดทันทีเมื่อเจอ error |
| `enable_no_clock_flow` | 0 | อนุญาตให้ flow ทำงานโดยไม่มีคล็อก |
| `save_all_verilog` | 0 | บันทึก Verilog ทุกเวอร์ชัน |
| `export_RDB` | 1 | export ฐานข้อมูลรายงาน |
| `allow_incomplete_liberty_data` | 0 | ยอมรับ Liberty ที่ไม่ครบ |
| `dont_use_libcells` | *(ว่าง)* | เซลล์ที่ห้ามใช้ |
| `HDL_format` | *(ว่าง)* | `verilog` / `systemverilog` / `vhdl87` / `vhdl93` / `vhdl2008` |
| `rtl_max_util` | 85 | ความหนาแน่นสูงสุดของ netlist ที่สังเคราะห์ |
| `enable_clock_gating` | 0 | ใส่ clock gating อัตโนมัติ |
| `DFT_flow` | `native` | วิธีทำ scan: `native` / `tessent` |
| `force_io_placement` | 1 | บังคับวางพอร์ตตามตำแหน่งที่กำหนด |
| `delete_unconnected_phys_pins` | 0 | ลบรูปพอร์ตที่ไม่ต่อ |
| `well_tap_cell` | *(ว่าง)* | เซลล์ well tap |
| `well_tap_h_spread` | *(ว่าง)* | ระยะแนวนอนระหว่างคอลัมน์ well tap |
| `well_tap_h_offset` | 0 | ตำแหน่งเริ่มของ well tap แรก |
| `well_tap_pattern` | `none` | `none` / `stagger` / `even_rows` / `odd_rows` |
| `pg_rail_method` | `auto` | `auto` / `lef` / `filler` |
| `physical_effort` | `low` | ความพยายามของ physical synthesis |
| `cts_repeaters` | *(ว่าง)* | เซลล์ repeater ของ clock tree |
| `delay_cells` | *(ว่าง)* | เซลล์ delay |
| `tie_high_libcell` | *(ว่าง)* | เซลล์ tie logic ขั้นสูง |
| `tie_low_libcell` | *(ว่าง)* | เซลล์ tie logic ขั้นต่ำ |
| `route_optimize_effort` | `low` | ความพยายามของ router |
| `route_opt_via_effort` | `low` | ความพยายามของการเพิ่ม via |
| `antenna_diodes` | *(ว่าง)* | เซลล์ antenna diode |
| `auto_select_diodes` | 1 | เลือกเซลล์ diode ให้อัตโนมัติ |
| `decap_libcells` | *(ว่าง)* | เซลล์ decap |
| `filler_libcells` | *(ว่าง)* | เซลล์ filler |
| `check_user_defined_filler_libcells` | 0 | ตรวจเซลล์ filler ที่ผู้ใช้กำหนด |
| `filler_avoid_viol` | 0 | ให้ filler หลีกเลี่ยง violation |
| `repair_after_filler` | 1 | ซ่อม DRC หลังใส่ filler |

### 6.3 ตัวแปรของ engine ที่ตั้งได้ด้วย `set_param`

จาก `flow_variables.tcl` ส่วนท้าย

| พารามิเตอร์ | ค่าเริ่มต้น | ความหมาย |
|---|---|---|
| `basic verbose_level` | 0 | ระดับความละเอียดของข้อความ |
| `basic timestamp` | 0 | ใส่ timestamp ในข้อความ |
| `db no_brace_in_oblist` | true | ไม่ใช้วงเล็บปีกกาในรายการ object |
| `db save_all_params` | true | บันทึกพารามิเตอร์ทั้งหมด |
| `db trim_macro_blockage` | 1 | ตัดรูป blockage ของ macro ให้พอดี |
| `ta setup_slack_margin` | 0.0 | ขอบเขต slack ของ setup |
| `ta hold_slack_margin` | 0.0 | ขอบเขต slack ของ hold |
| `ta enable_preset_and_clear_arcs` | true | เปิดการตรวจ arc ของ preset/clear |
| `ta dont_check_clock_gating` | false | ไม่ตรวจ clock gating |
| `ta dont_check_recovery_removal` | false | ไม่ตรวจ recovery/removal |
| `ta default_clock_at_input_port` | false | เดา clock ที่พอร์ต input หรือไม่ |
| `place no_filler1` | false | ไม่ใช้ filler ความกว้าง 1 |
| `place use_min_spacing_rules` | true | ใช้กฎระยะห่างขั้นต่ำ |
| `cts move_commit_table_verbosity` | 0 | ความละเอียดของตาราง commit ของ CTS |
| `opt verbose_level` | 0 | ระดับความละเอียดของ optimizer |
| `opt dont_create_assign` | true | ไม่สร้าง assign ใหม่ |
| `route dont_use_m1_wire` | 0 | ไม่ใช้สาย Metal1 |
| `route max_filler_cell_mask` | 1 | ระดับโลหะสูงสุดในเซลล์ filler |
| `route allow_cell_off_grid` | false | อนุญาตให้เซลล์ไม่ตรง grid |

### 6.4 ข้อมูลตัวอย่าง ADC8 ที่วัดได้จริง

| รายการ | ค่า |
|---|---|
| โมดูล | `ADCCtrl` |
| พอร์ตทั้งหมด | 15 (input 4 / output 11) |
| บัสเอาต์พุต | `B[7:0]` |
| คล็อก | `clk`, คาบเวลา 10000 ns, duty 50% |
| `timescale` ของ RTL | `100ns/1ps` (1 time unit = 100 ns) |
| เลย์เอาต์ | `prBoundray:drawing` (Icon Layer) |
| ขนาดบล็อก | 177.800 × 53.000 µm |
| หน่วย DEF | 1000 DBU = 1 µm |
| พอร์ตอยู่บน | Metal4 — ขอบล่าง 6 / ขอบบน 9 |
| ระยะพอร์ตต่ำสุด | 15.200 µm |
| เทคโนโลยี | Generic 250 nm, Metal1..Metal4, Via1..Via3 |
| site | `CORE`, 1.15 × 8.10 µm |
| เซลล์มาตรฐาน | 22 เซลล์ (LEF และ Liberty เท่ากันแต่ไม่ใช่ชุดเดียวกัน) |
| มุมของกระบวนการ | fast = FF 2.75 V −40 °C, nominal = TT 2.50 V 25 °C, slow = SS 2.25 V 125 °C |
| PTF | `Generic250_MET4_typ`, หน่วยความจุ ff, ความต้านทาน ohm |
| min spacing | Metal3 / Metal4 = 0.5 µm |

### 6.5 สูตรที่ flow ใช้คำนวณแผน power

จาก `ap_ref_flows/tcl_procs/compute_floorplan_details.tcl`

```tcl
set total_widths   [expr ผลรวมของ pg_ring_widths]        # หรือ width เดียว x จำนวนแหล่งจ่าย
set total_spacing  [expr ผลรวมของ pg_ring_spacing]       # หรือ spacing เดียว x (จำนวนแหล่งจ่าย - 1)
set pg_ring_width  [expr $total_widths + $total_spacing]

set width_contrib    = width ของ Vdd + width ของ Gnd
set spacing_contrib  = 2 x spacing แรก
set macro_ring_spacing = 2 x ความสูงของ site          # ถ้าไม่ได้ตั้งไว้เอง
set oversize_m2m     = 2 x (width_contrib + spacing_contrib + macro_ring_spacing)

set ring_offset_<side> = pg_ring_offset_<side> + pg_ring_width
set core_to_<side>    = ring_offset_<side> + core_<side>_spacing
set oversize_b2m      = max(ring_offset ทั้งสี่ด้าน) + oversize_m2m
```

ตัวอย่างที่คำนวณได้จากค่าในคู่มือนี้

| ปริมาณ | ค่า |
|---|---|
| `total_widths` | 3.5 µm |
| `total_spacing` | 0.6 µm |
| `pg_ring_width` | 4.1 µm |
| `width_contrib` | 3.5 µm |
| `spacing_contrib` | 1.2 µm |
| `macro_ring_spacing` | 16.2 µm |
| `oversize_m2m` | 41.8 µm |
| `ring_offset_*` | 4.1 µm ทุกด้าน |
| `oversize_b2m` | 45.9 µm |

### 6.6 ไฟล์ทั้งหมดที่คัดลอกมาในโปรเจกต์นี้

ทั้งหมดมาจากการติดตั้ง Custom IC 2025.4 และชุดตัวอย่าง ADC8

| ไฟล์ต้นทาง | ไฟล์ในโปรเจกต์ | ขนาด |
|---|---|---|
| `...\ADC8\ADC8\ADCCtrl\PNR_Data\from_ledit.def` | `design/from_ledit.def` | 3,287 B |
| `...\ADC8\ADC8\ADCCtrl\PNR_Data\scanchain.tcl` | `design/scanchain.tcl` | 779 B |
| `...\ADC8\ADC8\ADCCtrl\AP_Data\ADCCtrl_rtl.v` | `design/files/ADCCtrl_rtl.v` | 945 B |
| `...\ADCCtrl\STA_Data\files\Generic250nm_tech.lef` | `design/files/…` | 6,900 B |
| `...\ADCCtrl\STA_Data\files\Generic250nm_StdCells.lef` | `design/files/…` | 62,591 B |
| `...\ADCCtrl\STA_Data\files\Generic250nm_TT_2P50V_25C.lib` | `design/files/…` | 377,228 B |
| `...\ADCCtrl\STA_Data\files\Generic250nm_typ.ptf` | `design/files/…` | 159,458 B |
| `...\ADCCtrl\STA_Data\files\timing_constraints.sdc` | `design/files/…` | 73 B |
| `...\Generic_250nm\...\Liberty\Generic250nm_FF_2P75V_M40C.lib` | `design/files/…` | 330,089 B |
| `...\Generic_250nm\...\Liberty\Generic250nm_SS_2P25V_125C.lib` | `design/files/…` | 330,351 B |

ไฟล์ที่คู่มือนี้เขียนขึ้นเอง

| ไฟล์ | รายละเอียด |
|---|---|
| `design/nitro_settings_ADCCtrl.tcl` | ตัวอย่างไฟล์ตั้งค่าตามสัญญาในหัวข้อ 6.1 |
| `design/files/timing_constraints_full.sdc` | SDC ฉบับครบที่เพิ่ม input/output delay |
| `tools/checks/*.js` | ตัวตรวจสอบของ lab 01..06 เขียนขึ้นใหม่ทั้งหมด |
| `tools/run_template.cmd`, `tools/make-runners.ps1` | ตัวสร้าง runner ของแต่ละ lab |
| `docs/parts/*.md` | ต้นฉบับคู่มือ |

### 6.7 ที่มาและลิขสิทธิ์

- คู่มือ **Tanner Digital Implementer (TDI) Self-Paced Tutorial** ของ Siemens EDA
  (รุ่น 2024.3) เป็นเอกสารประกอบการใช้งานของหน้าต่าง Setup TDI
  เอกสารนี้เป็นเอกสารภายในของ Siemens ที่มีข้อกำหนดเรื่องการเผยแพร่
  **คู่มือฉบับนี้จัดทำขึ้นเป็นเอกสารภายในขององค์กร ไม่ควรแจกจ่ายต่อ**
- ไฟล์ตัวอย่าง ADC8, LEF, Liberty, PTF และ SDC เป็นส่วนหนึ่งของ
  **Siemens Custom IC Platform 2025.4** ซึ่งใช้ภายใต้สัญญาอนุญาตของผู้ใช้
- โค้ดตัวตรวจสอบ, ไฟล์ตั้งค่าตัวอย่าง และเอกสารทั้งหมดในโปรเจกต์นี้
  **เขียนขึ้นใหม่** สำหรับคู่มือนี้
- `Tanner`, `L-Edit`, `Nitro`, `Oasys` และ `Siemens EDA` เป็นเครื่องหมายการค้า
  ของ Siemens EDA

### 6.8 สร้างเอกสารใหม่

```bat
powershell -NoProfile -ExecutionPolicy Bypass -File tools\build-docs.ps1
```

ต้องมี **pandoc** และ **Google Chrome**
สคริปต์จะรวม `docs/parts/*.md` เป็น `docs/Lab_Guide_TDI.md`
แล้วสร้าง HTML และ PDF ต่อ

สร้างไฟล์ ZIP ส่งมอบ

```bat
powershell -NoProfile -ExecutionPolicy Bypass -File tools\make-zip.ps1
```

---

