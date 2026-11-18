# บทที่ 2: แนวคิดและ flow การทำงาน

> สิ่งที่ต้องรู้ก่อนกดปุ่มใด ๆ — library คืออะไร, คำสั่งไหนมาก่อนคำสั่งไหน
> และทำไมบางครั้งโค้ดที่คอมไพล์ผ่านแล้วยังมองไม่เห็นสัญญาณ

**เครื่องมือที่เกี่ยวข้อง:** Questa SIM
**ที่มาของเนื้อหา:** Questa SIM Tutorial 2026.1 หัวข้อ
Conceptual Overview และ Basic Simulation

---

## สารบัญบท

- [1. Library คืออะไร](#1-library-คืออะไร)
- [2. Basic simulation flow](#2-basic-simulation-flow)
- [3. Project flow](#3-project-flow)
- [4. Multiple library flow](#4-multiple-library-flow)
- [5. Design optimization และ switch +acc](#5-design-optimization-และ-switch-acc)
- [6. เครื่องมือ debug ที่ Questa มีให้](#6-เครื่องมือ-debug-ที่-questa-มีให้)

---

## 1. Library คืออะไร

ใน Questa SIM ทุกอย่างที่คอมไพล์จะอยู่ใน **library** เสมอ
ไม่มีการคอมไพล์ "ไฟล์ลอย" นอก library

Questa ใช้ library ในสองรูปแบบ

| รูปแบบ | ลักษณะ | ใช้ทำอะไร |
|---|---|---|
| **working library** | เปลี่ยนแปลงได้ตลอดเวลา | เก็บโค้ดที่คุณคอมไพล์เอง |
| **resource library** | มักคงที่ ไม่เปลี่ยนแปลง | เป็นแหล่งของ component เช่น model ของผู้ผลิตชิป |

working library ที่ใช้บ่อยที่สุดชื่อ `work` เป็นค่าเริ่มต้นของคอมไพลเลอร์

### 1.1 โครงสร้างของ library บนดิสก์

library คือโฟลเดอร์ธรรมดาที่มีไฟล์ `_info` อยู่ข้างใน
ไฟล์ `_info` นี้คือสิ่งที่บอกเครื่องมือว่า "โฟลเดอร์นี้เป็น library"

> ห้ามแก้ไขหรือลบไฟล์ภายในโฟลเดอร์ library ด้วยมือ
> ให้จัดการผ่านคำสั่งของเครื่องมือเสมอ

### 1.2 ข้อดีที่สำคัญ

รูปแบบไฟล์ library ของ Questa **เหมือนกันทุกแพลตฟอร์มที่รองรับ**
จึงคอมไพล์ครั้งเดียวแล้วเอาไปจำลองบนเครื่องอื่นได้โดยไม่ต้องคอมไพล์ใหม่
เหมาะกับทีมที่ใช้เครื่องต่างกัน

---

## 2. Basic simulation flow

Questa SIM Tutorial อธิบาย flow พื้นฐานไว้ 4 ขั้นตอน

### ขั้นตอนที่ 1 — สร้าง working library

```bash
vlib work
vmap work work
```

คำสั่งทั้งสองนี้เป็นคู่กัน
`vlib` สร้างโฟลเดอร์ ส่วน `vmap` ผูกชื่อโลจิคาล `work` เข้ากับตำแหน่งจริง
เมื่อทำผ่านหน้าต่าง **File → New → Library** เครื่องมือจะพิมพ์สองบรรทัดนี้ลง
ในหน้าต่าง Transcript ด้วย

### ขั้นตอนที่ 2 — คอมไพล์ design unit

```bash
vcom -2008 -work work src/counter_tut.vhd
vcom -2008 -work work tb/tb_counter_tut.vhd
```

รายละเอียดของคำสั่งนี้อยู่ใน[บทที่ 3](03-compile-vhdl.md)

### ขั้นตอนที่ 3 — โหลด design และเริ่มจำลอง

```bash
vsim -c -work work -do "run -all; quit -f" tb_counter_tut
```

สวิตช์ `-c` คือโหมดบรรทัดคำสั่ง ไม่เปิดหน้าต่างกราฟิก
ถ้าไม่ใส่ `-c` เครื่องมือจะเปิด GUI พร้อมหน้าต่าง Transcript, Wave และอื่น ๆ

หลังโหลดสำเร็จ เวลาของ simulation จะเริ่มที่ศูนย์
และต้องสั่ง `run` เพื่อให้เวลาเดิน

### ขั้นตอนที่ 4 — ตรวจผลลัพธ์

ถ้าไม่ได้ผลตามที่คาด ให้ใช้เครื่องมือ debug ของ Questa หาสาเหตุ
รายละเอียดอยู่ใน[บทที่ 6](06-waveform.md) และ[บทที่ 7](07-debugging.md)

---

## 3. Project flow

**project** คือกลไกเก็บกลุ่มไฟล์ของ design พร้อมการตั้งค่าการจำลอง

การใช้ project มีข้อดีสองข้อเมื่อเทียบกับ basic flow

1. **ไม่ต้องสร้าง working library เอง** — เครื่องมือทำให้อัตโนมัติ
2. **project มีอยู่ตลอด** — จะเปิดกลับมาเป็น project เดิมทุกครั้งที่เรียกเครื่องมือ
   จนกว่าจะสั่งปิด project โดยเฉพาะ

ในแง่ VHDL project คืออีกทางเลือกหนึ่งของ basic flow
โค้ดยังต้องคอมไพล์ด้วย `vcom` และต้องเรียก DUT ด้วย `entity work.<name>` เหมือนเดิม
ต่างกันแค่วิธีจัดการไฟล์และการจำค่าตั้ง

> **ห้ามสับสน `Project` กับ `library`**
> project คือโครงสร้างการจัดการไฟล์ ส่วน library คือที่เก็บโค้ดที่คอมไพล์แล้ว
> ทุก project ยังต้องมี library เพื่อเก็บ design unit

---

## 4. Multiple library flow

เมื่อโปรเจกต์มีหลายไลบรารี เช่น กรณีที่ testbench อยู่ใน working library
แต่ DUT อ้างอิง model ของผู้ผลิตชิปที่อยู่ในอีกไลบรารีหนึ่ง

คำสั่งที่เกี่ยวข้อง

```bash
# ดูรายการไลบรารีที่ผูกไว้ทั้งหมด
vmap

# ผูกไลบรารีเพิ่มเติม
vmap vendor_lib /opt/pdk/lib/vendor_lib
```

เมื่อคอมไพล์ ระบุว่าจะคอมไพล์เข้าไลบรารีใดด้วย `-work`

```bash
vcom -2008 -work work tb/tb_counter_tut.vhd
```

### 4.1 ลำดับการค้นหาไลบรารี

เมื่อโค้ด VHDL เขียน `library vendor_lib; use vendor_lib.pkg.all;`
เครื่องมือจะหา `pkg` ในไลบรารี `vendor_lib` ที่ผูกไว้
ถ้าไม่พบจะรายงานข้อผิดพลาดว่าไม่พบ package

> ข้อผิดพลาดที่พบบ่อยคือ **ผูกไลบรารีไว้แล้วแต่ผูกผิดพาธ**
> หรือผูกไว้กับเครื่องอื่นที่ path ไม่เหมือนกัน
> ให้ตรวจด้วย `vmap` ทุกครั้งที่เปลี่ยนเครื่อง

### 4.2 เมื่อใช้ร่วมกับ project

ถ้าใช้ project จะเปลี่ยนขั้นตอนแรกของ multiple library flow
เป็นการสร้าง project แล้วเพิ่ม testbench เข้าไปใน project
แทนที่จะสร้าง working library เอง

---

## 5. Design optimization และ switch `+acc`

### 5.1 การ optimize โดยอัตโนมัติ

โดยค่าเริ่มต้น Questa จะ optimize design ทุกตัวโดยอัตโนมัติ
เพื่อเพิ่มความเร็วการจำลอง (เอกสารระบุว่าได้ความเร็วเพิ่มสูงสุดประมาณ 10 เท่า
ในบางงาน Verilog)

เครื่องมือที่ทำหน้าที่นี้คือ **`vopt`**

### 5.2 ผลข้างเคียงที่ต้องรู้

> การ optimize ระดับ global อาจทำให้ **มองไม่เห็นบางสัญญาณและ process**
> ในผลลัพธ์การจำลอง
> ถ้าสัญญาณที่ต้องการ debug เป็นสัญญาณสำคัญ อาจต้องปิดการ optimize
> เฉพาะบาง module

คำสั่ง `vopt` พร้อม switch `+acc` จะเปิดการมองเห็น design unit ทั้งหมด

```bash
vopt +acc test_counter -o testcounter_opt
vsim testcounter_opt
```

| ส่วนของคำสั่ง | ความหมาย |
|---|---|
| `+acc` | เปิดการเข้าถึงทุก design unit เพื่อการ debug |
| `test_counter` | ชื่อ top-level ที่จะ optimize |
| `-o testcounter_opt` | ชื่อไฟล์ผลลัพธ์ |

> **ห้ามลืม `-o`** — คำสั่ง `vopt` ต้องมีชื่อไฟล์ผลลัพธ์เสมอ
> คำสั่งจะไม่ทำงานถ้าไม่ระบุ

### 5.3 กรณีของ VHDL

สำหรับโค้ด VHDL ที่คอมไพล์จาก source โดยตรง
การมองเห็นสัญญาณทำได้ด้วยการส่ง `+acc` ให้ `vsim` โดยตรง

```bash
vsim +acc work.tb_counter_tut
```

การเรียก `vopt` แยกต่างหากมีประโยชน์เมื่อต้องการเก็บ design ที่ optimize แล้ว
ไปใช้ซ้ำหลายครั้ง หรือเมื่อ design เป็น gate-level netlist ที่คอมไพล์มาแล้ว

> ถ้าสัญญาณไม่ปรากฏในหน้าต่าง Wave ให้ลองเพิ่ม `+acc` ก่อน
> แล้วจึงพิจารณาปัญหาอื่น ดู[บทที่ 6](06-waveform.md)

---

## 6. เครื่องมือ debug ที่ Questa มีให้

Questa มีเครื่องมือ debug หลากหลาย คู่มือนี้จะลงรายละเอียดเฉพาะที่จำเป็นต่อ VHDL

| เครื่องมือ | บทที่อธิบาย |
|---|---|
| ใช้ project | [บทที่ 2](#3-project-flow) |
| ทำงานกับหลายไลบรารี | [บทที่ 2](#4-multiple-library-flow) |
| ตั้ง breakpoint และ step ทีละบรรทัด | [บทที่ 7](07-debugging.md) |
| ดู waveform และวัดเวลา | [บทที่ 6](06-waveform.md) |
| ดูโครงสร้างการเชื่อมต่อของ design | [บทที่ 5](05-gui-workflow.md) |
| ดูและกำหนดค่าเริ่มต้นของ memory | [บทที่ 6](06-waveform.md) |
| สร้าง stimulus ด้วย Waveform Editor | [บทที่ 8](08-stimulus-and-forcing.md) |
| วิเคราะห์ประสิทธิภาพการจำลอง | — |
| ทดสอบ code coverage | — |
| เทียบ waveform สองชุด | [บทที่ 6](06-waveform.md) |
| debug ด้วย PSL assertion | — |
| ใช้ SystemVerilog assertion และ cover directive | — |
| ใช้ SystemVerilog DPI | — |
| ทำ simulation อัตโนมัติ | [บทที่ 10](10-tcl-and-batch.md) |

---

## แบบฝึกหัดท้ายบท

1. สร้าง working library ด้วย `vlib work` แล้วตรวจด้วย `vmap` ว่าผูกถูกตำแหน่ง
2. สังเกตว่าโฟลเดอร์ `work` ที่ถูกสร้างมีไฟล์อะไรบ้าง และไฟล์ใดทำหน้าที่ระบุว่า
   เป็น library
3. คอมไพล์ `ex00_counter_tutorial` แล้วรัน `vsim` โดยไม่ใส่ `+acc`
   จากนั้นเปิดหน้าต่าง Wave แล้วสังเกตว่าเห็นสัญญาณครบหรือไม่
4. รันซ้ำโดยเพิ่ม `+acc` แล้วเทียบความครบถ้วนของสัญญาณที่เห็น
5. อธิบายว่าทำไมการมี project จึงไม่ต้องสร้าง working library เอง

---

## คำถามท้ายบท

1. working library ต่างจาก resource library อย่างไร
2. คำสั่ง `vlib` และ `vmap` ทำหน้าที่อะไรต่างกัน
3. ข้อดีของการ optimize design คืออะไร และเสียหายอย่างไร
4. switch `+acc` มีผลต่ออะไร และควรใช้เมื่อใด
5. ทำไมโค้ดที่คอมไพล์บนเครื่องหนึ่งจึงเอาไปจำลองบนเครื่องอื่นได้

---

**อ่านต่อ:** [บทที่ 3 — คอมไพล์ VHDL](03-compile-vhdl.md) →
[บทที่ 4 — โหลดและ elaborate](04-load-and-elaborate.md) →
[บทที่ 3 — รูปแบบและการตั้งชื่อของคู่มือ VHDL](../vhdl/03-style-and-naming.md)
