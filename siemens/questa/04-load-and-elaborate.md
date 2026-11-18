# บทที่ 4: โหลดและ elaborate

> ขั้นตอนที่เครื่องมือเอาโค้ดที่คอมไพล์แล้วมาสร้างเป็น design ที่จำลองได้
> รวมถึงการกำหนดค่า generic และการเลือก architecture ที่ถูกต้อง

**เครื่องมือที่เกี่ยวข้อง:** Questa SIM คำสั่ง `vsim`
**ไฟล์ตัวอย่าง:** [`ex01_generic_override`](../../../code/reference/questa/examples/ex01_generic_override/README.md)

---

## สารบัญบท

- [1. คำสั่ง vsim](#1-คำสั่ง-vsim)
- [2. Top-level ของ VHDL](#2-top-level-ของ-vhdl)
- [3. การเลือก architecture](#3-การเลือก-architecture)
- [4. Configuration](#4-configuration)
- [5. การกำหนดค่า generic](#5-การกำหนดค่า-generic)
- [6. ตัวเลือกที่ใช้บ่อย](#6-ตัวเลือกที่ใช้บ่อย)
- [7. ข้อผิดพลาดที่พบบ่อย](#7-ข้อผิดพลาดที่พบบ่อย)

---

## 1. คำสั่ง `vsim`

```bash
vsim -c -work work -do "run -all; quit -f" tb_counter_tut
```

| ส่วน | ความหมาย |
|---|---|
| `vsim` | คำสั่งโหลด design เข้าสู่ simulator |
| `-c` | โหมดบรรทัดคำสั่ง ไม่เปิดหน้าต่างกราฟิก |
| `-work work` | ไลบรารีที่มองหา design unit |
| `-do "..."` | คำสั่ง Tcl ที่จะรันทันทีหลังโหลด design |
| `tb_counter_tut` | ชื่อ entity ที่เป็น top-level |

เมื่อไม่ใส่ `-c` เครื่องมือจะเปิด GUI พร้อมหน้าต่าง Transcript, Wave, Objects,
Processes, Structure และ Source

---

## 2. Top-level ของ VHDL

> Questa SIM Tutorial ระบุว่าการโหลด simulator สำหรับ VHDL
> ทำได้ด้วย **configuration** หรือ **entity/architecture pair**
> ซึ่งต่างจาก Verilog ที่ใช้ชื่อ module

### 2.1 รูปแบบการระบุชื่อ

| รูปแบบ | ตัวอย่าง | หมายเหตุ |
|---|---|---|
| ชื่อ entity ในไลบรารีปัจจุบัน | `tb_counter_tut` | ใช้ได้ถ้ามีไลบรารี `work` อยู่ในขอบเขต |
| ชื่อเต็มพร้อมไลบรารี | `work.tb_counter_tut` | ระบุชัดเจนที่สุด แนะนำให้ใช้ |
| ระบุ architecture | `work.tb_counter_tut(tb)` | ใช้เมื่อ entity เดียวมีหลาย architecture |
| configuration | `work.cfg_counter` | ดูหัวข้อ 4 |

> **แนะนำให้ใช้รูปแบบ `work.<entity>` เสมอ**
> เพราะเมื่อมีหลายไลบรารีอยู่ในขอบเขต การไม่ระบุไลบรารีอาจทำให้
> เครื่องมือเลือก entity ที่ชื่อเหมือนกันจากไลบรารีอื่น

### 2.2 ตัวอย่างจริงจากชุดตัวอย่าง

```bash
vsim -c -work work -do "run -all; quit -f" work.tb_counter_tut
```

---

## 3. การเลือก architecture

โดยค่าเริ่มต้น เครื่องมือจะเลือก architecture ที่คอมไพล์ล่าสุดของ entity นั้น
ซึ่งอาจไม่ใช่ architecture ที่ต้องการ เช่นเมื่อมีทั้ง `rtl` และ `tb`
ในไลบรารีเดียวกัน

ระบุให้ชัดเจนได้ด้วยเครื่องหมายวงเล็บ

```bash
vsim -c -work work -do "run -all; quit -f" work.tb_counter_tut(tb)
```

> ในชุดตัวอย่างของคอร์สนี้ ใช้ชื่อ architecture `rtl` สำหรับ RTL
> และ `tb` สำหรับ testbench ดังนั้นถ้าเรียก DUT ที่มี architecture ทั้งสองแบบ
> ให้ระบุ `(rtl)` เสมอ

### 3.1 การดูว่ามี architecture อะไรบ้าง

```bash
vdir work
vdir work.tb_counter_tut
```

คำสั่ง `vdir` แสดงรายการ design unit ในไลบรารีพร้อมชนิดของแต่ละอัน
(Modules, Entities, Architectures, Configurations)

---

## 4. Configuration

configuration เป็นวิธีที่ VHDL ระบุได้ว่า entity ใดจะถูกผูกกับ architecture ใด
รวมถึงการเลือก implementation ของ component

```vhdl
configuration cfg_counter of tb_counter_tut is
  for tb
    for dut : counter_tut use entity work.counter_tut(rtl);
    end for;
  end for;
end configuration cfg_counter;
```

คอมไพล์แล้วเรียกใช้ด้วย

```bash
vsim -c -work work -do "run -all; quit -f" work.cfg_counter
```

> configuration เป็นเครื่องมือของ VHDL ที่ไม่มีใน Verilog
> ในคอร์สนี้ยังไม่ได้ใช้ เพราะการเลือก architecture ด้วย `(rtl)` เพียงพอ
> แต่ควรรู้ไว้เพราะโปรเจกต์จริงที่มีหลาย variant มักใช้ configuration

---

## 5. การกำหนดค่า generic

### 5.1 สวิตช์ `-g`

```bash
vsim -c -work work -gEXPECT_INIT=100 -do "run -all; quit -f" work.tb_counter_gen
```

รูปแบบคือ `-g<ชื่อ generic>=<ค่า>` ไม่มีช่องว่างระหว่าง `-g` กับชื่อ

### 5.2 ข้อจำกัดที่สำคัญที่สุด

> สวิตช์ `-g` มีผลกับ **generic ของ entity ระดับบนสุดเท่านั้น**
> ไม่มีผลกับ generic ของ entity ที่ถูกเรียก (instantiated)

ตัวอย่างจากชุดตัวอย่าง `ex01_generic_override`

```vhdl
entity tb_counter_gen is
  generic (
    EXPECT_INIT : natural := 0
  );
end entity tb_counter_gen;
```

```vhdl
  dut : entity work.counter_gen
    generic map (
      INIT_VALUE => EXPECT_INIT
    )
```

| คำสั่ง | ผล |
|---|---|
| `vsim ... work.tb_counter_gen` | ใช้ค่าเริ่มต้น `EXPECT_INIT = 0` และ `INIT_VALUE = 0` |
| `vsim ... -gEXPECT_INIT=100 work.tb_counter_gen` | ได้ `EXPECT_INIT = 100` และ `INIT_VALUE = 100` |
| `vsim ... -gINIT_VALUE=100 work.tb_counter_gen` | **ไม่มีผล** เพราะ `INIT_VALUE` ไม่ใช่ generic ของ entity ระดับบนสุด |

### 5.3 วิธีที่ถูกต้องเมื่อ generic อยู่ที่ entity ที่ถูกเรียก

1. ประกาศ generic ที่ entity ระดับบนสุด แล้วส่งต่อผ่าน `generic map`
   วิธีนี้คือวิธีที่ตัวอย่าง `ex01_generic_override` ใช้
2. หรือป้อนค่าตอนสร้าง instance โดยตรงในไฟล์ VHDL

### 5.4 ชนิดของค่าที่ใส่ได้

| ชนิดของ generic | ตัวอย่างค่า |
|---|---|
| `integer` `natural` `positive` | `-gWIDTH=8` |
| `boolean` | `-gFAIL_MODE=true` `-gFAIL_MODE=false` |
| `string` | `-gMODE=fast` |
| `real` | `-gGAIN=1.5` |

---

## 6. ตัวเลือกที่ใช้บ่อย

| ตัวเลือก | ความหมาย |
|---|---|
| `-c` | โหมดบรรทัดคำสั่ง ไม่เปิด GUI |
| `-gui` | บังคับให้เปิด GUI (ในรุ่นที่รองรับ) |
| `-do "<คำสั่ง>"` | รันคำสั่ง Tcl ทันทีหลังโหลด design |
| `-work <ชื่อ>` | ไลบรารีที่มองหา design unit |
| `-g<ชื่อ>=<ค่า>` | กำหนดค่า generic ของ entity ระดับบนสุด |
| `-config <ชื่อ>` | โหลด configuration |
| `-t <เวลา>` | จำกัดเวลาจำลองสูงสุด เช่น `-t 10us` |
| `-wlf <ไฟล์>` | บันทึกข้อมูล waveform เป็นไฟล์ WLF |
| `-novopt` | ไม่ optimize design |
| `+acc` | เปิดการเข้าถึง design unit ทั้งหมดเพื่อ debug |
| `-quiet` | ลดข้อความระหว่างโหลด |

> รายการที่รองรับทั้งหมดขึ้นกับรุ่นของเครื่องมือ
> ให้ใช้ `vsim -help` ของเครื่องที่ใช้เป็นหลัก

### 6.1 ตัวอย่างคำสั่งที่ใช้จริง

จำลองแบบไม่เปิด GUI และจำกัดเวลาไว้ที่ 10 ไมโครวินาที

```bash
vsim -c -work work -t 10us -do "run -all; quit -f" work.tb_counter_tut
```

จำลองแบบมี GUI พร้อมบันทึก waveform เป็นไฟล์ WLF

```bash
vsim -wlf counter.wlf -do "do ../../tcl/ex00_counter_tutorial.do" work.tb_counter_tut
```

---

## 7. ข้อผิดพลาดที่พบบ่อย

| อาการ | สาเหตุ | วิธีแก้ |
|---|---|---|
| `Unable to bind to entity "tb_xxx"` | ยังไม่ได้คอมไพล์ หรือชื่อผิด หรือไลบรารีผิด | คอมไพล์ให้ครบแล้วตรวจด้วย `vdir work` และระบุไลบรารีให้ครบ |
| `Unable to find design unit` | ระบุ architecture ผิด หรือมีหลาย architecture | ตรวจด้วย `vdir work.<entity>` แล้วระบุ `(architecture)` ให้ถูก |
| ค่า generic ไม่เปลี่ยนตามที่สั่ง | ใช้ `-g` กับ generic ที่ไม่ใช่ของ entity ระดับบนสุด | ดูหัวข้อ 5.2 |
| `generic "xxx" not found` | พิมพ์ชื่อ generic ผิด หรือ entity ระดับบนสุดไม่มี generic นั้น | ตรวจชื่อใน `entity` ของไฟล์ |
| simulation ไม่เดินเวลา | ไม่ได้สั่ง `run` | หลังโหลด design ต้องสั่ง `run -all` หรือ `run <เวลา>` |
| simulation หยุดทันทีที่เวลา 0 | เจอ breakpoint หรือ assertion ระดับ error/failure | ดูข้อความในหน้าต่าง Transcript |
| ไม่เห็นสัญญาณบางตัวใน Wave | ไม่ได้เปิดการมองเห็น design unit ทั้งหมด | เพิ่ม `+acc` ดูหัวข้อ 2.3 ของ[บทที่ 2](02-concepts-and-flows.md) |
| `simulation failed` ทันที | ใช้ฟีเจอร์ VHDL-2008 ทั้งที่คอมไพล์ด้วย `-2002` | ดูตารางฟีเจอร์ที่ห้ามใช้ใน[บทที่ 3](03-compile-vhdl.md) |

---

## แบบฝึกหัดท้ายบท

1. คอมไพล์ `ex00_counter_tutorial` แล้วโหลดด้วย
   `vsim -c -work work -do "run -all; quit -f" work.tb_counter_tut`
   จากนั้นลองสลับเป็นชื่อ entity ที่ไม่ระบุไลบรารี แล้วเทียบผล
2. รัน `ex01_generic_override` สองครั้ง ครั้งแรกไม่ใส่ `-g`
   ครั้งที่สองใส่ `-gEXPECT_INIT=100` แล้วเทียบข้อความ marker ทั้งสองครั้ง
3. ลองใช้ `-gINIT_VALUE=100` แทน แล้วบันทึกว่าผลต่างกันอย่างไร
4. รัน `vdir work` แล้วบันทึกรายการ design unit ทั้งหมดที่เห็น
5. โหลดแบบมี GUI แล้วสังเกตว่าหน้าต่าง Objects และ Processes แสดงอะไรบ้าง

---

## คำถามท้ายบท

1. top-level ของงาน VHDL ต่างจากของงาน Verilog อย่างไร
2. เหตุใดควรระบุชื่อไลบรารีในคำสั่ง `vsim` เสมอ
3. สวิตช์ `-g` มีผลกับ generic ใดบ้าง และวิธีตั้งค่า generic ที่อยู่ที่
   entity ที่ถูกเรียกคืออะไร
4. ทำไมหลังโหลด design แล้วเวลายังไม่เดิน
5. จะทำอย่างไรถ้าต้องการบันทึก waveform เป็นไฟล์ที่เปิดดูภายหลังได้

---

**อ่านต่อ:** [บทที่ 5 — การทำงานแบบ GUI](05-gui-workflow.md) →
[บทที่ 6 — การวิเคราะห์ waveform](06-waveform.md) →
[บทที่ 5 — ตรรกะ sequential ของคู่มือ VHDL](../vhdl/05-sequential-logic.md)
