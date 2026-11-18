## ภาคนำ

### คู่มือนี้คืออะไร

คู่มือนี้สอน **การจำลองระดับ gate (Gate-Level Simulation, GLS)** ด้วย QuestaSim / ModelSim
ตั้งแต่พื้นฐานจนถึงระดับที่เอาไปใช้ต่อในงานจริงได้
แยกเป็น **8 lab แบบทีละขั้น** ที่ทำตามแล้วรันได้จริงทุกขั้น

จุดต่างของคู่มือนี้คือ **ตัวเลขและข้อความทุกตัวมาจากการรันจริงบนเครื่อง**
ไม่ใช่ตัวอย่างที่แต่งขึ้น — ทำซ้ำตามคู่มือแล้วจะได้ผลชุดเดียวกัน

### จุดต่างสำคัญของฉบับนี้: **RTL เขียนด้วย VHDL**

โค้ดทั้งหมดในคู่มือนี้เริ่มต้นจาก **VHDL** ทั้งหมด

```text
RTL (VHDL)  --ghdl synth-->  Verilog  --Yosys+Liberty-->  gate netlist (Verilog)
     |                                                              |
     +--------------- testbench VHDL ชุดเดียวกัน --------------------+
```

นี่คือสถานการณ์ที่พบบ่อยที่สุดในอุตสาหกรรม ASIC จริง:
**RTL เขียนด้วย VHDL แต่สังเคราะห์และจำลองระดับ gate ด้วย Verilog**
เครื่องมือที่ต้องใช้จึงมีทั้งสองภาษา

คู่มือนี้จึงต้องสอนเรื่องที่หลายคู่มือข้ามไป คือ **การทำให้ testbench VHDL ชุดเดียว
ขับได้ทั้งระดับ RTL (VHDL) และระดับ gate (Verilog)** — ซึ่งเป็นหัวใจของ LAB 01 ถึง LAB 05

### ผู้เรียนจะได้อะไร

เมื่อทำครบทุก lab ผู้เรียนจะทำสิ่งเหล่านี้ได้ด้วยตัวเอง

1. เขียน **RTL ภาษา VHDL** และแปลงเป็น Verilog ด้วย `ghdl synth`
   แล้วสังเคราะห์ต่อเป็น gate netlist ด้วย Yosys + Liberty ของ IHP SG13G2
2. ใช้ **testbench VHDL ชุดเดียวกัน** ขับทั้งระดับ RTL และระดับ gate
   โดยเปลี่ยนแค่ไฟล์ที่คอมไพล์เข้าไลบรารี `work`
3. อธิบายได้ว่า **RTL simulation กับ gate level simulation ต่างกันอย่างไร**
   และอะไรที่ gate level จับได้แต่ RTL จับไม่ได้
4. อ่าน **เซลล์มาตรฐาน** ของ SG13G2 และเข้าใจว่า Liberty, Verilog model
   และ timing check ของแต่ละเซลล์เป็นอย่างไร
5. จับ **บั๊กใน netlist** ที่การจำลองระดับ RTL มองไม่เห็น
6. สร้าง **regression** ของการจำลองระดับ gate ที่รันซ้ำได้และรหัสจบนำไปใช้กับ CI ได้

### วิธีใช้คู่มือนี้

ทุก lab มีโครงสร้างเดียวกัน

```text
labNN_xxx/
├── run.cmd          ตัวรันแบบ Windows  (เลือกเครื่องมือ + ตัดสิน PASS/FAIL)
├── run_batch.do     สคริปต์ Tcl ที่ vsim จะทำงาน
├── run_rtl.do       สคริปต์จำลองระดับ RTL   (มีใน lab ที่เทียบสองระดับ)
├── run_gls.do       สคริปต์จำลองระดับ gate (มีใน lab ที่เทียบสองระดับ)
└── results/         ผลลัพธ์จากการรัน
```

รัน lab เดียวด้วย

```bat
cd questa_gls_vhdl_lab\lab05_rtl_vs_gate
run.cmd
```

แล้วดูรหัสจบของ `cmd.exe`

| รหัส | ความหมาย |
|---|---|
| `0` | ผ่าน (PASS) |
| `1` | ไม่ผ่าน (FAIL) |
| `2` | หาเครื่องมือหรือโฟลเดอร์ไม่เจอ |

### ข้อตกลงเบื้องต้น

- ต้องมี **QuestaSim หรือ ModelSim 2026.1** (วิธีติดตั้งและ license อยู่ในหัวข้อ 1.2)
- ต้องมี **IHP SG13G2** (ไฟล์ Verilog model และ Liberty อยู่ใน `cells/` แล้ว ไม่ต้องติดตั้งอะไรเพิ่ม)
- **Yosys และ GHDL ใช้เฉพาะตอนสังเคราะห์ netlist ใหม่** และต้องรันใน WSL (หัวข้อ 2.2)
  netlist ที่สังเคราะห์ไว้แล้วอยู่ใน `netlist/` ของคู่มือนี้
  ดังนั้น **ทุก lab ที่เป็นการจำลอง รันได้บน Windows ล้วน ๆ**
- ถ้าไม่มี ModelSim เลย **ยังตรวจโค้ด VHDL ทั้งหมดได้ด้วย GHDL** (ภาคผนวก C)

---

## บทที่ 1 — เตรียมเครื่องมือ

### 1.1 เครื่องมือที่ใช้ (ทุกตัววัดจริงบนเครื่องนี้)

| เครื่องมือ | เวอร์ชันที่วัดได้ | ใช้ทำอะไร |
|---|---|---|
| ModelSim DE-64 | `vsim 2026.1 Simulator 2026.01 Jan 25 2026` | จำลองระดับ RTL และระดับ gate |
| Questa Sim-64 | `vsim 2026.1 Simulator 2026.01 Jan 25 2026` | เหมือนกัน (เป็นชุดเต็ม) |
| GHDL | `5.0.1 (Ubuntu 5.0.1+dfsg-1ubuntu1) [Dunoon edition]` | แปลง VHDL เป็น Verilog (`ghdl synth`) |
| GNAT (ตัวหลัง GHDL) | `14.2.0` | คอมไพล์ VHDL |
| Yosys | `0.52 (git sha1 fee39a3284c90249e1d9684cf6944ffbbcbb8f90)` | สังเคราะห์ Verilog → netlist |
| ABC (ใน Yosys) | เป็นส่วนหนึ่งของ Yosys 0.52 | map logic เข้าเซลล์จริงตาม Liberty |
| Icarus Verilog | `12.0 (stable)` | ใช้ตรวจ netlist เบา ๆ (ไม่จำเป็น) |
| IHP SG13G2 | `sg13g2_stdcell_typ_1p20V_25C` | ชุดเซลล์มาตรฐาน: Liberty + Verilog model |

ไฟล์ชุดเซลล์ที่ใช้จริง

| ไฟล์ | ขนาด | หน้าที่ |
|---|---|---|
| `cells/sg13g2_stdcell.v` | 56,308 bytes | โมเดลการจำลองของเซลล์ทั้งหมด 84 เซลล์ |
| `cells/sg13g2_udp.v` | 13,561 bytes | user defined primitives ที่เซลล์อ้างถึง |
| `cells/sg13g2_stdcell_typ_1p20V_25C.lib` | 1,748,984 bytes | Liberty ของ corner typ (1.20 V / 25 °C) |

> ไฟล์เซลล์ทั้งสองเป็นของ IHP PDK Authors แบบ Apache License 2.0
> (มีหัวข้อลิขสิทธิ์อยู่ในไฟล์ต้นฉบับ)

### 1.2 ⚠ เรื่องใบอนุญาต (license) — อ่านให้เข้าใจก่อนทำ lab

ใบอนุญาตของเครื่องนี้เป็น **node-locked แบบ session เดียว**
คือ **จำลองได้ทีละ session เท่านั้น**

ถ้ามี **QuestaSim GUI** เปิดค้างอยู่ (`vish.exe -gui`) มันจะถือ seat ของชุด QuestaSim
การรันแบบบรรทัดคำสั่งด้วยชุดนั้นจะถูกปฏิเสธว่า

```text
** Error: License checkout has been disallowed because
only one session is allowed to run on an uncounted nodelocked
license and an instance of QuestaSim is already running with a
nodelocked license on this machine.
```

แต่ **ModelSim DE-64 ยังรันได้ตามปกติ** เพราะเป็นอีก seat หนึ่ง

ทางแก้ที่คู่มือนี้ใช้: **ไม่ hardcode path ของชุดติดตั้งเลย**
แต่ให้ `tools/pick_tool.cmd` ไล่ทดสอบ license จริงของแต่ละชุด
(คอมไพล์ design จิ๋วแล้วโหลดจริง — เพราะ license ถูกเช็คตอน "โหลด design" เท่านั้น)
แล้วเลือกชุดแรกที่ใช้ได้

ผลที่วัดได้จริงขณะที่ QuestaSim GUI ยังเปิดค้างอยู่

```text
 tool   : C:\Siemens\modelsim_dlx64_2026.1\win64pe
```

ถ้าอยากบังคับให้ใช้ชุดใดชุดหนึ่ง ให้ตั้ง `QUESTASIM_HOME` หรือ `MODELSIM_HOME`

### 1.3 โครงสร้างโฟลเดอร์ของคู่มือ

```text
questa_gls_vhdl_lab/
├── docs/                     คู่มือฉบับนี้ (Markdown / HTML / PDF)
├── tools/
│   ├── pick_tool.cmd          เลือกชุดติดตั้งที่ยังมี license ว่าง (ใช้ร่วมกันทุก lab)
│   ├── run_template.cmd       เทมเพลต run.cmd ของ lab ที่จำลองครั้งเดียว
│   ├── run_template_2step.cmd เทมเพลต run.cmd ของ lab ที่ต้องรันสองครั้ง
│   ├── make-runners.ps1       ตัวสร้าง run.cmd ของทุก lab
│   ├── gls_common.do          proc ช่วยเหลือที่ทุก lab ใช้ร่วมกัน
│   ├── check_vhdl.sh          ตรวจ VHDL ทั้งหมดด้วย GHDL (รันใน WSL)
│   ├── synth/synth.sh         สคริปต์สังเคราะห์ VHDL -> netlist (รันใน WSL)
│   ├── build-docs.ps1         รวม Markdown แล้วสร้าง HTML + PDF
│   └── probe/probe_top.vhd    design จิ๋วสำหรับ license probe
├── rtl/                       โค้ด RTL ที่ใช้ในคู่มือ (VHDL)
│   ├── cnt4.vhd               ตัวนับ 4 บิต
│   ├── alu4.vhd               ALU 4 บิต
│   ├── fsm_light.vhd          FSM ไฟสัญญาณจราจร
│   └── sr16.vhd               shift register 16 บิต
├── netlist/                   gate netlist ที่สังเคราะห์ไว้แล้ว
│   ├── cnt4_net.v             netlist ปกติ
│   ├── cnt4_bug_net.v         netlist ที่ใส่บั๊กไว้ (LAB 07)
│   ├── vhdl2verilog/          Verilog กลางที่ GHDL สร้างแล้ว Yosys อ่านเข้าไป
│   ├── *_stat.txt             สถิติจาก Yosys
│   └── *_synth.log            log ฉบับเต็มของการสังเคราะห์
├── cells/                     โมเดลเซลล์ + Liberty ของ SG13G2
├── tb/                        testbench VHDL ที่ใช้ร่วมกันทุก lab
├── lab01_rtl_baseline/        ... lab08_gls_regression/
└── lab08_gls_regression/results/   ผลรวมของทั้งชุด
```

> **จุดสำคัญของโครงสร้างนี้**
> `rtl/`, `netlist/`, `cells/` และ `tb/` อยู่ระดับเดียวกัน
> และแต่ละ lab อ้างถึงด้วยพาธแบบสัมพัทธ์ (`../rtl/cnt4.vhd`)
> ทำให้ **testbench ชุดเดียวกันถูกใช้ได้ทั้งระดับ RTL และระดับ gate**
> ซึ่งเป็นหัวใจของคู่มือนี้

### 1.4 RTL กับ gate level ต่างกันอย่างไร

| | RTL simulation | Gate level simulation |
|---|---|---|
| สิ่งที่จำลอง | พฤติกรรมที่เขียนไว้ (`process (clk, rst_n)`) | โครงสร้างจริงของวงจร (ทรานซิสเตอร์ → เกต → เซลล์) |
| โมเดลของ flip-flop | ตัวแปร `unsigned` ที่มีพฤติกรรมตามโค้ด | `sg13g2_dfrbpq_1` ที่มี timing check และ specify block |
| ค่า `x` | มักถูกกลืนหายไป | แพร่ผ่านเกตตามธรรมชาติ |
| เวลาที่ใช้ | เวลาจำลองเท่ากันหมด (delta cycle) | เวลาหน่วงจริงของเซลล์ (ถ้าใส่ SDF) |
| ขนาด | เล็ก | ใหญ่กว่ามาก (นับจาก 11 เซลล์ ถึงหลายพัน) |
| จับบั๊กได้ | บั๊กเชิงตรรกะ | บั๊กเชิงตรรกะ **และ** บั๊กของตัวสังเคราะห์/ของ netlist |

### 1.5 GLS จับอะไรได้ที่ RTL ไม่จับ

คู่มือนี้จะให้พิสูจน์ด้วยการรันจริง 3 เรื่อง

1. **ค่า `x` ที่ RTL กลืนไว้ แต่ gate level จับได้** — LAB 06
2. **บั๊กใน netlist ที่ไม่มีใน RTL** — LAB 07
3. **ความจริงของโครงสร้างวงจร** — จำนวนเซลล์จริง, ชนิดเซลล์จริง, flip-flop จริง — LAB 02

### 1.6 คำสั่งพื้นฐานที่ใช้บ่อย

```tcl
vlib work                 :: สร้างไลบรารีชื่อ work
vmap work work            :: ผูกชื่อ work ให้โฟลเดอร์ work
vcom -2008 -work work x.vhd :: คอมไพล์ VHDL เข้าไลบรารี work
vlog -work work x.v       :: คอมไพล์ Verilog เข้าไลบรารี work
vsim -t 10ps -voptargs=+acc work.tb_cnt4 :: โหลด design (+acc ถ้าจะดูค่าใน hierarchy)
run -all                  :: จำลองจนจบ
quit -f                   :: ออกจากตัวจำลอง
```

ส่วน VHDL ที่ใช้ในคู่มือนี้

```tcl
vsim -t 10ps work.tb_cnt4 -gTRACEFILE=results/trace.txt -gRESULTFILE=results/result.txt
```

คำสั่ง `-g<ชื่อ>=<ค่า>` ส่งค่าเข้าไปใน **generic ของ entity** ของ testbench
คู่มือนี้ใช้ generic 3 ตัวกับทุก testbench

| generic | ชนิด | ค่าเริ่มต้น | หน้าที่ |
|---|---|---|---|
| `TRACEFILE` | `string` | `"trace.txt"` | ไฟล์ที่จะเขียน trace |
| `RESULTFILE` | `string` | `"result.txt"` | ไฟล์ที่จะเขียนคำตัดสิน `PASS` / `FAIL` |
| `GATE` | `boolean` | `false` | `true` = บอก testbench ว่านี่คือการรันระดับ gate |

### 1.7 หัวใจของคู่มือนี้ — testbench ชุดเดียว ขับทั้งสองระดับ

นี่คือปัญหาหลักของการผสม VHDL กับ Verilog:
**ถ้า testbench เขียน `entity work.cnt4` มันจะผูกกับ entity ของ VHDL เท่านั้น
และจะไม่มีทางขับ Verilog netlist ได้เลย**

วิธีแก้คือ **ประกาศ DUT เป็น `component`** แทน `entity`
แล้วปล่อยให้ ModelSim ทำ **default binding** ซึ่งจะผูก `component` ที่มีชื่อเดียวกัน
เข้ากับ design unit ที่ชื่อนั้นในไลบรารี `work` ไม่ว่าจะเป็น VHDL entity หรือ Verilog module

`tb/tb_cnt4.vhd` (ตัดเฉพาะส่วนสำคัญ)

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_cnt4 is
  generic (
    TRACEFILE  : string  := "trace.txt";
    RESULTFILE : string  := "result.txt";
    GATE       : boolean := false
  );
end entity tb_cnt4;

architecture sim of tb_cnt4 is
  constant CYCLE : time := 10 ns;

  signal clk   : std_logic := '0';
  signal rst_n : std_logic := '0';
  signal en    : std_logic := '1';
  signal q     : std_logic_vector(3 downto 0);

  -- ประกาศเป็น COMPONENT ไม่ใช่ entity work.cnt4
  component cnt4 is
    port (
      clk   : in  std_logic;
      rst_n : in  std_logic;
      en    : in  std_logic;
      q     : out std_logic_vector(3 downto 0)
    );
  end component cnt4;
begin
  clk <= not clk after CYCLE / 2;

  dut : cnt4
    port map (
      clk   => clk,
      rst_n => rst_n,
      en    => en,
      q     => q
    );
  -- ... ส่วน stimulus ...
end architecture sim;
```

จากนั้นสลับแค่ **ไฟล์ที่คอมไพล์เข้า `work`** ก็พอ

```tcl
# --- ระดับ RTL : VHDL entity ---
vcom -2008 -work work ../rtl/cnt4.vhd
vcom -2008 -work work ../tb/tb_cnt4.vhd
vsim -t 10ps work.tb_cnt4 -gTRACEFILE=results/trace_rtl.txt -gGATE=false

# --- ระดับ gate : Verilog module ---
vlog -work work ../cells/sg13g2_stdcell.v
vlog -work work ../netlist/cnt4_net.v
vcom -2008 -work work ../tb/tb_cnt4.vhd
vsim -t 10ps work.tb_cnt4 -gTRACEFILE=results/trace_gls.txt -gGATE=true
```

ข้อสังเกตสำคัญจากการรันจริง: **ข้อความใน console ของ ModelSim บอกได้ว่าผูกกับอะไร**

```text
# RTL  : Loading work.cnt4(rtl)      <- ผูกกับ entity ของ VHDL
# GLS  : Loading work.cnt4            <- ผูกกับ module ของ Verilog
```

#### อีกทางหนึ่งที่ใช้ได้ แต่คู่มือนี้เลือกไม่ใช้

การทดลองจริงพบว่า ModelSim 2026.1 **ผูก entity declaration ของ VHDL
เข้ากับ Verilog module ที่ชื่อเดียวกันได้เลย** (mixed-language default binding)

```vhdl
-- รูปแบบที่ใช้ได้ใน ModelSim แต่ไม่ใช้ในคู่มือนี้
dut : entity work.cnt4 port map ( ... );
```

เมื่อทดลองให้ `entity work.cnt4` ไปขับ netlist ของ Verilog
ModelSim ผูกได้จริง และเซลล์ทั้งหมดถูกโหลดเข้ามา

```text
# Loading work.tb_cnt4_entity(sim)
# Loading work.cnt4
# Loading work.sg13g2_nand3_1
# Loading work.sg13g2_dfrbpq_1
# Loading work.ihp_dff_r
```

และ trace ที่ได้คือ `q=1,2,3,4,5,6,7,8,9` — ตัวนับเดินจริง

**แต่คู่มือนี้ยังเลือกใช้ `component`** เพราะเหตุผลสามข้อ

1. **เป็นวิธีมาตรฐานและ portable** — กฎ default binding ของ LRM ให้ผูกได้ทั้งสองภาษา
   วิธี `entity work.x` ผูก Verilog module เป็นความสามารถเฉพาะของ ModelSim
   เมื่อย้ายไปใช้ Questa/ตัวจำลองอื่น หรือเอา testbench ไปใช้กับ GHDL
   วิธี `component` ยังทำงาน ส่วน `entity work.x` ไม่แน่นอน
2. **อ่านง่ายกว่า** — เห็นชัดว่ากำลังผูกกับ "ชื่อ" ไม่ใช่ "entity ใด entity หนึ่ง"
3. **ถ้าชื่อไม่ตรง จะได้ข้อความ error ที่ชัดเจน** ตอนคอมไพล์
   ไม่ใช่ error ลอย ๆ ตอนโหลด design

> บทเรียนที่ควรจำ: **ชื่อ entity และชื่อ module ต้องตรงกัน**
> นี่คือเหตุผลที่ `rtl/*.vhd` และ `netlist/*_net.v` ต้องตั้งชื่อให้เหมือนกันทุกตัวอักษร

### 1.8 กฎการผสม VHDL กับ Verilog (วัดแล้วพลาดได้จริง)

1. **ชื่อ entity/module ต้องตรงกันทุกตัวอักษรและเป็นตัวพิมพ์เล็กทั้งหมด**
   Verilog เป็น case-sensitive และ VHDL ก็ case-sensitive เช่นกัน
   ชื่อ `fsm_light` ต้องตรงกันจริง ๆ ไม่ใช่ `FSM_Light` หรือ `fsm_Light`

2. **ชื่อ port ต้องตรงกันและเป็นตัวพิมพ์เล็ก**
   เมื่อ GHDL แปลง VHDL เป็น Verilog มันจะ **แปลงชื่อ port ทั้งหมดเป็นตัวพิมพ์เล็ก**
   ดังนั้น `rst_n` ต้องเป็น `rst_n` ไม่ใช่ `RST_N` แม้ในไฟล์ VHDL จะเขียนตัวใหญ่ก็ได้

3. **ชนิดของ port ต้องเข้ากันได้**
   `std_logic_vector` ↔ Verilog `[3:0]` ผสมกันได้
   แต่ `unsigned` ต้องแปลงเป็น `std_logic_vector` ก่อนออกจาก entity

4. **`numeric_std` ไม่มี `std_logic_vector + integer`**
   ต้องใช้ `unsigned` หรือ `unsigned_vector` ภายใน แล้วค่อยแปลงกลับที่ port

5. **ค่าเริ่มต้นของ signal ต้องเป็น `:=` ใน declaration**
   `signal clk : std_logic := '0';` — ถ้าไม่ใส่ `:= '0'` นาฬิกาจะเริ่มเป็น `'U'`
   และ `not 'U'` ก็ยังเป็น `'U'` → **นาฬิกาจะไม่เดินเลย** ตลอดการจำลอง

6. **`trim` และ `time'image` ไม่มีใน GHDL VHDL-2008**
   `integer'image(5)` จะพิมพ์ `" 5"` (มีช่องว่างนำหน้า) ต้องตัดออก
   `time'image` จะพิมพ์หน่วยตาม resolution ของตัวจำลอง ซึ่งต่างกันระหว่าง ModelSim กับ GHDL
   คู่มือนี้มี helper `nospace()` และ `timestr()` ใน testbench ทุกไฟล์เพื่อแก้ปัญหานี้

7. **VHDL ใช้ `wait until rising_edge(clk)` ไม่ได้ถ้า clock เป็น `'U'`**
   ต้องประกาศ `signal clk : std_logic := '0';` เสมอ (ข้อ 5)

### 1.9 ⚠ ข้อผิดพลาดที่ต้องรู้ก่อนเริ่ม: `vsim-3693`

ถ้าคอมไพล์เซลล์ Verilog ของ SG13G2 แล้วโหลด design **โดยไม่ใส่ `-t 10ps`**
จะได้ข้อความนี้

```text
** Fatal: (vsim-3693) The minimum time resolution limit (10ps)
in the Verilog source is smaller than the one chosen for SystemC or VHDL
units in the design. Use the vsim -t option to set the resolution.
```

**สาเหตุ:** โมเดลเซลล์ของ SG13G2 ประกาศ `timescale 1ns/10ps`
แต่ค่าเริ่มต้นของ ModelSim คือ 1 ps ซึ่ง**ละเอียดกว่า** 10 ps
ModelSim จึงห้ามและให้เลือก resolution ที่หยาบพอ

**วิธีแก้:** ใส่ `-t 10ps` ในทุกคำสั่ง `vsim` ของโปรเจกต์นี้

```tcl
vsim -t 10ps -voptargs=+acc work.tb_cnt4 ...
```

> ข้อความนี้เป็นของจริงที่เจอระหว่างทำคู่มือนี้ ไม่ใช่ตัวอย่างสมมติ
> และเป็นข้อผิดพลาดที่มักพบบ่อยที่สุดเมื่อข้ามจาก Verilog มาใช้ VHDL

---

## บทที่ 2 — สังเคราะห์ netlist จาก VHDL

### 2.1 สายการผลิต

```text
rtl/cnt4.vhd  (VHDL)
      │
      │  ghdl synth --std=08 --out=verilog
      ▼
netlist/vhdl2verilog/cnt4_rtl.v  (Verilog)
      │
      │  yosys + sg13g2_stdcell_typ_1p20V_25C.lib
      ▼
netlist/cnt4_net.v  (gate netlist, Verilog)
```

จุดที่ต้องเข้าใจ: **Yosys ไม่รู้จัก VHDL**
การใช้ `yosys-ghdl` plugin ก็ยังยุ่งกว่าการให้ GHDL แปลงเป็น Verilog ก่อน
เพราะ GHDL เป็นตัวแปลงที่เข้าใจ semantics ของ VHDL ดีกว่า
(เช่น `std_logic_vector` ที่มีค่า `'X'` และ `'Z'`)

คู่มือนี้เลือกวิธีที่ **ตรวจสอบได้ง่ายที่สุด** คือเก็บไฟล์ Verilog กลางไว้ให้ดู
(`netlist/vhdl2verilog/`) เพื่อให้เห็นชัดว่า Yosys "เห็น" อะไร

### 2.2 เตรียม WSL

สคริปต์สังเคราะห์ต้องรันใน Linux (WSL) เพราะ Yosys และ GHDL ที่ติดตั้งอยู่ในนั้น

```bash
wsl -d Ubuntu -u root -- bash /mnt/c/Users/000148/Documents/MiniMax/eda-tools/questa_gls_vhdl_lab/tools/synth/probe_env.sh
```

ผลจริงที่วัดได้

```text
--- ghdl ---
ghdl (Ubuntu 5.0.1+dfsg-1ubuntu1) [Dunoon edition]
 Compiled with GNAT Version: 14.2.0
 static elaboration, mcode JIT code generator
--- yosys ---
Yosys 0.52 (git sha1 fee39a3284c90249e1d9684cf6944ffbbcbb8f90)
--- ghdl plugin ---
ghdl.so
--- liberty ---
-rw-r--r-- 1 root root 1748984 ... sg13g2_stdcell_typ_1p20V_25C.lib
--- iverilog / verilator ---
Icarus Verilog version 12.0 (stable) ()
```

> **หมายเหตุเรื่อง PATH**
> `yosys-ghdl` plugin ที่ใช้จริงอยู่ที่
> `/nix/store/55al5ccngwgjgigi20jh6d3my8h9x0i2-yosys-ghdl-2026-01-11/share/yosys/plugins/ghdl.so`
> แต่ใน WSL แบบ non-interactive **nix profile จะไม่ถูกโหลดใน PATH อัตโนมัติ**
> สคริปต์จึงต้องมีบรรทัดนี้ทุกครั้ง
>
> ```bash
> export PATH="/root/.nix-profile/bin:$PATH"
> ```
>
> ถ้าไม่ใส่ จะเจอ `librelane: command not found` หรือ `yosys: command not found`
> แม้ทั้งสองโปรแกรมจะมีอยู่จริง

### 2.3 ขั้นที่ 1: GHDL แปลง VHDL เป็น Verilog

```bash
ghdl -a --std=08 rtl/cnt4.vhd
ghdl synth --std=08 --out=verilog cnt4 > netlist/vhdl2verilog/cnt4_rtl.v
```

> ⚠ **ลำดับ option สำคัญ**
> ต้องเป็น `ghdl synth --std=08 --out=verilog <top>` เท่านั้น
> ถ้าสลับลำดับ (`--out=verilog` ก่อน `--std=08`) จะได้ `unknown command`
> และต้อง redirect เองด้วย `>` เพราะ GHDL ไม่มีตัวเลือกชื่อไฟล์

ผลที่ได้คือ Verilog 30 บรรทัด (วัดได้จริง) ดูไฟล์เต็มได้ที่ `netlist/vhdl2verilog/cnt4_rtl.v`

```verilog
module cnt4
  (input  clk,
   input  rst_n,
   input  en,
   output [3:0] q);
  reg [3:0] cq;
  wire n4_o;
  wire [3:0] n7_o;
  wire [3:0] n13_o;
  reg [3:0] n14_q;
  assign q = cq; //(module output)
  /* rtl/cnt4.vhd:18:10  */
  always @*
    cq = n14_q; // (isignal)
  initial
    cq = 4'b0000;
  /* rtl/cnt4.vhd:23:14  */
  assign n4_o = ~rst_n;
  /* rtl/cnt4.vhd:27:18  */
  assign n7_o = cq + 4'b0001;
  /* rtl/cnt4.vhd:25:5  */
  assign n13_o = en ? n7_o : cq;
  /* rtl/cnt4.vhd:25:5  */
  always @(posedge clk or posedge n4_o)
    if (n4_o)
      n14_q <= 4'b0000;
    else
      n14_q <= n13_o;
endmodule
```

สังเกตสิ่งที่น่าสนใจมากในบรรทัดนี้

```verilog
assign n13_o = en ? n7_o : cq;
```

นี่คือจุดที่ **semantics ของ VHDL กับ Verilog ต่างกันอย่างมีนัยสำคัญ** และเป็นแก่นของ LAB 06

| | VHDL ต้นฉบับ | Verilog ที่ GHDL สร้าง |
|---|---|---|
| เงื่อนไข | `if en = '1' then` | `en ? n7_o : cq` |
| `en = 'X'` | `'X' = '1'` → **false** → ทำ else (คงค่าเดิม) | `?:` → **propagate X** → ผลเป็น `X` |
| `en = '0'` | false → else | false → else |

คู่มือนี้จะพิสูจน์ความต่างนี้ด้วยการรันจริงใน LAB 06

### 2.4 ขั้นที่ 2: Yosys + Liberty

```bash
yosys -l netlist/cnt4_synth.log -p "
  read_verilog netlist/vhdl2verilog/cnt4_rtl.v
  hierarchy -check -top cnt4
  proc
  opt
  fsm
  opt
  memory
  opt
  techmap
  opt
  dfflibmap -liberty $PDK_LIB
  abc -liberty $PDK_LIB
  setundef -zero
  splitnets
  opt_clean
  write_verilog -noattr netlist/cnt4_net.v
  tee -o netlist/cnt4_stat.txt stat
"
```

จุดที่ต้องระวัง (วัดแล้วพลาดมาแล้ว)

- **`dfflibmap -liberty` ต้องมาก่อน `abc -liberty` เสมอ**
  ไม่งั้น ABC จะไม่เห็นฟลิป-flop ที่ map แล้ว
- **`abc` ไม่รองรับ gate type `NOT`** — โค้ดจะสร้าง inverter ให้อัตโนมัติ
- **Yosys `fsm` pass แปลง FSM แบบ binary เป็น one-hot โดยอัตโนมัติ**
  `fsm_light` มี 4 สถานะ → เป็น one-hot → flip-flop เพิ่มจาก 2 เป็น 5
  (ถ้าต้องการคุมเอง ใช้ `fsm -norecode` หรือเขียน FSM เป็น one-hot ตั้งแต่ RTL)
- **`/usr/share/yosys/cells.lib` ที่มากับ distro มีแต่ DFF ไม่มี gate**
  map logic ที่เป็น combinational ไม่ได้ ต้องใช้ Liberty ของ PDK เสมอ

### 2.5 ผลลัพธ์จริงของทั้ง 4 ดีไซน์

ตัวเลขทั้งหมดในตารางนี้มาจาก `netlist/*_stat.txt` ที่ Yosys เขียนออกมาจริง

| ดีไซน์ | เซลล์ทั้งหมด | ชนิดเซลล์ | flip-flop | ขนาด Verilog กลาง |
|---|---|---|---|---|
| `cnt4` | **11** | 7 | 4 | 30 บรรทัด |
| `alu4` | **59** | 19 | 4 | 77 บรรทัด |
| `fsm_light` | **11** | 4 | 5 | 97 บรรทัด |
| `sr16` | **100** | 14 | 16 | 57 บรรทัด |

รายละเอียดรายเซลล์ของ `cnt4` (จาก `netlist/cnt4_stat.txt`)

```text
   Number of cells:                 11
     sg13g2_a21o_1                   1
     sg13g2_and2_1                   1
     sg13g2_dfrbpq_1                 4
     sg13g2_nand3_1                  1
     sg13g2_nand4_1                  1
     sg13g2_xnor2_1                  2
     sg13g2_xor2_1                   1
```

รายละเอียดรายเซลล์ของ `sr16` (100 เซลล์ — ใหญ่ที่สุดในชุดนี้)

```text
   Number of cells:                100
     sg13g2_a21o_1                   5
     sg13g2_a221oi_1                 8
     sg13g2_a22oi_1                  3
     sg13g2_and2_1                   3
     sg13g2_dfrbpq_1                16
     sg13g2_inv_1                    6
     sg13g2_nand2_1                  6
     sg13g2_nand2b_1                 2
     sg13g2_nand3_1                  7
     sg13g2_nand3b_1                 8
     sg13g2_nand4_1                 11
     sg13g2_nor2_1                   5
     sg13g2_nor2b_1                 10
     sg13g2_o21ai_1                 10
```

### 2.6 อ่าน netlist ที่ได้

`netlist/cnt4_net.v` (เหลือเฉพาะส่วนที่น่าสนใจ)

```verilog
module cnt4(clk, rst_n, en, q);
  ...
  sg13g2_nand3_1 _07_ (
    .A(en),
    .B(\n14_q[0] ),
    .C(\n14_q[1] ),
    .Y(_04_)
  );
  ...
  sg13g2_dfrbpq_1 _16_ (
    .CLK(clk),
    .D(_02_),
    .Q(\n14_q[1] ),
    .RESET_B(rst_n)
  );
  ...
  assign q = { \n14_q[3] , \n14_q[2] , \n14_q[1] , \n14_q[0]  };
endmodule
```

สิ่งที่ควรสังเกต

- ชื่อสัญญาณภายในของ Yosys เป็นรูปแบบ `\n14_q[1] ` (มี **เว้นวรรคท้าย**
  เพราะ Yosys escape ชื่อที่มี `[` ด้วย backslash แล้วเติมช่องว่างปิดท้าย)
- flip-flop คือ `sg13g2_dfrbpq_1` มีพอร์ต `RESET_B` (reset แบบ active-low และ asynchronous)
  ตรงกับ `if rst_n = '0' then` ใน RTL พอดี
- ชนิดเซลล์ทั้งหมดเป็น `sg13g2_..._1` คือ **ความแรงขับ (drive strength) ระดับ 1**

### 2.7 รันสังเคราะห์ใหม่เอง

```bash
wsl -d Ubuntu -u root -- bash /mnt/c/Users/000148/Documents/MiniMax/eda-tools/questa_gls_vhdl_lab/tools/synth/synth.sh
```

หรือสังเคราะห์เฉพาะบางดีไซน์

```bash
wsl -d Ubuntu -u root -- bash /mnt/c/Users/000148/Documents/MiniMax/eda-tools/questa_gls_vhdl_lab/tools/synth/synth.sh cnt4 alu4
```

> **ต้องแก้ path ของ Liberty ให้ตรงกับเครื่อง**
> ค่า default ใน `tools/synth/synth.sh` คือ
> `/mnt/e/lab/pdks/IHP-Open-PDK/ihp-sg13g2/libs.ref/sg13g2_stdcell/lib/sg13g2_stdcell_typ_1p20V_25C.lib`
> ถ้า PDK อยู่ที่อื่น ให้แก้ตัวแปร `PDK_LIB` ในสคริปต์
> (สคริปต์จะเช็คและหยุดพร้อมข้อความชัดเจนถ้าไม่เจอไฟล์)

---

## บทที่ 3 — LAB 01: RTL baseline (VHDL)

### เป้าหมาย

สร้าง **จุดอ้างอิง** ของทั้งคู่มือ
testbench ไฟล์นี้จะถูกใช้ซ้ำใน LAB 04 ถึง LAB 08 โดยไม่แก้แม้แต่บรรทัดเดียว
และ trace ที่ได้ต้องเหมือนกันทุกบรรทัด

### ขั้นที่ 1 — เข้าโฟลเดอร์ lab

```bat
cd C:\Users\000148\Documents\MiniMax\eda-tools\questa_gls_vhdl_lab\lab01_rtl_baseline
```

### ขั้นที่ 2 — รัน

```bat
run.cmd
```

### ผลลัพธ์จริง

```text
====================================================================
 LAB 01 : RTL baseline (VHDL)
 cwd    : C:\Users\000148\Documents\MiniMax\eda-tools\questa_gls_vhdl_lab\lab01_rtl_baseline
 tool   : C:\Siemens\modelsim_dlx64_2026.1\win64pe
 expect : PASS -- 9 checks, 0 errors
====================================================================
...
# ** Note: === tb_cnt4 : RTL ===
# ** Note:   t=20 ns : after reset         q = 0
# ** Note:   t=26 ns : count up 1            q = 1
# ** Note:   t=36 ns : count up 2            q = 2
# ** Note:   t=46 ns : count up 3            q = 3
# ** Note:   t=56 ns : count up 4            q = 4
# ** Note:   t=66 ns : count up 5            q = 5
# ** Note:   t=76 ns : count up 6            q = 6
# ** Note:   t=106 ns : hold (en = '0')     q = 6
# ** Note:   t=136 ns : count up again     q = 9
# ** Note:  checks = 9 , errors = 0
   the RTL verdict : PASS
   the trace file  : results/trace_rtl.txt
RESULT: PASS
[RESULT] PASS
```

`results/trace_rtl.txt` มี 9 บรรทัด

```text
q=0
q=1
q=2
q=3
q=4
q=5
q=6
q=6
q=9
```

อ่านให้เข้าใจ trace นี้ — มันคือสิ่งที่ testbench ทำ
(คอลัมน์ "เวลา" มาจากข้อความ `report` ที่ testbench พิมพ์ออกมา วัดจริง)

| บรรทัด | เวลา | เหตุการณ์ | ค่า `q` ที่ถูกต้อง | `q` จริง |
|---|---|---|---|---|
| 1 | 20 ns | หลัง reset | `0` | `0` |
| 2 | 26 ns | นับขึ้นครั้งที่ 1 | `1` | `1` |
| 3 | 36 ns | นับขึ้นครั้งที่ 2 | `2` | `2` |
| 4 | 46 ns | นับขึ้นครั้งที่ 3 | `3` | `3` |
| 5 | 56 ns | นับขึ้นครั้งที่ 4 | `4` | `4` |
| 6 | 66 ns | นับขึ้นครั้งที่ 5 | `5` | `5` |
| 7 | 76 ns | นับขึ้นครั้งที่ 6 | `6` | `6` |
| 8 | 106 ns | `en = '0'` → คงค่า | `6` | `6` |
| 9 | 136 ns | นับต่อ 3 ครั้ง | `9` | `9` |

**ตรวจสอบเวลาด้วยตัวเองได้** — นาฬิกามีคาบ 10 ns และขอบขึ้นที่ 5, 15, 25, … ns
- reset จบที่ `2 × CYCLE` = 20 ns → ตรวจครั้งแรกที่ 20 ns
- นับขึ้น: รอขอบขึ้น (25, 35, 45, …) แล้วรออีก 1 ns → 26, 36, 46, … ns
- `en = '0'` ค้างไว้ 3 รอบนาฬิกา = 30 ns → 76 + 30 = 106 ns
- นับต่อ 3 ครั้ง: 115 + 125 + 135 แล้วรออีก 1 ns → **136 ns**
  ซึ่งตรงกับ `Time: 136 ns` ที่ ModelSim พิมพ์ตอนจบการจำลอง

> สังเกตว่าค่า hex เป็น **ตัวพิมพ์ใหญ่** เพราะ VHDL ใช้ `to_hstring()`
> ใน Verilog จะได้ตัวพิมพ์เล็กจาก `%h`
> นี่เป็นความต่างที่ต้องรู้เมื่อเปรียบเทียบ trace ข้ามภาษา

### ขั้นที่ 3 — ตรวจสอบเอง

```bat
type results\trace_rtl.txt
type result.txt
```

`result.txt` ต้องเป็น `PASS` และ `run.cmd` ต้องจบด้วยรหัส 0

```bat
echo %ERRORLEVEL%
```

### เก็บความรู้จาก LAB นี้

- testbench เขียน `component cnt4` ไม่ใช่ `entity work.cnt4` → **คัดลอกไฟล์นี้ไปใช้ได้ทั้งระดับ gate**
- ใช้ generic `GATE` เป็นตัวบอก testbench ว่าตอนนี้อยู่ระดับไหน
  ทำให้ testbench เดียวกันพิมพ์ข้อความหัวข้างว่าเป็น RTL หรือ GATE ได้

---

## บทที่ 4 — LAB 02: netlist ที่สังเคราะห์ได้

### เป้าหมาย

ตรวจว่า **netlist ที่ Yosys สร้างใช้เซลล์ที่มีอยู่จริงในไลบรารี**
และเห็นความจริงของโครงสร้างวงจร — ตัวนับ 4 บิตต้องมี 4 flip-flop พอดี

### รัน

```bat
cd C:\Users\000148\Documents\MiniMax\eda-tools\questa_gls_vhdl_lab\lab02_synth_netlist
run.cmd
```

### ผลลัพธ์จริง (ส่วนสำคัญ)

```text
---- 1. the statistics file ----
Number of wires:                 19
Number of ports:                  4
Number of cells:                11
   sg13g2_a21o_1            1
   sg13g2_and2_1            1
   sg13g2_dfrbpq_1          4
   sg13g2_nand3_1           1
   sg13g2_nand4_1           1
   sg13g2_xnor2_1           2
   sg13g2_xor2_1            1
---- 2. the cells used by the netlist ----
   sg13g2_nand3_1
   sg13g2_nand4_1
   sg13g2_xnor2_1
   sg13g2_xor2_1
   sg13g2_a21o_1
   sg13g2_and2_1
   sg13g2_dfrbpq_1
---- 11 instances, 7 different cell types ----
---- 3. check every cell against the library ----
   OK : every cell of the netlist exists in ../cells/sg13g2_stdcell.v
---- 4. the Verilog that Yosys actually read ----
module cnt4
input  rst_n,
input  en,
output [3:0] q);
reg [3:0] cq;
wire n4_o;
wire [3:0] n7_o;
wire [3:0] n13_o;
reg [3:0] n14_q;
always @*
always @(posedge clk or posedge n4_o)
endmodule
---- 5. the design needs 4 flip-flops (a 4 bit counter needs 4) ----
   the netlist has 4 flip-flop(s)
RESULT: PASS
```

> สังเกตว่า transcript จะมีบรรทัดที่ขึ้นต้นด้วย `#` เป็นการ **echo คำสั่ง Tcl ที่กำลังทำงาน**
> เช่น `# ../netlist/cnt4_net.v` คือการ echo ค่าในตัวแปร
> และตอนขั้นที่ 3 จะเห็นเนื้อหาไฟล์เซลล์ทั้งไฟล์ถูก echo ออกมาเป็น `# ...`
> **นั่นไม่ใช่ error** แค่ข้อความใน console

ตัวเลขที่ต้องจำไว้

| สิ่งที่วัด | ค่า |
|---|---|
| instance ทั้งหมดใน netlist | **11** |
| ชนิดเซลล์ที่ต่างกัน | **7** |
| flip-flop | **4** |
| เซลล์ที่หาไม่พบในไลบรารี | **0** |

### ⚠ กับดัก Tcl ที่เจอระหว่างทำ lab นี้

ตอนตรวจว่าเซลล์มีอยู่ในไลบรารีจริง ต้องใช้ regex

```tcl
set found [regexp [format {module\s+%s\s*\(} $c] $libtxt]
```

> **ห้ามเขียน `"\s"` ใน double quotes**
> ใน Tcl เมื่ออยู่ใน double quotes แล้ว `\s` จะกลายเป็น `s` (backslash หายไป)
> pattern จะกลายเป็น `modules+...` แล้วไม่มีทาง match
> ทางแก้คือใช้ **braces** `{...}` หรือ `format {...}` เสมอ

คู่มือนี้แก้ให้เรียบร้อยแล้วใน `lab02_synth_netlist/run_batch.do`

---

## บทที่ 5 — LAB 03: เซลล์มาตรฐานของ SG13G2

### เป้าหมาย

ก่อนจะจำลอง netlist ได้ ตัวจำลองต้อง "รู้จัก" เซลล์แต่ละตัวว่าคืออะไร
lab นี้จะคอมไพล์โมเดลเซลล์ทั้ง 84 ตัว แล้วจำแนกให้ดู

### รัน

```bat
cd C:\Users\000148\Documents\MiniMax\eda-tools\questa_gls_vhdl_lab\lab03_cell_library
run.cmd
```

### ผลลัพธ์จริง

```text
---- 1. compile the cell models into the library 'sg13g2' ----
---- 2. the cells of the library ----
   84 modules

   flip-flops (sequential)  : 9
        sg13g2_dfrbp_1
        sg13g2_dfrbp_2
        sg13g2_dfrbpq_1
        sg13g2_dfrbpq_2
        sg13g2_sdfbbp_1
        sg13g2_sdfrbp_1
        sg13g2_sdfrbp_2
        sg13g2_sdfrbpq_1
        sg13g2_sdfrbpq_2
   latches + latch clocks   : 7
        sg13g2_dlhq_1
        sg13g2_dlhr_1
        sg13g2_dlhrq_1
        sg13g2_dllr_1
        sg13g2_dllrq_1
        sg13g2_lgcp_1
        sg13g2_slgcp_1
   delay cells              : 3
        sg13g2_dlygate4sd1_1
        sg13g2_dlygate4sd2_1
        sg13g2_dlygate4sd3_1
   utility / physical only  : 10
        sg13g2_antennanp
        sg13g2_decap_4
        sg13g2_decap_8
        sg13g2_fill_1
        sg13g2_fill_2
        sg13g2_fill_4
        sg13g2_fill_8
        sg13g2_sighold
        sg13g2_tiehi
        sg13g2_tielo
   combinational gates      : 55
   sum of the 5 groups      : 84  (total 84)

---- 3. the Liberty file ----
   library (sg13g2_stdcell_typ_1p20V_25C) {
   capacitive_load_unit (1,pf);
   current_unit : "1uA";
   time_unit : "1ns";
   voltage_unit : "1V";
   size of the Liberty file : 1748984 bytes
RESULT: PASS
```

### ตารางสรุป

| กลุ่ม | จำนวน |
|---|---|
| flip-flop (sequential) | 9 |
| latch + latch clock | 7 |
| delay cell | 3 |
| utility / physical only | 10 |
| combinational gate | 55 |
| **รวม** | **84** |

### ⚠ อ่าน "ชนิด" ของเซลล์ให้ถูกวิธี

`run_batch.do` ของ lab นี้ **ไม่ได้** จำแนกจากชื่อเซลล์
แต่อ่านคอมเมนต์ `// type: XXX` ที่อยู่เหนือ `module` ในไฟล์ `sg13g2_stdcell.v`

```tcl
if {[regexp {^\s*//\s*type:\s*(\S+)\s*$} $line -> t]} {
    set curtype $t
    continue
}
if {[regexp {^\s*module\s+([A-Za-z0-9_]+)\s*\(} $line -> name]} {
    lappend mods $name
    lappend types $curtype
    set curtype ""
}
```

**ทำไมต้องอ่าน `// type:`** เพราะชื่อเซลล์หลอกตาได้มาก

| ชื่อเซลล์ | ดูเหมือนจะเป็น | จริง ๆ แล้วเป็น |
|---|---|---|
| `sg13g2_dfrbp_1` | flip-flop | ✅ flip-flop |
| `sg13g2_decap_4` | อะไรซักอย่าง | ❌ **decapacitor** (ใช้ไฟล์เฉพาะทาง ไม่ใช่เกต) |
| `sg13g2_dlygate4sd1_1` | gate | ❌ **delay cell** |
| `sg13g2_dlhr_1` | "d-l-h-r" | ❌ **latch** |
| `sg13g2_tiehi` | gate | ❌ **tie cell** |

> คู่มือฉบับ Verilog รุ่นแรกจำแนกจาก **ชื่อเซลล์** แล้วได้ตัวเลขผิด
> ต้องแก้มาใช้ `// type:` จึงได้ 9 / 7 / 3 / 10 / 55 = 84 ที่ถูกต้อง
> **เป็นบทเรียนที่ควรจำ: อย่าตัดสินเซลล์จากชื่อ**

### เซลล์ latch ในไลบรารี — ทำไมต้องรู้

ในไลบรารีมี latch 7 ตัว
ถ้า Yosys map ล็อกให้เป็น latch เมื่อออกแบบไม่ดี (เช่น case statement ที่ไม่ครบ)
การจำลองระดับ gate จะเผยอาการ **ล็อกค้าง** ที่ RTL จะไม่เห็น
เพราะ RTL จะเขียน `if ... then ... else ...` เสมอ

> ข้อเท็จจริงที่วัดได้: **`dfflibmap` ของ Yosys map ได้แต่ flip-flop
> แต่ map latch ไม่ได้** ถ้าเจอ latch ใน netlist ให้ระวัง

---

## บทที่ 6 — LAB 04: การจำลองระดับ gate ครั้งแรก

### เป้าหมาย

รัน **testbench ไฟล์เดียวกันจาก LAB 01** กับ gate netlist
และได้ trace ที่เหมือนกันทุกบรรทัด

### ขั้นที่ 1 — ลองทำผิดวิธีก่อน (ตั้งใจให้ผิด)

คู่มือนี้ให้ลองผิดวิธีก่อน เพื่อให้เห็นข้อความ error จริงด้วยตาตัวเอง

```bat
cd C:\Users\000148\Documents\MiniMax\eda-tools\questa_gls_vhdl_lab\lab04_gls_first
run_wrong.cmd
```

`run_wrong.cmd` นี้ทำสิ่งที่ผิดอย่างตั้งใจ:
คอมไพล์เซลล์เข้าไลบรารี `cells_lib` แต่คอมไพล์ netlist เข้า `work`
ผลคือโหลด design ไม่ได้

### ผลลัพธ์จริง

```text
# ** Error: (vsim-3033) Instantiation of 'sg13g2_nand3_1' failed. The design unit was not found.
#    Time: 0 ps  Iteration: 0  Instance: /tb_cnt4/dut File: ../netlist/cnt4_net.v Line: 34
#         Searched libraries:
#             C:/Users/.../questa_gls_vhdl_lab/lab04_gls_first/work
# ** Error: (vsim-3033) Instantiation of 'sg13g2_nand4_1' failed. The design unit was not found.
...
# ** Error: (vsim-3033) Instantiation of 'sg13g2_dfrbpq_1' failed. The design unit was not found.
# Error loading design
# Errors: 11, Warnings: 0

---- the error that was expected ----
  the transcript contains 11 line(s) with "vsim-3033"
  (one line per instance of a cell that could not be found)
  the exit code of vsim itself was 12
  NOTE : a .do file that cannot be opened gives exit code 0 too
         (measured on this machine).  A build system that only looks at
         the exit code will NOT notice that failure -- always read the
         transcript.

[RESULT] AS EXPECTED -- the simulator refused the design
```

### สิ่งที่ต้องสังเกตจาก error นี้

1. **จำนวนบรรทัด error = จำนวน instance พอดี (11 = 11)**
   คุณสามารถนับ instance จาก netlist แล้วรู้ล่วงหน้าว่าจะได้ error กี่บรรทัด

2. **`Searched libraries:` บอกว่าเครื่องมือหาเซลล์ไปที่ไหน**
   ในกรณีนี้มันหาแค่ใน `work` เพราะ `cells_lib` ไม่ได้ถูก `vmap`

3. **exit code ของ `vsim` คือ 12 แต่การเปิด `.do` ที่ไม่มีไฟล์ให้ exit code 0**
   (วัดจริงทั้งสองกรณี) → **ระบบ CI ต้องอ่าน transcript ไม่ใช่พึ่ง exit code อย่างเดียว**

4. **การโหลด design ที่ล้มเหลวเป็น FATAL — session จบทันที**
   คำสั่ง Tcl หลังจากนั้นไม่ถูกทำเลย
   นี่เป็นเหตุผลที่ `run_wrong.cmd` (ที่เป็น `.cmd`) เป็นคนตัดสิน ไม่ใช่สคริปต์ `.do`

### ขั้นที่ 2 — ทำให้ถูก

```bat
run.cmd
```

### ผลลัพธ์จริง

```text
---- 1. compile the cells, the netlist and the testbench ----
---- 2. simulate ----
# vsim -t 10ps -voptargs="+acc" work.tb_cnt4 -gGATE=true ...
# ** Note:  checks = 9 , errors = 0
---- 3. the verdict ----
   the GLS verdict : PASS
   the trace file  : results/trace_gls.txt
RESULT: PASS
[RESULT] PASS
```

### เปรียบเทียบ trace สองไฟล์

```bat
fc /b results\trace_rtl.txt ..\lab01_rtl_baseline\results\trace_rtl.txt
```

หรือด้วย PowerShell

```powershell
Compare-Object (Get-Content ..\lab01_rtl_baseline\results\trace_rtl.txt) `
             (Get-Content results\trace_gls.txt)
```

ผลคือ **ไม่มีอะไรต่าง** — trace ทั้งสองไฟล์เหมือนกันทุกบรรทัด

```text
q=0
q=1
q=2
q=3
q=4
q=5
q=6
q=6
q=9
```

### เก็บความรู้จาก LAB นี้

- **เซลล์และ netlist ต้องอยู่ในไลบรารีเดียวกัน** กับ testbench
  (หรืออย่างน้อยต้อง `vmap` ให้มองเห็นกัน)
- ถ้าอยู่คนละไลบรารี ต้อง `vmap` ไลบรารีเซลล์ด้วย เช่น

```tcl
vmap cells_lib cells_lib
vlog -work cells_lib ../cells/sg13g2_stdcell.v
vlog -work work       ../netlist/cnt4_net.v
```

  ในคู่มือนี้เลือกวิธีง่ายกว่า: **คอมไพล์ทุกอย่างเข้า `work` เหมือนกัน**
- **ต้องใส่ `-t 10ps`** (หัวข้อ 1.9)
- **testbench เดิมไม่ต้องแก้แม้แต่บรรทัดเดียว**


## บทที่ 7 — LAB 05: RTL กับ gate level เทียบกัน

### เป้าหมาย

พิสูจน์ว่า **testbench ไฟล์เดียวกันให้ผลเหมือนกันทั้งสองระดับ**
และผลลัพธ์ปกติของ GLS คือ **trace เหมือนกันทุกบรรทัด**

### โครงสร้างของ lab นี้

lab นี้ต้องรัน **สอง process ของ `vsim`** แยกกัน

```text
lab05_rtl_vs_gate/
├── run_rtl.do    process ที่ 1 : คอมไพล์ VHDL RTL แล้วจำลอง
├── run_gls.do    process ที่ 2 : คอมไพล์เซลล์ + netlist แล้วจำลอง + เทียบ trace
└── run.cmd       ตัวห่อทั้งสอง process
```

### ⚠ ทำไมต้องแยกสอง process

> **ModelSim session เดียวจำลองได้แค่ครั้งเดียว**
> ถ้า testbench จบด้วย `std.env.finish` แล้วเราโหลด design ใหม่ใน session เดิม
> สคริปต์ `.do` จะ **หยุดเงียบ ๆ โดยไม่มี error** — ไม่มีข้อความอะไรให้เห็นเลย
>
> วิธีแก้คือใช้ **process แยกสองตัว** ทำทีละอัน
> ข้อดีเพิ่มคือแต่ละรอบได้ transcript ของตัวเอง
> และใช้ license แบบ session เดียวทีละรอบได้พอดี

### รัน

```bat
cd C:\Users\000148\Documents\MiniMax\eda-tools\questa_gls_vhdl_lab\lab05_rtl_vs_gate
run.cmd
```

### ผลลัพธ์จริง

```text
[STEP 1] the RTL level run
...
# Loading work.tb_cnt4(sim)
# Loading work.cnt4(rtl)              <- ผูกกับ entity ของ VHDL
# ** Note: === tb_cnt4 : RTL ===
# ** Note:  checks = 9 , errors = 0
   the RTL verdict : PASS

[STEP 2] the gate level run
...
# Loading work.tb_cnt4(sim)
# Loading work.cnt4                   <- ผูกกับ module ของ Verilog
# ** Note: === tb_cnt4 : GATE LEVEL ===
# ** Note:  checks = 9 , errors = 0
   the RTL verdict : PASS
   the GLS verdict : PASS

---- compare the two traces line by line ----
   the RTL trace has 10 lines
   OK : the two traces are IDENTICAL
RESULT: PASS
[RESULT] PASS
```

> บรรทัด `Loading work.cnt4(rtl)` กับ `Loading work.cnt4` คือหลักฐานว่า
> **default binding ทำงานข้ามภาษาได้จริง**
> มีวงเล็บ `(rtl)` คือ architecture ของ VHDL
> ไม่มีวงเล็บคือ Verilog module (Verilog ไม่มี concept นี้)

### trace ทั้งสองไฟล์

`results/trace_rtl.txt` และ `results/trace_gls.txt` เหมือนกันทุกบรรทัด

```text
q=0
q=1
q=2
q=3
q=4
q=5
q=6
q=6
q=9
```

> ตัวเลข `10 lines` ในผลลัพธ์มาจาก `split` ที่แยกด้วย `\n`
> ซึ่งเก็นสัญญาณจบบรรทัดไปหนึ่งช่องว่าง
> **ไฟล์ trace จริงมี 9 บรรทัด** (ตรวจด้วย `type` แล้วเห็น 9 บรรทัด)

### กลไกการเทียบ trace

`tools/gls_common.do` มี proc นี้

```tcl
proc gls_diff_lines {file_a file_b} {
    set a [split [gls_read_file $file_a] "\n"]
    set b [split [gls_read_file $file_b] "\n"]
    set diff {}
    set n [expr {[llength $a] > [llength $b] ? [llength $a] : [llength $b]}]
    for {set i 0} {$i < $n} {incr i} {
        set la [lindex $a $i]
        set lb [lindex $b $i]
        if {$la ne $lb} { lappend diff [list $i $la $lb] }
    }
    return $diff
}
```

ถ้า `diff` ว่าง = trace เหมือนกันหมด

### เก็บความรู้จาก LAB นี้

- **ผลลัพธ์ปกติของ GLS คือ "เหมือนกัน"** ไม่ใช่ "ต่างกัน"
  ถ้าต่างกันแปลว่ามีปัญหา (เซลล์ผิด, netlist ผิด, หรือ timing check ทำงาน)
- ขั้นตอนที่ต้องทำ **คือการเปลี่ยนแค่ไฟล์ที่คอมไพล์** ไม่ต้องแตะ testbench เลย

| | ระดับ RTL | ระดับ gate |
|---|---|---|
| คอมไพล์ | `vcom ../rtl/cnt4.vhd` | `vlog ../cells/sg13g2_stdcell.v` + `vlog ../netlist/cnt4_net.v` |
| testbench | `vcom ../tb/tb_cnt4.vhd` | `vcom ../tb/tb_cnt4.vhd` (**เหมือนกันเป๊ะ**) |

---

## บทที่ 8 — LAB 06: การแพร่ของค่า `x`

### เป้าหมาย

พิสูจน์เรื่องที่สำคัญที่สุดของ GLS:
**RTL กับ gate level ให้คำตอบไม่เหมือนกันเมื่ออินพุตมีค่า `x`**

### เรื่องที่เกิดขึ้น

ทั้งสองระดับได้ netlist จาก **โค้ดชุดเดียวกัน** แต่มีความหมายของ `x` ต่างกัน

### ฝั่ง RTL (VHDL)

```vhdl
elsif rising_edge(clk) then
  if en = '1' then
    cq <= cq + 1;
  end if;
end process;
```

เมื่อ `en = 'X'`:
- ใน VHDL ตัวดำเนินการ `'X' = '1'` ให้ผลเป็น **false**
- จึงเข้าไปใน `else` → **ไม่ทำอะไร → คงค่าเดิม**

### ฝั่ง gate (Verilog ที่ GHDL สร้าง)

```verilog
assign n13_o = en ? n7_o : cq;
```

เมื่อ `en = 'X'`:
- ใน Verilog ตัวดำเนินการ `?:` **propagate ค่า `x`**
- ผลคือ `n13_o = 'X'` → **D ของ flip-flop เป็น `X` → ฟลิป-flopจับ `X`**

### รัน

```bat
cd C:\Users\000148\Documents\MiniMax\eda-tools\questa_gls_vhdl_lab\lab06_x_propagation
run.cmd
```

### ผลลัพธ์จริง

```text
[STEP 1] the RTL level run
# ** Note: === tb_cnt4_x : RTL ===
# ** Note: note : this testbench only observes, it does not judge
# ** Note:   t=46 ns : before the 'x'      q = 3
# ** Note:   t=66 ns : after  en = 'x'     q = 3
   the RTL verdict : PASS

[STEP 2] the gate level run
# ** Note: === tb_cnt4_x : GATE LEVEL ===
# ** Note: note : this testbench only observes, it does not judge
# ** Note:   t=46 ns : before the 'x'      q = 3
# ** Note:   t=66 ns : after  en = 'x'     q = X
   the RTL saw : observed=3
   the GLS saw : observed=X
---- the difference ----
   the RTL run produced an 'x' : 0   (expected : 0)
   the GLS run produced an 'x' : 1   (expected : 1)
   OK : the gate level simulation sees what the RTL hides
RESULT: PASS
[RESULT] PASS
```

> บรรทัดที่สำคัญที่สุดคือ **บรรทัดเวลาเดียวกัน (66 ns) แต่ค่าต่างกัน**
> ค่า `q = 3` กับ `q = X` — ระดับ gate เห็นว่าผลลัพธ์ "ไม่รู้จัก"

### ตีความผลลัพธ์

| | ค่าที่เห็น | ความหมาย |
|---|---|---|
| RTL | `observed=3` | ตัวนับ **คงค่า 3** เพราะ `'X' = '1'` เป็น false → ไม่นับ |
| GLS | `observed=X` | `x` แพร่ผ่านเกต → flip-flop จับ `x` → **ผลลัพธ์ไม่รู้จัก** |

> ⚠ **นี่คือเหตุผลที่ต้องเขียน testbench ให้ดี**
> ถ้า testbench เขียน `assert q = "0011"` ตอนนั้น
> - RTL จะผ่าน (เพราะ `q` เป็น `3`)
> - GLS จะ **ไม่ผ่าน** เพราะ `q` เป็น `X` และ `X` ไม่เท่ากับ `0011`
>
> ในงานจริง นี่อาจเป็น **ผลดี** เพราะบอกว่า design มีความเสี่ยงจะทำงานผิดเมื่อสัญญาณเข้ามาเป็น `X`
> แต่ก็อาจเป็น **ผลร้าย** เพราะบอกว่า design ไม่มี reset ที่ดีพอ

### ⚠ ข้อควรระวังเรื่อง X-optimism

ตัวจำลองหลายตัว (รวมถึง ModelSim) มี **X-optimism** โดย default
คือเมื่อเจอ `X` ในสัญญาณ ตัวจำลองจะพยายาม "เดา" ค่าที่ทำให้ simulation เดินต่อได้
ซึ่งทำให้ผลการจำลอง **ไม่ใช่ค่าที่แท้จริง**

ถ้าต้องการผลแบบ "ปลอดภัย" ให้ใช้

```tcl
vsim -t 10ps -voptargs=+acc -nooptargs? work.tb_cnt4_x
```

หรือเพิ่ม `+acc` ร่วมกับ `vsim -x` / ตัวเลือกที่เข้มงวดกว่า
คู่มือนี้ยังไม่ได้วัดผลของตัวเลือกเหล่านี้ จึงไม่ใส่ตัวเลขที่ไม่ได้มาจากการรันจริง
แต่ควรรู้ไว้ว่าเป็นประเด็นที่ต้องควบคุมใน flow จริง

### เก็บความรู้จาก LAB นี้

- `std_logic_vector` ใน VHDL มี 9 ค่า (`U`, `X`, `0`, `1`, `Z`, `W`, `L`, `H`, `-`)
  แต่ `to_hstring` จะพิมพ์ `X` เป็นตัวพิมพ์ใหญ่
- **การเปรียบเทียบใน testbench ต้องระวัง `X`**
  `q = "0011"` เป็น false เมื่อ `q` มี `X`
  ถ้าต้องการให้ผ่านกับ `X` ต้องใช้ `q ?= "0011"` (ตัวดำเนินการ `?=`)
- **ความต่างระหว่าง VHDL กับ Verilog ไม่ใช่เรื่องเล็ก**
  โค้ดเดียวกันแปลงเป็น Verilog แล้วอาจให้ผลจำลองต่างกันจริง
  นี่เป็นเหตุผลที่ทีมที่สังเคราะห์ต้องทดสอบทั้งสองภาษา

---

## บทที่ 9 — LAB 07: บั๊กที่ซ่อนอยู่ใน netlist

### เป้าหมาย

พิสูจน์ว่า **GLS จับบั๊กที่ RTL จับไม่ได้** แบบที่ชัดเจนที่สุด
โดยการ **แก้แค่ netlist** โดยไม่แตะ RTL เลย

### บั๊กที่ถูกฉีด

`netlist/cnt4_bug_net.v` เป็นสำเนาของ `netlist/cnt4_net.v`
ที่มีการ **สลับ D ของฟลิป-flop q[1] กับ q[2]**

```verilog
/* ต้นฉบับ : q[1] ใช้ D = _02_ , q[2] ใช้ D = _03_ */
sg13g2_dfrbpq_1 _16_ (
  .CLK(clk),
  .D(_02_),          /* แก้เป็น _03_ */
  .Q(\n14_q[1] ),
  .RESET_B(rst_n)
);
sg13g2_dfrbpq_1 _17_ (
  .CLK(clk),
  .D(_03_),          /* แก้เป็น _02_ */
  .Q(\n14_q[2] ),
  .RESET_B(rst_n)
);
```

**ทุกอย่างอื่นเหมือนเดิมทุกประการ**: ชนิดเซลล์เดียวกัน สัญญาณนาฬิกาเดียวกัน reset เดียวกัน
ไฟล์ RTL `rtl/cnt4.vhd` ไม่ถูกแตะเลย

### รัน

```bat
cd C:\Users\000148\Documents\MiniMax\eda-tools\questa_gls_vhdl_lab\lab07_netlist_bug
run.cmd
```

### ผลลัพธ์จริง

```text
[STEP 1] the RTL level run
   the RTL verdict : PASS

[STEP 2] the gate level run with the broken netlist
   the RTL verdict : PASS   (expected : PASS)
   the GLS verdict : FAIL   (expected : FAIL)
---- the two traces next to each other ----
   line 3 : RTL 'q=2'   vs   GLS 'q=4'
   line 5 : RTL 'q=4'   vs   GLS 'q=2'
RESULT: PASS
  -> the RTL simulation cannot see the defect, the gate level simulation can
[RESULT] PASS
```

### trace ทั้งสองฝั่ง

| บรรทัด | RTL | GLS (มีบั๊ก) | ค่าที่ถูกต้อง |
|---|---|---|---|
| 1 | `q=0` | `q=0` | 0 |
| 2 | `q=1` | `q=1` | 1 |
| 3 | `q=2` | **`q=4`** | 2 |
| 4 | `q=3` | `q=3` | 3 |
| 5 | `q=4` | **`q=2`** | 4 |
| 6 | `q=5` | `q=5` | 5 |
| 7 | `q=6` | `q=6` | 6 |
| 8 | `q=6` | `q=6` | 6 |
| 9 | `q=9` | `q=9` | 9 |

### อธิบายว่าทำไมถึงเป็นแบบนี้

สมการของตัวนับ (ที่ Yosys สังเคราะห์ได้)

```text
q[0]_next = q[0] XOR en
q[1]_next = q[1] XOR (q[0] AND en)
q[2]_next = q[2] XOR (q[1] AND q[0] AND en)
```

ใน netlist

| สัญญาณ | นิยาม | ของจริง |
|---|---|---|
| `_02_` | `AND(_04_, _06_)` = `q[1] XOR (q[0] AND en)` | D ของ q[1] |
| `_03_` | `XNOR(q[2], _04_)` = `q[2] XOR (q[1] AND q[0] AND en)` | D ของ q[2] |

พอสลับกัน

```text
q[1]_next = q[2] XOR (q[1] AND q[0] AND en)   <- ผิด
q[2]_next = q[1] XOR (q[0] AND en)            <- ผิด
```

ลองไล่ด้วยมือจาก `q = 0001` (นับไป 1 ครั้งแล้ว) โดย `en = 1`

| | q[0] | q[1] | q[2] | ผล |
|---|---|---|---|---|
| ค่าปัจจุบัน | 1 | 0 | 0 | `q = 0001` |
| ของจริง | 0 | 1 | 0 | `q = 0010` ✅ |
| ของเสีย | 0 | 0 | 1 | `q = 0100` ❌ |

จากนั้นรอบถัดไปก็สลับกลับ ทำให้ได้ `q = 0011` → `0100` → `0011` → ...
จึงเห็น trace ที่สลับไปมา `2, 4` ตามที่ข้อความ error บอก

### ⚠ เก็บความรู้ที่สำคัญ

1. **RTL ผ่าน 100%** — เพราะ RTL ไม่เคยถูกแก้
   ถ้าคุณมีแต่ RTL regression คุณจะไม่มีทางรู้ว่ามีบั๊กนี้

2. **บั๊กแบบนี้เกิดได้จริงในงานจริง**
   - การสลับสัญญาณระหว่างการวางตำแหน่ง (placement) ผิด
   - การผิด pin assignment ใน constraint file
   - บั๊กจากการแก้ netlist ด้วยมือ
   - บั๊กจากเครื่องมือสังเคราะห์เอง

3. **นี่คือเหตุผลที่ GLS ยังต้องมีอยู่แม้จะมี formal verification**
   - formal ต้องเขียน property ให้ถูก ถ้าไม่มี property ก็จับบั๊กนี้ไม่ได้
   - GLS ใช้ testbench ที่มีอยู่แล้ว จับบั๊กได้ทันทีโดยไม่ต้องเขียนอะไรเพิ่ม

4. **บั๊กนี้ "หาย" ไปเมื่อนำไปวางตำแหน่งและ route จริง**
   เพราะมันเป็นบั๊กเชิงตรรกะในระดับ netlist
   การตรวจ DRC/LVS จะไม่จับได้เลย

---

## บทที่ 10 — LAB 08: regression ของทั้งชุด

### เป้าหมาย

ทำให้ชุด lab ทั้งหมดรันได้ใน **คำสั่งเดียว** และได้รหัสจบที่ใช้ใน CI ได้

### สองส่วนของ LAB 08

1. **regression ของทุก lab** — รัน lab01 ถึง lab07 ตามลำดับแล้วสรุปผล
2. **การเทียบสามดีไซน์เพิ่ม** — `alu4`, `fsm_light`, `sr16`

### รันทั้งชุด

```bat
cd C:\Users\000148\Documents\MiniMax\eda-tools\questa_gls_vhdl_lab\lab08_gls_regression
regression.cmd
```

### ผลลัพธ์จริง

```text
====================================================================
 LAB 08 : GLS regression -- running every gate level lab
 root    : C:\Users\000148\Documents\MiniMax\eda-tools\questa_gls_vhdl_lab\lab08_gls_regression\..
====================================================================
[PASS] lab01_rtl_baseline
[PASS] lab02_synth_netlist
[PASS] lab03_cell_library
[PASS] lab04_gls_first
[PASS] lab05_rtl_vs_gate
[PASS] lab06_x_propagation
[PASS] lab07_netlist_bug
[PASS] lab08_multi_design

====================================================================
 REGRESSION SUMMARY
 total = 8   passed = 8   failed = 0
 summary file : ...\lab08_gls_regression\results\regression_summary.txt
====================================================================
PASS  lab01_rtl_baseline
PASS  lab02_synth_netlist
PASS  lab03_cell_library
PASS  lab04_gls_first
PASS  lab05_rtl_vs_gate
PASS  lab06_x_propagation
PASS  lab07_netlist_bug
PASS  lab08_multi_design
[REGRESSION] ALL GREEN
```

**8 lab ผ่านหมด รหัสจบ = 0**

### ส่วนที่สอง: สามดีไซน์เพิ่ม

`run.cmd` ใน `lab08_gls_regression` จะวนลูปผ่าน `alu4`, `fsm_light`, `sr16`
โดยส่งชื่อดีไซน์ผ่าน plusarg `+TOP=`

```bat
vsim -c -onfinish stop +TOP=alu4 -do "do run_rtl.do"
vsim -c -onfinish stop +TOP=alu4 -do "do run_gls.do"
```

และใน `run_rtl.do` / `run_gls.do` อ่านค่านี้มาเลือกชื่อไฟล์

```tcl
set top "cnt4"
foreach a [split $::argv " "] {
    if {[regexp {^\+TOP=(.*)$} $a -> v]} { set top $v }
}
set tb "tb_$top"
```

### ผลลัพธ์จริง

```text
[DESIGN] alu4
   the RTL verdict : PASS
   the GLS verdict : PASS
   7 trace lines , 0 difference(s)
  [PASS] alu4
[DESIGN] fsm_light
   the RTL verdict : PASS
   the GLS verdict : PASS
   6 trace lines , 0 difference(s)
  [PASS] fsm_light
[DESIGN] sr16
   the RTL verdict : PASS
   the GLS verdict : PASS
   6 trace lines , 0 difference(s)
  [PASS] sr16

 total = 3   passed = 3   failed = 0
[RESULT] PASS
```

### trace จริงของทั้งสามดีไซน์

`alu4` (6 บรรทัด)

```text
op=0 a=7 b=5 y=C zero=0
op=1 a=7 b=5 y=2 zero=0
op=2 a=C b=A y=8 zero=0
op=3 a=C b=A y=E zero=0
op=4 a=C b=A y=6 zero=0
op=0 a=F b=1 y=0 zero=1
```

อ่าน `alu4` (op: 0=add, 1=sub, 2=and, 3=or, 4=xor)

| op | a | b | y | ความหมาย | zero |
|---|---|---|---|---|---|
| 0 | 7 | 5 | C | 7 + 5 = 12 = `C` | 0 |
| 1 | 7 | 5 | 2 | 7 − 5 = 2 | 0 |
| 2 | C | A | 8 | `1100` AND `1010` = `1000` | 0 |
| 3 | C | A | E | `1100` OR `1010` = `1110` | 0 |
| 4 | C | A | 6 | `1100` XOR `1010` = `0110` | 0 |
| 0 | F | 1 | 0 | 15 + 1 = 16 → ตัดเหลือ 0 (4 บิต) | **1** |

`fsm_light` (5 บรรทัด)

```text
state=0 red=1 green=0 yellow=0
state=1 red=0 green=1 yellow=0
state=2 red=0 green=0 yellow=1
state=0 red=1 green=0 yellow=0
state=1 red=0 green=1 yellow=0
```

`sr16` (5 บรรทัด)

```text
qout=0000
qout=A5C3
qout=4B86
qout=25C3
qout=25C3
```

ตรวจด้วยมือ

| ขั้น | ค่า | ความหมาย |
|---|---|---|
| reset | `0000` | ล้างเป็น 0 |
| load `A5C3` | `A5C3` | โหลดคู่ขนาน |
| shift left (`sh=10`) | `4B86` | `A5C3` << 1 = `14B86` → ตัดทิ้งบิตบน = `4B86` ✅ |
| shift right (`sh=01`) | `25C3` | `4B86` >> 1 = `25C3` ✅ |
| hold (`sh=00`) | `25C3` | คงค่าเดิม ✅ |

> ทั้งสามดีไซน์ ใช้ **testbench ไฟล์เดียวกับ RTL** และผลลัพธ์เหมือนกันทุกบรรทัด
> ยืนยันว่าเทคนิคในหัวข้อ 1.7 ใช้ได้กับทุกดีไซน์ ไม่ใช่แค่ตัวนับ

### ตัวอย่างที่โหลดเพิ่มขึ้นในระดับ gate

เทียบสองรายการ `Loading` จาก log จริง

```text
# ระดับ RTL
# Loading work.tb_sr16(sim)
# Loading work.sr16(rtl)

# ระดับ gate
# Loading work.tb_sr16(sim)
# Loading work.sr16
# Loading work.sg13g2_inv_1
# Loading work.sg13g2_nor2b_1
# Loading work.sg13g2_nand2b_1
# Loading work.sg13g2_nand3_1
# Loading work.sg13g2_a22oi_1
# Loading work.sg13g2_o21ai_1
# Loading work.sg13g2_nand4_1
# Loading work.sg13g2_nand2_1
# Loading work.sg13g2_nand3b_1
# Loading work.sg13g2_a21o_1
# Loading work.sg13g2_and2_1
# Loading work.sg13g2_a221oi_1
# Loading work.sg13g2_nor2_1
# Loading work.sg13g2_dfrbpq_1
# Loading work.ihp_dff_r_err
# Loading work.ihp_dff_r
```

เห็นชัดว่า:
- ระดับ gate โหลด **เซลล์จริง** เข้ามาด้วย
- และโหลด **UDP** (`ihp_dff_r`, `ihp_dff_r_err`) ที่เป็น primitive ภายในเซลล์ `sg13g2_dfrbpq_1`

> `ihp_dff_r` คือ user defined primitive ที่อยู่ในไฟล์ `cells/sg13g2_stdcell.v` เอง
> (บรรทัด 1974 เป็นต้นไป มี primitive ทั้ง 17 ตัว ซ่อนอยู่หลังโมเดล 84 เซลล์
> โดยแต่ละตัวถูกห่อด้วย `` `ifdef _udp_def_..._ ``)
> ไฟล์ `cells/sg13g2_udp.v` เป็นไฟล์แยกที่มีเฉพาะ UDP ชุดเดียวกันสำหรับ flow ที่ต้องแยกคอมไพล์

### ⚠ กับดักของสคริปต์ `.cmd` ที่เจอระหว่างทำ lab นี้

1. **`<` redirection ใน `for` block ของ `.cmd` ใช้ไม่ได้**
   ต้องอ่าน verdict ด้วย `for /f` แทน

```bat
for /f "usebackq delims=" %%V in ("results\%%D_verdict.txt") do set "R=%%V"
```

2. **ใน `for %%V in (...)` ตัว `=` จะถูกตีความเป็นตัวคั่น var=value**
   จึงห้ามใช้ `=` เป็นตัวคั่นข้อมูล

3. **ต้องเปิด delayed expansion** เมื่อต้องการอ่านตัวแปรที่เพิ่งถูกตั้งใน loop

```bat
setlocal enabledelayedexpansion
...
if "!R!"=="PASS" (
```

4. **`.cmd` ต้องเป็น ASCII ล้วน**
   ถ้าใส่ข้อความไทยหรือ UTF-8 `cmd.exe` จะอ่านโครงสร้างบรรทัดผิด
   (คอมเมนต์บรรทัดหนึ่งจะกลืนตัวอักษรแรกของบรรทัดถัดไป: `echo` กลายเป็น `cho`)

5. **ห้ามเว้นวรรคในวงเล็บก่อน `(` หรือ `)` ในบรรทัด `echo` ที่อยู่ใน if-block**
   `cmd.exe` จะหยุดสคริปต์แบบเงียบ

### เก็บความรู้จาก LAB นี้

- **regression ต้องมี exit code ที่ CI ใช้ได้**
  คู่มือนี้ใช้ 0 = ผ่านหมด, 1 = มีบางอันไม่ผ่าน
- **แต่ละ lab ต้องเขียน verdict เป็นไฟล์** ไม่ใช่ดูแค่ console
  เพราะ `vsim` คืน 0 แม้จะล้มเหลว (หัวข้อ 6.1)
- **เก็บ log ของแต่ละ lab แยกกัน** เพื่อให้หาที่ผิดได้เร็ว

```text
lab08_gls_regression/results/
├── regression_summary.txt
├── lab01_rtl_baseline.log
├── lab02_synth_netlist.log
├── lab03_cell_library.log
├── lab04_gls_first.log
├── lab05_rtl_vs_gate.log
├── lab06_x_propagation.log
├── lab07_netlist_bug.log
└── lab08_multi_design.log
```


## ภาคผนวก A — คลังข้อความ error จริง

ทุกข้อความในภาคผนวกนี้ถูก **คัดลอกมาจากการรันจริงบนเครื่อง**
ไม่มีการแต่งขึ้น

### A.1 `vsim-3693` — ไม่ได้ใส่ `-t 10ps`

เกิดเมื่อคอมไพล์เซลล์ Verilog ของ SG13G2 แล้วโหลด design โดยลืมใส่ `-t 10ps`

```text
# ** Fatal: (vsim-3693) The minimum time resolution limit (10ps) in the Verilog source is smaller than the one chosen
for SystemC or VHDL units in the design. Use the vsim -t option to specify the desired resolution.
# FATAL ERROR while loading design
# Errors: 1, Warnings: 0
```

exit code = **12**

**สาเหตุ:** โมเดลเซลล์ประกาศ `` `timescale 1ns/10ps ``
แต่ค่าเริ่มต้นของ ModelSim คือ 1 ps ซึ่งละเอียดกว่า → ModelSim ห้าม

**แก้:** `vsim -t 10ps ...`

---

### A.2 `vsim-3033` — เซลล์อยู่คนละไลบรารี

```text
# Loading work.cnt4
# ** Error: (vsim-3033) Instantiation of 'sg13g2_nand3_1' failed. The design unit was not found.
#    Time: 0 ps  Iteration: 0  Instance: /tb_cnt4/dut File: ../netlist/cnt4_net.v Line: 27
#         Searched libraries:
#             C:/Users/000148/Documents/MiniMax/eda-tools/questa_gls_vhdl_lab/lab04_gls_first/work
# ** Error: (vsim-3033) Instantiation of 'sg13g2_nand4_1' failed. The design unit was not found.
...
# Error loading design
# Errors: 11, Warnings: 0
```

- **จำนวนบรรทัด error = จำนวน instance พอดี (11 = 11)**
- `Searched libraries:` บอกว่าหาเซลล์ไปที่ไหน — ที่นี่มีแค่ `work`
- exit code = **12**
- **การโหลด design ที่ล้มเหลวเป็น FATAL → session จบทันที**
  คำสั่ง Tcl หลังจากนั้นไม่ถูกทำเลย

**แก้:** คอมไพล์เซลล์เข้า `work` เหมือนกัน หรือ `vmap cells_lib cells_lib` ให้มองเห็นกัน

---

### A.3 `vsim-7` — โฟลเดอร์ของไฟล์ trace ไม่มีอยู่

เกิดเมื่อ VHDL `file_open` เปิดไฟล์ที่อยู่ในโฟลเดอร์ที่ยังไม่ถูกสร้าง

```text
# ** Warning: (vsim-7) Failed to open VHDL file "results/trace_gateflag.txt" in r+ mode.
# No such file or directory. (errno = ENOENT)
#    Time: 0 ps  Iteration: 0  Instance: /tb_cnt4
# ** Note: === tb_cnt4 : GATE LEVEL ===
#    Time: 0 ps  Iteration: 0  Instance: /tb_cnt4
# ** Fatal: (vsim-7) Failed to open VHDL file "results/trace_gateflag.txt" in r+ mode.
# No such file or directory. (errno = ENOENT)
#    Time: 20 ns  Iteration: 0  Process: /tb_cnt4/stim File: .../tb/tb_cnt4.vhd line 99
# Fatal error in Process stim at .../tb/tb_cnt4.vhd line 99
# Errors: 1, Warnings: 1
```

สังเกตว่า error แรกเป็น **Warning** แต่ครั้งที่สองเป็น **Fatal**
เพราะ VHDL เปิดไฟล์ตอนเริ่ม process แล้วเปิดซ้ำตอนเขียน

**แก้:** `file mkdir results` ก่อนเรียก `vsim` ทุกครั้ง

---

### A.4 License ไม่ว่าง

```text
** Error: License checkout has been disallowed because
only one session is allowed to run on an uncounted nodelocked
license and an instance of QuestaSim is already running with a
nodelocked license on this machine.
```

**แก้:** ปิด QuestaSim GUI ที่เปิดค้างอยู่ หรือให้ `tools/pick_tool.cmd` เลือก ModelSim DE ที่ยังว่าง

---

### A.5 เปิดไฟล์ `.do` ที่ไม่มีอยู่

```text
# Cannot open macro file: this_file_does_not_exist.do
ModelSim> #
# <EOF>
```

exit code = **0** (!)

**นี่คือกับดักที่อันตรายที่สุด** — ระบบ CI ที่ดูแค่ exit code จะไม่เห็นความล้มเหลว
ต้องอ่าน transcript เสมอ

---

### A.6 สรุป exit code ของ `vsim` ที่วัดได้จริง

| สถานการณ์ | exit code | มี error ใน transcript? |
|---|---|---|
| รันจบปกติ | 0 | ไม่มี |
| เปิดไฟล์ `.do` ไม่เจอ | **0** | มี (`Cannot open macro file`) |
| โหลด design ไม่สำเร็จ (`vsim-3033`) | **12** | มี |
| ไม่ใส่ `-t 10ps` (`vsim-3693`) | **12** | มี |
| สคริปต์ Tcl ตาย (`onerror` → `quit -code 90`) | **90** | มี |

> **สรุป: อย่าเชื่อ exit code อย่างเดียว**
> ให้อ่านไฟล์ verdict ที่ testbench เขียน แล้วค่อยตัดสิน
> นี่คือสิ่งที่ `tools/gls_common.do` + `run_template.cmd` ทำในคู่มือนี้

---

## ภาคผนวก B — กับดักที่วัดได้จริง

### B.1 กับดักฝั่ง VHDL

| # | กับดัก | อาการ | วิธีแก้ |
|---|---|---|---|
| 1 | นาฬิกาไม่มีค่าเริ่มต้น | `clk` เป็น `'U'` → `not 'U'` = `'U'` → **นาฬิกาไม่เดินเลย** | `signal clk : std_logic := '0';` |
| 2 | `std_logic_vector + integer` | compile error (`numeric_std` ไม่มี operator นี้) | ใช้ `unsigned` ภายใน แล้ว `std_logic_vector(cq)` ที่ port |
| 3 | `trim` ไม่มีใน GHDL VHDL-2008 | compile error | เขียน helper `nospace()` เอง |
| 4 | `time'image` พิมพ์หน่วยตาม resolution | ได้ `26000000 fs` ใน GHDL แต่ `26 ns` ใน ModelSim | เขียน helper `timestr()` |
| 5 | `integer'image(5)` มีช่องว่างนำหน้า | ได้ `" 5"` ไม่ใช่ `"5"` | ใช้ helper `nospace()` |
| 6 | `to_hstring` พิมพ์ **ตัวพิมพ์ใหญ่** | `C` ไม่ใช่ `c` (ต่างจาก Verilog `%h`) | ระวังเมื่อเทียบ trace ข้ามภาษา |
| 7 | `wait until rising_edge(clk)` ไม่ทำงาน | ถ้า `clk` เป็น `'U'` | แก้ข้อ 1 |
| 8 | `file_open` ล้มเหลว | `vsim-7` ถ้าโฟลเดอร์ไม่มี | `file mkdir results` |
| 9 | ชื่อ port ของ VHDL ถูก GHDL แปลงเป็นตัวพิมพ์เล็ก | ไม่ match กับ Verilog module | ตั้งชื่อ port เป็นตัวพิมพ์เล็กตั้งแต่ต้น |

### B.2 กับดักฝั่ง Verilog / Yosys

| # | กับดัก | อาการ | วิธีแก้ |
|---|---|---|---|
| 1 | `abc -g` ไม่รองรับ gate type `NOT` | `ERROR: Unsupported gate type` | ปล่อยให้ Yosys สร้าง inverter ให้เอง |
| 2 | `dfflibmap` ต้องมาก่อน `abc` | ABC ไม่เห็นฟลิป-flop | เรียงลำดับให้ถูก |
| 3 | `cells.lib` ของ distro มีแต่ DFF | map combinational ไม่ได้ | ใช้ Liberty ของ PDK เสมอ |
| 4 | `fsm` recode เป็น one-hot | จำนวน FF เปลี่ยน (fsm_light: 2 → 5) | `fsm -norecode` หรือเขียน one-hot เอง |
| 5 | `write_verilog` เขียน `$_DFF*` กลับเป็น `always` | ไม่ใช่ gate level จริง | ใช้ `dfflibmap` + `abc` ให้ครบก่อน `write_verilog` |
| 6 | `dfflibmap` map latch ไม่ได้ | latch หลุดเป็น `$_DLATCH*` | ออกแบบให้ไม่มี latch |
| 7 | ชื่อสัญญาณที่ escape มีช่องว่างท้าย | `\n14_q[1] ` | อย่า parse ชื่อสัญญาณด้วย regex แบบตรงไปตรงมา |

### B.3 กับดักฝั่ง Tcl / ModelSim

| # | กับดัก | อาการ | วิธีแก้ |
|---|---|---|---|
| 1 | `"\s"` ใน double quotes | backslash หาย → pattern พัง | ใช้ braces `{...}` หรือ `format {...}` |
| 2 | `$finish` ตัดคำสั่งที่เหลือใน `-do` | `coverage save` ไม่ทำงาน แต่ไม่มี error | ใส่ `-onfinish stop` |
| 3 | โหลด design ครั้งที่สองใน session เดียว | `.do` หยุดเงียบ ๆ | ใช้ **process แยก** สองตัว |
| 4 | `vsim` คืน 0 แม้ล้มเหลว | CI ผ่านทั้งที่พัง | อ่าน transcript / ไฟล์ verdict |
| 5 | `[info script]` คืน path ของ vsim | simulator crash | อย่าใช้ ให้ `source` ด้วยพาธสัมพัทธ์ |
| 6 | console echo พิมพ์ argument ขนาดใหญ่ | เห็นบรรทัด `#` เต็มจอ | ไม่ใช่ error — สคริปต์ที่อ่านไฟล์เซลล์ต้องหลีกเลี่ยง |
| 7 | ไม่มี `vsim-3033` แต่มี error | จำนวน error ไม่เท่าจำนวน instance | มักเป็นเรื่องอื่น — อ่าน transcript ให้ครบ |

### B.4 กับดักฝั่ง WSL / Linux

| # | กับดัก | อาการ | วิธีแก้ |
|---|---|---|---|
| 1 | nix profile ไม่ถูกโหลดใน non-interactive shell | `yosys: command not found` | `export PATH="/root/.nix-profile/bin:$PATH"` |
| 2 | `ghdl synth` สลับลำดับ option | `unknown command` | `ghdl synth --std=08 --out=verilog <top>` |
| 3 | `ghdl synth` ไม่มีตัวเลือกชื่อไฟล์ | ไม่มีไฟล์เกิด | redirect เองด้วย `>` |
| 4 | path ของ PDK ใน Windows | `Liberty file not found` | แก้ `PDK_LIB` ใน `tools/synth/synth.sh` |
| 5 | PowerShell + WSL + quote ซ้อน | `syntax error near unexpected token` | เขียนเป็นไฟล์ `.sh` แล้วเรียกด้วย `bash <file>` |

### B.5 กับดักฝั่ง Windows batch

| # | กับดัก | อาการ | วิธีแก้ |
|---|---|---|---|
| 1 | ข้อความไทย/UTF-8 ใน `.cmd` | `echo` กลายเป็น `cho` | ใช้ **ASCII ล้วน** |
| 2 | `<` redirection ใน `for` block | ใช้ไม่ได้ | ใช้ `for /f` |
| 3 | `=` เป็นตัวคั่นใน `for %%V in (...)` | ถูกตีความเป็น var=value | ห้ามใช้ `=` เป็นตัวคั่น |
| 4 | ต้องอ่านตัวแปรที่เพิ่งตั้งใน loop | ได้ค่าว่าง | `setlocal enabledelayedexpansion` + `!VAR!` |
| 5 | `(` หรือ `)` ในบรรทัด `echo` ที่อยู่ใน if-block | script หยุดเงียบ | escape หรือย้ายออกจาก if-block |
| 6 | `cd` แล้วสั่งลบ | ไม่ผ่านการตรวจความปลอดภัย | ใช้ `mavis-trash` หรือ `rm --` โดยไม่เปลี่ยนโฟลเดอร์ |

---

## ภาคผนวก C — ตรวจโค้ดด้วย GHDL (ไม่ต้องมี ModelSim)

ถ้าเครื่องยังไม่มี license ของ ModelSim คุณยังตรวจความถูกต้องของ VHDL ได้
ด้วย GHDL ซึ่งเป็นตัวจำลองโอเพนซอร์ส

```bash
wsl -d Ubuntu -u root -- bash /mnt/c/Users/000148/Documents/MiniMax/eda-tools/questa_gls_vhdl_lab/tools/check_vhdl.sh
```

สคริปต์นี้ทำ 3 อย่าง

1. คอมไพล์ `rtl/*.vhd` และ `tb/*.vhd` ทั้งหมดด้วย `ghdl -a --std=08`
   ลงในไดเรกทอรีชั่วคราว (ไฟล์ `work-obj08.cf` ของโปรเจกต์ไม่ถูกแตะ)
2. elaborate และ **รัน testbench ทั้ง 5 ตัวจริง**
3. รัน `ghdl synth` เพื่อพิสูจน์ว่าสังเคราะห์เป็น Verilog ที่ Yosys อ่านต่อได้

### ผลลัพธ์จริง

```text
---- ghdl version ----
ghdl (Ubuntu 5.0.1+dfsg-1ubuntu1) [Dunoon edition]
 Compiled with GNAT Version: 14.2.0
 static elaboration, mcode JIT code generator

== rtl/alu4.vhd
== rtl/cnt4.vhd
== rtl/fsm_light.vhd
== rtl/sr16.vhd
== tb/tb_alu4.vhd
== tb/tb_cnt4.vhd
== tb/tb_cnt4_x.vhd
== tb/tb_fsm_light.vhd
== tb/tb_sr16.vhd
---- ghdl --dir --std=08 ----
VHDL SIGNATURE FILE START
-- --[readme]--
-- Library    ieee:
--     [vhdl.files]--
--      [units]--
--        ieee.std_logic_1164
--        ieee.numeric_std
...
---- compile errors : 0 ----

=====================================================================
 RUN : tb_cnt4
=====================================================================
tb/tb_cnt4.vhd:109:7:@0ms:(report note): === tb_cnt4 : RTL ===
tb/tb_cnt4.vhd:123:5:@20ns:(report note):   t=20 ns : after reset         q = 0
tb/tb_cnt4.vhd:138:7:@26ns:(report note):   t=26 ns : count up 1            q = 1
tb/tb_cnt4.vhd:138:7:@36ns:(report note):   t=36 ns : count up 2            q = 2
tb/tb_cnt4.vhd:138:7:@46ns:(report note):   t=46 ns : count up 3            q = 3
tb/tb_cnt4.vhd:138:7:@56ns:(report note):   t=56 ns : count up 4            q = 4
tb/tb_cnt4.vhd:138:7:@66ns:(report note):   t=66 ns : count up 5            q = 5
tb/tb_cnt4.vhd:138:7:@76ns:(report note):   t=76 ns : count up 6            q = 6
tb/tb_cnt4.vhd:153:5:@106ns:(report note):   t=106 ns : hold (en = '0')     q = 6
tb/tb_cnt4.vhd:170:5:@136ns:(report note):   t=136 ns : count up again     q = 9
tb/tb_cnt4.vhd:175:5:@136ns:(report note):  checks = 9 , errors = 0
tb/tb_cnt4.vhd:179:7:@136ns:(report note): TEST_PASSED : tb_cnt4 completed
---- tb_cnt4.trace ----
q=0
q=1
q=2
q=3
q=4
q=5
q=6
q=6
q=9
---- tb_cnt4.result ----
PASS

---- ghdl synth : cnt4 ----
SYNTH_OK cnt4  (30 lines of Verilog)
---- ghdl synth : alu4 ----
SYNTH_OK alu4  (77 lines of Verilog)
---- ghdl synth : fsm_light ----
SYNTH_OK fsm_light  (97 lines of Verilog)
---- ghdl synth : sr16 ----
SYNTH_OK sr16  (57 lines of Verilog)
---- total errors : 0 ----
```

**ข้อสังเกตที่น่าสนใจ:** trace จาก GHDL กับจาก ModelSim **เหมือนกันทุกบรรทัด**
รวมถึง **เวลาที่วัดได้ด้วย**

| | GHDL | ModelSim |
|---|---|---|
| เวลาหลัง reset | 20 ns | 20 ns |
| นับขึ้นครั้งที่ 1…6 | 26, 36, 46, 56, 66, 76 ns | เหมือนกัน |
| คงค่า | 106 ns | เหมือนกัน |
| นับต่อ | 136 ns | เหมือนกัน |
| checks / errors | 9 / 0 | 9 / 0 |

นี่เป็นหลักฐานว่า testbench ถูกต้องจริง ไม่ใช่แค่ "ผ่าน" บน ModelSim
และยืนยันว่า helper `timestr()` ทำให้สองตัวจำลองให้ผลตรงกัน

> **ข้อจำกัดของ GHDL**
> - อ่าน Verilog ไม่ได้ → ตรวจได้แค่ระดับ RTL ไม่ได้ตรวจระดับ gate
> - `trim` และ `time'image` ไม่มี → ต้องใช้ helper ที่คู่มือนี้เตรียมไว้
> - ความละเอียดเวลาต่างจาก ModelSim → ต้องมี helper `timestr()`

---

## ภาคผนวก D — แบบฝึกหัด (เฉลยทุกข้อรันจริงแล้ว)

> ทุกเฉลยในภาคผนวกนี้ได้มาจาก **การทดลองจริงบนเครื่อง**
> ไม่ใช่การคาดเดา

### D.1 — `-gGATE` เปลี่ยนพฤติกรรมจริงหรือไม่?

**คำถาม:** ถ้าเรียก `vsim ... -gGATE=true` แต่ยังคอมไพล์ **RTL** อยู่
ผลลัพธ์จะต่างจากการรัน RTL ปกติหรือไม่?

**เฉลย (จากการรันจริง):** **ไม่ต่าง**
เกิดแค่ข้อความประจำการจำลองเปลี่ยนไป

```text
# ** Note: === tb_cnt4 : GATE LEVEL ===      <- banner เปลี่ยน
# ** Note:  checks = 9 , errors = 0
   the verdict : PASS
q=0
q=1
q=2
q=3
q=4
q=5
q=6
q=6
q=9
```

trace เหมือนกันทุกบรรทัดกับการรัน RTL ปกติ

**เหตุผล:** generic `GATE` ถูกใช้แค่เลือกข้อความที่พิมพ์
ส่วน "ระดับการจำลอง" จริง ๆ ถูกกำหนดโดย **ไฟล์ที่คอมไพล์เข้า `work`**
ไม่ใช่โดย generic

> บทเรียน: อย่าใช้ข้อความในบรรทัดเดียวกันเป็นหลักฐานว่าจำลองระดับไหน
> ดู `Loading work.xxx(rtl)` กับ `Loading work.xxx` แทน

---

### D.2 — ลืม `-t 10ps` เกิดอะไรขึ้น?

**คำถาม:** ถ้าโหลด gate netlist โดยไม่ใส่ `-t 10ps` จะเกิดอะไรขึ้น?

**เฉลย (จากการรันจริง):** โหลด design ไม่ได้เลย

```text
# ** Fatal: (vsim-3693) The minimum time resolution limit (10ps) in the Verilog source is smaller than the one chosen
for SystemC or VHDL units in the design. Use the vsim -t option to specify the desired resolution.
# FATAL ERROR while loading design
# Errors: 1, Warnings: 0
```

exit code = **12**

---

### D.3 — บั๊กสลับ D ของ q[0] กับ q[1]

**คำถาม:** แก้ `netlist/cnt4_net.v` ให้สลับ `D` ของฟลิป-flop q[0] กับ q[1]
แล้วจำลองระดับ gate จะได้ trace อะไร และ testbench จะตรวจจับกี่จุด?

**เฉลย (จากการรันจริง):**

```text
q=0
q=2
q=3
q=4
q=6
q=7
q=8
q=8
q=C
```

```text
# ** Error: FAIL count up : expected 1 but got 2
# ** Error: FAIL count up : expected 2 but got 3
# ** Error: FAIL count up : expected 3 but got 4
# ** Error: FAIL count up : expected 4 but got 6
# ** Error: FAIL count up : expected 5 but got 7
# ** Error: FAIL count up : expected 6 but got 8
# ** Error: FAIL hold : expected 6 but got 8
# ** Error: FAIL count up again : expected 9 but got C
# ** Note:  checks = 9 , errors = 8
```

**checks = 9, errors = 8** — เป็นกรณีที่แย่ที่สุด เพราะสลับบิตเล็กสุด
ทำให้ตัวนับนับผิดตั้งแต่จังหวะแรก

---

### D.4 — บั๊กสลับ D ของ q[2] กับ q[3]

**คำถาม:** ถ้าสลับ `D` ของ q[2] กับ q[3] ล่ะ?

**เฉลย (จากการรันจริง):**

```text
q=0
q=1
q=2
q=3
q=8
q=5
q=A
q=6
q=D
```

```text
# ** Error: FAIL count up : expected 4 but got 8
# ** Error: FAIL count up : expected 6 but got A
# ** Error: FAIL count up again : expected 9 but got D
# ** Note:  checks = 9 , errors = 3
```

**checks = 9, errors = 3**

---

### D.5 — เปรียบเทียบบั๊กทั้งสามแบบ

| บั๊ก | trace | errors |
|---|---|---|
| สลับ q[0]↔q[1] | `0,2,3,4,6,7,8,8,C` | **8 / 9** |
| สลับ q[1]↔q[2] (LAB 07) | `0,1,4,3,2,5,6,6,9` | **2 / 9** |
| สลับ q[2]↔q[3] | `0,1,2,3,8,5,A,6,D` | **3 / 9** |

**ข้อสังเกต:** ยิ่งสลับบิตที่ "สูง" ยิ่งตรวจจับยาก
เพราะบิตสูงเปลี่ยนค่าน้อยครั้งในช่วงทดสอบสั้น ๆ

> **บทเรียนสำคัญ:** testbench ที่สั้นเกินไปจะจับบั๊กระดับ gate ไม่ครบ
> การออกแบบ stimulus ให้ครอบคลุมจึงสำคัญไม่แพ้การออกแบบ RTL

---

### D.6 — จำนวนเซลล์และ flip-flop ของแต่ละดีไซน์

**คำถาม:** อ่านจาก `netlist/*_stat.txt` ว่าแต่ละดีไซน์มีเซลล์กี่ตัวและมี flip-flop กี่ตัว?

**เฉลย (จากการรันจริง):**

| ดีไซน์ | เซลล์ทั้งหมด | ชนิดเซลล์ | flip-flop |
|---|---|---|---|
| `cnt4` | 11 | 7 | 4 |
| `alu4` | 59 | 19 | 4 |
| `fsm_light` | 11 | 4 | **5** |
| `sr16` | 100 | 14 | 16 |

**ทำไม `fsm_light` มี 5 flip-flop ไม่ใช่ 2?**

เพราะ Yosys pass `fsm` แปลง FSM แบบ binary เป็น **one-hot** โดยอัตโนมัติ
- binary encoding: 2 บิต = 2 flip-flop
- one-hot encoding: 3 สถานะ → 3 flip-flop สำหรับ state + 2 ตัวสำหรับ output register
  (red/green/yellow) = 5

ถ้าอยากได้ 2 ให้ใช้ `fsm -norecode` หรือเขียน FSM เป็น one-hot ตั้งแต่ RTL

---

### D.7 — ชนิดเซลล์ในไลบรารี SG13G2

**คำถาม:** ไลบรารีมีกี่เซลล์ และแบ่งเป็นกี่กลุ่ม?

**เฉลย (จากการรันจริง):** **84 เซลล์**

| กลุ่ม | จำนวน |
|---|---|
| flip-flop | 9 |
| latch + latch clock | 7 |
| delay cell | 3 |
| utility / physical only | 10 |
| combinational gate | 55 |
| **รวม** | **84** |

ต้องอ่านจากคอมเมนต์ `// type:` ไม่ใช่จากชื่อเซลล์ (หัวข้อ 5)

---

### D.8 — ลบโฟลเดอร์ `results/` แล้วรัน

**คำถาม:** ถ้าลบโฟลเดอร์ `results/` ในโฟลเดอร์ lab แล้วรัน `run.cmd` จะเกิดอะไรขึ้น?

**เฉลย (จากการรันจริง):** จำลองจะตายทันที

```text
# ** Warning: (vsim-7) Failed to open VHDL file "results/trace_rtl.txt" in r+ mode.
# No such file or directory. (errno = ENOENT)
...
# ** Fatal: (vsim-7) Failed to open VHDL file "results/trace_rtl.txt" in r+ mode.
# Fatal error in Process stim at .../tb/tb_cnt4.vhd line 99
```

**แก้:** สคริปต์ทุก lab ต้องมี `file mkdir results` ก่อนเรียก `vsim`

---

### D.9 — `entity work.cnt4` ต่างจาก `component cnt4` อย่างไร?

**คำถาม:** ถ้าเปลี่ยน testbench จาก `component cnt4` เป็น `entity work.cnt4`
แล้วขับ gate netlist จะเกิดอะไรขึ้น?

**เฉลย (จากการรันจริง):** **ใช้ได้ใน ModelSim**
ModelSim ผูก entity declaration ของ VHDL เข้ากับ Verilog module ที่ชื่อเดียวกันได้

```text
# Loading work.tb_cnt4_entity(sim)
# Loading work.cnt4
# Loading work.sg13g2_nand3_1
# Loading work.sg13g2_dfrbpq_1
# Loading work.ihp_dff_r
# ** Note: ENTITY TRACE DONE
```

และ trace ที่ได้คือ

```text
q=1
q=2
q=3
q=4
q=5
q=6
q=7
q=8
q=9
```

ตัวนับเดินจริง → binding สำเร็จ

**แต่คู่มือนี้เลือก `component`** เพราะเป็นวิธีมาตรฐานที่ portable กว่า
(ดูหัวข้อ 1.7 สำหรับเหตุผลทั้งสามข้อ)

---

### D.10 — เขียน Tcl หาเซลล์ใน netlist

**คำถาม:** เขียน Tcl ที่อ่าน `netlist/cnt4_net.v` แล้วพิมพ์ชื่อเซลล์ที่ใช้
โดยไม่ผิดพลาดเรื่อง backslash

**เฉลย (จากการรันจริง):**

```tcl
set used {}
foreach line [split [gls_read_file $netfile] "\n"] {
    if {[regexp {^\s*(sg13g2_[A-Za-z0-9_]+)\s+\S+\s*\(} $line -> name]} {
        lappend used $name
    }
}
puts "[llength $used] instances, [llength [lsort -unique $used]] different cell types"
```

ผล

```text
11 instances, 7 different cell types
```

> ห้ามเขียน `"^\s*(sg13g2_...)"` ใน double quotes
> `\s` จะกลายเป็น `s` แล้ว pattern จะไม่ match
> ต้องใช้ braces `{...}` เสมอ

---

## ภาคผนวก E — ตัวเลขอ้างอิงทั้งหมด

ทุกตัวเลขในตารางนี้มาจากการรันจริงบนเครื่องนี้

### E.1 เครื่องมือ

| เครื่องมือ | เวอร์ชัน |
|---|---|
| ModelSim DE-64 | `vsim 2026.1 Simulator 2026.01 Jan 25 2026` |
| Questa Sim-64 | `vsim 2026.1 Simulator 2026.01 Jan 25 2026` |
| GHDL | `5.0.1 (Ubuntu 5.0.1+dfsg-1ubuntu1) [Dunoon edition]` |
| GNAT | `14.2.0` |
| Yosys | `0.52 (git sha1 fee39a3284c90249e1d9684cf6944ffbbcbb8f90)` |
| Icarus Verilog | `12.0 (stable)` |
| yosys-ghdl plugin | `/nix/store/55al5ccngwgjgigi20jh6d3my8h9x0i2-yosys-ghdl-2026-01-11/share/yosys/plugins/ghdl.so` |

### E.2 ไฟล์ชุดเซลล์

| ไฟล์ | ขนาด (bytes) | จำนวน design unit |
|---|---|---|
| `cells/sg13g2_stdcell.v` | 56,308 | 84 module + 17 primitive |
| `cells/sg13g2_udp.v` | 13,561 | 17 primitive |
| `cells/sg13g2_stdcell_typ_1p20V_25C.lib` | 1,748,984 | corner typ (1.20 V / 25 °C) |

### E.3 ไลบรารีเซลล์ (LAB 03)

| กลุ่ม | จำนวน |
|---|---|
| flip-flop | 9 |
| latch + latch clock | 7 |
| delay cell | 3 |
| utility / physical only | 10 |
| combinational gate | 55 |
| **รวม** | **84** |

Liberty: `time_unit : "1ns"` / `voltage_unit : "1V"` / `current_unit : "1uA"` / `capacitive_load_unit (1,pf)`

### E.4 netlist ทั้ง 4 ดีไซน์

| ดีไซน์ | เซลล์ | ชนิดเซลล์ | flip-flop | ports | wires | ขนาด Verilog กลาง |
|---|---|---|---|---|---|---|
| `cnt4` | 11 | 7 | 4 | 4 | 19 | 30 บรรทัด |
| `alu4` | 59 | 19 | 4 | 7 | 81 | 77 บรรทัด |
| `fsm_light` | 11 | 4 | 5 | 6 | 23 | 97 บรรทัด |
| `sr16` | 100 | 14 | 16 | 6 | 188 | 57 บรรทัด |

### E.5 ผลการรันทุก lab

| Lab | ผล | ตัวเลขสำคัญ |
|---|---|---|
| LAB 01 | PASS | checks = 9, errors = 0, trace 9 บรรทัด |
| LAB 02 | PASS | 11 instance, 7 ชนิด, 4 FF, เซลล์หาไม่พบ 0 |
| LAB 03 | PASS | 84 เซลล์, 5 กลุ่ม, ผลรวม 84 |
| LAB 04 | PASS | 11 บรรทัด `vsim-3033` (ตั้งใจให้ผิด), GLS PASS |
| LAB 05 | PASS | trace ทั้งสองระดับเหมือนกัน, 0 ความต่าง |
| LAB 06 | PASS | RTL `observed=3`, GLS `observed=X` |
| LAB 07 | PASS | RTL PASS / GLS FAIL, checks = 9, errors = 2 |
| LAB 08 | PASS | 3 ดีไซน์ผ่านหมด (alu4 6, fsm_light 5, sr16 5 บรรทัด) |
| **regression** | **ALL GREEN** | **total = 8, passed = 8, failed = 0** |

### E.6 trace มาตรฐานที่ใช้เทียบ

```text
# cnt4
q=0
q=1
q=2
q=3
q=4
q=5
q=6
q=6
q=9

# alu4
op=0 a=7 b=5 y=C zero=0
op=1 a=7 b=5 y=2 zero=0
op=2 a=C b=A y=8 zero=0
op=3 a=C b=A y=E zero=0
op=4 a=C b=A y=6 zero=0
op=0 a=F b=1 y=0 zero=1

# fsm_light
state=0 red=1 green=0 yellow=0
state=1 red=0 green=1 yellow=0
state=2 red=0 green=0 yellow=1
state=0 red=1 green=0 yellow=0
state=1 red=0 green=1 yellow=0

# sr16
qout=0000
qout=A5C3
qout=4B86
qout=25C3
qout=25C3
```

### E.7 exit code ของ `vsim`

| สถานการณ์ | exit code |
|---|---|
| รันจบปกติ | 0 |
| เปิดไฟล์ `.do` ไม่เจอ | 0 |
| `vsim-3033` / `vsim-3693` | 12 |
| Tcl `onerror` → `quit -code 90` | 90 |

---

## ภาคผนวก F — ไฟล์ทั้งหมดในโปรเจกต์

```text
questa_gls_vhdl_lab/
├── README.md
├── docs/
│   ├── Lab_Guide_QuestaSim_GLS.md
│   ├── Lab_Guide_QuestaSim_GLS.html
│   ├── Lab_Guide_QuestaSim_GLS.pdf
│   ├── lab_style.css
│   └── parts/
│       ├── 01_intro_lab01-04.md
│       ├── 02_lab05-08.md
│       └── 03_appendix.md
├── tools/
│   ├── pick_tool.cmd              เลือกชุดติดตั้งที่ license ว่าง
│   ├── run_template.cmd           เทมเพลต run.cmd (จำลอง 1 ครั้ง)
│   ├── run_template_2step.cmd     เทมเพลต run.cmd (จำลอง 2 ครั้ง)
│   ├── make-runners.ps1           สร้าง run.cmd ของทุก lab
│   ├── make-zip.ps1               สร้างไฟล์ ZIP
│   ├── build-docs.ps1             รวม Markdown -> HTML -> PDF
│   ├── gls_common.do              proc ช่วยเหลือร่วมกัน
│   ├── check_vhdl.sh              ตรวจ VHDL ด้วย GHDL (WSL)
│   ├── synth/synth.sh             VHDL -> netlist (WSL)
│   ├── synth/probe_env.sh         รายงานสภาพแวดล้อม (WSL)
│   └── probe/probe_top.vhd        design จิ๋วสำหรับ license probe
├── rtl/
│   ├── cnt4.vhd      (903 B)
│   ├── alu4.vhd      (2,049 B)
│   ├── fsm_light.vhd (2,125 B)
│   └── sr16.vhd      (1,740 B)
├── tb/
│   ├── tb_cnt4.vhd      (6,899 B)
│   ├── tb_cnt4_x.vhd    (4,771 B)
│   ├── tb_alu4.vhd      (5,524 B)
│   ├── tb_fsm_light.vhd (5,743 B)
│   └── tb_sr16.vhd      (5,381 B)
├── netlist/
│   ├── cnt4_net.v       (1,650 B)
│   ├── cnt4_bug_net.v   (2,389 B)
│   ├── alu4_net.v       (6,786 B)
│   ├── fsm_light_net.v  (1,806 B)
│   ├── sr16_net.v       (15,472 B)
│   ├── *_stat.txt
│   ├── *_synth.log
│   └── vhdl2verilog/
│       ├── cnt4_rtl.v      (614 B)
│       ├── alu4_rtl.v      (1,777 B)
│       ├── fsm_light_rtl.v (2,217 B)
│       └── sr16_rtl.v      (1,315 B)
├── cells/
│   ├── sg13g2_stdcell.v
│   ├── sg13g2_udp.v
│   └── sg13g2_stdcell_typ_1p20V_25C.lib
├── lab01_rtl_baseline/     ... lab08_gls_regression/
└── lab08_gls_regression/results/   log + สรุปของทั้งชุด
```

### แผนผัง lab

| Lab | ชื่อโฟลเดอร์ | จำนวน process | สิ่งที่พิสูจน์ |
|---|---|---|---|
| 01 | `lab01_rtl_baseline` | 1 | จุดอ้างอิงระดับ RTL (9 checks) |
| 02 | `lab02_synth_netlist` | 1 | netlist ถูกต้องและเซลล์มีอยู่จริง |
| 03 | `lab03_cell_library` | 1 | ไลบรารี 84 เซลล์ แบ่งเป็น 5 กลุ่ม |
| 04 | `lab04_gls_first` | 1 (+ `run_wrong.cmd`) | GLS ครั้งแรก + ดู error จริงจากการทำผิด |
| 05 | `lab05_rtl_vs_gate` | 2 | trace สองระดับเหมือนกัน |
| 06 | `lab06_x_propagation` | 2 | RTL กลืน `x` แต่ GLS จับได้ |
| 07 | `lab07_netlist_bug` | 2 | GLS จับบั๊กที่ RTL จับไม่ได้ |
| 08 | `lab08_gls_regression` | 6 | รวมทั้งชุด + สามดีไซน์เพิ่ม |

---

## ภาคผนวก G — วิธีแก้ปัญหาแบบเร็ว

เมื่อ lab ไม่ผ่าน ให้ไล่ตามลำดับนี้

### ขั้นที่ 1 — ดูว่า fail ที่ไหน

```bat
type result.txt
type transcript | findstr /C:"Error" /C:"Fatal"
```

### ขั้นที่ 2 — เช็คว่าเรียกจากโฟลเดอร์ถูก

ทุก lab script มี guard นี้

```tcl
if {![file exists ../netlist/cnt4_net.v]} {
    puts "!! wrong folder : [pwd]"
    puts "!! this script must be run from lab04_gls_first"
    quit -code 2
}
```

ถ้าเห็นข้อความนี้ แปลว่าเรียกจากผิดโฟลเดอร์

### ขั้นที่ 3 — ตรวจ license

```bat
call ..\tools\pick_tool.cmd
echo %MT%
```

ถ้า `MT` ว่าง แปลว่า license ไม่ว่างทั้งหมด

### ขั้นที่ 4 — ดูว่า design ผูกกับอะไร

```bat
type transcript | findstr /C:"Loading work"
```

- `Loading work.cnt4(rtl)` → ผูกกับ VHDL entity
- `Loading work.cnt4` → ผูกกับ Verilog module

### ขั้นที่ 5 — เทียบกับ trace มาตรฐาน (ภาคผนวก E.6)

### ขั้นที่ 6 — ถ้ายังไม่ออก ให้รัน GHDL

```bash
wsl -d Ubuntu -u root -- bash /mnt/c/.../tools/check_vhdl.sh
```

จะบอกว่าปัญหาอยู่ที่ VHDL หรือที่ netlist

---

## ภาคผนวก H — สรุปสิ่งที่ต้องจำ

1. **testbench VHDL ชุดเดียว ขับได้ทั้ง RTL และ gate**
   โดยประกาศ DUT เป็น `component` และเปลี่ยนแค่ไฟล์ที่คอมไพล์
2. **ต้องใส่ `-t 10ps`** ทุกครั่งที่โหลด gate netlist
3. **ชื่อ entity/module และชื่อ port ต้องตรงกันทุกตัวอักษร**
4. **ModelSim session เดียวจำลองได้ครั้งเดียว** ให้แยกเป็นสอง process
5. **`vsim` คืน 0 แม้ล้มเหลว** ให้อ่าน verdict จากไฟล์เสมอ
6. **อ่านชนิดเซลล์จาก `// type:`** ไม่ใช่จากชื่อเซลล์
7. **VHDL กับ Verilog มี semantics ของ `x` ต่างกัน** และนั่นคือหัวใดของ GLS
8. **GLS จับบั๊กที่ RTL จับไม่ได้** และนั่นคือเหตุผลที่ต้องมี GLS
9. **ใน Tcl ห้ามใช้ `"\s"` ใน double quotes** ให้ใช้ `{...}`
10. **ใน `.cmd` ห้ามมีข้อความไทยหรือ UTF-8** ให้เป็น ASCII ล้วน
