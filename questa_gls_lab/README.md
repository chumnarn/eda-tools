# QuestaSim GLS Lab — คู่มือปฏิบัติการ Gate-Level Simulation

คู่มือแบบ **step-by-step 8 lab** สอนการจำลองระดับ gate (Gate-Level Simulation)
ด้วย **QuestaSim / ModelSim 2026.1** โดยใช้ชุดเซลล์มาตรฐาน **IHP SG13G2**

> **ทุกตัวเลขและทุกข้อความในคู่มือมาจากการรันจริงบนเครื่อง**
> ไม่ใช่ตัวอย่างที่แต่งขึ้น — ผลรันของทั้ง 8 lab คือ **8/8 ALL GREEN**

## คู่มือฉบับเต็ม

| รูปแบบ | ไฟล์ |
|---|---|
| Markdown | `docs/Lab_Guide_QuestaSim_GLS.md` |
| HTML | `docs/Lab_Guide_QuestaSim_GLS.html` |
| PDF | `docs/Lab_Guide_QuestaSim_GLS.pdf` |

## สิ่งที่ต้องมี

| ต้องมี | หมายเหตุ |
|---|---|
| QuestaSim หรือ ModelSim 2026.1 | ใบอนุญาตเป็น session เดียว — ระบบเลือกชุดที่ใช้ได้ให้อัตโนมัติ |
| ไฟล์เซลล์ SG13G2 | มีอยู่ใน `cells/` แล้ว ไม่ต้องติดตั้ง PDK เพิ่ม |
| Yosys (ถ้าจะสังเคราะห์ netlist ใหม่) | ต้องรันใน WSL — netlist ที่สังเคราะห์ไว้แล้วอยู่ใน `netlist/` |

**ทุก lab ที่เป็นการจำลอง รันได้บน Windows ล้วน ๆ** ไม่ต้องมี WSL

## เริ่มต้นใช้งาน

รัน lab เดียว

```bat
cd questa_gls_lab\lab05_rtl_vs_gate
run.cmd
```

รันทั้งชุด

```bat
cd questa_gls_lab\lab08_gls_regression
regression.cmd
```

รหัสจบของ `run.cmd` / `regression.cmd`

| รหัส | ความหมาย |
|---|---|
| `0` | ผ่าน |
| `1` | ไม่ผ่าน |
| `2` | หาเครื่องมือหรือโฟลเดอร์ไม่เจอ |

## 8 lab

| Lab | หัวข้อ | สิ่งที่พิสูจน์ |
|---|---|---|
| 01 | RTL baseline | จุดอ้างอิงของ trace (checks = 9, errors = 0) |
| 02 | RTL → netlist ด้วย Yosys | `cnt4` = 11 เซลล์, 7 ชนิด, 4 flip-flop |
| 03 | รู้จักชุดเซลล์ SG13G2 | 84 เซลล์ แบ่งเป็น 5 กลุ่ม (9 / 7 / 3 / 10 / 55) |
| 04 | GLS ครั้งแรก | ข้อผิดพลาด `vsim-3033` 11 บรรทัดในทางที่ผิด |
| 05 | RTL vs gate ด้วย testbench ชุดเดียว | trace สองฝั่งตรงกันทุกบรรทัด |
| 06 | การแพร่ค่า `x` | RTL เห็น `3` แต่ gate เห็น `x` |
| 07 | จับบั๊กใน netlist | RTL ผ่าน แต่ gate พัง (6 error) |
| 08 | regression หลายดีไซน์ | `alu4`, `fsm_light`, `sr16` ผ่านทั้งสองระดับ |

## โครงสร้างโฟลเดอร์

```text
questa_gls_lab/
├── docs/                     คู่มือฉบับนี้ (Markdown / HTML / PDF)
│   └── parts/                ต้นฉบับที่แยกเป็นส่วน ๆ
├── tools/
│   ├── pick_tool.cmd          เลือกชุดติดตั้งที่ยังมี license ว่าง
│   ├── run_template.cmd       เทมเพลต run.cmd ของ lab ที่จำลองครั้งเดียว
│   ├── run_template_2step.cmd เทมเพลต run.cmd ของ lab ที่ต้องรันสองครั้ง
│   ├── make-runners.ps1       ตัวสร้าง run.cmd ของทุก lab
│   ├── gls_common.do          proc ช่วยเหลือที่ทุก lab ใช้ร่วมกัน
│   ├── synth/synth.sh         สคริปต์สังเคราะห์ (รันใน WSL)
│   ├── build-docs.ps1         รวม Markdown แล้วสร้าง HTML + PDF
│   └── make-zip.ps1           สร้างไฟล์ ZIP ส่งมอบ
├── rtl/                       RTL ที่ใช้ในคู่มือ (Verilog)
├── netlist/                   gate netlist ที่สังเคราะห์ไว้แล้ว
├── cells/                     โมเดลเซลล์ + Liberty ของ SG13G2
├── tb/                        testbench ที่ใช้ร่วมกันทุก lab
├── lab01_rtl_baseline/  ...  lab08_gls_regression/
└── lab08_gls_regression/results/   ผลรวมของทั้งชุด
```

> **หัวใจของคู่มือ**
> `rtl/`, `netlist/`, `cells/` และ `tb/` อยู่ระดับเดียวกัน
> ทำให้ **testbench ชุดเดียวกันใช้ได้ทั้งระดับ RTL และระดับ gate**
> ต่างกันแค่ว่าไฟล์ไหนถูก compile เข้าไลบรารี `work`

## สังเคราะห์ netlist ใหม่ (ต้องมี WSL)

```bash
wsl -d Ubuntu -u root -- bash /mnt/c/Users/000148/Documents/MiniMax/eda-tools/questa_gls_lab/tools/synth/synth.sh
```

หรือเลือกเฉพาะบางดีไซน์

```bash
bash tools/synth/synth.sh cnt4 alu4
```

สคริปต์อ่าน Liberty จาก PDK ที่ `E:\lab\pdks\IHP-Open-PDK\...`
และเขียนผลลง `netlist/<top>_net.v`, `<top>_stat.txt`, `<top>_synth.log`

## สร้างเอกสารใหม่

```bat
powershell -NoProfile -ExecutionPolicy Bypass -File tools\build-docs.ps1
```

ต้องมี **pandoc** และ **Google Chrome** (สำหรับ PDF)
สคริปต์จะรวม `docs/parts/*.md` เป็น `docs/Lab_Guide_QuestaSim_GLS.md`
แล้วสร้าง HTML และ PDF ต่อ

## เรื่องใบอนุญาต (license)

ใบอนุญาตของเครื่องที่วัดคือ **node-locked แบบ session เดียว**
ถ้ามี QuestaSim GUI เปิดค้างอยู่ (`vish.exe -gui`) มันจะถือ seat ของชุด QuestaSim
การรันแบบบรรทัดคำสั่งด้วยชุดนั้นจะถูกปฏิเสธ

คู่มือนี้จึง **ไม่ hardcode path ของชุดติดตั้งเลย**
แต่ให้ `tools/pick_tool.cmd` ไล่ทดสอบ license จริงของแต่ละชุด
(คอมไพล์ design จิ๋วแล้วโหลดจริง — เพราะ license ถูกเช็คตอนโหลด design เท่านั้น)
แล้วเลือกชุดแรกที่ใช้ได้

ถ้าอยากบังคับให้ใช้ชุดใดชุดหนึ่ง ให้ตั้ง `QUESTASIM_HOME` หรือ `MODELSIM_HOME`

## ลิขสิทธิ์และที่มา

- โค้ด RTL, testbench, สคริปต์ และเอกสารในโปรเจกต์นี้เขียนขึ้นใหม่สำหรับคู่มือนี้
- `cells/sg13g2_stdcell.v`, `cells/sg13g2_udp.v` และไฟล์ Liberty
  เป็นของ **IHP PDK Authors** ภายใต้ **Apache License 2.0**
  (มีหัวข้อลิขสิทธิ์อยู่ในไฟล์ต้นฉบับ)
- `ModelSim` / `QuestaSim` เป็นเครื่องหมายการค้าของ Siemens EDA
