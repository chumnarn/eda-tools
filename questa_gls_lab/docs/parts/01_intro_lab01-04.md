
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
