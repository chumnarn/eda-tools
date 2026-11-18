# คู่มือปฏิบัติการ QuestaSim: การจำลองด้วย VHDL

โครงการประกอบคู่มือปฏิบัติการ **“QuestaSim for VHDL Simulation — from Basics to Advanced”**
แบบ Lab แบบทีละขั้น 11 lab

> ตัวเลขและข้อความทุกตัวในคู่มือได้จาก **การรันจริง** บนเครื่อง
> ModelSim DE-64 / QuestaSim **2026.1** (`vsim 2026.1 Simulator 2026.01 Jan 25 2026`)
> ไม่ใช่ตัวอย่างที่แต่งขึ้น — ทำซ้ำตามคู่มือแล้วจะได้ผลชุดเดียวกัน

## เอกสารหลัก

| ไฟล์ | รูปแบบ | ความเหมาะสม |
|---|---|---|
| [`docs/Lab_Guide_QuestaSim_VHDL.md`](docs/Lab_Guide_QuestaSim_VHDL.md) | Markdown | ต้นฉบับสำหรับแก้ไข / แปลงเป็นรูปแบบอื่น |
| [`docs/Lab_Guide_QuestaSim_VHDL.html`](docs/Lab_Guide_QuestaSim_VHDL.html) | HTML (CSS ฝังในไฟล์) | เปิดด้วยเบราว์เซอร์ได้ทันที ไม่ต้องติดตั้งอะไร |
| [`docs/Lab_Guide_QuestaSim_VHDL.pdf`](docs/Lab_Guide_QuestaSim_VHDL.pdf) | PDF (A4) | พิมพ์และแจกเป็นเอกสารประกอบการสอน |

## หัวข้อที่ครอบคลุม

| # | Lab | หัวข้อหลัก |
|---|---|---|
| 01 | first simulation | `vlib` / `vmap` / `vcom` / `vsim`, โหมด GUI กับ batch |
| 02 | libraries | design library, การอ้างอิงข้ามไลบรารี |
| 03 | self-checking tb | `assert` severity, จังหวะตรวจ FSM แบบ Moore, ผลลัพธ์เป็นไฟล์ |
| 04 | waveform | `add wave`, cursor, WLF, ส่งออก VCD |
| 05 | debugging | `bp`, `examine`, `force`, หาบั๊กจริงใน DUT |
| 06 | dataflow | ต้นเหตุของค่า X, กฎการแพร่ X ของ IEEE 1164 |
| 07 | memory | คำสั่ง `mem` ทั้งชุด, โหลด/บันทึก/ค้นหาในอาร์เรย์ VHDL |
| 08 | stimulus | เวกเตอร์จากไฟล์, สุ่มแบบ deterministic, generic, golden file |
| 09 | PSL | property assertion, `default clock`, `assume`, `cover`, `-nopsl` |
| 10 | coverage | statement/branch/condition/expression/toggle/FSM, merge, รายงาน |
| 11 | regression | รันทุก lab เป็นชุด, สรุปผล, รหัสจบสำหรับ CI |

## วิธีรัน

```bat
:: รัน lab เดียว
cd questa_vhdl_lab\lab01_first_simulation
run.cmd

:: รันทุก lab แล้วสรุปผล
cd questa_vhdl_lab\lab11_regression
regression.cmd
```

| รหัสจบ | ความหมาย |
|---|---|
| `0` | ผ่าน (PASS) |
| `1` | ไม่ผ่าน (FAIL) |
| `2` | หาเครื่องมือ/โฟลเดอร์ไม่เจอ |
| `90` | เครื่องมือล้มเหลวระหว่างทำงาน |

`run.cmd` จะหาเครื่องมือที่ใช้ได้จริงให้เองโดยอัตโนมัติ (ดูหัวข้อ 1.2 ของคู่มือ)
ถ้าต้องการบังคับใช้ชุดใดชุดหนึ่ง ให้ตั้ง `QUESTASIM_HOME` หรือ `MODELSIM_HOME`

## ข้อควรรู้เรื่องใบอนุญาต (license)

ใบอนุญาตของเครื่องนี้เป็น **node-locked แบบ session เดียว**
ถ้ามี QuestaSim GUI เปิดค้างอยู่ การรันแบบบรรทัดคำสั่งด้วยชุด QuestaSim จะถูกปฏิเสธ
สคริปต์ `run.cmd` จึงทดสอบ license จริงแล้วเลือกชุดติดตั้งที่ใช้ได้ให้เอง

## โครงสร้าง

```text
questa_vhdl_lab/
├── docs/                     คู่มือฉบับเต็ม (Markdown / HTML / PDF)
├── tools/
│   ├── pick_tool.cmd           เลือกชุดติดตั้งที่ยังมี license ว่าง (ใช้ร่วมกันทุก lab)
│   ├── run_template.cmd       เทมเพลตสคริปต์รันของทุก lab
│   ├── make-runners.ps1       ตัวสร้าง run.cmd ของทุก lab
│   ├── build-docs.ps1         รวม Markdown แล้วสร้าง HTML + PDF
│   ├── make-zip.ps1           รวมทั้งชุดเป็นไฟล์ ZIP (ไม่รวม work/ และ modelsim.ini)
│   └── probe/probe_top.vhd    design จิ๋วสำหรับ license probe
├── lab01_first_simulation/    ... lab11_regression/
│   ├── src/                   DUT
│   ├── tb/                    testbench
│   ├── run.do                 สคริปต์สำหรับใช้ใน GUI
│   ├── run_batch.do           สคริปต์สำหรับรันแบบ batch
│   ├── run.cmd                ตัวรันแบบ Windows (เลือกเครื่องมือ + ตัดสิน PASS/FAIL)
│   └── results/               ผลลัพธ์จากการรัน
└── lab11_regression/results/  ผลรวมของทั้งชุด
```

## ไฟล์ที่ถูกสร้างขึ้นใหม่ทุกครั้งที่รัน

เป็นผลลัพธ์ของเครื่องมือ ไม่ต้องแก้ไข:

| ไฟล์ | ที่มา |
|---|---|
| `work/` | work library ที่ `vmap` สร้างไว้ |
| `modelsim.ini` | ไฟล์ตั้งค่าที่ `vmap` สร้างขึ้นในโฟลเดอร์ปัจจุบัน |
| `transcript` | transcript ของ `vsim` รอบล่าสุด |
| `result.txt` | ผล PASS/FAIL ที่ testbench เขียนให้ |

## สร้างเอกสารใหม่หลังแก้ไข Markdown

```bat
set PATH=C:\Program Files\Pandoc;%PATH%
pandoc docs\Lab_Guide_QuestaSim_VHDL.md -f gfm -t html5 --standalone --toc ^
       --toc-depth=3 --embed-resources --css=docs\lab_style.css ^
       --metadata title="QuestaSim VHDL Simulation - Lab Guide" ^
       --metadata lang="th" -o docs\Lab_Guide_QuestaSim_VHDL.html

"C:\Program Files\Google\Chrome\Application\chrome.exe" --headless=new --disable-gpu ^
       --no-pdf-header-footer --print-to-pdf=docs\Lab_Guide_QuestaSim_VHDL.pdf ^
       "file:///C:/path/to/questa_vhdl_lab/docs/Lab_Guide_QuestaSim_VHDL.html"
```
