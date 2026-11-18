# ไฟล์ประกอบแบบฝึกหัด (labs)

ไฟล์ทั้งหมดในโฟลเดอร์นี้ **ผ่านการตรวจสอบด้วยการรันจริงแล้ว** ด้วย GHDL 5.0.1
ผลที่ได้แสดงไว้ในหัวข้อ "ผลที่ตรวจสอบแล้ว" ด้านล่าง

> **ข้อสำคัญบน Windows**: ต้องคัดลอกโฟลเดอร์นี้ไปไว้ในพาธที่เป็น ASCII ล้วนก่อนรัน GHDL
> เพราะ GHDL เก็บพาธไฟล์ต้นทางลงใน work library และพาธภาษาไทยจะทำให้คอมไพล์ไม่ผ่าน
> (ดูรายละเอียดในบทที่ 0 หัวข้อ 0.3.3)

---

## 1. รายการไฟล์

| ไฟล์ | ประเภท | ใช้ในบทไหน | หน้าที่ |
|---|---|---|---|
| `rtl/alu8.vhd` | RTL | 1, 2, 3, 4, 5 | หน่วยคำนวณ 8 บิตแบบมีเครื่องหมาย มีทะเบียน zero/overflow |
| `rtl/hex2seg.vhd` | RTL | 1, 2, 4 | ถอดเลขฐาน 16 เป็นรูปแบบจอ 7 ส่วน |
| `rtl/sync_fifo.vhd` | RTL | 1 | FIFO แบบตรง 8 ช่อง × 32 บิต ใช้ตัวชี้แบบ Gray code |
| `rtl/int8_mac.vhd` | RTL | 1, 2, 5 | หน่วยคูณสะสม INT8 แบบไปป์ไลน์ 2 ขั้น พร้อม backpressure |
| `rtl/top_alu8.vhd` | RTL | 2, 3, 4, 5 | โมดูลบนสุดสำหรับบอร์ด Nexys A7-100T |
| `tb/alu_ref_pkg.vhd` | แพ็กเกจ | 1 | แบบจำลองอ้างอิงของ ALU (คำนวณด้วยเลขจำนวนเต็ม คนละวิธีกับ RTL) |
| `tb/tb_alu8.vhd` | testbench | 1 | ตรวจ ALU ครบทุกคำสั่ง 47,104 เคส |
| `tb/tb_sync_fifo.vhd` | testbench | 1 | ตรวจ FIFO: เขียนครบ/เขียนเกิน/อ่านคืน/เขียนอ่านสลับ |
| `tb/tb_int8_mac.vhd` | testbench | 1 | ตรวจ MAC พร้อม backpressure แบบสุ่มด้วย LFSR 70 ธุรกรรม |
| `tb/tb_top_alu8.vhd` | testbench | 1, 4 | ตรวจโมดูลบนสุดระดับบอร์ด 1,026 เคส รวมการรีเซ็ต |
| `sdc/top_alu8.sdc` | เงื่อนไข | 2, 3, 4, 5 | เงื่อนไขเวลาสำหรับบอร์ด (คาบเวลา 10 ns) |
| `sdc/top_alu8_8ns.sdc` | เงื่อนไข | 5 | เงื่อนไขเวลาแบบเข้มขึ้น (คาบเวลา 8 ns) สำหรับการทดลองเปรียบเทียบ |
| `precision/ps_build.tcl` | สคริปต์ | 2, 5 | สคริปต์หลักของ Precision: ตั้งค่า → Compile → Synthesize → รายงาน → ส่ง EDIF |
| `precision/ps_qor_10ns.tcl` | สคริปต์ | 5 | รอบทดลองที่ 1 (10 ns) |
| `precision/ps_qor_8ns.tcl` | สคริปต์ | 5 | รอบทดลองที่ 2 (8 ns) |
| `vivado/nexys_a7_100t.xdc` | ข้อจำกัด | 4, 5 | ผูกพอร์ตกับพินจริงบนบอร์ด + ข้อกำหนดเวลา |
| `vivado/run_pnr.tcl` | สคริปต์ | 4, 5 | อ่าน EDIF → place → route → รายงาน → เรียกเกณฑ์ sign-off |
| `vivado/check_signoff.tcl` | สคริปต์ | 4, 5 | เกณฑ์ตรวจรับงาน: setup, hold, DRC, unconstrained paths |
| `results/qor_results_template.md` | แบบฟอร์ม | 5 | ตารางบันทึกผลและคำถามวิเคราะห์ของบทที่ 5 |

---

## 2. วิธีใช้งาน

### 2.1 จำลองด้วย QuestaSim / ModelSim

ใช้โหมด Transcript (บรรทัดคำสั่ง)

```text
:: เปลี่ยนเข้าโฟลเดอร์ labs
vlib work
vcom -2008 tb/alu_ref_pkg.vhd
vcom -2008 rtl/alu8.vhd rtl/hex2seg.vhd rtl/sync_fifo.vhd rtl/int8_mac.vhd rtl/top_alu8.vhd
vcom -2008 tb/tb_alu8.vhd
vsim -c work.tb_alu8 -do "run -all; quit -f"
```

ทำซ้ำสำหรับ testbench อีก 3 ตัว

```text
vcom -2008 tb/tb_sync_fifo.vhd
vsim -c work.tb_sync_fifo -do "run -all; quit -f"
vcom -2008 tb/tb_int8_mac.vhd
vsim -c work.tb_int8_mac -do "run -all; quit -f"
vcom -2008 tb/tb_top_alu8.vhd
vsim -c work.tb_top_alu8 -do "run -all; quit -f"
```

ผลที่ถูกต้องต้องลงท้ายด้วยคำว่า `PASS`

### 2.2 จำลองด้วย GHDL (ไม่ต้องมีใบอนุญาต)

```powershell
# Windows: ต้องคัดลอกไปพาท ASCII ก่อน
$src = "C:\...\Precision-Synthesis-QuickStart-TH\labs"
$dst = "C:\ps_labs"
New-Item -ItemType Directory -Force -Path "$dst\rtl","$dst\tb" | Out-Null
Copy-Item "$src\rtl\*.vhd" "$dst\rtl\" -Force
Copy-Item "$src\tb\*.vhd"  "$dst\tb\"  -Force
Set-Location $dst

ghdl -a --std=08 tb/alu_ref_pkg.vhd
ghdl -a --std=08 rtl/alu8.vhd rtl/hex2seg.vhd rtl/sync_fifo.vhd rtl/int8_mac.vhd rtl/top_alu8.vhd
ghdl -a --std=08 tb/tb_alu8.vhd
ghdl -a --std=08 tb/tb_sync_fifo.vhd
ghdl -a --std=08 tb/tb_int8_mac.vhd
ghdl -a --std=08 tb/tb_top_alu8.vhd

ghdl -e --std=08 tb_alu8       ; ghdl -r --std=08 tb_alu8       --assert-level=error
ghdl -e --std=08 tb_sync_fifo  ; ghdl -r --std=08 tb_sync_fifo  --assert-level=error
ghdl -e --std=08 tb_int8_mac   ; ghdl -r --std=08 tb_int8_mac   --assert-level=error
ghdl -e --std=08 tb_top_alu8   ; ghdl -r --std=08 tb_top_alu8   --assert-level=error
```

บน Linux / macOS:

```bash
cd labs
ghdl -a --std=08 tb/alu_ref_pkg.vhd
ghdl -a --std=08 rtl/*.vhd
ghdl -a --std=08 tb/*.vhd
ghdl -e --std=08 tb_alu8 && ghdl -r --std=08 tb_alu8 --assert-level=error
```

### 2.3 สังเคราะห์ด้วย Precision

```bash
cd labs/precision
ps_shell -f ps_qor_10ns.tcl     # รอบที่ 1: เป้าหมาย 10 ns
ps_shell -f ps_qor_8ns.tcl      # รอบที่ 2: เป้าหมาย 8 ns
```

ผลลัพธ์จะอยู่ใน `out_10ns/` และ `out_8ns/` ตามลำดับ ได้แก่

```text
out_10ns/
├── top_alu8.edif      ← เน็ตลิสต์สำหรับ Vivado
├── top_alu8.sdc       ← เงื่อนไขเวลา
├── timing.rpt         ← รายงานเวลา
├── unconstrained.rpt  ← รายงานเส้นทางที่ไม่ถูกจำกัด
└── area.rpt           ← รายงานการใช้ทรัพยากร
```

> **ข้อควรรู้**: ชื่อคำสั่งใน Precision ขึ้นกับรุ่น
> วิธีที่ปลอดภัยที่สุดคือทำขั้นตอนเดียวกันใน GUI แล้วใช้ `File > Save Command File`
> (ตรวจสอบกับเอกสารของรุ่นที่ใช้)

### 2.4 ส่งต่อไป Vivado

```bash
cd labs/vivado

# แก้บรรทัด edif_file ใน run_pnr.tcl ให้ชี้ไปที่เน็ตลิสต์ที่ต้องการ
#   set edif_file "../precision/out_10ns/top_alu8.edif"
vivado -mode batch -source run_pnr.tcl
```

ผลลัพธ์

```text
vivado_out/
├── timing_summary.rpt     ← ตัวเลข setup/hold ที่ใช้ตัดสินได้
├── utilization.rpt
├── drc.rpt
├── methodology.rpt
├── signoff_report.txt     ← ผลของเกณฑ์ sign-off
└── top_alu8.bit           ← สร้างเฉพาะเมื่อผ่านเกณฑ์เท่านั้น
```

---

## 3. ผลที่ตรวจสอบแล้ว

ผลล่าสุดจากการรันจริง (GHDL 5.0.1)

```text
=== tb_alu8 ===
tb_alu8: checked 47104 cases, errors 0
PASS

=== tb_sync_fifo ===
tb_sync_fifo: checked 16 items, errors 0
PASS

=== tb_int8_mac ===
tb_int8_mac: sent 70 transactions, received 70
PASS

=== tb_top_alu8 ===
tb_top_alu8: checked 1026 cases, errors 0
PASS
```

### 3.1 บั๊กจริง 5 จุดที่พบระหว่างทำแล็บนี้ (ควรอ่านด้วย)

การตรวจสอบด้วยการรันจริงพบข้อผิดพลาดที่การอ่านโค้ดอย่างเดียวมักไม่พบ
ทั้งหมดนี้ถูกแก้แล้วในไฟล์ที่ส่งมอบ และเป็นบทเรียนที่ควรสอนนักศึกษา

**ข้อที่ 1 — process ที่ไวต่อนาฬิกาขาด `rising_edge(clk)` (rtl/sync_fifo.vhd, rtl/int8_mac.vhd)**

```vhdl
-- ผิด: ทำงานทั้งขอบขึ้นและขอบลง ตัวชี้เดินสองครั้งต่อรอบนาฬิกา
process (clk, rst_n)
begin
  if rst_n = '0' then
    wr_ptr <= (others => '0');
  else
    wr_ptr <= wr_ptr + 1;      -- เดินเร็วเป็นสองเท่า
  end if;
end process;

-- ถูก
process (clk, rst_n)
begin
  if rst_n = '0' then
    wr_ptr <= (others => '0');
  elsif rising_edge(clk) then
    wr_ptr <= wr_ptr + 1;
  end if;
end process;
```

**อาการที่พบ**: FIFO ขนาด 8 ช่อง "เต็ม" หลังเขียนเพียง 4 ค่า
และตัวสะสม INT8 MAC ให้ผลเป็นสองเท่าของที่ถูกต้อง
**บั๊กนี้อันตรายมาก** เพราะผลจำลองกับผลสังเคราะห์จะ "ผ่าน" ทั้งที่การทำงานบนฮาร์ดแวร์ผิด

**ข้อที่ 2 — ใช้ `(others => '0')` ใน expression (rtl/alu8.vhd, tb/alu_ref_pkg.vhd)**

```vhdl
-- ผิด: "others' choice not allowed for an aggregate in this context"
if y_v = (others => '0') then

-- ถูก
constant ZERO_VAL : signed(W-1 downto 0) := (others => '0');
if y_v = ZERO_VAL then
```

**ข้อที่ 3 — อักษรไทยใน string literal (tb/tb_alu8.vhd)**

```vhdl
-- ผิด: GHDL/ModelSim รายงาน "invalid character not allowed, even in a string"
report "ผิดพลาด: a=" & integer'image(a_v);

-- ถูก: ใช้ภาษาอังกฤษในข้อความ ส่วนคำอธิบายไทยไว้ใน comment
report "MISMATCH y: a=" & integer'image(a_v);
```

**ข้อที่ 4 — สลับลำดับ operand เพราะเข้าใจผิดว่าการต่อสัญญาณเอา A ไว้บิตต่ำ (tb/tb_top_alu8.vhd)**

```vhdl
-- ผิด: SW[15:8] ได้ค่า a และ SW[7:0] ได้ค่า b (สลับกัน)
sw <= std_logic_vector(byte_of(a_i) & byte_of(b_i));

-- ถูก: ใน VHDL "A & B" เอา A ไว้ที่บิตสูงกว่า
sw <= std_logic_vector(byte_of(b_i) & byte_of(a_i));
```

**อาการที่พบ**: คำสั่ง ADD ผ่านทุกเคส (เพราะสลับตัวก็ได้ผลเท่ากัน)
แต่คำสั่ง SUB ผิดทั้งหมด ถ้า test มีแต่ ADD จะไม่พบบั๊กนี้เลย

**ข้อที่ 5 — ส่งค่า byte ดิบเข้าแบบจำลองที่ตีความแบบมีเครื่องหมาย (tb/tb_alu8.vhd)**

```vhdl
-- ผิด: ref_alu ตีความ 128 ว่าเป็น +128 แต่ RTL ตีความว่า -128
ref_alu(ai, B_LIST(bi), op_v, y_exp, ovf_exp, zero_exp);

-- ถูด: แปลงเป็นค่าที่มีเครื่องหมายก่อน
a_v := int_of(byte_of(ai));
b_v := int_of(byte_of(B_LIST(bi)));
ref_alu(a_v, b_v, op_v, y_exp, ovf_exp, zero_exp);
```

**อาการที่พบ**: แฟล็ก overflow ผิดเฉพาะกรณีที่มีบิตที่ 7 เป็น 1

### 3.2 ข้อจำกัดของเครื่องมือที่พบ (ไม่ใช่บั๊กของโค้ด)

**GHDL ไม่รองรับพาธที่มีอักษรไทย**

```text
work-obj08.cf:2:35:error: invalid character not allowed, even in a string
file "C:\Users\...\งานเขียน\...\alu_ref_pkg.vhd" ...
```

GHDL บันทึกพาธไฟล์ต้นทางแบบ absolute ลงใน work library
ซึ่งเป็นไฟล์ที่ต้องเขียนด้วยอักขระ basic character set
**ทางแก้**: คัดลอกไฟล์ไปไว้ในพาทที่เป็น ASCII ล้วนก่อนรัน
(ModelSim/QuestaSim ไม่มีข้อจำกัดนี้)

---

## 4. การทดสอบบนฮาร์ดแวร์จริง

หลังสร้าง bitstream สำเร็จ ให้ทดสอบตามตารางนี้

| ทดสอบ | วิธีทำ | ผลที่คาดหวัง |
|---|---|---|
| นาฬิการะบบ | สังเกตจอ 7 ส่วน | เปลี่ยนประมาณ 1,526 ครั้งต่อวินาที |
| การบวก | SW[7:0]=5, SW[15:8]=3, BTN=ADD | LED[7:0] = 0x08, จอแสดง "08" |
| การลบ | SW[7:0]=5, SW[15:8]=3, BTN=SUB | LED[7:0] = 0x02 |
| แฟล็ก zero | ตั้ง operand เป็น 0 | LED[8] ติด |
| แฟล็ก overflow | ตั้ง 127 + 1 | LED[9] ติด, ผลเป็น 0x80 |
| รีเซ็ต | กดปุ่มที่พิน C12 | LED และจอถูกล้างเป็นศูนย์ |

---

## 5. สิ่งที่ยังไม่ได้ตรวจสอบด้วยการรันจริง

รายการต่อไปนี้ **ต้องใช้เครื่องมือที่มีใบอนุญาต** จึงยังไม่ได้รันตรวจสอบ
ในครั้งที่จัดทำคู่มือ ให้ผู้เรียนเป็นผู้ตรวจสอบและบันทึกผล

| รายการ | เครื่องมือที่ต้องใช้ | หมายเหตุ |
|---|---|---|
| ผลสังเคราะห์จริง (LUT/FF/ตัวเลขเวลา) | Precision Synthesis | ขึ้นกับรุ่นและค่าคอนฟิก |
| เน็ตลิสต์ EDIF ที่ใช้งานได้ | Precision Synthesis + Vivado | ขึ้นกับไลบรารีอุปกรณ์ที่เลือก |
| ตัวเลข post-route | Vivado | ขึ้นกับรุ่นและ seed ของการวางวาง |
| ผลของเกณฑ์ sign-off | Vivado | ต้องปรับตัวแปรตามรุ่น |

> คู่มือนี้ระบุไว้ชัดเจนเพื่อไม่ให้ผู้เรียนเข้าใจผิดว่าตัวเลขในบทต่าง ๆ
> เป็นผลจากการรันจริง ตัวเลขเหล่านั้นเป็น **ตัวอย่างประกอบการอธิบาย** ทั้งสิ้น
