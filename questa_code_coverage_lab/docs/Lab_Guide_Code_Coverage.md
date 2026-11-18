# คู่มือปฏิบัติการ (Lab Guide): Using Code Coverage in QuestaSim

**หลักสูตร:** Questa Tool Usage — Module 3: Introduction to Code-Coverage
**ระดับ:** เป็นคู่มือปฏิบัติการแบบ hands-on (workshop) สำหรับผู้เรียนที่ผ่าน Module 1–2 แล้ว
**ภาษา:** อธิบายเป็นภาษาไทย ศัพท์เทคนิคคงศัพท์อังกฤษตามที่ปรากฏในเครื่องมือ
**เวลาที่แนะนำ:** 4–6 ชั่วโมง (บทที่ 1–2: 2 ชม., บทที่ 3–5: 2–4 ชม.)

---

## ภาพรวม (Overview)

คู่มือนี้จัดลำดับหัวข้อตามโครงสร้าง Module-3 ของเอกสารประกอบการสอน โดยแต่ละหัวข้อจะแบ่งเป็น
3 ส่วนเสมอ:

| ส่วน | รูปแบบ | เวลาโดยประมาณ |
|---|---|---|
| **ทฤษฎี (Theory)** | อธิบายแนวคิด ศัพท์ และสิ่งที่เครื่องมือวัดจริง | 20–30 นาที |
| **ปฏิบัติ (Lab)** | ขั้นตอนทำตาม มีภาพผลลัพธ์ที่วัดได้จริงเปรียบเทียบ | 30–60 นาที |
| **แบบฝึกหัด (Exercise)** | ให้ผู้เรียนทำเอง มีเฉลยท้ายบท | 30–45 นาที |

> **หลักการของคู่มือนี้** — ตัวเลขทุกตัวที่ปรากฏในคู่มือได้มาจากการรันจริงบนเครื่อง
> **ModelSim DE-64 / QuestaSim 2026.1** ด้วยไฟล์ที่แนบมากับคู่มือ ไม่ใช่ตัวอย่างที่แต่งขึ้น
> ผู้เรียนจึงสามารถทำซ้ำแล้วได้ตัวเลขชุดเดียวกัน

### ผลการเรียนรู้ (Learning Objectives)

เมื่อจบคู่มือนี้ ผู้เรียนจะสามารถ:

1. อธิบายว่า code coverage คืออะไร และเหตุใดจึงต้องใช้ร่วมกับ functional coverage
2. แยกแยะ coverage metric ทั้ง 6 ชนิด (`s b c e t f`) ว่าวัดอะไร และดูผลได้จากหน้าต่างใด
3. เปิดใช้งาน code coverage แบบ 2-step flow ทั้งจาก GUI และจาก command line
4. อ่านรายงาน coverage ระดับ summary และระดับ detail แล้วระบุได้ว่า
   *อะไรยังไม่ถูก cover และเพราะอะไร*
5. บันทึก coverage ของแต่ละ test เป็นฐานข้อมูล UCDB แล้ว **merge** ให้เป็นผลรวม
6. สร้างรายงาน coverage ได้ทั้งแบบ text, HTML และเปิดดูแบบ Coverage View mode
7. อธิบายข้อผิดพลาดที่พบบ่อยที่สุดของการ merge coverage และวิธีแก้ไข

### สิ่งที่ต้องเตรียม (Prerequisites)

| รายการ | ข้อกำหนด |
|---|---|
| Simulator | ModelSim DE / QuestaSim (ทดสอบกับ **2026.1**) |
| License | ต้องมีสิทธิ์ใช้ Code Coverage (ModelSim DE มีให้อยู่แล้ว) |
| ภาษา | Verilog-2001 (หลัก) และ VHDL-2008 (ภาคผนวก D) |
| ความรู้พื้นฐาน | รู้จัก `vlog`/`vcom`, `vsim`, `vlib`/`vmap`, การสร้าง testbench |

### โครงสร้างไฟล์ของแลป (Lab Files)

```
questa_code_coverage_lab/
├── rtl/
│   └── cmd_fsm.v              # DUT (Verilog) — มีโครงสร้างครบทั้ง 6 metric
├── tb/
│   ├── tb_cmd_fsm.v           # testbench เดียว เลือก test ด้วย +TEST= plusarg
│   └── pitfall/               # testbench 2 ชุด สำหรับสาธิต "ข้อผิดพลาด" ในบทที่ 4
│       ├── tb_cmd_fsm_basic.v
│       └── tb_cmd_fsm_extra.v
├── vhdl/
│   ├── cmd_fsm.vhd            # DUT (VHDL) — ภาคผนวก D
│   └── tb_cmd_fsm.vhd
├── scripts/
│   ├── compile.do             # Lab 0 : คอมไพล์
│   ├── lab1_test_basic.do     # Lab 1 : test basic
│   ├── lab2_test_extra.do     # Lab 2 : test extra
│   ├── lab3_merge.do          # Lab 3 : merge
│   ├── lab4_report.do         # Lab 4 : รายงาน
│   ├── run_all.cmd            # รันทั้ง flow อัตโนมัติ (Verilog)
│   └── run_vhdl.cmd           # รันทั้ง flow อัตโนมัติ (VHDL)
├── results/                   # ผลลัพธ์ UCDB และรายงาน (สร้างโดยสคริปต์)
└── docs/
    └── Lab_Guide_Code_Coverage.md   # คู่มือนี้
```

---

## บทที่ 1 — Introduction to Code Coverage

### 1.1 Code coverage คืออะไร

**Code coverage** คือการวัดว่า *ส่วนใดของซอร์สโค้ด HDL ถูกเรียกใช้งานจริง* ระหว่างการ
simulate และ *ส่วนใดไม่เคยถูกเรียก* ผลลัพธ์ที่ได้คือ **coverage bins** ซึ่งแต่ละ bin จะ
ถูกทำเครื่องหมายว่า

| สถานะ | ความหมาย |
|---|---|
| **Hit** | มีการเรียกใช้งานอย่างน้อย 1 ครั้ง |
| **Miss** | ไม่เคยถูกเรียกใช้งานเลย |
| **Excluded** | ถูกตัดออกจากการคำนวณด้วยคำสั่ง exclude (ดูบทที่ 3.7) |

ความสำคัญของมันอยู่ที่ **"สิ่งที่ไม่เคยถูกทดสอบ" คือบริเวณที่ยังอาจมีบั๊ก** —
ถ้าบรรทัดใดของโมดูลไหนไม่เคยถูกเรียกเลย เรายังไม่รู้ว่ามันทำงานถูกหรือไม่

### 1.2 Code coverage ต่างจาก Functional coverage อย่างไร

| | Code coverage | Functional coverage |
|---|---|---|
| **วัดอะไร** | โครงสร้างของซอร์สโค้ด (บรรทัด, branch, condition…) | พฤติกรรม/สเปกของดีไซน์ที่ประกาศไว้เอง (covergroup, assertion) |
| **ใครเป็นเจ้าของ** | เครื่องมือวิเคราะห์โค้ดอัตโนมัติ | ผู้ออกแบบ verification ประกาศไว้เอง |
| **ตัวอย่าง** | `if (a > b)` สาขไหนไม่เคยเป็นจริง | "ต้องเคยรับ packet ยาว 64–128 ไบต์" |
| **ข้อจำกัด** | บอกได้แค่ "โค้ดยังไม่ถูกรันครบ" ไม่ได้บอกว่าสเปกถูกตรวจแล้ว | บอกได้ว่าสเปกครบ แต่ไม่ได้บอกว่าตรรกะภายในถูกรันครบ |

> **ข้อควรจำ (จุดที่ผู้เรียนมักสับสน)** — code coverage 100% **ไม่ได้แปลว่า** ดีไซน์ถูกต้อง
> และ functional coverage 100% **ไม่ได้แปลว่า** โค้ดถูกรันครบ
> ทั้งสองอย่างต้องได้ 100% ควบคู่กันจึงจะเรียกว่ามีความมั่นใจในระดับที่ยอมรับได้

### 1.3 ข้อดีและข้อจำกัด

**ข้อดี**
- ติดตั้งและใช้งานได้ทันที ไม่ต้องแก้ซอร์สโค้ด ไม่ต้องเขียน covergroup เพิ่ม
- รองรับ VHDL, Verilog และ SystemVerilog ทั้งหมด
- เห็นผล "สด" ระหว่าง simulation และตรวจย้อนกลับไปยังบรรทัดที่ยังไม่ถูกรันได้ทันที
- บันทึกเป็นฐานข้อมูล UCDB แยกต่างหากได้ → merge ข้าม regression ได้

**ข้อจำกัด**
- มี overhead ประมาณ **5–10%** ของเวลา simulate (ตัวเลขจากเอกสารประกอบการสอน)
- เป็น *static* coverage ของโค้ด บอกไม่ได้ว่าสเปกที่ตั้งใจทดสอบครบหรือยัง
- การได้ 100% บางครั้งเป็นผลของ testbench ที่ "บังคับ" ค่าสัญญาณเข้าไปใน DUT
  ซึ่งไม่ได้ทดสอบพฤติกรรมจริง → ต้องอ่านรายงานร่วมกับ waveform เสมอ

### 1.4 ศัพท์พื้นฐาน (Vocabulary)

| ศัพท์ | ความหมาย |
|---|---|
| **bin** | หน่วยนับเล็กที่สุดของ coverage (เช่น 1 branch = 1 bin) |
| **hit / miss** | bin ที่ถูก / ไม่ถูกเรียกใช้ |
| **coverage %** | (จำนวน bin ที่ hit) ÷ (จำนวน bin ทั้งหมด) × 100 |
| **weight** | น้ำหนักของ bin ในการคำนวณสรุป (ปกติ = 1 ทุก bin) |
| **dataset** | ชุดข้อมูล coverage หนึ่งชุด ในที่นี้คือไฟล์ UCDB หนึ่งไฟล์ |
| **UCDB** | Unified Coverage Database — รูปแบบฐานข้อมูล coverage ของ Siemens EDA |
| **instance path** | พาธเต็มของ instance เช่น `/tb_cmd_fsm/dut` — **สำคัญมากในบทที่ 4** |

### 1.5 รู้จัก DUT ของแลป (อ่านก่อนลงมือ)

DUT ของแลปคือ `rtl/cmd_fsm.v` — โมดูล Command Decoder + Response FSM เล็ก ๆ ที่ออกแบบมาให้มี
โครงสร้างครบทุก metric ที่วัดได้ ผู้เรียนควรอ่านโค้ดก่อนเริ่ม และทำนายจำนวน bin ด้วยมือ
(แบบฝึกหัดที่ 1)

โครงสร้างของโมดูล (หมายเลขบรรทัดตรงกับไฟล์จริง):

| บรรทัด | โค้ด | ให้ coverage metric อะไร |
|---|---|---|
| 47–52 | `case (state)` + `if` ในแต่ละสถานะ | **Branch**, **FSM** |
| 48 | `ST_IDLE : if (en)` | Branch (2 สาข) |
| 49 | `ST_EXEC : if (!en)` | Branch (2 สาข) |
| 50 | `ST_WAIT : if (a == b)` | Branch (2 สาข) + **Condition** (UDP) |
| 51 | `ST_DONE : if (!en)` | Branch (2 สาข) |
| 52 | `default : next_state = ST_IDLE;` | Branch (case item) |
| 59–61 | process ของ register `state` | **Statement**, Branch (reset) |
| 64 | `assign state_o = state;` | **Toggle** |
| 65 | `assign done = (state == ST_DONE);` | **Expression** |
| 73–84 | decoder: `if (en)` + `case (cmd)` + 5 ข้อความ | **Statement**, **Branch**, **Expression** |
| 90–95 | compare: `if/elsif/else` 3 ทาง | **Branch**, **Condition** |
| 101–103 | `parity = (a[0]^b[0]) & (a[1]\|b[1]);` | **Expression**, **Toggle** |

> **จุดที่ต้องสังเกต** — บรรทัด 50 (`if (a == b)`) และบรรทัด 65 (`state == ST_DONE`)
> จะกลายเป็น *บรรทัดที่ยากที่สุด* ที่จะ cover ได้ เพราะต้องอยู่ในสถานะที่ถูกต้อง
> พร้อมกับค่าอินพุตที่ถูกต้อง ซึ่งจะได้แก้ในบทที่ 4

---

## บทที่ 2 — Types of Code Coverage

QuestaSim/ModelSim วัด code coverage ได้ **6 ชนิด** (หรือ 7 ถ้านับ extended toggle แยก)
ควบคุมกันด้วยสวิตช์ `+cover=<spec>` ที่ตัวอักษรแต่ละตัวเป็นตัวเลือก:

| ตัวอักษร | Metric | วัดอะไร |
|---|---|---|
| `s` | **Statement** | คำสั่งแต่ละบรรทัดถูกเรียกครบหรือไม่ |
| `b` | **Branch** | ทุกทางเลือกของ `if`/`else` และทุก item ของ `case` |
| `c` | **Condition** | ทุกแถวในตารางความจริง (UDP) ของเงื่อนไข boolean |
| `e` | **Expression** | นิพจน์ทางขวาของ assignment ทุก sub-expression |
| `f` | **FSM** | สถานะและ transition ของ state machine |
| `t` | **Toggle** | สัญญาณเปลี่ยนค่า 0→1 และ 1→0 |
| `x` | **Extended toggle** | Toggle แบบ 3-state (รวมการเข้า/ออกจาก Z) — `x` มีผลเหนือ `t` |

> **ค่า default ของเครื่องมือ** — ถ้าไม่ระบุ `<spec>` เครื่องมือจะใช้ `sbceft`
> (ตรวจสอบจาก `vlog -help Coverage` บน 2026.1)
> *หมายเหตุ:* เอกสารประกอบการสอนระบุ `bcesft` ซึ่งเป็นค่าที่โรงเรียนใช้ในตัวอย่าง
> ในคู่มือนี้จะระบุ `+cover=bcesft` **เต็มไปตลอด** เพื่อไม่ให้ผลขึ้นกับค่า default

### 2.1 Statement Coverage (`s`)

ทุกๆ คำสั่งที่มีการ assign ค่า จะถูกนับเป็น 1 statement

```verilog
always @(*) begin
    result = 4'h0;                 // ← นับเป็น 1 statement
    if (en) begin
        case (cmd)
            4'h1:    result = a + b;   // ← นับเป็น 1 statement
            ...
        endcase
    end
end
```

**ข้อควรระวัง:** คำสั่งที่อยู่ภายใน `if` จะถูกนับเป็น statement **เฉพาะเมื่อเงื่อนไขเป็นจริง**
เท่านั้น เช่นเดียวกับตัวอย่างในสไลด์ `if (x == 0) z = 1;` — ถ้า `x` ไม่เท่ากับ 0
คำสั่งนั้นจะไม่ถูก hit ดังนั้น statement coverage จึงต่ำกว่า branch coverage เสมอ

**ข้อจำกัดของ statement coverage:** มันบอกได้แค่ว่า "บรรทัดนี้ถูกรัน" ไม่ได้บอกว่า
"รันในสถานการณ์ที่ถูกต้องหรือไม่" — จึงต้องใช้ร่วมกับ branch/condition เสมอ

### 2.2 Branch Coverage (`b`)

วัดว่า **ทุกทางเลือก** ของโครงสร้างการตัดสินใจถูกเดินครบหรือไม่

**a) `if` / `else`** — 2 สาข (จริง / เท็จ)

```verilog
if (x == 0) z = 1;
else       z = 0;
```
→ 2 bins: สาขจริง และสาขเท็จ

**b) `case`** — 1 bin ต่อ case item **และ** แต่ละ item ยังถูกนับเป็น branch แยกอีกชุด

```verilog
case (x)
    1,2: z = 1;      // เป็น 1 case item แต่แตกเป็น 2 เงื่อนไข
    3:   z = 0;
endcase
```
→ Statement coverage: บรรทัด `1,2: z = 1;` ถูก hit ถ้า `x` เป็น 1 หรือ 2
→ Branch coverage: รายงานแยกว่า `x == 1` ถูกทดสอบหรือยัง, `x == 2` ถูกทดสอบหรือยัง,
และ `x == 3` ถูกทดสอบหรือยัง → **branch coverage ให้ข้อมูลที่ละเอียดกว่า**

**ใน DUT ของแลป** — `case (cmd)` ที่บรรทัด 76–82 มี 5 items
(`4'h1`, `4'h2`, `4'h3`, `4'h4`, `default`) → 5 branch bins
รวมกับ `if (en)` ที่บรรทัด 75 อีก 2 bins → decoder ให้ 7 bins

### 2.3 Condition Coverage (`c`)

เป็นส่วนขยายของ branch coverage ที่วิเคราะห์เงื่อนไขแบบ **boolean (UDP)**
โดยสร้างตารางความจริงขึ้นมาเอง แล้วนับจำนวนครั้งที่แต่ละแถวถูกเดินผ่าน

```verilog
if (en && (a > b)) zero = 1'b1;
```
→ เงื่อนไขนี้ถูกแตกเป็น 2 input term (`en`, `a > b`) และแต่ละ term มีแถว `_0` และ `_1`
→ ต้อง hit **ครบทั้ง 4 แถว** จึงจะถือว่า condition นี้ covered

> **ความต่างจาก branch:** branch ถามว่า *"if นี้เป็นจริงบ้าง เป็นเท็จบ้าง"*
> condition ถามว่า *"แต่ละ combination ของตัวแปรย่อยถูกลองครบหรือยัง"*
> เงื่อนไขแบบ `a && b` ต้องการ 4 แถว ขณะที่ branch ต้องการแค่ 2 สาข

ใน DUT ของแลป มีเงื่อนไขที่ต้องวัด 5 เงื่อนไข:
1. บรรทัด 50 — `(a == b)` ใน `ST_WAIT`
2. บรรทัด 92 — `(en && (a > b))`
3. บรรทัด 93 — `(en && (a == b))`
4. บรรทัด 75 — `(en)` (เงื่อนไขเดี่ยว)
5. บรรทัด 48/49/51 — เงื่อนไขเดี่ยวใน FSM

### 2.4 Expression Coverage (`e`)

วิเคราะห์ **นิพจน์ทางขวาของ assignment** แล้วแตกเป็น sub-expression
โดยแต่ละ sub-expression จะมีตารางความจริงของตัวเอง

```verilog
parity = (a[0] ^ b[0]) & (a[1] | b[1]);
```
→ นิพจน์นี้มี sub-expression 4 ตัว: `a[0]`, `b[0]`, `a[1]`, `b[1]`
→ แต่ละตัวต้องถูก hit **ทั้งค่า 0 และค่า 1** และต้องให้ผลลัพธ์ของนิพจน์ใหญ่
เป็นทั้ง 0 และ 1 → นี่คือเหตุผลที่ expression coverage มักเป็น **ตัวที่ปิดยากที่สุด**
เพราะต้องควบคุม "หน้าต่าง" ของแต่ละบิต ให้ถูกต้องทั้งแบบที่นิพจน์ให้ผลเป็น 0 และ 1

> **เคล็ดลับในการปิด expression** — ถ้านิพจน์ใหญ่เป็น `X & Y` แล้ว `X` เป็น 0
> ผลลัพธ์จะเป็น 0 เสมอไม่ว่า `Y` จะเป็นอะไร → **ต้องทำให้ `X` เป็น 1 ด้วย** ไม่งั้น
> แถวของ `Y` จะไม่มีวันถูก hit ดูรายงาน detail บรรทัด "Non-masking condition(s)"
> เพื่อดูว่าต้องจัดค่าอะไรบ้าง

### 2.5 Toggle Coverage (`t` / `x`)

นับการเปลี่ยนค่าของสัญญาณแต่ละบิต

- **Standard toggle (2-state):** นับ `0→1` และ `1→0`
- **Extended toggle (3-state):** นับเพิ่ม `Z→1`, `Z→0`, `1→Z`, `0→Z`

ตัวอย่าง: ถ้า `b[3]` เป็น 0 ตลอดการ simulate → ทั้ง `0→1` และ `1→0` ไม่เคยเกิด
→ สร้าง **2 bins ที่ไม่มีทาง hit** ขึ้นมา

> **Toggle coverage เป็นตัวที่สร้างความเจ็บปวดที่สุดในงานจริง**
> สัญญาณอินพุตที่ testbench ไม่เคยขยี่ เช่น `cmd[3]` จะกลายเป็น bin ที่ค้างตลอด
> วิธีรับมือที่ถูกต้องคือ **เขียน stimulus ให้ครบ** หรือ **exclude** เฉพาะตัว node
> (`coverage exclude -togglenode`) — อย่า exclude ทั้ง instance

### 2.6 FSM Coverage (`f`)

วัด 2 อย่างของ state machine:

| สิ่งที่วัด | ความหมาย |
|---|---|
| **FSM States** | สถานะแต่ละสถานะถูกเข้าถึงหรือยัง |
| **FSM Transitions** | การเปลี่ยนสถานะแต่ละเส้นถูกเดินผ่านหรือยัง |

FSM ถูก**สกัดอัตโนมัติตอนคอมไพล์** ด้วย `+cover=f` โดยเครื่องมือจะหา pattern
ของ FSM ที่เขียนด้วย state register + next-state combinational logic

> **กรณีพิเศษที่ทำให้งง: reset นับเป็น transition ด้วย**
> เมื่อออกแบบ FSM ที่มี asynchronous reset (`always @(posedge clk or negedge rst_n)`)
> การ assert reset ขณะ FSM อยู่ในสถานะใดก็ตาม จะถูกนับเป็น **transition
> ออกจากสถานะนั้น** → FSM ของแลปมี 4 สถานะ แต่มี **6 transitions** เพราะมี
> `ST_EXEC → ST_IDLE` และ `ST_WAIT → ST_IDLE` ที่เกิดจาก reset

### 2.7 ตารางสรุป metric ทั้งหมด

| Metric | สวิตช์ | วัดที่อะไร | จำนวน bin ใน DUT ของแลป | ยากที่จะปิด |
|---|---|---|---|---|
| Statement | `s` | ทุกคำสั่ง assignment | 25 | ง่าย |
| Branch | `b` | ทุกทางของ if/case | 25 | ปานกลาง |
| Condition | `c` | ทุกแถวของเงื่อนไข boolean | 5 | ปานกลาง |
| Expression | `e` | sub-expression ของ assignment | 5 | **ยาก** |
| FSM States | `f` | สถานะ | 4 | ง่าย |
| FSM Transitions | `f` | เส้นทางการเปลี่ยนสถานะ | 6 | **ยาก (reset)** |
| Toggle | `t` | 0→1 และ 1→0 ของแต่ละบิต | 56 | **ยาก** |

> ตัวเลข "จำนวน bin" ข้างบนเป็นของ DUT ที่คอมไพล์ด้วย `+cover=bcesft`
> **ถ้าเปลี่ยนวิธีเขียนโค้ดหรือเปลี่ยนภาษา ตัวเลขนี้จะเปลี่ยนไปด้วย**
> (ภาคผนวก D แสดงตัวอย่างภาษา VHDL ซึ่งให้ 31 branch / 33 statement)

---

## บทที่ 3 — Using Code Coverage in QuestaSim

### 3.1 Flow แบบ 2 ขั้นตอน (Two-step flow)

Code coverage **ไม่สามารถเปิดใช้งานได้ด้วยการสั่งเพียงอย่างเดียว** ต้องทำ 2 ขั้นตอน:

```
ขั้นที่ 1  COMPILE   vlog / vcom  +cover=<spec>      ← ฝังตัวนับลงในโค้ด
ขั้นที่ 2  SIMULATE  vsim -coverage <design>         ← เปิดใช้การเก็บสถิติ
```

ถ้าขั้นที่ 1 ไม่ได้ทำ จะไม่มีอะไรให้วัดเลย (coverage จะเป็น 0% หรือไม่มีข้อมูลเลย)

**จาก GUI**

| ขั้นตอน | เมนู |
|---|---|
| ขั้นที่ 1 | `Compile > Compile Options > Coverage tab` → เลือก metric ที่ต้องการ |
| ขั้นที่ 2 | `Simulate > Start Simulation > Others tab` → ติ๊ก `Enable code coverage` |

ทางลัด: คลิกขวาที่ design unit ในหน้าต่าง Library → `Simulate with Coverage`

**จาก Command line**

```bash
vlog  -work work rtl/cmd_fsm.v +cover=bcesft
vsim -coverage work.tb_cmd_fsm +TEST=basic
```

> **ทางลัดที่ควรรู้:** `vsim -c -coverage work.tb_cmd_fsm` จะ **คง coverage ไว้ในหน่วยความจำ**
> แล้วปิด session ทิ้งโดยไม่บันทึก → ถ้าจะบันทึก UCDB ต้องสั่ง `coverage save`
> **ก่อน** `quit -f` (ดูบทที่ 4.2)

### 3.2 แลป 0 — Compile (เตรียมก่อนทุกอย่าง)

**GUI**

1. `File > Change Directory` → เลือกโฟลเดอร์ `questa_code_coverage_lab`
2. คลิกขวาที่ `work` ในหน้าต่าง Library → `New > Library` (ถ้ายังไม่มี)
3. `Compile > Compile Options > Coverage tab` → เลือก `s b c e f t`
4. `Compile > Compile` → เลือก `rtl/cmd_fsm.v` → Compile
5. `Compile > Compile` → เลือก `tb/tb_cmd_fsm.v` → Compile

**CLI**

```bash
cd questa_code_coverage_lab
vlib work
vmap work work
vlog -work work rtl/cmd_fsm.v +cover=bcesft
vlog -work work tb/tb_cmd_fsm.v
```

> **เคล็ดลับที่ควรทำตั้งแต่ต้น:** **คอมไพล์เฉพาะ RTL ให้มี coverage** และคอมไพล์
> testbench **โดยไม่ใส่ `+cover`** → ตัวเลขทุกตัวในรายงานจะเป็นของ DUT ล้วน
> ไม่ถูกปนสัญญาณของโค้ด stimulus
> ถ้าคอมไพล์ทั้งหมดพร้อมกัน ตัวเลข statement ของแต่ละ test จะไม่เท่ากัน
> (เพราะ testbench ต่างกัน) และรายงานจะรวมสัญญาณของ TB ด้วย

**ผลลัพธ์ที่ต้องเห็น**

```
-- Compiling module cmd_fsm
** Note: (vlog-143) Recognized 1 FSM in module "cmd_fsm(verilog)".
```

> ข้อความ `Recognized 1 FSM` คือหลักฐานว่าเครื่องมือ **หา FSM เจอ** และจะเก็บ
> FSM coverage ให้ ถ้าไม่เห็นข้อความนี้ แปลว่าไม่ได้ใส่ `+cover=f`
> หรือรูปแบบการเขียน FSM ไม่ถูกต้องตามที่เครื่องมือรองรับ
> (ในภาคผนวก D ภาษา VHDL จะได้ข้อความ
> `Recognized 1 FSM in architecture body "cmd_fsm(rtl)"`)

### 3.3 แลป 1 — เปิดดูผล coverage สด

1. `Simulate > Start Simulation` → เลือก `tb_cmd_fsm` → ตั้งค่า
   `Enable code coverage` ในแท็บ `Others` → OK
2. `Simulate > Run > Run All` (หรือพิมพ์ `run -all` ในหน้าต่าง Transcript)
3. `View > Coverage > Code Coverage Analysis` (CLI: `view canalysis`)

หน้าต่าง **Code Coverage Analysis** จะแสดงตารางแยกตาม instance และแยกตาม metric:

```
     Enabled Coverage              Bins      Hits    Misses    Weight  Coverage
     ----------------              ----      ----    ------    ------  --------
     Branches                        25        18         7         1    72.00%
     Conditions                       5         3         2         1    60.00%
     Expressions                      5         2         3         1    40.00%
     FSM States                       4         3         1         1    75.00%
     FSM Transitions                  6         2         4         1    33.33%
     Statements                      25        21         4         1    84.00%
     Toggles                         56        42        14         1    75.00%
 Total coverage (filtered view): 62.76%
```

> เลขชุดนี้คือผลของ **test `basic` เพียง test เดียว** (บรรทัดที่ 2 ของภาคผนวก A)

**สิ่งที่ต้องลองทำในหน้าต่างนี้**

| การกระทำ | ผลลัพธ์ |
|---|---|
| คลิกที่แถวของ metric | แสดงรายละเอียดของ metric นั้น |
| ดับเบิลคลิกที่ item | เปิดหน้าต่าง **Coverage Details** (CLI: `view details`) |
| คลิกขวาที่ item → `Exclude` | ตัด item นั้นออกจากการคำนวณ (ดู 3.7) |
| ดูแถว `Excluded` | รายการที่ถูก exclude จะแยกออกมาให้เห็นชัด |
| กดไอคอน FSM | เปิดหน้าต่าง FSM View |

### 3.4 ดู coverage รายบรรทัดในหน้าต่าง Source

เปิดหน้าต่าง Source ที่ `rtl/cmd_fsm.v` แล้วมองที่คอลัมน์ coverage ทางขวา
จะเห็นสัญลักษณ์ต่อบรรทัด:

| สัญลักษณ์ | ความหมาย |
|---|---|
| (เครื่องหมายถูก) | บรรทัดนี้ถูกรันแล้ว / ถูก cover แล้ว |
| `X` | มี coverage หลายชนิดที่ยัง miss ในบรรทัดนี้ |
| `XB` | มี branch ที่ยังไม่ถูก hit |
| `XC` | มี condition ที่ยังไม่ถูก hit |
| `XE` | มี expression ที่ยังไม่ถูก hit |
| `XS` | มี statement ที่ยังไม่ถูก hit |
| `XT` | สาข true ยังไม่เคยเกิด (คอลัมน์ BC) |
| `XF` | สาข false ยังไม่เคยเกิด (คอลัมน์ BC) |

บรรทัดที่ยังไม่ถูกรันจะถูก **ไฮไลต์สีชมพู** ให้กดเมาส์ทับบรรทัดเพื่อดูตัวเลข
hit count ของแต่ละ metric

### 3.5 ดู FSM และ Toggle แยก

**FSM View:** คลิกไอคอนรูปเครื่องสถานะในหน้าต่าง Analysis หรือ
`View > Coverage > FSM View` (CLI: `view fsmlist`)

หน้าต่างนี้จะแสดง state machine เป็นกราฟ โดย:
- เครื่องหมายถูกสีเขียว = สถานะถูก cover แล้ว
- `X` = transition ที่ยังไม่เคยเดินผ่าน
- คลิกที่ state เพื่อดู transition ที่ออกจาก state นั้น

**Toggle Analysis:** เลือกแท็บ `Toggle` ในหน้าต่าง Analysis
จะเห็นรายการ node พร้อมคอลัมน์ `1H->0L` และ `0L->1H` ค่าที่ 0 ในคอลัมน์ใดคอลัมน์หนึ่ง
แปลว่า **สัญญาณนั้นยังไม่เคยเปลี่ยนค่าในทิศทางนั้น**

### 3.6 ตั้งเป้าหมาย (Coverage Goal)

> **ข้อจำกัดสำคัญ:** คำสั่ง `coverage goal` **ใช้ได้เฉพาะใน Coverage View mode**
> (ดูบทที่ 5.4) — ถ้าสั่งระหว่าง simulation ปกติ จะได้ข้อความ
> `Coverage sub-command 'goal' may be used in viewcov mode only.`

```bash
# ต้องอยู่ใน Coverage View mode
vsim -viewcov results/merged.ucdb
# VSIM> coverage goal -code b 95
# VSIM> coverage goal            <- แสดงเป้าหมายทั้งหมดที่ตั้งไว้
```

ผลลัพธ์ที่วัดได้:

```
#     Goal: 95.0   Coverage Type: Branch coverage, per instance
#     Goal: 95.0   Coverage Type: Branch coverage, per design unit
```

ใช้กับระบบ regression ที่ต้องการ "เข้าเกณฑ์ขั้นต่ำ" ก่อนปล่อยงาน

### 3.7 ตัดรายการที่ไม่สามารถ cover ออก (Exclude)

บาง item เป็น **ไปไม่ได้** ตามโครงสร้างของดีไซน์ (เช่น branch ที่เกิดไม่ได้)
การ exclude อย่างเหมาะสมเป็นส่วนหนึ่งของกระบวนการ coverage ที่ดี
แต่ต้อง **มีเหตุผลประกอบเสมอ**

**ทาง GUI**
- คลิกขวาที่ item ที่ miss ในหน้าต่าง Analysis → `Exclude Selection`
- คลิกขวาที่บรรทัดในคอลัมน์ Hits ของหน้าต่าง Source →
  `Exclude Coverage Line xxx`
- คลิกขวาที่ไฟล์ในหน้าต่าง Files → `Code Coverage > Exclude Selected File`

**ทาง Command line**

```bash
# ตัดทั้งบรรทัดของไฟล์หนึ่ง
coverage exclude -srcfile rtl/cmd_fsm.v -linerange 52

# ตัดเฉพาะ instance นั้น (instance-specific)
coverage exclude -scope /tb_cmd_fsm/dut -srcfile rtl/cmd_fsm.v -linerange 52

# ตัดเฉพาะ toggle node
coverage exclude -togglenode {b[3]} -scope /tb_cmd_fsm/dut
```

> **ระวังเรื่องวงเล็บปีกกาใน Tcl:** ชื่อ node ที่มีวงเล็บเหลี่ยม เช่น `b[3]`
> ต้องอยู่ในวงเล็บปีกกา `{ }` มิฉะนั้น Tcl จะพยายามรัน `b[3]` เป็นคำสั่งย่อยและจะเกิดข้อผิดพลาด
> (`coverage exclude -togglenode b[3] ...` → ผิดพลาด,
> `coverage exclude -togglenode {b[3]} ...` → ถูกต้อง)

**ทาง source code (pragma)** — เป็นวิธีที่เหมาะกับ regression มากที่สุด
เพราะ exclusion ติดไปกับซอร์สโค้ด ไม่หลุดหายเมื่อเปลี่ยนเครื่อง

```verilog
    // coverage off
    if (unreachable_condition) y = 1'b0;   // ไม่ถูกนับ
    // coverage on
```

> **ข้อจำกัดของ pragma ที่ต้องทราบ:**
> 1. ทำงาน **ระดับ design unit** เท่านั้น — วางไว้ก่อน architecture แล้ว
>    architecture ทั้งก้อนจะถูก exclude
> 2. **ใช้ exclude condition/expression ที่อยู่ภายในบรรทัดเดียวไม่ได้**
>    ถ้าต้องการจัดการระดับนั้นให้ใช้ `coverage exclude` แทน
> 3. ใน Verilog ใช้ `// coverage off` / `// coverage on`
>    ใน VHDL ใช้ `-- coverage off` / `-- coverage on`

> **สิ่งที่ไม่ควรทำ:** exclude เพื่อ "ทำให้ตัวเลขสวย" — ถ้า exclude แล้วตัวเลขเพิ่ม
> แปลว่าเราซ่อนช่องว่างที่อาจเป็นบั๊กจริง ให้ใช้ exclude เฉพาะกรณีที่พิสูจน์แล้วว่า
> เป็นไปไม่ได้จริง และเขียนเหตุผลกำกับเสมอ

---

## บทที่ 4 — Merging Code Coverage from different tests

### 4.1 ทำไมต้อง merge

ในการ verify จริง ไม่มี test เดียวที่ cover ทุกอย่างได้ — แต่ละ test มีหน้าที่เฉพาะ
การรวมผลของทุก test เข้าด้วยกันจึงเป็น "ความครอบคลุมของ regression ทั้งหมด"

```
  test basic ──┐
  test extra ──┼──►  merge  ──►  merged.ucdb  ──►  รายงานรวม
  test edge  ──┘
```

### 4.2 บันทึก coverage ของแต่ละ test เป็น UCDB

```bash
vsim -c -coverage -onfinish stop work.tb_cmd_fsm +TEST=basic \
     -do "run -all; coverage save results/basic.ucdb -codeAll -testname basic; quit -f"
```

| ส่วนของคำสั่ง | ความหมาย |
|---|---|
| `-coverage` | เก็บสถิติ coverage ระหว่าง simulate |
| `-onfinish stop` | **สำคัญมาก** — ดูคำเตือนด้านล่าง |
| `coverage save <file>` | บันทึกเป็นฐานข้อมูล UCDB |
| `-codeAll` | บันทึก coverage ทุกชนิด |
| `-testname <name>` | ติดป้ายชื่อ test ลงใน UCDB (ใช้รายงาน/จัดอันดับได้) |

> ### ⚠ กับดักที่พบบ่อยที่สุดของการรันแบบ batch
> เมื่อ testbench จบด้วย `$finish` ในโหมด `vsim -c` (command line)
> **simulator จะจบ session ทันที** และคำสั่งที่เหลือใน `-do "..."` จะ
> **ไม่ถูก execute เลย** — เช่น `coverage save` จะไม่ทำงาน
> โดยไม่มีข้อความ error ใด ๆ
>
> ทางแก้: ใส่ `-onfinish stop` เพื่อให้ simulator กลับมาที่ prompt
> เมื่อเจอ `$finish` แล้วค่อยทำคำสั่งที่เหลือต่อ
>
> **ตรวจสอบว่าเสียง:** ดูว่าไฟล์ `.ucdb` ถูกสร้างจริงหรือไม่
> (`dir results\*.ucdb`) และดูว่า transcript มีข้อความ
> `Coverage database has been saved successfully.`

### 4.3 Merge ด้วย vcover

```bash
vcover merge results/merged.ucdb results/basic.ucdb results/extra.ucdb results/edge.ucdb
```

| ตัวเลือก | ความหมาย |
|---|---|
| `-du <du_name>` | merge โดยอ้างอิง **design unit** แทน instance path (ใช้แก้กรณี instance path ไม่ตรงกัน) |
| `-instance <path>` | merge เฉพาะ instance ที่ระบุ |
| `-recursive` | รวม instance ทั้ง subtree |
| `-totals` / `-combine` | วิธีรวมค่าของ bin (รวม / สูงสุด / ต่ำสุด) |
| `-preservetestcounts` | เก็บจำนวน hit ของแต่ละ test ไว้ (ใช้กับ `ranktest`) |

**ผลลัพธ์ที่ได้**

| Metric | test basic | test extra | **หลัง merge** |
|---|---|---|---|
| Branches | 72.00% | 88.00% | **96.00%** |
| Conditions | 60.00% | 80.00% | **80.00%** |
| Expressions | 40.00% | 20.00% | **60.00%** |
| FSM States | 75.00% | 100.00% | **100.00%** |
| FSM Transitions | 33.33% | 66.66% | **66.66%** |
| Statements | 84.00% | 92.00% | **100.00%** |
| Toggles | 75.00% | 87.50% | **91.07%** |
| **Total** | 62.76% | 76.30% | **84.81%** |

> สังเกตว่า **ไม่มี test ไหนได้ 100%** แต่เมื่อ merge กันแล้วได้มากกว่าทั้งสอง test เพิ่มเติม
> และ **จำนวน bin ไม่เพิ่มขึ้น** (ยังเป็น 25 branches) → แปลว่าการ merge ทำงานถูกต้อง

### 4.4 Merge จาก GUI

1. `View > Verification Management > Browser` (CLI: `view browser`)
2. คลิกขวาในหน้าต่าง Browser → `Add File` → เลือก `results/basic.ucdb` และ `results/extra.ucdb`
3. เลือกไฟล์ UCDB ทั้งสอง (Ctrl คลิก) → คลิกขวา → `Merge`
4. กรอกชื่อไฟล์ผลลัพธ์ (ค่า default คือ `merge.ucdb`) → OK

### 4.5 ⚠ PITFALL: instance path ไม่ตรงกัน

**นี่คือข้อผิดพลาดที่พบบ่อยที่สุดในงานจริง และเป็นเรื่องที่ควรสาธิตในชั้นเรียน**

สมมติว่ามี testbench 2 ชุด คนละชื่อ — ซึ่งเป็นแนวปฏิบัติที่หลายคนใช้โดยไม่ทันระวัง

```verilog
module tb_cmd_fsm_basic;   cmd_fsm dut (...);   // → /tb_cmd_fsm_basic/dut
module tb_cmd_fsm_extra;   cmd_fsm dut (...);   // → /tb_cmd_fsm_extra/dut
```

เมื่อ merge ไฟล์ UCDB ของสอง test นี้เข้าด้วยกัน `vcover merge` จะมองว่าเป็น
**คนละ instance** จึง **บวกจำนวน bin เข้าหากัน** แทนที่จะรวม hit

| | ผลลัพธ์ที่ถูกต้อง (testbench เดียว) | ผลลัพธ์ที่ผิด (testbench สองชื่อ) |
|---|---|---|
| Number of Instances | 2 | **4** |
| Branches (bins) | 25 | **50** ← โตเป็น 2 เท่า |
| Toggles (bins) | 56 | **112** ← โตเป็น 2 เท่า |
| Total coverage | 84.81% | **69.53%** ← **ต่ำกว่า!** |

> **อ่านผลนี้ให้เข้าใจ:** ตัวเลขที่ "ดูเหมือนจะครบ" จริง ๆ แล้วมีครึ่งหนึ่งที่ยังไม่ถูก hit
> เพราะเครื่องมือกำลังนับ "สอง instance คนละตัว" ไม่ใช่ "instance เดียวที่ถูกทดสอบครบ"

### 4.6 วิธีแก้ไข

**ทางเลือกที่ 1 (แนะนำ) — ใช้ testbench เดียว + plusarg**

เก็บชื่อ testbench ให้เหมือนเดิมทุก test แล้วเลือก stimulus ด้วย plusarg
→ instance path เหมือนกันเสมอ → merge จะรวม hit ถูกต้อง

```verilog
// tb/tb_cmd_fsm.v
reg [8*16-1:0] test_name;
integer        plusarg_ok;
...
plusarg_ok = $value$plusargs("TEST=%s", test_name);
if      (test_name == "extra") run_extra_test;
else if (test_name == "edge")  run_edge_test;
else                           run_basic_test;
```

```bash
vsim -coverage work.tb_cmd_fsm +TEST=basic
vsim -coverage work.tb_cmd_fsm +TEST=extra
vsim -coverage work.tb_cmd_fsm +TEST=edge
```

> นี่คือแนวปฏิบัติมาตรฐานของ regression — ใช้ testbench ชุดเดียวกับทุก test
> เพื่อให้ coverage รวมกันได้ และเปลี่ยน stimulus ได้ตามต้องการ

**ทางเลือกที่ 2 — บังคับ merge ตาม design unit**

```bash
vcover merge -du work.cmd_fsm results/merged.ucdb results/pit_basic.ucdb results/pit_extra.ucdb
```

ผลลัพธ์ที่วัดได้: Number of Instances กลับเป็น 1, bins กลับเป็น 25 branches /
56 toggles, Total กลับเป็น **84.81%** เท่ากับกรณีที่ใช้ testbench เดียวพอดี

> ทางเลือกนี้ใช้ได้ แต่ระวัง: `-du` จะรวม **ทุก instance** ของ design unit นั้นเข้าด้วยกัน
> ถ้ามีหลาย instance จริง (เช่น `dut_core`, `dut_periph`) ต้องระวังว่าจะถูกรวมเข้าหากัน
> ในกรณีนั้นควรใช้ `-instance` ร่วมด้วย

### 4.7 จัดอันดับว่า test ไหนคุ้มที่สุด (Rank Test)

```bash
vcover ranktest -metric aggregate -codeAll results/basic.ucdb results/extra.ucdb results/edge.ucdb
```

```
Rank   TotalCov  Testname              Branch  Cond    Expr    Stmt    FSM_ST  FSM_TR  Toggle
-----  --------  --------------------  ------  ------  ------  ------  ------  ------  ------
    1     76.30  extra                  88.00   80.00   20.00   92.00  100.00   66.66   87.50
    2     97.20  edge                   92.00  100.00  100.00   92.00  100.00  100.00   96.42
    3    100.00  basic                 100.00  100.00  100.00  100.00  100.00  100.00  100.00
All 3 items have been ranked.

Ranking summary:
	Total Contributing Tests      = 3
	Total Non-Contributing Tests  = 0
	Total Coverage                = 100.00%
```

คอลัมน์ `TotalCov` เป็น **coverage สะสม** หลังรวม test ที่อยู่ในอันดับนั้น
ตัวเลขนี้ตอบคำถามว่า *"ถ้าจะตัด test ออกจาก regression ควรตัดตัวไหน"*
(ในตัวอย่างนี้ 3 test มีส่วนช่วยที่ไม่ซ้ำกัน จึงต้องใช้ทั้งสาม)

ตรวจสอบรายชื่อ test ที่ถูก merge มา:

```bash
vcover testnames results/merged.ucdb
basic
edge
extra
```

> **หมายเหตุ:** คำสั่ง `vcover ranktest` จะเขียนไฟล์ `ranktest.rank`,
> `ranktest.contrib` และ `ranktest.noncontrib` ไว้ใน **โฟลเดอร์ปัจจุบัน**
> ไฟล์เหล่านี้คือข้อมูลประกอบการจัดอันดับ ใช้ประกอบการวิเคราะห์ในรอบถัดไป

---

## บทที่ 5 — Generating Code Coverage Reports

### 5.1 รายงานแบบสรุป (Summary report)

```bash
vcover report -summary -codeAll results/merged.ucdb
```

```
Coverage Report Totals BY INSTANCES: Number of Instances 2
     Enabled Coverage              Bins      Hits    Misses    Weight  Coverage
     ----------------              ----      ----    ------    ------  --------
     Branches                        25        25         0         1   100.00%
     Conditions                       5         5         0         1   100.00%
     Expressions                      5         5         0         1   100.00%
     FSM States                       4         4         0         1   100.00%
     FSM Transitions                  6         6         0         1   100.00%
     Statements                      25        25         0         1   100.00%
     Toggles                         56        56         0         1   100.00%
Total coverage (filtered view): 100.00%
```

ตัวเลือกที่ใช้บ่อย:

| ตัวเลือก | ความหมาย |
|---|---|
| `-summary` | สรุปหนึ่งบรรทัดต่อ metric |
| `-details` | รายละเอียดทุก bin (ใช้ตอนต้องรู้ว่าอะไรยัง miss) |
| `-codeAll` | รวม coverage ทุกชนิด |
| `-code bcesft` | เลือกเฉพาะชนิดที่ต้องการ |
| `-instance=<path>` | จำกัดขอบเขต (เช่น `-instance=/tb_cmd_fsm/dut`) |
| `-output <file>` | บันทึกลงไฟล์แทนการพิมพ์ออกจอ |
| `-verbose` | รายละเอียดของ hit count ในแต่ละ bin |
| `-showexcluded` | แสดงรายการที่ถูก exclude |
| `-rankfile`, `-testdetails` | รายงานเชิงลึกของแต่ละ test |

### 5.2 รายงานแบบรายละเอียด (Detailed report)

```bash
vcover report -details -codeAll -output results/merged_detail.txt results/merged.ucdb
```

รายงานนี้เป็นหัวใจของการหา "อะไรยังไม่ถูก cover" เพราะมันบอก **บรรทัด** ที่ยัง miss

ตัวอย่างส่วนที่ยังไม่ถูก cover (หลัง merge แค่ 2 test) — โจทย์ของแบบฝึกหัดที่ 3:

```
------------------------------------IF Branch------------------------------------
    50                                         2     Count coming in to IF
    50              2                          2
                                         ***0***     All False Count
Branch totals: 1 hit of 2 branches = 50.00%
```

```
----------------Focused Condition View-------------------
Line       50 Item    1  (a == b)
Condition totals: 0 of 1 input term covered = 0.00%
  Input Term   Covered  Reason for no coverage   Hint
    (a == b)         N  '_0' not hit             Hit '_0'
     Rows:       Hits  FEC Target            Non-masking condition(s)
 Row   1:    ***0***  (a == b)_0            -
 Row   2:          2  (a == b)_1            -
```

```
    Uncovered Transitions :
Line            Trans_ID          Transition
----            --------          ----------
  60                   2          ST_EXEC -> ST_IDLE
  60                   4          ST_WAIT -> ST_IDLE
```

```
                                              Node      1H->0L      0L->1H  "Coverage"
                                              ---------------------------------------
                                              b[3]           0           0        0.00
                                            cmd[3]           0           0        0.00
                                             rst_n           0           2       50.00
Total Node Count     =         28
Toggled Node Count   =         25
Untoggled Node Count =          3
```

### 5.3 รายงานแบบ HTML

```bash
vcover report -html -codeAll -output results/html_report results/merged.ucdb
```

จะได้โฟลเดอร์ `results/html_report/` ที่เปิดด้วยเว็บเบราว์เซอร์ได้ทันที:

| ไฟล์ | เนื้อหา |
|---|---|
| `index.html` | หน้าแรกของรายงาน |
| `summary.html` | ตารางสรุปทั้งหมด |
| `statements.html`, `branches.html`, `condExp.html`, `toggles.html`, `fsm.html` | รายละเอียดราย metric |
| `sourceViewer.html` | **ตัวดูซอร์สเปคซอร์สโค้ด พร้อมคอลัมน์ hit** |
| `testRecords.html` | รายละเอียดของแต่ละ test ที่ merge มา |

**ทาง GUI**

- `Verification Browser > HTML Report` (เมนูหลัก) หรือ
- คลิกขวาที่ไฟล์ UCDB ในหน้าต่าง Browser → `HTML Report`
- หรือ `Tools > Coverage Report > HTML`

### 5.4 เปิดดูแบบ Coverage View mode

โหมดนี้โหลด UCDB เข้าไปใน simulator เพื่อ "เปิดดู" ข้อมูลที่ merge แล้ว
โดยไม่ต้องมี simulation ที่กำลังทำงาน

```bash
vsim -viewcov results/merged.ucdb
# หรือในโหมด GUI:
coverage open results/merged.ucdb
```

เมื่อเปิดในโหมดนี้ จะเห็นแท็บของไฟล์ UCDB ในหน้าต่าง และสามารถใช้
`coverage report`, `coverage exclude` (พร้อมใส่ comment ได้) และ
`coverage goal` กับข้อมูลที่ merge แล้วได้ทั้งหมด

ตรวจสอบว่าเปิดได้:

```bash
vsim -c -viewcov results/merged.ucdb -do "coverage report -summary -codeAll; quit -f"
```

### 5.5 รายงานจาก GUI

- คลิกขวาที่ item ในหน้าต่าง Instance Coverage → `Coverage Report`
- คลิกขวาที่ไฟล์หรือ instance ในหน้าต่าง Files / Structure →
  `Code Coverage > Code Coverage Reports`
- CLI ที่สมนัย: `coverage report` (ทำงานกับ session ปัจจุบัน)

---

## บทที่ 6 — ผลลัพธ์จริงทั้งหมด (Reference Results)

ตารางนี้เป็น **ค่าที่วัดได้จริง** บน ModelSim DE-64 / QuestaSim 2026.1
ด้วยไฟล์ที่แนบมา ใช้เป็นค่าอ้างอิงตอนตรวจงานนักเรียน

### 6.1 ผลของแต่ละ test (Verilog)

| Metric | test `basic` | test `extra` | test `edge` | **merged** |
|---|---|---|---|---|
| Branches | 72.00% | 88.00% | 68.00% | **100.00%** |
| Conditions | 60.00% | 80.00% | 80.00% | **100.00%** |
| Expressions | 40.00% | 20.00% | 80.00% | **100.00%** |
| FSM States | 75.00% | 100.00% | 75.00% | **100.00%** |
| FSM Transitions | 33.33% | 66.66% | 66.66% | **100.00%** |
| Statements | 84.00% | 92.00% | 76.00% | **100.00%** |
| Toggles | 75.00% | 87.50% | 71.42% | **100.00%** |
| **Total** | **62.76%** | **76.30%** | **73.87%** | **100.00%** |

### 6.2 ผลของภาษา VHDL (ภาคผนวก D)

| Metric | test `basic` | **merged (3 test)** |
|---|---|---|
| Branches | 70.96% (31 bins) | **100.00%** |
| Conditions | 75.00% (4 bins) | **100.00%** |
| Expressions | 50.00% (4 bins) | **100.00%** |
| FSM States | 75.00% (4 bins) | **100.00%** |
| FSM Transitions | 33.33% (6 bins) | **100.00%** |
| Statements | 84.84% (33 bins) | **100.00%** |
| Toggles | 77.94% (68 bins) | **100.00%** |
| **Total** | **66.72%** | **100.00%** |

> **ข้อสังเกตสำคัญ:** จำนวน bin ของภาษา VHDL **ไม่เท่ากับ** ภาษา Verilog
> (31 branch เทียบกับ 25, 33 statement เทียบกับ 25)
> เพราะโครงสร้าง `if/elsif/else` และ `case ... when others` ของ VHDL
> ถูกนับเป็น branch ต่างจาก Verilog
> **ตัวเลข bin ขึ้นกับภาษาและรูปแบบโค้ด ไม่ใช่ค่าคงที่สากล**

---

## บทที่ 7 — แบบฝึกหัด (Exercises)

### แบบฝึกหัดที่ 1 — ทำนายจำนวน bin

**โจทย์:** จากซอร์สโค้ด `rtl/cmd_fsm.v` ที่ให้มา (โดยยังไม่เคยรัน)
จงทำนายจำนวน bin ของแต่ละ metric แล้วเทียบกับผลจริงในตาราง 6.1

**เฉลย**

| Metric | ทำนาย | จริง | วิธีคิด |
|---|---|---|---|
| Statements | 25 | 25 | นับทุก assignment ที่มีผลกระทบจริง (รวมบรรทัด `next_state = state`) |
| Branches | 25 | 25 | `case(state)` 5 items + if 4 จุด×2 + `case(cmd)` 5 items + `if(en)` 2 + if ของ compare 3 ทาง + if ของ register 2 |
| Conditions | 5 | 5 | เงื่อนไขที่มีตัวแปรย่อย: `en` (บรรทัด 75), `a==b` (บรรทัด 50), `en && a>b` (92), `en && a==b` (93), และเงื่อนไข FSM |
| Expressions | 5 | 5 | `state==ST_DONE`, `a+b`, `a-b`, `a^b`, `(a[0]^b[0])&(a[1]\|b[1])` |
| FSM States | 4 | 4 | ST_IDLE, ST_EXEC, ST_WAIT, ST_DONE |
| FSM Transitions | 6 | 6 | 4 transition ตามการออกแบบ + 2 transition ที่เกิดจาก reset |
| Toggles | 56 | 56 | 28 node × 2 ทิศทาง (0→1 และ 1→0) |

> **บทเรียน:** จำนวน FSM transitions **มากกว่า** จำนวน states เสมอเมื่อมี reset
> และจำนวน toggle bins = จำนวนบิตที่สังเกตได้ × 2

### แบบฝึกหัดที่ 2 — อ่านรายงานและหาสาเหตุ

**โจทย์:** รันเฉพาะ `+TEST=basic` แล้วเปิดรายงานแบบ detail
จงระบุว่า **อะไรยังไม่ถูก cover และเพราะอะไร** สำหรับรายการต่อไปนี้

| รายการ | คำตอบ |
|---|---|
| บรรทัดใดของ `case (cmd)` ยังไม่ถูก hit | บรรทัด 79 (`4'h3`), 80 (`4'h4`), 81 (`default`) — เพราะ test basic ส่งเฉพาะ `4'h1` และ `4'h2` |
| FSM state ใดยังไม่ถูกเข้าถึง | `ST_DONE` — เพราะไม่มีการ trigger เงื่อนไข `a == b` ขณะอยู่ใน `ST_WAIT` |
| FSM transition ใดยังไม่เดินผ่าน | ทั้ง 4 รายการที่เหลือ ได้แก่ `ST_EXEC→ST_WAIT`(บางส่วน), `ST_WAIT→ST_DONE`, `ST_EXEC→ST_IDLE`(reset), `ST_WAIT→ST_IDLE`(reset) |
| toggle node ใดไม่เคยเปลี่ยนค่า | `b[3]`, `cmd[3]` (ไม่เคยถูกขับเป็น 1) และ `rst_n` (ไม่เคยกลับไปเป็น 0 หลังปล่อย reset) |
| expression ใดปิดยากที่สุด | `parity = (a[0]^b[0]) & (a[1]\|b[1])` — เพราะต้องควบคุมให้ `a[0]^b[0]` เป็น 1 ไม่งั้นผลลัพธ์จะถูก mask เป็น 0 ทั้งหมด |

### แบบฝึกหัดที่ 3 — เขียน test ที่ 3 ให้ปิด coverage ให้ครบ

**โจทย์:** จากผล merge ของ `basic` + `extra` (ยังไม่ถึง 100%) จงเพิ่ม test ที่ 3
ให้ปิดช่องว่างที่เหลือทั้งหมด

**เฉลย (ตรวจสอบด้วยการรันจริง — ผลลัพธ์ merged เป็น 100.00% ทุก metric)**

| ช่องว่าง | วิธีปิด |
|---|---|
| Branch/Condition บรรทัด 50 | อยู่ในสถานะ `ST_WAIT` ขณะที่ `a ≠ b` |
| FSM `ST_EXEC→ST_IDLE` | สั่ง reset ขณะ FSM อยู่ใน `ST_EXEC` |
| FSM `ST_WAIT→ST_IDLE` | สั่ง reset ขณะ FSM อยู่ใน `ST_WAIT` |
| Toggle `b[3]` | ขับ `b` ให้มีบิต 3 เป็น 1 แล้วกลับเป็น 0 |
| Toggle `cmd[3]` | ขับ `cmd` เป็น `4'h8` แล้วกลับเป็น `4'h0` |
| Toggle `rst_n` | สั่ง reset ซ้ำ (1→0→1) |
| Expression `a[1]`, `b[1]` | ใช้ค่าที่ `a[0] ≠ b[0]` (เช่น `a=4'b0000, b=4'b0001` และ `a=4'b0010, b=4'b0001`) เพื่อไม่ให้ผลลัพธ์ถูก mask |

โค้ดที่ใช้ (เพิ่มใน `tb/tb_cmd_fsm.v`):

```verilog
    task pulse_reset;
        begin
            @(negedge clk);
            rst_n = 1'b0;
            @(posedge clk);
            @(negedge clk);
            rst_n = 1'b1;
        end
    endtask

    task run_edge_test;
        begin
            // expression coverage : ต้องทำให้ a[0] != b[0]
            step(4'h0, 4'b0000, 4'b0001, 1'b1);
            step(4'h0, 4'b0010, 4'b0001, 1'b1);
            // toggle coverage : cmd[3] และ b[3]
            step(4'h8, 4'd8,  4'd12, 1'b1);
            step(4'h0, 4'd8,  4'd0,  1'b1);
            // reset ขณะอยู่ใน ST_EXEC
            step(4'h0, 4'd1,  4'd2,  1'b1);
            pulse_reset;
            // อยู่ใน ST_WAIT ขณะ a != b
            step(4'h0, 4'd1,  4'd2,  1'b1);
            step(4'h0, 4'd1,  4'd2,  1'b0);
            step(4'h0, 4'd1,  4'd2,  1'b0);
            // reset ขณะอยู่ใน ST_WAIT
            pulse_reset;
        end
    endtask
```

### แบบฝึกหัดที่ 4 — จัดการกรณี instance path ไม่ตรง

**โจทย์:** จากโฟลเดอร์ `tb/pitfall/` มี testbench 2 ชุดที่ใช้ชื่อต่างกัน
จง merge เข้าด้วยกัน จงอธิบายว่าเหตุใดตัวเลขที่ได้จึง "ดูผิด" และหาวิธีแก้ 2 วิธี

**เฉลย**

| | ผลที่ได้ |
|---|---|
| merge ตามปกติ | Number of Instances = **4**, Branches = **50 bins**, Total = **69.53%** |
| แก้โดยใช้ testbench เดียว + plusarg | Instances = 2, Branches = 25 bins, Total = **84.81%** |
| แก้โดย `vcover merge -du work.cmd_fsm` | Instances = 1, Branches = 25 bins, Total = **84.81%** |

### แบบฝึกหัดที่ 5 — ออกแบบ testbench สำหรับงานจริง

**โจทย์:** ออกแบบ regression ของโมดูล UART 8-bit ที่มี
FSM (IDLE→RECV→PARITY→DONE) และ parity logic โดยตอบคำถามต่อไปนี้

1. จะใช้ testbench เดียวหรือหลายชุด? เพราะอะไร?
2. จะเลือก stimulus ด้วยวิธีใด (plusarg / define / config)?
3. FSM transition กี่เส้นที่ควรเป็น และจะมี transition จาก reset กี่เส้น?
4. จะตั้ง coverage goal เท่าไร และจะ exclude อะไรบ้าง (พร้อมเหตุผล)?

**เฉลยแนวทาง**

1. **testbench เดียว** เพื่อให้ instance path คงที่ → merge ได้ถูกต้อง
2. ใช้ **plusarg** (`+TEST=...`) เพราะไม่ต้องคอมไพล์ใหม่ → regression เร็วกว่า
   และยืนยันว่าใช้ binary ชุดเดียวกันทั้งหมด
3. 4 states → 4 transition ตามการออกแบบ + 3 transition จาก reset
   (ออกจากทุก state ยกเว้น IDLE) = **7 transitions**
4. ตั้ง goal: `coverage goal -code b 100` และ `-code s 100`
   exclude เฉพาะ: branch ที่เกิดจาก error path ที่ไม่มีในระบบจริง,
   toggle node ของสัญญาณที่ testbench ควบคุมโดยตรง

---

## บทที่ 8 — ปัญหาที่พบบ่อย (Troubleshooting)

| อาการ | สาเหตุ | วิธีแก้ |
|---|---|---|
| Coverage เป็น 0% ทั้งหมด | คอมไพล์โดยไม่มี `+cover=` | คอมไพล์ใหม่ด้วย `+cover=bcesft` |
| Coverage เป็น 0% แม้คอมไพล์แล้ว | simulate โดยไม่มี `-coverage` | เพิ่ม `-coverage` ตอน `vsim` |
| ไม่มีข้อความ `Recognized 1 FSM` | ไม่ได้ใส่ `+cover=f` หรือรูปแบบ FSM ไม่ถูกต้อง | เพิ่ม `f` ใน `+cover=` และเขียน FSM ให้เป็น state register + next-state logic |
| ไฟล์ `.ucdb` ไม่ถูกสร้าง | `$finish` จบ session ในโหมด `-c` ก่อนถึงคำสั่ง `coverage save` | ใส่ `-onfinish stop` |
| ตัวเลข bin โตเป็น 2 เท่าหลัง merge | instance path ของ test ต่างกัน | ใช้ testbench เดียว หรือ `vcover merge -du <du>` |
| ตัวเลขรวม **ลดลง** หลัง merge | อาการเดียวกับข้างบน | เช่นเดียวกัน |
| ตัวเลขต่างกันทุกครั้งที่รัน | คอมไพล์ testbench เข้าไปใน coverage ด้วย | คอมไพล์ testbench โดยไม่ใส่ `+cover=` |
| รายงานไม่มี toggle ของสัญญาณบางตัว | สัญญาณไม่เคยเปลี่ยนค่า | ตรวจในรายงาน detail ว่าค่าไหนเป็น 0 แล้วเพิ่ม stimulus |
| `vcover report -html` ไม่ออกไฟล์ | ไม่ได้ใส่ `-output` | `vcover report -html -codeAll -output <dir> <file.ucdb>` |
| ข้อความ `Personal Edition doesn't support verification plan` | ใบอนุญาตเป็นรุ่น Personal | เป็นข้อความเตือน ไม่กระทบรายงาน code coverage |
| คำสั่ง `coverage exclude` ไม่มีผล | ต้องระบุ `-srcfile` เมื่อใช้ `-linerange` | `coverage exclude -srcfile <file> -linerange <n>` |
| `coverage exclude -togglenode b[3]` ผิดพลาด | Tcl ตีความ `[3]` เป็นคำสั่งย่อย | ใส่วงเล็บปีกกา: `-togglenode {b[3]}` |
| `coverage goal` ขึ้นว่า *"may be used in viewcov mode only"* | คำสั่งนี้ใช้ได้เฉพาะใน Coverage View mode | `vsim -viewcov <file>.ucdb` แล้วสั่งซ้ำ |

---

## ภาคผนวก A — คำสั่งทั้งหมด (Command Reference)

### A.1 คอมไพล์

```bash
vlib work
vmap work work
vlog -work work rtl/cmd_fsm.v +cover=bcesft      # DUT พร้อม coverage
vlog -work work tb/tb_cmd_fsm.v                   # TB ไม่ต้องมี coverage
vcom -2008 -work vhdl_work vhdl/cmd_fsm.vhd +cover=bcesft
vcom -2008 -work vhdl_work vhdl/tb_cmd_fsm.vhd
```

### A.2 รันและบันทึก

```bash
vsim -coverage work.tb_cmd_fsm +TEST=basic
vsim -c -coverage -onfinish stop work.tb_cmd_fsm +TEST=basic \
     -do "run -all; coverage save results/basic.ucdb -codeAll -testname basic; quit -f"

vsim -c -coverage -onfinish stop vhdl_work.tb_cmd_fsm -gTEST=basic \
     -do "run -all; coverage save results/vhdl_basic.ucdb -codeAll -testname vbasic; quit -f"
```

### A.3 รายงาน

```bash
coverage report -summary -codeAll -instance=/tb_cmd_fsm/dut
coverage report -details -codeAll -output results/merged_detail.txt results/merged.ucdb
vcover report -summary -codeAll results/merged.ucdb
vcover report -details -codeAll -output results/merged_detail.txt results/merged.ucdb
vcover report -html -codeAll -output results/html_report results/merged.ucdb
```

### A.4 Merge และวิเคราะห์

```bash
vcover merge results/merged.ucdb results/basic.ucdb results/extra.ucdb results/edge.ucdb
vcover merge -du work.cmd_fsm results/merged.ucdb results/a.ucdb results/b.ucdb
vcover testnames results/merged.ucdb
vcover ranktest -metric aggregate -codeAll results/basic.ucdb results/extra.ucdb results/edge.ucdb
vsim -viewcov results/merged.ucdb
coverage open results/merged.ucdb
```

### A.5 Exclude และ Goal

```bash
coverage exclude -srcfile rtl/cmd_fsm.v -linerange 52
coverage exclude -scope /tb_cmd_fsm/dut -srcfile rtl/cmd_fsm.v -linerange 52
coverage exclude -togglenode {b[3]} -scope /tb_cmd_fsm/dut
coverage goal -code b 95      # ต้องอยู่ใน Coverage View mode
coverage goal
```

### A.6 เรียกดูหน้าต่างในโหมด GUI

```bash
view canalysis        # Code Coverage Analysis
view details         # Coverage Details
view fsmlist         # FSM List
view browser         # Verification Management Browser
```

---

## ภาคผนวก B — เทียบ GUI กับ Command line

| งาน | GUI | CLI |
|---|---|---|
| เปิดใช้ coverage ตอนคอมไพล์ | `Compile > Compile Options > Coverage tab` | `vlog ... +cover=bcesft` |
| เปิดใช้ coverage ตอน simulate | `Simulate > Start Simulation > Others > Enable code coverage` | `vsim -coverage <design>` |
| เปิดหน้าต่าง Analysis | `View > Coverage > Code Coverage Analysis` | `view canalysis` |
| เปิดหน้าต่าง Details | `View > Coverage > Details` | `view details` |
| เปิดหน้าต่าง FSM | คลิกไอคอน FSM ใน Analysis | `view fsmlist` |
| บันทึก UCDB | `Tools > Coverage Save` | `coverage save <file>.ucdb -codeAll` |
| โหลด UCDB | `View > Verification Management > Browser` → `Add File` | `coverage open <file>.ucdb` / `vsim -viewcov <file>.ucdb` |
| Merge | Browser → เลือกไฟล์ → `Merge` | `vcover merge <out> <in1> <in2> ...` |
| สร้างรายงาน HTML | `Verification Browser > HTML Report` | `vcover report -html -output <dir> <file>.ucdb` |
| Exclude | คลิกขวาที่ item → `Exclude Selection` | `coverage exclude ...` |
| โหลดแบบพร้อม coverage | คลิกขวาที่ design unit → `Simulate with Coverage` | `vsim -coverage <design>` |

---

## ภาคผนวก C — การทำซ้ำทั้งหมด (Reproduce)

```bash
cd questa_code_coverage_lab
set PATH=C:\Siemens\modelsim_dlx64_2026.1\win64pe;%PATH%     # ปรับตามเครื่อง

scripts\run_all.cmd       # flow ของ Verilog  -> results/merged.ucdb + รายงาน HTML
scripts\run_vhdl.cmd      # flow ของ VHDL     -> results/vhdl_merged.ucdb + รายงาน HTML
```

หรือทีละขั้น (เหมาะกับการเรียนรู้):

```bash
vsim -c -do "do scripts/compile.do"
vsim -c -coverage -onfinish stop work.tb_cmd_fsm +TEST=basic -do "do scripts/lab1_test_basic.do"
vsim -c -coverage -onfinish stop work.tb_cmd_fsm +TEST=extra -do "do scripts/lab2_test_extra.do"
vsim -c -do "do scripts/lab3_merge.do"
vsim -c -do "do scripts/lab4_report.do"
```

---

## ภาคผนวก D — เวอร์ชันภาษา VHDL

DUT และ testbench ภาษา VHDL อยู่ในโฟลเดอร์ `vhdl/`
ใช้โครงสร้างเดียวกับเวอร์ชัน Verilog แต่มีข้อแตกต่างที่ต้องรู้:

| หัวข้อ | Verilog | VHDL |
|---|---|---|
| เลือก test | plusarg `+TEST=basic` | generic `-gTEST=basic` |
| สร้าง library | `work` | `vhdl_work` (แยก เพราะชื่อ entity ชนกัน) |
| มาตรฐาน | Verilog-2001 | VHDL-2008 (`vcom -2008`) เพื่อให้ใช้ `to_hstring` ได้ |
| FSM state | `reg [1:0]` + `localparam` | `type state_t is (...)` (แนวปฏิบัติที่ดีกว่า) |
| โครงสร้าง case | `case (cmd)` | `case cmd is when "0001" => ...` |
| pragma exclude | `// coverage off` | `-- coverage off` |

**คำสั่งที่ใช้**

```bash
vlib vhdl_work
vmap vhdl_work vhdl_work
vcom -2008 -work vhdl_work vhdl/cmd_fsm.vhd +cover=bcesft
vcom -2008 -work vhdl_work vhdl/tb_cmd_fsm.vhd

vsim -c -coverage -onfinish stop vhdl_work.tb_cmd_fsm -gTEST=basic \
     -do "run -all; coverage save results/vhdl_basic.ucdb -codeAll -testname vbasic; quit -f"

vcover merge results/vhdl_merged.ucdb results/vhdl_basic.ucdb results/vhdl_extra.ucdb results/vhdl_edge.ucdb
vcover report -summary -codeAll results/vhdl_merged.ucdb
```

> **ข้อสังเกตที่ต้องให้นักเรียนสังเกต:** จำนวน bin ของ VHDL **ไม่เท่ากับ** Verilog
> (ดูตาราง 6.2) เพราะโครงสร้างภาษาต่างกัน — ไม่ควรเปรียบเทียบตัวเลขข้ามภาษาโดยตรง

---

## ภาคผนวก E — ข้อควรจำสรุป (Checklist)

ก่อนปิดงาน ตรวจสอบว่า:

- [ ] คอมไพล์ RTL ด้วย `+cover=bcesft` และเห็นข้อความ `Recognized 1 FSM`
- [ ] simulate ด้วย `vsim -coverage`
- [ ] ใช้ `-onfinish stop` เมื่อรันแบบ batch
- [ ] ตรวจสอบว่าไฟล์ `.ucdb` ถูกสร้างจริงหลัง `coverage save`
- [ ] ตรวจสอบ **instance path** เหมือนกันทุก test ก่อน merge
- [ ] ตรวจสอบ `Number of Instances` ในรายงานหลัง merge ว่าไม่ได้เพิ่มขึ้นเป็น 2 เท่า
- [ ] ใช้ `vcover report -details` เพื่อหาว่า **อะไร** ยังไม่ถูก cover ไม่ใช่แค่ดูเปอร์เซ็นต์
- [ ] อ่านเหตุผลที่ miss ก่อนตัดสินใจ exclude
- [ ] ทุก item ที่ exclude ต้องมีเหตุผลประกอบเสมอ
- [ ] ยืนยันว่า code coverage 100% ควรไปคู่กับ functional coverage ที่ครบด้วย
