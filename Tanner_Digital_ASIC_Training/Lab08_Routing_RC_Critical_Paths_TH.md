# Lab 8 — Routing, RC Extraction และการแก้ Critical Path

หลักสูตร Tanner Digital ASIC Design Implementation — ระดับเริ่มต้นถึงกลาง

## 1. เป้าหมายและขอบเขต

Lab นี้ต่อจาก Lab 7 โดยใช้ฐานข้อมูลหลัง CTS ของ digital block หนึ่งคล็อก ผู้เรียนจะสร้าง signal routing สกัด parasitic RC จากเส้นทางที่มีจริง วิเคราะห์ setup/hold ด้วย propagated clocks และแก้ปัญหาหนึ่งรายการโดยมีหลักฐานก่อน–หลัง ใช้ mapped netlist จากต้นทาง VHDL หรือ Verilog/SystemVerilog ได้เหมือนกัน เพราะขั้นนี้ทำงานกับเซลล์และ geometry แล้ว หากทำทั้งสองภาษาให้แยก run และไม่คาดหวังชื่อ instance เหมือนกัน

เมื่อจบ Lab ผู้เรียนต้องสามารถ:

1. แยก global routing, detailed routing และ RC extraction ได้
2. ตรวจ route completion, connectivity และ routing-rule violations ได้
3. ระบุว่ารายงาน timing ใช้ RC จากขั้นใดและ corner ใด
4. อ่าน critical path แบบ full clock path และแยก cell delay จาก net delay
5. เลือก ECO ที่สัมพันธ์กับสาเหตุ แล้ว reroute/re-extract/reanalyze
6. รายงานผลที่ดีขึ้นพร้อมผลข้างเคียงด้าน hold, area, congestion และ electrical limits

ระยะเวลาแนะนำ 3–5 ชั่วโมง ไม่รวมเวลารันของ block ขนาดใหญ่ นี่คือ implementation lab; route สำเร็จหรือ internal DRC ผ่านยังไม่ใช่ sign-off DRC/LVS

## 2. ข้อกำหนดเกี่ยวกับรุ่นเครื่องมือ

Siemens อธิบาย Digital Implementer ว่าเริ่ม placement/routing จาก L-Edit มี setup wizard, Tcl customization และ timing-driven implementation [1] แต่เอกสารสาธารณะไม่ได้ยืนยัน syntax routing/extraction ของ TDI ทุกรุ่น ขั้นตอนด้านล่างจึงระบุ **หน้าที่** ที่ต้องค้นหาใน installed Help และ reference flow ไม่ถือข้อความเหล่านั้นเป็นชื่อเมนูจริง

ก่อนสอน ผู้สอนกรอกตารางนี้จากรุ่นที่ใช้งาน ห้ามแทนที่ด้วยคำสั่ง OpenROAD, Innovus หรือ IC Compiler แล้วเรียกว่าเป็น TDI

| หน้าที่ | เมนู/คำสั่งที่ยืนยันในรุ่นติดตั้ง | หลักฐาน |
|---|---|---|
| เปิดและบันทึก native checkpoint | ผู้สอนกรอก | Help/reference script |
| Global routing/congestion analysis | ผู้สอนกรอก หรือระบุว่ารวมอยู่ใน task | run log |
| Detailed routing และ route repair | ผู้สอนกรอก | run log |
| Route connectivity และ routing DRC | ผู้สอนกรอก | report |
| เลือก RC technology/corner และ extraction | ผู้สอนกรอก | settings/log |
| โหลด parasitics และตรวจ annotation | ผู้สอนกรอก | analysis report |
| Setup/hold และ full clock path | ผู้สอนกรอก | timing report |
| Resize/buffer/incremental legalization | ผู้สอนกรอก | ECO log |
| Incremental route และ export | ผู้สอนกรอก | checkpoint/output log |

หาก flow ใช้ RC ภายในฐานข้อมูลโดยไม่ส่งออก SPEF ให้ใช้หลักฐานจาก extraction/analysis log แทน อย่ากำหนดว่าต้องมี SPEF ทั้งที่ release หรือ license ไม่รองรับ ส่วน Calibre xACT เป็นตัวอย่างเครื่องมือ extraction แยกต่างหากที่ต้องมี license, physical inputs และ foundry deck ตาม flow [2] ไม่ได้สมมติว่ารวมอยู่ใน TDI ทุก installation

## 3. Input และจุดตรวจพร้อมเริ่ม

ใช้ checkpoint หลัง CTS ที่ผ่านการตรวจจาก Lab 7 พร้อม mapped netlist, SDC, timing libraries, physical libraries และ technology เดียวกัน

| Input | สิ่งที่ต้องยืนยัน |
|---|---|
| Post-CTS database | top, hierarchy, CTS cells, pin placement และ supply association ถูกต้อง |
| Placement | ไม่มี overlap/off-row/unplaced cells ที่ยังไม่แก้ |
| Clock | clock source/sinks ถูกต้อง ใช้ propagated analysis ตาม flow |
| Timing views | ระบุ mode, PVT, RC corner และ early/late policy |
| Routing technology | legal layers, preferred directions, vias, tracks และ blockages |
| RC technology | stack และ layer mapping ตรงกับ physical technology |
| Constraints | period, I/O min/max, uncertainty, loads และ exceptions ถูกชุด |
| Baseline | setup/hold, clock quality, cell area และ electrical violations จาก Lab 7 |

หาก clock network ยังไม่มี routing จริงทั้งหมด ต้องให้ flow จัดการส่วนที่เหลือก่อน extraction และตรวจอีกครั้งหลัง route ไม่สรุปว่าหลัง CTS มี extracted clock RC แล้วเสมอ

**หยุดแก้ input ก่อนรันต่อเมื่อ:** missing timing/physical models, power association ไม่ชัดเจน, หน่วยไม่ตรง, unintended ideal clocks หรือ constraint loading มีคำสั่งถูก ignore

## 4. หลักการที่ต้องเข้าใจ

### 4.1 Routing สามขั้นที่ต้องแยก

- Global routing ประเมินทางเดินและทรัพยากรใน routing regions ใช้หา congestion และทางอ้อมได้ แต่ไม่ใช่หลักฐานว่า wire/via ทุกชิ้นถูกกฎแล้ว
- Detailed routing สร้าง geometry บน track/layer และ vias ตามเทคโนโลยี ต้องตรวจทั้ง completion และข้อผิดพลาด
- Extraction แปลง geometry และข้อมูลกระบวนการเป็น parasitic network เพื่อใช้ delay calculation การมี wire ใน layout ไม่ได้ทำให้ STA โหลด RC ใหม่อัตโนมัติในทุก flow

### 4.2 ทำไม RC ทำให้ timing เปลี่ยน

ความต้านทานของเส้นทางเพิ่มตามความยาวและขึ้นกับวัสดุ/หน้าตัด ส่วน capacitance ขึ้นกับ geometry และตัวนำรอบข้าง ความสัมพันธ์คร่าว ๆ R ≈ ρL/(wt) ใช้เพื่อเข้าใจแนวโน้มเท่านั้น ไม่ใช้แทน extraction deck ซึ่งรวม via, thickness และ process effects

RC ทำให้ net delay และ slew เปลี่ยน และ slew ที่ input ของ cell ถัดไปทำให้ cell delay เปลี่ยนด้วย ดังนั้นผล extraction ไม่ใช่การบวก wire delay เพิ่มลงในรายงานเดิมอย่างเดียว Coupling capacitance ต้องรู้ว่า engine เก็บ coupling, ลดเป็น grounded C หรือใช้ SI-aware analysis แบบใด ห้ามอ้างว่า crosstalk ผ่านถ้าไม่ได้เปิดและตรวจ analysis นั้น

### 4.3 PVT corner กับ RC corner

PVT กำหนด cell timing ส่วน RC corner กำหนด interconnect model ต้องใช้คู่ตาม analysis-view definition ที่ได้รับอนุมัติ ไม่เดาว่า corner ชื่อ “max” ต้องแย่สุดกับทุก path หรือ “min” ต้องให้ hold แย่สุดเสมอ รายงานผลทุก view ที่ flow กำหนด

### 4.4 เกณฑ์ timing สำหรับตัวอย่างหนึ่งคล็อก

สำหรับ register-to-register แบบหนึ่งรอบ ไม่มี exception และใช้ skew = capture arrival − launch arrival:

```text
setup slack = Tperiod + skew − (Tcq,max + Tdata,max + Tsetup + Usetup)
hold slack  = Tcq,min + Tdata,min − (Thold + Uhold + skew)
```

Positive skew ช่วย setup แต่ทำให้ hold ยากขึ้น รายงานจริงอาจใช้ early/late derates, CPPR/CRPR, waveform และ clock-edge relationships เพิ่ม ต้องอ่านตามเครื่องมือ ไม่ใช้สมการย่อนี้แทน sign-off engine

## 5. ขั้นที่ 1 — สร้าง run และตรึง baseline

1. เปิด post-CTS checkpoint และยืนยัน top/run identifier
2. สร้าง run `lab08_route_base` โดยเก็บผล Lab 7 ไว้
3. บันทึก checkpoint `pre_route` และ manifest: tool build, library/deck releases, mode/corners, SDC, routing options และ seed ถ้ามี
4. ส่งออกรายงาน setup/hold, clock paths, max transition/capacitance/fanout และ placement legality
5. ระบุ RC method ของ baseline ว่าเป็น estimate, partial route หรือ extracted
6. เก็บ log ว่า clock ถูก propagate และมี timing coverage ถูกต้อง

โครงสร้างผลส่งมอบแนะนำ:

```text
lab08_routing/
  manifest.txt
  inputs/constraints.sdc
  scripts/verified_flow.tcl
  checkpoints/pre_route/
  checkpoints/post_route_base/
  checkpoints/post_eco/
  reports/base/
  reports/eco/
  extraction/base/
  extraction/eco/
  evidence/
  comparison.csv
  conclusion.md
```

Native checkpoint อาจเป็นไฟล์หรือ directory ตาม release ชื่อด้านบนเป็นเพียงโครงสร้างจัดเก็บ

## 6. ขั้นที่ 2 — ตรวจ routing setup

1. ตรวจว่าชั้นโลหะที่อนุญาตตรงกับ PDK และข้อตกลง integration ของ block
2. ตรวจ signal/clock layer policy และการกันชั้นสำหรับ power หรือ analog integration
3. ตรวจ track grid, via definitions, pin accessibility และ blockages รอบ macro/ขอบ block
4. ตรวจ fixed routing และ PG geometry ไม่ถูก signal router เปลี่ยนผิดเจตนา
5. ตรวจ CTS cells และ repair cells มีพื้นที่เพิ่มได้อย่างถูกกฎหมาย
6. เก็บ routing settings เป็น baseline ห้ามเปลี่ยนหลายค่าโดยไม่บันทึก

ไม่ควรเริ่มด้วยการอนุญาตทุกชั้นโลหะหรือเอา blockage ออกทั้งหมดเพื่อให้ route ผ่าน เพราะอาจละเมิด integration contract ของ block

## 7. ขั้นที่ 3 — Global routing และประเมิน congestion

1. เรียก task ที่ทำ global route หรือ routing-resource analysis ตาม reference flow
2. เปิด congestion map ตรวจทั้งแนวนอนและแนวตั้ง และแยกดูราย layer หากมี
3. บันทึก demand/capacity หรือ overflow พร้อมนิยาม metric ของรุ่นนั้น
4. ดู hotspot รอบ pin groups, macro corners, ทางแคบระหว่าง PG straps และกลุ่มเซลล์หนาแน่น
5. Cross-probe net ที่ผ่าน hotspot กับเส้นทาง timing ที่สำคัญ
6. ตรวจว่ามี unresolved net หรือ pin-access failure ก่อน detailed route หรือไม่

หาก congestion รุนแรงทั่ว block ให้ย้อน placement/floorplan แทนการหวังให้ detailed router แก้ทั้งหมด หากเป็นจุดเล็กให้เก็บเป็นผู้สมัครสำหรับการทดลอง ECO แต่ baseline ต้องมี routing ที่วิเคราะห์ได้ก่อน

**หลักฐาน:** congestion map, จำนวน overflow ตามนิยามเครื่องมือ, ชื่อ hotspot และเหตุผลที่เดินหน้าหรือย้อนแก้

## 8. ขั้นที่ 4 — Detailed routing และตรวจความสมบูรณ์

1. รัน detailed route ด้วยค่าที่ตรึงไว้
2. อ่าน summary และ warning ทั้งหมด โดยเฉพาะ incomplete nets, opens/shorts, via และ pin-access failures
3. เรียก route connectivity checker และ internal routing DRC แยกจากการดู exit status
4. Cross-probe violation อย่างน้อยหนึ่งรายการถ้ามี เพื่อแยกว่าเกิดจาก route, pin หรือ input geometry
5. ใช้ repair ที่ flow รองรับ แล้วตรวจซ้ำจนข้อผิดพลาดที่อยู่ในขอบเขต Lab เป็นศูนย์ หรือมีรายการ unresolved ที่ระบุชัด
6. ตรวจ cell legality และ PG association ใหม่หาก router/optimizer เพิ่มหรือย้าย cells
7. บันทึก `post_route_base` และ export route statistics

เก็บ total wirelength, via count, usage ราย layer และ routing violations ถ้าเครื่องมือรายงาน ต้องใช้ metric ขอบเขตเดียวกันก่อน–หลัง อย่าบวก PG wirelength กับ signal-only baseline

**จุดผ่าน:** ไม่มี signal net ที่ควรเชื่อมแต่ยังขาด ไม่มี short ที่ยังไม่แก้ และไม่มี routing-rule violation ที่ไม่ได้ยอมรับตามเกณฑ์การสอน การยอมรับเพื่อเรียนรู้ต้องเขียนว่า incomplete ไม่ใช้คำว่า DRC clean

## 9. ขั้นที่ 5 — สกัด RC จาก routed database

1. เลือก routed checkpoint ที่เพิ่งตรวจและบันทึก design revision
2. โหลด extraction technology และตรวจ stack/layer mapping ไม่ใช้ deck คนละ metal option
3. เลือก RC corner สำหรับแต่ละ analysis view ตาม flow
4. ตั้ง coupling treatment และ reduction policy ตาม reference flow พร้อมบันทึก
5. รัน extraction และอ่าน errors/warnings รวมทั้ง missing layer/via model
6. หากส่งออก SPEF ให้ระบุ design name, units, hierarchy delimiter, bus notation และ name mapping
7. โหลด RC เข้าฐานข้อมูล STA ตามวิธีของรุ่นนั้น หรือยืนยันจาก log ว่าใช้ extracted RC ภายในแล้ว
8. ตรวจ annotation coverage ของ clock/data nets ที่เกี่ยวข้องกับ timing และตรวจ mismatch/ignored nets
9. เลือก net ใน critical path อย่างน้อยหนึ่งเส้น ตรวจว่ามี nonzero RC ที่สมเหตุสมผล และ trace ไปยัง geometry ได้

หาก coverage ไม่ครบ ให้จำแนก excluded PG nets, ideal nets, logical-only nets และ unmatched routed signal nets ตามนิยาม engine ไม่ใช้ total annotated-net percentage อย่างเดียวตัดสินผล การมี SPEF ไม่พิสูจน์ว่า STA โหลดสำเร็จ และค่า 100% ในรายงานหนึ่งต้องรู้ denominator

Clock/data nets ที่ควรใช้ RC แต่ unmatched เป็นเหตุให้หยุดตีความ timing แก้ hierarchy, revision, delimiter หรือ mapping ก่อน อย่าใช้การปิด warning แทนการแก้

## 10. ขั้นที่ 6 — รัน Post-route STA

1. ใช้ netlist/physical revision เดียวกับ RC ที่สกัด
2. ตรวจ library/view และ constraints อีกครั้ง โดยเฉพาะ I/O delays และ exceptions
3. ยืนยัน propagated clocks และตรวจ launch/capture clock network delay ในรายงาน
4. อัปเดต timing หลัง RC annotation
5. รายงาน setup และ hold แยกทุก required view
6. รายงาน unconstrained endpoints, disabled arcs, missing models และ electrical violations
7. ดึง top paths เช่น 10 setup และ 10 hold paths; หากทำได้ให้เลือกจากหลาย endpoints เพื่อลดรายการซ้ำของปัญหาเดียว
8. เปรียบเทียบ post-CTS estimate กับ post-route extraction โดยระบุว่าการเปลี่ยนของ RC model เป็นส่วนหนึ่งของความต่าง

WNS คือ slack ที่แย่ที่สุดตาม scope ของรายงาน ส่วน TNS รวม negative slack ตามวิธีนับของเครื่องมือ ต้องใช้ scope/view/endpoint convention เดียวกันในการเปรียบเทียบ หากไม่มี violation ให้รายงานค่าตามนิยามเครื่องมือ ไม่เดาว่า TNS แทนผลรวมของทุก enumerated path

## 11. ขั้นที่ 7 — อ่าน Critical Path ทีละส่วน

เลือกหนึ่ง setup path แล้วเปิดทั้ง timing report และ layout cross-probe บันทึก:

| รายการ | สิ่งที่ต้องอธิบาย |
|---|---|
| View/path group | mode, PVT/RC และประเภท path |
| Startpoint/endpoint | instance/pin และเหตุผลที่ path ถูกวิเคราะห์ |
| Launch/capture edge | ความสัมพันธ์ของขอบคล็อก |
| Clock paths | arrivals, skew, uncertainty และ CPPR ถ้ามี |
| Data path | clock-to-Q, cell arcs และ net delays |
| Electrical data | slew, effective/load capacitance และ fanout |
| Physical route | layer, vias, detour, hotspot และ endpoint positions |
| Result | arrival, required time และ slack พร้อม units |

อย่ารวม cumulative arrival ทุกแถวเพื่อหาผลรวม delay ให้ใช้ incremental column และแยก clock path กับ data path ระบุให้ชัดว่า Tdata ที่คำนวณรวมส่วนใดบ้าง

ใช้สามคำถามวิเคราะห์: (1) cell delay สูงเพราะ logic depth หรือ input slew/load? (2) net delay สูงเพราะระยะทาง/fanout/ทางอ้อมหรือไม่? (3) required time ถูกบีบจาก clock relationship/constraint ที่ถูกต้องหรือไม่? คำตอบต้องมีหลักฐาน ไม่ตัดสินจาก WNS อย่างเดียว

## 12. ตัวอย่างคำนวณก่อน–หลัง

ตัวเลขต่อไปนี้เป็น **ข้อมูลสมมติสำหรับฝึกอ่าน** ไม่ใช่ผลรัน TDI และไม่ใช่ค่าเป้าหมายของ PDK ใด

กำหนด period 10.00 ns, skew +0.10 ns, Tcq,max 0.20 ns, setup 0.30 ns และ setup uncertainty 0.20 ns

| ส่วนประกอบ data path | ก่อน ECO | หลัง ECO |
|---|---:|---:|
| Cell delays ไม่รวม Tcq | 6.90 ns | 6.75 ns |
| Net delays | 2.80 ns | 2.45 ns |
| Tdata รวม | 9.70 ns | 9.20 ns |
| Setup slack | −0.30 ns | +0.20 ns |

ก่อน: 10.00 + 0.10 − (0.20 + 9.70 + 0.30 + 0.20) = −0.30 ns

หลัง: 10.00 + 0.10 − (0.20 + 9.20 + 0.30 + 0.20) = +0.20 ns

ตัวอย่างนี้ตรึง clock terms เพื่อสอนคำนวณเท่านั้น ผลจริงต้องอ่าน clock terms ใหม่หลัง ECO ตรวจ hold ด้วย เช่น Tcq,min 0.08 ns, Tdata,min 0.19 ns, hold 0.08 ns, Uhold 0.05 ns และ skew 0.10 ns ให้ slack +0.04 ns หากการแก้ลด Tdata,min เหลือ 0.13 ns จะกลายเป็น −0.02 ns แม้ setup ดีขึ้น

## 13. ขั้นที่ 8 — เลือกปัญหาและตั้งสมมติฐานหนึ่งข้อ

| หลักฐานสาเหตุ | แนวทางทดลอง | ผลข้างเคียงที่ต้องตรวจ |
|---|---|---|
| Driver slew เสีย, load สูง และ cell อ่อน | resize หนึ่ง driver เป็น legal equivalent ที่แรงขึ้น | input cap ย้ายภาระไป upstream, area/power, hold |
| Long high-fanout net | buffering ที่ flow รองรับ | cells/PG, legality, route และ min delay |
| Detour ผ่าน hotspot | local placement หรือ routing change ที่อนุญาต | congestion ย้ายจุด, neighbor paths, vias |
| Hold path สั้นเกิน | hold-repair/delay cell ที่ flow อนุมัติ | setup, area และหลาย corners |
| Unmatched RC | แก้ revision/naming/mapping | ต้อง rerun analysis; นี่คือ model repair ไม่ใช่ PPA ECO |

โจทย์หลักแนะนำคือแก้ setup/electrical problem ด้วยการ resize หนึ่ง driver หากหลักฐานสนับสนุน อย่า resize sequential cell, clock buffer หรือ cell ที่มี special purpose โดยไม่ใช้ flow ที่เหมาะสม หาก baseline ผ่านทั้งหมด ให้ผู้สอนกำหนดการปรับปรุง path ที่วัดได้โดยไม่อ้างว่ามี violation หรือจัดเตรียม checkpoint ที่มีปัญหาจริง ห้ามลด period ใน SDC เพื่อสร้างผลเสียแล้วเปรียบเทียบข้ามคนละ constraint

## 14. ขั้นที่ 9 — ทดลอง ECO หนึ่งรายการอย่างควบคุม

1. Clone `post_route_base` เป็น `lab08_route_eco01`
2. ระบุ target instance, input/output pins, violated view และเหตุผลจาก report/layout
3. ตรวจ candidate cell มี logic function, pin mapping, voltage domain และ physical/timing views ที่เข้ากัน
4. ตรวจ dont-use/dont-touch และข้อกำหนด flow ก่อนเลือก cell
5. ใช้ resize ผ่าน implementation engine ไม่แก้เพียงข้อความใน netlist แล้วปล่อย physical database ไม่ตรงกัน
6. บันทึก cell ก่อน–หลังและให้ incremental legalizer จัดตำแหน่งที่ได้รับผล
7. เชื่อม supply ของเซลล์ใหม่/ที่เปลี่ยนตาม flow และตรวจ legality
8. Reroute affected nets รวม upstream nets ที่ load เปลี่ยน และ route repair ตามที่ engine ระบุ
9. ตรวจ connectivity และ internal routing DRC ใหม่
10. Re-extract RC จาก revision หลัง ECO; ใช้ incremental extraction ได้เฉพาะเมื่อ flow รองรับและยืนยัน update coverage
11. รัน setup/hold ทุก required view รวม electrical checks และ coverage อีกครั้ง
12. ตรวจทั้ง path เดิมและ global worst paths เพราะ critical endpoint อาจเปลี่ยน
13. หากผลแย่ลง ให้ย้อน baseline และบันทึกสาเหตุ การทดลองล้มเหลวที่วิเคราะห์ถูกต้องเป็นหลักฐานการเรียนรู้ แต่ไม่ถือว่าแก้ปัญหาสำเร็จ

ให้ใช้ optimization objective หลักหนึ่งอย่างต่อรอบ เครื่องมืออาจแทรก legalize/repair changes ตาม dependency ได้ ต้องเก็บรายการเปลี่ยนจริงทั้งหมด ถ้าปัญหายังไม่หมดให้ทำรอบถัดไปเป็น ECO02 โดยแยก checkpoint ไม่ปะปนผล

**ห้ามใช้เพื่อให้รายงานผ่าน:** เพิ่ม period, ลด uncertainty, สร้าง false path ที่ไม่มีเหตุผล, ปิด hold analysis หรือเปลี่ยน corner ระหว่างการเทียบ ECO

## 15. Pseudocode สำหรับทำความเข้าใจลำดับ

โค้ดด้านล่าง **ไม่ใช่ Tcl API ที่นำไปรันใน TDI ได้** ผู้สอนต้องแทนทุกบรรทัดด้วยคำสั่งที่ตรวจสอบจาก installed reference flow

```text
OPEN post_cts_checkpoint
VERIFY constraints, libraries, clocks, placement, supplies
SAVE pre_route
RUN global_route_and_congestion_analysis
RUN detailed_route_and_supported_repairs
CHECK route_connectivity, routing_rules, legality
SAVE post_route_base
EXTRACT RC using approved technology and view mapping
VERIFY parasitic_annotation and propagated_clocks
REPORT setup, hold, coverage, electrical_limits

CLONE baseline_as_eco01
APPLY one_evidence_based_change
LEGALIZE and UPDATE supplies
REROUTE affected_geometry
CHECK route_connectivity, routing_rules, legality
REEXTRACT RC for new_revision
REPORT all_required_views and global_worst_paths
COMPARE same_constraints_and_analysis_conditions
SAVE accepted_result
```

## 16. ขั้นที่ 10 — บันทึกผลก่อน–หลัง

เติมข้อมูลจริง ไม่คัดลอกค่าตัวอย่างในหัวข้อ 12

| Metric | Post-CTS | Routed baseline | หลัง ECO | เงื่อนไข/หลักฐาน |
|---|---|---|---|---|
| Checkpoint/revision | | | | |
| RC method/corner | | | | |
| Setup WNS/TNS และ violating endpoints | | | | แยกแต่ละ view |
| Hold WNS/TNS และ violating endpoints | | | | แยกแต่ละ view |
| Path เดิม: cell/net delay และ slack | | | | ใช้ endpoint/edge เดิม |
| Global worst endpoint | | | | อาจเปลี่ยนหลัง ECO |
| Max transition/capacitance violations | | | | units/scope |
| Unconstrained/unmatched timing objects | | | | อธิบาย exclusion |
| Unrouted nets/opens/shorts | N/A ตามขั้น | | | checker scope |
| Internal routing DRC | N/A ตามขั้น | | | ไม่แทน sign-off |
| Cell area/buffer count | | | | cell area ไม่ใช่ core area |
| Signal wirelength/via count | | | | scope เดียวกัน |
| Clock arrivals/skew ของ path | | | | view/edge เดียวกัน |

เขียนข้อสรุปหนึ่งย่อหน้า: ปัญหาคืออะไร หลักฐานบ่งชี้สาเหตุใด เปลี่ยนอะไร ผลดีขึ้นเท่าไร และมี regression ใดบ้าง หากไม่มี activity-based power analysis ให้กล่าวเพียงแนวโน้มจาก cell/capacitance ไม่รายงานตัวเลข power reduction ที่ไม่ได้วัด

## 17. Troubleshooting

| อาการ | ตรวจเป็นอันดับแรก | วิธีดำเนินการ |
|---|---|---|
| Route จบแต่มี opens | completion/connectivity report, inaccessible pin | แก้ pin access/route; ตรวจซ้ำ |
| DRC มากรอบ PG strap | spacing/blockage/layer policy | ตรวจ technology และ floorplan contract |
| RC ใกล้ศูนย์ทุก signal net | extraction log, ideal flags, annotation | แก้ model/loading ก่อน STA |
| SPEF unmatched จำนวนมาก | top/revision/hierarchy/bus notation | export และโหลดชุดเดียวกัน |
| Timing แย่ลงหลัง route | net delays, slew, clock arrivals | แยก RC-model shift จาก physical detour |
| Resize แล้ว setup แย่ลง | upstream input load, new route | เปรียบเทียบทุก arc และย้อนถ้าจำเป็น |
| Setup ผ่านแต่ hold เสีย | fast/early view และ path skew | ใช้ hold repair แล้วตรวจ setup ซ้ำ |
| Critical path เปลี่ยนหลัง ECO | global top paths | วัดทั้ง path เดิมและภาพรวม |
| Clock ยัง ideal | full clock report และ flow stage | เปิด propagated ตาม reference flow |
| Internal DRC ผ่านแต่ sign-off ไม่ผ่าน | checker/deck scope | วิเคราะห์ด้วย sign-off deck ที่ตกลง |

## 18. เกณฑ์ผ่านและผลส่งมอบ

### เกณฑ์ผ่านทางการเรียนรู้

1. มี routed baseline และ post-ECO checkpoint ที่ย้อนกลับได้
2. มีหลักฐาน routing completion/connectivity และขอบเขต routing DRC
3. ระบุ extracted RC technology/corner, revision และ annotation coverage ได้
4. อธิบาย setup หนึ่ง path และ hold check ที่เกี่ยวข้องได้
5. ทดลองแก้ปัญหาหนึ่งรายการที่สัมพันธ์กับสาเหตุ และวัดผลหลัง reroute/re-extract จริง
6. ตรวจ regression ทั้ง setup/hold, electrical constraints, routing และ legality
7. ส่งตารางก่อน–หลังพร้อม known limitations ไม่ซ่อน remaining violations

การผ่าน Lab ไม่จำเป็นต้องเท่ากับทุก sign-off view ผ่าน หากผู้สอนกำหนดให้ผ่านแบบวิเคราะห์ ต้องระบุสถานะนี้ชัดเจน ส่วนเกณฑ์ส่งต่อ block สำหรับงานจริงต้องผ่าน timing/physical checks ตาม specification และ sign-off plan ของโครงการ

### ชุดหลักฐานที่ต้องส่ง

- Manifest, SDC และ verified scripts/settings
- Native checkpoints ก่อน route, routed baseline และหลัง ECO
- Routing logs, completion/connectivity และ internal DRC reports
- Extraction settings/logs, RC outputs ถ้า export ได้ และ annotation reports
- Setup/hold/electrical/coverage reports ของ baseline และ ECO ทุก required view
- ภาพ cross-probe path ก่อน–หลังและภาพ hotspot ที่ใช้วิเคราะห์
- ตารางเปรียบเทียบ, ECO change list และข้อสรุปพร้อม remaining issues

## 19. คำถามท้าย Lab

1. ทำไม route สำเร็จยังไม่พิสูจน์ว่า STA ใช้ extracted parasitics?
2. ทำไมเพิ่ม drive strength แล้ว upstream path อาจช้าลง?
3. ถ้า WNS ดีขึ้นแต่ TNS แย่ลง จะยอมรับ ECO หรือไม่ และต้องดูอะไรเพิ่ม?
4. ทำไมต้องดูทั้ง path เดิมและ global worst path หลังแก้?
5. Propagated clock กับ extracted clock RC ต่างกันอย่างไร?
6. ถ้า setup ผ่านที่ view หนึ่งแต่ hold เสียอีก view ควรดำเนินการอย่างไร?
7. Internal routing DRC, sign-off DRC และ LVS ให้หลักฐานต่างกันอย่างไร?
8. ถ้า period เปลี่ยนระหว่าง baseline กับ ECO ทำไมผลเทียบจึงไม่ยืนยัน physical improvement?

แนวคำตอบ: ต้องตรวจ RC annotation; drive ที่แรงขึ้นอาจเพิ่ม input capacitance; ต้องประเมินทุก endpoint/view; worst path ย้ายได้; propagated บอกวิธีคำนวณ clock arrival ส่วน extracted บอกแหล่ง RC; ต้องแก้และตรวจทั้ง setup/hold; geometry/connectivity checks มี scope ต่างกัน; constraints ที่เปลี่ยนทำให้ timing budget เปลี่ยน

## 20. เอกสารอ้างอิงและข้อจำกัด

1. Siemens, Digital Implementation — ภาพรวม L-Edit-driven implementation และความสามารถ timing-driven P&R: https://www.siemens.com/en-us/products/ic/ic-custom/ams/digital-implementer/
2. Siemens, Calibre xACT parasitic extraction — ตัวอย่างเครื่องมือ RC extraction, inputs และ deck/license requirements: https://www.siemens.com/en-us/products/ic/calibre-design/circuit-verification/xact/
3. Installed TDI User Guide, Command Reference, release notes, PDK integration guide และ reference project ของสถานที่ — ใช้ยืนยันคำสั่งและ corner mapping จริง

ตรวจแหล่งสาธารณะวันที่ 16 ตุลาคม 2026 คู่มือนี้ให้ workflow และหลักการวิเคราะห์ ไม่อ้างว่ามีการรัน TDI หรือทดสอบ ECO กับ PDK จริงแล้ว ผู้สอนต้องเติมตารางคำสั่งของรุ่นติดตั้งและเก็บผลรันจริงก่อนใช้เป็น lab ที่ทำซ้ำได้ครบชุด
