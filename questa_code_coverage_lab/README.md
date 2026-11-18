# Lab: Using Code Coverage in QuestaSim

โครงการประกอบคู่มือปฏิบัติการ **"Using Code Coverage in QuestaSim"**
(Questa Tool Usage — Module 3: Introduction to Code-Coverage)

## เอกสารหลัก

| ไฟล์ | รูปแบบ | ความเหมาะสม |
|---|---|---|
| [`docs/Lab_Guide_Code_Coverage.md`](docs/Lab_Guide_Code_Coverage.md) | Markdown | ต้นฉบับสำหรับแก้ไข / แปลงเป็นรูปแบบอื่น |
| [`docs/Lab_Guide_Code_Coverage.html`](docs/Lab_Guide_Code_Coverage.html) | HTML (CSS ฝังในไฟล์) | เปิดด้วยเบราว์เซอร์ได้ทันที ไม่ต้องติดตั้งอะไร |
| [`docs/Lab_Guide_Code_Coverage.pdf`](docs/Lab_Guide_Code_Coverage.pdf) | PDF (A4) | พิมพ์และแจกเป็นเอกสารประกอบการสอน |

> ตัวเลขทุกตัวในคู่มือได้จากการรันจริงบน **ModelSim DE-64 / QuestaSim 2026.1**
> ไม่ใช่ตัวอย่างที่แต่งขึ้น — ทำซ้ำตามคู่มือแล้วจะได้ผลชุดเดียวกัน

## หัวข้อที่ครอบคลุม

1. **Introduction to Code Coverage** — ความหมาย ความจำเป็น และความต่างจาก functional coverage
2. **Types of Code Coverage** — statement / branch / condition / expression / toggle / FSM
3. **Using Code Coverage in QuestaSim** — 2-step flow, หน้าต่างวิเคราะห์, goal และ exclude
4. **Merging Code Coverage from different tests** — UCDB, merge, และกับดัก instance path
5. **Generating Code Coverage Reports** — summary / detail / HTML / Coverage View mode

## วิธีรัน

```bat
:: ตั้ง PATH ของ ModelSim / QuestaSim (ปรับตามเครื่อง)
set PATH=C:\Siemens\modelsim_dlx64_2026.1\win64pe;%PATH%

cd questa_code_coverage_lab

scripts\run_all.cmd     :: flow ของ Verilog -> results\merged.ucdb + รายงาน HTML
scripts\run_vhdl.cmd    :: flow ของ VHDL    -> results\vhdl_merged.ucdb + รายงาน HTML
```

ต้องมี ModelSim / QuestaSim พร้อมสิทธิ์ใช้ Code Coverage

## ผลลัพธ์ที่ได้ (ตรวจสอบแล้ว)

| | test `basic` | test `extra` | test `edge` | merged |
|---|---|---|---|---|
| Total (Verilog) | 62.76% | 76.30% | 73.87% | **100.00%** |
| Total (VHDL) | 66.72% | 76.81% | 78.56% | **100.00%** |

## โครงสร้าง

```
rtl/cmd_fsm.v            DUT (Verilog-2001)  มีโครงสร้างครบทั้ง 6 metric
tb/tb_cmd_fsm.v          testbench เดียว เลือก test ด้วย +TEST= plusarg
tb/pitfall/              testbench 2 ชุด สำหรับสาธิตข้อผิดพลาดเรื่อง instance path
vhdl/cmd_fsm.vhd         DUT (VHDL-2008)  + generic TEST
scripts/                 compile.do / lab1..lab4.do / run_all.cmd / run_vhdl.cmd
results/                 ผลลัพธ์จากการรัน (UCDB, รายงาน text และ HTML)
docs/                    คู่มือฉบับเต็ม (Markdown / HTML / PDF)
tools/                   ตัวตรวจสอบโครงสร้าง Markdown
```

ไฟล์ที่ถูกสร้างขึ้น **ใหม่ทุกครั้งที่รัน** (เป็นผลลัพธ์ของเครื่องมือ ไม่ต้องแก้ไข):

| ไฟล์ | ที่มา |
|---|---|
| `work/`, `vhdl_work/` | work library ที่ `vmap` สร้างไว้ |
| `modelsim.ini` | ไฟล์ตั้งค่าที่ `vmap` สร้างขึ้นในโฟลเดอร์ปัจจุบัน |
| `transcript` | transcript ของ `vsim` รอบล่าสุด |
| `ranktest.rank`, `ranktest.contrib`, `ranktest.noncontrib` | ไฟล์ประกอบการจัดอันดับจาก `vcover ranktest` |

## ไฟล์ผลลัพธ์ที่น่าสนใจใน `results/`

| ไฟล์ | เนื้อหา |
|---|---|
| `basic.ucdb`, `extra.ucdb`, `edge.ucdb` | coverage ของแต่ละ test (ติดป้ายด้วย `-testname`) |
| `merged.ucdb` | ผลรวมของ 3 test — 100.00% ทุก metric |
| `merged_2tests.ucdb` / `merged_2tests_detail.txt` | ผลรวมของ 2 test — 84.81% **ใช้เป็นโจทย์แบบฝึกหัด** |
| `merged_detail.txt` | รายงานแบบรายละเอียดของผลรวม 3 test |
| `html_report/index.html` | รายงาน HTML พร้อมตัวดูซอร์สเปคซอร์สโค้ด |
| `vhdl_merged.ucdb`, `vhdl_html/` | ผลของเวอร์ชันภาษา VHDL |

## สร้างเอกสารใหม่หลังแก้ไข Markdown

```bat
set PATH=C:\Program Files\Pandoc;%PATH%
pandoc docs\Lab_Guide_Code_Coverage.md -f gfm -t html5 --standalone --toc ^
       --toc-depth=3 --embed-resources --css=docs\lab_style.css ^
       --metadata title="Using Code Coverage in QuestaSim - Lab Guide" ^
       --metadata lang="th" -o docs\Lab_Guide_Code_Coverage.html

"C:\Program Files\Google\Chrome\Application\chrome.exe" --headless=new --disable-gpu ^
       --no-pdf-header-footer --print-to-pdf=docs\Lab_Guide_Code_Coverage.pdf ^
       "file:///C:/path/to/questa_code_coverage_lab/docs/Lab_Guide_Code_Coverage.html"
```
