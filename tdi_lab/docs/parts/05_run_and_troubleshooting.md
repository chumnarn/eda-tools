
## บทที่ 5 — การรัน TDI จริง และการแก้ปัญหา

บทนี้เป็นส่วนที่ต้องมีเครื่อง Linux ที่ติดตั้ง Nitro
แต่ขั้นตอนการเตรียมทั้งหมดก่อนกด Run สามารถทำบนเครื่อง Windows ได้

### 5.1 ขั้นตอนใน L-Edit ตั้งแต่ต้นจนจบ

#### ขั้นที่ 1 — เปิดดีไซน์และดู RTL

1. เปิด S-Edit
2. `File > Open > Open Design...` แล้วเลือกไฟล์
   `Documents\SiemensEDA\CustomIC_2025.4\Designs\ADC8\lib.defs`
3. เปิด view ชื่อ `verilog_rtl` ของ cell `ADCCtrl` ใน library `ADC8`
4. ตรวจดูพอร์ตของโมดูล — สังเกตว่า `B` เป็นบัส 8 บิต

> ขั้นนี้เป็นแค่การดู ไม่ต้องทำอะไรกับไฟล์
> ใช้เพื่อยืนยันว่า interface ที่คุณเห็นตรงกับที่ lab 01 ตรวจได้

#### ขั้นที่ 2 — เตรียม boundary และพอร์ตในเลย์เอาต์

1. เปิด L-Edit แล้วเปิดดีไซน์เดิม (`Designs\ADC8\lib.defs`)
2. เปิด view ชื่อ `layout` ของ cell `ADCCtrl`
3. กด `Ctrl+A` เพื่อเลือกทั้งหมด จะเห็นกรอบสี่เหลี่ยมบนเลเยอร์
   `prBoundray:drawing` คือ boundary ของบล็อก
4. ยืนยันว่าเลเยอร์นี้ถูกตั้งเป็น **Icon Layer**
   โดยไปที่ `Setup > Special Layers...` ดูค่า Icon Layer
5. หาพอร์ต: กด `Ctrl+F` (Find) ให้ติ๊กที่ `Port` และเว้นช่องว่าง
   แล้วกด `Find Next` จะซูมไปที่พอร์ต `clk`

> **ทำไมต้องเป็น Icon Layer**
>
> เพราะนี่คือสัญญาที่บอก L-Edit ว่า "รูปนี้คือขอบเขตที่ให้วางได้"
> ไม่ใช่แค่เส้นหรือรูปที่วาดไว้เฉย ๆ
> ถ้าเปลี่ยนชื่อเลเยอร์ ต้องไปแก้ค่า Icon Layer ตามด้วยเสมอ

#### ขั้นที่ 3 — เปิดหน้าต่าง Setup TDI

กดปุ่ม **Setup TDI** บนแถบเครื่องมือ Nitro ใน L-Edit
จะเปิดหน้าต่างที่มี 7 หน้า ดูรายละเอียดของแต่ละหน้าในบทที่ 2

#### ขั้นที่ 4 — กรอกค่า

สรุปค่าที่ต้องใส่สำหรับตัวอย่าง ADC8 / ADCCtrl

| หน้า | ค่า |
|---|---|
| **Run File** | Data Directory = โฟลเดอร์ข้อมูลของ run |
| **Tech and Lib** | LEF: `Generic250nm_tech.lef` แล้วค่อย `Generic250nm_StdCells.lef`<br>Liberty: `Generic250nm_TT_2P50V_25C.lib`<br>PTF: `Generic250nm_typ.ptf` |
| **Netlist/RTL** | RTL: `ADCCtrl_rtl.v`<br>Top Cell: `ADCCtrl`<br>Power Net: `Vdd` / Ground Net: `Gnd` |
| **Timing** | โหมด SDC พร้อมไฟล์ `timing_constraints_full.sdc` |
| **Floorplan** | Export from layout (ใช้ boundary ที่วาดไว้) |
| **Power Plan** | แนวตั้ง Metal4, แนวนอน Metal3<br>ลำดับวง: Vdd นอก, Gnd ใน<br>width 2.0 / 1.5 µm, spacing 0.6 µm |
| **Additional Commands** | ว่างไว้ก่อน (ค่าเริ่มต้นของ flow ใช้ได้) |

#### ขั้นที่ 5 — กด Run

กดปุ่ม **Run** จะมีหน้าต่างแสดง log ความคืบหน้า
เมื่อเสร็จแล้วกด **Close** แล้วเลย์เอาต์ที่วางเสร็จจะปรากฏ

### 5.2 สิ่งที่เกิดขึ้นบนเครื่อง Linux

หลังกด Run ไฟล์ทั้งหมดในโฟลเดอร์ข้อมูลจะถูกคัดลอกไปที่

```bash
/tmp/<ชื่อผู้ใช้>_nitro_data
```

จากนั้น flow จะทำงานตามขั้นตอนนี้

```text
data_prep → rtl_synthesis → floorplan → powerplan → physical_synthesis
          → place → cts → post_cts → route → export
```

ตรวจสอบงานบนเครื่อง Linux ได้ด้วย

```bash
ls -la /tmp/$USER_nitro_data
ls -la /tmp/$USER_nitro_data/results
cat /tmp/$USER_nitro_data/results/reports/*.rpt | head -50
```

### 5.3 ผลลัพธ์ที่ได้กลับมา

| ไฟล์ใน `results/` | เนื้อหา |
|---|---|
| `<top>_syn.v` | netlist ระดับ gate ที่ synthesis สร้าง |
| `<top>_scan.def` | นิยาม scan chain (เมื่อเปิด scan) |
| `reports/` | รายงานของทุกขั้นตอน |
| `Kpi.html` | สรุปตัวชี้วัดหลัก เปิดด้วยเบราว์เซอร์ได้ |

**รายงานที่ควรดูก่อนเสมอ**

| ไฟล์ | บอกอะไร |
|---|---|
| `results/reports/*timing*.rpt` | slack ของเส้นทางเวลาที่แย่ที่สุด |
| `results/reports/*place*.rpt` | ผลวางเซลล์ ความหนาแน่นจริงที่ได้ |
| `results/reports/*route*.rpt` | ผลเดินสาย จำนวน violation |
| `results/reports/*power*.rpt` | รายงานแผนจ่ายไฟและ IR drop |

### 5.4 ตารางแก้ปัญหา

อาการ → สาเหตุที่เป็นไปได้ → ทำอะไร

| อาการ | สาเหตุที่เป็นไปได้ | วิธีแก้ |
|---|---|---|
| `FLOW-ERROR : Nb of ring spacing values does not match number of intervals between supplies` | ใส่ `pg_ring_spacing` ผิดจำนวน | ใส่ 1 ค่า หรือ จำนวนแหล่งจ่าย − 1 (หัวข้อ 2.6) |
| `FLOW-ERROR : Nb of ring width values does not match number of supplies` | ใส่ `pg_ring_widths` ผิดจำนวน | ใส่ 1 ค่า หรือ จำนวนแหล่งจ่าย |
| `FLOW-ERROR : PG ring spacing constraint is smaller than ... min_spacing` | spacing ของ ring ชิดเกินกฎของชั้นโลหะ | เพิ่ม `pg_ring_spacing` ให้มากกว่า min spacing ใน LEF (lab 03) |
| `FLOW-ERROR: Number of RLC models ... does not match number of RLC files` | `rlc_file_list` กับไฟล์ RLC ไม่ตรงกัน | ล้าง `rlc_file_list` ให้ว่าง ถ้าใช้ PTF อยู่แล้ว |
| flow อ่าน LEF ล้มเหลว | tech LEF ไม่ได้มาก่อน standard cell LEF | สลับลำดับในหน้า Tech and Lib (lab 06) |
| synthesis หาเซลล์ไม่เจอ | Liberty กับ LEF ไม่ตรงกัน | เทียบรายชื่อเซลล์ทั้งสองไฟล์ (lab 03) |
| พังตอนใส่ tie cell | `tie_high_libcell` / `tie_low_libcell` ชี้เซลล์ที่ไม่มีใน LEF | ตรวจว่าเซลล์ tie มีทั้งใน LEF และ Liberty |
| flow ทำงานแต่ผลลัพธ์ผิด | ตัวแปรหายไป → TCL อ่านเป็นค่าว่าง | รัน lab 06 เพื่อเช็กสัญญา |
| หาไฟล์รายงานไม่เจอ | รายงานอยู่ใน `reports/` แล้วถูกย้ายตอนปิดงาน | ดูทั้ง `results/reports/` และ `reports/` |
| ไม่เจอพอร์ตของ scan | DEF ถูก export ก่อนเพิ่มพอร์ต scan | เพิ่มพอร์ตแล้ว export DEF ใหม่ (lab 05) |
| `nit_write.lock` ค้าง | งานก่อนหน้าถูกปิดไม่สะอาด | ลบไฟล์ lock ใน `/tmp/<user>_nitro_data` แล้วรันใหม่ |

### 5.5 ลำดับที่แนะนำในการทำงานจริง

```text
  1. แก้ RTL ให้เสร็จ
        ↓
  2. วาง boundary + พอร์ตในเลย์เอาต์ แล้ว export DEF
        ↓
  3. รัน lab 01–05 เพื่อตรวจอินพุตทั้งหมด   ← ตรงนี้ที่เสียเวลาน้อยที่สุด
        ↓
  4. ตั้งค่า Setup TDI ตามบทที่ 2
        ↓
  5. ตรวจอีกครั้งด้วย lab 06 (ถ้าแก้ไฟล์ตั้งค่าเอง)
        ↓
  6. กด Run แล้วรอ
        ↓
  7. อ่านรายงาน: timing → place → route → power
        ↓
  8. แก้แล้ววนกลับไปที่ข้อ 2 (ต้อง export DEF ใหม่ทุกครั้ง)
```

> **ข้อควรจำข้อสุดท้าย**
>
> ทุกครั้งที่แก้เลย์เอาต์ ต้อง **export DEF ใหม่** ก่อนกด Run
> DEF คือสัญญาระหว่างเลย์เอาต์กับ flow
> ถ้าไม่ export ใหม่ flow จะทำงานกับเลย์เอาต์เก่าโดยไม่บอก

---
