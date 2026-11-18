# บทที่ 9: assertion, severity และรหัสออก

> วิธีทำให้ testbench รายงานความผิดพลาดได้อย่างถูกต้อง
> และทำให้ระบบ CI ตัดสินใจผ่านหรือไม่ผ่านได้โดยอัตโนมัติ

**เครื่องมือที่เกี่ยวข้อง:** Questa SIM
**ไฟล์ตัวอย่าง:** [`ex03_assert_severity`](../../../code/reference/questa/examples/ex03_assert_severity/README.md)

---

## สารบัญบท

- [1. assert ใน VHDL](#1-assert-ใน-vhdl)
- [2. สี่ระดับ severity](#2-สี่ระดับ-severity)
- [3. ตารางพฤติกรรมจริง](#3-ตารางพฤติกรรมจริง)
- [4. severity ต้องเป็น static expression](#4-severity-ต้องเป็น-static-expression)
- [5. onerror, onbreak และ when](#5-onerror-onbreak-และ-when)
- [6. รหัสออกของ vsim](#6-รหัสออกของ-vsim)
- [7. การทำ negative test](#7-การทำ-negative-test)
- [8. PSL assertion](#8-psl-assertion)

---

## 1. `assert` ใน VHDL

```vhdl
assert <เงื่อนไข>
  report "ข้อความที่อธิบายความผิดพลาด"
  severity <ระดับ>;
```

### 1.1 รูปแบบที่ใช้ใน testbench ของคอร์สนี้

```vhdl
if to_integer(unsigned(cnt)) /= exp_v then
  error_count := error_count + 1;
  report "cnt mismatch: got " & integer'image(to_integer(unsigned(cnt)))
         & " expected " & integer'image(exp_v)
         severity error;
end if;
```

ข้อสังเกตสองข้อ

1. **ใช้ `severity error` ไม่ใช่ `severity failure` ในกรณีผลไม่ตรง**
   เพราะ `failure` จะหยุด simulation ทันที ทำให้เก็บจำนวน error ไม่ได้
   และไม่เห็นภาพรวมว่าผิดกี่จุด
2. **ข้อความบอกทั้ง "ได้อะไร" และ "ควรได้อะไร"**
   ทำให้หาสาเหตุได้เร็วโดยไม่ต้องเปิด waveform

### 1.2 ข้อควรระวัง

> ข้อความใน `report "..."` ต้องเป็น **ASCII เท่านั้น**
> ถ้าใส่อักขระไทย จะขึ้นข้อผิดพลาด
> `String literal has a character with value 0x84`
> ภาษาไทยใช้ได้เฉพาะในคอมเมนต์

---

## 2. สี่ระดับ severity

| ระดับ | ความหมาย | ใช้เมื่อ |
|---|---|---|
| `note` | ข้อความบอกสถานะ ไม่มีผลต่อการทำงาน | บันทึกค่าที่ได้รับ หรือทำเครื่องหมายจุดในการจำลอง |
| `warning` | สิ่งที่น่าสงสัย แต่ยังไม่ใช่ความผิดพลาด | ค่าที่อยู่นอกช่วงที่คาดหวัง แต่ยังใช้งานได้ |
| `error` | ผลไม่ตรงความคาดหมาย | ค่าไม่ตรง golden model |
| `failure` | ปัญหาร้ายแรงที่ไม่มีทางแก้ต่อ | timeout, ไม่พบ entity ที่ต้องการ |

---

## 3. ตารางพฤติกรรมจริง

> ตารางนี้เป็นข้อมูลที่วัดได้จริง
> คอลัมน์ GHDL วัดด้วย GHDL 1.0.0 ในเครื่องที่จัดทำคู่มือนี้
> ส่วนคอลัมน์ Questa ยังต้องให้ผู้เรียนตรวจสอบเอง

### 3.1 ผลที่วัดได้ด้วย GHDL 1.0.0

| severity | ค่าเริ่มต้นของ GHDL | GHDL กับ `--assert-level=error` |
|---|---|---|
| `note` | พิมพ์แล้วจบปกติ รหัสออก 0 | พิมพ์แล้วจบปกติ รหัสออก 0 |
| `warning` | พิมพ์แล้วจบปกติ รหัสออก 0 | พิมพ์แล้วจบปกติ รหัสออก 0 |
| `error` | พิมพ์แล้ว **จบปกติ** รหัสออก 0 | พิมพ์แล้ว **หยุด** รหัสออก 1 |
| `failure` | พิมพ์แล้ว **หยุด** รหัสออก 1 | พิมพ์แล้ว **หยุด** รหัสออก 1 |

ทดสอบซ้ำได้ด้วยคำสั่ง

```bash
cd code/reference/questa
ghdl -r --std=08 --workdir=work/ex03_assert_severity_08 tb_assert_severity \
     --assert-level=error -gFAIL_MODE=true -gSEVERITY_LEVEL=2
```

### 3.2 สิ่งที่ต้องทำเองเพื่อยืนยันพฤติกรรมของ Questa

> **ห้ามสรุปว่า "severity error หยุด simulation เสมอ"**
> เพราะไม่จริงกับ GHDL ตามตารางข้างบน

ขั้นตอนยืนยันด้วยตัวเอง

```bash
cd code/reference/questa/examples/ex03_assert_severity

vlib work
vmap work work
vcom -2008 -work work src/sum8.vhd
vcom -2008 -work work tb/tb_assert_severity.vhd

# ลองทีละระดับ
vsim -c -work work -gFAIL_MODE=true -gSEVERITY_LEVEL=0 -do "run -all; quit -f" tb_assert_severity
vsim -c -work work -gFAIL_MODE=true -gSEVERITY_LEVEL=1 -do "run -all; quit -f" tb_assert_severity
vsim -c -work work -gFAIL_MODE=true -gSEVERITY_LEVEL=2 -do "run -all; quit -f" tb_assert_severity
vsim -c -work work -gFAIL_MODE=true -gSEVERITY_LEVEL=3 -do "run -all; quit -f" tb_assert_severity
```

จดผลลัพธ์ของแต่ละระดับลงในบันทึกของตัวเอง
โดยดูทั้งข้อความใน Transcript และรหัสออกของคำสั่ง

```bash
echo $?
```

### 3.3 ข้อสรุปที่ใช้ได้ทั้งสองเครื่องมือ

> ระดับ `note` และ `warning` ไม่ทำให้ simulation หยุดในทั้งสองเครื่องมือ
> ระดับ `failure` ทำให้ simulation หยุดและให้รหัสออกที่ไม่ใช่ศูนย์ในทั้งสองเครื่องมือ
> ส่วนระดับ `error` **ต่างกันได้** และต้องทดลองด้วยตัวเอง

---

## 4. severity ต้องเป็น static expression

> ระดับ severity ในคำสั่ง `assert` ต้องเป็นค่าที่ทราบตอน **elaboration**
> ไม่ใช่ค่าที่เปลี่ยนได้ระหว่างรัน

ถ้าต้องการเลือกระดับตามพารามิเตอร์ ต้องใช้ `case` บน generic

```vhdl
case SEVERITY_LEVEL is
  when 0 =>
    assert false report "..." severity note;
  when 1 =>
    assert false report "..." severity warning;
  when 2 =>
    assert false report "..." severity error;
  when others =>
    assert false report "..." severity failure;
end case;
```

ตัวอย่างนี้อยู่ใน
[`ex03_assert_severity`](../../../code/reference/questa/examples/ex03_assert_severity/README.md)
โดยใช้ร่วมกับ `if generate` เพื่อไม่ให้ส่วนสาธิตกระทบการรันปกติ

---

## 5. `onerror`, `onbreak` และ `when`

เป็น procedure ของ Tcl ที่กำหนดว่าให้ทำอะไรเมื่อเกิดเหตุการณ์พิเศษ

| procedure | ถูกเรียกเมื่อ |
|---|---|
| `onerror` | เกิด error ระดับ `failure` หรือเหตุการณ์ร้ายแรงอื่น |
| `onbreak` | simulation หยุดที่ breakpoint |
| `when` | ทำงานตามเงื่อนไขที่กำหนด เช่น เมื่อจบการจำลอง |

### 5.1 รูปแบบการใช้

```tcl
onerror {quit -code 1}
onbreak {quit -code 1}
```

### 5.2 ทำไมต้องตั้ง `onerror`

โดยค่าเริ่มต้น `onerror` ไม่ได้ทำอะไร
แปลว่าเมื่อเกิด error แล้ว simulation จะหยุดและรอคำสั่งจากผู้ใช้
ซึ่งเหมาะกับการ debug แต่ไม่เหมาะกับการรันแบบอัตโนมัติ

เมื่อตั้งเป็น `quit -code 1` จะทำให้การรันแบบ batch จบด้วยรหัสที่บอกว่าล้มเหลว

### 5.3 การตั้ง `when` เพื่อทำงานเมื่อจบการจำลอง

```tcl
when {ending} {
    puts "Simulation ended at [gettime]"
}
```

### 5.4 ใช้ร่วมกับข้อความที่ต้องเห็น

```tcl
onerror {
    puts "ERROR: simulation failed"
    quit -code 1
}
onbreak {
    puts "BREAK: simulation stopped at [gettime]"
    quit -code 1
}
```

---

## 6. รหัสออกของ `vsim`

### 6.1 คำสั่ง `quit`

| รูปแบบ | ผล |
|---|---|
| `quit` | ออกโดยถามยืนยัน |
| `quit -f` | ออกทันทีโดยไม่ถาม |
| `quit -code <n>` | ออกโดยกำหนดรหัสออกเป็น n |
| `quit -code [expr {...}]` | ออกโดยคำนวณรหัสออกจากเงื่อนไข |

### 6.2 รูปแบบที่ใช้ในชุดตัวอย่าง

```bash
vsim -c -work work \
  -do "onerror {quit -code 1}; onbreak {quit -code 1}; run -all; quit -code 0" \
  work.tb_counter_tut
```

ลำดับการทำงาน

1. ตั้ง `onerror` และ `onbreak` ให้ออกด้วยรหัส 1
2. รันจนจบ
3. ถ้าไม่มี error ให้ออกด้วยรหัส 0

### 6.3 อย่าพึ่งรหัสออกอย่างเดียว

> สคริปต์ `scripts/questa_run.sh` ของชุดตัวอย่างตรวจ **ทั้งรหัสออกของ `vsim`
> และข้อความใน Transcript** ว่ามี `Error` หรือ `Failure` หรือไม่

เหตุผลคือพฤติกรรมของ `severity error` ต่างกันระหว่าง simulator
ถ้าพึ่งรหัสออกอย่างเดียว อาจพลาดการรายงานความผิดพลาดได้

การตรวจทั้งสองอย่างเป็นแนวทางที่ปลอดภัยกว่า
และยังตรวจได้ว่า marker `GOLDEN_<ชื่อ>_PASS` ปรากฏใน log จริงหรือไม่

---

## 7. การทำ negative test

### 7.1 หลักการ

> testbench ที่ตรวจผลได้ ยังต้องพิสูจน์ว่า "มันตรวจจับความผิดพลาดได้จริง"
> ถ้าไม่ทดสอบเส้นทางที่ควรจะล้มเหลวว่าล้มเหลวจริง
> เราไม่มีหลักประกันว่ามันไม่ผ่านทุกครั้ง

เรียกว่า **negative test** — ตัวอย่างที่ตั้งใจให้ล้มเหลว

### 7.2 วิธีทำในตัวอย่าง `ex03_assert_severity`

ตัวอย่างมี generic `FAIL_MODE` ที่เปิดส่วนสาธิต severity ได้

| การรัน | ผลที่คาดหวัง |
|---|---|
| ค่าเริ่มต้น | `GOLDEN_ASSERT_SEVERITY_PASS` — ผ่าน |
| `FAIL_MODE=true` ระดับ 0–1 | พิมพ์ข้อความ แล้ว simulation จบปกติ |
| `FAIL_MODE=true` ระดับ 2–3 | พิมพ์ข้อความ แล้ว simulation หยุด |

การรันระดับ 2 หรือ 3 แล้ว **ไม่เห็น marker PASS** เป็นหลักฐานว่า
การตรวจสอบทำงานจริง

### 7.3 ใน Lab ของคอร์ส

Lab ที่ตรวจสอบผลลัพธ์มี `scripts/negative_test.sh` อยู่แล้ว
ให้ดูรูปแบบเดียวกัน — ใช้พารามิเตอร์หรือไฟล์ config ที่ผิดโดยตั้งใจ
แล้วยืนยันว่าการรันล้มเหลว

---

## 8. PSL assertion

PSL (Property Specification Language) ใช้เขียน property ระดับสูงกว่า `assert`
เช่น "ถ้าเกิด A แล้ว B ต้องเกิดภายใน 3 รอบนาฬิกา"

สำหรับ VHDL สามารถฝังคำสั่ง PSL ไว้ในคอมเมนต์

```vhdl
-- psl default clock is rising_edge(clk);
-- psl assert always (req -> s_eventually ready);
```

ข้อดีคือเขียน property ได้กระชับและตรวจได้อัตโนมัติ
ข้อจำกัดคือต้องใช้เครื่องมือที่รองรับ PSL
และต้องคอมไพล์ด้วยมาตรฐานที่เหมาะสมกับไฟล์ `.psl`

> คู่มือนี้เน้น VHDL ล้วน จึงไม่ลงรายละเอียดของ PSL
> รายละเอียดอยู่ใน Questa SIM Tutorial หัวข้อ Debugging with PSL assertions

---

## แบบฝึกหัดท้ายบท

1. รัน `ex03_assert_severity` ด้วย `FAIL_MODE=true` ทั้ง 4 ระดับ
   จดข้อความและรหัสออกของแต่ละระดับ
2. ทำสิ่งเดียวกันกับ GHDL โดยใช้ `--assert-level=error`
   แล้วเทียบตารางข้อ 3.1 กับผลที่วัดได้
3. แก้ไฟล์ `tb_assert_severity.vhd` ให้ใช้ `severity failure` แทน `severity error`
   ในกรณีที่ผลไม่ตรง แล้วรันซ้ำเพื่อดูว่าพฤติกรรมเปลี่ยนอย่างไร
4. เขียนไฟล์ `.do` ขนาดเล็กที่มี `onerror {quit -code 1}`
   แล้วรัน testbench ที่ตั้งใจให้ล้มเหลว แล้วตรวจรหัสออก
5. อธิบายว่าทำไมสคริปต์ตรวจต้องดูทั้งรหัสออกและข้อความใน Transcript

---

## คำถามท้ายบท

1. ทำไมกรณีผลไม่ตรงควาดหมายควรใช้ `severity error` แทน `severity failure`
2. ผลของ `severity error` ต่างกันอย่างไรระหว่าง GHDL กับ Questa
3. เหตุใด severity จึงต้องเป็น static expression
4. `onerror` มีหน้าที่อะไร และทำไมการรันแบบ batch จึงต้องตั้ง
5. negative test คืออะไร และทำไมต้องมี

---

**อ่านต่อ:** [บทที่ 10 — Tcl และการรันแบบ batch](10-tcl-and-batch.md) →
[บทที่ 11 — เทียบเทียบ GHDL กับ Questa](11-ghdl-cross-reference.md) →
[บทที่ 11 — รูปแบบการทดสอบของคู่มือ VHDL](../vhdl/11-verification-style.md)
