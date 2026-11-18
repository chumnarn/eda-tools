# บทที่ 5: การทำงานแบบ GUI

> หน้าต่างกราฟิกของ Questa SIM และวิธีใช้แต่ละหน้าต่าง
> สำหรับผู้ที่เพิ่งเริ่มใช้เครื่องมือและอยากเห็นภาพรวมของ design

**เครื่องมือที่เกี่ยวข้อง:** Questa SIM
**ที่มาของเนื้อหา:** Questa SIM Tutorial 2026.1 หัวข้อ Basic Simulation

---

## สารบัญบท

- [1. เปิดเครื่องมือครั้งแรก](#1-เปิดเครื่องมือครั้งแรก)
- [2. หน้าต่างหลัก](#2-หน้าต่างหลัก)
- [3. Compile จากหน้าต่าง](#3-compile-จากหน้าต่าง)
- [4. Start Simulation](#4-start-simulation)
- [5. การดูโครงสร้างของ design](#5-การดูโครงสร้างของ-design)
- [6. หน้าต่าง Objects และ Processes](#6-หน้าต่าง-objects-และ-processes)
- [7. หน้าต่าง Source](#7-หน้าต่าง-source)
- [8. Transcript prompt](#8-transcript-prompt)
- [9. เมนูที่ควรรู้](#9-เมนูที่ควรรู้)

---

## 1. เปิดเครื่องมือครั้งแรก

### 1.1 เปิดเครื่องมือ

```bash
vsim
```

บน Windows ให้ใช้ไอคอน Questa SIM ใน Start menu

เมื่อเปิดครั้งแรกจะมีหน้าต่าง **Welcome to Questa SIM** ขึ้นมา
ให้กด **Close** เพื่อปิด

### 1.2 เปลี่ยนไดเรกทอรีทำงาน

เลือก **File → Change Directory** แล้วชี้ไปที่โฟลเดอร์ที่เก็บโค้ด

> หน้าต่าง Transcript จะแสดงคำสั่งที่คุณสั่งจากเมนู
> เช่นเมื่อสร้าง library จะเห็นข้อความ `vlib work` และ `vmap work work`
> ข้อความเหล่านี้คือคำสั่งที่เทียบเท่ากับการคลิกในเมนู
> **ใช้ประโยชน์ได้สองทาง** — ใช้เรียนรู้ว่าคำสั่งจริงเป็นอะไร
> และใช้คัดลอกไปใส่ในสคริปต์ได้

---

## 2. หน้าต่างหลัก

| หน้าต่าง | หน้าที่ | เปิดอย่างไร |
|---|---|---|
| **Transcript** | บันทึกคำสั่งทุกคำสั่งและข้อความจากเครื่องมือ | เปิดโดยอัตโนมัติ |
| **Library** | แสดงไลบรารีและ design unit ที่คอมไพล์แล้ว | **View → Library** |
| **Structure (sim)** | แสดง hierarchy ของ design ที่โหลดอยู่ | เปิดโดยอัตโนมัติเมื่อมี simulation |
| **Objects** | แสดงชื่อและค่าปัจจุบันของ data object | **View → Objects** |
| **Processes** | แสดงรายชื่อ process ที่กำลังทำงาน | **View → Process** |
| **Wave** | แสดง waveform ของสัญญาณ | **View → Wave** หรือพิมพ์ `view wave` |
| **Source** | แสดงไฟล์ต้นฉบับพร้อมจุดหยุด | **View → Files** แล้วดับเบิลคลิกไฟล์ |
| **Tcl Console** | รันคำสั่ง Tcl โดยตรง | **View → Tcl Console** |
| **WLF Wave** | แสดงข้อมูล waveform ที่บันทึกไว้ | **View → Wave** แล้วเลือกแท็บ WLF |

> ถ้าหน้าต่างใดถูกปิดไป ให้เปิดใหม่ได้จากเมนู **View**
> หน้าต่างส่วนใหญ่จัดตำแหน่งได้ด้วยการลากขอบ

---

## 3. Compile จากหน้าต่าง

1. เลือก **Compile → Compile**
   จะเปิดหน้าต่าง **Compile Source Files**
2. เลือกไฟล์ที่ต้องการ แล้วกด **Compile**
3. เมื่อเสร็จแล้วกด **Done**

> **หากเมนู Compile ใช้ไม่ได้** แสดงว่ามี project เปิดอยู่
> ให้ทำให้หน้าต่าง Library เป็นหน้าต่างที่ active แล้วเลือก
> **File → Close** เพื่อปิด project

### 3.1 ดูผลการคอมไพล์

ในหน้าต่าง Library ให้กดเครื่องหมาย `+` ข้าง library `work`
จะเห็น design unit ที่คอมไพล์แล้ว พร้อมชนิดของแต่ละอัน
(Modules, Entities, Architectures) และพาธของไฟล์ต้นฉบับ

---

## 4. Start Simulation

เลือก **Simulate → Start Simulation** หรือพิมพ์ที่ prompt

```text
vsim work.tb_counter_tut
```

ในหน้าต่าง **Start Simulation** สามารถกำหนดได้

| ช่อง | ใช้ทำอะไร |
|---|---|
| Top Level | entity หรือ configuration ที่จะโหลด |
| Simulation Options | ตัวเลือกของ `vsim` |
| Design Units | เลือก design unit ที่จะโหลด |
| Libraries | เลือกไลบรารีที่มองเห็น |
| Optimization Options | ตัวเลือกของ `vopt` เช่น `+acc` |

เมื่อโหลดสำเร็จ เวลาของ simulation จะเริ่มที่ศูนย์
ต้องสั่ง `run` เพื่อให้เวลาเดิน

---

## 5. การดูโครงสร้างของ design

หน้าต่าง **Structure (sim)** แสดง hierarchy ของ design ที่โหลดอยู่

- คลิกขยายโหนดเพื่อดู instance ที่อยู่ข้างใต้
- คลิกขวาที่สัญญาณในโหนดใดแล้วเลือก **Add Wave** เพื่อเพิ่มลงหน้าต่าง Wave
- สัญญาณที่อยู่ในระดับบนสุดจะอยู่ใต้ชื่อ top-level โดยตรง
- สัญญาณที่อยู่ภายใน instance จะอยู่ใต้ชื่อ instance

> สำหรับ VHDL โครงสร้าง hierarchy จะแสดง entity ที่เป็น instance
> ซึ่งต่างจาก Verilog ที่แสดงเป็น module

---

## 6. หน้าต่าง Objects และ Processes

### 6.1 หน้าต่าง Objects

แสดงชื่อและค่าปัจจุบันของ data object ใน region ที่เลือกไว้ในหน้าต่าง Structure

data object ที่แสดงได้แบ่งเป็น

- signal และ net
- register
- constant
- variable ที่ประกาศนอก process
- generic และ parameter
- member data variable ของโมดูล SystemC

> สำหรับ VHDL ค่าที่แสดงจะเป็นค่าของ `std_logic` ที่อาจเป็น `U`, `X`, `Z` หรือ `-`
> ไม่ใช่แค่ 0 หรือ 1 ดูความหมายของแต่ละค่าใน[บทที่ 6](06-waveform.md)

### 6.2 หน้าต่าง Processes

แสดงรายชื่อ process ในโหมดการดู 4 แบบ

| โหมด | ใช้ดูอะไร |
|---|---|
| **Active** | process ที่กำลังทำงานอยู่ใน simulation ปัจจุบัน (ค่าเริ่มต้น) |
| **In Region** | process ที่อยู่ใน region ปัจจุบัน |
| **Design** | ใช้นำทางใน design ระดับ ESL ที่ process เป็นสิ่งสำคัญที่สุด |
| **Hierarchical** | process แยกตามระดับของ hierarchy |

> ถ้าไม่เห็น process ที่คาดว่าจะเห็น ให้ตรวจว่า process นั้นกำลังรออยู่
> เช่น process ที่รอ `wait until rising_edge(clk)` จะไม่ทำงานในรอบนาฬิกาปัจจุบัน

---

## 7. หน้าต่าง Source

หน้าต่าง **Source** แสดงไฟล์ต้นฉบับของ VHDL พร้อมตำแหน่งที่จะตั้ง breakpoint ได้

### 7.1 เปิดไฟล์

1. เลือก **View → Files** เพื่อเปิดหน้าต่าง Files
2. คลิก `+` ข้างชื่อไฟล์ `sim` เพื่อดูเนื้อหาของ dataset `vsim.wlf`
3. ดับเบิลคลิกชื่อไฟล์ `.vhd` เพื่อเปิดในหน้าต่าง Source

### 7.2 ตั้ง breakpoint

> **ห้ามตั้ง breakpoint บนบรรทัดที่ไม่ใช่คำสั่งที่ทำงานได้**
> Questa SIM Tutorial ระบุว่า breakpoint ตั้งได้เฉพาะบรรทัดที่มี
> เลขบรรทัดสีแดง

วิธีทำ

1. เลื่อนไปยังบรรทัดที่ต้องการ
2. คลิกในคอลัมน์ `Ln#` (เลขบรรทัด) ถัดจากเลขบรรทัดนั้น
3. จะมีจุดสีแดงปรากฏแสดงว่าตั้ง breakpoint แล้ว

| สีของจุด | ความหมาย |
|---|---|
| สีแดง | breakpoint ทำงานอยู่ |
| สีเทา | breakpoint ถูกปิดใช้งาน |
| สีน้ำเงินพร้อมลูกศร | ตำแหน่งที่ simulation หยุดอยู่ |

คลิกจุดสีแดงเพื่อปิดใช้งาน คลิกซ้ำเพื่อเปิดใช้งาน
คลิกขวาแล้วเลือก **Remove Breakpoint** เพื่อลบ

### 7.3 ตำแหน่งของ breakpoint ใน VHDL ต่างจาก Verilog

> ในตัวอย่างของ Questa SIM Tutorial ตำแหน่งที่แนะนำให้ตั้ง breakpoint
> สำหรับไฟล์ Verilog `counter.v` อยู่ที่ **บรรทัด 36**
> แต่สำหรับไฟล์ VHDL `counter.vhd` อยู่ที่ **บรรทัด 39**
> แม้จะเป็นวงจรเดียวกันก็ตาม

เหตุผลคือโครงสร้างของแต่ละภาษาต่างกัน
VHDL มีบรรทัด `architecture`, `entity` และ `begin` ที่ Verilog ไม่มี
**ห้ามยกเลขบรรทัดจากเอกสารไปใช้กับโค้ดของตัวเองโดยไม่ตรวจสอบ**

---

## 8. Transcript prompt

หน้าต่าง Transcript มี prompt ชื่อ `VSIM>` สำหรับรันคำสั่งโดยตรง

| คำสั่ง | ผล |
|---|---|
| `run` | รันต่อจนกว่าจะหยุด |
| `run -all` | รันจนกว่า event queue จะว่าง |
| `run 500 ns` | รันไปข้างหน้า 500 นาโนวินาที |
| `run 500` | รันไปข้างหน้า 500 หน่วยเวลาของ simulation |
| `step` | ทำขั้นตอนถัดไป |
| `finish` | จบการจำลอง |
| `quit -f` | ออกจากเครื่องมือโดยไม่ถาม |
| `examine cnt` | พิมพ์ค่าปัจจุบันของสัญญาณ |
| `add wave -r /*` | เพิ่มสัญญาณทั้งหมดลงหน้าต่าง Wave |
| `view wave` | เปิดหน้าต่าง Wave |
| `show commands` | แสดงรายการคำสั่งทั้งหมดที่ใช้ได้ |

> คำสั่ง Tcl ทั้งหมดทำงานได้ที่ prompt นี้
> เมื่อพิมพ์คำสั่งที่ไม่รู้จัก เครื่องมือจะแนะนำคำสั่งที่ใกล้เคียงให้

---

## 9. เมนูที่ควรรู้

| เมนู | รายการที่ใช้บ่อย |
|---|---|
| **File** | Change Directory, New → Library, Close (project), Exit |
| **Compile** | Compile, Compile All |
| **Simulate** | Start Simulation, End Simulation, Restart, Break, Run, Continue |
| **Edit** | Copy, Paste, Find, Search |
| **View** | Objects, Process, Wave, Structure, Source, Files, Tcl Console |
| **Tools** | Waveform Editor, Memory Editor, Coverage |
| **Window** | สลับระหว่างหน้าต่าง |
| **Help** | เอกสาร ModelSim/Questa User's Manual ในตัวเครื่องมือ |

### 9.1 Restart

เมื่อกดปุ่ม **Restart** จะมีหน้าต่างถามว่าจะเก็บอะไรไว้ระหว่าง restart

| ตัวเลือก | ความหมาย |
|---|---|
| **Design** | โหลด design ใหม่จากไลบรารี |
| **Configuration** | โหลด configuration ใหม่ |
| **Generic values** | ใช้ค่า generic เดิมหรือค่าใหม่ |

### 9.2 End Simulation

เมื่อเสร็จงานให้เลือก **Simulate → End Simulation** แล้วกด **Yes**
เพื่อยืนยันการออกจากการจำลอง

> ถ้าไม่จบการจำลองแล้วสั่ง `run -all` อีกครั้ง
> เครื่องมือจะถามว่าต้องการจบ simulation หรือไม่
> การจบการจำลองอย่างเป็นระเบียบเป็นสิ่งที่ควรทำทุกครั้ง

---

## แบบฝึกหัดท้ายบท

1. เปิดเครื่องมือแล้วเปลี่ยนไดเรกทอรีไปที่
   `code/reference/questa/examples/ex00_counter_tutorial`
2. สร้าง library ผ่าน **File → New → Library** แล้วดูว่า Transcript
   พิมพ์คำสั่งอะไรบ้าง
3. คอมไพล์ไฟล์ทั้งสองไฟล์ผ่าน **Compile → Compile**
4. โหลด design ผ่าน **Simulate → Start Simulation** แล้วเปิดหน้าต่าง
   Objects, Processes, Wave และ Source
5. เปิดไฟล์ `.vhd` ในหน้าต่าง Source แล้วหาบรรทัดที่มีเลขสีแดง
   จากนั้นตั้ง breakpoint ที่บรรทัดนั้น สังเกตว่าจุดสีแดงปรากฏตรงไหน
6. สังเกตเลขบรรทัดของบรรทัดเดียวกันในไฟล์ `.vhd` กับในตัวอย่าง Verilog
   ของ Questa SIM Tutorial แล้วจดความต่าง

---

## คำถามท้ายบท

1. หน้าต่าง Transcript มีประโยชน์อย่างไรต่อการเรียนรู้การใช้เครื่องมือ
2. หน้าต่าง Objects กับ Processes แสดงข้อมูลคนละอย่างอย่างไร
3. เหตุใดจึงตั้ง breakpoint ได้เฉพาะบรรทัดที่มีเลขสีแดง
4. ทำไมเลขบรรทัดของโค้ด VHDL และ Verilog ที่เป็นวงจรเดียวกันจึงต่างกัน
5. `run` กับ `run -all` ต่างกันอย่างไร

---

**อ่านต่อ:** [บทที่ 6 — การวิเคราะห์ waveform](06-waveform.md) →
[บทที่ 7 — การ debug](07-debugging.md) →
[บทที่ 11 — การตรวจสอบหลักฐานของคู่มือ VHDL](../vhdl/11-verification-style.md)
