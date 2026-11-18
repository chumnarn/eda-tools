
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
