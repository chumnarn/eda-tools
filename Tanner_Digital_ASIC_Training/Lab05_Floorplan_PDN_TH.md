# Lab 5 — Floorplan/PDN
## กำหนด block boundary, pins, rows, supplies และ PG connections

**หลักสูตร:** Tanner Digital ASIC Design Implementation — ระดับเริ่มต้นถึงระดับกลาง  
**ระยะเวลาแนะนำ:** 3–4 ชั่วโมง รวมตรวจผลและทดลองสร้างข้อผิดพลาด  
**อินพุต:** mapped netlist, SDC และ library/technology setup ที่ผ่าน Lab 4  
**ผลลัพธ์:** floorplan และ PDN checkpoint ที่ตรวจพื้นที่วางเซลล์และการเชื่อมต่อไฟตามขอบเขตของ checks ที่ใช้ได้

> เกณฑ์สำเร็จ: placement area ถูกต้อง; ไม่มี PG open/short ที่ยังไม่ได้แก้ตาม checks ที่รันจริง พร้อมหลักฐานว่า checks ครอบคลุมวัตถุเป้าหมาย การไม่มี error จากรายงานที่ตรวจ 0 pins ไม่ถือว่าผ่าน

## 5.1 วัตถุประสงค์

เมื่อจบ Lab ผู้เรียนต้องสามารถ:

1. แยก block boundary, core boundary, row area และ effective placeable area ได้
2. คำนวณขนาดเริ่มต้นจาก mapped cell area และ utilization พร้อมตรวจค่าที่เครื่องมือสร้างจริงหลัง snap grid
3. กำหนดตำแหน่ง signal pins และ supply ports ที่ใช้เชื่อมกับ analog-on-top ได้
4. สร้าง placement rows ที่ตรงกับ site, cell height, orientation และ PG rail architecture ของ library
5. กำหนด supply nets และ map PG pins ตามชื่อที่มีอยู่จริงในแต่ละ view
6. ตรวจ logical PG assignment และ physical PG connectivity แยกกัน
7. อธิบายข้อจำกัดของผลตรวจระยะ floorplan และรายการที่ต้องตรวจซ้ำหลัง placement/CTS/route ได้

## 5.2 ขอบเขตและข้อกำหนดของเครื่องมือ

Siemens อธิบาย Digital Implementer ว่าเป็น flow ที่เริ่มจาก L-Edit มี setup wizard และ Tcl customization รวมถึง floorplanning และ power planning [R1] คู่มือนี้จึงใช้ขั้นตอนตามหน้าที่ของเครื่องมือ ไม่กำหนดชื่อเมนูหรือ Tcl command ของ TDI/Nitro ที่ยังไม่ได้ยืนยันกับรุ่นที่ติดตั้ง

ก่อนสอน ผู้สอนต้องผูกแต่ละขั้นเข้ากับ GUI, generated script และ help ของรุ่นที่ใช้จริง หากใช้ reference template ให้เก็บสำเนา script ต้นฉบับและบันทึกจุดที่แก้ ไม่สมมติว่าหมายเลข stage หรือชื่อไฟล์ script เหมือนกันทุก release

Lab นี้ทำ **digital block สำหรับ analog-on-top** ขอบเขต block ไม่ใช่ die boundary ของชิปทั้งหมด ไม่มีการกำหนด pad ring, ESD หรือ package ใน Lab นี้ ตัวอย่างชื่อ VDD/VSS หมายถึง supply domain เดียว ต้องแทนด้วยชื่อและ voltage ที่โครงการอนุมัติ ห้ามรวม analog/digital supplies เพราะเห็นว่าเป็นชื่อใกล้เคียงกัน

ในขั้น floorplan เซลล์อาจยังไม่ถูกวาง จึงตรวจโครงข่ายหลักและ logical assignment ได้ แต่ยังยืนยัน physical connection ถึงทุก standard-cell pin ไม่ได้ ต้องแสดงสถานะ pending ของส่วนนี้และตรวจซ้ำหลัง placement/PG hookup หากต้องการปิดเกณฑ์ all-cell connectivity ภายใน Lab ให้ทำ temporary placement บนสำเนา checkpoint แล้วตรวจตามขั้น 12

## 5.3 เตรียมข้อมูลก่อนเริ่ม

| รายการ | สิ่งที่ต้องยืนยัน | หลักฐาน |
|---|---|---|
| Netlist | top ถูกต้อง, ไม่มี unresolved cell, mapped กับ library ที่เลือก | Lab 4 log และ cell summary |
| SDC | clock/IO coverage ผ่านตามขอบเขต Lab 4 | constraint report |
| Technology | DBU, manufacturing grid, metal/via rules, routing layers | technology file revision |
| Cell abstracts | LEF/site, dimensions, symmetry, PG pin shapes และ obstructions | library manifest |
| Cell layout | physical master/GDS ตรงกับ abstract | view audit |
| Supply | net name, voltage, PG pin naming และ domain | power contract |
| Special cells | tap/endcap/tie/filler/decap ตาม flow ที่รองรับ | approved cell list |
| Checks | geometry/connectivity checker และขอบเขต rule deck | checker/version/deck |

อย่าเริ่มสร้าง PDN หากยังไม่ทราบชั้นโลหะที่อนุญาต ชนิด via และ PG pin layer ของ standard cells การมี Liberty เพียงอย่างเดียวไม่เพียงพอสำหรับสร้าง geometry

สร้างพื้นที่เก็บงาน เช่น:

```text
lab05/
  inputs/                 # netlist, SDC และ manifests
  config/                 # floorplan, pin plan, supply map
  scripts/                # approved generated/customized scripts
  checkpoints/            # ก่อนและหลังสร้าง PDN
  reports/                # geometry, assignment, connectivity
  evidence/               # ภาพประกอบและ bug-injection results
  release/                # สรุปสถานะสำหรับ Lab 6
```

RTL แบบ VHDL และ Verilog/SystemVerilog จาก Lab ก่อนหน้าใช้กระบวนการ physical implementation เดียวกันหลังได้ mapped netlist แต่ไม่จำเป็นต้องได้ netlist เหมือนกันทุก instance หากรันทั้งสองภาษา ให้แยก run directory และใช้ area/cell counts ของแต่ละ run จริง

## 5.4 ทำความเข้าใจพื้นที่ก่อนกำหนดขนาด

| คำศัพท์ | ความหมายใน Lab |
|---|---|
| Block boundary | กรอบส่งมอบของ digital block ให้ top-level integration |
| Core boundary | บริเวณที่กำหนดให้สร้าง rows และวาง logic ตาม flow |
| Nominal row area | ผลรวมพื้นที่ rows ก่อนหักสิ่งกีดขวางตามนิยามรายงาน |
| Effective placeable area | พื้นที่ไซต์ที่ placer ใช้ได้จริงหลังหักสิ่งกีดขวางที่เกี่ยวข้อง |
| Cell area | ผลรวมพื้นที่ของเซลล์ในหมวดที่รายงานนับ |
| Utilization | cell area หารด้วยพื้นที่ฐานตามนิยามของเครื่องมือ |

Ring margin ไม่ใช่ row area และ routing blockage ไม่จำเป็นต้องตัด placement capacity หากต้องห้ามทั้งสองอย่างต้องกำหนดทั้งสองชนิดให้ถูกต้อง ส่วน PG strap ที่อยู่บนชั้นโลหะสูงไม่จำเป็นต้องหักพื้นที่วางเซลล์ใต้ strap ทั้งเส้น เว้นแต่ flow สร้าง placement blockage ไว้จริง

### ตัวอย่างคำนวณเริ่มต้น

สมมติ mapped standard-cell area = 12,000 µm² เลือก utilization เริ่มต้น 0.50:

\[
A_{core,initial} \approx \frac{12{,}000}{0.50}=24{,}000\;\mu m^2
\]

ถ้าเลือกอัตราส่วนกว้างต่อสูง \(r=W/H=1.5\):

\[
W=\sqrt{Ar}\approx189.74\;\mu m,\qquad
H=\sqrt{A/r}\approx126.49\;\mu m
\]

ตัวเลขนี้เป็นโจทย์ฝึก ไม่ใช่ขนาด counter ที่วัดจริง และไม่ใช่ขนาดแนะนำสำหรับ PDK ใด ต้อง snap ความกว้างตาม site pitch ความสูงตาม row height และจุดกำเนิดตามข้อกำหนด technology

หากภายหลังพื้นที่ใช้ได้เหลือ 22,000 µm² และมีเซลล์เพิ่มเป็น 13,200 µm² จะได้ effective utilization = 60% ไม่ใช่ 50% ให้เผื่อ CTS, timing buffers และ physical-only cells ตามนโยบายของ flow โดยระบุว่ารายงาน area นับเซลล์ประเภทใดบ้าง สำหรับบล็อกเล็ก ขนาดขั้นต่ำอาจถูกกำหนดด้วยจำนวน pins, ring clearance, tap spacing และ routing access มากกว่า cell area

## 5.5 ขั้นตอนที่ 1 — เปิด checkpoint และล็อกฐานข้อมูล

1. เปิดโครงการจาก Lab 4 และเลือก top ที่ถูกต้อง
2. โหลด mapped netlist, technology, physical abstracts และ timing setup ชุดเดิม
3. ตรวจชื่อ design, cell count และ cell area เทียบกับ Lab 4
4. ตรวจหน่วย coordinate: µm หรือ DBU และค่าการแปลง เช่น DBU ต่อ µm จากฐานข้อมูลจริง
5. ตรวจ bounding box และ rows ที่อาจติดมาจาก template ห้ามสร้างทับโดยไม่รู้ว่ามีอยู่แล้ว
6. บันทึก checkpoint `05_00_imported` พร้อม log และ revision ของ inputs

**ผ่านเมื่อ:** ไม่มี missing physical master และรู้ว่ากำลังเริ่มจาก floorplan ว่างหรือจาก reference ที่มี geometry อยู่แล้ว

## 5.6 ขั้นตอนที่ 2 — กำหนด boundary และ integration contract

1. ตกลง origin และกรอบ block กับผู้รวมระบบ
2. กำหนด core margins แยกซ้าย/ขวา/บน/ล่างตาม ring และ pin access ที่ต้องใช้
3. ระบุชั้นโลหะที่ top-level ใช้เชื่อมเข้า block และชั้นที่สงวนให้ PDN
4. ระบุ keepout สำหรับ analog circuitry ที่อยู่นอก block ผ่านข้อตกลงกับ top-level ไม่สร้างโลหะล้ำ boundary โดยไม่อนุญาต
5. ใส่ boundary ผ่าน floorplan setup หรือวิธีนำเข้า floorplan ที่ reference flow รองรับ
6. อ่านค่า actual bounding boxes หลังเครื่องมือ snap grid

บันทึกตาราง:

| Parameter | Requested | Actual | หน่วย/เหตุผล |
|---|---:|---:|---|
| Block lower-left / upper-right | กรอก | กรอก | µm |
| Core lower-left / upper-right | กรอก | กรอก | µm |
| Core width/height | กรอก | กรอก | µm |
| Margin L/R/B/T | กรอก | กรอก | µm |
| Origin/grid | กรอก | กรอก | technology reference |

**ตรวจ:** core อยู่ใน block, margins ไม่ติดลบ, geometry ที่จะส่งออกอยู่ในขอบเขตตาม contract และกรอบที่แสดงใน GUI ตรงกับฐานข้อมูลจริง

## 5.7 ขั้นตอนที่ 3 — สร้าง rows และตรวจ capacity

1. เลือก site จาก technology/library ที่ใช้จริง ห้ามใช้ site ที่มีเพียงชื่อคล้ายกัน
2. ตรวจ standard-cell height และ site width รวมถึงการรองรับ multi-height cells หากมี
3. สร้าง rows ภายใน core โดยใช้ orientation pattern ของ library/reference flow
4. ตรวจว่า row origin และระยะห่าง snap ถูกต้อง ไม่มี rows ซ้อนกันหรือยื่นพ้น core
5. ถ้ามี macro ให้ตัด rows/กำหนด halo ตามแผนและตรวจว่าพื้นที่นั้นถูกหักจริง
6. แยก hard placement blockage, soft/partial blockage และ routing obstruction
7. อ่านจำนวน rows, sites และ effective capacity จากรายงาน
8. คำนวณ utilization ซ้ำด้วย denominator เดียวกับรายงาน และอธิบายความต่างหากนิยามไม่ตรงกับการคำนวณเอง

ห้ามสลับ R0/MX หรือรูปแบบ orientation ตามความเคยชิน ต้องตรวจ LEF symmetry, PG rail polarity และข้อกำหนด well/tap ของ library ก่อน ขอบแถวที่ชนกันต้องให้ rail ขั้วเดียวกันต่อกันตามสถาปัตยกรรมของเซลล์

**ผ่านเมื่อ:** row/site check ไม่มีข้อผิดพลาดที่ยังไม่ได้แก้, capacity รองรับ cells และ growth budget, ตำแหน่ง rails สอดคล้องกับ PG pins ของเซลล์ที่ orientation ที่อนุญาต

## 5.8 ขั้นตอนที่ 4 — กำหนด signal pins

ใช้ชื่อพอร์ตจริงจาก netlist ตัวอย่าง counter อาจมี `clk`, `rst_n`, `en`, `q[7:0]` โดย VHDL export อาจเปลี่ยนการเขียน bus ต้องตรวจชื่อในฐานข้อมูล ไม่คัดลอกชื่อจาก RTL โดยไม่ตรวจ

| Pin group | ตำแหน่งเริ่มต้นเพื่อการฝึก | เหตุผล |
|---|---|---|
| clk | ฝั่งที่ใกล้ clock source ของ top-level | ลดเส้นทางเชื่อมเข้าบล็อก |
| rst_n, en | ฝั่ง control interface | จัดกลุ่มกับแหล่งขับ |
| q bus | ฝั่งที่ใกล้ receiving block | ลดการไขว้ของ bus |
| VDD/VSS | รูปร่างและตำแหน่งตาม power contract | เชื่อม top-level PDN |

ขั้นปฏิบัติ:

1. สร้าง pin list จาก top-level ports ของฐานข้อมูล
2. เลือก signal pin layers ที่อนุญาต โดยดู routing direction และ pin-access rules
3. จัดลำดับ bus bits ให้ชัดเจน ระบุว่ามองจากภายในหรือภายนอก block
4. กำหนด spacing และ corner keepout ตามกฎของ PDK/flow
5. สร้าง pin shapes และผูกกับ net objects ที่ถูกต้อง การวาง label อย่างเดียวไม่เท่ากับสร้าง terminal
6. ตรวจ overlap กับ ring, straps, vias และ obstructions
7. ตรวจครบทุก signal port และไม่มี pin ซ้ำโดยไม่ตั้งใจ
8. Export pin table: name, net, layer, rectangle, side และ fixed status

**ผ่านเมื่อ:** pin ทุกตัวมี geometry ที่เข้าถึงได้ อยู่ในขอบเขตที่อนุญาต และ layer/spacing ผ่าน checks ที่มี หากมีเพียง visual inspection ให้ระบุข้อจำกัด ห้ามรายงานว่า pin-access DRC ผ่าน

## 5.9 ขั้นตอนที่ 5 — จัดทำ supply map

แยก 4 สิ่ง: top-level supply port, supply net ในฐานข้อมูล, PG pin ของ instance และโลหะที่เชื่อมถึงกัน

| Object class | ตัวอย่างชื่อเพื่ออธิบาย | ต้องตรวจจาก |
|---|---|---|
| Block supply net | VDD / VSS | integration contract |
| Standard-cell power pin | VDD หรือ VPWR | physical master และ library |
| Standard-cell ground pin | VSS หรือ VGND | physical master และ library |
| Well/body supply | ตาม library | PDK/LVS methodology |
| Macro supply | ชื่อเฉพาะของ macro | macro LEF/netlist/CDL |

1. Enumerate ชื่อ PG pins แยกตาม cell master รวม physical-only cells
2. ระบุชนิด power/ground และ voltage domain ตาม view ที่มี
3. สร้าง mapping แบบจำกัด scope ให้ตรง domain หลีกเลี่ยง wildcard ที่จับทุก pin ชื่อ VDD ทั้งชิป
4. ถ้า flow ใช้ implicit/global PG pins ให้ใช้วิธี binding ที่ flow รองรับและบันทึกกฎที่ใช้
5. ถ้า netlist แสดง PG pins ชัดเจน ให้ตรวจ instance connections และไม่สร้าง supply driver ซ้ำ
6. ตรวจจำนวน matched objects ของแต่ละ rule; จำนวน 0 ต้องอธิบายได้
7. ยืนยัน VDD และ VSS เป็น net คนละ object และไม่มี alias รวมกัน

ไม่เพิ่มพอร์ตไฟเข้า RTL ที่ไม่มีการใช้งานเพียงเพื่อให้ชื่อปรากฏ เพราะ synthesis อาจลบทิ้งหรือเกิด interface mismatch ให้จัดการ explicit/implicit PG ผ่านวิธีที่โครงการอนุมัติ ไม่ใช้ `assign VDD = 1'b1` หรือ `supply1` เป็นตัวแทนโลหะจ่ายไฟ

## 5.10 ขั้นตอนที่ 6 — วางแผน PDN

PDN อาจประกอบด้วย supply terminals → ring หรือ trunk → straps → row rails → cell PG pins รูปแบบจริงไม่จำเป็นต้องมี ring เสมอไป ให้เลือก topology จาก reference flow และ power contract

บันทึกอย่างน้อย:

| ส่วน | Parameter ที่ต้องกำหนด |
|---|---|
| Ring/trunk | net, layer, width, spacing, offset, boundary clearance |
| Straps | layer, direction, width, pitch, offset, net order |
| Row rails | layer, width, row alignment, VDD/VSS polarity |
| Vias | layer pairs, legal via master/array, enclosure, cut spacing |
| Supply ports | layer, shape, ตำแหน่ง, จุดเชื่อมจาก top-level |
| Physical cells | tap/endcap policy, insertion stage, spacing rules |

ความกว้างและ pitch ต้องอิงกฎ geometry และเป้าหมาย IR/EM ของโครงการ ไม่สามารถให้ค่าตายตัวจากตัวอย่าง counter ได้ หากยังไม่มี power estimate ให้ระบุว่าเป็น training PDN จาก approved reference และยังไม่ได้รับรอง IR/EM

การคำนวณเบื้องต้นใช้ \(\Delta V\approx IR\) และ \(R\approx\rho L/(wt)\) เพื่อเข้าใจแนวโน้ม แต่โครงข่ายจริงมี parallel paths, vias และ distributed loads ต้องใช้ extraction/analysis ที่เหมาะสม ไม่มี connectivity violation ไม่ได้ยืนยันว่า voltage drop หรือ current density ผ่าน

## 5.11 ขั้นตอนที่ 7 — สร้าง PDN และ physical cells

1. บันทึก `05_01_floorplan_pre_pdn`
2. สร้าง ring/trunk ถ้าอยู่ใน topology ที่เลือก ตรวจขั้วของทุก segment
3. สร้าง straps และยืนยันว่า offset ทำให้มีทั้ง VDD/VSS ครอบคลุม core โดยเฉพาะบล็อกที่เล็กกว่า strap pitch
4. สร้าง row rails ตาม row architecture
5. สร้าง via connections ระหว่างชั้นที่ต้องเชื่อมต่อกัน
6. สร้าง supply terminal shapes บนโลหะที่ต่อกับ PDN จริง
7. แทรก tap/endcap ที่ stage ที่ PDK/reference กำหนด; ถ้ากำหนดให้ทำภายหลัง ให้บันทึก pending อย่างชัดเจน
8. รัน logical PG binding ซ้ำหลังเพิ่ม physical-only instances ตามที่ flow ต้องการ
9. บันทึกจำนวน shapes/vias และตรวจ warning ของ dropped/failed vias
10. บันทึก `05_02_pdn_created`

ไม่ใส่ filler/decap แบบสุ่มเพื่อทำให้ภาพดูเต็ม การแทรกเซลล์เหล่านี้ต้องตรง stage, library และ well/rail continuity ของ flow

## 5.12 ขั้นตอนที่ 8 — ตรวจ logical assignment

จัดทำรายงานแยก VDD และ VSS:

| Net | Expected PG pins | Assigned pins | Unassigned | Wrong domain |
|---|---:|---:|---:|---:|
| VDD | วัดจริง | วัดจริง | วัดจริง | วัดจริง |
| VSS | วัดจริง | วัดจริง | วัดจริง | วัดจริง |

1. ตรวจ expected count จาก instances และ PG pin definitions ไม่ตั้งสมมติฐานว่าทุก cell มีอย่างละหนึ่งขา
2. ตรวจ instance ที่ไม่เข้า rule โดยเฉพาะ hierarchical instances, macros และ physical-only cells
3. ตรวจ supply ports และ PG pins ของ macros แยกเป็นรายกลุ่ม
4. Trace จาก instance ตัวอย่างกลับไปยัง supply net
5. ตรวจ net name/case sensitivity และ bus/hierarchy escaping

**ผ่านเมื่อ:** PG pins ทุกตัวที่อยู่ใน scope ผูกกับ net/domain ถูกต้อง และ unmatched rules ทั้งหมดมีคำอธิบาย การผูก net สำเร็จยังไม่ใช่ physical connectivity pass

## 5.13 ขั้นตอนที่ 9 — ตรวจ physical connectivity

1. ระบุ source terminals ของแต่ละ supply ตามขอบเขต block ให้ checker เห็น source/reference ที่ถูกต้อง
2. รัน checker สำหรับ special-net/PG connectivity ที่ติดตั้งอยู่
3. ตรวจจำนวน connected components และ floating shapes โดยอิง topology ที่คาดหวัง ไม่ใช้จำนวน components เพียงอย่างเดียวเป็นเกณฑ์ตายตัว
4. ตรวจ VDD/VSS short, PG-to-signal short และ wrong-domain connection ตามความสามารถ checker
5. Trace จุดต่อ terminal → trunk/ring → strap → rail โดยดู net, layer และ via
6. เปิด marker ทุกจุดที่มีปัญหา จด coordinate, layer และ object IDs
7. บันทึก scope ว่ารวม standard-cell pin geometry, macro pins และ physical-only cells หรือไม่

โลหะต่างชั้นที่ดูทับกันใน top view ยังเป็น open ได้หากไม่มี via ส่วนโลหะ same-net ที่เชื่อมกันในฐานข้อมูล abstract อาจยังต้องตรวจ geometry จริงใน layout view อีกครั้ง

ใน checkpoint ที่ยังไม่มี placement ให้ระบุ `cell-pin physical connectivity: pending placement` ห้ามอ้างว่าเชื่อมครบทุก instance จากผลเช็ค rails อย่างเดียว

## 5.14 ขั้นตอนที่ 10 — ตรวจ geometry ของ PDN

1. รัน available geometry/DRC checks และระบุว่าเป็น in-design check หรือ foundry sign-off deck
2. ตรวจ width/spacing ของ rails, straps และ ring
3. ตรวจ via enclosure ทั้งด้านล่างและด้านบน cut spacing และ array ที่อยู่ใกล้มุม/ขอบโลหะ
4. ตรวจ notch/min-area และ geometry ที่ถูก clip บริเวณ block boundary
5. ตรวจ supply ports ว่าอยู่บน shape/layer ที่ถูกต้องและไม่ short กับ signal pins
6. ตรวจ tap/endcap/well requirements เท่าที่ deck และ stage รองรับ

เมื่อพบ via marker ให้เปิดแยก lower metal, cut และ upper metal แล้ววัด enclosure ตามกฎ PDK อย่าแก้ด้วยการย้าย marker หรือปิด layer และอย่าถือว่าการเชื่อมต่อผ่านแปลว่า via ถูกกฎ

ถ้าไม่มี deck ที่จำเป็น ให้ลงสถานะ `NOT RUN` หรือ `NOT AVAILABLE` พร้อม scope ที่ทำได้ ไม่เขียนค่า violations = 0 แทนการไม่ได้ตรวจ

## 5.15 ขั้นตอนที่ 11 — ทดลองตรวจจับความผิดพลาด

ทำบนสำเนา `05_test_only` และย้อนกลับ baseline ทุกกรณี

### A. PG open

1. เลือกจุดต่อ rail/strap ที่มีเส้นทางเดียวจริง ไม่มีเส้นทางขนาน
2. ลบ via ที่จุดนั้นในสำเนา
3. รัน connectivity checker เดิม
4. ยืนยันว่ารายงาน open/floating segment ที่ตำแหน่งคาดหมายและมี nonzero checked objects
5. Restore baseline แล้วรันซ้ำเพื่อยืนยันว่าข้อผิดพลาดหาย

หากลบ via แล้วไม่เกิด open ให้ trace เส้นทางสำรองก่อนสรุปว่า checker เสีย หาก checker ไม่ครอบคลุมวัตถุชนิดนี้ ต้องบันทึกข้อจำกัดและใช้วิธีตรวจที่เหมาะสม

### B. PG short

1. บนสำเนา สร้าง bridge ระหว่าง VDD/VSS บนชั้นเดียวกันในพื้นที่ทดสอบ
2. อย่าสั่ง merge net เพื่อกลบ net conflict
3. รัน short/geometry check ที่รองรับ และยืนยัน marker
4. Restore baseline แล้วตรวจซ้ำ

### C. Logical mapping error

เปลี่ยน mapping ของ instance ที่เลือกในสำเนา หรือเอาออกจาก rule แล้วตรวจว่า assignment coverage ตรวจพบ unassigned/wrong-domain ตามที่ตั้งใจ การทดลองนี้ช่วยแยกความสามารถของ assignment checker ออกจาก geometry checker

## 5.16 ขั้นตอนที่ 12 — ตรวจ cell-pin connectivity เมื่อมี placement

หาก Lab 5 ต้องส่งมอบผล PG ถึงทุก standard-cell pin:

1. สำเนา floorplan/PDN baseline ไป run สำหรับตรวจเท่านั้น
2. ทำ temporary placement และ legalization ด้วย flow ที่รองรับ
3. ตรวจ cells อยู่บน legal rows และ orientations
4. รัน PG hookup ตาม flow และสร้าง connections ที่ต้องรอ cell positions
5. รัน logical coverage, PG connectivity และ available geometry checks ซ้ำ ครอบคลุม cells ทั้งหมดที่มีใน run นี้
6. บันทึก temporary-placement checkpoint แยกจาก baseline พร้อม counts และ reports

ผลนี้รับรองเฉพาะ run ที่ตรวจ เมื่อ Lab 6 เปลี่ยน placement หรือ CTS เพิ่ม buffers ต้องตรวจซ้ำ ไม่ใช้ temporary placement เป็นหลักฐานยืนยัน connectivity ของ layout ที่เปลี่ยนไปแล้ว

## 5.17 ตัวอย่าง Tcl สำหรับบันทึก parameter

ตัวอย่างต่อไปนี้เป็น **Tcl มาตรฐานสำหรับเก็บข้อมูลและตรวจค่าพื้นฐานเท่านั้น** ไม่ใช่คำสั่งสร้าง floorplan/PDN ของ TDI และยังไม่ผูกกับฐานข้อมูล หน่วยในโจทย์ตัวอย่างเป็น µm

```tcl
set fp [dict create \
    block_llx 0.0 block_lly 0.0 \
    block_urx 240.0 block_ury 180.0 \
    core_llx 20.0 core_lly 20.0 \
    core_urx 220.0 core_ury 160.0 \
    power_net VDD ground_net VSS]

foreach axis {x y} {
    set blo [dict get $fp block_ll$axis]
    set bhi [dict get $fp block_ur$axis]
    set clo [dict get $fp core_ll$axis]
    set chi [dict get $fp core_ur$axis]
    if {!($blo <= $clo && $clo < $chi && $chi <= $bhi)} {
        error "Invalid boundary on axis $axis"
    }
}
if {[dict get $fp power_net] eq [dict get $fp ground_net]} {
    error "Power and ground names must differ"
}
set w [expr {[dict get $fp core_urx]-[dict get $fp core_llx]}]
set h [expr {[dict get $fp core_ury]-[dict get $fp core_lly]}]
puts "Requested rectangular core area = [expr {$w*$h}] um^2"
# Next: use only version-verified project commands, then query actual geometry.
```

พื้นที่ที่พิมพ์ได้คือ 28,000 µm² เป็น requested rectangular area ยังไม่ใช่ effective placeable area หรือผลตรวจ grid ต้องใช้รายงานฐานข้อมูลหลังสร้างจริงเป็นเกณฑ์รับงาน

## 5.18 ตารางแก้ปัญหา

| อาการ | สาเหตุที่ควรตรวจ | วิธีดำเนินการ |
|---|---|---|
| ไม่มี rows หรือ capacity = 0 | site ผิด, core เล็กเกิน, blockage ครอบหมด | ตรวจ site/core และแสดง blockage ทีละชนิด |
| Cells ไม่ลง rows | height/orientation/site ไม่ตรง | ตรวจ master/site และ reference row pattern |
| Utilization สูงกว่าคำนวณ | หักพื้นที่เพิ่ม, growth, นิยาม area ต่าง | เทียบ counts และ denominator จริง |
| PG rule matched 0 | pin name/hierarchy/scope ผิด | enumerate objects ก่อนแก้ rule |
| Assignment ผ่านแต่ physical open | ไม่มี via/shape, cells ยังไม่วาง | trace geometry และตรวจ stage coverage |
| Rails สลับขั้ว | row orientation หรือ rail offset ผิด | เทียบ PG pin shapes กับ row architecture |
| Straps ขาดหนึ่ง supply | block เล็กกว่า pitch หรือ offset ไม่เหมาะ | ตรวจจำนวน/ตำแหน่ง straps ของแต่ละ net |
| VDD/VSS short | ring corner, bridge, via landing หรือ net binding ผิด | เปิด marker แยก layer และตรวจ net IDs |
| Via connected แต่ DRC fail | enclosure/cut-spacing ไม่ผ่าน | ใช้ legal via/array และ landing geometry |
| Macro PG open | pin layer ไม่อยู่ใน via stack หรือ mapping ไม่ครบ | ตรวจ macro view และ connection topology |
| View ใน L-Edit ต่างจาก P&R | import รุ่นเก่า/layer map ผิด | ตรวจ checkpoint timestamp, mapping และ units |
| Report ดูสะอาดเกินจริง | checks ตรวจ 0 objects หรือปิด category | ตรวจ coverage และทำ bug injection |

แก้ต้นเหตุใน configuration หรือ generated-script customization ที่อนุมัติแล้ว regenerate จาก checkpoint ที่เหมาะสม หลีกเลี่ยงการแก้ geometry มือโดยไม่มีบันทึกจนรันซ้ำไม่ได้

## 5.19 เกณฑ์รับงาน

| Gate | เกณฑ์ผ่าน | หลักฐานขั้นต่ำ |
|---|---|---|
| G1 Boundary | actual block/core ถูกต้องตาม contract | bounding-box report |
| G2 Placement area | rows/site/orientation ถูกต้องและ capacity เพียงพอ | row/capacity report |
| G3 Pins | signal/supply terminals ครบและ placement ถูกต้อง | pin table และ available checks |
| G4 Supply mapping | ไม่มี unassigned/wrong-domain ใน scope | PG assignment counts |
| G5 PDN backbone | ไม่มี unresolved open/short ใน geometry ที่ตรวจ | checker scope/counts/markers |
| G6 Geometry | available PG geometry checks ผ่านตาม scope | deck/version/report |
| G7 Cell-pin PG | ผ่านหลัง placement หรือระบุ pending พร้อมผู้รับผิดชอบ | post-placement report/status |
| G8 Reproducibility | เปิด checkpoint และรันซ้ำได้ | config/scripts/input manifest |
| G9 Checker validation | จับ intentional fault ได้ใน scope ที่อ้าง | ก่อนแก้/หลังแก้ test reports |

**สถานะที่ใช้:** PASS / FAIL / PENDING / NOT RUN / NOT AVAILABLE / N/A พร้อมเหตุผล ห้ามสรุป PASS รวมเมื่อ gate ที่จำเป็นยัง pending หากตรวจเพียง backbone ให้ใช้ข้อความ “Floorplan/PDN backbone ผ่านตาม checks ที่ระบุ; all-cell PG pending placement”

หากข้อกำหนดส่งงานบังคับว่าไม่มี PG open/short ถึงทุก cell ต้องทำขั้น 12 และให้ G7 ผ่านก่อนส่ง ส่วน sign-off DRC/LVS และ IR/EM ให้ระบุสถานะตามการรันจริง ไม่อนุมานจาก Lab นี้

## 5.20 สิ่งที่ต้องส่ง

1. Floorplan/PDN checkpoint และ checkpoint temporary placement ถ้าทำ
2. Input manifest: tool build, PDK/library revision, top, netlist/SDC revision
3. ตาราง requested/actual boundary, site/rows/capacity/utilization
4. Signal pin plan และ supply map พร้อม matched counts
5. PDN parameters, via strategy และ physical-cell policy
6. Assignment/connectivity/geometry reports พร้อม scope และ coverage
7. ภาพ overview และภาพขยาย terminal/strap/rail/via ตัวอย่าง ใช้ประกอบรายงาน ไม่แทน checker
8. ผล bug injection บนสำเนาและหลักฐานว่า baseline กลับมาสะอาด
9. Known limitations และรายการต้องตรวจซ้ำหลัง placement/CTS/route

### แบบฟอร์มสรุปผล

```text
Design / run / date:
Tool build / PDK / library revision:
Netlist and SDC revision:
Actual block box / core box / units:
Site / row count / effective placeable area:
Mapped area / counted cell categories / utilization definition:
Signal ports expected / created / checked:
Supply nets and voltage domains:
PG pins expected / assigned / physically checked / pending:
Connectivity checker and scope:
Unresolved PG opens / shorts:
Geometry checker / deck / scope / remaining violations:
Intentional fault detection result:
Cell-pin connectivity after placement:
IR/EM status:
Checkpoint and report locations:
Gate results / limitations / owner of next checks:
```

## 5.21 คำถามท้าย Lab

1. เพราะเหตุใดชื่อ VDD ตรงกันจึงยังยืนยัน physical connectivity ไม่ได้?
2. พื้นที่ core เท่ากันแต่จำนวน legal sites ต่างกันได้จากอะไร?
3. หาก checker ตรวจ rails แต่ไม่ตรวจ cell pins จะเขียนผลรับงานอย่างไร?
4. เพราะเหตุใดการลบ via หนึ่งตัวอาจไม่สร้าง open?
5. Ring/strap ผ่าน connectivity แต่ยังล้มเหลว DRC หรือ IR/EM ได้อย่างไร?
6. หลัง CTS เพิ่ม clock buffers ต้องตรวจ PG ใหม่ส่วนใดบ้าง?
7. การเปลี่ยน row orientation กระทบ PG polarity และ well continuity อย่างไร?
8. Digital block boundary ต่างจาก full-chip die boundary อย่างไรในงาน analog-on-top?

## 5.22 แนวทางประเมินสำหรับผู้สอน

ให้คะแนนจากความถูกต้องของ boundary/rows 25%, pin/supply contract 20%, PDN และ PG mapping 25%, coverage/bug injection/การตีความรายงาน 20% และ reproducibility 10% ผู้เรียนที่รายงาน violations = 0 แต่ไม่มี checked-object coverage ยังไม่ผ่านส่วน verification

ก่อนขึ้น Lab Placement ให้ยืนยัน baseline ที่จะใช้ต่อ และตั้ง mandatory PG recheck หลัง placement/legalization, หลัง CTS เพิ่มเซลล์, หลัง routing/repair และหลัง export/import ที่อาจเปลี่ยน geometry หรือ net interpretation

## เอกสารอ้างอิงและขอบเขตการอ้าง

- [R1] Siemens, “Digital Implementation”: https://eda.sw.siemens.com/en-US/ic/ic-custom/ams/digital-implementer/ — อ้างเฉพาะภาพรวม L-Edit setup wizard, Tcl customization และความสามารถ floorplanning/power planning; ตรวจเข้าถึง 16 ตุลาคม 2026
- [R2] Siemens, “A full-flow solution for analog/mixed-signal IC design”: https://static.sw.cdn.siemens.com/siemens-disw-assets/public/1xqViRATpGkS6iFOXguaxE/en-US/Siemens-SW-Full-flow-solution-for-analog-mixed-signal-IC-design-WP-84095-D9.pdf — เอกสารภาพรวม flow; stage/script names ในโครงการจริงต้องตรวจตาม release
- [R3] เอกสาร local ของ TDI/Nitro release ที่ติดตั้ง: user guide, command reference และ generated reference scripts — ผู้สอนต้องระบุ release และหัวข้อที่ใช้ก่อนออกคู่มือฉบับผูกกับเครื่องมือ
- [R4] PDK/library documentation ของโครงการ: site/row rules, metal/via rules, tap/endcap policy, PG pin definitions, sign-off decks และ power contract — เป็นแหล่งตัดสินค่ากายภาพของ Lab นี้

ขั้นตอนตรวจรับ ตัวอย่างคำนวณ และแบบฟอร์มในบทนี้เป็นแนวทางการสอนเชิงวิศวกรรม ไม่ใช่ syntax รับรองของ TDI หรือกฎทดแทน PDK
