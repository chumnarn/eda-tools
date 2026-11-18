## ภาคนำ

### คู่มือนี้คืออะไร

คู่มือนี้สอน **การจำลองระดับ gate (Gate-Level Simulation, GLS)** ด้วย QuestaSim
ตั้งแต่พื้นฐานจนถึงระดับที่เอาไปใช้ต่อในงานจริงได้
แยกเป็น **8 lab แบบทีละขั้น** ที่ทำตามแล้วรันได้จริงทุกขั้น

จุดต่างของคู่มือนี้คือ **ตัวเลขและข้อความทุกตัวมาจากการรันจริงบนเครื่อง**
ไม่ใช่ตัวอย่างที่แต่งขึ้น — ทำซ้ำตามคู่มือแล้วจะได้ผลชุดเดียวกัน

### ผู้เรียนจะได้อะไร

เมื่อทำครบทุก lab ผู้เรียนจะทำสิ่งเหล่านี้ได้ด้วยตัวเอง

1. อธิบายได้ว่า **RTL simulation กับ gate level simulation ต่างกันอย่างไร**
   และอะไรที่ gate level จับได้แต่ RTL จับไม่ได้
2. สังเคราะห์ RTL เป็น **gate netlist** ด้วย Yosys + Liberty ของ IHP SG13G2
3. จำลอง netlist นั้นใน QuestaSim โดยใช้ **testbench ชุดเดียวกับกับกับระดับ RTL**
4. อ่าน **เซลล์มาตรฐาน** ของ SG13G2 และเข้าใจว่า Liberty, Verilog model
   และ timing check ของแต่ละเซลล์เป็นอย่างไร
5. จับ **บั๊กใน netlist** ที่การจำลองระดับ RTL มองไม่เห็น
6. สร้าง **regression** ของการจำลองระดับ gate ที่รันซ้ำได้และรหัสจบนำไปใช้กับ CI ได้

### วิธีใช้คู่มือนี้

ทุก lab มีโครงสร้างเดียวกัน

```text
labNN_xxx/
├── run.cmd        ตัวรันแบบ Windows  (เลือกเครื่องมือ + ตัดสิน PASS/FAIL)
├── run.do         สคริปต์สำหรับใช้ในหน้าต่าง GUI
├── run_rtl.do     สคริปต์จำลองระดับ RTL   (มีใน lab ที่เทียบสองระดับ)
├── run_gls.do     สคริปต์จำลองระดับ gate (มีใน lab ที่เทียบสองระดับ)
└── results/       ผลลัพธ์จากการรัน
```

รัน lab เดียวด้วย

```bat
cd questa_gls_lab\lab05_rtl_vs_gate
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
- **Yosys ใช้เฉพาะตอนสังเคราะห์ netlist ใหม่** และต้องรันใน WSL (หัวข้อ 2.2)
  netlist ที่สังเคราะห์ไว้แล้วอยู่ใน `netlist/` ของคู่มือนี้
  ดังนั้น **ทุก lab ที่เป็นการจำลอง รันได้บน Windows ล้วน ๆ**

---

## บทที่ 1 — เตรียมเครื่องมือ

### 1.1 เครื่องมือที่ใช้ (ทุกตัววัดจริงบนเครื่องนี้)

| เครื่องมือ | เวอร์ชันที่วัดได้ | ใช้ทำอะไร |
|---|---|---|
| ModelSim DE-64 | `vsim 2026.1 Simulator 2026.01 Jan 25 2026` | จำลองระดับ RTL และระดับ gate |
| Questa Sim-64 | `vsim 2026.1 Simulator 2026.01 Jan 25 2026` | เหมือนกัน (เป็นชุดเต็ม) |
| Yosys | `0.52 (git sha1 fee39a3284c90249e1d9684cf6944ffbbcbb8f90)` | สังเคราะห์ RTL → netlist |
| ABC (ใน Yosys) | เป็นส่วนหนึ่งของ Yosys 0.52 | map logic เข้าเซลล์จริงตาม Liberty |
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
(คอมไพล์ design จิ๋วแล้วโหลดจริง — เพราะ license ถูกเช็คตอน “โหลด design” เท่านั้น)
แล้วเลือกชุดแรกที่ใช้ได้

ผลที่วัดได้จริงขณะที่ QuestaSim GUI ยังเปิดค้างอยู่

```text
 tool   : C:\Siemens\modelsim_dlx64_2026.1\win64pe
```

ถ้าอยากบังคับให้ใช้ชุดใดชุดหนึ่ง ให้ตั้ง `QUESTASIM_HOME` หรือ `MODELSIM_HOME`

### 1.3 โครงสร้างโฟลเดอร์ของคู่มือ

```text
questa_gls_lab/
├── docs/                     คู่มือฉบับนี้ (Markdown / HTML / PDF)
├── tools/
│   ├── pick_tool.cmd          เลือกชุดติดตั้งที่ยังมี license ว่าง (ใช้ร่วมกันทุก lab)
│   ├── run_template.cmd       เทมเพลต run.cmd ของ lab ที่จำลองครั้งเดียว
│   ├── run_template_2step.cmd เทมเพลต run.cmd ของ lab ที่ต้องรันสองครั้ง
│   ├── make-runners.ps1       ตัวสร้าง run.cmd ของทุก lab
│   ├── gls_common.do          proc ช่วยเหลือที่ทุก lab ใช้ร่วมกัน
│   ├── synth/synth.sh         สคริปต์สังเคราะห์ (รันใน WSL)
│   ├── build-docs.ps1         รวม Markdown แล้วสร้าง HTML + PDF
│   └── probe/probe_top.vhd    design จิ๋วสำหรับ license probe
├── rtl/                       โค้ด RTL ที่ใช้ในคู่มือ (Verilog)
│   ├── cnt4.v                 ตัวนับ 4 บิต
│   ├── alu4.v                 ALU 4 บิต
│   ├── fsm_light.v            FSM ไฟสัญญาณจราจร
│   └── sr16.v                 shift register 16 บิต
├── netlist/                   gate netlist ที่สังเคราะห์ไว้แล้ว
│   ├── cnt4_net.v             netlist ปกติ
│   ├── cnt4_bug_net.v         netlist ที่ใส่บั๊กไว้ (LAB 07)
│   ├── *_stat.txt             สถิติจาก Yosys
│   └── *_synth.log            log ฉบับเต็มของการสังเคราะห์
├── cells/                     โมเดลเซลล์ + Liberty ของ SG13G2
├── tb/                        testbench ที่ใช้ร่วมกันทุก lab
├── lab01_rtl_baseline/        ... lab08_gls_regression/
└── lab08_gls_regression/results/   ผลรวมของทั้งชุด
```

> **จุดสำคัญของโครงสร้างนี้**
> `rtl/`, `netlist/`, `cells/` และ `tb/` อยู่ระดับเดียวกัน
> และแต่ละ lab อ้างถึงด้วยพาธแบบสัมพัทธ์ (`../rtl/cnt4.v`)
> ทำให้ **testbench ชุดเดียวกันถูกใช้ได้ทั้งระดับ RTL และระดับ gate**
> ซึ่งเป็นหัวใจของคู่มือนี้

### 1.4 RTL กับ gate level ต่างกันอย่างไร

| | RTL simulation | Gate level simulation |
|---|---|---|
| สิ่งที่จำลอง | พฤติกรรมที่เขียนไว้ (`always @(posedge clk)`) | โครงสร้างจริงของวงจร (transistor → gate → cell) |
| โมเดลของ flip-flop | `reg` ที่มีพฤติกรรมตามโค้ด | `sg13g2_dfrbpq_1` ที่มี timing check และ specify block |
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
vlog -work work x.v       :: คอมไพล์ Verilog เข้าไลบรารี work
vsim -voptargs=+acc work.tb_cnt4     :: โหลด design (ต้องมี +acc ถ้าจะดูค่าใน hierarchy)
run -all                  :: จำลองจนจบ
quit -f                   :: ออกจากตัวจำลอง
```

ดูค่าของสัญญาณ

```tcl
examine -radix hex -value /tb_cnt4/dut/q
examine -radix binary -value /tb_cnt4/dut/en
```

---

## LAB 01 — เส้นฐาน: จำลอง RTL ที่เป็นจุดอ้างอิง

### เป้าหมาย

จำลอง `cnt4` ที่ระดับ RTL ด้วย testbench แบบตรวจตัวเอง
ผลลัพธ์ของ lab นี้จะเป็น **จุดอ้างอิง** ที่ lab ที่ 5 เป็นต้นนำไปเทียบกับระดับ gate

### ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | หน้าที่ |
|---|---|
| `rtl/cnt4.v` | DUT — ตัวนับ 4 บิต พร้อม reset แบบ asynchronous |
| `tb/tb_cnt4.v` | testbench แบบตรวจตัวเอง + เขียน trace ลงไฟล์ |

### ดูโค้ดของ DUT

```verilog
module cnt4 (
    input  wire       clk,
    input  wire       rst_n,     // asynchronous, active low
    input  wire       en,
    output reg  [3:0] q
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)      q <= 4'd0;   // asynchronous reset
    else if (en)     q <= q + 4'd1;
  end

endmodule
```

### ขั้นตอน

**ขั้นที่ 1 : รัน**

```bat
cd questa_gls_lab\lab01_rtl_baseline
run.cmd
```

**ขั้นที่ 2 : ดูผลลัพธ์จริง**

```text
# === tb_cnt4 : RTL ===
#   t=16.000 ns : after reset          q = 0
#   t=26.000 ns : count up             q = 1
#   t=36.000 ns : count up             q = 2
#   t=46.000 ns : count up             q = 3
#   t=56.000 ns : count up             q = 4
#   t=66.000 ns : count up             q = 5
#   t=76.000 ns : count up             q = 6
#   t=106.000 ns : hold, en = 0          q = 6
#   t=136.000 ns : count up again       q = 9
#   checks = 9 , errors = 0
# TEST_PASSED : tb_cnt4 completed
RESULT: PASS
[RESULT] PASS
```

**ขั้นที่ 3 : ดู trace ที่ testbench เขียนไว้**

```bat
type results\trace_rtl.txt
```

ไฟล์นี้มี 10 บรรทัด (หนึ่งบรรทัดต่อการตรวจหนึ่งครั้ง)
และจะได้ถูกเทียบกับ trace ของระดับ gate ใน LAB 05

### สิ่งที่ควรรู้จาก Lab นี้

**1. testbench เขียนผลลัพธ์ลงไฟล์เอง ไม่พึ่ง exit code ของ `vsim`**

```verilog
task write_result(input [8*64:1] fname, input [8*16:1] verdict);
    integer f;
    begin
      f = $fopen(fname, "w");
      if (f != 0) begin
        $fdisplay(f, "%0s", verdict);
        $fclose(f);
      end
    end
endtask
```

เหตุผล: `vsim` คืน exit code `0` **เสมอ** แม้จะเปิดไฟล์ `.do` ไม่ได้เลย
(ดูข้อ ค.4 ในภาคผนวก ค) การอ่านไฟล์ผลลัพธ์ที่ testbench เขียนเองจึงเป็นวิธีที่เชื่อถือได้

**2. `$realtime` ไม่ใช่ `$time`**

ถ้าใช้ `$display("t=%0t", $time)` จะได้เลขหน่วย **10 ps** (ความละเอียดเวลาของตัวจำลอง)
คือ `1600` แทน `16` ต้องใช้ `$realtime` ซึ่งคืนค่าเป็น `real` ในหน่วยเวลาของโมดูล

```verilog
$display("  t=%0.3f ns : after reset          q = %h", $realtime, q);
```

**3. ตัวตรวจใช้ `!==` ไม่ใช่ `!=`**

```verilog
if (got !== exp) begin ... end
```

`!==` เปรียบเทียบรวมค่า `x` ด้วย ถ้าใช้ `!=` ค่า `x` จะทำให้เงื่อนไขเป็น `false`
และบั๊กจะหลุดลอดออกไปโดยไม่มีใครรู้ตัว

### แบบฝึกหัด

1. แก้ `rtl/cnt4.v` ให้นับลงแทนขึ้น แล้วรันซ้ำ → ควร FAIL
2. แก้ `tb/tb_cnt4.v` ให้เปลี่ยน `en` เป็น `1'bx` ชั่วขณะ
   แล้วดูว่า `q` เป็นอะไร (เตรียมดูคำตอบใน LAB 06)

---

## LAB 02 — จาก RTL มาเป็น gate netlist ด้วย Yosys

### เป้าหมาย

ดูว่า “สิ่งที่เขียนไว้” กับ “สิ่งที่วงจรจริงเป็น” ต่างกันแค่ไหน
โดยสังเคราะห์ `cnt4` เป็น gate netlist ของเซลล์ SG13G2 จริง ๆ

### ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | หน้าที่ |
|---|---|
| `tools/synth/synth.sh` | สคริปต์ที่รัน Yosys (ต้องรันใน WSL) |
| `netlist/cnt4_net.v` | netlist ที่สังเคราะห์ไว้แล้ว |
| `netlist/cnt4_stat.txt` | สถิติของวงจรจาก Yosys |
| `netlist/cnt4_synth.log` | log ฉบับเต็มของการสังเคราะห์ |
| `cells/sg13g2_stdcell_typ_1p20V_25C.lib` | Liberty ที่ Yosys ใช้หาเซลล์ |

### ขั้นตอน

**ขั้นที่ 1 : ดู netlist ที่สังเคราะห์ไว้**

```bat
cd questa_gls_lab\lab02_synth_netlist
run.cmd
```

**ขั้นที่ 2 : ดูผลลัพธ์จริง**

สถิติจาก Yosys

```text
=== cnt4 ===

   Number of wires:                 11
   Number of wire bits:             14
   Number of ports:                  4
   Number of port bits:              7
   Number of cells:                 11
     sg13g2_a21o_1                   1
     sg13g2_and2_1                   1
     sg13g2_dfrbpq_1                 4
     sg13g2_nand3_1                  1
     sg13g2_nand4_1                  1
     sg13g2_xnor2_1                  2
     sg13g2_xor2_1                   1
```

สรุปที่สคริปต์ของ lab พิมพ์ออกมา

```text
---- 1. the statistics file ----
...
---- 2. the cells used by the netlist ----
   sg13g2_xor2_1
   sg13g2_nand3_1
   sg13g2_a21o_1
   sg13g2_and2_1
   sg13g2_nand4_1
   sg13g2_xnor2_1
   sg13g2_dfrbpq_1
---- 11 instances, 7 different cell types ----
---- 3. check every cell against the library ----
   OK : every cell of the netlist exists in ../cells/sg13g2_stdcell.v
---- 4. the design needs 4 flip-flops (a 4 bit counter needs 4) ----
RESULT: PASS
```

### ขั้นตอน (ถ้าอยากสังเคราะห์เอง — ต้องมี WSL)

**ขั้นที่ 3 : สังเคราะห์ใหม่**

```bash
# ใน WSL
cd /mnt/c/Users/000148/Documents/MiniMax/eda-tools/questa_gls_lab
bash tools/synth/synth.sh cnt4
```

สคริปต์จะทำงานนี้ (ดูไฟล์ `tools/synth/synth.sh`)

```tcl
read_verilog rtl/cnt4.v
hierarchy -check -top cnt4
proc; opt; fsm; opt; memory; opt
techmap; opt
dfflibmap -liberty <SG13G2 typ>.lib
abc -liberty <SG13G2 typ>.lib
setundef -zero
splitnets
opt_clean
write_verilog -noattr netlist/cnt4_net.v
stat
```

ผลที่วัดได้จริงจาก log

```text
ABC RESULTS:     sg13g2_a21o_1 cells:        1
ABC RESULTS:     sg13g2_and2_1 cells:        1
ABC RESULTS:    sg13g2_nand3_1 cells:        1
ABC RESULTS:    sg13g2_nand4_1 cells:        1
ABC RESULTS:    sg13g2_xnor2_1 cells:        2
ABC RESULTS:     sg13g2_xor2_1 cells:        1
ABC RESULTS:        internal signals:        6
ABC RESULTS:           input signals:        5
ABC RESULTS:          output signals:        4
```

### ขนาดของวงจรจริงของดีไซน์ทั้งสี่

| ดีไซน์ | จำนวนเซลล์ | จำนวนชนิดเซลล์ | flip-flop |
|---|---|---|---|
| `cnt4` (ตัวนับ 4 บิต) | 11 | 7 | 4 |
| `fsm_light` (FSM ไฟสัญญาณจราจร) | 11 | 4 | 5 |
| `alu4` (ALU 4 บิต) | 64 | 19 | 4 |
| `sr16` (shift register 16 บิต) | 102 | 14 | 16 |

> สังเกตว่า `sr16` มี 102 เซลล์ แต่มีแค่ 16 flip-flop
> เพราะตัว shift register ต้องมี **มัลติเพลเซอร์** (mux) ต่อบิตด้วย
> นี่คือเหตุผลที่ gate level simulation ช้ากว่า RTL simulation มาก

### สิ่งที่ควรรู้จาก Lab นี้

**1. `dfflibmap` ต้องมาก่อน `abc` เสมอ**

```tcl
dfflibmap -liberty <lib>
abc       -liberty <lib>
```

`abc` ทำงานเฉพาะ logic combinational เท่านั้น
ถ้าให้ `abc` ไปจัดการ flip-flop ด้วยมันจะข้ามเซลล์ sequential ทั้งหมด
(log จะขึ้นว่า `Scl_LibertyReadGenlib() skipped sequential cell "sg13g2_dfrbp_1"`)

**2. ดู netlist ที่สังเคราะห์ได้**

```verilog
  sg13g2_dfrbpq_1 _14_ (
    .CLK(clk),
    .D(_00_),
    .Q(q[0]),
    .RESET_B(rst_n)
  );
```

จะเห็นว่า **ชื่อ port ของ RTL ยังอยู่** (`clk`, `rst_n`, `q`)
และ flip-flop กลายเป็น `sg13g2_dfrbpq_1` (D flip-flop with reset, แบบ Q only)
นี่คือเหตุผลที่ **testbench ชุดเดิมยังใช้ได้ทั้งสองระดับ**

**3. Yosys เปลี่ยนโครงสร้างของโค้ดที่เขียนไว้**

โค้ด RTL เขียนว่า `q <= q + 1`
แต่ใน netlist กลายเป็นตรรกะของ adder ที่ map เป็น `xor2` / `nand3` / `nand4` / `a21o` / `and2` / `xnor2`
ซึ่งเป็นเซลล์ที่เล็กที่สุดและช้าที่สุดที่ทำหน้าที่นั้นได้

### แบบฝึกหัด

1. สังเคราะห์ `alu4` ด้วยตัวเอง แล้วดูว่าต้องใช้เซลล์กี่ตัว / กี่ชนิด
2. แก้ `rtl/cnt4.v` ให้เป็นตัวนับ 8 บิต แล้วสังเคราะห์ใหม่
   → จำนวนเซลล์จะเปลี่ยนอย่างไร
3. ลองสังเคราะห์โดยไม่มี `dfflibmap` แล้วดูว่า netlist ผิดอย่างไร

---

## LAB 03 — รู้จักชุดเซลล์ SG13G2

### เป้าหมาย

ก่อนจะจำลอง netlist ได้ ตัวจำลองต้อง “รู้จัก” เซลล์แต่ละตัวว่าทำงานอย่างไร
lab นี้จะเปิดชุดเซลล์ SG13G2 ออกมาดูว่าข้างในมีอะไรบ้าง

### ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | หน้าที่ |
|---|---|
| `cells/sg13g2_stdcell.v` | โมเดลการจำลองของเซลล์ทั้งหมด |
| `cells/sg13g2_stdcell_typ_1p20V_25C.lib` | Liberty (ข้อมูลเวลา/กำลัง/ขนาดของเซลล์) |

### เซลล์หนึ่งตัวดูหน้าตาแบบไหน

```verilog
// type: AO21
`timescale 1ns/10ps
`celldefine
module sg13g2_a21o_1 (X, A1, A2, B1);
	output X;
	input A1, A2, B1;

	// Function
	wire int_fwire_0;

	and (int_fwire_0, A1, A2);
	or (X, int_fwire_0, B1);

	// Timing
	specify
		if (B1 == 1'b0)
			(A1 => X) = 0;
		ifnone (A1 => X) = 0;
		...
	end specify
endmodule
```

สังเกตว่าเซลล์แบ่งเป็นสามส่วน

| ส่วน | คืออะไร |
|---|---|
| `// Function` | ตรรกะของเซลล์ (เขียนด้วย gate พื้นฐาน) |
| `// Timing` | `specify` block = ค่าหน่วงและเงื่อนไขการตรวจเวลา |
| `\`celldefine` | ป้องกันไม่ให้เซลล์ถูก compile ซ้ำ |

### ขั้นตอน

**ขั้นที่ 1 : รัน**

```bat
cd questa_gls_lab\lab03_cell_library
run.cmd
```

**ขั้นที่ 2 : ดูผลลัพธ์จริง**

```text
---- 2. the cells of the library ----
   84 modules
   flip-flops (sequential)  : 9
   latches + latch clocks   : 7
   delay cells              : 3
   utility / physical only  : 10
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

> **อย่าจำแนกเซลล์จากชื่อ**
> ชุดเซลล์นี้มีชื่อที่ “หลอก” อยู่หลายตัว
> เช่น `sg13g2_decap_4` เริ่มต้นด้วย `d` แต่เป็น **ตัวถอดหลัง (decapacitor)** ไม่ใช่ flip-flop
> และ `sg13g2_dlygate4sd1_1` เริ่มต้นด้วย `d` แต่เป็น **เซลล์หน่วง** ไม่ใช่ตรรกะ
> สคริปต์ของ lab นี้จึงอ่านคอมเมนต์ `// type: XXX` ที่ PDK ใส่ไว้เหนือโมดูล
> แล้วจัดกลุ่มตาม **ชนิดเซลล์จริง** ไม่ใช่ตามชื่อ

เซลล์ที่เป็น **flip-flop** ของ SG13G2 (9 ตัว)

```text
   sg13g2_dfrbp_1       (Q, Q_N, D, RESET_B, CLK)
   sg13g2_dfrbp_2       (Q, Q_N, D, RESET_B, CLK)
   sg13g2_dfrbpq_1      (Q, D, RESET_B, CLK)
   sg13g2_dfrbpq_2      (Q, D, RESET_B, CLK)
   sg13g2_sdfbbp_1      (scan D flip-flop, set/reset)
   sg13g2_sdfrbp_1      (scan D flip-flop)
   sg13g2_sdfrbp_2
   sg13g2_sdfrbpq_1
   sg13g2_sdfrbpq_2
```

เซลล์ที่เป็น **latch** และ **นาฬิกาควบคุม latch** (7 ตัว)

```text
   sg13g2_dlhq_1        (latch, level sensitive, transparent high)
   sg13g2_dlhr_1
   sg13g2_dlhrq_1
   sg13g2_dllr_1
   sg13g2_dllrq_1
   sg13g2_lgcp_1        (latch gated clock pulse)
   sg13g2_slgcp_1       (scan version ของ lgcp)
```

เซลล์ที่เป็น **หน่วงเวลา** (3 ตัว) และ **เซลล์ที่ไม่ใช่ตรรกะ** (10 ตัว)

```text
   sg13g2_dlygate4sd1_1   sg13g2_dlygate4sd2_1   sg13g2_dlygate4sd3_1
   sg13g2_antennanp   (antenna)      sg13g2_decap_4 / sg13g2_decap_8
   sg13g2_fill_1 / _2 / _4 / _8      sg13g2_sighold
   sg13g2_tiehi / sg13g2_tielo
```

> **ข้อสังเกตที่สำคัญ**
> ชุดเซลล์นี้มี **latch** อยู่ด้วย
> นั่นแปลว่าถ้าสังเคราะห์แล้วได้ latch ที่ไม่ควรได้ (หรือ enable ของ latch หายไป)
> ระดับ gate จะเผยให้เห็นทันที ซึ่งเป็นบั๊กที่การจำลองระดับ RTL มองไม่เห็น

### สิ่งที่ควรรู้จาก Lab นี้

**1. Liberty คืออะไร**

ไฟล์ `.lib` บอกว่าเซลล์แต่ละตัว “ช้าแค่ไหน กินกำลังเท่าไร ขนาดเท่าไร”
คือข้อมูลที่ Yosys ใช้ตัดสินใจว่าจะเลือกเซลล์ตัวไหน และที่ STA tool ใช้ตรวจเวลา

หน่วยที่วัดได้จากไฟล์ของ SG13G2

| หน่วย | ค่า | ความหมาย |
|---|---|---|
| `time_unit` | `1ns` | เวลาใน Liberty มีหน่วยเป็นนาโนวินาที |
| `capacitive_load_unit` | `1pf` | ความจุโหลดมีหน่วยเป็นพิโคฟารัด |
| `voltage_unit` | `1V` | แรงดันมีหน่วยเป็นโวลต์ |
| `current_unit` | `1uA` | กระแสมีหน่วยเป็นไมโครแอมป์ |

**2. SG13G2 มีหลาย corner**

ไฟล์ Liberty ใน PDK มี 6 corner

| ไฟล์ | corner |
|---|---|
| `sg13g2_stdcell_fast_1p32V_m40C.lib` | fast |
| `sg13g2_stdcell_fast_1p65V_m40C.lib` | fast |
| `sg13g2_stdcell_typ_1p20V_25C.lib` | typ (corner ที่คู่มือนี้ใช้) |
| `sg13g2_stdcell_typ_1p50V_25C.lib` | typ |
| `sg13g2_stdcell_slow_1p08V_125C.lib` | slow |
| `sg13g2_stdcell_slow_1p35V_125C.lib` | slow |

**3. โมเดล Verilog ของ SG13G2 เป็นแบบ functional + specify**

คือตรรกะเป็น gate พื้นฐาน (ไม่ใช่ black box)
แต่มี `specify` block ที่ให้เวลาหน่วงและเงื่อนไขการตรวจเวลา
แปลว่า **ถ้าใส่ SDF เข้าไป ตัวจำลองจะตรวจ timing ให้ด้วย**

### แบบฝึกหัด

1. เปิด `cells/sg13g2_stdcell.v` แล้วหาโมดูล `sg13g2_dfrbpq_1`
   ดูว่า flip-flop ตัวนี้ทำอะไรเมื่อ `RESET_B` เป็น `0`
2. ดู `sg13g2_lgcp_1` (latch) ว่าต่างจาก flip-flop อย่างไร
3. คอมไพล์ไลบรารี SG13G2 แล้วใช้ `examine` ดูค่าภายในของเซลล์

---

## LAB 04 — GLS ครั้งแรก

### เป้าหมาย

จำลอง `cnt4` ที่ระดับ gate จริง ๆ ด้วยเซลล์ SG13G2
และเข้าใจข้อผิดพลาดคลาสสิกของ GLS ที่ทุกคนเจอครั้งแรก

### ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | หน้าที่ |
|---|---|
| `cells/sg13g2_stdcell.v` | โมเดลเซลล์ |
| `netlist/cnt4_net.v` | netlist ของ `cnt4` |
| `tb/tb_cnt4.v` | testbench เดียวกับ lab 01 |
| `run.cmd` | ทางที่ถูกต้อง |
| `run_wrong.cmd` | ทางที่ผิด — จงใจให้พัง |

### ขั้นตอน

**ขั้นที่ 1 : ลองทางที่ผิดก่อน (เพื่อจะได้เห็นข้อความจริง)**

```bat
cd questa_gls_lab\lab04_gls_first
run_wrong.cmd
```

ผลลัพธ์จริง

```text
 ** Error: (vsim-3033) Instantiation of 'sg13g2_xor2_1' failed. The design unit was not found.
 ** Error: (vsim-3033) Instantiation of 'sg13g2_nand3_1' failed. The design unit was not found.
 ** Error: (vsim-3033) Instantiation of 'sg13g2_a21o_1' failed. The design unit was not found.
 ** Error: (vsim-3033) Instantiation of 'sg13g2_and2_1' failed. The design unit was not found.
 ** Error: (vsim-3033) Instantiation of 'sg13g2_nand4_1' failed. The design unit was not found.
 ** Error: (vsim-3033) Instantiation of 'sg13g2_xnor2_1' failed. The design unit was not found.
 ** Error: (vsim-3033) Instantiation of 'sg13g2_xnor2_1' failed. The design unit was not found.
 ** Error: (vsim-3033) Instantiation of 'sg13g2_dfrbpq_1' failed. The design unit was not found.
 ** Error: (vsim-3033) Instantiation of 'sg13g2_dfrbpq_1' failed. The design unit was not found.
 ** Error: (vsim-3033) Instantiation of 'sg13g2_dfrbpq_1' failed. The design unit was not found.
 ** Error: (vsim-3033) Instantiation of 'sg13g2_dfrbpq_1' failed. The design unit was not found.
 Error loading design
```

> **นี่คือข้อผิดพลาดคลาสสิกที่สุดของ GLS**
> เซลล์อยู่คนละไลบรารีกับ netlist → ตัวจำลองหาเซลล์ไม่เจอ
> และ **exit code ก็ยังเป็น 0** ต้องดูข้อความ `Error loading design` เท่านั้น

**ขั้นที่ 2 : ทางที่ถูกต้อง**

```bat
run.cmd
```

ผลลัพธ์จริง

```text
# === tb_cnt4 : GATE LEVEL ===
#   t=16.000 ns : after reset          q = 0
#   t=26.000 ns : count up             q = 1
#   t=36.000 ns : count up             q = 2
#   t=46.000 ns : count up             q = 3
#   t=56.000 ns : count up             q = 4
#   t=66.000 ns : count up             q = 5
#   t=76.000 ns : count up             q = 6
#   t=106.000 ns : hold, en = 0          q = 6
#   t=136.000 ns : count up again       q = 9
#   checks = 9 , errors = 0
# TEST_PASSED : tb_cnt4 completed
RESULT: PASS
[RESULT] PASS
```

เทียบกับผลของ LAB 01 ที่ระดับ RTL — **เหมือนกันทุกตัว**

### สิ่งที่ควรรู้จาก Lab นี้

**1. เซลล์และ netlist ต้องอยู่ในไลบรารีเดียวกัน**

```tcl
vlib work
vmap work work
vlog -work work ../cells/sg13g2_stdcell.v     # <<< เซลล์
vlog -work work ../netlist/cnt4_net.v          # <<< netlist
vlog -work work ../tb/tb_cnt4.v                # <<< testbench
```

วิธีอื่นที่ใช้ได้คือแยกไลบรารีแล้วอ้างชื่อแบบเต็มใน netlist
(`sg13g2.sg13g2_inv_1`) ซึ่ง Yosys ไม่ได้ทำให้เอง — ต้องแก้ netlist ด้วยมือ
วิธีแรกง่ายกว่าและเป็นวิธีที่ใช้ใน flow จริงหลาย ๆ

**2. เวลาหน่วงของเซลล์เป็นศูนย์ในการจำลองแบบนี้**

โมเดล SG13G2 ประกาศ `` `timescale 1ns/10ps `` และใส่ค่าหน่วงเป็น `0` ใน `specify`
การจำลองจึงเห็นเวลาเป็น “ศูนย์หน่วง” — เหมือนการจำลอง RTL
ถ้าอยากให้เห็นหน่วงจริง ต้องใส่ SDF ซึ่งอยู่นอกขอบเขตของคู่มือฉบับนี้

**3. `+acc` ยังจำเป็น**

```tcl
vsim -voptargs=+acc work.tb_cnt4
```

> **ผลที่วัดได้จริงบน netlist ขนาดเล็กของคู่มือนี้**
> `examine` ภายในตัวเซลล์ให้ผล **เหมือนกันทั้งสองแบบ**
> ทั้งแบบไม่ใส่ `+acc` และแบบใส่ `+acc` ตอนรัน
> ต่างกันแค่ตอนโหลด design ที่ log จะขึ้น `Loading work.sg13g2_xor2_1` เป็นต้น
> และรายการสัญญาณภายใน `dut` มี 11 ตัวทั้งสองแบบ
>
> ข้อแตกต่างจะเห็นชัดเมื่อ **วงจรใหญ่ขึ้น** เพราะตัว optimize จะตัดสัญญาณ
> ที่ไม่มีใครอ้างถึงทิ้งได้ ให้ใส่ `+acc` ไว้เสมอเพื่อความชัวร์ตอน debug
> ว่าอยู่ข้างในเซลล์เป็นอะไร

### แบบฝึกหัด

1. แก้ `run_batch.do` ให้เอา `vlog -work work ../cells/sg13g2_stdcell.v` ออก
   แล้วรัน → ต้องเห็นข้อความ `vsim-3033` เหมือนขั้นที่ 1
2. ลองใส่ `+acc` ออก แล้วใช้ `examine` ดูค่าข้างในเซลล์ → จะดูไม่ได้
3. รันด้วย `run.do` ในหน้าต่าง GUI แล้วเปิด waveform ดูสัญญาณ `q`

---


---

## LAB 05 — เทียบ RTL กับ gate level ด้วย testbench ชุดเดียวกัน

### เป้าหมาย

นี่คือ **หัวใจของคู่มือนี้**
lab ที่ผ่านมาทั้งหมดเป็นการเตรียมความพร้อม ส่วน lab นี้คือการเอาทุกอย่างมารวมกัน

เป้าหมายคือ **จำลอง `cnt4` แบบเดียวกันเป็นสองระดับ**
แล้วพิสูจน์ว่า trace ที่ได้ออกมา **เหมือนกันทุกบรรทัด**

สิ่งที่ทำให้ lab นี้เป็นไปได้คือ **ไม่มีการแก้ testbench เลย**
มีแค่การเปลี่ยนว่า “คอมไพล์ไฟล์ไหนเข้าไลบรารี `work`”

| ระดับ | คำสั่ง `vlog` |
|---|---|
| RTL | `vlog -work work ../rtl/cnt4.v` + `vlog -work work ../tb/tb_cnt4.v` |
| Gate level | `vlog -work work ../cells/sg13g2_stdcell.v` + `vlog -work work ../netlist/cnt4_net.v` + `vlog -work work ../tb/tb_cnt4.v` |

### ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | หน้าที่ |
|---|---|
| `run_rtl.do` | สคริปต์ขั้นที่ 1 — จำลองระดับ RTL แล้วเขียน `results/trace_rtl.txt` |
| `run_gls.do` | สคริปต์ขั้นที่ 2 — จำลองระดับ gate แล้วเทียบ trace สองฝั่ง |
| `run.cmd` | ตัวรันที่สั่ง `vsim` สองครั้ง (สอง process) |

### ขั้นตอน

**ขั้นที่ 1 : รัน**

```bat
cd questa_gls_lab\lab05_rtl_vs_gate
run.cmd
```

**ขั้นที่ 2 : ดูผลลัพธ์จริง**

```text
=====================================================================
 LAB 05 : RTL against gate level, the same testbench
=====================================================================
[STEP 1] the RTL level run
=====================================================================
 LAB 05 : step 1 -- the RTL level run
=====================================================================
# === tb_cnt4 : RTL ===
#   t=16.000 ns : after reset          q = 0
#   t=26.000 ns : count up             q = 1
#   t=36.000 ns : count up             q = 2
#   t=46.000 ns : count up             q = 3
#   t=56.000 ns : count up             q = 4
#   t=66.000 ns : count up             q = 5
#   t=76.000 ns : count up             q = 6
#   t=106.000 ns : hold, en = 0          q = 6
#   t=136.000 ns : count up again       q = 9
#   checks = 9 , errors = 0
# TEST_PASSED : tb_cnt4 completed
[STEP 2] the gate level run
=====================================================================
 LAB 05 : step 2 -- the gate level run
=====================================================================
# === tb_cnt4 : GATE LEVEL ===
#   t=16.000 ns : after reset          q = 0
#   t=26.000 ns : count up             q = 1
#   t=36.000 ns : count up             q = 2
#   t=46.000 ns : count up             q = 3
#   t=56.000 ns : count up             q = 4
#   t=66.000 ns : count up             q = 5
#   t=76.000 ns : count up             q = 6
#   t=106.000 ns : hold, en = 0          q = 6
#   t=136.000 ns : count up again       q = 9
#   checks = 9 , errors = 0
# TEST_PASSED : tb_cnt4 completed
   the RTL verdict : PASS
   the GLS verdict : PASS
---- compare the two traces line by line ----
   the RTL trace has 10 lines
   OK : the two traces are IDENTICAL
RESULT: PASS
[RESULT] PASS
```

**ขั้นที่ 3 : ดู trace ทั้งสองฝั่งด้วยตา**

```bat
type results\trace_rtl.txt
type results\trace_gls.txt
```

ผลที่ได้จริง (ทั้งสองไฟล์เหมือนกันทุกตัวอักษร)

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

> เหตุผลที่สคริปต์บอกว่า “10 lines” แต่ไฟล์มี 9 บรรทัด
> เพราะสคริปต์นับด้วย `split [gls_read_file ...] "\n"`
> ซึ่งไฟล์ที่ลงท้ายด้วยขีดใหม่จะได้ element ว่างต่อท้ายมาอีก 1 ตัว
> (ถ้าอยากได้เลขบรรทัดจริง ให้นับด้วย `llength [split ...]` แล้วลบ 1)

### สิ่งที่ควรรู้จาก Lab นี้

**1. ⚠ ต้องเป็นคนละ process ต่อหนึ่งการจำลอง**

นี่คือข้อค้นพบที่สำคัญที่สุดของ lab นี้

ถ้าพยายามโหลด design ครั้งที่สองใน session เดียวกัน
(โหลด RTL จำลองเสร็จ แล้วโหลด netlist จำลองต่อ) **สคริปต์ `.do` จะหยุดเงียบ ๆ**
ไม่มี error ไม่มีข้อความอะไรเลย แต่ผลลัพธ์ก็ไม่ถูกเขียน

วิธีที่ถูกต้องคือใช้ `vsim` สองครั้ง แยก process กัน ดังที่ `run.cmd` ทำ

```bat
vsim -c -onfinish stop -do "do run_rtl.do"
vsim -c -onfinish stop -do "do run_gls.do"
```

เทมเพลตที่ใช้คือ `tools/run_template_2step.cmd`

> **ข้อสำคัญอีกข้อ**
> ต้องใส่ `-onfinish stop` เสมอ
> เพราะปกติ `vsim -c` จะจบ session ทันทีที่ testbench เรียก `$finish`
> คำสั่งที่เหลือใน `-do "..."` จะไม่ถูก execute เลย
> (เคยเจอกรณีนี้กับ `coverage save` ที่ไม่มี error แต่ไฟล์ไม่ถูกสร้าง)

**2. เทียบ trace ทีละบรรทัดด้วย `gls_diff_lines`**

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

คืนค่าเป็นรายการของบรรทัดที่ต่างกัน ถ้าได้รายการว่าง = เหมือนกันทุกบรรทัด
วิธีนี้ดีกว่าการเทียบด้วย `exec` ของ Windows เพราะไม่ต้องพึ่ง `fc.exe`
และรายงานได้ว่า “ต่างกันที่บรรทัดไหน” ไม่ใช่แค่ “ต่างกัน”

**3. trace คือสัญญาที่ตกลงกันระหว่าง DUT กับ testbench**

testbench เขียน trace ลงไฟล์ด้วย plusarg

```tcl
vsim -voptargs=+acc work.tb_cnt4 +GATE +tracefile=results/trace_gls.txt +resultfile=results/result_gls.txt
```

ดังนั้น **ระดับ RTL และระดับ gate ใช้ testbench ไฟล์เดียวกันเป๊ะ ๆ**
ต่างกันแค่ว่าไฟล์ที่ compile เข้า `work` คืออะไร
นี่คือหลักการที่ควรยึดใน flow จริง เพราะถ้าใช้ testbench คนละชุด
เราจะไม่รู้ว่าความต่างที่เห็นมาจาก DUT หรือมาจาก testbench

### แบบฝึกหัด

1. แก้ `netlist/cnt4_net.v` ให้ต่อ `D` ของ `q[1]` กับ `q[2]` สลับกัน
   แล้วรันซ้ำ → trace สองฝั่งจะต่างกันตรงไหน (เตรียมดูคำตอบใน LAB 07)
2. ลองแก้ `run_gls.do` ให้เปลี่ยน `+tracefile` เป็นชื่อเดียวกับของ RTL
   แล้วดูว่า trace เดิมถูกเขียนทับหรือไม่
3. เพิ่มบรรทัดตรวจใน `tb/tb_cnt4.v` ให้พิมพ์ค่า `q` ทุก 5 ns
   แล้วเทียบว่าจำนวนบรรทัดของ trace เปลี่ยนเป็นเท่าไร

---

## LAB 06 — ค่า `x` ที่ระดับ RTL กลืน แต่ระดับ gate เผยให้เห็น

### เป้าหมาย

พิสูจน์ข้อเท็จจริงข้อที่ 1 ของคู่มือนี้

> **การจำลองระดับ RTL “ทำให้” ค่าที่ไม่แน่นอนหายไป
> แต่การจำลองระดับ gate จะปล่อยให้ค่า `x` แพร่ผ่านเกตได้ตามจริง**

ในที่นี้เราจะให้ `en` (สัญญาณ enable) ของตัวนับกลายเป็น `'x'`
แล้วดูว่าแต่ละระดับตอบสนองอย่างไร

### ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | หน้าที่ |
|---|---|
| `tb/tb_cnt4_x.v` | testbench ที่ **ไม่ตัดสิน** — บันทึกเฉพาะสิ่งที่เห็น |
| `run_rtl.do` | จำลองระดับ RTL → `results/obs_rtl.txt` |
| `run_gls.do` | จำลองระดับ gate → `results/obs_gls.txt` แล้วเปรียบเทียบ |

> **ทำไม testbench ตัวนี้ถึง “ไม่ตัดสิน”**
> เพราะคำตอบที่ถูกคือ **ไม่เหมือนกัน** ระหว่างสองระดับ
> ตัว testbench จึงทำหน้าที่แค่ “สังเกต” แล้วเขียนลงไฟล์
> ส่วนสคริปต์ `run_gls.do` เป็นคนตัดสินว่าความต่างนั้นเกิดขึ้นจริงหรือไม่

### ขั้นตอน

**ขั้นที่ 1 : รัน**

```bat
cd questa_gls_lab\lab06_x_propagation
run.cmd
```

**ขั้นที่ 2 : ดูผลลัพธ์จริง**

```text
[STEP 1] the RTL level run
# === tb_cnt4_x : RTL ===
#   t=46.000 ns : before the 'x'      q = 3
#   t=66.000 ns : after  en = 'x'     q = 3
# === tb_cnt4_x finished ===
[STEP 2] the gate level run
# === tb_cnt4_x : GATE LEVEL ===
#   t=46.000 ns : before the 'x'      q = 3
#   t=66.000 ns : after  en = 'x'     q = x
# === tb_cnt4_x finished ===
   the RTL saw : observed=3
   the GLS saw : observed=x
---- the difference ----
   the RTL run produced an 'x' : 0   (expected : 0)
   the GLS run produced an 'x' : 1   (expected : 1)
   OK : the gate level simulation sees what the RTL hides
RESULT: PASS
[RESULT] PASS
```

**ขั้นที่ 3 : ดูไฟล์ที่บันทึกการสังเกต**

```bat
type results\obs_rtl.txt
type results\obs_gls.txt
```

ผลจริง

```text
observed=3
observed=x
```

### ทำไมผลจึงต่างกัน

**ระดับ RTL** — โค้ดคือ

```verilog
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)      q <= 4'd0;
    else if (en)     q <= q + 4'd1;
end
```

เมื่อ `en = 'x'` เงื่อนไข `if (en)` จะประเมินเป็น **ไม่จริง** (เพราะ `'x'` ไม่ใช่ `1`)
เงื่อนไขจึงไปทาง `else` → ไม่มีการ assign → **register คงค่าเดิม = 3**

**ระดับ gate** — สัญญาณ `en` ต้องผ่านเกตจริงของวงจรก่อนถึงขา `D` ของ flip-flop
เกตเหล่านั้นมีพฤติกรรมตามตารางความจริงของตรรกะ เช่น `xor` ที่มีอินพุต `'x'`
จะให้ผลลัพธ์เป็น `'x'` → ขา `D` กลายเป็น `'x'` → **flip-flop จับ `'x'` ไปไว้**

ภาพรวมคือ

| | ตัวนับที่ RTL เขียน | ตัวนับที่สังเคราะห์ได้ |
|---|---|---|
| เงื่อนไข | `if (en)` | `en` ผ่าน `xor` / `and` / ... |
| `en = 'x'` | เงื่อนไขเป็น false → คงค่า | `'x'` แพร่ผ่าน → ขา `D` เป็น `'x'` |
| ผลลัพธ์ | `q = 3` | `q = x` |

### สิ่งที่ควรรู้จาก Lab นี้

**1. `x` คือ “ไม่รู้” ไม่ใช่ “ศูนย์”**

ใน Verilog ค่า 4 สถานะคือ `0`, `1`, `x` (ไม่รู้), `z` (อิมพีแดนซ์)
เมื่อ `en` เป็น `'x'` เราไม่รู้ว่าตัวนับควรนับหรือไม่นับ

* RTL กลืนความไม่รู้นี้ทิ้ง (เลือกทางที่ “ปลอดภัย” คือไม่ทำอะไร)
* gate level เผยให้เห็นว่าวงจรจริง **ไม่ได้ตัดสินใจให้เรา**

นี่คือเหตุผลที่ใน flow จริง หลัง GLS ต้องมีการตรวจเงื่อนไข `x` เพิ่มเติม
(scan, ATPG หรือ X-propagation analysis) ไม่ใช่แค่ผ่าน PASS/FAIL

**2. อย่าใช้ `!=` หรือ `==` ตรวจค่าที่อาจเป็น `x`**

```verilog
if (got !== exp) begin     // <<< ถูกต้อง : เปรียบเทียบรวม x
    $display("** FAIL : expected %h but got %h", exp, got);
end
```

`!==` (case inequality) จะให้ผลเป็น `1` เมื่อค่าหนึ่งเป็น `x`
ทำให้บั๊กที่มีค่า `x` ไม่หลุดลอดออกไปเงียบ ๆ

**3. การเขียนค่าที่เห็นเป็น `%h` จะแสดง `x` ได้**

```verilog
$fdisplay(fh, "observed=%h", q);
```

ผลจริงที่วัดได้คือ `observed=x` — ค่า `x` ไม่ถูกแปลงเป็น `0` ให้โดยอัตโนมัติ
(ถ้าใช้ `%d` จะได้ `x` เช่นกัน แต่ `%d` ของค่าที่มีบางบิตเป็น `x` จะเติม `x` ทั้งตัว)

### แบบฝึกหัด

1. แก้ `tb/tb_cnt4_x.v` ให้เปลี่ยน `en` เป็น `'z` แทน `'x` แล้วรันซ้ำ
   → ผลจะเป็นอย่างไร และต่างจาก `'x` หรือไม่
2. หาสัญญาณภายในของ netlist ที่คำนวณตรรกะของ `en`
   ด้วย `examine -radix hex -value /tb_cnt4_x/dut/_00_`
   แล้วดูว่าค่าเป็น `x` หรือไม่
   → ลองคิดว่าทำไม RTL จึงไม่มีสัญญาณลักษณะนี้
3. ลองใช้ `!==` เทียบกับ `!=` ใน testbench ของ LAB 07
   แล้วดูว่าตัวตรวจจะรายงานผิดอย่างไร

---

## LAB 07 — จับบั๊กใน netlist ที่ RTL มองไม่เห็น

### เป้าหมาย

พิสูจน์ข้อเท็จจริงข้อที่ 2 ของคู่มือนี้

> **บั๊กที่เกิดจากการสังเคราะห์หรือการแก้ netlist
> จะไม่มีทางปรากฏในการจำลองระดับ RTL เด็ดขาด**

เราจะสร้าง netlist ที่ **เสียหาย** ขึ้นมาโดยเฉพาะ
แล้วให้ testbench ตัวเดียวกับของ LAB 05 ทำงานทั้งสองระดับ

### ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | หน้าที่ |
|---|---|
| `netlist/cnt4_bug_net.v` | netlist ที่ **ใส่บั๊กไว้** |
| `netlist/cnt4_net.v` | netlist ปกติ (เปรียบเทียบ) |
| `tb/tb_cnt4.v` | testbench เดิม ไม่แตะแม้แต่บรรทัดเดียว |
| `rtl/cnt4.v` | RTL ต้นฉบับ ไม่แตะแม้แต่บรรทัดเดียว |

### บั๊กที่ใส่ไว้คืออะไร

สลับการต่อขา `D` ของ flip-flop สองตัว คือ `q[1]` กับ `q[2]`

```verilog
// netlist/cnt4_net.v  (ปกติ)
sg13g2_dfrbpq_1 _16_ (
    .CLK(clk),
    .D(_02_),
    .Q(q[1]),
    .RESET_B(rst_n)
);

// netlist/cnt4_bug_net.v  (มีบั๊ก : สลับกับ q[2])
sg13g2_dfrbpq_1 _16_ (
    .CLK(clk),
    .D(_03_),        // <<< ควรเป็น _02_
    .Q(q[1]),
    .RESET_B(rst_n)
);
```

โค้ด RTL ยังเป็น `q <= q + 1` เหมือนเดิม
ดังนั้น **การจำลองระดับ RTL จะผ่าน** แต่ **การจำลองระดับ gate จะพัง**

### ขั้นตอน

**ขั้นที่ 1 : รัน**

```bat
cd questa_gls_lab\lab07_netlist_bug
run.cmd
```

**ขั้นที่ 2 : ดูผลลัพธ์จริง**

```text
[STEP 1] the RTL level run
# === tb_cnt4 : RTL ===
#   t=16.000 ns : after reset          q = 0
#   t=26.000 ns : count up             q = 1
#   t=36.000 ns : count up             q = 2
#   t=46.000 ns : count up             q = 3
#   t=56.000 ns : count up             q = 4
#   t=66.000 ns : count up             q = 5
#   t=76.000 ns : count up             q = 6
#   t=106.000 ns : hold, en = 0          q = 6
#   t=136.000 ns : count up again       q = 9
#   checks = 9 , errors = 0
# TEST_PASSED : tb_cnt4 completed
[STEP 2] the gate level run
# === tb_cnt4 : GATE LEVEL ===
#   t=16.000 ns : after reset          q = 0
#   t=26.000 ns : count up             q = 1
# ** FAIL count up : expected 2 but got 4
#   t=36.000 ns : count up             q = 4
#   t=46.000 ns : count up             q = 3
# ** FAIL count up : expected 4 but got 2
#   t=56.000 ns : count up             q = 2
#   t=66.000 ns : count up             q = 5
#   t=76.000 ns : count up             q = 6
#   t=106.000 ns : hold, en = 0          q = 6
#   t=136.000 ns : count up again       q = 9
#   checks = 9 , errors = 2
# TEST_FAILED : 2 error(s)
   the RTL verdict : PASS   (expected : PASS)
   the GLS verdict : FAIL   (expected : FAIL)
---- the two traces next to each other ----
   line 3 : RTL 'q=2'   vs   GLS 'q=4'
   line 5 : RTL 'q=4'   vs   GLS 'q=2'
RESULT: PASS
  -> the RTL simulation cannot see the defect, the gate level simulation can
[RESULT] PASS
```

**ขั้นที่ 3 : ดู trace ทั้งสองฝั่ง**

```bat
type results\trace_rtl.txt
type results\trace_bug.txt
```

ผลจริง

```text
RTL  : q=0  q=1  q=2  q=3  q=4  q=5  q=6  q=6  q=9
บั๊ก : q=0  q=1  q=4  q=3  q=2  q=5  q=6  q=6  q=9
```

สังเกตว่าหลังจากเกิดบั๊ก **บิตที่ 1 และบิตที่ 2 สลับกันไปตลอด**
(`q=2` กลายเป็น `q=4`, `q=4` กลายเป็น `q=2`) เพราะเป็นการสลับสาย
ไม่ใช่การนับผิดแบบสุ่ม

### ⚠ อ่านให้เข้าใจ: ทำไม lab นี้ถึง “ผ่าน” (RESULT: PASS)

สังเกตว่า lab นี้พิมพ์ `** FAIL` และ `TEST_FAILED` แต่สรุปกลับเป็น `RESULT: PASS`

เหตุผลคือ **เกณฑ์ของ lab คือ “ต้องพบความต่าง”** ไม่ใช่ “ต้องผ่านทั้งสองระดับ”

```tcl
if {$v_rtl eq "PASS" && $v_bug eq "FAIL"} {
    gls_write_verdict result.txt "PASS"
    puts "RESULT: PASS"
    puts "  -> the RTL simulation cannot see the defect, the gate level simulation can"
    quit -code 0
}
```

ถ้าเคยทำ lab แบบนี้แล้วเห็น `RESULT: FAIL` แปลว่า **บั๊กหายไป**
(เช่น แก้ netlist ผิดไฟล์) ไม่ใช่ว่าแบบฝึกหัดทำผิด

### สิ่งที่ควรรู้จาก Lab นี้

**1. นี่คือเหตุผลที่ GLS มีอยู่จริง**

| บั๊ก | ใครจับได้ |
|---|---|
| บั๊กเชิงตรรกะในโค้ด RTL | RTL simulation จับได้ (LAB 01 ยืนยันว่า RTL จับบั๊กนี้ได้) |
| บั๊กจากการสังเคราะห์ (เช่น enable ของ latch หายไป) | **เฉพาะ gate level เท่านั้น** |
| บั๊กจากการแก้ netlist / ECO ผิด | **เฉพาะ gate level เท่านั้น** |
| ค่า `x` ที่กลืนหายใน RTL | **เฉพาะ gate level เท่านั้น** (LAB 06) |

**2. GLS ไม่ได้แทน RTL simulation — มันเสริมกัน**

flow ที่เหมาะสมคือ

```text
RTL simulation   ->  จับบั๊กเชิงตรรกะเร็ว ๆ (วินาที)
        +
Gate level sim   ->  จับบั๊กของโครงสร้างวงจร (นาที)
        +
STA / LVS / DRC  ->  จับปัญหาที่การจำลองไม่เห็นเลย (เวลา)
```

**3. บั๊กที่จับได้อาจเล็กมาก แต่ผลกระทบใหญ่**

การสลับบิตที่ 1 กับบิตที่ 2 ของตัวนับ 4 บิต เป็นบั๊ก 1 บรรทัด
แต่ถ้าเป็นบิตของตัวนับ address หรือบิตของ data bus
ผลกระทบอาจไปถึงระดับทั้งชิป

### แบบฝึกหัด

1. แก้ `netlist/cnt4_bug_net.v` ให้สลับ `D` ของ `q[0]` กับ `q[3]` แทน
   แล้วรันซ้ำ → ดูว่า trace เปลี่ยนอย่างไร และจำนวน error เท่าไร
2. สร้าง `netlist/cnt4_bug2_net.v` ที่ตัด `RESET_B` ของ flip-flop ตัวหนึ่งออก
   (ต่อเป็น `1'b1` แทน) แล้วรัน → reset จะมีผลอย่างไร
3. ลองใส่ latch ใน netlist โดยแก้ `always @(posedge clk)` เป็น `always @*`
   ใน `rtl/cnt4.v` แล้วสังเคราะห์ใหม่ → จะเจอ latch ในระดับ gate ไหม

---

## LAB 08 — เทียบหลายดีไซน์ และรวมเป็น regression

### เป้าหมาย

จนถึง LAB 07 เราทำได้แค่ดีไซน์เดียว
lab นี้จะทำให้ flow เหมือนงานจริง

1. ทำให้ **สคริปต์เดียวกันใช้กับดีไซน์หลายตัว** ได้
   (เลือกดีไซน์ด้วย plusarg `+TOP=`)
2. รัน **ทั้งชุด 8 lab** แล้วสรุปเป็นรหัสจบเดียว
   (เอาไปต่อกับ CI ได้ทันที)

### ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | หน้าที่ |
|---|---|
| `lab08_gls_regression/run_rtl.do` | จำลองระดับ RTL ของดีไซน์ที่เลือกด้วย `+TOP=` |
| `lab08_gls_regression/run_gls.do` | จำลองระดับ gate ของดีไซน์เดียวกัน แล้วเทียบ trace |
| `lab08_gls_regression/run.cmd` | วนทั้ง 3 ดีไซน์ (`alu4`, `fsm_light`, `sr16`) |
| `lab08_gls_regression/regression.cmd` | วนทั้ง 8 lab แล้วสรุป |
| `tb/tb_alu4.v`, `tb/tb_fsm_light.v`, `tb/tb_sr16.v` | testbench ของแต่ละดีไซน์ |

### ขั้นตอนที่ 1 : เลือกดีไซน์ด้วย plusarg

สคริปต์อ่านชื่อดีไซน์จาก `+TOP=` แล้วเดา testbench ว่า `tb_<TOP>`

```tcl
set top "cnt4"
foreach a [split $::argv " "] {
    if {[regexp {^\+TOP=(.*)$} $a -> v]} { set top $v }
}
set tb "tb_$top"

if {![file exists "../netlist/${top}_net.v"]} {
    puts "!! wrong folder or no netlist for $top : [pwd]"
    quit -code 2
}
```

จึงรันดีไซน์เดียวได้ด้วย

```bat
cd questa_gls_lab\lab08_gls_regression
vsim -c -onfinish stop +TOP=alu4 -do "do run_rtl.do"
vsim -c -onfinish stop +TOP=alu4 -do "do run_gls.do"
```

### ขั้นตอนที่ 2 : รันทั้ง 3 ดีไซน์

```bat
cd questa_gls_lab\lab08_gls_regression
run.cmd
```

ผลลัพธ์จริง

```text
[DESIGN] alu4
  ---- the RTL level run ----
   the RTL verdict : PASS
  ---- the gate level run ----
   the RTL verdict : PASS
   the GLS verdict : PASS
   7 trace lines , 0 difference(s)
RESULT: PASS
  [PASS] alu4
[DESIGN] fsm_light
  ---- the RTL level run ----
   the RTL verdict : PASS
  ---- the gate level run ----
   the RTL verdict : PASS
   the GLS verdict : PASS
   6 trace lines , 0 difference(s)
RESULT: PASS
  [PASS] fsm_light
[DESIGN] sr16
  ---- the RTL level run ----
   the RTL verdict : PASS
  ---- the gate level run ----
   the RTL verdict : PASS
   the GLS verdict : PASS
   6 trace lines , 0 difference(s)
RESULT: PASS
  [PASS] sr16

=====================================================================
 total = 3   passed = 3   failed = 0
=====================================================================
[RESULT] PASS
```

### ขั้นตอนที่ 3 : ดู trace ที่เทียบกันแล้ว

**`alu4`** — ALU 4 บิต ทดสอบทั้ง 5 คำสั่ง

```text
op=0 a=7 b=5 y=c zero=0
op=1 a=7 b=5 y=2 zero=0
op=2 a=c b=a y=8 zero=0
op=3 a=c b=a y=e zero=0
op=4 a=c b=a y=6 zero=0
op=0 a=f b=1 y=0 zero=1
```

**`fsm_light`** — FSM ไฟสัญญาณจราจร 3 สถานะ

```text
state=0 red=1 green=0 yellow=0
state=1 red=0 green=1 yellow=0
state=2 red=0 green=0 yellow=1
state=0 red=1 green=0 yellow=0
state=1 red=0 green=1 yellow=0
```

**`sr16`** — shift register 16 บิต

```text
qout=0000
qout=a5c3
qout=4b86
qout=25c3
qout=25c3
```

ทั้งสามดีไซน์ **trace ของ RTL กับ gate level ตรงกันทุกบรรทัด**
(ข้อความในตารางข้างต้นคือฝั่ง RTL — ฝั่ง gate level เหมือนกันทุกตัวอักษร)

### ขั้นตอนที่ 4 : รัน regression ทั้งชุด

```bat
cd questa_gls_lab\lab08_gls_regression
regression.cmd
```

ผลลัพธ์จริง

```text
=====================================================================
 LAB 08 : GLS regression -- running every gate level lab
 root    : C:\Users\000148\Documents\MiniMax\eda-tools\questa_gls_lab\lab08_gls_regression\..
=====================================================================
[PASS] lab01_rtl_baseline
[PASS] lab02_synth_netlist
[PASS] lab03_cell_library
[PASS] lab04_gls_first
[PASS] lab05_rtl_vs_gate
[PASS] lab06_x_propagation
[PASS] lab07_netlist_bug
[PASS] lab08_multi_design

=====================================================================
 REGRESSION SUMMARY
 total = 8   passed = 8   failed = 0
 summary file : ...\lab08_gls_regression\results\regression_summary.txt
=====================================================================
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

รหัสจบของ `regression.cmd`

| รหัส | ความหมาย |
|---|---|
| `0` | ผ่านทั้งหมด (ALL GREEN) |
| `1` | มี lab อย่างน้อย 1 ตัวไม่ผ่าน |

### สิ่งที่ควรรู้จาก Lab นี้

**1. `<` redirection ใช้ไม่ได้ใน `for` block ของ `.cmd`**

```bat
for %%D in (alu4 fsm_light sr16) do (
    ...
    set /p R=<results\%%D_verdict.txt>     rem <<< ผิด ! ล้มเหลวแบบเงียบ
)
```

ต้องใช้ `for /f` แทน

```bat
set "R="
for /f "usebackq delims=" %%V in ("results\%%D_verdict.txt") do set "R=%%V"
```

> เหตุผล: ใน `for` block ของ `cmd.exe` ตัวอักษร `<` จะถูกตีความว่าเป็น
> redirection ซึ่งทำให้ทั้ง block พัง โดยไม่มีข้อความแจ้งเตือนที่ชัดเจน
> (เป็นกับดักที่วัดได้จริงบนเครื่องนี้)

**2. `for /f` กับ `usebackq delims=`**

`delims=` ว่าง = ไม่ตัดอักขระใด ๆ (เก็บทั้งบรรทัด)
`usebackq` = ให้ใช้เครื่องหมายคำพูดแบบ backquote เป็นตัวคั่น path

**3. regression คือหัวใจของการทำ GLS ให้เป็นประจำ**

จุดที่ต้องระวังคือ **ใบอนุญาตแบบ session เดียว**
การรันทีละ process ตามลำดับ (ไม่ขนาน) จึงเป็นวิธีที่ปลอดภัยที่สุด
ตัวอย่างในคู่มือนี้จึงรันทีละตัว ไม่ใช้ `start /parallel`

**4. เกณฑ์ PASS ของแต่ละดีไซน์เป็น 3 ข้อพร้อมกัน**

```tcl
if {$v_rtl eq "PASS" && $v_gls eq "PASS" && [llength $diff] == 0} {
    gls_write_verdict result.txt "PASS"
    ...
}
```

1. ระดับ RTL ผ่าน
2. ระดับ gate ผ่าน
3. trace ทั้งสองฝั่งตรงกัน **ทุกบรรทัด**

ข้อ 3 สำคัญที่สุด เพราะเคยมีกรณีที่ทั้งสองระดับผ่าน
แต่ trace ต่างกัน (เกิดจากการที่ testbench ไม่ได้ตรวจทุกจุด)
การเทียบ trace จึงเป็นตาข่ายนิรภัยชั้นที่สอง

**5. ขนาดวงจรจริงของทั้งสี่ดีไซน์ (จาก LAB 02)**

| ดีไซน์ | จำนวนเซลล์ | จำนวนชนิดเซลล์ | flip-flop |
|---|---|---|---|
| `cnt4` | 11 | 7 | 4 |
| `fsm_light` | 11 | 4 | 5 |
| `alu4` | 64 | 19 | 4 |
| `sr16` | 102 | 14 | 16 |

ให้สังเกตอัตราส่วน **จำนวนเซลล์ต่อ flip-flop**
`cnt4` ได้ 11/4 ≈ 2.8 เซลล์ต่อบิต แต่ `sr16` ได้ 102/16 ≈ 6.4
เพราะ `sr16` มี **มัลติเพลเซอร์** ต่อบิต นี่คือเหตุผลที่ GLS ของวงจรใหญ่
จึงช้ากว่า RTL simulation มาก และเป็นเหตุผลที่ต้องมี **SDF / timing-driven simulation**
ในขั้นถัดไป

### แบบฝึกหัด

1. เพิ่มดีไซน์ใหม่ลงใน `lab08_gls_regression/run.cmd`
   (เช่นแก้ `rtl/cnt4.v` ให้เป็นตัวนับ 8 บิต สังเคราะห์ใหม่ แล้วเพิ่ม `cnt8`)
   → ต้องทำอะไรบ้างให้ flow รันได้
2. ลองทำให้ `regression.cmd` รันผิดโดยตั้งใจแก้ `netlist/cnt4_net.v`
   แล้วดูว่า `regression_summary.txt` หน้าตาเป็นอย่างไรเมื่อมี lab ไม่ผ่าน
3. เพิ่มการนับ **เวลาที่ใช้** ของแต่ละ lab ใน regression
   แล้วเปรียบเทียบเวลาระหว่างระดับ RTL กับระดับ gate

---


---

## ภาคผนวก ก — กับดักที่พบจริง (Pitfalls)

กับดักทั้งหมดในภาคผนวกนี้ **วัดได้จริงบนเครื่องนี้**
ไม่ใช่ข้อควรระวังที่ได้ยินมา แต่เป็นสิ่งที่เจอจริงระหว่างทำคู่มือฉบับนี้

### ก.1 เซลล์กับ netlist ต้องอยู่ไลบรารีเดียวกัน

อาการคือ

```text
** Error: (vsim-3033) Instantiation of 'sg13g2_xor2_1' failed. The design unit was not found.
   Time: 0 ns  Iteration: 0  Instance: /tb_cnt4/dut File: ../netlist/cnt4_net.v Line: 19
        Searched libraries:
            C:/.../lab04_gls_first/work
Error loading design
```

จำนวนข้อความ `vsim-3033` ที่พิมพ์ออกมา **เท่ากับจำนวน instance ของเซลล์ใน netlist พอดี**
(สำหรับ `cnt4` คือ 11 บรรทัด และตัว simulator รายงาน `Errors: 11, Warnings: 0`)

ข้อความ `Searched libraries:` บอกว่า **ตัวจำลองค้นหาเซลล์ที่ไหนบ้าง**
ให้ดูเส้นทางนั้น — ถ้า path ของไลบรารีที่ค้นหาไม่ใช่ที่ที่คุณคอมไพล์เซลล์ไว้
นั่นคือสาเหตุ

แก้โดยคอมไพล์ทั้งสองอย่างเข้าไลบรารีเดียวกัน

```tcl
vlog -work work ../cells/sg13g2_stdcell.v
vlog -work work ../netlist/cnt4_net.v
```

### ก.2 โหลด design ครั้งที่สองใน session เดียว → สคริปต์หยุดเงียบ

ถ้า `vsim -c -do "..."` สั่งให้โหลด design หนึ่ง จำลองจน `$finish`
แล้วโหลด design ที่สองต่อใน session เดียวกัน
**สคริปต์ `.do` จะหยุดตรงนั้นโดยไม่มี error และไม่มีข้อความใด ๆ**
ผลลัพธ์ที่ควรถูกเขียนก็ไม่ถูกเขียน

วิธีแก้คือ **แยกเป็นคนละ process ต่อหนึ่งการจำลอง**

```bat
vsim -c -onfinish stop -do "do run_rtl.do"
vsim -c -onfinish stop -do "do run_gls.do"
```

### ก.3 `$finish` ตัดคำสั่งที่เหลือใน `-do` ทิ้ง

โดยปกติ `vsim -c` จบ session ทันทีที่ testbench เรียก `$finish`
คำสั่งที่เหลือใน `-do "..."` **ไม่ถูก execute เลย**
(เคยเจอกับ `coverage save` ที่ไม่มี error แต่ไฟล์ไม่ถูกสร้าง)

แก้โดยใส่ `-onfinish stop`

```bat
vsim -c -onfinish stop -do "do run_batch.do"
```

### ก.4 `vsim` คืน exit code `0` เสมอ

แม้จะเปิดไฟล์ `.do` ไม่ได้เลย `vsim` ก็ยังคืน `0`
**ห้ามใช้ exit code ของ `vsim` เป็นเกณฑ์ PASS/FAIL**

ทางเลือกที่ใช้ได้คือให้ testbench เขียนไฟล์ผลลัพธ์เอง แล้วให้ `.cmd` อ่านไฟล์นั้น

```bat
if not exist "result.txt" (
    echo [RESULT] FAIL -- the simulator did not finish
    exit /b 1
)
set /p RESULT=<result.txt
if /i "%RESULT%"=="PASS" ( exit /b 0 )
exit /b 1
```

### ก.5 `<` redirection ใช้ไม่ได้ใน `for` block ของ `.cmd`

```bat
for %%D in (alu4 fsm_light sr16) do (
    set /p R=<results\%%D_verdict.txt>      rem <<< ทำให้ทั้ง block พังแบบเงียบ
)
```

ต้องใช้ `for /f` แทน

```bat
set "R="
for /f "usebackq delims=" %%V in ("results\%%D_verdict.txt") do set "R=%%V"
```

### ก.6 `[info script]` ทำให้ตัวจำลอง crash

ใน ModelSim 2026.1 คำสั่ง `[info script]` คืนค่าเป็น **พาธของตัว `vsim` เอง**
ไม่ใช่พาธของสคริปต์ และเมื่อนำไปใช้กับ `file join` แล้วเปิดไฟล์
ตัวจำลองจะ **ล้มแล้วปิดตัวทันที**

แก้โดยคำนวณพาธจาก `[pwd]` แทน

```tcl
proc gls_root {} {
    return [file normalize [file join [pwd] ..]]
}
```

### ก.7 `$value$plusargs("%s")` ตัดพาธที่ยาวเกิน 64 ตัวอักษร

ตัวแปรที่รับค่าจาก plusarg ต้องประกาศให้ยาวพอ

```verilog
reg [8*64:1] tracefile = "trace.txt";
```

`8*64` = 512 บิต = **64 ตัวอักษร** ถ้าพาธยาวเกินนั้นจะถูกตัดทิ้ง
(ซึ่งทำให้ `$fopen` ล้มเหลวแบบเงียบ ๆ)

ทางแก้คือใช้พาธแบบสัมพัทธ์สั้น ๆ เสมอ เช่น `results/trace_rtl.txt`
ไม่ใช้พาธเต็มยาว ๆ

### ก.8 `void'` เป็น SystemVerilog — `vlog` ธรรมดาใช้ไม่ได้

`vlog` (Verilog) รับเฉพาะ Verilog-2001
ถ้าเขียน `void'(expr)` หรือ `bit`/`logic`/`always_ff` จะคอมไพล์ไม่ผ่าน
ต้องใช้ `vlog -sv` ซึ่งในโปรเจกต์นี้ **ไม่ได้ใช้** เพื่อให้ flow ตรงกับ netlist ที่ Yosys สร้าง

### ก.9 `[` ใน string ที่ครอบด้วย `"` ใน Tcl จะเริ่ม command substitution

```tcl
puts "   the trace has [llength $a] lines"      # <<< OK : [] ใน string ปกติ
```

แต่ถ้า string ถูกครอบด้วย `"` **ภายใน** `{}` หรืออยู่ในนิพจน์ที่ Tcl parse ใหม่
`[` จะถูกตีความว่าเป็นการเรียก sub-command

วิธีหลีกเลี่ยงคือ escape ด้วย backslash หรือใช้ `{ }` ครอบ

```tcl
puts {   the trace has [llength $a] lines}
```

### ก.10 `timescale` ของ testbench ต้องตรงกับของเซลล์

เซลล์ SG13G2 ประกาศ `` `timescale 1ns/10ps ``
ถ้า testbench ประกาศ `1ns/1ns` ความละเอียดเวลาจะไม่ตรงกัน
และ `$realtime` จะให้ค่าที่ดูแปลก

ในโปรเจกต์นี้ testbench ทุกไฟล์ประกาศ `` `timescale 1ns/10ps `` เหมือนกันหมด

### ก.11 `$time` ให้หน่วยเวลาไม่ใช่หน่วยเวลาของโมดูล

`$time` คืนจำนวนเต็มในหน่วย **ความละเอียดเวลาของตัวจำลอง** (ค่า default คือ 10 ps)
`$realtime` คืนค่าเป็น `real` ในหน่วยเวลาของโมดูล

| | `t=16 ns` จะพิมพ์เป็น |
|---|---|
| `$time` | `1600` |
| `$realtime` | `16.000` |

### ก.12 ตัวตรวจต้องใช้ `!==` ไม่ใช่ `!=`

```verilog
if (got !== exp) begin ... end
```

`!=` จะให้ผลเป็น `false` เมื่อค่าใดค่าหนึ่งเป็น `x`
ทำให้บั๊กที่มีค่า `x` **หลุดลอดออกไปโดยไม่มีใครรู้ตัว**
(ดูหลักฐานจริงใน LAB 06 และ LAB 07)

### ก.13 ห้าม hardcode path ของชุดติดตั้ง

ใบอนุญาตเป็น **node-locked แบบ session เดียว**
ถ้ามี QuestaSim GUI เปิดค้างอยู่ การรันแบบบรรทัดคำสั่งด้วยชุดนั้นจะถูกปฏิเสธ

คู่มือนี้จึงให้ใช้ `tools/pick_tool.cmd` ที่ไล่ทดสอบ license จริงของแต่ละชุด
แล้วเลือกชุดแรกที่ใช้ได้

### ก.14 ไฟล์ `.cmd` ต้องเป็น ASCII ล้วน

ถ้ามีข้อความภาษาไทยหรือ UTF-8 ในไฟล์ `.cmd` `cmd.exe` จะอ่านโครงสร้างบรรทัดผิด
อาการที่เห็นบ่อยคือ **บรรทัดคอมเมนต์กินอักขระแรกของบรรทัดถัดไปไป**
(`echo` กลายเป็น `cho`)

ในโปรเจกต์นี้ไฟล์ `.cmd` ทั้งหมดเป็น ASCII ล้วน ๆ
ส่วนคำอธิบายภาษาไทยอยู่ในไฟล์ `.md` และคอมเมนต์ใน `.do` ซึ่งไม่มีข้อจำกัดนี้

### ก.15 ABC ข้ามเซลล์ sequential และเซลล์ที่อยู่ใน `dont_use`

`abc` ทำงานเฉพาะ logic combinational
log จะขึ้นว่า

```text
Scl_LibertyReadGenlib() skipped sequential cell "sg13g2_dfrbp_1"
```

และเซลล์ที่ตั้ง `dont_use` ใน Liberty (เช่น `antennanp`, `decap_4`, `decap_8`)
ก็จะไม่ถูกเลือกมาใช้

นี่คือเหตุผลที่ **`dfflibmap` ต้องมาก่อน `abc` เสมอ**

### ก.16 Yosys `fsm` เปลี่ยน FSM binary เป็น one-hot

Yosys 0.52 แปลง FSM แบบ binary เป็น one-hot โดยอัตโนมัติ
จึงทำให้ **จำนวน flip-flop ใน netlist มากกว่าที่คาดจาก RTL**

ตัวเลขจำนวน flip-flop ที่ได้จึง **ขึ้นกับ flow ที่ใช้**
ต้องระบุเสมอว่าได้จาก `synth` แบบไหน

ถ้าต้องการคุมรูปแบบเอง ให้ใช้ `fsm -norecode` หรือเขียน FSM เป็น one-hot ตั้งแต่ RTL

### ก.17 `dfflibmap` ไม่ได้ map latch — และ `write_verilog` จะเขียน flip-flop กลับเป็น `always`

นี่คือข้อค้นพบที่วัดได้จริงจากการทำแบบฝึกหัด

**1. ถ้าไม่มี `dfflibmap`**

สถิติจาก Yosys จะขึ้นว่า flip-flop เป็นเซลล์ภายใน

```text
   Number of cells:                 10
     $_DFFE_PN0P_                    4
     sg13g2_a21o_1                   1
     ...
```

แต่เมื่อเขียนไฟล์ Verilog ออกมา `write_verilog` จะ **แปลงกลับ**
flip-flop เหล่านั้นเป็น `always` block เชิงพฤติกรรม

```verilog
  always @(posedge clk, negedge rst_n)
    if (!rst_n) q[0] <= 1'h0;
    else if (en) q[0] <= _02_;
```

ผลคือ netlist ที่ได้ **ยังคอมไพล์และจำลองผ่าน** แต่ส่วน sequential
**ไม่ใช่ gate level เลย** และตรรกะ combinational ก็เปลี่ยนไปด้วย
เพราะ ABC optimize ได้ผลต่างออกไป

**2. `dfflibmap` ไม่ได้จัดการ latch**

แม้ชุดเซลล์ SG13G2 จะมีเซลล์ latch อยู่จริง (`sg13g2_dlhq_1`, `sg13g2_dlhr_1` เป็นต้น)
แต่ `dfflibmap` จัดการเฉพาะ flip-flop
ถ้า RTL เขียนด้วย `always @*` แล้วสังเคราะห์ จะได้

```text
   Number of cells:                 13
     $_DLATCH_N_                     4
     sg13g2_a21o_1                   1
     ...
```

และ netlist จะมี `always @*` เช่นกัน

```verilog
  always @*
    if (!_04_) q[0] = _00_;
```

**สรุป**

> ถ้าอยากให้ GLS ทดสอบอะไรจริง ๆ ต้องแน่ใจว่า **ทุกเซลล์ใน netlist
> เป็นเซลล์มาตรฐานของ PDK** ไม่ใช่เซลล์ภายในของ Yosys
> วิธีตรวจง่าย ๆ คือเปิดไฟล์ netlist แล้วดูว่า
> มี `always` block หลงเหลืออยู่หรือไม่
> ถ้ามี แปลว่ายังไม่ใช่ gate level จริง

### ก.18 ชื่อไฟล์ trace ที่ใช้ซ้ำกันทำให้การเทียบไร้ผล

วัดได้จริง: ถ้าให้ทั้งสองระดับเขียน trace ลงไฟล์เดียวกัน
การรัน GLS จะ **เขียนทับ** trace ของ RTL ทิ้ง

```text
ก่อนเขียนทับ (RTL) : 0, 1, 2, 3, 4, 5, 6, 6, 9
หลังเขียนทับ (GLS) : 0, 8, 9, 3, 4, c, d, d, 2
```

ถ้าสคริปต์เปรียบเทียบไฟล์กับตัวเอง จะได้ผลว่า **เหมือนกัน 0 จุด**
ทั้งที่วงจรต่างกันสิ้นเชิง — เป็นกับดักที่ทำให้ GLS ไม่จับบั๊กเลย

แก้โดยใช้ชื่อไฟล์ต่างกันเสมอ (`trace_rtl.txt` / `trace_gls.txt`)
ซึ่งเป็นสิ่งที่ LAB 05 ทำอยู่แล้ว

---

## ภาคผนวก ข — คำสั่งที่ใช้บ่อย

### คำสั่ง Tcl ของตัวจำลอง

```tcl
vlib work                       # สร้างไลบรารี
vmap work work                  # ผูกชื่อ work ให้โฟลเดอร์ work
vlog -work work file.v          # คอมไพล์ Verilog
vsim -voptargs=+acc work.tb     # โหลด design (+acc = เห็นค่าข้างใน hierarchy)
run -all                        # จำลองจนจบ
run 100ns                       # จำลอง 100 ns
quit -f                         # ออก (บังคับ)
do script.do                    # รันสคริปต์อื่น
examine -radix hex -value /tb/dut/q     # ดูค่าสัญญาณ
add wave /tb/dut/*              # เพิ่มสัญญาณเข้า waveform
run -all                        # จำลองต่อ
```

### คำสั่ง Verilog ใน testbench

```verilog
$realtime                        # เวลาปัจจุบันในหน่วยเวลาของโมดูล
$time                            # เวลาปัจจุบันในหน่วย 10 ps
$display("... %h ...", q)        # พิมพ์ hex
$fdisplay(fh, "...", q)          # พิมพ์ลงไฟล์
$fopen(name, "w")                # เปิดไฟล์เขียน
$fclose(fh)                      # ปิดไฟล์
$finish                          # จบการจำลอง
$test$plusargs("GATE")           # ตรวจว่ามี plusarg ชื่อ GATE ไหม
$value$plusargs("file=%s", name) # อ่านค่าจาก plusarg
got !== exp                      # เทียบโดยรวมค่า x
```

### คำสั่ง `.cmd` ที่ใช้บ่อย

```bat
call "%~dp0..\tools\pick_tool.cmd"    # เลือกชุดติดตั้งที่มี license
cd /d "%~dp0"                          # เปลี่ยนโฟลเดอร์ (สำคัญมากใน .cmd ที่ถูก call)
set "PATH=%MT%;%PATH%"                # เพิ่ม vsim.exe เข้า PATH
set /p RESULT=<result.txt             # อ่านบรรทัดแรกของไฟล์
if /i "%RESULT%"=="PASS" ( exit /b 0 )
for /f "usebackq delims=" %%V in ("f.txt") do set "R=%%V"
```

> **กฎเหล็กของ `.cmd`**
> ไฟล์ `.cmd` ที่ถูกเรียกด้วย `call` ต้อง `cd /d` กลับก่อนจบ
> ไม่เช่นนั้นผู้เรียนจะเจอโฟลเดอร์ที่ผิดเมื่อรันคำสั่งถัดไป

### คำสั่ง Yosys ที่ใช้ใน LAB 02

```tcl
read_verilog rtl/cnt4.v
hierarchy -check -top cnt4
proc; opt; fsm; opt; memory; opt
techmap; opt
dfflibmap -liberty <lib>       # ต้องมาก่อน abc
abc -liberty <lib>
setundef -zero
splitnets
opt_clean
write_verilog -noattr netlist/cnt4_net.v
stat
```

---

## ภาคผนวก ค — การวิเคราะห์และแก้ปัญหา

ตารางนี้เรียงตามอาการที่พบบ่อยที่สุด
ให้ค้นจาก **อาการ** ในคอลัมน์ซ้าย

### ค.1 ตัวจำลองปิดตัวทันทีทันทีที่ `source` สคริปต์

| | |
|---|---|
| **อาการ** | `vsim` ล้มทันทีโดยไม่มีข้อความ ไม่มี transcript |
| **สาเหตุ** | ใช้ `[info script]` เพื่อหาพาธของสคริปต์ — ใน 2026.1 ค่าที่ได้คือพาธของ `vsim` เอง |
| **แก้** | คำนวณพาธจาก `[pwd]` แทน (ดู ก.6) |

### ค.2 `vsim-3033) Instantiation of '...' failed. The design unit was not found`

| | |
|---|---|
| **อาการ** | ตัวจำลองหาโมดูลของเซลล์ไม่เจอ แล้วจบด้วย `Error loading design` |
| **สาเหตุ** | เซลล์ถูกคอมไพล์ไว้คนละไลบรารีกับ netlist |
| **แก้** | คอมไพล์ทั้งสองอย่างเข้า `work` ไลบรารีเดียวกัน (ดู ก.1) |

### ค.3 `Error loading design` แต่ exit code เป็น `0`

| | |
|---|---|
| **อาการ** | มีข้อความ error แต่สคริปต์ `.cmd` ยังบอกว่าผ่าน |
| **สาเหตุ** | `vsim` คืน exit code `0` เสมอ (ดู ก.4) |
| **แก้** | ให้ testbench เขียนไฟล์ `result.txt` แล้วให้ `.cmd` อ่านไฟล์นั้นเป็นเกณฑ์ |

### ค.4 `vsim` เปิดไฟล์ `.do` ไม่ได้ แต่ exit code เป็น `0`

| | |
|---|---|
| **อาการ** | ไม่มี output เลย แต่รหัสจบเป็น 0 |
| **สาเหตุ** | `vsim` คืน exit code `0` แม้จะเปิดไฟล์ไม่ได้ (ดู ก.4) |
| **แก้** | ตรวจว่ามีไฟล์ `result.txt` เกิดขึ้นจริงหรือไม่ แล้วค่อยตัดสิน |

### ค.5 สคริปต์ `.do` หยุดเงียบ ๆ โดยไม่มี error

| | |
|---|---|
| **อาการ** | รัน design ที่สองใน session เดียว แล้วสคริปต์ค้าง/จบโดยไม่ทำงานต่อ |
| **สาเหตุ** | session เดียวจำลองได้ครั้งเดียวเมื่อ testbench จบด้วย `$finish` (ดู ก.2) |
| **แก้** | แยกเป็นคนละ `vsim` process ต่อหนึ่งการจำลอง |

### ค.6 คำสั่งหลัง `$finish` ไม่ถูก execute

| | |
|---|---|
| **อาการ** | เช่น `coverage save` ไม่มี error แต่ไฟล์ไม่ถูกสร้าง |
| **สาเหตุ** | `vsim -c` จบ session ทันทีที่เจอ `$finish` (ดู ก.3) |
| **แก้** | ใส่ `-onfinish stop` |

### ค.7 `License checkout has been disallowed`

| | |
|---|---|
| **อาการ** | `vsim` ปฏิเสธการทำงาน พร้อมข้อความเรื่องใบอนุญาต |
| **สาเหตุ** | ใบอนุญาตแบบ session เดียว และมี QuestaSim GUI เปิดค้างอยู่ |
| **แก้** | ใช้ `tools/pick_tool.cmd` ที่ไล่หาเป็นแบบอัตโนมัติ (ดู ก.13) — อย่าปิด GUI ของผู้ใช้ |

### ค.8 `for` block ใน `.cmd` ทำงานผิด

| | |
|---|---|
| **อาการ** | ค่าที่อ่านมาเป็นค่าว่าง หรือทั้ง block หยุดโดยไม่มีข้อความ |
| **สาเหตุ** | ใช้ `<` redirection ใน `for` block (ดู ก.5) |
| **แก้** | ใช้ `for /f "usebackq delims=" %%V in ("file") do set "R=%%V"` |

### ค.9 ไฟล์ผลลัพธ์ไม่ถูกเขียน

| | |
|---|---|
| **อาการ** | `$fopen` คืนค่า 0 หรือไฟล์ถูกสร้างแต่ชื่อผิด |
| **สาเหตุ** | พาธยาวเกิน 64 ตัวอักษร ทำให้ `$value$plusargs("%s")` ตัดทิ้ง (ดู ก.7) |
| **แก้** | ใช้พาธสัมพัทธ์สั้น ๆ และขยาย `reg [8*64:1]` เป็น `reg [8*128:1]` ถ้าต้อง |

### ค.10 เวลาใน log ไม่ตรงกับที่คาด

| | |
|---|---|
| **อาการ** | เวลาที่พิมพ์เป็น `1600` แทน `16` |
| **สาเหตุ** | ใช้ `$time` ซึ่งมีหน่วยเป็นความละเอียดเวลาของตัวจำลอง (10 ps) |
| **แก้** | ใช้ `$realtime` (ดู ก.11) |

### ค.11 เวลาที่พิมพ์ผิดหน่วย

| | |
|---|---|
| **อาการ** | `t=1600` แทน `t=16.000` |
| **สาเหตุ** | `$time` ใช้หน่วย 10 ps ส่วน `$realtime` ใช้หน่วยเวลาของโมดูล |
| **แก้** | ใช้ `$realtime` และระบุ `` `timescale `` ให้ตรงกับเซลล์ |

### ค.12 บั๊กที่มีค่า `x` หลุดลอดไปโดยไม่มีใครรู้ตัว

| | |
|---|---|
| **อาการ** | จำนวน error เป็น 0 ทั้งที่วงจรควรจะพัง |
| **สาเหตุ** | ใช้ `!=` หรือ `==` ซึ่งไม่รวมค่า `x` |
| **แก้** | ใช้ `!==` (ดู ก.12) และอย่าลืมเปรียบเทียบ trace ทั้งไฟล์ (LAB 05) |

---

## ภาคผนวก ง — ข้อมูลอ้างอิงจากการวัดจริง

### ง.1 เครื่องมือและเวอร์ชัน

| เครื่องมือ | ค่าที่วัดได้ |
|---|---|
| ModelSim DE-64 | `vsim 2026.1 Simulator 2026.01 Jan 25 2026` |
| Questa Sim-64 | `vsim 2026.1 Simulator 2026.01 Jan 25 2026` |
| Yosys | `0.52 (git sha1 fee39a3284c90249e1d9684cf6944ffbbcbb8f90)` |
| IHP SG13G2 | Liberty corner `sg13g2_stdcell_typ_1p20V_25C` |

### ง.2 ไฟล์ที่ใช้จริงในคู่มือนี้ (ขนาดจริง)

| ไฟล์ | ขนาด | หน้าที่ |
|---|---|---|
| `cells/sg13g2_stdcell.v` | 56,308 bytes | โมเดลการจำลองของเซลล์ 84 ตัว |
| `cells/sg13g2_udp.v` | 13,561 bytes | user defined primitives ที่เซลล์อ้างถึง |
| `cells/sg13g2_stdcell_typ_1p20V_25C.lib` | 1,748,984 bytes | Liberty ของ corner typ |
| `rtl/cnt4.v` | 991 bytes | DUT ตัวนับ 4 บิต |
| `tb/tb_cnt4.v` | 4,337 bytes | testbench หลัก ของทั้ง LAB 01/04/05/07 |
| `tb/tb_cnt4_x.v` | 2,541 bytes | testbench ของ LAB 06 |
| `netlist/cnt4_net.v` | 1,237 bytes | netlist ปกติ |
| `netlist/alu4_net.v` | 6,469 bytes | netlistของ ALU |
| `netlist/sr16_net.v` | 10,749 bytes | netlist ของ shift register |

### ง.3 ชุดเซลล์ SG13G2 ที่วัดได้จริง (84 เซลล์)

| กลุ่ม | จำนวน | ตัวอย่าง |
|---|---|---|
| flip-flop (sequential) | 9 | `dfrbp_1`, `dfrbpq_1`, `sdfrbp_1`, `sdfrbpq_1`, `sdfbbp_1` |
| latch + latch clock | 7 | `dlhq_1`, `dlhr_1`, `dllrq_1`, `lgcp_1`, `slgcp_1` |
| delay cell | 3 | `dlygate4sd1_1`, `dlygate4sd2_1`, `dlygate4sd3_1` |
| utility / physical only | 10 | `antennanp`, `decap_4/8`, `fill_1/2/4/8`, `sighold`, `tiehi`, `tielo` |
| combinational gates | 55 | `and2`, `nand3`, `nor4`, `xor2`, `xnor2`, `mux2`, `mux4`, `a21o` |
| **รวม** | **84** | |

หน่วยที่ประกาศในไฟล์ Liberty

| หน่วย | ค่า |
|---|---|
| `time_unit` | `1ns` |
| `capacitive_load_unit` | `1pf` |
| `voltage_unit` | `1V` |
| `current_unit` | `1uA` |

### ง.4 ขนาดวงจรจริงของทั้งสี่ดีไซน์

| ดีไซน์ | จำนวนเซลล์ | จำนวนชนิดเซลล์ | flip-flop | เซลล์/flip-flop |
|---|---|---|---|---|
| `cnt4` | 11 | 7 | 4 | 2.8 |
| `fsm_light` | 11 | 4 | 5 | 2.2 |
| `alu4` | 64 | 19 | 4 | 16.0 |
| `sr16` | 102 | 14 | 16 | 6.4 |

รายการเซลล์ของ `cnt4` ทั้งหมด

```text
sg13g2_a21o_1                   1
sg13g2_and2_1                   1
sg13g2_dfrbpq_1                 4
sg13g2_nand3_1                  1
sg13g2_nand4_1                  1
sg13g2_xnor2_1                  2
sg13g2_xor2_1                   1
```

### ง.5 ผลรันจริงของทั้ง 8 lab

| Lab | หัวข้อ | เกณฑ์ | ผล |
|---|---|---|---|
| 01 | RTL baseline | checks = 9, errors = 0 | PASS |
| 02 | Yosys → netlist | 11 เซลล์, 7 ชนิด, 4 FF | PASS |
| 03 | ชุดเซลล์ SG13G2 | 84 โมดูล, 5 กลุ่มรวม 84 | PASS |
| 04 | GLS ครั้งแรก | 11 `vsim-3033` ในทางที่ผิด | PASS |
| 05 | RTL vs gate | trace 10 บรรทัด, 0 ต่าง | PASS |
| 06 | การแพร่ค่า `x` | RTL = 3, GLS = x | PASS |
| 07 | บั๊กใน netlist | RTL PASS, GLS FAIL | PASS |
| 08 | regression | 8/8 ผ่าน | ALL GREEN |

### ง.6 ตัวอย่างผลที่ได้จากแต่ละดีไซน์ (ฝั่ง gate level)

**`alu4`**

```text
op=0 a=7 b=5 y=c zero=0
op=1 a=7 b=5 y=2 zero=0
op=2 a=c b=a y=8 zero=0
op=3 a=c b=a y=e zero=0
op=4 a=c b=a y=6 zero=0
op=0 a=f b=1 y=0 zero=1
```

**`fsm_light`**

```text
state=0 red=1 green=0 yellow=0
state=1 red=0 green=1 yellow=0
state=2 red=0 green=0 yellow=1
state=0 red=1 green=0 yellow=0
state=1 red=0 green=1 yellow=0
```

**`sr16`**

```text
qout=0000
qout=a5c3
qout=4b86
qout=25c3
qout=25c3
```

### ง.7 ไฟล์ log ที่เก็บไว้ให้ตรวจย้อนหลัง

| ไฟล์ | เก็บอะไร |
|---|---|
| `lab08_gls_regression/results/regression_summary.txt` | สรุปผลรวมของทั้งชุด |
| `lab08_gls_regression/results/lab0*.log` | stdout ของแต่ละ lab |
| `lab08_gls_regression/results/*_rtl.txt`, `*_gls.txt` | trace ของแต่ละดีไซน์ |
| `lab08_gls_regression/results/*_verdict.txt` | PASS/FAIL ของแต่ละดีไซน์ |
| `netlist/*_stat.txt` | สถิติเซลล์จาก Yosys |
| `netlist/*_synth.log` | log ฉบับเต็มของการสังเคราะห์ |

---

## ภาคผนวก จ — เฉลยแบบฝึกหัด และการต่อยอด

### จ.1 เฉลยแบบฝึกหัดของแต่ละ lab

> **คำตอบทั้งหมดในหัวข้อนี้ได้จากการรันจริง**
> ไม่ใช่การคาดเดา — ทุกข้อสรุปมาจากการแก้ไฟล์จริงแล้วรันซ้ำ

**LAB 01**

| แบบฝึกหัด | คำตอบ (วัดจริง) |
|---|---|
| 1. แก้ `cnt4` ให้นับลง → FAIL | ข้อความแรกที่ผิดคือ `** FAIL count up : expected 1 but got f` ที่ `t=26.000 ns` (เริ่มจาก `q = 0` แล้วลดลงเป็น `f`) — trace ที่ได้คือ `0, f, e, d, c, b, a, a, 7` และ `checks = 9 , errors = 8` |
| 2. เปลี่ยน `en` เป็น `'x` ชั่วขณะ | ที่ระดับ RTL `q` จะ**คงค่าเดิม = 3** แต่ที่ระดับ gate จะกลายเป็น `x` — วัดได้จริงใน LAB 06 |

**LAB 02**

| แบบฝึกหัด | คำตอบ (วัดจริง) |
|---|---|
| 1. สังเคราะห์ `alu4` | **64 เซลล์, 19 ชนิดเซลล์, 4 flip-flop** |
| 2. แก้เป็นตัวนับ 8 บิต | สังเคราะห์ `cnt8` จริงได้ **24 เซลล์, 10 ชนิดเซลล์, 8 flip-flop** (จาก 11 เซลล์ของ `cnt4`) — เพิ่มขึ้น 13 เซลล์ |
| 3. สังเคราะห์โดยไม่มี `dfflibmap` | ⚠ **ผลที่วัดได้น่าสนใจมาก** — ดูรายละเอียดด้านล่าง |

> **รายละเอียดข้อ 3 (วัดจริง)**
>
> | | มี `dfflibmap` | ไม่มี `dfflibmap` |
> |---|---|---|
> | จำนวนเซลล์ | 11 | 10 |
> | flip-flop | `sg13g2_dfrbpq_1` × 4 | `$_DFFE_PN0P_` × 4 (เซลล์ภายในของ Yosys) |
> | ตรรกะ combinational | `a21o_1`, `and2_1`, `nand3_1`, `nand4_1`, `xnor2_1` × 2, `xor2_1` | `a21o_1`, `and2_1`, `inv_1`, `nand3_1`, `xnor2_1`, `xor2_1` |
> | ไฟล์ netlist ที่ได้ | instance ของเซลล์ทั้งหมด | **กลับไปเป็น `always` block เชิงพฤติกรรม** |
> | จำลองแล้ว | เป็น gate level จริง | **ยังรันผ่าน** (`checks = 9 , errors = 0`) แต่ส่วน sequential **ไม่ใช่ gate level เลย** |
>
> นี่คือข้อสรุปที่สำคัญ: **ถ้าไม่มี `dfflibmap` คุณจะได้ netlist ที่ “รันผ่าน”**
> แต่ flip-flop จะกลับไปเป็นโค้ด `always` เชิงพฤติกรรม
> ซึ่ง **ไม่ได้ทดสอบอะไรที่ระดับ gate เลย** ส่วนตรรกะ combinational ก็เปลี่ยนไปด้วย
> เพราะ ABC optimize ได้ผลต่างออกไป
>
> (ถ้าอยากได้เซลล์ภายในของ Yosys เป็น instance จริง ๆ ต้องใช้ `simplemap` ก่อน `write_verilog`
> แต่ถึงอย่างนั้นก็ยังไม่ใช่เซลล์มาตรฐานของ PDK — จึงยัง GLS ไม่ได้)

**LAB 03**

| แบบฝึกหัด | คำตอบ (วัดจริง) |
|---|---|
| 1. `sg13g2_dfrbpq_1` ตอน `RESET_B` = 0 | โมดูลคือ `sg13g2_dfrbpq_1 (Q, D, RESET_B, CLK)` — มีแค่ขา `Q` **ไม่มี `Q_N`** (ต่างจาก `dfrbp_1` ที่มีทั้ง `Q` และ `Q_N`) และ `specify` block ระบุ `(negedge RESET_B => (Q+:1'b0)) = 0;` คือ `Q` ถูกบังคับเป็น `0` **ทันทีที่ขา reset ตก โดยไม่ต้องรอ edge ของ clock** |
| 2. `sg13g2_lgcp_1` ต่างจาก flip-flop อย่างไร | เป็น **clock gating cell ของ latch** (latch gated clock pulse) มีขา `GCLK`, `GATE`, `CLK` และ **ไม่มีขา `D` หรือ `Q`** — จึงไม่เก็บสถานะ เป็นเพียงตัวควบคุมนาฬิกา |
| 3. ดูค่าภายในของเซลล์ | วัดจริงแล้ว **บน netlist ขนาดเล็กของคู่มือนี้ `examine` ให้ผลเหมือนกันทั้งแบบที่ใส่ `+acc` และไม่ใส่** (ทั้งคู่คืนค่า `x` และรายการสัญญาณภายใน `dut` มี 11 ตัว) ข้อแตกต่างจะเห็นชัดเมื่อวงจรใหญ่ขึ้นและตัว optimize ตัดสัญญาณที่ไม่มีใครดูทิ้ง — ให้ใส่ `+acc` ไว้เสมอ |

**LAB 04**

| แบบฝึกหัด | คำตอบ (วัดจริง) |
|---|---|
| 1. เอา `vlog` ของเซลล์ออก | จะเห็น `** Error: (vsim-3033)` **11 บรรทัด** แล้วจบด้วย `Error loading design` โดยตัว simulator รายงาน `Errors: 11, Warnings: 0` (11 = จำนวน instance ของเซลล์ใน `cnt4_net.v` พอดี) |
| 2. เอา `+acc` ออก | ดูข้อ 3 ของ LAB 03 ข้างบน — บน netlist ขนาดเล็ก **ผลเหมือนกัน** ไม่ได้แตกต่างอย่างที่คิด |
| 3. รัน `run.do` ใน GUI | เปิด waveform ดู `q` ได้ และเห็นว่าเป็นสัญญาณของโมดูล `cnt4` ที่ถูกสังเคราะห์แล้ว (หัวข้อนี้เป็นการใช้ GUI จึงไม่มีตัวเลขจากการรันบรรทัดคำสั่ง) |

**LAB 05**

| แบบฝึกหัด | คำตอบ (วัดจริง) |
|---|---|
| 1. สลับ `D` ของ `q[1]`/`q[2]` | trace จะต่างกันที่ **บรรทัด 3 และ 5** พอดี — ดู LAB 07 |
| 2. ใช้ชื่อ trace เดียวกัน | ⚠ วัดแล้ว: การรัน GLS **เขียนทับ** trace ของ RTL ทิ้ง (ไฟล์ก่อนเขียนทับเป็น `0,1,2,3,4,5,6,6,9` พอเขียนทับแล้วเป็น `0,8,9,3,4,c,d,d,2`) ถ้าสคริปต์เปรียบเทียบไฟล์กับตัวเอง จะได้ผลว่า **เหมือนกัน 0 จุด** ทั้งที่วงจรต่างกันสิ้นเชิง — เป็นกับดักที่ทำให้ GLS ไม่จับบั๊กเลย |
| 3. พิมพ์ `q` ทุก 5 ns | วัดแล้ว: testbench ที่พิมพ์ทุก 5 ns ให้ไฟล์ trace **28 บรรทัด** (29 องค์ประกอบเมื่อนับด้วย `split` ซึ่งเก็บ element ว่างท้ายไฟล์ไว้ด้วย) เทียบกับ 9 บรรทัดเดิม |

**LAB 06**

| แบบฝึกหัด | คำตอบ (วัดจริง) |
|---|---|
| 1. เปลี่ยน `en` เป็น `'z` | วัดแล้วได้ผล **เหมือนกรณี `'x'` ทุกประการ** — RTL เห็น `observed=3` และ GLS เห็น `observed=x` เหตุผลคือเกตมาตรฐานถือว่าอิมพีแดนซ์เป็น “ไม่รู้” เหมือนกัน |
| 2. ตัดตรรกะของ `en` ออก | วัดแล้ว: สัญญาณภายในของ netlist คือ `_00_` ถึง `_03_` (ผลของ `xor2`, `and2`, `xnor2`) มีค่า **`x` ทั้ง 4 ตัว** รวมถึง `q` — นี่คือหลักฐานว่า `x` **แพร่ผ่านเกตจริง** ไม่ใช่โผล่มาเองที่ flip-flop |
| 3. ใช้ `!=` แทน `!==` | วัดแล้วบน netlist ที่มีบั๊ก: ตัวตรวจที่ใช้ `!=` ยังรายงาน **6 error เท่าเดิม** เพราะค่าในบั๊กนี้เป็น `0/1` ล้วน ไม่มี `x` — ข้อนี้จึงไม่มีผลกับ LAB 07 แต่จะมีผลกับเคสที่ค่าเป็น `x` |

**LAB 07**

| แบบฝึกหัด | คำตอบ (วัดจริง) |
|---|---|
| 1. สลับ `D` ของ `q[0]` กับ `q[3]` | ข้อความแรกที่ผิดคือ `** FAIL count up : expected 1 but got 8` ที่ `t=26.000 ns` — trace ที่ได้คือ `0, 8, 9, 3, 4, c, d, d, 2` และ `checks = 9 , errors = 6` (มากกว่า 2 error ของเคสสลับ `q[1]`/`q[2]` ตามคาด) |
| 2. ตัด `RESET_B` ออก | วัดแล้ว: ต่อ `RESET_B` ของ `q[0]` เป็น `1'b1` ผลคือ **`** FAIL after reset : expected 0 but got X`** และ **ทั้ง 9 จุดผิดหมด** (`checks = 9 , errors = 9`) เพราะบิตที่ไม่ถูก reset ค้างเป็น `X` แล้วแพร่ไปทั้งตัวนับ |
| 3. เขียน `always @*` แล้วสังเคราะห์ใหม่ | ⚠ **ผลที่วัดได้และไม่คาดคิด** — ดูรายละเอียดด้านล่าง |

> **รายละเอียดข้อ 3 (วัดจริง)**
>
> log ของ Yosys จะขึ้นว่า
>
> ```text
> 3.8. Executing PROC_DLATCH pass (convert process syncs to latches).
> Latch inferred for signal `\cnt4.\q' from process ...
> Using extmapper simplemap for cells of type $dlatch.
> ```
>
> และสถิติจะได้
>
> ```text
> Number of cells:                 13
>    $_DLATCH_N_                     4
>    sg13g2_a21o_1                   1
>    sg13g2_a21oi_1                  1
>    sg13g2_and2_1                   1
>    sg13g2_and3_1                   1
>    sg13g2_nand3_1                  1
>    sg13g2_nor2b_1                  2
>    sg13g2_o21ai_1                  1
>    sg13g2_xnor2_1                  1
> ```
>
> ⚠ **แม้ชุดเซลล์ SG13G2 จะมีเซลล์ latch อยู่จริง (`sg13g2_dlhq_1` เป็นต้น)
> แต่ flow ของคู่มือนี้จะไม่เอา latch ไป map เป็นเซลล์มาตรฐาน**
> เพราะ `dfflibmap` จัดการเฉพาะ flip-flop
> ผลคือ latch ค้างเป็น `$_DLATCH_N_` ของ Yosys แล้วถูกเขียนกลับเป็น
> `always @*` เชิงพฤติกรรมในไฟล์ netlist
>
> นี่คือข้อสรุปสำคัญ: **ถ้าอยากจับ latch ด้วย GLS ต้องทำให้ flow map latch
> เป็นเซลล์มาตรฐานก่อน** ไม่เช่นนั้นจะได้โค้ดเชิงพฤติกรรมที่ไม่ได้ทดสอบอะไร

**LAB 08**

| แบบฝึกหัด | คำตอบ (วัดจริง) |
|---|---|
| 1. เพิ่มดีไซน์ใหม่ | ต้อง (1) เพิ่ม `rtl/<top>.v` (2) สังเคราะห์เป็น `netlist/<top>_net.v` (3) เพิ่ม `tb/tb_<top>.v` (4) เพิ่มชื่อดีไซน์ใน `for %%D in (...)` ของ `run.cmd` — ทดลองทำตามนี้กับ `cnt8` ที่สังเคราะห์ไว้ข้างบนก็ได้ (24 เซลล์, 10 ชนิด) |
| 2. ทำให้ regression ไม่ผ่าน | `results/regression_summary.txt` จะมีบรรทัด `FAIL  <lab>  exit=1` แทน `PASS` และสรุปจะขึ้น `failed = 1` พร้อมข้อความ `[REGRESSION] FAILED -- 1 lab(s) did not pass` |
| 3. นับเวลา | ⚠ **ผลที่วัดได้ไม่ตรงกับที่คาด** — ดูรายละเอียดด้านล่าง |

> **รายละเอียดข้อ 3 (วัดจริง)**
>
> วัดเวลาเฉพาะช่วง `run -all` ด้วย `clock milliseconds` (ไม่รวมเวลาเปิดตัวจำลอง)
> รันซ้ำ 3 ครั้งต่อหนึ่งกรณี:
>
> | ดีไซน์ | RTL | GLS |
> |---|---|---|
> | `alu4` | 58, 65, 59 ms | 61, 67, 63 ms |
> | `sr16` | 78, 71, 60 ms | 69, 83, 78 ms |
>
> **ผลคือระดับ gate ไม่ช้ากว่าระดับ RTL อย่างที่คาด**
> เพราะดีไซน์ในคู่มือนี้เล็กมาก (11–102 เซลล์) และเวลาที่ใช้จริง
> ในการจำลองมีแค่หลักสิบหน่วยเวลาจำลอง
> เวลาที่วัดได้จึงถูกกลืนไปกับค่าคงที่ของตัวจำลองเอง
>
> ข้อสรุปที่ถูกต้องคือ: **ความช้าของ GLS จะเห็นชัดเมื่อวงจรใหญ่ขึ้น**
> (หลักพันเซลล์ขึ้นไป) ไม่ใช่กับดีไซน์ตัวอย่างในคู่มือนี้
> และเวลาเปิดตัวจำลองเอง (ประมาณ 5–7 วินาทีต่อครั้ง) มักมากกว่าเวลาจำลองเองเสมอ
> ซึ่งเป็นเหตุผลที่ flow จริงต้องรันหลาย design ใน batch เดียวกัน

### จ.2 ต่อยอดจากคู่มือนี้

คู่มือนี้ครอบคลุม **พื้นฐานของ GLS** เท่านั้น
ถ้าจะเอาไปใช้กับงานจริง ขั้นต่อไปตามลำดับความยากคือ

1. **ใส่ SDF เพื่อดูความหน่วงจริง**
   ตอนนี้โมเดล SG13G2 ใส่ค่าหน่วงเป็น `0` ใน `specify` block
   การจำลองจึงเห็นเวลาเป็นศูนย์หน่วง
   เมื่อมี SDF จะเห็น **setup/hold violation** และเวลาหน่วงจริงของแต่ละเซลล์

2. **ทำ netlist coverage**
   เพิ่มคำสั่ง `coverage` ของ QuestaSim เพื่อวัดว่าเซลล์และเส้นทางใด
   ของ netlist ถูกกระตุ้นบ้าง รวมถึง **toggle coverage** ของ flip-flop

3. **ทำ X-propagation analysis**
   LAB 06 สาธิตว่าค่า `x` แพร่ผ่านเกตได้
   ใน flow จริงต้องมีการตรวจว่ามี `x` หลุดออกมาที่ output หรือไม่
   (เครื่องมือที่นิยมคือ Questa X-prop / Synopsys VCZ)

4. **เปรียบเทียบกับ STA**
   ผลของ GLS ควรตรงกับ static timing analysis
   ถ้าไม่ตรง แปลว่ามีปัญหาที่ระดับ setup/hold ที่การจำลองแบบไม่มี SDF จะไม่เห็น

5. **ทำ formal equivalence**
   เทียบ RTL กับ netlist ด้วยเครื่องมือ formal แทนการจำลอง
   ครอบคลุมทุก input ไม่ใช่แค่ที่ testbench กระตุ้น

### จ.3 ข้อควรจำสำหรับผู้สอน

- คู่มือนี้ใช้ **Verilog** ทั้งหมด เพราะ testbench ชุดเดียวต้องรันได้ทั้งระดับ RTL และระดับ gate
  (เปลี่ยนเฉพาะไฟล์ที่ compile เข้า `work`)
- ทุก lab มี `run.cmd` ที่เป็น **ทางเดียว** (single entry point)
  ผู้เรียนไม่ต้องจำคำสั่งยาว ๆ
- ใบอนุญาตเป็น **session เดียว** ถ้าเปิด QuestaSim GUI ค้างไว้
  ระบบจะเลือกใช้ ModelSim DE ให้อัตโนมัติ แต่ถ้าเปิดทั้งสองชุดพร้อมกัน
  ให้ปิดหน้าต่าง GUI ของผู้เรียนก่อน
- LAB 07 เป็น lab ที่ “ผ่าน” ทั้งที่ข้อความเป็น `** FAIL`
  ให้อธิบายเกณฑ์นี้ก่อนให้ทำ ไม่เช่นนั้นผู้เรียนจะสับสน
- ถ้าใช้กับ **นักเรียน ~30 คน** แนะนำให้แบ่งเป็น 2 กลุ่ม
  โดยให้กลุ่มหนึ่งทำ LAB 01–04 (พื้นฐาน RTL และเซลล์)
  อีกกลุ่มทำ LAB 05–08 (การเทียบและการจับบั๊ก) แล้วสลับกัน
  เพราะใบอนุญาตของเครื่องจำลองเป็น session เดียว
