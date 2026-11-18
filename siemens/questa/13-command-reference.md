# บทที่ 13: ตารางคำสั่งทั้งหมด

> รวมคำสั่งที่ใช้ในคู่มือนี้ไว้ที่เดียว
> ใช้เป็นคลังค้นเมื่อจำไม่ได้ว่าคำสั่งที่ต้องการอยู่ตรงไหน

**เครื่องมือที่เกี่ยวข้อง:** Questa SIM

---

## สารบัญบท

- [1. คำสั่งระดับโปรแกรม](#1-คำสั่งระดับโปรแกรม)
- [2. การจัดการ library](#2-การจัดการ-library)
- [3. คอมไพล์](#3-คอมไพล์)
- [4. โหลดและ elaborate](#4-โหลดและ-elaborate)
- [5. ควบคุมการจำลอง](#5-ควบคุมการจำลอง)
- [6. ดูค่า](#6-ดูค่า)
- [7. Waveform](#7-waveform)
- [8. Debug](#8-debug)
- [9. Tcl และการทำงานอัตโนมัติ](#9-tcl-และการทำงานอัตโนมัติ)
- [10. คำสั่งฝังใน testbench](#10-คำสั่งฝังใน-testbench)

---

## 1. คำสั่งระดับโปรแกรม

| คำสั่ง | หน้าที่ |
|---|---|
| `vsim` | โหลด design เข้าสู่ simulator และเปิดหน้าต่างกราฟิก |
| `vsim -version` | แสดงเวอร์ชันของเครื่องมือ |
| `vsim -help` | แสดงรายการตัวเลือกทั้งหมด |
| `vcom` | คอมไพล์ไฟล์ VHDL |
| `vcom -help` | แสดงรายการตัวเลือกของคอมไพลเลอร์ |
| `vlib` | สร้าง library |
| `vlib -help` | แสดงรายการตัวเลือก |
| `vmap` | ผูกชื่อโลจิคาลของ library กับตำแหน่งจริง |
| `vdir` | แสดงรายการ design unit ใน library |
| `vdel` | ลบ design unit ออกจาก library |
| `vmap` ไม่มีอาร์กิวเมนต์ | แสดงรายการ library ที่ผูกไว้ทั้งหมด |
| `lmutil lmstat -a` | ตรวจสถานะใบอนุญาต (มาพร้อมเครื่องมือ) |

---

## 2. การจัดการ library

| คำสั่ง | หน้าที่ |
|---|---|
| `vlib work` | สร้างไลบรารีชื่อ `work` ในไดเรกทอรีปัจจุบัน |
| `vmap work work` | ผูกชื่อโลจิคาล `work` เข้ากับตำแหน่งจริง |
| `vmap <ชื่อ> <พาธ>` | ผูกไลบรารีที่ระบุ |
| `vmap -c` | ลบการผูกของไลบรารีทั้งหมด |
| `vdel -all -lib work` | ลบ design unit ทั้งหมดในไลบรารี `work` |
| `vdel <entity> -lib work` | ลบ design unit ที่ระบุ |

---

## 3. คอมไพล์

| คำสั่ง | หน้าที่ |
|---|---|
| `vcom -2008 -work work f.vhd` | คอมไพล์ด้วยมาตรฐาน VHDL-2008 เข้าไลบรารี `work` |
| `vcom -2002 -work work f.vhd` | คอมไพล์ด้วยมาตรฐาน VHDL-2002 |
| `vcom -93 -work work f.vhd` | คอมไพล์ด้วยมาตรฐาน VHDL-1993 |
| `vcom -quiet -work work f.vhd` | คอมไพล์โดยไม่พิมพ์ข้อความระหว่างทำงาน |
| `vcom -explicit -work work f.vhd` | ใช้เฉพาะ library ที่ระบุใน context clause |
| `vcom -check_synthesis -work work f.vhd` | ตรวจว่าโค้ดอยู่ใน synthesis subset |

---

## 4. โหลดและ elaborate

| คำสั่ง | หน้าที่ |
|---|---|
| `vsim -c -work work -do "run -all; quit -f" tb_x` | จำลองแบบไม่เปิด GUI |
| `vsim -gui -work work tb_x` | บังคับให้เปิด GUI |
| `vsim -do "..." tb_x` | รันคำสั่ง Tcl หลังโหลด design |
| `vsim -work work work.tb_x` | ระบุไลบรารีและ entity อย่างชัดเจน |
| `vsim -work work work.tb_x(tb)` | ระบุ architecture |
| `vsim -work work -config work.cfg_x` | โหลด configuration |
| `vsim -gNAME=value -work work tb_x` | กำหนดค่า generic ของ entity ระดับบนสุด |
| `vsim -t 10us -work work tb_x` | จำกัดเวลาจำลอง |
| `vsim -wlf out.wlf -work work tb_x` | บันทึกข้อมูล waveform เป็นไฟล์ WLF |
| `vsim -novopt -work work tb_x` | ไม่ optimize design |
| `vsim +acc -work work tb_x` | เปิดการเข้าถึง design unit ทั้งหมด |
| `vsim -quiet -work work tb_x` | ลดข้อความระหว่างโหลด |

---

## 5. ควบคุมการจำลอง

| คำสั่ง | หน้าที่ |
|---|---|
| `run` | รันต่อจนกว่าจะหยุด |
| `run -all` | รันจนกว่า event queue จะว่าง |
| `run 500 ns` | รันไปข้างหน้าเวลาที่กำหนด |
| `finish` | จบการจำลอง |
| `quit` | ออกโดยถามยืนยัน |
| `quit -f` | ออกทันทีโดยไม่ถาม |
| `quit -code <n>` | ออกโดยกำหนดรหัสออก |

---

## 6. ดูค่า

| คำสั่ง | หน้าที่ |
|---|---|
| `examine cnt` | พิมพ์ค่าปัจจุบันของสัญญาณ |
| `examine -radix hex cnt` | พิมพ์ค่าในฐานที่ระบุ |
| `examine -time cnt` | พิมพ์ค่าพร้อมเวลาที่เปลี่ยนแปลง |
| `examine -hierarchical cnt` | พิมพ์ค่าของวัตถุทั้งหมดใน hierarchy |
| `examine -lines cnt` | พิมพ์ค่าพร้อมเลขบรรทัดที่เปลี่ยน |
| `watch cnt` | พิมพ์ค่าอัตโนมัติทุกครั้งที่เปลี่ยน |
| `radix hexadecimal` | เปลี่ยนฐานเริ่มต้นของหน้าต่าง Wave |
| `gettime` | เวลาปัจจุบันของ simulation |

---

## 7. Waveform

| คำสั่ง | หน้าที่ |
|---|---|
| `view wave` | เปิดหน้าต่าง Wave |
| `add wave -r /*` | เพิ่มสัญญาณทุกตัวในทุกระดับ |
| `add wave cnt` | เพิ่มสัญญาณเดียว |
| `add wave -group <ชื่อ> <สัญญาณ>` | เพิ่มสัญญาณลงกลุ่ม |
| `add wave -divider <ชื่อ>` | แทรกเส้นคั่น |
| `add wave -radix hex <สัญญาณ>` | เพิ่มสัญญาณพร้อมกำหนดรูปแบบแสดงผล |
| `log -w <สัญญาณ> {<ช่วงเวลา>}` | กำหนดว่าจะบันทึกค่าของสัญญาณช่วงใดลง WLF |
| `measure time <t1> <t2>` | วัดระยะเวลาระหว่างสองจุดเวลา |
| `search -match <ข้อความ> transcript` | ค้นหาข้อความใน Transcript |

---

## 8. Debug

| คำสั่ง | หน้าที่ |
|---|---|
| `step` | ทำขั้นตอนถัดไปเข้าไปใน procedure |
| `step -over` | ทำขั้นตอนถัดไปโดยไม่เข้า procedure |
| `next` | ทำขั้นตอนถัดไปในระดับเดียวกัน |
| `break` | แสดงรายการ breakpoint |
| `break <ไฟล์>:<บรรทัด>` | ตั้ง breakpoint ที่บรรทัดที่ระบุ |
| `break <ไฟล์>:<บรรทัด> if <เงื่อนไข>` | ตั้ง breakpoint พร้อมเงื่อนไข |
| `break -delete` | ลบ breakpoint ทั้งหมด |
| `break -disable <เลข>` | ปิดใช้งาน breakpoint |
| `break -enable <เลข>` | เปิดใช้งาน breakpoint |
| `force <วัตถุ> <ค่า>` | บังคับค่าสัญญาณ |
| `release <วัตถุ>` | คืนการขับสัญญาณ |
| `deposit <วัตถุ> <ค่า>` | ฝังค่าในเวลาปัจจุบันเท่านั้น |
| `mem load -infile <ไฟล์> <memory>` | โหลดค่าลง memory |
| `mem examine <memory> -address <ที่อยู่>` | ดูค่าใน memory |
| `mem change <memory> -address <ที่อยู่> <ค่า>` | เปลี่ยนค่าใน memory |

---

## 9. Tcl และการทำงานอัตโนมัติ

| คำสั่ง | หน้าที่ |
|---|---|
| `do <ไฟล์.do>` | โหลดและรันไฟล์ Tcl |
| `echo <ข้อความ>` | พิมพ์ข้อความลง Transcript |
| `puts <ข้อความ>` | พิมพ์ข้อความจาก Tcl |
| `onerror {<คำสั่ง>}` | กำหนดคำสั่งที่ทำเมื่อเกิด error |
| `onbreak {<คำสั่ง>}` | กำหนดคำสั่งที่ทำเมื่อเจอ breakpoint |
| `when {<เงื่อนไข>} {<คำสั่ง>}` | กำหนดคำสั่งที่ทำเมื่อเงื่อนไขเป็นจริง |
| `transcript file <ชื่อไฟล์>` | กำหนดไฟล์ที่บันทึก Transcript |
| `transcript on` / `transcript off` | เปิด/ปิดการบันทึก Transcript |
| `set <ตัวแปร> <ค่า>` | กำหนดค่าตัวแปร Tcl |
| `info exists <ตัวแปร>` | ตรวจว่ามีตัวแปรนั้นอยู่หรือไม่ |
| `catch {<คำสั่ง>} <ผล>` | รันคำสั่งและจับข้อผิดพลาด |
| `foreach <ตัวแปร> <รายการ> {<ลูป>}` | วนลูป |
| `vsim -c -do "..."` | รันเครื่องมือแบบไม่เปิด GUI พร้อมคำสั่ง Tcl |

---

## 10. คำสั่งฝังใน testbench

คำสั่งเหล่านี้เป็นของภาษา VHDL ไม่ใช่คำสั่งของ simulator
แต่เป็นส่วนที่ต้องใช้คู่กับเครื่องมือ

| คำสั่ง | หน้าที่ |
|---|---|
| `report "<ข้อความ>" severity <ระดับ>;` | พิมพ์ข้อความลง Transcript |
| `assert <เงื่อนไข> report "..." severity <ระดับ>;` | ตรวจเงื่อนไขและรายงานเมื่อไม่ผ่าน |
| `wait for <เวลา>;` | รอเวลา |
| `wait until <เงื่อนไข>;` | รอจนกว่าเหตุการณ์ที่ทำให้เงื่อนไขเป็นจริง |
| `wait until rising_edge(<สัญญาณ>);` | รอขอบขึ้นของสัญญาณ |
| `wait until falling_edge(<สัญญาณ>);` | รอขอบลงของสัญญาณ |
| `std.env.stop;` / `std.env.finish;` | หยุด simulation — ใช้ได้เฉพาะ VHDL-2008 |
| `file_open` / `readline` / `read` / `endfile` | อ่าน stimulus จากไฟล์ด้วย `std.textio` |

> `wait until` รอ **เหตุการณ์** ไม่ใช่เงื่อนไข
> ถ้าเงื่อนไขเป็นจริงอยู่แล้วโดยไม่มี event ใหม่ process จะค้าง
> รายละเอียดอยู่ใน[บทที่ 11 ของคู่มือ VHDL](../vhdl/11-verification-style.md)

---

## แบบฝึกหัดท้ายบท

1. จงเลือกคำสั่งจากตารางนี้มา 10 คำสั่งที่ใช้บ่อยที่สุดในงานจริง
   พร้อมเขียนว่าใช้ทำอะไร
2. เขียนคำสั่ง `vsim` แบบ batch ที่ครบทุกอย่างสำหรับ
   `ex03_assert_severity` โดยระบุมาตรฐาน VHDL-2002 และ generic
3. ค้นหาในตารางว่าคำสั่งใดใช้ตรวจค่าที่อยู่ใน memory
4. เปรียบเทียบคำสั่งในหัวข้อ 5 กับหัวข้อ 9 ว่าคำสั่งใดซ้ำกันและต่างกันอย่างไร
5. จงเขียนคำสั่ง `vsim` ที่ใช้ทดสอบว่า `severity error` หยุด simulation หรือไม่

---

## คำถามท้ายบท

1. `force` กับ `deposit` ต่างกันอย่างไร และอยู่ในกลุ่มคำสั่งใด
2. คำสั่งใดที่ต้องใช้เมื่อต้องการให้ simulator หยุดและคืนรหัสออกที่ถูกต้อง
3. `run -all` ต่างจาก `finish` อย่างไร
4. คำสั่งใดที่เป็นของภาษา VHDL ไม่ใช่ของ simulator
5. `wait until` รออะไร และทำไมจึงอาจทำให้ process ค้าง

---

**อ่านต่อ:** [บทที่ 14 — เช็กลิสต์](14-checklists.md) →
[ภาคผนวก A — ศัพท์อ้างอิง](appendix-a-glossary.md) →
[บทที่ 14 — เช็กลิสต์ก่อนส่งงานของคู่มือ VHDL](../vhdl/15-checklists.md)
