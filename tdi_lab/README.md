# Tanner Digital Implementer (TDI) — คู่มือปฏิบัติการ

คู่มือแบบ **6 lab + ภาคผนวกอ้างอิง** สอนการตั้งค่าและตรวจสอบกระบวนการ
**Tanner Digital Implementer (TDI)** ซึ่งนำ RTL ดิจิทัลเข้าไปวางและเดินสาย
ภายในเลย์เอาต์ของวงจรอนุล็อกที่ออกแบบด้วย L-Edit

> **ทุกตัวเลขและทุกข้อความในคู่มือนี้มาจากการรันจริงบนเครื่อง**
> ไม่ใช่ตัวอย่างที่แต่งขึ้น — ผลรันของทั้ง 6 lab คือ **6/6 ALL GREEN**
> และมี **62 ข้อตรวจสอบ** ผ่านทั้งหมด

## คู่มือฉบับเต็ม

| รูปแบบ | ไฟล์ |
|---|---|
| Markdown | `docs/Lab_Guide_TDI.md` |
| HTML | `docs/Lab_Guide_TDI.html` |
| PDF | `docs/Lab_Guide_TDI.pdf` |

## สิ่งที่ต้องมี

| ต้องมี | หมายเหตุ |
|---|---|
| **Custom IC Platform 2025.4** | ติดตั้งที่ `C:\Siemens\Custom IC\Custom IC 2025.4\x64` แล้ว |
| **ไฟล์ตัวอย่าง ADC8** | อยู่ที่ `...\Documents\SiemensEDA\CustomIC_2025.4\Designs\ADC8` แล้ว |
| **Node.js 18 ขึ้นไป** | ใช้รันตัวตรวจสอบ — ตรวจ `node -v` |
| **Generic 250 nm libraries** | คัดลอกมาไว้ใน `design/files/` แล้ว ไม่ต้องติดตั้ง PDK เพิ่ม |

**ทุก lab รันได้บน Windows ล้วน ๆ** ไม่ต้องใช้ Nitro

## เริ่มต้นใช้งาน

รัน lab เดียว

```bat
cd tdi_lab\lab01_rtl_ports
run.cmd
```

รันทั้งชุด

```bat
cd tdi_lab\lab07_regression
run.cmd
```

รหัสจบของ `cmd.exe`

| รหัส | ความหมาย |
|---|---|
| `0` | ผ่าน |
| `1` | ไม่ผ่าน |
| `2` | หาเครื่องมือหรือโฟลเดอร์ไม่เจอ |

## 6 lab

| Lab | หัวข้อ | สิ่งที่พิสูจน์ |
|---|---|---|
| 01 | RTL กับพอร์ตใน DEF | 15 พอร์ตตรงกันหมด ทิศทางและชื่อโมดูลถูกต้อง |
| 02 | Boundary และตำแหน่งพอร์ต | บล็อก 177.800 × 53.000 µm, พอร์ตบน Metal4, pitch ต่ำสุด 15.200 µm |
| 03 | เทคโนโลยีและชุดเซลล์ | 4 ชั้นโลหะ, SITE CORE 1.15 × 8.10 µm, พบ LEF/Liberty ไม่ตรงกัน 4 เซลล์ |
| 04 | เงื่อนไขเวลา | คล็อก 10000 ns = 100 รอบเวลา, SDC ฉบับครบมี input/output delay |
| 05 | การตั้งค่า scan | 1 chain, สร้างพอร์ตใหม่ 3 ตัวที่ยังไม่มีใน DEF |
| 06 | สัญญาไฟล์ตั้งค่า | ตัวแปร 51 ตัวผูกกับสคริปต์จริง, power ring ผ่านกฎของ flow |

## โครงสร้างโฟลเดอร์

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
│   ├── nitro_settings_ADCCtrl.tcl  ตัวอย่างไฟล์ตั้งค่า (สัญญา 51 ตัวแปร)
│   └── files/                    LEF / Liberty / PTF / SDC / RTL
├── lab01_rtl_ports/  ...  lab06_settings/
└── lab07_regression/            รันทุก lab พร้อมกันและสรุปผล
```

## สร้างเอกสารใหม่

```bat
powershell -NoProfile -ExecutionPolicy Bypass -File tools\build-docs.ps1
```

ต้องมี **pandoc** และ **Google Chrome** (สำหรับ PDF)
สคริปต์จะรวม `docs/parts/*.md` เป็น `docs/Lab_Guide_TDI.md` แล้วสร้าง HTML และ PDF ต่อ

สร้างไฟล์ ZIP ส่งมอบ

```bat
powershell -NoProfile -ExecutionPolicy Bypass -File tools\make-zip.ps1
```

## เรื่องเอกสารต้นทาง

คู่มือ **TDI Self-Paced Tutorial** ของ Siemens EDA (รุ่น 2024.3) เป็นเอกสาร
ภายในที่มีข้อกำหนดเรื่องการเผยแพร่ **คู่มือฉบับนี้จัดทำขึ้นเป็นเอกสารภายในขององค์กร
ไม่ควรแจกจ่ายต่อ** รายละเอียดอยู่ในภาคผนวก หัวข้อ 6.7

โค้ดตัวตรวจสอบ ไฟล์ตั้งค่าตัวอย่าง และเอกสารทั้งหมดในโปรเจกต์นี้
เขียนขึ้นใหม่สำหรับคู่มือนี้
