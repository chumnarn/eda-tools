# คู่มือปฏิบัติการ QuestaSim: การจำลองด้วย VHDL

### ตั้งแต่พื้นฐานจนถึงขั้นสูง — แบบ Lab แบบทีละขั้น

> **ทุกตัวเลขและข้อความในคู่มือนี้มาจากการรันจริงบนเครื่อง Windows**
> ด้วย ModelSim DE-64 / QuestaSim **2026.1** (`vsim 2026.1 Simulator 2026.01 Jan 25 2026`)
> ไม่ใช่ตัวอย่างที่แต่งขึ้น — ทำซ้ำตามคู่มือแล้วจะได้ผลชุดเดียวกัน
> รวมถึงข้อความ error ที่ควรรู้ด้วย

---

## ภาคนำ

### คู่มือนี้เหมาะกับใคร

ผู้เรียน/ผู้ใช้งานที่ต้องการ **จำลองวงจรดิจิทัลที่เขียนด้วย VHDL** บน QuestaSim
ตั้งแต่ยังไม่เคยเปิดเครื่องมือเลย จนถึงขั้นที่ต้องทำระบบตรวจสอบอัตโนมัติ
(code coverage, PSL assertion, regression) เพื่อปล่อยซิปสำหรับชิป

### สิ่งที่คุณจะได้หลังจบคู่มือนี้

| ความสามารถ | Lab ที่เกี่ยวข้อง |
|---|---|
| คอมไพล์/โหลด/จำลอง VHDL ทั้งแบบ GUI และแบบ batch | 01 |
| จัดการ design library หลายชุด และอ้างอิงข้ามไลบรารี | 02 |
| เขียน testbench ที่ตรวจตัวเองและส่งสัญญาณ PASS/FAIL ให้ CI | 03 |
| อ่าน waveform, วัดเวลา, ส่งออก WLF/VCD | 04 |
| หาบั๊กด้วย breakpoint, step, examine | 05 |
| หาที่มาของค่า X (Unknown) | 06 |
| ตรวจ/โหลด/บันทึกหน่วยความจำ (RAM) | 07 |
| สร้างสติมูลัสจากไฟล์, สุ่มแบบสุ่ม, ปรับค่าผ่าน generic | 08 |
| เขียน property assertion ด้วย PSL | 09 |
| วัด code coverage ของ DUT ที่เขียนด้วย VHDL | 10 |
| ทำ regression และสรุปผลอัตโนมัติ | 11 |

### วิธีใช้คู่มือนี้

1. อ่าน **บทที่ 1** (เตรียมเครื่องมือ) ก่อนเสมอ
2. ทำ lab ตามลำดับ 01 → 11 แต่ละ lab ใช้เวลาไม่นาน
3. ทุก lab มี 2 วิธีรัน:
   - **แบบ GUI** — เปิด QuestaSim แล้วทำตามขั้นตอนที่ระบุ (เห็นภาพจริง)
   - **แบบ batch** — พิมพ์ `run.cmd` ในหน้าต่างพร้อม (ใช้กับ CI ได้)
4. ทุก lab มีส่วน **“แบบฝึกหัด”** ปิดท้าย — ลองทำเองก่อนดูเฉลย

> **ข้อควรรู้เรื่องภาษา**
> ข้อความที่เครื่องมือพิมพ์ออกมา (ใน Transcript, ในข้อความ error) เป็น **ภาษาอังกฤษ**
> เพราะทั้ง ModelSim และ QuestaSim เขียน log ตาม code page ของ console
> ถ้าใส่ภาษาไทยลงในข้อความที่เครื่องมือพิมพ์ จะเห็นเป็นตัวยึก
> ส่วน **คำอธิบายในคู่มือฉบับนี้เป็นภาษาไทยทั้งหมด**

---

## บทที่ 1 — เตรียมเครื่องมือ

### 1.1 เครื่องมือที่ใช้

คู่มือนี้เขียนและทดสอบกับชุดติดตั้งสองชุดที่อยู่ในเครื่องนี้

| ชุดติดตั้ง | ตำแหน่ง | หมายเหตุ |
|---|---|---|
| Questa Sim-64 2026.1 | `C:\Siemens\questasim64_2026.1\win64` | ชุดเต็ม ใช้กับ GUI (คือ `vish.exe`) |
| ModelSim DE-64 2026.1 | `C:\Siemens\modelsim_dlx64_2026.1\win64pe` | ชุดที่ใช้รันแบบ batch ในคู่มือนี้ |

ทั้งสองชุดเป็น **โค้ดเดียวกันเวอร์ชัน 2026.1** คำสั่ง `vlib / vmap / vcom / vsim / vcover`
ที่ใช้ในคู่มือนี้ใช้ได้ทั้งสองชุดอย่างเหมือนกันทุกประการ

ตรวจสอบเวอร์ชันได้ด้วย

```bat
"C:\Siemens\questasim64_2026.1\win64\vsim.exe" -version
:: Questa Sim-64 vsim 2026.1 Simulator 2026.01 Jan 25 2026

"C:\Siemens\modelsim_dlx64_2026.1\win64pe\vsim.exe" -version
:: Model Technology ModelSim DE-64 vsim 2026.1 Simulator 2026.01 Jan 25 2026
```

### 1.2 ⚠ เรื่องใบอนุญาต (license) — อ่านให้เข้าใจก่อนทำ lab

ใบอนุญาตของเครื่องนี้เป็น **node-locked แบบ session เดียว** ความหมายคือ
**เปิดจำลองได้ session เดียวต่อชุดติดตั้ง** ถ้ามี GUI เปิดค้างไว้
การรันแบบบรรทัดคำสั่งจะถูกปฏิเสธด้วยข้อความ

```text
** Error: License checkout has been disallowed because
only one session is allowed to run on an uncounted nodelocked
license and an instance of QuestaSim is already running with a
nodelocked license on this machine.
```

**วิธีแก้**

| สถานการณ์ | ทำอย่างไร |
|---|---|
| ต้องการรันแบบ batch / CI | ใช้ชุด ModelSim DE-64 (ใช้งานพร้อมกับ QuestaSim GUI ได้) |
| ต้องการใช้ QuestaSim แบบ CLI | **ปิด QuestaSim GUI ก่อน** แล้วค่อยรัน |
| อยากให้สคริปต์จัดการเอง | ไฟล์ `run.cmd` ของทุก lab มี “license probe” ที่ลองไล่หา
ชุดติดตั้งที่ใช้ได้จริงให้เอง (ดูหัวข้อ 1.4) |

> **ข้อสังเกตที่วัดได้จริง**
> คำสั่ง `vsim -c -do "quit -f"` **ไม่** ดึง license — ต้อง **โหลด design** จึงเช็ค license
> ดังนั้นการทดสอบว่า license ว่างไหม ต้องคอมไพล์แล้วโหลด design จริง

### 1.3 โครงสร้างโฟลเดอร์ของคู่มือ

```text
questa_vhdl_lab/
├── docs/                     คู่มือฉบับนี้ (Markdown / HTML / PDF)
├── tools/
│   ├── pick_tool.cmd           เลือกชุดติดตั้งที่ยังมี license ว่าง (ใช้ร่วมกันทุก lab)
│   ├── run_template.cmd       เทมเพลตสคริปต์รันของทุก lab
│   ├── make-runners.ps1       ตัวสร้าง run.cmd ของทุก lab
│   ├── build-docs.ps1         รวม Markdown แล้วสร้าง HTML + PDF
│   └── probe/probe_top.vhd    design จิ๋วสำหรับ license probe
├── lab01_first_simulation/    ครั้งแรก: compile / load / run
├── lab02_libraries/           design library และการอ้างอิงข้ามไลบรารี
├── lab03_selfchecking_tb/     testbench แบบตรวจตัวเอง
├── lab04_waveform/            waveform, WLF, VCD
├── lab05_debugging/           breakpoint / step / examine
├── lab06_dataflow/            ตามหาต้นเหตุของค่า X
├── lab07_memory/              RAM และคำสั่ง mem
├── lab08_stimulus/            สติมูลัสจากไฟล์ / สุ่ม / generic
├── lab09_psl/                 PSL assertion
├── lab10_coverage/            code coverage ของ VHDL
└── lab11_regression/          regression และสรุปผล
```

ภายในแต่ละ lab โครงสร้างเหมือนกันหมด

```text
labNN_xxx/
├── src/        ไฟล์ DUT (design ที่ถูกทดสอบ)
├── tb/         ไฟล์ testbench
├── run.do      สคริปต์สำหรับใช้ใน GUI
├── run_batch.do สคริปต์สำหรับรันแบบ batch (ไม่มี GUI)
├── run.cmd     ตัวรันแบบ Windows (เลือกเครื่องมือ + ตัดสิน PASS/FAIL)
└── results/    ผลลัพธ์ที่ได้จากการรัน
```

### 1.4 สคริปต์ `run.cmd` ทำอะไรบ้าง

`run.cmd` ของทุก lab สร้างจากเทมเพลตเดียวกัน (`tools/run_template.cmd`) มี 4 ขั้นตอน

1. **หาเครื่องมือ** — เรียก `tools/pick_tool.cmd` ซึ่งไล่จาก `QUESTASIM_HOME` → `MODELSIM_HOME`
   → path ที่ติดตั้งไว้ แล้วทดสอบด้วย license probe จริง (คอมไพล์ + โหลด design จิ๋ว)
   เพื่อเลือกชุดติดตั้งที่ license ว่างจริงในเวลานั้น
2. **เข้าโฟลเดอร์ของ lab** (`cd /d "%~dp0"`) เพื่อให้สคริปต์ `.do` หาไฟล์เจอ
3. **รัน** `vsim -c -onfinish stop -do "do run_batch.do"`
4. **ตัดสินผล** — อ่านไฟล์ `result.txt` ที่ testbench เขียนไว้ แล้วคืนรหัสจบการทำงาน

| รหัสจบ | ความหมาย |
|---|---|
| `0` | ผ่าน (PASS) |
| `1` | ไม่ผ่าน (FAIL) |
| `2` | หาเครื่องมือหรือโฟลเดอร์ไม่เจอ |
| `90` | เครื่องมือล้มเหลวระหว่างทำงาน (คอมไพล์ไม่ผ่าน ฯลฯ) |

> **ทำไมต้องอ่าน `result.txt` แทนที่จะเชื่อ exit code ของ `vsim` ?**
> เพราะ `vsim` คืนค่า `0` แม้แต่จะ **เปิดไฟล์ `.do` ไม่ได้** เลย
> (เห็นข้อความ `Cannot open macro file: ...` แล้วจบด้วยรหัส 0)
> การอ่านไฟล์ผลลัพธ์ที่ testbench เขียนเองจึงเป็นวิธีที่เชื่อถือได้จริง

### 1.5 คำสั่งพื้นฐานที่ใช้บ่อย

| คำสั่ง | หน้าที่ |
|---|---|
| `vlib <path>` | สร้างไลบรารีจริง (โฟลเดอร์ที่เก็บ design unit ที่คอมไพล์แล้ว) |
| `vmap <ชื่อ> <path>` | ผูก “ชื่อเชิงตรรกะ” ของไลบรารีเข้ากับโฟลเดอร์จริง แล้วบันทึกใน `modelsim.ini` |
| `vcom -2008 <file.vhd>` | คอมไพล์ VHDL (ใช้มาตรฐาน VHDL-2008) |
| `vsim <lib>.<entity>` | โหลด design เข้าจำลอง (ทำให้เกิดการ “optimize”) |
| `run -all` | รันจำลองจนจบการจำลอง |
| `run <เวลา>` | รันจำลองเป็นเวลาที่กำหนด เช่น `run 500 ns` |
| `quit -code <n>` | จบการทำงานพร้อมรหัสจบ (สำคัญมากสำหรับ CI) |
| `add wave -r /*` | เพิ่มสัญญาณทั้งหมดเข้าหน้าต่าง Wave |
| `examine -radix hex <path>` | ดูค่าปัจจุบันของสัญญาณ |
| `bp <file> <บรรทัด>` | ตั้ง breakpoint |
| `log -recursive /*` | บันทึกทุกสัญญาณลงไฟล์ WLF |

---

## LAB 01 — การจำลองครั้งแรก

### เป้าหมาย

คอมไพล์ DUT + testbench ของ VHDL แล้วจำลองออกมาเป็นรูปคลื่น
ทั้งแบบที่ “มองเห็น” (GUI) และแบบที่ “ตรวจอัตโนมัติ” (batch)

### ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | หน้าที่ |
|---|---|
| `src/counter.vhd` | DUT — ตัวนับขึ้น/ลง 8 บิต มี enable และ reset |
| `tb/tb_counter.vhd` | testbench — สร้างนาฬิกา ป้อนสติมูลัส และ monitor ค่า |

### ขั้นตอน — แบบ GUI

**ขั้นที่ 1 : เปิด QuestaSim และเข้าโฟลเดอร์ของ lab**

ที่เมนู `File > Change Directory...` เลือกโฟลเดอร์ `lab01_first_simulation`
(สำคัญมาก — สคริปต์ทั้งหมดอ้างอิงไฟล์แบบสัมพัทธ์)

**ขั้นที่ 2 : สร้าง work library**

พิมพ์ที่ prompt ในหน้าต่าง Transcript

```tcl
vlib work
vmap work work
```

ผลลัพธ์ที่จะเห็น

```text
# Model Technology ModelSim DE-64 vmap 2026.1 Lib Mapping Utility 2026.01 Jan 25 2026
# vmap work work
# Copying C:/Siemens/modelsim_dlx64_2026.1/win64pe/../modelsim.ini to modelsim.ini
# Modifying modelsim.ini
```

> `vlib` สร้างโฟลเดอร์ `work` ส่วน `vmap` เป็นการ **ผูกชื่อ** `work` เข้ากับโฟลเดอร์นั้น
> แล้วบันทึกการผูกไว้ในไฟล์ `modelsim.ini`
> ถ้าไม่ `vmap` ไลบรารีจะ “มองไม่เห็น” และคอมไพล์ไม่ได้

**ขั้นที่ 3 : คอมไพล์**

```tcl
vcom -2008 src/counter.vhd
vcom -2008 tb/tb_counter.vhd
```

> **ทำไมต้องใส่ `-2008` ?**
> `std.env.finish` (ที่ testbench ใช้จบการจำลอง) เป็นของใหม่ใน VHDL-2008
> ค่าเริ่มต้นของ `vcom` คือ VHDL-93 ซึ่งไม่รู้จักแพ็กเกจนี้

**ขั้นที่ 4 : โหลด design**

```tcl
vsim work.tb_counter
```

สังเกตว่าข้อความจะบอกว่าโหลดอะไรบ้าง

```text
# Loading std.standard
# Loading std.textio(body)
# Loading ieee.std_logic_1164(body)
# Loading ieee.numeric_std(body)
# Loading std.env(body)
# Loading work.tb_counter(sim)
# Loading work.counter(rtl)
```

**ขั้นที่ 5 : เปิดหน้าต่าง Wave แล้วรัน**

```tcl
add wave -r /tb_counter/*
run -all
```

### ขั้นตอน — แบบ batch

```bat
cd questa_vhdl_lab\lab01_first_simulation
run.cmd
```

ผลลัพธ์จริง (ตัดเฉพาะส่วนสำคัญ)

```text
====================================================================
 LAB 01 : first simulation
 cwd    : C:\...\questa_vhdl_lab\lab01_first_simulation
 tool   : C:\Siemens\modelsim_dlx64_2026.1\win64pe
====================================================================
# ** Note: tb_counter : start
# ** Note:   [mon] t=0 ns cnt = 00
# ** Note: tb_counter : reset released, cnt = 00
# ** Note:   [mon] t=35 ns cnt = 01
# ** Note:   [mon] t=45 ns cnt = 02
# ** Note:   [mon] t=55 ns cnt = 03
# ** Note:   [mon] t=65 ns cnt = 04
# ** Note:   [mon] t=75 ns cnt = 05
# ** Note: tb_counter : after 5 counts up, cnt = 05
# ** Note: tb_counter : while disabled, cnt = 05
# ** Note:   [mon] t=115 ns cnt = 04
# ** Note:   [mon] t=125 ns cnt = 03
# ** Note: tb_counter : after 2 counts down, cnt = 03
# ** Note: TEST_PASSED : tb_counter completed
RESULT: PASS
[RESULT] PASS
```

รหัสจบของโปรเซส `cmd.exe` = `0`

### สิ่งที่ควรรู้จาก Lab นี้

**1. นาฬิกาต้องถูก “เริ่มต้น” เสมอ**

```vhdl
signal clk : std_logic := '0';       -- ต้องมีค่าเริ่มต้น
clk <= not clk after CLK_PERIOD / 2;
```

ถ้าไม่ใส่ `:= '0'` สัญญาณจะเริ่มเป็น `'U'` และ `not 'U'` ก็ยังเป็น `'U'`
นาฬิกาจะ **ไม่มีวัน toggle** และการจำลองจะ “เงียบ ๆ” ทำงานผิด

**2. `add wave -r /*` ใช้ในโหมด console ไม่ได้**

ถ้ารัน `vsim -c` (โหมดไม่มี GUI) คำสั่งนี้จะ error
คู่มือนี้จึงห่อด้วย `if {[catch {add wave -r /*} err]} { ... }` ในสคริปต์ `.do`

**3. `run -all` ใช้เวลานานมากได้**

ค่าเริ่มต้นของการรันใน GUI คือ 100 ns ถ้าต้องการนานกว่านั้นให้พิมพ์ `run 500 ns`

### แบบฝึกหัด

1. เปลี่ยน `WIDTH` ใน generic ของ `counter.vhd` เป็น 4 แล้วรันใหม่ ดูว่า waveform เปลี่ยนอย่างไร
2. แก้ `CLK_PERIOD` เป็น `20 ns` แล้วดูว่าระยะห่างระหว่างขอบขึ้นใน waveform เปลี่ยนไปเท่าไร
3. ลบ `:= '0'` ออกจาก `signal clk` แล้วรัน — อธิบายว่าทำไมจำลองไม่เดิน

---

## LAB 02 — Design library และการอ้างอิงข้ามไลบรารี

### เป้าหมาย

เรียนรู้ว่า “ไลบรารี” คืออะไร, `vlib` กับ `vmap` ต่างกันอย่างไร
และ **วิธีเรียกใช้ design unit ที่อยู่คนละไลบรารี**

### ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | ไลบรารีปลายทาง | หน้าที่ |
|---|---|---|
| `src/adder_pkg.vhd` | `work` | package — มีฟังก์ชัน `parity` และ `to_hex` |
| `src/ip_core.vhd` | `ip_lib` | entity — ตัวนับที่ทำหน้าที่เป็น “IP core” |
| `src/counter_top.vhd` | `work` | top ที่เรียกทั้งสองอย่าง |
| `tb/tb_libraries.vhd` | `work` | testbench |

### ขั้นตอน

**ขั้นที่ 1 : สร้างไลบรารีสองชุด**

```tcl
vlib work
vmap work work
vlib lib/ip_lib
vmap ip_lib lib/ip_lib
```

**ขั้นที่ 2 : คอมไพล์แยกตามไลบรารี**

```tcl
vcom -2008 -work work   src/adder_pkg.vhd
vcom -2008 -work ip_lib src/ip_core.vhd
vcom -2008 -work work   src/counter_top.vhd
vcom -2008 -work work   tb/tb_libraries.vhd
```

**ขั้นที่ 3 : ตรวจว่ามีอะไรอยู่ในไลบรารี**

```tcl
vdir -lib ip_lib
```

ผลลัพธ์จริง

```text
# Loading ip_lib.ip_core(rtl)
```

**ขั้นที่ 4 : โหลดและรัน**

```tcl
vsim work.tb_libraries
run -all
```

ผลลัพธ์จริง

```text
# ** Note: ==============================================
# ** Note:  adder_pkg version = 1.0.0
# ** Note: ==============================================
# ** Note:   [mon] t=0 ns value=00 parity='0'
# ** Note:   [mon] t=25 ns value=01 parity='1'
# ** Note:   [mon] t=45 ns value=03 parity='0'
# ** Note:   [mon] t=55 ns value=04 parity='1'
# ** Note:   [mon] t=65 ns value=05 parity='0'
# ** Note: value  = 06
# ** Note: parity = '0'
# ** Note: TEST_PASSED : lab02_libraries
```

สังเกตว่า transcript จะแสดง `Loading ip_lib.ip_core(rtl)` — ตัวจำลองหา
design unit จากไลบรารี `ip_lib` ที่ผูกไว้ใน `modelsim.ini` เจอโดยอัตโนมัติ

### สิ่งที่ควรรู้จาก Lab นี้

**1. `use` clause เลือกได้เฉพาะ PACKAGE**

เขียนแบบนี้ **ผิด**:

```vhdl
use ip_lib.ip_core.all;      -- ** Error: 'ip_core' is not a library or a package.
```

**2. ชื่อไลบรารีต้องประกาศด้วย `library` clause ก่อน**

เขียนแบบนี้ก็ **ผิดเช่นกัน**:

```vhdl
core : entity ip_lib.ip_core      -- ** Error: (vcom-1136) Unknown identifier "ip_lib".
```

ทางที่ถูกต้องคือ **ประกาศไลบรารีใน context** แล้วเรียกแบบ direct entity instantiation

```vhdl
library ip_lib;                  -- <<< บรรทัดนี้สำคัญ
...
core : entity ip_lib.ip_core
  generic map (WIDTH => WIDTH)
  port map (clk => clk, rst => rst, en => en, value => core_val);
```

**3. ห้ามลบ `modelsim.ini` ระหว่าง session**

ถ้าสคริปต์ `.do` สั่ง `file delete -force modelsim.ini` ตัวจำลองที่โหลดไฟล์นี้ไว้
ตั้งแต่ตอนเริ่มจะหาไฟล์ไม่เจอ แล้ว **คอมไพล์ที่อ้างไลบรารีอื่นจะ error**
ให้ `vmap` เป็นคนสร้าง/แก้ไฟล์นี้แทน

**4. package ข้ามไลบรารีก็ทำได้**

```vhdl
use work.adder_pkg.all;          -- package อยู่ใน work
```

### แบบฝึกหัด

1. สร้างไลบรารีชุดที่สามชื่อ `util_lib` แล้วย้าย `adder_pkg` ไปไว้ที่นั่น
   (ต้องแก้ `library util_lib; use util_lib.adder_pkg.all;` ในไฟล์ที่อ้างถึง)
2. ตั้งใจลบบรรทัด `library ip_lib;` ออกจาก `counter_top.vhd` แล้วคอมไพล์
   จะเห็นข้อความ error อะไร

---

## LAB 03 — Testbench แบบตรวจตัวเอง (self-checking)

### เป้าหมาย

เขียน testbench ที่ **ตรวจคำตอบด้วยตัวเอง** และรายงานผลให้ระบบอัตโนมัติตัดสินได้
พร้อมเรียนรู้ severity level ของ `assert` และจังหวะการตรวจที่ถูกต้องสำหรับ FSM

### ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | หน้าที่ |
|---|---|
| `src/fsm_timer.vhd` | DUT — FSM ตัวจับเวลา (IDLE → RUN → DONE) เอาต์พุตแบบ Moore |
| `tb/tb_timer.vhd` | testbench ที่ตรวจตัวเอง มี generic `INJECT_ERROR` |

### ขั้นตอน

**ขั้นที่ 1 : คอมไพล์และรัน**

```tcl
vlib work
vmap work work
vcom -2008 src/fsm_timer.vhd
vcom -2008 tb/tb_timer.vhd
vsim work.tb_timer
run -all
```

**ขั้นที่ 2 : ดูผลสรุป**

```text
# ** Note: --------------------------------------------------
# ** Note:  checks = 7 , errors = 0
# ** Note: --------------------------------------------------
# ** Note: TEST_PASSED : lab03_selfchecking_tb
```

**ขั้นที่ 3 : จงใจให้มันพัง เพื่อดูว่า “ไม่ผ่าน” หน้าตาเป็นอย่างไร**

```bat
run_fail.cmd
```

ผลลัพธ์จริง (ที่วัดได้)

```text
# ** Note: --------------------------------------------------
# ** Note:  tb_timer : start
# ** Note: --------------------------------------------------
# ** Failure: FAIL: injected error (INJECT_ERROR = true)
# Stopped at tb/tb_timer.vhd line 126
RESULT: FAIL
[RESULT] FAIL as expected -- exit=1
```

สังเกตว่า **ไม่มีบรรทัดสรุป `checks = ...` เลย**
เพราะ `severity failure` หยุด process ตรงนั้น
บรรทัดสรุปผลซึ่งอยู่ถัดไปจึงไม่ได้ทำงาน
(ทำให้ testbench ต้องเขียน `result.txt` = `FAIL` **ก่อน** `assert` — ดูโค้ดใน `tb/tb_timer.vhd`)

รหัสจบของ `cmd.exe` = `1` ตามที่ตั้งใจไว้

### สิ่งที่ควรรู้จาก Lab นี้

**1. severity ของ `assert`**

| severity | ผลต่อการจำลอง | ใช้เมื่อ |
|---|---|---|
| `note` | พิมพ์ข้อความ ไม่หยุด | ข้อมูลประกอบ |
| `warning` | พิมพ์ข้อความ ไม่หยุด | เตือนที่ยังไม่ผิดจริง |
| `error` | พิมพ์ข้อความ **หยุดการจำลอง** | ตรวจไม่ผ่าน |
| `failure` | พิมพ์ข้อความ **หยุดการจำลอง** | ผิดร้ายแรง ต้องแก้ |

**2. Moore output ต้องตรวจ “หลัง” ขอบขึ้น 1 ns**

เอาต์พุตแบบ Moore ลงทะเบียนแล้ว ค่าจึงเปลี่ยน **หลัง** ขอบขึ้นเสียงไปเล็กน้อย
ถ้าตรวจทันทีที่ขอบขึ้นจะเห็นค่าของรอบก่อนหน้า → ผลลัพธ์เพี้ยนทั้งชุด

```vhdl
wait until rising_edge(clk);
wait for 1 ns;                 -- <<< จุดนี้สำคัญ
assert cnt = exp_cnt report "..." severity error;
```

ถ้าใช้ **Mealy** (เอาต์พุตเป็น combinational) ต้องตรวจ **ที่** ขอบขึ้นเลย
เพราะค่าจะเปลี่ยนพร้อมกับขอบขึ้น ไม่งั้นจะพลาดพัลส์ 1 รอบที่ต้องการตรวจ

**3. นับ error ด้วย VARIABLE ไม่ใช่ signal**

```vhdl
variable errors : integer := 0;
...
if cnt /= exp_cnt then errors := errors + 1; end if;
```

ถ้าใช้ `signal` ค่าจะถูกอัปเดตท้าย delta cycle ตัวสรุปจะเห็นค่าคนละรอบ
(เช่นเห็น `N-1` แทน `N`)

**4. เขียนผลลงไฟล์ `result.txt` เอง**

```vhdl
procedure write_result(constant fname : in string; constant verdict : in string) is
  file f : text;
  variable l : line;
begin
  file_open(f, fname, write_mode);
  write(l, verdict);
  writeline(f, l);
  file_close(f);
end procedure write_result;
...
write_result("result.txt", "PASS");
```

> ข้อควรระวัง: `writeline` รับค่าเป็น `line` (access to string) **ไม่ใช่ string ธรรมดา**
> ต้อง `write(l, verdict)` แล้วค่อย `writeline(f, l)`
> ถ้าเขียน `writeline(f, verdict)` จะได้
> `** Error: (vcom-1600) No feasible entries for subprogram "WRITELINE".`

**5. `const` เป็นคำสงวนใน VHDL-2008**

```vhdl
procedure write_result(const fname : in string; ...)   -- ผิด ! ต้องใช้ constant
```

ใน VHDL-2008 คำว่า `const` ถูกสงวนไว้สำหรับ interface constant
ถ้าใช้ผิดจะได้ `** Error: near "fname": (vcom-1576) expecting ':'.`

**6. `std.env.finish` ต้องห่อด้วย `catch` ในสคริปต์**

```tcl
if {[catch {run -all} err]} {
    puts "---- simulation stopped by an assertion : $err ----"
}
```

ถ้าไม่ห่อ และ testbench หยุดด้วย `severity failure`
ModelSim จะ **รีสตาร์ทรายการคำสั่ง `-do` ตั้งแต่ต้น** ทำให้สคริปต์ถูกรันซ้ำ

### แบบฝึกหัด

1. เปลี่ยน `wait for 1 ns` เป็น `wait for 0 ns` แล้วรันซ้ำ ดูว่า error กี่ตัว
2. เพิ่มเคสตรวจที่ขอบขึ้นแรกหลัง reset (ว่า `cnt` ยังเป็น `00`)
3. เปลี่ยน `severity error` เป็น `severity warning` ใน testbench แล้วดูว่า
   การจำลองจะ “หยุด” หรือไม่

---

## LAB 04 — การวิเคราะห์ waveform

### เป้าหมาย

สร้าง waveform ที่ “อ่านเป็น” เรียนรู้การวัดเวลาด้วย cursor
และส่งออกผลลัพธ์เป็นไฟล์ WLF (native) และ VCD (มาตรฐาน) เพื่อนำไปใช้ต่อ

### ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | หน้าที่ |
|---|---|
| `src/clock_div.vhd` | DUT — ตัวหารความถี่นาฬิกา (`div_clk` เปลี่ยนสถานะทุก ๆ `DIV` รอบ) |
| `tb/tb_divider.vhd` | testbench พร้อม monitor จับเวลาขอบขึ้น |

### ขั้นตอน

**ขั้นที่ 1 : เตรียมหน้าต่าง Wave**

```tcl
vlib work
vmap work work
vcom -2008 src/clock_div.vhd
vcom -2008 tb/tb_divider.vhd
vsim work.tb_divider
add wave -r /*
run -all
```

**ขั้นที่ 2 : วัดความระยะห่างระหว่างขอบขึ้น**

ในหน้าต่าง Wave กดไอคอนเส้นประ (cursor) แล้วลากไปวางบนขอบขึ้นของ `div_clk`
สองครั้ง → ค่าในช่อง “Time Delta” จะเป็นคาบของสัญญาณ

ถ้าทำแบบ batch ให้ดูจากข้อความใน transcript ที่ monitor พิมพ์

```text
# ** Note:   [mon] t=65 ns div_clk rising #1
# ** Note:   [mon] t=145 ns div_clk rising #2
# ** Note:   [mon] t=225 ns div_clk rising #3
# ** Note:   [mon] t=305 ns div_clk rising #4
# ** Note:   [mon] t=385 ns div_clk rising #5
```

> คาบที่วัดได้ = 145 − 65 = **80 ns**
> ตรวจสอบด้วยทฤษฎี: คาบของ `div_clk` = 2 × `DIV` × คาบของ `clk`
> = 2 × 4 × 10 ns = **80 ns** ✔

**ขั้นที่ 3 : เปลี่ยนฐานแสดงผล (radix)**

```tcl
add wave -radix hex /tb_divider/*
```

**ขั้นที่ 4 : บันทึกเป็น WLF และ VCD**

ในสคริปต์ `run_batch.do` ของ lab นี้

```tcl
log -recursive /*                 -- บันทึกทุกสัญญาณเป็น vsim.wlf
vcd file results/waveform.vcd     -- เตรียมไฟล์ VCD   (ต้องทำก่อน run!)
vcd add -r /*                     -- เพิ่มสัญญาณที่จะส่งออก
run -all
vcd flush                         -- ปิดและเขียนไฟล์ให้เรียบร้อย
```

ผลลัพธ์จริง

```text
  vsim.wlf                              49152 bytes
  results/waveform.vcd                   3219 bytes
  created results\waveform_from_wlf.vcd
```

### สิ่งที่ควรรู้จาก Lab นี้

**1. ต้อง “เตรียม” VCD ก่อน `run` เสมอ**

ถ้าสั่ง `vcd add` หลัง `run -all` เสร็จแล้ว ไฟล์ VCD จะมีแต่ส่วนหัว
(ประกาศตัวแปร) **แต่ไม่มีค่าที่เปลี่ยนแปลงเลย** ขนาดไฟล์จะเล็กกว่าเดิมมาก

| สถานการณ์ | ขนาดไฟล์ที่ได้ |
|---|---|
| `vcd add` หลัง `run` | 1,310 bytes (มีแต่ header) |
| `vcd add` ก่อน `run` | **3,219 bytes** (มีค่าครบ) ✔ |

**2. แปลง WLF → VCD ต้องทำหลัง simulator ปิดตัวลง**

```bat
wlf2vcd vsim.wlf -o results\waveform_from_wlf.vcd
```

ถ้ารันคำสั่งนี้ **ระหว่าง** จำลอง จะได้

```text
** Error: Unable to open WLF file "vsim.wlf".
```

เพราะไฟล์ WLF ถูกล็อกไว้ระหว่างที่ simulator ยังทำงาน
คู่มือนี้จึงย้ายคำสั่งนี้ไปไว้ใน `run.cmd` หลัง `vsim` จบแล้ว

**3. เครื่องมือแปลงไฟล์ที่มีให้ใช้**

| เครื่องมือ | ทำอะไร |
|---|---|
| `wlf2vcd` | WLF → VCD |
| `vcd2wlf` | VCD → WLF |
| `vcd2qwave` | VCD → ไฟล์สำหรับ Questa Visualizer |

### แบบฝึกหัด

1. เปลี่ยน `DIV` เป็น 8 แล้วรันซ้ำ ตรวจว่าคาบที่วัดได้เป็น 160 ns
2. เพิ่มสัญญาณ `data_bus` (ที่เปลี่ยนทุกขอบขึ้นของ `div_clk`) แล้วหา cursor ที่ทำให้
   เห็นการเปลี่ยนแปลงของทั้งสองสัญญาณพร้อมกัน
3. เปิดไฟล์ `results/waveform.vcd` ด้วยโปรแกรมดู waveform ใด ๆ
   (เช่น GTKWave) แล้วเทียบกับหน้าต่าง Wave ของ QuestaSim

---

## LAB 05 — การ debug

### เป้าหมาย

หาบั๊กใน DUT ที่ “เขียนดูถูกต้อง” แต่ทำงานผิด ด้วยเครื่องมือ debug ของ QuestaSim

### ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | หน้าที่ |
|---|---|
| `src/alu.vhd` | DUT — ALU 8 บิต **มีบั๊กจริง 1 จุด** |
| `tb/tb_alu.vhd` | testbench ที่ป้อนเวกเตอร์ 4 ชุด |

### บั๊กที่ซ่อนอยู่

```vhdl
when "01" =>
  tmp := ('0' & unsigned(a)) + ('0' & unsigned(b));   -- <<< BUG : ต้องเป็น "-"
```

กรณี `op = "01"` คือการ “ลบ” แต่โค้ดกลับบวก

### ขั้นตอน

**ขั้นที่ 1 : รันแล้วดูว่าพัง**

```bat
run.cmd
```

ผลลัพธ์จริง

```text
# ** Note: PASS : op=0 got=0F
# ** Error: FAIL : op=1 a=0A b=05 expected=05 got=0F   [SUB exposes the bug]
# ** Note: PASS : op=2 got=30
# ** Note: PASS : op=3 got=FC
# ** Note:  checks = 4 , errors = 1
# ** Error: TEST FAILED : 1 error(s)
# Stopped at tb/tb_alu.vhd line 124
RESULT: FAIL
[RESULT] FAIL -- exit=1
```

สังเกตว่าเคสอื่น ๆ ผ่านหมด เพราะการ “เขียนเทสต์เยอะ” อย่างเดียวไม่พอ
ต้องรู้ด้วยว่าเคสไหนครอบคลุมพฤติกรรมของ DUT

รหัสจบของ `cmd.exe` = `1` — นี่คือผลที่ **ตั้งใจให้เป็นแดง**
(entry point ที่เป็น “เขียว” ของ lab นี้คือ `run_debug.cmd` ดูขั้นที่ 5)

**ขั้นที่ 2 : ตั้ง breakpoint**

```tcl
bp src/alu.vhd 36
```

> ต้องเป็น **บรรทัดที่ execute ได้จริง** (บรรทัดที่มีคำสั่ง)
> ถ้าตั้งผิดบรรทัดจะขึ้นว่า breakpoint ไม่ได้ถูกตั้ง

**ขั้นที่ 3 : รันจนกว่าจะติด**

```tcl
run -all
```

ผลลัพธ์จริง

```text
bp src/alu.vhd 36  ;# 1
# Break in Process comb at src/alu.vhd line 36
# Stopped at src/alu.vhd line 36
```

**ขั้นที่ 4 : ดูค่าของสัญญาณ**

```tcl
examine -radix hex -value /tb_alu/dut/a
examine -radix hex -value /tb_alu/dut/b
examine -radix hex -value /tb_alu/dut/op
examine -radix hex -value /tb_alu/dut/y
```

ผลลัพธ์จริง

```text
  a = 0A
  b = 05
  op = 1
  y = 0F
```

> `0A − 05` ควรเป็น `05` แต่ได้ `0F` ซึ่งคือ `0A + 05` → **ยืนยันว่าเป็นบั๊ก**
> `op = 1` แปลว่า `op` = `"01"` ในฐานสอง ✔

สคริปต์ `run_debug.cmd` ทำทั้งหมดนี้ให้อัตโนมัติและสรุปว่า

```text
BUG CONFIRMED : y = 0F but A - B should be 05
RESULT: PASS
```

### สิ่งที่ควรรู้จาก Lab นี้

**1. ในโหมด console ต้อง `puts` ค่าที่ `examine` คืนมาเอง**

```tcl
set v [examine -radix hex -value /tb_alu/dut/y]
puts "  y = $v"
```

ถ้าเรียก `examine` เปล่า ๆ ในโหมด `vsim -c` เอาต์พุตจะ **ไม่ถูกพิมพ์ออกมา**
(ในโหมด GUI จะไปโผล่ในหน้าต่าง Source Examine แทน)

**2. เวลาจำลองปัจจุบันอยู่ใน `$::now`**

```tcl
puts "---- simulation stopped at $::now ----"
```

ห้ามใช้ `[time]` เพราะจะชนกับคำสั่ง `time` ของ Tcl
(จะได้ `** Error: wrong # args: should be "time command ?count?"`)

**3. `force` / `release` ใช้กับสัญญาณ VHDL ได้**

```tcl
force /tb_alu/dut/op 01 -deposit
```

เหมาะกับการ “ยัดค่า” เข้าไปในสัญญาณเพื่อขับ design ให้เข้าเงื่อนไขที่ต้องการ

**4. คำสั่ง debug ที่ใช้บ่อย**

| คำสั่ง | หน้าที่ |
|---|---|
| `bp <file> <line>` | ตั้ง breakpoint |
| `bp` | แสดง breakpoint ทั้งหมด |
| `run -all` / `run -next` / `run -finish` | รันจนจบ / จนบรรทัดถัดไป / จนจบ process |
| `step` / `next` | เข้าไปใน process / ข้ามบรรทัด |
| `examine -radix hex -value <path>` | ดูค่า |
| `when <เงื่อนไข> {<คำสั่ง>}` | ตั้ง action ให้ทำงานเมื่อเงื่อนไขเป็นจริง |
| `force` / `release` | บังคับ/ปล่อยค่าของสัญญาณ |
| `restart` | เริ่มจำลองใหม่จากเวลา 0 |

### แบบฝึกหัด

1. แก้บั๊กใน `src/alu.vhd` ให้ถูกต้อง แล้วรัน `run.cmd` อีกครั้ง ต้องได้ PASS
2. ตั้ง breakpoint ที่ **บรรทัดของ testbench** (ไม่ใช่ของ DUT) แล้วใช้ `step` ดูว่า
   `errors` เปลี่ยนจาก 0 เป็น 1 ตรงจุดไหน
3. ใช้ `force` สั่งค่า `op` เป็น `"01"` ในขณะจำลอง แล้วดูว่า `y` เปลี่ยนอย่างไร

---

## LAB 06 — ตามหาต้นเหตุของค่า X (Unknown)

### เป้าหมาย

เข้าใจว่าค่า `X`/`U` เกิดมาอย่างไร ต่างกันอย่างไรระหว่าง “ปกติ” กับ “บั๊ก”
และเรียนรู้วิธีไล่หาต้นเหตุของ `X` ใน hierarchy

### ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | หน้าที่ |
|---|---|
| `src/x_demo.vhd` | DUT — มีทั้ง register ที่ไม่ init และสัญญาณที่ไม่เคยถูก assign |
| `tb/tb_x.vhd` | testbench ที่รายงานว่าสัญญาณใดเป็น X บ้าง |

### ขั้นตอน

**ขั้นที่ 1 : รันแล้วดูค่า**

```bat
run.cmd
```

ผลลัพธ์จริง

```text
# ** Note:  t=1ns (no reset yet) : sum = XXX  eq = '0'  eq2 = 'U'
# ** Note:    -> X here is NORMAL (register not initialised yet)
# ** Note:    -> eq  uses '=' so it stays '0' even with X
# ** Note:    -> eq2 uses xor so the X propagates
# ** Note:  after reset          : sum = 07A  eq = '0'
# ** Note:                         eq2 = 'U'
# ** Note:    -> eq2 is X forever : root cause is never_driven which is never assigned (this is the bug)
# ** Note:  errors = 0
  /tb_x/dut/acc = 46
  /tb_x/dut/never_driven = XX
  /tb_x/eq = 0
  /tb_x/eq2 = U
  /tb_x/sum = 07A
RESULT: PASS
```

**ขั้นที่ 2 : ไล่หาทีละชั้น**

```tcl
examine -radix hex -value /tb_x/dut/acc
examine -radix hex -value /tb_x/dut/never_driven
```

จะเห็นว่า `acc` กลับมาเป็นค่าที่รู้ (`46`) หลัง reset
แต่ `never_driven` เป็น `XX` **ตลอดการจำลอง** → นั่นคือต้นเหตุ

### สิ่งที่ควรรู้จาก Lab นี้

**1. `X` ตอนเวลา 0 ไม่ใช่บั๊ก**

register ที่ไม่มีค่าเริ่มต้นจะเริ่มเป็น `'U'` จนกว่าจะถูกเขียนครั้งแรก
หลัง reset ถ้ายังเป็น `X` อยู่ → มีปัญหาจริง

**2. `X` แพร่ผ่านตัวไหนบ้าง (วัดได้จริง)**

| ตัวดำเนินการ | ผลกับ X |
|---|---|
| `+` `-` `*` (numeric_std) | **แพร่ X** ✔ |
| `xor` `and` `or` `not` (bitwise) | **แพร่ X** ✔ |
| `=` `/=` (IEEE 1164) | **ไม่แพร่** — คืนค่า `FALSE` เมื่อ operand มี X ✘ |

นี่คือเหตุผลที่ `eq` (ที่ใช้ `=`) เป็น `'0'` แต่ `eq2` (ที่ใช้ `xor`) เป็น `'U'`
ถ้าเขียนโค้ดที่ “ตรวจความเท่ากัน” แล้วคาดหวังว่าจะได้ X เมื่อข้อมูลเพี้ยน
**จะไม่ได้ X** — ต้องใช้ bitwise หรือ `is_x()` ตรวจแทน

**3. ตรวจ X ด้วย `is_x()` (VHDL-2008)**

```vhdl
if is_x(sum) then
  report "FAIL: sum is still unknown after reset" severity error;
end if;
```

**4. ระดับของการไล่หา X**

```text
เอาต์พุตที่เป็น X
   ↓ ดูสัญญาณข��าบนใน hierarchy
สัญญาณต้นทาง
   ↓ ดูว่าถูก assign ที่ไหน
process / port
   ↓
สาเหตุ: ไม่มี reset / ไม่เคยถูก assign / อ่านค่าก่อนถูกเขียน
```

**5. เครื่องมือใน GUI**

- **Dataflow window** (`View > Dataflow`): แสดงแผนผังการไหลของข้อมูล
  คลิกที่สัญญาณที่เป็น X แล้วดูเส้นทางย้อนกลับไปยังต้นทาง
- **Source window**: คลิกชื่อสัญญาณแล้วเลือก `Examine` เพื่อดูค่า ณ เวลาที่ cursor อยู่
- **Objects window**: เห็นค่าปัจจุบันของสัญญาณทั้งหมดใน scope ที่เลือก

### แบบฝึกหัด

1. เพิ่ม signal `ghost` ใน `x_demo.vhd` ที่ประกาศแล้วไม่ assign เช่นเดียวกับ
   `never_driven` แล้วต่อเข้ากับ `eq2` — สังเกตว่าผลลัพธ์เปลี่ยนอย่างไร
2. เปลี่ยน `eq` ให้ใช้ `xor` แทน `=` แล้วรันซ้ำ — `eq` จะกลายเป็น `X` ตอน t=0 หรือไม่
3. ใส่ `rst` ที่ไม่มีเงื่อนไขใน `fsm_timer.vhd` ของ Lab 03 แล้วดูว่าเอาต์พุตจะเป็น X
   ตอนไหน

---

## LAB 07 — หน่วยความจำ (RAM) และคำสั่ง `mem`

### เป้าหมาย

เรียนรู้วิธี “มองเข้าไป” ในอาร์เรย์ของ VHDL จากภายนอก
โหลดค่าเริ่มต้นลงไปในหน่วยความจำ และค้นหาค่าที่ต้องการ

### ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | หน้าที่ |
|---|---|
| `src/ram.vhd` | DUT — RAM 256 × 8 บิต แบบ single port |
| `tb/tb_ram.vhd` | testbench — เขียนค่าแล้วอ่านกลับมาตรวจทั้ง 256 คำ |
| `mem_init.txt` | ไฟล์ค่าเริ่มต้นของหน่วยความจำ (256 คำ ฐานสิบหก) |

### ขั้นตอน

**ขั้นที่ 1 : คอมไพล์และโหลด**

```tcl
vlib work
vmap work work
vcom -2008 src/ram.vhd
vcom -2008 tb/tb_ram.vhd
vsim -voptargs=+acc work.tb_ram
```

**ขั้นที่ 2 : ดูว่ามีหน่วยความจำอะไรบ้างใน design**

```tcl
mem list -r
```

ผลลัพธ์จริง

```text
VHDL:    /tb_ram/dut/mem [0:255] x 8 w
VHDL:    /tb_ram/dut/ram_inst/mem [0:255] x 8 w
VHDL:    /tb_ram/stim/v_read [0:255] x 8 w
```

สังเกตว่า **1 ตัวแปรใน VHDL กลายเป็น 3 รายการ** ในรายการของตัวจำลอง
เพราะตัวจำลองมองเห็นทั้งตัวแปรที่ประกาศไว้ ตัวที่เกิดจากการแตกตัวของ signal
และตัวแปรภายในของ process ใน testbench

**ขั้นที่ 3 : โหลดค่าเริ่มต้นลงในหน่วยความจำ**

```tcl
mem load -format hex -infile mem_init.txt -startaddress 0 -endaddress 255 /tb_ram/dut/mem
```

> ทำก่อน `run` เสมอ — ค่าจะถูกเขียนลงหน่วยความจำที่เวลา 0

**ขั้นที่ 4 : ดูและค้นหาในหน่วยความจำ**

```tcl
mem display -dataradix hexadecimal -wordsperline 16 /tb_ram/dut/mem
```

ผลลัพธ์จริง (16 คำต่อบรรทัด)

```text
  0: 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 10
 16: 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F 20
 32: 21 22 23 24 25 26 27 28 29 2A 2B 2C 2D 2E 2F 30
 ...
208: D1 D2 D3 D4 D5 D6 D7 D8 D9 DA DB DC DD DE DF E0
```

เลขหน้าเป็น **ที่อยู่แบบฐานสิบ** ส่วนข้อมูลเป็นฐานสิบหก

ค้นหาค่า

```tcl
mem search -glob 3F /tb_ram/dut/mem
```

ผลลัพธ์จริง

```text
 62: 8'h3F
```

บันทึกออกมาเป็นไฟล์

```tcl
mem save -outfile mem_saved.txt -format hex /tb_ram/dut/mem
```

**ขั้นที่ 5 : รันและดูว่าหน่วยความจำเปลี่ยนไปอย่างไร**

```tcl
run -all
mem display -dataradix hexadecimal -wordsperline 16 /tb_ram/dut/mem
```

ผลลัพธ์จริง

```text
# ** Note: tb_ram : phase 1 checked 256 words, mismatches = 0
# ** Note: tb_ram : measured mem[0]=01 mem[1]=02 mem[10]=0B mem[62]=3F mem[254]=FF mem[255]=00
# ** Note: tb_ram : phase 2 wrote 17 words (0..15 and 255) and read them back
# ** Note: tb_ram : measured mem[0]=01 (still the loaded value), mem[255]=EE
# ** Note: TEST_PASSED : tb_ram memory checks completed
RESULT: PASS
```

สังเกตว่า `mem[255]` เปลี่ยนจาก `00` เป็น `EE` หลัง testbench เขียนทับ
แต่ `mem[0]` ยังเป็น `01` เพราะ testbench เขียนที่ address 255 เท่านั้น

### สิ่งที่ควรรู้จาก Lab นี้

**1. `mem` ใน 2026.1 ไม่มีคำสั่ง `mem export`**

คำสั่งที่มีจริงคือ

```text
mem compare   mem display   mem list   mem load   mem save   mem search
```

ต้องการ “ส่งออก” ให้ใช้ **`mem save`** แทน

**2. `mem save` ไม่คืนข้อความกลับมา**

คำสั่ง `mem save -outfile ...` เขียนไฟล์เรียบร้อย แต่คืนค่าว่าง
(ถ้าเก็บผลลัพธ์มา `puts` จะได้บรรทัดว่าง) — ต้องไปเปิดไฟล์ที่ได้แทน

**3. ⚠ `+acc` ไม่จำเป็นสำหรับหน่วยความจำที่เป็น VHDL array**

คู่มือนี้ทดสอบโดยรันแบบไม่ใส่ `-voptargs=+acc`
(`run_noacc.do` ในโฟลเดอร์ lab) ผลที่วัดได้

| รายการ | ผลเมื่อไม่ใส่ `+acc` |
|---|---|
| `mem list -r` | เห็นหน่วยความจำครบเหมือนกัน |
| `mem load` | ไม่มีข้อความ error |
| `mem display` | **ได้ข้อมูลเหมือนกันทุกบรรทัด** |
| `mem search` | ไม่มีข้อความ error |
| testbench อ่านค่ากลับ | ผ่าน 256/256 คำ |

ข้อสรุป: **สำหรับอาร์เรย์ของ VHDL คำสั่ง `mem` ทำงานได้โดยไม่ต้องใช้ `+acc`**
(ส่วน memory ของ Verilog มักต้องใช้) — แต่การใส่ `+acc` ไว้ก็ไม่เสียหาย
และช่วยให้เห็น signal ภายในทั้งหมดได้

**4. `mem list -r` ช่วยหา “ทาง” ไปยังหน่วยความจำ**

ถ้าไม่รู้ว่าหน่วยความจำอยู่ที่ไหน ให้ใช้ `mem list -r` ก่อน
แล้วค่อยใช้ path ที่ได้ (เช่น `/tb_ram/dut/mem`)

### แบบฝึกหัด

1. แก้ `mem_init.txt` ให้คำที่ 100 เป็น `AA` แล้วรัน `mem search -glob AA`
2. ใช้ `mem load -filldata 55 -filltype inc` โหลดค่าทั้งหน่วยความจำ
   แล้วดูด้วย `mem display` ว่าได้ค่าอะไร
3. ลอง `mem compare` ระหว่างหน่วยความจำสองตัวของ design ที่มีมากกว่าหนึ่ง instance

---

## LAB 08 — สติมูลัสขั้นสูง: จากไฟล์, แบบสุ่ม, และการปรับค่า

### เป้าหมาย

สร้างสติมูลัสที่ใกล้เคียงความจริง ด้วยสามวิธีที่ใช้จริงในงาน verification

1. **อ่านเวกเตอร์จากไฟล์** — ใช้ซ้ำชุดทดสอบเดิมได้
2. **สุ่มเอง** — ทดสอบกรณีที่คิดไม่ออก
3. **ปรับพารามิเตอร์** — ใช้ testbench ชุดเดียวทดสอบหลาย configuration

### ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | หน้าที่ |
|---|---|
| `src/ram8.vhd` | DUT — register file 16 × 8 บิต (ทางข้อมูลเป็น `bit_vector`) |
| `tb/tb_stimulus.vhd` | testbench — อ่านเวกเตอร์จากไฟล์ สุ่มค่า และเขียนผลลง `result.txt` |
| `tb/probe_uniform.vhd` | โปรแกรมเล็ก ๆ ที่โชว์ค่าจริงที่ `uniform` คืนมา |
| `vectors.txt` | ไฟล์เวกเตอร์ (ที่อยู่, ข้อมูล, ค่าที่คาดหวัง, คำสั่ง) |
| `run.cmd` / `run_batch.do` | ตัวรันแบบไม่มีหน้าต่าง |
| `run.do` | ตัวรันสำหรับใช้ในหน้าต่าง GUI |

### generic ของ testbench

| generic | ค่าเริ่มต้น | ความหมาย |
|---|---|---|
| `VECTOR_FILE` | `"vectors.txt"` | ชื่อไฟล์เวกเตอร์ |
| `NUM_RANDOM` | `8` | จำนวนเวกเตอร์สุ่ม |
| `SEED1` | `12345` | seed ตัวที่ 1 |
| `SEED2` | `67890` | seed ตัวที่ 2 |

### ขั้นตอน

**ขั้นที่ 1 : รัน**

```bat
run.cmd
```

`run.cmd` จะรัน **สองครั้ง** ในไฟล์เดียว

- ครั้งที่ 1 — ใช้ generic ที่กำหนดไว้ใน `run_batch.do`
  (`-gNUM_RANDOM=8 -gSEED1=12345 -gSEED2=67890`)
- ครั้งที่ 2 — ใช้ค่าจาก plusarg ที่ `run.cmd` ส่งเข้ามา
  (`+NUM_RANDOM=4 +SEED1=777 +SEED2=888`) โดยสคริปต์ Tcl แปลงกลับเป็น generic

**ขั้นที่ 2 : ดูผลลัพธ์ที่วัดได้จริง — ครั้งที่ 1 (generic)**

```text
** Note: tb_stimulus : parameters from the generics
** Note: tb_stimulus :   VECTOR_FILE = vectors.txt
** Note: tb_stimulus :   NUM_RANDOM  = 8
** Note: tb_stimulus :   SEED1       = 12345
** Note: tb_stimulus :   SEED2       = 67890
** Note: tb_stimulus : phase 1 - file based stimulus from vectors.txt
** Note: tb_stimulus : phase 1 read 32 vectors from 52 lines of the file
** Note: tb_stimulus : phase 2 - random stimulus with ieee.math_real.uniform
** Note: tb_stimulus : random vector 1 : A addr=15 data=233 | B addr=15 data=233
** Note: tb_stimulus : random vector 2 : A addr=2 data=132 | B addr=2 data=132
** Note: tb_stimulus : random vector 3 : A addr=6 data=188 | B addr=6 data=188
** Note: tb_stimulus : random vector 4 : A addr=1 data=87 | B addr=1 data=87
** Note: tb_stimulus : random vector 5 : A addr=0 data=51 | B addr=0 data=51
** Note: tb_stimulus : random vector 6 : A addr=13 data=244 | B addr=13 data=244
** Note: tb_stimulus : random vector 7 : A addr=4 data=95 | B addr=4 data=95
** Note: tb_stimulus : random vector 8 : A addr=0 data=239 | B addr=0 data=239
** Note: tb_stimulus : the same seed pair (12345,67890) reproduces the same sequence : true
** Note: tb_stimulus : file vectors : read=32 passed=32 failed=0
** Note: tb_stimulus : random vectors : count=8 passed=8 failed=0
** Note: TEST_PASSED : tb_stimulus completed
```

จบที่เวลา **246 ns** — อ่านเวกเตอร์จากไฟล์ได้ 32 จาก 52 บรรทัด
(อีก 20 บรรทัดเป็นบรรทัดอธิบายที่ขึ้นต้นด้วย `#` ซึ่ง `hread` อ่านไม่ได้แล้วข้ามไป)

**ขั้นที่ 3 : ดูผลลัพธ์ที่วัดได้จริง — ครั้งที่ 2 (plusarg → generic)**

```text
plusarg found : +NUM_RANDOM=4   ->   passed to VHDL as -gNUM_RANDOM=4
plusarg found : +SEED1=777   ->   passed to VHDL as -gSEED1=777
plusarg found : +SEED2=888   ->   passed to VHDL as -gSEED2=888
--- second run, parameterised by the plusargs ---
** Note: tb_stimulus : phase 1 read 32 vectors from 52 lines of the file
** Note: tb_stimulus : random vector 1 : A addr=0 data=157 | B addr=0 data=157
** Note: tb_stimulus : random vector 2 : A addr=6 data=11 | B addr=6 data=11
** Note: tb_stimulus : random vector 3 : A addr=15 data=161 | B addr=15 data=161
** Note: tb_stimulus : random vector 4 : A addr=12 data=162 | B addr=12 data=162
** Note: tb_stimulus : the same seed pair (777,888) reproduces the same sequence : true
** Note: tb_stimulus : file vectors : read=32 passed=32 failed=0
** Note: tb_stimulus : random vectors : count=4 passed=4 failed=0
** Note: TEST_PASSED : tb_stimulus completed
```

จบที่เวลา **206 ns** (สั้นลงเพราะสุ่มแค่ 4 เวกเตอร์แทน 8)

สรุปตัวเลขที่วัดได้จริง

| รอบ | วิธีกำหนดค่า | เวกเตอร์จากไฟล์ | สุ่มได้ | ผ่าน / พัง | เวลาจบ |
|---|---|---|---|---|---|
| 1 | generic `-gNUM_RANDOM=8 -gSEED1=12345 -gSEED2=67890` | 32 / 52 บรรทัด | 8 | 8 / 0 | 246 ns |
| 2 | plusarg `+NUM_RANDOM=4 +SEED1=777 +SEED2=888` | 32 / 52 บรรทัด | 4 | 4 / 0 | 206 ns |

ทั้งสองรอบจบด้วย `Errors: 0, Warnings: 0`

**ขั้นที่ 4 : ดูค่าจริงที่ `uniform` คืนมา (สำคัญที่สุดของ lab นี้)**

รันโปรแกรมเล็ก ๆ ที่แนบมาให้ดู

```bat
cd lab08_stimulus
vcom -2008 tb/probe_uniform.vhd
vsim -c -onfinish stop work.probe_uniform -do "run -all"
```

ผลลัพธ์จริง

```text
** Note: seed (777,888) -- raw values of uniform :
** Note:   call 1 : u = 9.976514e-01   integer(u*16.0) = 16   integer(u*256.0) = 255
** Note:   call 2 : u = 6.140334e-01   integer(u*16.0) = 10   integer(u*256.0) = 157
** Note:   call 3 : u = 3.730142e-01   integer(u*16.0) = 6   integer(u*256.0) = 95
** Note:   call 4 : u = 4.306080e-02   integer(u*16.0) = 1   integer(u*256.0) = 11
** Note: seed (12345,67890) -- raw values of uniform :
** Note:   call 1 : u = 9.435974e-01   integer(u*16.0) = 15   integer(u*256.0) = 242
** Note:   call 2 : u = 9.083188e-01   integer(u*16.0) = 15   integer(u*256.0) = 233
** Note:   call 3 : u = 1.466878e-01   integer(u*16.0) = 2   integer(u*256.0) = 38
** Note:   call 4 : u = 5.147019e-01   integer(u*16.0) = 8   integer(u*256.0) = 132
```

เทียบกับผลของ testbench ในขั้นที่ 3 จะตรงกันเป๊ะ เช่น
seed `(777,888)` เรียกครั้งที่ 2 ได้ `integer(u*256.0) = 157`
ก็คือ “random vector 1 : data=157” ที่ testbench พิมพ์ออกมา

### สิ่งที่ควรรู้จาก Lab นี้

**1. VHDL ไม่มี plusargs — ใช้ generic แทน**

ใน Verilog ใช้ `+TEST=xxx` ได้ แต่ VHDL-2008 ไม่มี `std.env.getenv`
ต้องใช้ **generic** และส่งค่าตอนโหลด design

```tcl
vsim work.tb_stimulus -gNUM_RANDOM=16 -gSEED1=1 -gSEED2=2
```

ข้อควรระวังใน PowerShell: ต้องใส่เครื่องหมายคำพูด

```powershell
vsim work.tb_stimulus "-gSEED1=12345"     # ถูก
vsim work.tb_stimulus -gSEED1=12345      # ผิด -- PowerShell ไม่ขยายตัวแปรใน argument ของโปรแกรม native
```

ถ้าอยากให้ผู้ใช้สั่งแบบ Verilog ก็ให้ฝั่ง Tcl เป็นตัวแปลกลาง
ตามที่ `run_batch.do` ทำไว้: อ่าน `+NAME=VALUE` จาก `$::argv` แล้วแปลงเป็น `-gNAME=VALUE`

```tcl
foreach a [split $::argv " "] {
    if {[regexp {^\+([A-Za-z_][A-Za-z0-9_]*)=(.*)$} $a -> nm val]} {
        lappend gargs -g$nm=$val
    }
}
```

**2. `uniform` คืนค่าที่ใกล้ 1.0 มากได้ — และนั่นคือกับดัก**

จากผลวัดจริงข้างบน: seed `(777,888)` คืนค่าแรก `9.976514e-01`
การเขียนแบบที่คนส่วนใหญ่เขียน

```vhdl
a_addr(i) := integer(r_addr * 16.0);    -- ตั้งใจได้ 0 .. 15
```

จะได้ **16** ซึ่งไม่พอดีกับ address bus 4 บิต
เมื่อส่งเข้า `to_unsigned(16, 4)` ตัวจำลองจะเตือน

```text
** Warning: NUMERIC_STD.TO_UNSIGNED: vector truncated
```

และที่อยู่จะกลายเป็น 0 **โดยไม่มีใครรู้ตัว**
ร้ายที่สุดคือ testbench ยังขึ้น `TEST_PASSED` เพราะมันเขียนที่ address 0
แล้วอ่านกลับมาที่ address 0 เท่ากัน — บั๊กแบบเงียบ ๆ ที่ไม่มี checker จับได้

แก้โดยบังคับให้อยู่ในช่วงของ bus

```vhdl
a_addr(i) := integer(r_addr * 16.0) mod 16;
```

> กฎ: **อย่าเชื่อว่า `uniform` คืนค่าในช่วงเปิด (0,1) เสมอไป**
> ต้อง `mod` หรือ clamp ทุกครั้งที่เอาไปแปลงเป็นจำนวนเต็ม

**3. `variable a, b : positive := 777;` ให้ค่า 777 ทั้งสองตัว**

เขียนผิดแบบนี้

```vhdl
variable s1, s2 : positive := 777;    -- ทั้ง s1 และ s2 = 777 !!
```

ต้องประกาศแยกทีละตัว

```vhdl
variable s1 : positive := 777;
variable s2 : positive := 888;
```

ถ้าไม่ระวัง ผลของการทดสอบแบบสุ่มจะเปลี่ยนไปเงียบ ๆ
โดยที่ seed ที่ “คิดว่าใช้” ไม่ใช่ค่าที่ใช้จริง

**4. seed คู่เดียวกันให้ลำดับเลขเดิมเสมอ**

วัดได้จากขั้นที่ 2 และ 3 ข้างบน — รอบที่ 1 ใช้ seed `(12345,67890)`
รอบที่ 2 ใช้ seed `(777,888)` แต่ทั้งสองรอบให้ค่า “A = B” ทุกตัว
และ testbench พิมพ์ `reproduces the same sequence : true`

กฎที่ต้องจำ

- ต้องมี **สอง** seed (ไม่ใช่หนึ่ง)
- ค่าของ seed ทั้งสองเปลี่ยนไปทุกครั้งที่เรียก `uniform`
  → ถ้าต้องการผลลัพธ์เดิมต้อง “บันทึกค่า seed ก่อนเรียก” แล้วค่อยใช้ค่าใหม่
  (ใน testbench นี้คือ `sa1/sa2` กับ `sb1/sb2` ที่ประกาศแยกจากกัน)
- **seed คู่เดียวกันให้ลำดับเลขเดิมเสมอ** → ใช้ทำ regression แบบ deterministic ได้

**5. `hread` อ่านได้เฉพาะ `BIT_VECTOR`**

ข้อจำกัดของแพ็กเกจ `std.textio` คือ `hread` มี overload สำหรับ `bit_vector`
เท่านั้น ไม่มีสำหรับ `std_logic_vector` ทางเลือก:

```vhdl
-- ทางเลือกที่ใช้ได้ : เก็บค่าเป็น bit_vector แล้วแปลงทีหลัง
variable bv : bit_vector(7 downto 0);
hread(l, bv);
data <= std_logic_vector(bv);
```

DUT ของ lab นี้ (`src/ram8.vhd`) จึงใช้ `bit_vector` เป็นทางข้อมูลโดยเฉพาะ
ส่วน address และสัญญาณควบคุมยังเป็น `std_logic` ตามปกติ

**6. อ่านตัวอักษรท้ายบรรทัดทีละตัว — อย่าใช้ `read(l, s)`**

คำสั่ง `read` ของ `std.textio` เมื่ออ่าน `string` จาก `line`
ต้องการ string ที่ยาว **เท่ากับทั้งที่เหลือของบรรทัด** พอดี
ถ้าไม่ใช่จะได้

```text
** Error: (vsim-3549) String is not the length of the remaining line.
```

ทางแก้คืออ่านทีละตัวอักษรแล้วข้ามช่องว่าง

```vhdl
read(l, c);
while c <= ' ' loop
    read(l, c);
end loop;
v_op := c;
```

**7. อย่าอ่าน `transcript` เพื่อตัดสินผล — ให้ testbench เขียนผลเอง**

เมื่อโหลด design ครั้งที่สอง (รอบ plusarg) ตัวจำลองจะถือไฟล์ `transcript`
ไว้ในโหมดเขียน ทำให้อ่านไม่ได้ → ตัวตัดสินจาก transcript จะพังแบบไม่มีข้อความ

แนวทางที่ใช้ใน lab นี้: **testbench เขียนผลลง `result.txt` เอง**

```vhdl
procedure write_result(constant fname : in string; constant verdict : in string) is
    file f : text;
    variable l : line;
begin
    file_open(f, fname, write_mode);
    write(l, verdict);
    writeline(f, l);
    file_close(f);
end procedure write_result;
...
write_result("result.txt", "PASS");
```

แล้ว `run_batch.do` อ่านไฟล์นั้นเพื่อตัดสิน ไม่ใช้ exit code ของ `vsim`
(เพราะ `vsim` คืน 0 แม้จะเปิดไฟล์ `.do` ไม่ได้ — ดูข้อ C.4 ในภาคผนวก ก)

**8. อ่านไฟล์ด้วย `std.textio`**

```vhdl
file f : text;
variable l : line;
variable addr, data : integer;
...
file_open(f, "vectors.txt", read_mode);
while not endfile(f) loop
    readline(f, l);
    read(l, addr);
    read(l, data);
    ...
end loop;
file_close(f);
```

บรรทัดที่ขึ้นต้นด้วย `#` จะทำให้ `hread` ล้มเหลว
ในโค้ดจริงใช้ `hread(l, addr_bv, good)` แล้วตรวจ flag `good`
ถ้าเป็น false ก็ข้ามบรรทัดนั้น (นั่นคือเหตุผลที่ “52 บรรทัด → 32 เวกเตอร์”)

**9. เปรียบเทียบผลกับไฟล์คำตอบ (golden file)**

เขียนผลลัพธ์ลงไฟล์ แล้วเทียบกับไฟล์ที่คาดหวังไว้
ถ้าเทียบกับไฟล์ที่ “คาดหวัง” ให้เขียนไฟล์คำตอบออกมาเป็น golden file
แล้วในรอบถัดไปให้เทียบ — เป็นวิธีมาตรฐานของการทำ regression

### แบบฝึกหัด

1. เปลี่ยน `SEED1`/`SEED2` เป็นค่าอื่นแล้วรันซ้ำ ดูว่าลำดับตัวเลขที่สุ่มได้เปลี่ยนอย่างไร
2. ใส่ค่า seed เดิมกลับแล้วรันซ้ำ → ต้องได้ผลเหมือนเดิมทุกประการ
3. เพิ่มเวกเตอร์ผิดลงใน `vectors.txt` แล้วดูว่า testbench จับได้ไหม
   (ต้องเห็น `** Error: Assertion failed` และ `result.txt` ต้องเป็น `FAIL`)
4. ลบ `mod 16` ออกจาก `tb_stimulus.vhd` แล้วใช้ seed `(777,888)`
   → ต้องเห็น `** Warning: NUMERIC_STD.TO_UNSIGNED: vector truncated`
   ทั้งที่ testbench ยังขึ้น `TEST_PASSED` (บั๊กแบบเงียบ)

---

## LAB 09 — PSL assertion (Property Specification Language)

### เป้าหมาย

เขียน “คุณสมบัติ” ของ design ในรูปแบบที่เครื่องมือตรวจให้อัตโนมัติ
แทนที่จะเขียน `assert` ทีละเคสเอง

PSL คือภาษาที่ออกแบบมาให้ “เขียนสเปกเป็นคุณสมบัติ” เช่น
“ถ้าขอแล้วต้องตอบรับภายใน 1 รอบนาฬิกา” แล้วให้ตัวจำลองพิสูจน์ให้

### ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | หน้าที่ |
|---|---|
| `src/handshake.vhd` | DUT — handshake แบบ req/ack มี generic `BUGGY` เลือกเวอร์ชันที่พัง |
| `tb/tb_handshake.vhd` | testbench ที่ส่ง 3 คำขอ |
| `run_fail.cmd` / `run_nopsl.cmd` | สคริปต์สำหรับกรณี “พัง” และกรณี “ปิด PSL” |

### PSL ใน VHDL เขียนยังไง

PSL ฝังอยู่ใน **คอมเมนต์** ที่ขึ้นต้นด้วย `-- psl`

```vhdl
architecture rtl of handshake is
  -- psl default clock is rising_edge(clk);
  ...
begin
  ...
  -- psl req_ack: assert always (req -> next ack);
end architecture rtl;
```

### ขั้นตอน

**ขั้นที่ 1 : รันกรณีปกติ (ดีไซน์ถูกต้อง)**

```bat
run.cmd
```

ผลลัพธ์จริง

```text
# ** Note: TEST_PASSED : 3/3 handshakes answered within the latency bound
# ** Note: transaction 1 : ack on cycle 1
# ** Note: transaction 2 : ack on cycle 1
# ** Note: transaction 3 : ack on cycle 1
---- no PSL assertion fired, as expected ----
RESULT: PASS
```

**ขั้นที่ 2 : รันกรณีที่ดีไซน์พัง**

```bat
run_fail.cmd
```

ผลลัพธ์จริง (ข้อความสำคัญที่สุดของ lab นี้)

```text
** Error: Assertion failed
   Time: 45 ns Started: 35 ns  Scope: /tb_handshake/dut/req_ack File: src/handshake.vhd Line: 59
```

สิ่งที่ข้อความนี้บอกเรา

| ส่วน | ความหมาย |
|---|---|
| `** Error:` | severity คือ Error (ไม่ใช่ failure) |
| `Time: 45 ns` | เวลาที่ property **พัง** |
| `Started: 35 ns` | เวลาที่ property เริ่มติดตาม (นับจากรอบก่อนหน้า) |
| `Scope: /tb_handshake/dut/req_ack` | **ชื่อ property** ปรากฏใน scope → ระบุได้ว่าตัวไหนพัง |
| `File:` / `Line:` | ชี้ไปที่คอมเมนต์ `-- psl` ที่เขียนไว้ |

> **จุดสำคัญของการออกแบบ lab นี้**
> testbench ตรวจแค่ “ตอบรับภายใน 2 รอบ” (เงื่อนไขหลวม)
> เวลาเปิด PSL จึง **ไม่** พัง แต่พอปิด PSL ด้วย `-nopsl`
> บั๊กที่แท้จริง (ตอบช้าเกิน 1 รอบ) จะ **ไม่มีใครจับได้เลย**
> นี่คือคุณค่าของ property checking

**ขั้นที่ 3 : ลองปิด PSL เพื่อเปรียบเทียบ**

```bat
run_nopsl.cmd
```

ผลลัพธ์จริง — สังเกตว่า **ไม่มีข้อความ “Assertion failed” เลย**
และ transcript จะบอกว่า ack มาช้า (`ack on cycle 2 (late)`)
แต่ไม่มีอะไรมาตรวจจับ

### สิ่งที่ควรรู้จาก Lab นี้

**1. PSL ใน VHDL เปิดใช้งาน “ตั้งแต่แรก”**

`vcom -help all` ไม่มีตัวเลือก `-psl` แบบบวก มีแค่

| ตัวเลือก | ความหมาย |
|---|---|
| `-nopsl` | ปิดการ parse PSL ที่ฝังในคอมเมนต์ |
| `-pslext` | เปิดตัวดำเนินการ LTL/Universal ของ PSL |
| `-pslfile <file>` | compile และ bind PSL vunit จากไฟล์ภายนอก |

`vcom -2008 -nopsl src/handshake.vhd` คอมไพล์ผ่าน **0 error 0 warning**
และคอมเมนต์ `-- psl` จะกลายเป็นคอมเมนต์ธรรมดา

**2. `default clock` ต้องมาก่อน property**

```vhdl
-- psl default clock is rising_edge(clk);   -- ต้องเป็น directive แรก
-- psl req_ack: assert always (req -> next ack);
```

ถ้าเอา property มาก่อน `default clock` จะได้

```text
** Error: Only simple boolean properties can be unclocked.
```

**3. directive ที่ใช้ได้ / ใช้ไม่ได้ (ทดสอบจริงทุกข้อ)**

| รูปแบบ | ผล |
|---|---|
| `-- psl default clock is rising_edge(clk);` | ✔ ใช้ได้ |
| `-- psl name: assert always (req -> next ack);` | ✔ ใช้ได้ |
| `-- psl name: assert always (not ((req = '1') and (ack = '1')));` | ✔ ใช้ได้ |
| `-- psl name: assert always (...) @(rising_edge(clk));` | ✔ ใช้ได้ (ระบุ clock เอง) |
| `-- psl name: assume always (req -> next not req);` | ✔ ใช้ได้ **และถูกบังคับใช้จริง** (violation ถูกรายงานเป็น error) |
| `-- psl name: cover {req; ack};` | ✔ ใช้ได้ (ต้องเป็นรูปแบบ sequence) — แต่ **ไม่มีข้อความตอบกลับ** ตอนรัน |
| `-- psl name: assert always (...) severity error;` | ✘ `syntax error, unexpected "IDENTIFIER", expecting ';'` |
| `-- psl name: assert always (req -> next[1 to 2] ack);` | ✘ `near "to": syntax error` (แม้ใส่ `-pslext` ก็ยังไม่ได้) |
| `-- psl name: cover (req = '1');` | ✘ `Type error resolving infix expression "=" as type PSL SERE.` |
| `-- psl name: cover always (req -> next ack);` | ✘ `Type conflict in 'always' as type 'PSL SERE'.` |
| `-- psl name: cover {req; next ack};` | ✘ `near "next": syntax error` |

**4. วาง directive ไว้ตรงไหนได้**

| ตำแหน่ง | ผล |
|---|---|
| ในส่วน declarative ของ architecture (ก่อน `begin`) | ✔ คอมไพล์ผ่าน |
| ในส่วน body ของ architecture (หลัง `begin`) | ✔ คอมไพล์ผ่าน |
| ภายใน process | ✘ `near "psl": syntax error` |

**5. `cover` ไม่มี feedback**

คำสั่ง `cover` จะนับว่า property เคยเป็นจริงกี่ครั้ง แต่ **ไม่มีข้อความออกมา**
และใน 2026.1 **ไม่มีคำสั่ง Tcl ชื่อ `psl`** เลย (`help psl` → “No help for psl available”)
ถ้าต้องการดูจำนวนครั้งที่ cover ถูก hit ให้ใช้ **code coverage** (Lab 10) แทน

**6. `assume` ถูกบังคับใช้จริง**

เมื่อ environment ที่ test ให้มาผิดเงื่อนไข `assume`
ตัวจำลองจะรายงานเป็น error พร้อมชื่อ property เหมือนกัน
เหมาะมากสำหรับการกลั่นกรองสติมูลัสที่ผิดวิธี

### แบบฝึกหัด

1. เพิ่ม property `-- psl no_ack_stuck: assert always (not (req and not ack)) ;`
   แล้วทำให้ ack ค้างสักหนึ่งรอบเพื่อดูว่าจับได้ไหม
2. เขียน `assume` ที่บังคับว่า “req ต้องเป็น 1 ครั้งแล้วหายไป” แล้วส่ง req ที่ค้าง
   ดูว่าตัวจำลองรายงานอย่างไร
3. ลองใส่ `severity error` ต่อท้าย property แล้วดูข้อความ error ที่ได้

---

## LAB 10 — Code coverage ของ VHDL

### เป้าหมาย

วัดว่าโค้ด DUT ของเราถูกทดสอบครบแค่ไหน — ไม่ใช่แค่ “ผ่าน”
และเรียนรู้การรวมผลจากหลายชุดทดสอบเข้าด้วยกัน

### ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | หน้าที่ |
|---|---|
| `src/alu_fsm.vhd` | DUT — FSM 5 สถานะ + ALU `case` + condition ซับซ้อน + `for`-generate 4 ช่อง + loop |
| `tb/tb_alu_fsm.vhd` | **testbench เดียว** เลือก test ด้วย generic `TEST` = `basic` / `extra` / `edge` |
| `tb/pitfall/` | testbench อีกชุด (ชื่อต่างไป) ใช้สาธิตกับดัก instance path |
| `compile.do`, `test_*.do`, `merge.do`, `report.do` | สคริปต์แต่ละขั้นตอนของ flow |

### ขั้นตอน

**ขั้นที่ 1 : คอมไพล์ — ใส่ coverage เฉพาะ DUT**

```tcl
vcom -2008 src/alu_fsm.vhd +cover=bcesft     ;# DUT  : มี coverage
vcom -2008 tb/tb_alu_fsm.vhd                 ;# TB   : ไม่มี coverage
```

> ใส่ coverage เฉพาะ DUT เท่านั้น ไม่งั้นตัวเลขในรายงานจะปนมากับโค้ดสติมูลัส

**ขั้นที่ 2 : รันแต่ละชุดทดสอบแล้วบันทึกผล**

```tcl
vsim -coverage work.tb_alu_fsm -gTEST=basic
run -all
coverage save results/basic.ucdb -codeAll -testname basic
```

ทำซ้ำสำหรับ `extra` และ `edge`

**ขั้นที่ 3 : รวมผล**

```tcl
vcover merge results/merged.ucdb results/basic.ucdb results/extra.ucdb results/edge.ucdb
```

**ขั้นที่ 4 : ดูรายงาน**

```tcl
vcover report -summary -codeAll -output results/merged_report.txt results/merged.ucdb
vcover report -details -codeAll -output results/merged_detail.txt results/merged.ucdb
vcover report -html   -codeAll -output results/html_report     results/merged.ucdb
```

### ผลลัพธ์ที่วัดได้จริง

| ชุดทดสอบ | Branches | Conditions | FSM States | FSM Transitions | Statements | Toggles | **รวม** |
|---|---|---|---|---|---|---|---|
| `basic` | 93.44% | 100.00% | 100.00% | 62.50% | 93.33% | 63.69% | **85.49%** |
| `extra` | 93.44% | 0.00% | 100.00% | 62.50% | 93.33% | 84.93% | **72.36%** |
| `edge` | 96.72% | 100.00% | 100.00% | 75.00% | 96.66% | 93.15% | **93.58%** |
| **รวม (merged)** | 98.36% | 100.00% | 100.00% | 75.00% | 98.33% | 95.20% | **94.48%** |

ตัวอย่างรายงานจริงจาก `results/merged_report.txt`

```text
Coverage Report Totals BY INSTANCES: Number of Instances 2

    Enabled Coverage              Bins      Hits    Misses    Weight  Coverage
    ---------------- ----      ----    ------    ------  --------
    Branches                        61        60         1         1    98.36%
    Conditions                       2         2         0         1   100.00%
    FSM States                       5         5         0         1   100.00%
    FSM Transitions                  8         6         2         1    75.00%
    Statements                      60        59         1         1    98.33%
    Toggles                        146       139         7         1    95.20%
Total coverage (filtered view): 94.48%
```

ดูรายละเอียดว่าอะไรยังไม่ถูกทดสอบ (`results/merged_detail.txt`)

```text
------------------------------------CASE Branch------------------------------------
    141               1                    ***0***
Branch totals: 4 hits of 5 branches = 80.00%
```

```text
    Uncovered Transitions :
    -----------------------
Line            Trans_ID          Transition
----            --------          ----------
  109                   2          ST_LOAD -> ST_IDLE
  109                   6          ST_WAIT -> ST_IDLE
```

### สิ่งที่ควรรู้จาก Lab นี้

**1. ค่าเริ่มต้นของ `+cover` คือ `sbceft` — ให้เขียน spec เต็มทุกครั้ง**

จาก `vcom -help all`:

```text
+cover[=<spec>]   ... If no <spec> characters are given, sbceft is the default.
```

การทดสอบ A/B ด้วย design และ test เดียวกันให้ตัวเลข **เหมือนกันทุก metric**
(`results/pitfall_cover_spec_comparison.txt`) แต่การเขียน spec เต็ม
ทำให้ผลไม่ขึ้นกับค่าเริ่มต้นของเครื่องมือ — ควรทำเสมอ

**2. ⚠ ต้องใช้ `-onfinish stop` เสมอ**

ถ้า testbench จบด้วย `std.env.finish` โดยไม่ใส่ `-onfinish stop`
session จะ **ตายทันที** คำสั่ง `coverage save` จะไม่ได้ทำงาน
และ **ไม่มีไฟล์ `.ucdb` ถูกสร้างขึ้นเลย** — เงียบไปแบบไม่บอกเหตุ

| การรัน | ผลลัพธ์ |
|---|---|
| `vsim -c -coverage work.tb_alu_fsm` | ไม่มีไฟล์ `.ucdb` เลย (`results/pitfall_finish_nostop.ucdb` ไม่ถูกสร้าง) |
| `vsim -c -onfinish stop -coverage work.tb_alu_fsm` | มีไฟล์ `.ucdb` (`results/pitfall_finish_stop.ucdb`, 2,368 bytes) ✔ |

**3. ⚠ `coverage goal` ใช้ได้เฉพาะใน Coverage View mode**

ในการจำลองปกติจะได้

```text
** Error: Coverage sub-command 'goal' may be used in viewcov mode only.
```

และข้อความนี้เป็น **error จริง** ที่จะไปตาม hook `onerror` ในสคริปต์
ต้องเรียกในโหมด Coverage View เท่านั้น

```tcl
vsim -c -viewcov results/merged.ucdb -do "coverage goal; quit -f"
```

**4. ⚠ ชื่อ testbench ต้องเหมือนเดิมเสมอเมื่อ merge ผล**

ถ้าใช้ testbench คนละชื่อ instance path จะต่างกัน
ตัวจำลองจะ **นับ bin แยกชุด** ไม่ใช่รวมกัน → ตัวเลขเพี้ยน

| วิธี | Instances | Branches bins | Toggles bins | ผลรวม |
|---|---|---|---|---|
| ✔ testbench เดียว 3 generic | 2 | 61 | 146 | **94.48%** |
| ✘ testbench สองชื่อ | 4 | **122** (โตสองเท่า) | 292 | **50.74%** |

วิธีที่ถูก: ใช้ **testbench เดียว** แล้วเลือกชุดทดสอบด้วย generic

**5. `vcover` คืน exit code 0 เสมอ**

แม้จะมี error เช่น `** Error: (vcover-7) Failed to open UCDB file …`
ต้องอ่าน **เนื้อหา** ของรายงาน ไม่ใช่ exit code

**6. coverage ไม่สะสมข้ามการโหลด design ใหม่ใน session เดียว**

ถ้าโหลด design ใหม่ใน session เดิม ตัวนับจะถูกรีเซ็ต
ต้องรันแต่ละชุดทดสอบเป็น session แยก (ซึ่งคือสิ่งที่ `run.cmd` ของ lab นี้ทำ)

**7. ครอบคลุมได้ครบทั้ง 6 metric สำหรับ VHDL**

| Metric | ตัวย่อในคำสั่ง |
|---|---|
| Branch | `b` |
| Condition | `c` |
| Expression | `e` |
| Statement | `s` |
| Toggle | `t` |
| FSM (states + transitions) | `f` |

ตัวคอมไพล์ยังบอกด้วยว่าเจอ FSM กี่ตัว

```text
** Note: (vcom-143) Recognized 1 FSM in architecture body "alu_fsm(rtl)".
```

### แบบฝึกหัด

1. เพิ่มเทสต์ที่ทำให้ transition `ST_LOAD -> ST_IDLE` เกิดขึ้น
   แล้ว merge ใหม่ ตัวเลข FSM Transitions ต้องขึ้นจาก 75.00%
2. ลองเปลี่ยนชื่อ testbench เป็นชื่ออื่นแล้ว merge ดูความเพี้ยนของตัวเลข
3. ตั้ง coverage goal ใน Coverage View mode แล้วดูว่าบรรทัดไหนยังไม่ถึงเกณฑ์

---


## LAB 11 — Regression และการทำงานอัตโนมัติ (CI)

### เป้าหมาย

ทำให้ทุก lab ที่ทำไว้ “รันได้ด้วยคำสั่งเดียว” และสรุปผลเป็นตาราง
พร้อมรหัสจบการทำงานที่เครื่อง CI นำไปใช้ต่อได้ทันที

### ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | หน้าที่ |
|---|---|
| `regression.cmd` | ตัวรันทุก lab แล้วสรุปผล |
| `results/regression_summary.txt` | ตารางสรุปผลล่าสุด |
| `results/<lab>.log` | log ของแต่ละ lab แยกกัน |
| `../tools/pick_tool.cmd` | เลือกชุดติดตั้งที่ยังมี license ว่าง (ใช้ร่วมกันทุก lab) |

### ขั้นตอน

**ขั้นที่ 1 : รันทั้งชุด**

```bat
cd questa_vhdl_lab\lab11_regression
regression.cmd
```

ผลลัพธ์จริงจากเครื่องนี้ (รอบที่ผ่านทั้งหมด)

```text
====================================================================
 LAB 11 : regression -- running every lab
 root    : C:\...\questa_vhdl_lab\lab11_regression\..
====================================================================
[PASS] lab01_first_simulation
[PASS] lab02_libraries
[PASS] lab03_selfchecking_tb
[PASS] lab04_waveform
[PASS] lab05_debugging
[PASS] lab06_dataflow
[PASS] lab07_memory
[PASS] lab08_stimulus
[PASS] lab09_psl
[PASS] lab10_coverage

====================================================================
 REGRESSION SUMMARY
 total = 10   passed = 10   failed = 0
 summary file : C:\...\lab11_regression\results\regression_summary.txt
====================================================================
PASS  lab01_first_simulation  script=run.cmd
PASS  lab02_libraries  script=run.cmd
PASS  lab03_selfchecking_tb  script=run.cmd
PASS  lab04_waveform  script=run.cmd
PASS  lab05_debugging  script=run_debug.cmd
PASS  lab06_dataflow  script=run.cmd
PASS  lab07_memory  script=run.cmd
PASS  lab08_stimulus  script=run.cmd
PASS  lab09_psl  script=run.cmd
PASS  lab10_coverage  script=run.cmd
[REGRESSION] ALL GREEN
```

รหัสจบของ `cmd.exe` = `0` เมื่อทุก lab เขียว

**ขั้นที่ 2 : ดู log ของ lab ที่พัง**

```bat
type results\lab05_debugging.log
```

ทุก lab ถูกเรียกด้วย `call` และ stdout ถูกเปลี่ยนเป็นไฟล์ ทำให้
ไม่มีข้อความรบกวนหน้าต่าง และยังได้ log แยกไว้ตรวจย้อนหลัง

**ขั้นที่ 3 : ลองให้ regression เป็นแดง**

จงใจแก้ `src/alu.vhd` ใน lab05 ให้พัง (แล้วแก้กลับ) แล้วรัน `regression.cmd` ใหม่
จะเห็น

```text
[FAIL] lab05_debugging  exit=1
...
[REGRESSION] FAILED -- 1 lab(s) did not pass
```

และรหัสจบของ `cmd.exe` จะเป็น `1`

### สิ่งที่ควรรู้จาก Lab นี้

**1. “เขียว” ของแต่ละ lab อาจไม่ใช่ `run.cmd` เสมอไป**

lab ที่มี “เคสที่ตั้งใจให้พัง” ต้องใช้ entry point คนละอัน

| lab | สคริปต์ที่เป็น “เขียว” | สคริปต์ที่เป็น “แดงโดยตั้งใจ” |
|---|---|---|
| lab03 | `run.cmd` | `run_fail.cmd` (จงใจให้ assert fail) |
| lab05 | `run_debug.cmd` (หาบั๊กสำเร็จ) | `run.cmd` (DUT มีบั๊กจริง) |
| lab09 | `run.cmd` | `run_fail.cmd` (PSL ต้อง fail) |

ผลที่วัดได้จริงของทุกชุดทางเลือก

| คำสั่ง | ผลลัพธ์ | รหัสจบ |
|---|---|---|
| `lab03\run.cmd` | `[RESULT] PASS` | `0` |
| `lab03\run_fail.cmd` | `** Failure: FAIL: injected error (INJECT_ERROR = true)` → `[RESULT] FAIL as expected` | `1` |
| `lab05\run_debug.cmd` | `[RESULT] PASS` (พบบั๊กที่ `y = 0F`) | `0` |
| `lab05\run.cmd` | `[RESULT] FAIL -- exit=1` | `1` |
| `lab09\run.cmd` | `[RESULT] PASS` (ไม่มี PSL fire) | `0` |
| `lab09\run_fail.cmd` | `[RESULT] FAIL -- EXPECTED for run_fail.cmd` | `1` |
| `lab09\run_nopsl.cmd` | `[RESULT] PASS` (ปิด PSL แล้วไม่มีอะไรจับบั๊ก) | `0` |

ถ้าใส่ `run.cmd` ของ lab05 ลงในรายการ regression ระบบจะแดงตลอด
เพราะโดยออกแบบ lab นั้นไว้ให้พัง

**2. สคริปต์ที่ถูกเรียกด้วย `call` เปลี่ยนโฟลเดอร์ปัจจุบัน**

`run.cmd` ของทุก lab มี `cd /d "%~dp0"` จึง **ต้องกลับมา** หลังเรียกเสร็จ

```bat
call "%ROOT%\%%L\!LABSCRIPT!" > "%LOGDIR%\%%L.log" 2>&1
set "RC=!ERRORLEVEL!"
cd /d "%~dp0"                 -- <<< ต้องมีบรรทัดนี้
```

ถ้าลืม รายการถัดไปจะหาไฟล์ไม่เจอเพราะอยู่ผิดโฟลเดอร์
อาการที่เห็นจริงคือ `Cannot open macro file: run_batch.do` (ดูข้อ C.29 ในภาคผนวก ก)
และ `vsim` จะคืนรหัส `0` พร้อมกับไม่มี `result.txt` → ต้องตัดสินจากไฟล์ผลลัพธ์เสมอ

**3. ใช้ delayed expansion (`!var!`) เมื่ออ่านตัวแปรภายใน `for` loop**

```bat
setlocal enabledelayedexpansion
...
if "!RC!"=="0" ( ... )
```

ถ้าใช้ `%RC%` ค่าจะถูกขยายตอน *อ่านทั้งบล็อก* จึงได้ค่าเก่าเสมอ

**4. `for %%L in (...)` ใช้ `=` เป็นตัวคั่นข้อมูลไม่ได้**

ดูข้อ C.5 ในภาคผนวก ก — ถ้าต้องการผูก lab กับสคริปต์ ให้แยกกรณีพิเศษออกไปเป็น `if`

**5. รหัสจบที่ CI ต้องดู**

| รหัส | แปลว่า |
|---|---|
| `0` | ทุก lab ผ่าน → ให้ pipeline เดินต่อ |
| `1` | มี lab ไม่ผ่าน → ให้ pipeline ล้ม |
| `2` | สคริปต์หาเครื่องมือ/โฟลเดอร์ไม่เจอ → ปัญหาการตั้งค่า ไม่ใช่ปัญหา DUT |

**6. รันทีละ lab เท่านั้น (ข้อจำกัดของ license)**

license ของเครื่องนี้เป็น single-session
สคริปต์จึงรันทีละ lab และแต่ละ lab ต้องรอให้จบก่อนของถัดไป

**7. อย่า hardcode path ของชุดติดตั้ง — ให้ `tools/pick_tool.cmd` เลือก**

ถ้า hardcode ว่าใช้ QuestaSim เสมอ จะพังทันทีที่มี QuestaSim GUI เปิดค้างไว้
เพราะ license เป็น session เดียว (ข้อ C.24 ในภาคผนวก ก)

ทางแก้คือให้ทุก lab เรียก `tools/pick_tool.cmd` ซึ่งจะ

1. ไล่ชุดติดตั้งตามลำดับ `QUESTASIM_HOME` → `MODELSIM_HOME` → path ที่ติดตั้งไว้
2. ทดสอบด้วย license probe จริง (คอมไพล์ + โหลด design จิ๋ว `tools/probe/probe_top.vhd`)
3. เลือกชุดแรกที่ดึง license ได้จริง แล้วส่งค่ากลับมาในตัวแปร `MT`

```bat
call "%~dp0..\tools\pick_tool.cmd"
if not defined MT (
    echo [ERROR] no usable vsim.exe with a free licence was found.
    exit /b 2
)
set "PATH=%MT%;%PATH%"
```

ผลที่วัดได้จริงระหว่างที่ QuestaSim GUI เปิดค้างไว้

```text
 tool   : C:\Siemens\modelsim_dlx64_2026.1\win64pe
```

— ระบบเลือก ModelSim DE-64 ให้เองโดยที่ผู้ใช้ไม่ต้องแก้อะไร

> ถ้าอยากบังคับให้ใช้ชุดใดชุดหนึ่ง ให้ตั้ง `QUESTASIM_HOME` หรือ `MODELSIM_HOME`
> ตัวแปรสองตัวนี้ถูกอ่านเป็นอันดับแรกโดย `pick_tool.cmd`

### แบบฝึกหัด

1. จงใจแก้ `src/alu.vhd` ใน lab05 ให้พังอีกครั้ง แล้วรัน `regression.cmd`
   ดูว่า lab05 กลายเป็น `[FAIL]` และรหัสจบกลายเป็น 1
2. เพิ่มเคส “negative test” ของ lab09 (`run_fail.cmd`) เข้าไปในรายการด้วย
   แล้วทำให้มันรายงานว่าผ่านเมื่อ PSL **ไม่** fire (ซึ่งถือว่าล้มเหลว)
3. เขียนสคริปต์ที่อ่าน `results/regression_summary.txt` แล้วส่งอีเมล/แจ้งเตือน
   เมื่อมี lab ล้มเหลว
4. เปิด QuestaSim GUI ค้างไว้ แล้วรัน `regression.cmd` อีกครั้ง
   → ต้องยังเป็น ALL GREEN เพราะทุก lab หาเครื่องมือที่ license ว่างให้เอง

---

## ภาคผนวก

### ภาคผนวก ก — กับดักที่วัดได้จริงบนเครื่องนี้

ทุกข้อในตารางนี้ **เกิดขึ้นจริง** ระหว่างทำคู่มือนี้ ไม่ใช่ข้อควรระวังทั่วไป
แต่ละข้อมีวิธีตรวจสอบและวิธีแก้ให้พร้อมกัน

#### C.1 `info script` ในไฟล์ `.do` คืนค่าผิด — ทำให้ QuestaSim crash

| | |
|---|---|
| **อาการ** | `vsim.exe : ** Fatal: Exiting VSIM license process.` แล้ว process ตายด้วยรหัส `3221225477` (0xC0000005, access violation) |
| **สาเหตุ** | เมื่อสั่ง `do file.do` ตัว `info script` ของ Tcl จะคืนค่า **path ของตัว vsim** ไม่ใช่ไฟล์ `.do` |
| **ตัวอย่าง** | `cd [file normalize [file dirname [info script]]]` → `cd` เข้า `C:/mtitcl/vsim` (โฟลเดอร์ของตัวโปรแกรม) แล้วพัง |
| **วิธีตรวจ** | พิมพ์ `puts [info script]` ในไฟล์ `.do` → จะได้ `C:/mtitcl/vsim/vsim` |
| **วิธีแก้** | ใช้ `source file.do` แทน `do file.do` — `source` ทำให้ `info script` คืน path ของไฟล์จริง |

```tcl
# do  -> info script = C:/mtitcl/vsim/vsim   (ผิด)
# source -> info script = C:/path/to/your/file.do   (ถูก)
```

> คู่มือนี้เลือกใช้แนวทางที่ปลอดภัยกว่า คือ **ไม่พึ่ง `info script` เลย**
> ทุกสคริปต์ `.do` ต้องรันจากโฟลเดอร์ของ lab (ทำโดย `run.cmd` ที่ `cd /d "%~dp0"`)
> และมี guard ตรวจว่าอยู่ในโฟลเดอร์ที่ถูกต้อง

#### C.2 ภาษาไทยในไฟล์ `.cmd` ทำให้ `cmd.exe` พังโครงสร้างบรรทัด

| | |
|---|---|
| **อาการ** | `'<ภาษาไทย>' is not recognized as an internal or external command` และบรรทัดถัดไปเสียไปด้วย (เช่น `echo` กลายเป็น `cho`) |
| **สาเหตุ** | `cmd.exe` อ่านไฟล์ `.cmd` ตาม code page ของ console (ไม่ใช่ UTF-8) ไบต์ภาษาไทยจึงกินตัวอักษรแรกของบรรทัดถัดไป |
| **วิธีแก้** | ให้ไฟล์ `.cmd` เป็น **ASCII ล้วน** เขียนคำอธิบายภาษาไทยไว้ใน `rem` ที่เป็น ASCII หรือย้ายไปไว้ในคู่มือ |

ตรวจสอบด้วย PowerShell ก่อน commit ไฟล์

```powershell
Get-ChildItem -Recurse -Include *.cmd | ForEach-Object {
  $n = 0
  foreach ($line in [System.IO.File]::ReadAllLines($_.FullName)) {
    $n++
    if ($line -match '[^\x00-\x7F]') { "$($_.FullName):$n : $line" }
  }
}
```

#### C.3 วงเล็บที่ไม่ escape ใน `echo` ที่อยู่ใน `if` block

| | |
|---|---|
| **อาการ** | สคริปต์หยุดทันที **โดยไม่มีข้อความแม้แต่บรรทัดเดียว** และ exit code = 1 |
| **สาเหตุ** | `cmd.exe` มอง `(` ในข้อความว่าเป็นการเปิด block ใหม่ ทำให้ syntax เพี้ยน |
| **ตัวอย่าง** | `echo [RESULT] FAIL  (no result file)` ภายใน `if (...)` → พัง |

วิธีแก้: เขียนข้อความให้ไม่มีวงเล็บ หรือ escape ด้วย `^(` และ `^)`

#### C.4 `vsim` คืน exit code 0 แม้แต่เปิดไฟล์ `.do` ไม่ได้

| | |
|---|---|
| **อาการ** | สคริปต์ batch รายงานว่า PASS ทั้งที่ไม่มีอะไรรันจริง |
| **สาเหตุ** | `vsim -c -do "do ไม่มีไฟล์.do"` พิมพ์ `Cannot open macro file: ...` แล้วจบด้วยรหัส 0 |
| **วิธีแก้** | ให้ testbench เขียนผลลงไฟล์ `result.txt` แล้วให้สคริปต์อ่านไฟล์นั้น (ไม่พึ่ง exit code อย่างเดียว) |

#### C.5 ใน `for %%V in (...)` เครื่องหมาย `=` ถูกตีความเป็นตัวคั่นคู่ `var=value`

| | |
|---|---|
| **อาการ** | รายการที่ตั้งใจจะเป็น 1 ชิ้น กลายเป็นหลายชิ้น |
| **สาเหตุ** | ภาษาของ `for` รองรับรายการรูปแบบ `ตัวแปร=ค่า` จึงตัดข้อความที่มี `=` ออกเป็นคนละชิ้น |
| **วิธีแก้** | อย่าใช้ `=` เป็นตัวคั่นข้อมูลในรายการของ `for` — แยกกรณีพิเศษออกไปเป็น `if` แทน |

#### C.6 ไฟล์ `.vhd` ที่มี BOM (UTF-8 with BOM) คอมไพล์ไม่ได้

| | |
|---|---|
| **อาการ** | `** Error: tb/tb_timer.vhd(1): near "?": syntax error` |
| **สาเหตุ** | BOM (3 ไบต์ `EF BB BF`) ที่หัวไฟล์ถูกตัวคอมไพล์อ่านเป็นอักขระผิด |
| **วิธีแก้** | บันทึกเป็น UTF-8 **ไม่มี BOM** |

```powershell
$enc = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($path, $text, $enc)
```

#### C.7 ภาษาไทยใน string literal ของ VHDL ใช้ไม่ได้

| | |
|---|---|
| **อาการ** | `** Error: (vcom-1576) String literal has a character with value 0x95 not in the enumeration type std.STANDARD.CHARACTER.` |
| **สาเหตุ** | string literal ของ VHDL ประกอบด้วยอักขระ `CHARACTER` (Latin-1) เท่านั้น |
| **วิธีแก้** | ใช้ภาษาไทยได้ใน **comment** เท่านั้น ใน `report`/`assert` ให้ใช้ภาษาอังกฤษ |

#### C.8 `const` เป็นคำสงวนใน VHDL-2008

```vhdl
procedure write_result(const fname : in string; ...)   -- ผิด
-- ** Error: near "fname": (vcom-1576) expecting ':'.
procedure write_result(constant fname : in string; ...) -- ถูก
```

#### C.9 `writeline` ต้องการ `line` ไม่ใช่ `string`

```vhdl
writeline(f, verdict);      -- ผิด : (vcom-1600) No feasible entries for subprogram "WRITELINE"
write(l, verdict);
writeline(f, l);            -- ถูก
```

#### C.10 `std_logic_vector` ไม่มีตัว `+`

```vhdl
tmp := ('0' & unsigned(a)) + ('0' & unsigned(b));   -- ผิด : ผสมสองชนิด
tmp := ('0' & unsigned(a)) + unsigned('0' & unsigned(b));  -- ถูก
```

#### C.11 `bus` เป็นคำสงวนของ VHDL

ตั้งชื่อ signal ว่า `bus` ไม่ได้ → ใช้ `data_bus` แทน

#### C.12 `string(0 to n)` ใช้ไม่ได้

`STRING` ถูกนิยามเป็น `array (POSITIVE range <>) of CHARACTER`
ดังนั้น index ต้องเป็นบวกเสมอ ใช้ `string(1 to n)`

#### C.13 array ของ unconstrained string ต้องมีความยาวเท่ากันทุกช่อง

```vhdl
type note_array is array (natural range <>) of string;
constant NOTES : note_array := ("ADD ok", "SUB exposes the bug");  -- ผิด
-- ** Error: (vcom-1622) Unconstrained subelements cannot be of different sizes.
```

ทางออกที่ดีกว่า: ใช้ enumerated type + ฟังก์ชันแปลงเป็น string

```vhdl
type note_id_t is (N_ADD, N_SUB, N_AND, N_OR);
function note_text(n : note_id_t) return string is ...
```

#### C.14 `use` clause เลือกได้เฉพาะ package

```vhdl
use ip_lib.ip_core.all;   -- ผิด : 'ip_core' is not a library or a package
```

และชื่อไลบรารีต้องประกาศก่อน

```vhdl
library ip_lib;            -- ต้องมีบรรทัดนี้
core : entity ip_lib.ip_core port map (...);
```

#### C.15 อย่าลบ `modelsim.ini` ระหว่าง session

ตัวจำลองโหลดไฟล์นี้ไว้ตั้งแต่ตอนเริ่ม ถ้าลบทิ้ง การคอมไพล์ที่อ้างไลบรารีอื่นจะ
ขึ้น `** Error: (vcom-1136) Unknown identifier "ip_lib".`

#### C.16 `vcd add` ต้องทำก่อน `run`

ถ้าทำหลัง ไฟล์ VCD จะมีแต่ header (1,310 bytes) ไม่มีค่าที่เปลี่ยนแปลง
ทำก่อนจะได้ 3,219 bytes

#### C.17 `wlf2vcd` เปิดไฟล์ WLF ไม่ได้ระหว่างจำลอง

```text
** Error: Unable to open WLF file "vsim.wlf".
```

ต้องรอให้ simulator ปิดตัวลงก่อน

#### C.18 `severity failure` ทำให้สคริปต์ `.do` ถูกรันซ้ำ

เมื่อ testbench หยุดด้วย `severity failure` ระหว่าง `run -all`
ModelSim จะ abort สคริปต์ปัจจุบัน แล้ว **เริ่มรายการคำสั่ง `-do` ใหม่ตั้งแต่ต้น**
(ตรวจได้จาก log ที่มีบรรทัด `# do run_batch.do` ซ้ำ)

ทางแก้ที่ใช้ในคู่มือนี้: ห่อ `run -all` ด้วย `catch` และให้ testbench เป็นคนเขียนผล

#### C.19 `examine` ในโหมด console ไม่พิมพ์ผลลัพธ์

ต้องเก็บค่าที่คืนมาแล้ว `puts` เอง

```tcl
set v [examine -radix hex -value /tb_alu/dut/y]
puts "  y = $v"
```

#### C.20 `[time]` ชนกับคำสั่ง `time` ของ Tcl

```tcl
puts "stopped at [time]"     -- ** Error: wrong # args: should be "time command ?count?"
puts "stopped at $::now"     -- ถูก
```

#### C.21 license ถูกเช็คตอน “โหลด design” เท่านั้น

`vsim -c -do "quit -f"` ไม่ดึง license ต้องคอมไพล์แล้วโหลด design จริงจึงจะเจอข้อความ
"License checkout has been disallowed" — ตัว `run.cmd` ใช้หลักการนี้ในการเลือกชุดติดตั้ง

#### C.22 `=` ไม่แพร่ค่า X

ตัวเปรียบเทียบของ IEEE 1164 คืน `FALSE` เมื่อ operand มี `X`/`U`
ต้องใช้ตัวบิต (`xor`/`and`/`or`) หรือ `is_x()` ถ้าต้องการให้ X แพร่

#### C.23 คำสั่ง `mem` ใน 2026.1 ไม่มี `mem export`

คำสั่งที่มีคือ `mem compare`, `mem display`, `mem list`, `mem load`, `mem save`, `mem search`
ใช้ `mem save` แทน `mem export`

#### C.24 QuestaSim GUI ที่เปิดค้างไว้ จะบล็อก QuestaSim แบบบรรทัดคำสั่ง

วัดได้จริงบนเครื่องนี้: ขณะที่ QuestaSim GUI (`vish.exe -gui`, ชื่อหน้าต่าง
“Questa Sim-64 2026.1”) ยังเปิดอยู่ การรัน `vsim` ของชุด QuestaSim แบบบรรทัดคำสั่ง
จะได้ข้อความ

```text
** Error: License checkout has been disallowed because
only one session is allowed to run on an uncounted nodelocked
license and an instance of QuestaSim is already running with a
nodelocked license on this machine.
```

แต่ **ModelSim DE-64 ยังรันได้ตามปกติ** เพราะเป็นอีก seat หนึ่ง
ทางแก้คืออย่า hardcode path ของชุดใดชุดหนึ่ง แต่ให้สแกน license จริงก่อน
(ดู `tools/pick_tool.cmd`) แล้วเลือกชุดที่ใช้ได้

#### C.25 `uniform` อาจคืนค่าที่แปลงเป็น `integer` แล้วเกินช่วงของ bus

วัดได้จริง: seed `(777,888)` คืนค่าแรก `9.976514e-01`
`integer(u * 16.0)` จึงได้ **16** ซึ่งเกิน address bus 4 บิต
ถ้าเอาไป `to_unsigned(16, 4)` จะได้

```text
** Warning: NUMERIC_STD.TO_UNSIGNED: vector truncated
```

และที่อยู่จะกลายเป็น 0 **แบบเงียบ ๆ** — testbench ที่อ่านกลับ address เดิม
ยังผ่านอยู่ จึงเป็นบั๊กที่ checker แบบธรรมดาจับไม่ได้
แก้ด้วย `mod 16` ทุกครั้งที่แปลงค่าจาก `uniform` ไปเป็นจำนวนเต็ม

#### C.26 `variable a, b : positive := 777;` ให้ค่า 777 **ทั้งสองตัว**

ตัวแปรที่ประกาศรวดในบรรทัดเดียวจะได้ค่าเริ่มต้นเท่ากันหมด
ต้องประกาศแยกทีละตัวถ้าต้องการ seed สองค่าที่ต่างกัน

#### C.27 `read(l, s)` อ่าน `string` จาก `line` ต้องยาวเท่ากับที่เหลือของบรรทัด

ถ้าไม่ใช่จะได้

```text
** Error: (vsim-3549) String is not the length of the remaining line.
```

แก้โดยอ่านทีละตัวอักษรแล้วข้ายช่องว่าง (`read(l, c)`) หรือใช้ `hread`
ซึ่งรับ flag `good` มาบอกว่าอ่านได้หรือไม่

#### C.28 `transcript` ถูกล็อกเมื่อโหลด design ซ้ำ

ถ้าสคริปต์ `.do` โหลด design ครั้งที่สีด้วย `vsim` อีกครั้ง
ไฟล์ `transcript` จะถูกถือไว้ในโหมดเขียน แล้วอ่านไม่ได้
ทางแก้คือให้ **testbench เขียนผลลง `result.txt` เอง** แล้วให้สคริปต์
อ่านไฟล์นั้น (ดู Lab 08)

#### C.29 `run.cmd` ที่ไม่มี `cd /d "%~dp0"` จะหาไฟล์ `.do` ไม่เจอ

อาการคือ

```text
# Cannot open macro file: run_batch.do
```

และ `vsim` จะ **คืน exit code 0** พร้อมกับไม่มีไฟล์ `result.txt`
ต้องมี `cd /d "%~dp0"` ใน `run.cmd` ทุกตัวเสมอ
และสคริปต์ที่ถูกเรียกด้วย `call` ต้อง `cd /d` กลับมาที่โฟลเดอร์ตัวเอง
(ดูข้อ 2 ของ Lab 11)

---

### ภาคผนวก ข — ตารางคำสั่ง Tcl ที่ใช้บ่อย (ตรวจด้วย `help <คำสั่ง>`)

| คำสั่ง | รูปแบบที่วัดได้จริง |
|---|---|
| `mem load` | `mem load {-infile <infile> \| -filldata <data_word> [-infile <infile>]} [-endaddress <end>] [-fillradix <radix_type>] [-filltype {dec \| inc \| rand \| value}] [-format [bin \| hex \| mti]] [<path>] [-skip <Nwords>] [-startaddress <st>] [-truncate]` |
| `mem save` | `mem save <file_name> [<object_name>]` |
| `examine` | `examine <name>... [-delta <delta>] [-event <time>] [-handle] {[-in] [-out] [-inout] \| [-ports]} [-internal] [-maxlen <integer>] [-expr <expression>] [-name] [-<radix_type>] [-radix <type>] [-showbase] [-time <time>] [-value]` |
| `add wave` | `add wave [-allowconstants] [-color <name>] [-depth <level>] [-divider <name>] [-expand <signal>] [-format <type>] [-group <group> [<sig>...]] [-height <px>] {[-in] [-out] [-inout] \| [-ports]} [-internal] [-label <name>] [-max <real>] [-min <real>] [-noupdate] [-position <loc>] [-radix <type>] [-recursive] [-time] [<object_name>...]` |
| `bp` | `bp {<filename> <line_number> \| in <task_or_fcn>} {-c {...}} [-cond "<expr>"] [-disable] [-id <id#>] [-label "<label>"] [-inst <region>] [<command>...] \| [-query <filename> [<line_number>]]` |
| `run` | `run {[<timesteps>[<time_units>]] \| -all \| -continue \| -final \| -finish \| -init \| -next \| -over [<n>]} \| {-step [<n>] [-current] [-out] [-over [<n>]]}` |
| `coverage save` | `coverage save [-instance <path>] [-code {b\|c\|e\|s\|t\|f}...] [-codeAll] [-du <du_name>] [-empty <ucdb>] [-testname <test_name>] [-norecursive] [-onexit] [-prune <inst_path>] [<file_name>] [-assert] [-directive]` |
| `force` | `force <object_name> {<value> [[@]<time_info>][, <value> ...]} [-freeze \| -drive \| -deposit] [-cancel [@]<time_info>] [-repeat [@]<time_info>]` |
| `when` | `when [[-fast] [-id <id#>] [-label <label>] [-repeat] {<condition>} {<command>}]` |
| `log` | `log -flush <object> \| {[-filter <f> \| -nofilter <f>] [-howmany] {[-in] [-inout] [-out] \| [-ports]} [-internal] [-recursive [-depth <level>]] <object_name> ...}` |
| `quit` | `quit [-f \| -force] [-sim] [-code <integer>]` |
| `vcd` | `vcd add \| checkpoint \| comment \| dumpports... \| file \| files \| flush \| limit \| off \| on` |

### ภาคผนวก ค — ตัวเลือกของคำสั่งที่ใช้บ่อย

| คำสั่ง | ตัวเลือก | ความหมาย |
|---|---|---|
| `vcom` | `-2008` | ใช้มาตรฐาน VHDL-2008 (จำเป็นสำหรับ `std.env.finish`, `is_x`) |
| `vcom` | `-work <lib>` | ระบุไลบรารีปลายทาง |
| `vcom` | `-nopsl` | ปิดการ parse PSL ที่ฝังในคอมเมนต์ |
| `vcom` | `-pslext` | เปิดตัวดำเนินการ LTL/Universal ของ PSL |
| `vcom` | `+cover=<spec>` | ใส่ instrumentation สำหรับ code coverage (ค่าเริ่มต้นของเครื่องมือคือ `sbceft`) |
| `vsim` | `-c` | โหมด console (ไม่มี GUI) |
| `vsim` | `-onfinish <mode>` | `ask` (ค่าเริ่มต้น) \| `stop` \| `exit` \| `final` — ควรใช้ `stop` ในงาน batch |
| `vsim` | `-voptargs=+acc` | เปิดการเข้าถึง signal ภายในทั้งหมด (จำเป็นสำหรับ memory) |
| `vsim` | `-coverage` | เปิดการเก็บข้อมูล coverage |
| `vsim` | `-L <lib>` | เพิ่มไลบรารีในเส้นทางค้นหา |
| `vsim` | `-lib <lib>` | โหลด top จากไลบรารีที่ระบุ |
| `vsim` | `-g<NAME>=<value>` | ส่งค่าให้ generic ของ entity |

### ภาคผนวก ง — เทียบกับ Questa SIM Tutorial 2026.1 (คู่มือทางการ)

| Lab ของคู่มือนี้ | บทที่เกี่ยวข้องในคู่มือทางการ |
|---|---|
| LAB 01 | Ch.3 Basic Simulation — Create the Working Design Library / Compile / Optimize / Load / Run / Breakpoints |
| LAB 02 | Ch.5 Working With Multiple Libraries — Creating the Resource Library / Linking to the Resource Library |
| LAB 03 | Ch.3 (Run the Simulation) + หลักการเขียน testbench ที่ตรวจตัวเอง |
| LAB 04 | Ch.7 Analyzing Waveforms + Ch.8 Creating Stimulus With Waveform Editor (ส่วน Export) |
| LAB 05 | Ch.3 Set Breakpoints and Step through the Source + Ch.10 Dataflow Window |
| LAB 06 | Ch.10 Debugging With The Dataflow Window — Tracing an X (Unknown) |
| LAB 07 | Ch.11 Viewing And Initializing Memories |
| LAB 08 | Ch.8 (Create Graphical Stimulus with a Wizard / Simulating with the Test Bench File) |
| LAB 09 | Ch.14 Debugging With PSL Assertions |
| LAB 10 | Ch.13 Simulating With Code Coverage |
| LAB 11 | Ch.4 Projects / Simulation Configurations + แนวทาง CI ของคู่มือทางการ |

> คู่มือทางการครอบคลุม SystemC, SystemVerilog assertions/functional coverage และ DPI ด้วย
> คู่มือนี้จำกัดขอบเขตที่ **VHDL** ตามที่โจทย์กำหนด และเจาะลึกกว่าในส่วน
> batch/CI กับกับดักที่เจอจริงบนเครื่อง

### ภาคผนวก จ — สรุป “ทำอะไรต่อ” หลังจบทุก lab

| คุณทำได้แล้ว | ขั้นต่อไปที่ควรทำ |
|---|---|
| จำลอง VHDL ได้ทั้ง GUI และ batch | ลองทำ Lab 11 เพื่อรันทุก lab เป็นชุด |
| เขียน testbench ที่ตรวจตัวเอง | เพิ่ม PSL assertion (Lab 09) เพื่อตรวจ property ที่ซับซ้อนขึ้น |
| ดู coverage แล้ว | ตั้ง coverage goal และทำให้ regression ไม่ผ่านเมื่อ coverage ต่ำกว่าเกณฑ์ |
| แก้บั๊กด้วย breakpoint | ลองใช้ `force`/`release` และ `when` เพื่อทำ debug แบบในเชิงพฤติกรรม |
| ส่งออก VCD ได้ | ต่อเข้ากับ flow อื่น เช่น สร้างรายงาน HTML coverage แล้วเก็บเป็น artifact ของ CI |

---

## ภาคผนวก ฉ — คำถามที่พบบ่อย (FAQ)

**ถาม: รัน `run.cmd` แล้วขึ้น `[RESULT] FAIL -- the simulator did not finish` ทำอย่างไร ?**

1. เปิดไฟล์ `transcript` ในโฟลเดอร์ lab ดูข้อความท้าย ๆ
2. ถ้าเจอ `License checkout has been disallowed` → มี QuestaSim GUI เปิดค้างอยู่
   ให้ปิด แล้วรันใหม่
3. ถ้าเจอ `Cannot open macro file` → สคริปต์ถูกเรียกจากโฟลเดอร์ผิด
   ให้รันจากในโฟลเดอร์ของ lab
4. ถ้าเจอ error ของ `vcom` → ดูบรรทัดและเลขบรรทัดที่ชี้

**ถาม: ทำไมผลลัพธ์ต่างกันเวลารันใน GUI กับแบบ batch ?**

ตรวจดูว่าเวลาจำลองสิ้นสุดเท่าไร — ใน GUI ค่าเริ่มต้นของการรันคือ 100 ns
ถ้าต้องการให้รันจนจบ ให้ใช้ `run -all` เสมอ

**ถาม: ใช้ `std.env.finish` แล้วสคริปต์ถัดไปไม่ทำงาน ?**

ใช้ `vsim -c -onfinish stop` — ค่าเริ่มต้นคือ `ask` ซึ่งจะถามในโหมด console
และ `-onfinish stop` จะทำให้จำลอง “หยุด” แทนที่จะ “จบ session” คำสั่งที่เหลือจึงทำงานต่อ

**ถาม: จะเขียนข้อความภาษาไทยลงใน report ของ testbench ได้ไหม ?**

ไม่ได้ใน string literal (ข้อ C.7) แต่ถ้าอยากให้ผู้อ่านไทยเข้าใจ ให้เขียนเป็น comment ในไฟล์ VHDL
แล้วให้ `report` พิมพ์ข้อความอังกฤษ

**ถาม: รันทุก lab พร้อมกันได้ไหม ?**

**ไม่ได้** ถ้า license เป็น single-session แบบของเครื่องนี้
ต้องรันทีละ lab หรือใช้เครื่อง/ชุดติดตั้งที่มี license แยกกัน
(สคริปต์ `regression.cmd` ของ Lab 11 รันทีละ lab อยู่แล้ว)

**ถาม: ย้ายโฟลเดอร์ lab ไปที่อื่นแล้วรันไม่ได้ ?**

ไฟล์ `.do` ทุกตัวอ้างอิงไฟล์แบบสัมพัทธ์ จึงต้อง `cd` เข้าโฟลเดอร์ lab ก่อนรัน
(`run.cmd` ทำให้อัตโนมัติ) ส่วน `run.cmd` จะหาเครื่องมือจาก path ที่ติดตั้งจริง
ถ้าย้ายไปเครื่องอื่นให้ตั้ง `QUESTASIM_HOME` หรือ `MODELSIM_HOME`
