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
