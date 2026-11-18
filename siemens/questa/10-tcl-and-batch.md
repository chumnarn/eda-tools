# บทที่ 10: Tcl และการรันแบบ batch

> การรัน simulation แบบไม่ต้องใช้เมาส์ เพื่อให้ทำซ้ำได้ ตรวจสอบย้อนหลังได้
> และนำไปต่อกับระบบ CI ได้

**เครื่องมือที่เกี่ยวข้อง:** Questa SIM
**ไฟล์ตัวอย่าง:** [`code/reference/questa/`](../../../code/reference/questa/README.md)

---

## สารบัญบท

- [1. ทำไมต้องมีโหมด batch](#1-ทำไมต้องมีโหมด-batch)
- [2. โหมดบรรทัดคำสั่ง](#2-โหมดบรรทัดคำสั่ง)
- [3. คำสั่งจำเป็นของการรัน](#3-คำสั่งจำเป็นของการรัน)
- [4. ตัวเลือก -do และไฟล์ .do](#4-ตัวเลือก--do-และไฟล์-do)
- [5. รูปแบบไฟล์ .do ที่ใช้ได้จริง](#5-รูปแบบไฟล์-do-ที่ใช้ได้จริง)
- [6. การรันหลายตัวอย่าง](#6-การรันหลายตัวอย่าง)
- [7. การเก็บ log](#7-การเก็บ-log)
- [8. เชื่อมกับระบบ CI](#8-เชื่อมกับระบบ-ci)
- [9. ข้อผิดพลาดที่พบบ่อย](#9-ข้อผิดพลาดที่พบบ่อย)

---

## 1. ทำไมต้องมีโหมด batch

การรันผ่าน GUI เหมาะกับการ debug แต่ไม่เหมาะกับงานที่ต้องทำซ้ำ
เพราะ

| ปัญหาของการรันผ่าน GUI | โหมด batch แก้ได้อย่างไร |
|---|---|
| ต้องคลิกทีละขั้น เสียเวลา | คำสั่งเดียวจบ |
| ผลลัพธ์ไม่ถูกเก็บเป็นไฟล์ | บันทึกเป็น Transcript และ log |
| ไม่รู้ว่ารันผ่านหรือไม่ เพราะไม่ได้ดูรหัสออก | มีรหัสออกให้ระบบอัตโนมัติตรวจ |
| ทำซ้ำไม่ได้โดยไม่ต้องจำขั้นตอน | เก็บขั้นตอนไว้ในไฟล์ `.do` |

> ในกระบวนการรันงานจริง (CI) สิ่งที่ระบบตรวจคือ **รหัสออก** ไม่ใช่ข้อความบนหน้าจอ

---

## 2. โหมดบรรทัดคำสั่ง

สวิตช์ `-c` ทำให้เครื่องมือไม่เปิดหน้าต่างกราฟิก

```bash
vsim -c -work work -do "run -all; quit -f" work.tb_counter_tut
```

ลำดับการทำงาน

1. โหลด design
2. รันคำสั่งใน `-do`
3. ออกจากเครื่องมือตามคำสั่งที่กำหนด

> ถ้าไม่ใส่ `quit` ใน `-do` เครื่องมือจะไม่ออกและจะค้างรอคำสั่ง
> ในการรันแบบ batch ต้องมี `quit` เสมอ

---

## 3. คำสั่งจำเป็นของการรัน

| คำสั่ง | ผล |
|---|---|
| `run` | รันต่อจนกว่าจะหยุด |
| `run -all` | รันจนกว่า event queue จะว่าง คือจนการจำลองจบสิ้น |
| `run <เวลา>` | รันไปข้างหน้าเวลาที่กำหนด เช่น `run 500 ns` |
| `finish` | จบการจำลอง |
| `quit` | ออกโดยถามยืนยัน |
| `quit -f` | ออกทันทีโดยไม่ถาม |
| `quit -code <n>` | ออกโดยกำหนดรหัสออก |
| `echo <ข้อความ>` | พิมพ์ข้อความลง Transcript |
| `puts <ข้อความ>` | พิมพ์ข้อความจาก Tcl |
| `gettime` | เวลาปัจจุบันของ simulation |

### 3.1 `run -all` กับ `run`

`run -all` รันจนกว่า event queue จะว่าง
ซึ่งเป็นการจบการจำลองแบบสมบูรณ์

`run` รันต่อจนกว่าจะเจอ breakpoint หรือเหตุการณ์ที่ทำให้หยุด
จึงยังไม่จบการจำลอง

> ใน testbench ที่นาฬิกาหยุดเมื่อ `done` เป็นจริง `run -all` จะจบเอง
> แต่ถ้านาฬิกาไม่หยุด event queue จะไม่ว่าง และการจำลองจะไม่จบสิ้น
> นี่คือเหตุผลที่กฎของคอร์สนี้กำหนดให้นาฬิกาใน testbench ต้องหยุดเมื่อ `done`

---

## 4. ตัวเลือก `-do` และไฟล์ `.do`

### 4.1 คำสั่งในบรรทัด

```bash
vsim -c -do "run -all; quit -f" work.tb_counter_tut
```

ค่าใน `-do` เป็นคำสั่ง Tcl ที่คั่นด้วยเครื่องหมาย `;`

### 4.2 ไฟล์ `.do`

เมื่อคำสั่งยาวขึ้น ให้แยกไปเป็นไฟล์

```bash
vsim -c -do "do tcl/ex00_counter_tutorial.do; quit -code 0" work.tb_counter_tut
```

คำสั่ง `do` โหลดและรันไฟล์ Tcl

### 4.3 กฎของไฟล์ `.do` ในชุดตัวอย่าง

> **ห้ามใส่ `quit` ในไฟล์ `.do`**
> เพราะไฟล์เดียวกันถูกใช้ทั้งแบบมี GUI (ต้องคงหน้าต่างไว้)
> และแบบ batch (ต้องออก) โดยให้ผู้เรียกต่อท้ายเองเมื่อรันแบบ batch

ต้องมี `onerror` และ `onbreak` เสมอ

```tcl
onerror {quit -code 1}
onbreak {quit -code 1}
```

---

## 5. รูปแบบไฟล์ `.do` ที่ใช้ได้จริง

### 5.1 แบบสำหรับ GUI และ batch

ไฟล์ `tcl/ex00_counter_tutorial.do` ในชุดตัวอย่าง

```tcl
# ex00_counter_tutorial.do: เปิด waveform ทั้ง design แล้วรันจนจบ
#
# ใช้สองแบบ
#   แบบมี GUI:
#     vsim -do "do tcl/ex00_counter_tutorial.do" work.tb_counter_tut
#   แบบ batch (ไม่เปิด GUI):
#     vsim -c -do "do tcl/ex00_counter_tutorial.do; quit -code 0" work.tb_counter_tut

onerror {quit -code 1}
onbreak {quit -code 1}

add wave -r /*

run -all
```

### 5.2 แบบรันทีละตัวอย่างด้วยตัวแปร

```tcl
# run_example.do: ต้องกำหนดตัวแปร TOP และ MARKER ก่อนเรียก
#   vsim -c -do "set TOP tb_x; set MARKER GOLDEN_X_PASS; do tcl/run_example.do" work.tb_x

onerror {quit -code 1}
onbreak {quit -code 1}

if {![info exists ::TOP]} {
    error "ต้องกำหนด ::TOP ก่อนเรียกไฟล์นี้"
}

add wave -r /*
run -all

# ตรวจว่า marker ปรากฏใน Transcript หรือไม่
if {[search -match $::MARKER transcript] == {}} {
    puts "FAIL: ไม่พบ marker $::MARKER"
    quit -code 1
} else {
    puts "PASS: พบ marker $::MARKER"
    quit -code 0
}
```

> คำสั่ง `search` ค้นหาข้อความในไฟล์ Transcript ที่กำลังบันทึก
> ถ้าไฟล์ Transcript ถูกปิดด้วย `transcript off` คำสั่งนี้จะไม่พบข้อความ
> ให้เปิด transcript ด้วย `transcript file <ชื่อไฟล์>` ก่อน

### 5.3 แบบที่รันหลายตัวอย่าง

```tcl
# run_all.do: รัน testbench หลายตัวในไลบรารีเดียว
onerror {quit -code 1}
onbreak {quit -code 1}

set tests {
    tb_counter_tut
    tb_counter_gen
    tb_counter_forced
    tb_assert_severity
}

set failed 0

foreach tb $tests {
    puts "=== กำลังรัน $tb ==="
    vsim -c -work work -do "run -all; quit -code 0" $tb
    if {$tb eq "tb_counter_tut"} {
        # ตรวจ marker ของตัวแรกเป็นตัวอย่าง
    }
}

if {$failed > 0} {
    puts "FAIL: มี $failed ตัวอย่างที่ไม่ผ่าน"
    quit -code 1
}
puts "PASS: ผ่านทั้งหมด"
quit -code 0
```

> ในทางปฏิบัติแนะนำให้รันแต่ละตัวอย่างแยกเป็น process แยก
> เพื่อให้เมื่อตัวหนึ่งล้มเหลว ไม่กระทบการเก็บ log ของตัวอื่น
> ซึ่งเป็นวิธีที่ `scripts/questa_run.sh` ในชุดตัวอย่างใช้

---

## 6. การรันหลายตัวอย่าง

### 6.1 วิธีที่แนะนำ — สคริปต์ชั้นนอกจัดการ

```bash
for ex in ex00_counter_tutorial ex01_generic_override; do
    bash scripts/questa_run.sh "$ex" "tb_${ex#ex[0-9][0-9]_}"
done
```

ข้อดีคือแต่ละตัวอย่างได้ log แยก และรหัสออกของแต่ละตัวชัดเจน

### 6.2 วิธีที่ใช้ Tcl จัดการ

```tcl
foreach {ex tb} {
    ex00_counter_tutorial tb_counter_tut
    ex01_generic_override  tb_counter_gen
} {
    puts "=== $ex ==="
    if {[catch {vsim -c -work work -do "run -all; quit -code 0" $tb} result]} {
        puts "FAIL: $ex"
        set failed 1
    }
}
```

---

## 7. การเก็บ log

### 7.1 ด้วยตัวเลือก `-l`

```bash
vsim -c -l reports/tb_counter_tut.log -work work -do "run -all; quit -f" work.tb_counter_tut
```

ตัวเลือก `-l` บันทึก Transcript ลงไฟล์ที่ระบุ

### 7.2 ด้วยคำสั่ง `transcript`

```tcl
transcript file reports/sim.log
transcript on
run -all
transcript off
```

### 7.3 ตรวจ marker จาก log

```bash
if grep -q "GOLDEN_COUNTER_TUT_PASS" reports/tb_counter_tut.log; then
    echo "ผ่าน"
else
    echo "ไม่ผ่าน"
fi
```

> สคริปต์ `scripts/questa_run.sh` ในชุดตัวอย่างตรวจ marker ด้วยวิธีนี้
> โดยใช้ชื่อ marker ที่สร้างจากชื่อโฟลเดอร์ของตัวอย่าง

---

## 8. เชื่อมกับระบบ CI

### 8.1 เงื่อนไขที่ CI ต้องการ

| เงื่อนไข | วิธีทำ |
|---|---|
| ไม่ต้องโต้ตอบกับมนุษย์ | ใช้ `-c` และ `quit -f` |
| บอกได้ว่าผ่านหรือไม่ | คืนรหัสออก 0 เมื่อผ่าน |
| เก็บหลักฐานได้ | บันทึก Transcript ลงไฟล์ |
| ตรวจได้ว่าผ่านจริง | grep marker จาก log |

### 8.2 ตัวอย่างขั้นตอนใน CI

```bash
set -euo pipefail

cd code/reference/questa
mkdir -p reports

bash scripts/questa_run.sh ex00_counter_tutorial tb_counter_tut
bash scripts/questa_run.sh ex01_generic_override  tb_counter_gen
bash scripts/questa_run.sh ex02_force_release     tb_counter_forced
bash scripts/questa_run.sh ex03_assert_severity   tb_assert_severity

echo "ผ่านทั้งหมด"
```

ตัวเลือก `set -euo pipefail` ทำให้ CI หยุดทันทีที่สคริปต์ใดคืนค่าที่ไม่ใช่ศูนย์

### 8.3 สิ่งที่ต้องเตรียมเพิ่มใน CI

- ติดตั้ง Questa หรือ ModelSim และตั้ง `LM_LICENSE_FILE`
- ถ้า license เป็นแบบเครือข่าย ต้องเข้าถึง license server ได้
- เก็บไฟล์ log เป็น artifact เพื่อให้ตรวจสอบย้อนหลังได้

### 8.4 ทางเลือกที่ไม่ต้องมี license

ถ้า CI ไม่มี license ให้ใช้ GHDL แทน ซึ่งเป็นซอฟต์แวร์ฟรี
รายละเอียดอยู่ใน[บทที่ 11](11-ghdl-cross-reference.md)

---

## 9. ข้อผิดพลาดที่พบบ่อย

| อาการ | สาเหตุ | วิธีแก้ |
|---|---|---|
| คำสั่งรันค้างไม่จบ | ไม่มี `quit` ใน `-do` | เติม `quit -f` หรือ `quit -code 0` |
| ไม่มีไฟล์ log | ไม่ได้ใส่ `-l` | เพิ่ม `-l <ชื่อไฟล์>` |
| รหัสออกเป็น 0 แม้มี error | ไม่ได้ตั้ง `onerror` | ตั้ง `onerror {quit -code 1}` |
| รหัสออกเป็น 1 แม้ผ่าน | `onbreak` ทำงานเมื่อเจอ breakpoint ที่ตั้งไว้ | เอา breakpoint ออกก่อนรันแบบ batch |
| ค้น marker ไม่เจอ | `transcript off` หรือบันทึก log ที่อื่น | ตรวจว่าเปิด transcript และตรวจไฟล์ log ที่ถูกต้อง |
| `can't find file` ตอนสั่ง `do` | พาธของไฟล์ `.do` ไม่ถูกต้อง | ใช้พาธสัมพัทธ์จากไดเรกทอรีที่รัน |
| ไฟล์ VHDL ไม่ถูกโหลด | คอมไพล์ในไลบรารีอื่น | ตรวจ `-work` และ `vmap` |

---

## แบบฝึกหัดท้ายบท

1. รัน `ex00_counter_tutorial` แบบ batch แล้วตรวจรหัสออก
2. รันซ้ำโดยเพิ่ม `-l` แล้วตรวจว่า log มี marker ครบ
3. สร้างไฟล์ `.do` ที่ตั้ง `onerror {quit -code 1}` แล้วรัน testbench
   ที่ตั้งใจให้ล้มเหลว แล้วตรวจรหัสออก
4. เขียนไฟล์ `.do` ที่รัน testbench ทั้งสี่ตัว แล้วรันด้วยคำสั่งเดียว
5. ลองใช้ `search -match GOLDEN_COUNTER_TUT_PASS transcript`
   ในไฟล์ `.do` แล้วบันทึกว่าได้ผลอย่างไร

---

## คำถามท้ายบท

1. เหตุใดโหมด batch จึงจำเป็นสำหรับ CI
2. `run` กับ `run -all` ต่างกันอย่างไร และเกี่ยวข้องกับเรื่องนาฬิกาใน testbench อย่างไร
3. ทำไมไฟล์ `.do` ในชุดตัวอย่างจึงไม่มีคำสั่ง `quit`
4. `onerror` กับ `onbreak` ทำหน้าที่ต่างกันอย่างไร
5. ทำไมต้องตรวจ marker จาก log เพิ่มเติม ไม่พึ่งรหัสออกอย่างเดียว

---

**อ่านต่อ:** [บทที่ 11 — เทียบเทียบ GHDL กับ Questa](11-ghdl-cross-reference.md) →
[บทที่ 12 — ปัญหาที่พบบ่อย](12-troubleshooting.md) →
[บทที่ 9 — โครงสร้างโค้ดโปรเจกต์ของคู่มือ VHDL](../vhdl/09-code-organization.md)
