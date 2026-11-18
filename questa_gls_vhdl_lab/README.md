# QuestaSim GLS Lab — ฉบับ VHDL

คู่มือปฏิบัติการ **การจำลองระดับ gate (Gate-Level Simulation, GLS)** ด้วย QuestaSim / ModelSim
**8 lab แบบทีละขั้น** ตั้งแต่พื้นฐานจนถึงระดับที่เอาไปใช้ในงานจริงได้

จุดต่างของฉบับนี้: **RTL เขียนด้วย VHDL** แต่สังเคราะห์และจำลองระดับ gate ด้วย Verilog
ซึ่งเป็นสถานการณ์ที่พบบ่อยที่สุดในอุตสาหกรรม ASIC — และเป็นกรณีที่ต้องใช้
**testbench VHDL ชุดเดียวกัน** ขับทั้งสองระดับ

> ⚠ **ตัวเลขและข้อความทุกตัวในคู่มือมาจากการรันจริงบนเครื่อง**
> ไม่ใช่ตัวอย่างที่แต่งขึ้น

---

## ผลการรันจริง

```text
[PASS] lab01_rtl_baseline
[PASS] lab02_synth_netlist
[PASS] lab03_cell_library
[PASS] lab04_gls_first
[PASS] lab05_rtl_vs_gate
[PASS] lab06_x_propagation
[PASS] lab07_netlist_bug
[PASS] lab08_multi_design

 total = 8   passed = 8   failed = 0
[REGRESSION] ALL GREEN
```

| สิ่งที่พิสูจน์ | ผล |
|---|---|
| testbench VHDL ชุดเดียวขับได้ทั้ง RTL และ gate | trace ทั้งสองระดับ **เหมือนกันทุกบรรทัด** |
| จำนวนเซลล์จริงของทั้ง 4 ดีไซน์ | cnt4 11 / alu4 59 / fsm_light 11 / sr16 100 |
| flip-flop จริง | cnt4 4 / alu4 4 / fsm_light 5 / sr16 16 |
| ไลบรารีเซลล์ SG13G2 | 84 เซลล์ = 9 FF + 7 latch + 3 delay + 10 utility + 55 comb |
| RTL กับ gate ต่างกันเรื่อง `x` | RTL เห็น `3` / gate เห็น `X` |
| GLS จับบั๊กที่ RTL จับไม่ได้ | RTL PASS / gate FAIL (checks 9, errors 2) |

---

## สิ่งที่ต้องมี

| ต้องมี | รายละเอียด |
|---|---|
| **QuestaSim หรือ ModelSim 2026.1** | จำลองระดับ RTL และระดับ gate |
| **IHP SG13G2** | ไฟล์เซลล์อยู่ใน `cells/` แล้ว ไม่ต้องติดตั้งอะไรเพิ่ม |
| **WSL (Ubuntu)** | **เฉพาะตอนสังเคราะห์ netlist ใหม่** — netlist ที่สังเคราะห์ไว้แล้วอยู่ใน `netlist/` |

> ทุก lab ที่เป็นการจำลอง **รันได้บน Windows ล้วน ๆ**
> ไม่ต้องมี WSL เลย

> ⚠ **เรื่อง license:** ใบอนุญาตของเครื่องนี้เป็น node-locked แบบ session เดียว
> ถ้าเปิด QuestaSim GUI ค้างไว้ การรันบรรทัดคำสั่งของชุด QuestaSim จะถูกปฏิเสธ
> `tools/pick_tool.cmd` จะทดสอบ license จริงแล้วเลือกชุดที่ใช้ได้ให้เอง

---

## วิธีรัน

### lab เดียว

```bat
cd questa_gls_vhdl_lab\lab05_rtl_vs_gate
run.cmd
echo %ERRORLEVEL%
```

| รหัส | ความหมาย |
|---|---|
| `0` | ผ่าน (PASS) |
| `1` | ไม่ผ่าน (FAIL) |
| `2` | หาเครื่องมือหรือโฟลเดอร์ไม่เจอ |

### ทั้งชุด (regression)

```bat
cd questa_gls_vhdl_lab\lab08_gls_regression
regression.cmd
```

### ตรวจโค้ด VHDL ด้วย GHDL (ไม่ต้องมี ModelSim)

```bash
wsl -d Ubuntu -u root -- bash /mnt/c/Users/000148/Documents/MiniMax/eda-tools/questa_gls_vhdl_lab/tools/check_vhdl.sh
```

### สังเคราะห์ netlist ใหม่

```bash
wsl -d Ubuntu -u root -- bash /mnt/c/Users/000148/Documents/MiniMax/eda-tools/questa_gls_vhdl_lab/tools/synth/synth.sh
```

---

## โครงสร้างโฟลเดอร์

```text
questa_gls_vhdl_lab/
├── docs/                     คู่มือฉบับนี้ (Markdown / HTML / PDF)
├── tools/
│   ├── pick_tool.cmd          เลือกชุดติดตั้งที่ยังมี license ว่าง
│   ├── run_template.cmd       เทมเพลต run.cmd (จำลอง 1 ครั้ง)
│   ├── run_template_2step.cmd เทมเพลต run.cmd (จำลอง 2 ครั้ง)
│   ├── make-runners.ps1       สร้าง run.cmd ของทุก lab
│   ├── make-zip.ps1           สร้างไฟล์ ZIP
│   ├── build-docs.ps1         รวม Markdown -> HTML -> PDF
│   ├── gls_common.do          proc ช่วยเหลือร่วมกัน
│   ├── check_vhdl.sh          ตรวจ VHDL ด้วย GHDL (WSL)
│   ├── synth/synth.sh         VHDL -> Verilog -> gate netlist (WSL)
│   └── probe/probe_top.vhd    design จิ๋วสำหรับ license probe
├── rtl/                       RTL ภาษา VHDL  (cnt4, alu4, fsm_light, sr16)
├── tb/                        testbench VHDL ที่ใช้ร่วมกันทุก lab
├── netlist/                   gate netlist + Verilog กลาง + stat/log
├── cells/                     โมเดลเซลล์ + Liberty ของ SG13G2
├── lab01_rtl_baseline/        ... lab08_gls_regression/
└── lab08_gls_regression/results/   log + สรุปของทั้งชุด
```

> `rtl/`, `tb/`, `netlist/`, `cells/` อยู่ระดับเดียวกัน และแต่ละ lab อ้างถึงด้วยพาธแบบสัมพัทธ์
> ทำให้ **testbench ชุดเดียวกันถูกใช้ได้ทั้งระดับ RTL และระดับ gate**

---

## แผนผัง 8 lab

| Lab | ชื่อโฟลเดอร์ | สิ่งที่พิสูจน์ |
|---|---|---|
| 01 | `lab01_rtl_baseline` | จุดอ้างอิงระดับ RTL — testbench ต้องเขียนด้วย `component` |
| 02 | `lab02_synth_netlist` | netlist ถูกต้อง / เซลล์ทุกตัวมีอยู่จริงในไลบรารี |
| 03 | `lab03_cell_library` | ไลบรารี 84 เซลล์ แบ่งเป็น 5 กลุ่ม (อ่านจาก `// type:`) |
| 04 | `lab04_gls_first` | GLS ครั้งแรก + `run_wrong.cmd` ให้ดู error จริง (`vsim-3033`) |
| 05 | `lab05_rtl_vs_gate` | trace สองระดับต้องเหมือนกันทุกบรรทัด |
| 06 | `lab06_x_propagation` | RTL กลืน `x` แต่ gate level จับได้ |
| 07 | `lab07_netlist_bug` | GLS จับบั๊กใน netlist ที่ RTL มองไม่เห็น |
| 08 | `lab08_gls_regression` | regression ทั้งชุด + อีก 3 ดีไซน์ (alu4, fsm_light, sr16) |

---

## ข้อควรรู้ (สรุปจากบทเรียนที่เจอจริง)

1. **ต้องใส่ `-t 10ps` ในทุกคำสั่ง `vsim`** ที่โหลด gate netlist
   ไม่งั้นได้ `vsim-3693` — เพราะเซลล์ใช้ `` `timescale 1ns/10ps ``
2. **ประกาศ DUT เป็น `component` ไม่ใช่ `entity work.xxx`**
   แล้ว ModelSim จะ default-bind เข้ากับ entity หรือ module ที่ชื่อตรงกันใน `work`
3. **ชื่อ entity/module และชื่อ port ต้องตรงกันทุกตัวอักษร**
   GHDL แปลงชื่อ port ของ VHDL เป็นตัวพิมพ์เล็กเสมอ
4. **ModelSim session เดียวจำลองได้ครั้งเดียว** (เมื่อ TB จบด้วย `std.env.finish`)
   ให้แยกเป็นสอง process
5. **`vsim` คืน exit code 0 แม้ล้มเหลว** — ให้อ่าน verdict จากไฟล์เสมอ
6. **อย่าจำแนกเซลล์จากชื่อ** ให้อ่านคอมเมนต์ `// type:` ในไฟล์เซลล์
7. **VHDL กับ Verilog มี semantics ของ `x` ต่างกัน**
   `'X' = '1'` → false ใน VHDL แต่ `?:` propagate `x` ใน Verilog
8. **Tcl: ห้ามใช้ `"\s"` ใน double quotes** ให้ใช้ `{...}` หรือ `format {...}`
9. **`.cmd` ต้องเป็น ASCII ล้วน** ข้อความไทย/UTF-8 ทำให้ `cmd.exe` อ่านผิดโครงสร้างบรรทัด
10. **VHDL: `signal clk` ต้องมี `:= '0'`** ไม่งั้นนาฬิกาเป็น `'U'` และไม่เดิน

รายละเอียดทั้งหมดอยู่ในคู่มือ (ภาคผนวก B และ D)

---

## คู่มือ

| ไฟล์ | ขนาด |
|---|---|
| `docs/Lab_Guide_QuestaSim_GLS.md` | 116,182 bytes |
| `docs/Lab_Guide_QuestaSim_GLS.html` | 229,124 bytes |
| `docs/Lab_Guide_QuestaSim_GLS.pdf` | 1,895,866 bytes (62 หน้า) |

สร้างใหม่ได้ด้วย

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build-docs.ps1
```

---

## ใบอนุญาตและเครดิต

- โค้ด RTL, testbench, สคริปต์ และคู่มือของโปรเจกต์นี้เขียนขึ้นใหม่ทั้งหมด
- ไฟล์เซลล์ `cells/sg13g2_stdcell.v`, `cells/sg13g2_udp.v` และไฟล์ Liberty
  เป็นของ **IHP PDK Authors** แบบ **Apache License 2.0**
  (มีหัวข้อลิขสิทธิ์อยู่ในไฟล์ต้นฉบับ)
