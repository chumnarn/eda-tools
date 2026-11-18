
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
