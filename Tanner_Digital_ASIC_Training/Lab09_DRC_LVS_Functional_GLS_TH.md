# Lab 9 — DRC/LVS/GLS
## รัน verification decks ที่เตรียมไว้ แก้ violation และตรวจ functional gate-level simulation

เอกสารประกอบหลักสูตร Tanner Digital ASIC Design Implementation ระดับเริ่มต้นถึงระดับกลาง

**ระยะเวลาแนะนำ:** 4–6 ชั่วโมง ไม่รวมเวลารันเครื่องมือและการแก้ปัญหาซับซ้อน

**จุดเริ่มต้น:** digital block หลัง detailed routing จาก Lab 8 มี layout, netlist และรายงาน timing ที่ระบุ revision ตรงกัน

**ขอบเขต:** ตรวจ block สำหรับ analog-on-top; full-chip pad ring, ESD, package และการรับรอง tape-out ต้องมี verification plan เพิ่มตามผู้รับงาน

> คู่มือนี้ไม่ได้แนบ foundry deck หรืออ้างว่าได้รันบนระบบ Tanner ของผู้เรียน ตัวเลขผลลัพธ์เป็นตัวอย่างเพื่อการสอน ชื่อเมนู เครื่องมือ verification และ syntax ที่รองรับต้องตรวจจาก installation, PDK และ reference project ที่เตรียมไว้ ห้ามนำคำสั่งตัวอย่างไปแทน launcher ที่ PDK รับรองโดยไม่ตรวจสอบ

## 9.1 ผลลัพธ์การเรียนรู้

เมื่อจบ Lab ผู้เรียนต้องทำได้ดังนี้

1. ระบุ artifact ที่แต่ละ check ใช้ และพิสูจน์ได้ว่าเป็น revision เดียวกัน
2. รัน DRC/LVS ด้วย deck, switches และ hierarchy policy ที่ถูกต้อง
3. แยก tool/setup failure ออกจาก design violation
4. ใช้ marker และ cross-probing หาตำแหน่ง สาเหตุ และวิธีแก้
5. รัน self-checking functional GLS บน mapped netlist พร้อม cell models ที่ตรงกัน
6. ยืนยันว่า flow ตรวจพบข้อผิดพลาดที่ใส่โดยตั้งใจ และจัดทำหลักฐานก่อน/หลังแก้
7. อธิบายได้ว่า DRC clean, LVS match, GLS pass และ timing pass เป็นคนละข้อสรุป

## 9.2 ความหมายและขอบเขตของแต่ละ check

| Check | สิ่งที่เปรียบเทียบหรือตรวจ | คำถามหลัก | สิ่งที่ยังสรุปไม่ได้ |
|---|---|---|---|
| DRC | geometry กับกฎใน deck | รูปร่าง ระยะห่าง via และเงื่อนไขที่เปิดตรวจถูกต้องหรือไม่ | ฟังก์ชันถูกต้องหรือไม่ และ netlist ตรงหรือไม่ |
| LVS | connectivity/devices ที่ extract จาก layout กับ reference circuit | วงจรทั้งสองสอดคล้องกันตามกฎ comparison หรือไม่ | timing ผ่านหรือไม่ และ RTL ตรง specification หรือไม่ |
| Functional GLS | mapped netlist + cell simulation models + stimulus/checker | netlist ทำงานตาม expected behavior ในกรณีที่ทดสอบหรือไม่ | ไม่มี timing violation ทุก path หรือไม่ |
| STA | timing graph + libraries + constraints + parasitics | path ที่ถูก constrain ผ่าน setup/hold และ checks ที่กำหนดหรือไม่ | geometry ถูกต้องหรือไม่ และทุกฟังก์ชันถูกทดสอบหรือไม่ |

Functional GLS ใน Lab นี้ไม่ annotate SDF และใช้ functional model ที่ library จัดให้ หาก model มี intrinsic delay ต้องบันทึกให้ชัด ไม่เรียก zero-delay โดยอัตโนมัติ การจำลองพร้อม SDF เป็นหัวข้อขยาย ไม่ใช่เงื่อนไขแทน STA

Siemens อธิบาย Digital Implementer ว่าเริ่ม implementation จาก L-Edit และรองรับการปรับแต่งด้วย Tcl ส่วนการเชื่อม L-Edit กับ Calibre และการ cross-probe เป็น workflow ที่มีเอกสารรองรับ อย่างไรก็ตาม reference project ของห้องอบรมเป็นแหล่งอ้างอิงสำหรับเมนูและ launcher จริง [1–3]

## 9.3 สิ่งที่ผู้สอนต้องเตรียม

### 9.3.1 ชุดข้อมูล

| รายการ | ตัวอย่างชื่อ | เงื่อนไขที่ต้องตรวจ |
|---|---|---|
| Layout database | implementation database ของ Lab 8 | เปิดได้และมี hierarchy ครบ |
| Stream file | counter8_route.gds | top, units, layer map และ cell geometry ถูกต้อง |
| Final mapped netlist | counter8_route.v | ตรงกับ layout หลัง ECO ล่าสุด |
| LVS source | counter8_source.cdl หรือ netlist ที่ flow รองรับ | ภาษาและ conversion ตรง deck |
| DRC launcher/runset | run_drc + approved runset | deck revision และ options ชัดเจน |
| LVS launcher/runset | run_lvs + approved runset | source/layout top, PG และ hierarchy ถูกต้อง |
| LVS library | standard-cell CDL/SPICE หรือข้อมูลตาม flow | cell/pin order และ devices สอดคล้องกัน |
| Simulation library | functional Verilog/VHDL models | ครอบคลุมทุก instantiated cell |
| Testbench | tb_counter8_gls.sv หรือ .vhd | self-checking พร้อม timeout |
| STA baseline | post-route reports | มาจาก revision เดียวกัน |

Liberty ใช้แทน simulation model ไม่ได้ และ LEF ไม่ใช่ full layout สำหรับ device extraction ตรวจว่าการ stream out รวม standard-cell GDS หรือมี library resolution ที่ deck รองรับจริง หาก flow ใช้ hierarchical cell recognition ต้องตรวจขอบเขตการตรวจและการรับรอง library ด้วย

### 9.3.2 แบบฟอร์ม run identity

```text
RUN_ID:
Date/time/timezone:
Operator:
Implementation tool/version:
Verification tool/version:
Simulator/version:
PDK release / metal stack / voltage option:
Top layout cell:
Top source circuit:
RTL revision:
Implementation database revision:
Layout stream SHA256:
Mapped netlist SHA256:
LVS reference SHA256:
Deck revision/checksum and included-file manifest:
DRC/LVS switches and hierarchy policy:
Simulation model release and compile options:
Approved waivers / black boxes:
```

Checksum ของ wrapper deck เพียงไฟล์เดียวไม่ครอบคลุม included files ให้เก็บรายการ dependency หรือ release identifier ที่ควบคุมได้ด้วย ไม่คัดลอก deck ที่มีข้อจำกัดสิทธิ์ออกนอกพื้นที่ที่ได้รับอนุญาต

### 9.3.3 โครงสร้างพื้นที่ทำงาน

```text
lab09/
  inputs/       layout, final netlist, LVS source
  config/       สำเนา runset และรายการ deck switches
  sim/          testbench, file list, simulator scripts
  runs/         แยก subdirectory ต่อ run และต่อ experiment
  reports/      summary และ issue log
  release/      เฉพาะ artifact ที่ตรวจครบแล้ว
```

เก็บ baseline แบบอ่านอย่างเดียว ทำ fault injection บนสำเนาแยก และระบุชื่อให้แยกจาก release ได้ทันที

## 9.4 ขั้นที่ 1 — Freeze และตรวจ input หลัง routing

1. เปิด design ของ Lab 8 ตรวจ top, boundary, supply pins และ routed connectivity
2. ตรวจว่าไม่มีงาน ECO ที่แก้ใน GUI แต่ยังไม่ save หรือยังไม่ export
3. export layout และ final netlist จาก revision เดียวกันตาม reference flow
4. บันทึก stream-out log รวม warning เกี่ยวกับ missing cell, layer mapping และ unsupported objects
5. ตรวจชื่อ top cell ใน stream file ด้วย viewer หรือ stream report ไม่อนุมานจากชื่อไฟล์
6. ตรวจว่าการ export ใช้ database units และ grid ตรงกับ PDK
7. ตรวจชื่อ VDD/VSS, well/substrate nets และ signal ports รวมทั้ง bus order
8. สร้าง checksum ก่อนรัน verification

ตัวอย่าง PowerShell สำหรับบันทึก checksum บน Windows:

```powershell
$items = @(
  '.\inputs\counter8_route.gds',
  '.\inputs\counter8_route.v',
  '.\inputs\counter8_source.cdl'
)
$items | ForEach-Object { Get-FileHash -LiteralPath $_ -Algorithm SHA256 } |
  Export-Csv -LiteralPath '.\reports\input_sha256.csv' -NoTypeInformation
```

คำสั่งนี้ใช้ได้เมื่อสร้างโฟลเดอร์และเตรียมไฟล์ครบแล้ว เปลี่ยนชื่อไฟล์ให้ตรงงานจริง

**จุดตรวจ:** ถ้า layout และ netlist ไม่ตรง revision ให้หยุดและ export ใหม่ก่อนวิเคราะห์ LVS

## 9.5 ขั้นที่ 2 — ตรวจ deck และ run configuration

ผู้เรียนกรอกตารางต่อไปนี้ก่อนเริ่มรัน

| Configuration | ค่าจริงที่ใช้ | หลักฐาน |
|---|---|---|
| Process / metal stack | … | PDK release note |
| DRC deck และ revision | … | launcher/runset |
| LVS deck และ revision | … | launcher/runset |
| Layout path / primary | … | resolved run configuration |
| Source path / primary / language | … | resolved run configuration |
| Include/library paths | … | log |
| Global net / supply mapping | … | deck documentation |
| Hierarchical/flat mode | … | runset |
| Black-box / cell recognition | … | approved list |
| Rule exclusions / waivers | … | approval record |
| Result limit / error cap | … | runset |
| Selected checks / window | … | runset |

อย่าสับสนระหว่าง GUI runset ซึ่งเป็นการตั้งค่าหน้าเครื่องมือ กับ rule file ที่ engine อ่านได้โดยตรง launcher อาจแปลง runset ก่อนรัน การส่งไฟล์ผิดชนิดให้ engine อาจรันไม่ได้หรือใช้ค่าผิด

**คำถามก่อนกด Run:** งานนี้รันทั้ง block หรือเฉพาะ window? มี rule กลุ่มใดปิดอยู่? ถ้ามี cell ที่ skip เพราะ library recognition จะยืนยันความถูกต้องของ library อย่างไร?

## 9.6 ขั้นที่ 3 — รัน DRC baseline

### 9.6.1 Workflow ผ่าน GUI

1. เปิดสำเนา layout ที่ใช้สำหรับ baseline
2. เรียก verification integration ที่ installation เตรียมไว้ เช่น Calibre Interactive เมื่อมีการเชื่อมต่อและ license รองรับ
3. โหลด DRC runset ที่ผู้สอนจัดให้
4. ตรวจ resolved layout path และ primary cell หลังโหลด runset เพราะ runset อาจจำ path ของงานเก่า
5. เลือก output directory ใหม่ เช่น runs/drc_baseline หลีกเลี่ยงทับผลเดิม
6. ตรวจ switches, rule selection, include paths และ error limit
7. รันและรอให้ engine จบจริง
8. อ่าน transcript ตั้งแต่ startup ถึง summary ตรวจ license, parse, missing file และ fatal errors
9. เปิด results database ที่ timestamp ตรงกับ run นี้
10. บันทึกจำนวน violation แยกตาม rule พร้อมจำนวนที่ถูก cap หรือ truncated

### 9.6.2 ตัวอย่าง CLI เฉพาะ flow ที่เตรียม Calibre SVRF ไว้แล้ว

```bash
# ตัวอย่าง shell บน Linux; ตรวจ option ด้วยคู่มือของรุ่นที่ติดตั้ง
# drc_run.svrf ต้องเป็น rule wrapper ที่ engine อ่านได้ ไม่ใช่ GUI runset
calibre -drc -hier drc_run.svrf > drc.log 2>&1
rc=$?
test "$rc" -eq 0 || exit "$rc"
```

ตัวอย่างนี้ไม่ใช่คำสั่ง Tanner Digital Implementer และใช้แทน launcher ของ PDK ไม่ได้โดยอัตโนมัติ ถ้า installation ใช้ engine อื่น ให้ใช้ launcher ที่เตรียมไว้ตาม engine นั้น ผลสำเร็จของ process เพียงอย่างเดียวไม่พิสูจน์ว่า DRC clean ต้องอ่าน completion status และ summary ด้วย

### 9.6.3 แยกผลให้ถูกต้อง

| สถานะ | การตีความ | การดำเนินการ |
|---|---|---|
| License/parse/input failure | ยังไม่ได้ตรวจ design ครบ | แก้ environment/config แล้วรันใหม่ |
| Complete, violations > 0 | พบ design/rule violations | debug จาก rule และ geometry |
| Complete, 0 แต่ selected checks จำกัด | ผ่านเฉพาะ checks ที่เปิด | ระบุ partial scope และรันชุดครบ |
| Results capped | จำนวนที่เห็นไม่ใช่จำนวนทั้งหมด | แก้ root cause หรือปรับ cap ตามทรัพยากร |
| Complete, required checks ครบ, 0 unwaived | ผ่าน DRC ตาม scope ที่ประกาศ | เก็บรายงานและ configuration |

## 9.7 ขั้นที่ 4 — อ่าน marker และแก้ DRC

### 9.7.1 วิธี debug หนึ่ง violation

1. เลือก rule หนึ่งรายการใน results viewer
2. อ่าน rule description จาก deck documentation และเงื่อนไขที่เกี่ยวข้อง ไม่เดาจากชื่อย่อ
3. cross-probe ไปยัง layout ที่ checksum ตรงกับผลตรวจ
4. แสดง layer ของ conductor, cut, enclosure, pin text และ obstruction ที่เกี่ยวข้อง
5. วัด geometry ด้วย units และ grid ของ design
6. ระบุเจ้าของ geometry: routing, PG, standard-cell master, filler/tap, macro หรือ boundary
7. เขียนสมมติฐาน root cause ก่อนแก้
8. แก้ที่ source ของปัญหา เช่น route constraints หรือ via selection แล้ว regenerate เมื่อทำได้
9. รัน local check เพื่อ feedback เร็ว จากนั้นรัน full required checks บน final export
10. ถ้ากระทบ connectivity ให้รัน LVS; ถ้ากระทบ wire/cell ให้ update extraction และ STA ตาม flow

### 9.7.2 ตัวอย่างเชิงตัวเลข

สมมติ deck สำหรับการสอนรายงาน metal spacing ต้องไม่น้อยกว่า 0.20 µm แต่ marker ชี้ระยะ 0.16 µm ตัวเลขนี้ไม่ใช่กฎของ PDK ใดโดยเฉพาะ

1. ยืนยันว่าเป็น spacing rule ปกติ หรือมี width/parallel-run-length exception
2. ถ้าเป็นคนละ net ให้ reroute หรือเลื่อน segment ตาม routing grid
3. ตรวจว่าการเลื่อนสร้าง pin-access หรือ via enclosure issue ใหม่หรือไม่
4. ตรวจ geometry หลัง snap ไม่ใช้ค่าที่คำนวณบนกระดาษอย่างเดียว
5. รัน DRC ใหม่และตรวจ LVS/STA เมื่อ route เปลี่ยน

### 9.7.3 ปัญหาที่พบบ่อย

| Violation | Root cause ที่ควรตรวจ | วิธีแก้ที่เหมาะสม |
|---|---|---|
| Metal width/spacing | route rule, wrong layer map, off-grid | แก้ route/config และ export ใหม่ |
| Via enclosure | via master ผิด หรือ landing metal สั้น | ใช้ via ที่รับรองหรือปรับ landing geometry |
| Minimum area | stub หรือ metal island เล็ก | route repair ตาม net และกฎ |
| Notch | geometry หลัง merge หรือ jog | ปรับรูปร่างโดยตรวจ spacing รอบข้าง |
| Well/tap-related | row/tap pattern หรือ boundary | แก้ insertion plan ตาม PDK |
| Density | window/fill/exclusions | รัน approved fill flow และตรวจใหม่ |
| Antenna | routing exposure ตาม process model | ใช้วิธี repair ที่ flow/PDK รองรับ |
| จำนวนมากซ้ำทุก instance | library option หรือ stream configuration | ตรวจ master/library ก่อนแก้ทีละ marker |

ห้ามแก้ foundry standard-cell master เพื่อทำให้ marker หายโดยพลการ หากเกิดภายใน library ให้ตรวจ release, abutment, orientation และ options แล้วแจ้งผู้ดูแล ไม่ waive โดยอาศัยเหตุผลว่าเป็น library cell อย่างเดียว

## 9.8 ขั้นที่ 5 — เตรียม reference สำหรับ LVS

1. เลือก final implementation netlist ที่สัมพันธ์กับ layout หลัง ECO ไม่ใช้ RTL เป็น source ของ device-level LVS โดยตรง
2. ถ้า deck ต้องการ CDL/SPICE ให้แปลงด้วย qualified exporter/converter ของ flow และเก็บ conversion log
3. ตรวจ top subcircuit, port list และลำดับ pin ของ library subcircuits
4. ตรวจ library includes ครบ โดยไม่มี cell name ซ้ำจากคนละ release
5. ตรวจว่า signal bus เช่น q[7] กับ q<7> ถูก map ตาม naming convention จริง
6. ตรวจ supply names และ global-net semantics ทั้ง source และ extracted layout
7. ตรวจ body/well/substrate connections ตาม device model ของ PDK
8. ตรวจ physical-only cells ได้แก่ filler, tap, decap และ tie cells ด้วย policy ที่ deck รับรอง
9. บันทึกทุก black box และการ exclude ห้ามใช้ wildcard กว้างเพื่อซ่อน unresolved blocks

**แยกมุมมองไฟล์ให้ชัด:** functional GLS อาจใช้ netlist ที่ไม่แสดง PG pins ขณะที่ LVS ใช้ netlist ที่แสดง PG/body pins ทั้งสองมาจาก implementation เดียวกันได้ แต่ต้องบันทึก export options และความสัมพันธ์ ไม่ตัด PG ออกจาก LVS source เพื่อให้ดู match โดยไม่มีหลักเกณฑ์

## 9.9 ขั้นที่ 6 — รัน LVS baseline และอ่านรายงาน

### 9.9.1 Workflow

1. สร้าง run directory ใหม่ เช่น runs/lvs_baseline
2. โหลด approved LVS runset
3. ตรวจ layout primary และ source primary ทีละด้าน
4. ตรวจ source language, includes, PG mapping และ hierarchy policy
5. รันและตรวจว่า extraction กับ comparison จบครบทั้งสองส่วน
6. อ่าน warnings เช่น missing devices/subcircuits, unmatched ports, incomplete extraction
7. อ่าน comparison status จาก report ไม่ใช้จำนวน error marker เป็นเกณฑ์เดียว
8. เก็บ extracted circuit และ correspondence data เมื่อ flow อนุญาต

ตัวอย่าง CLI เฉพาะ Calibre SVRF wrapper ที่เตรียมแล้ว:

```bash
calibre -lvs -hier lvs_run.svrf > lvs.log 2>&1
rc=$?
test "$rc" -eq 0 || exit "$rc"
```

### 9.9.2 ลำดับ debug ที่แนะนำ

**Top/configuration → missing models/devices → supplies/global nets → ports → shorts/opens → instance/device correspondence → parameters**

ลำดับนี้ช่วยลดการไล่ mismatch ปลายทางจำนวนมากที่เกิดจาก root cause เดียว เช่น VSS ไม่ต่อทั้ง row

| อาการ | สิ่งที่ต้องตรวจ |
|---|---|
| Source อ่านไม่ได้ | syntax, include path, conversion log, encrypted/unsupported format |
| Extracted devices เป็นศูนย์หรือผิดปกติ | wrong top, missing library geometry, layer map, device-recognition option |
| Ports ไม่ตรง | labels, text layer, top ports, bus notation, PG policy |
| Shorts | marker และ net tracing ของสอง net ที่ถูกรวม; metal/via/label/global mapping |
| Opens | geometry ขาด, missing via, disconnected rail, label ไม่สร้าง connection ตาม deck |
| Device count mismatch | geometry หาย, wrong master, source include ผิด, recognition settings |
| Parameter mismatch | W/L, multiplier, device subtype และ tolerance ตาม deck |

จำนวน nets หรือ devices อาจเปลี่ยนจาก reduction เช่น parallel-device merging ให้ดู comparison rules ประกอบ ไม่บังคับให้ raw count เท่ากันโดยแก้การออกแบบอย่างไม่มีเหตุผล

### 9.9.3 ตัวอย่างแก้ open ที่ supply rail

1. เลือก unmatched net และ cross-probe ฝั่ง layout/source
2. trace จาก VSS top pin ไปยัง rail และ cell PG pins
3. ตรวจว่าช่วงที่ดูแตะกันมี via ครบทุก layer จริงหรือไม่
4. ตรวจชื่อ text label เทียบกับ connectivity ที่ extractor สร้าง
5. ถ้า global mapping ผิด ให้แก้ configuration อย่างมีเอกสารอ้างอิง; ถ้า geometry ขาด ให้แก้ PDN/route
6. export ใหม่และสร้าง checksum ใหม่
7. รัน DRC และ LVS ใหม่ เก็บ before/after พร้อมภาพเฉพาะตำแหน่งปัญหา

LVS ที่ผ่านเพราะประกาศ net สองเส้นเป็น global เดียวกันไม่ได้พิสูจน์ว่ามี physical connection ที่ต้องการครบ ตรวจ physical PG connectivity ด้วย checks ของ implementation/verification flow เพิ่มด้วย

## 9.10 ขั้นที่ 7 — กำหนด functional contract สำหรับ GLS

ใช้ counter 8 บิตจาก Lab 2 โดยกำหนด interface ดังนี้

| Port | ทิศทาง | ความหมาย |
|---|---|---|
| clk | input | rising-edge clock |
| rst_n | input | asynchronous active-low reset |
| en | input | synchronous clock enable |
| q[7:0] | output | เพิ่มทีละหนึ่ง modulo 256 เมื่อ en=1 |

เมื่อ rst_n=0 ให้ q=0 โดยไม่รอ rising edge; เมื่อปล่อย reset ให้ทำห่างจาก active clock edge ใน stimulus; เมื่อ en=0 ต้องคงค่า; เมื่อ q=255 และ en=1 ให้รอบถัดไปเป็น 0

RTL ต้นทางอาจเป็น VHDL หรือ Verilog/SystemVerilog แต่ GLS ต้อง instantiate gate-level top ที่ export แล้ว ไม่ compile RTL top ชื่อเดียวกันเข้ามาปะปน

ขั้นเตรียม simulation:

1. ตรวจ top interface ของ final netlist ไม่สมมติว่า generic/parameter ของ RTL ยังอยู่
2. รวบรวม cell model ทุกชนิด: flop, combinational, clock buffer, tie, isolation และ macro ที่มีในงาน
3. เลือก functional models ตามคำแนะนำ library ไม่ผสมคนละ release
4. ตัดสินใจเรื่อง PG pins: explicit supply หรือ implicit supplies ตาม model จริง
5. ตรวจ scan/test controls ให้อยู่ functional mode ถ้ามี
6. ใช้ fresh simulator library แยกจาก RTL run
7. ตรวจ compile/elaboration ว่าไม่มี unresolved instances หรือ unintended black boxes
8. บันทึก model mode, timescale/time precision และ initialization policy

ถ้า explicit PG pins มีจริง ตัวอย่าง Verilog wrapper ใช้ supply1/supply0 ต่อ VDD/VSS ตาม pin names จริงของ top/model ไม่ force internal state และไม่เพิ่ม port ที่ netlist ไม่มี

## 9.11 ขั้นที่ 8A — Self-checking GLS ด้วย SystemVerilog

ตัวอย่างต่อไปนี้สมมติ final gate top ชื่อ counter8 มี ports ตามตารางและไม่มี explicit PG ports หากงานจริงต่างออกไปให้ใช้ adapter ที่ต่อ ports อย่างชัดเจน

```systemverilog
module tb_counter8_gls;
  timeunit 1ns;
  timeprecision 1ps;

  logic clk = 0;
  logic rst_n = 1;
  logic en = 0;
  wire [7:0] q;
  logic [7:0] expected = 0;
  int unsigned checks = 0;

  // counter8 ต้อง resolve ไปยัง gate-level netlist เท่านั้น
  counter8 dut (.clk(clk), .rst_n(rst_n), .en(en), .q(q));
  always #5ns clk = ~clk;

  task automatic check_q(input logic [7:0] value);
    if ($isunknown(q)) $fatal(1, "Unknown output at %0t: q=%b", $time, q);
    if (q !== value)
      $fatal(1, "Mismatch at %0t: expected=%0d actual=%0d", $time, value, q);
    checks++;
  endtask

  task automatic cycle(input bit enable_value);
    @(negedge clk);
    en = enable_value;
    @(posedge clk);
    if (enable_value) expected = expected + 8'd1;
    // ให้ NBA/delta cycles และ combinational propagation เสร็จก่อน sample
    #1ns;
    check_q(expected);
  endtask

  task automatic reset_now;
    // เรียกขณะไม่มี active edge ใกล้เคียง และสร้าง reset transition จริง
    rst_n = 0;
    #1ns;
    expected = 0;
    check_q(expected);
    repeat (2) @(negedge clk);
    #1ns;
    rst_n = 1;
  endtask

  initial begin
    #2ns;
    reset_now();
    repeat (4) cycle(0);       // hold after reset
    repeat (260) cycle(1);     // exercise wraparound
    repeat (5) cycle(0);       // hold nonzero value
    for (int i = 0; i < 40; i++) cycle((i % 3) != 0);
    en = 0;
    #1ns;
    reset_now();              // asynchronous reset during operation
    repeat (3) cycle(0);
    repeat (8) cycle(1);
    $display("GLS_PASS checks=%0d", checks);
    $finish;
  end

  initial begin
    #20us;
    $fatal(1, "GLS_TIMEOUT");
  end
endmodule
```

สำหรับ functional simulation นี้ period=10 ns และ sample offset=1 ns เป็นค่าตัวอย่าง ไม่ใช่ timing specification ของ PDK และใช้ตัดสิน timing closure ไม่ได้ หาก model มี delay เกิน offset ให้ทบทวน model mode และ verification plan ไม่ขยาย offset เพื่อซ่อน timing failure ใน SDF simulation

## 9.12 ขั้นที่ 8B — Self-checking GLS ด้วย VHDL

กรณี gate netlist เป็น Verilog และ TB เป็น VHDL ต้องใช้ simulator/license ที่รองรับ mixed-language พร้อม binding rules ของ installation หากไม่มี ให้ใช้ SystemVerilog TB ข้างต้นกับ gate netlist โดยคง functional contract เดิม

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_counter8_gls_vhdl is
end entity;

architecture sim of tb_counter8_gls_vhdl is
  signal clk   : std_logic := '0';
  signal rst_n : std_logic := '1';
  signal en    : std_logic := '0';
  signal q     : std_logic_vector(7 downto 0);

  -- ให้ simulator bind component นี้กับ gate-level top ตาม mixed-language setup
  component counter8 is
    port (
      clk, rst_n, en : in std_logic;
      q : out std_logic_vector(7 downto 0)
    );
  end component;
begin
  clk <= not clk after 5 ns;
  dut : counter8 port map(clk => clk, rst_n => rst_n, en => en, q => q);

  stimulus : process
    variable expected : unsigned(7 downto 0) := (others => '0');
    variable checks : natural := 0;

    procedure check_q(constant value : unsigned(7 downto 0)) is
    begin
      for i in q'range loop
        assert q(i) = '0' or q(i) = '1'
          report "GLS_UNKNOWN" severity failure;
      end loop;
      assert q = std_logic_vector(value)
        report "GLS_MISMATCH expected=" & integer'image(to_integer(value))
        severity failure;
      checks := checks + 1;
    end procedure;

    procedure cycle(constant enable_value : std_logic) is
    begin
      wait until falling_edge(clk);
      en <= enable_value;
      wait until rising_edge(clk);
      if enable_value = '1' then expected := expected + 1; end if;
      wait for 1 ns;
      check_q(expected);
    end procedure;

    procedure reset_now is
    begin
      rst_n <= '0';
      wait for 1 ns;
      expected := (others => '0');
      check_q(expected);
      for i in 1 to 2 loop wait until falling_edge(clk); end loop;
      wait for 1 ns;
      rst_n <= '1';
    end procedure;
  begin
    wait for 2 ns;
    reset_now;
    for i in 1 to 4 loop cycle('0'); end loop;
    for i in 1 to 260 loop cycle('1'); end loop;
    for i in 1 to 5 loop cycle('0'); end loop;
    for i in 0 to 39 loop
      if i mod 3 = 0 then cycle('0'); else cycle('1'); end if;
    end loop;
    en <= '0';
    wait for 1 ns;
    reset_now;
    for i in 1 to 3 loop cycle('0'); end loop;
    for i in 1 to 8 loop cycle('1'); end loop;
    report "GLS_PASS checks=" & integer'image(checks) severity note;
    finish;
    wait;
  end process;

  watchdog : process
  begin
    wait for 20 us;
    assert false report "GLS_TIMEOUT" severity failure;
    wait;
  end process;
end architecture;
```

ทั้งสอง TB ตรวจ 322 ครั้งเมื่อจบตามลำดับที่กำหนด ได้แก่ reset checks 2 ครั้งและ cycle checks 320 ครั้ง การมี PASS marker พร้อมจำนวน checks ช่วยแยก successful completion ออกจากการหยุดก่อนจบ

## 9.13 ขั้นที่ 9 — Compile, elaborate และรัน GLS

ตัวอย่างต่อไปนี้ใช้รูปแบบคำสั่งตระกูล Questa/ModelSim เพื่อการปรับใช้ ต้องตรวจ executable, mixed-language support และ options จากคู่มือรุ่นที่ติดตั้ง ไม่ใช่ syntax ของ TDI engine

### 9.13.1 SystemVerilog TB กับ Verilog netlist

รันจาก sim directory และใช้ mapping เฉพาะงานนี้:

```tcl
# compile_sv.do — ตรวจทุก path ก่อนใช้
onerror {quit -code 1 -force}
vlib gls_work
vmap gls_work gls_work

# cell_models.f ต้องมีรายชื่อ model files และ include options ที่ library ระบุ
vlog -work gls_work -f cell_models.f
vlog -work gls_work ../inputs/counter8_route.v
vlog -sv -work gls_work tb_counter8_gls.sv

vsim -onfinish stop gls_work.tb_counter8_gls
onbreak {quit -code 1 -force}
run -all
quit -code 0 -force
```

เรียกจาก shell เช่น:

```bash
vsim -c -do compile_sv.do > gls_sv.log 2>&1
```

### 9.13.2 VHDL TB กับ gate-level netlist

ใช้ compile script เดิมส่วน cell models/netlist แล้วแทนส่วน TB และ elaboration ด้วย:

```tcl
vcom -2008 -work gls_work tb_counter8_gls_vhdl.vhd
vsim -onfinish stop gls_work.tb_counter8_gls_vhdl
```

ถ้า component binding ไม่พบ Verilog module ให้ตรวจชื่อ case, port type, width และ library search rules ที่คู่มือ simulator ระบุ บาง setup ต้องแยก vendor library แล้วเพิ่ม -L ตามชื่อที่ compile จริง ห้ามแก้ด้วยการ compile RTL มาแทน gate top

### 9.13.3 เกณฑ์ตัดสิน run

ต้องครบทุกข้อ: compile/elaborate สำเร็จ, simulation จบก่อน watchdog, ไม่มี fatal/assertion failure, ไม่มี unresolved cell หรือ black box ที่ไม่ได้รับอนุมัติ และมี `GLS_PASS checks=322` เพียงครั้งเดียวสำหรับ TB ตัวอย่างนี้

`run -all` จบหรือ exit code เป็นศูนย์เพียงอย่างเดียวไม่พอ ผู้สอนต้องตรวจ failure exit behavior ด้วย negative test เพราะ severity, break behavior และ batch exit แตกต่างตาม simulator/version

## 9.14 ขั้นที่ 10 — Debug functional GLS

| อาการ | ตรวจอะไรเป็นลำดับแรก | สิ่งที่ไม่ควรใช้กลบปัญหา |
|---|---|---|
| Compile ไม่รู้จัก cell | file list, model release, include, library map | empty stub ที่ output ไม่จริง |
| Elaboration port mismatch | final top, PG pins, bus width, escaped names | ต่อ ports โดยเดาลำดับ |
| q เป็น X หลัง reset | reset transition/polarity, power model, test controls, driver conflict | force register เป็นศูนย์ |
| q ไม่เพิ่ม | enable/clock connection, reset ค้าง, scan mode | เปลี่ยน expected ให้ตรงผลผิด |
| q เพิ่มผิดช่วง sample | race, delta cycles, model delay | ปิด checker |
| RTL ผ่านแต่ GLS ไม่ผ่าน | mapping, reset semantics, X behavior, binding และ synthesis assumptions | สรุปทันทีว่า simulator ผิด |
| ค้างจน timeout | clock process, stimulus wait, run control | เอา timeout ออก |

วิธีไล่ mismatch:

1. ใช้ข้อความ checker หาเวลาที่ผิดครั้งแรก
2. ดู clk/rst_n/en/q และ expected รอบเวลานั้น
3. ตรวจว่า reset และ enable stable ก่อน active edge
4. ยืนยัน instance hierarchy ว่าเป็น gate-level design
5. trace driver จาก top ไปยัง flop control pins โดยใช้ netlist/simulator
6. เปรียบเทียบกับ synthesis warnings และ final netlist connectivity
7. หากเป็น design issue ให้แก้ source แล้ว regenerate implementation ตามขอบเขตที่กระทบ
8. rerun checks ที่เกี่ยวข้อง และยืนยันว่า final checksum เปลี่ยนอย่างมีที่มา

Functional GLS ไม่ควรพึ่งชื่อ internal register จาก RTL เพราะ optimization อาจ rename, merge หรือลบ register ได้ ให้ checker ยึด observable behavior ที่ interface

## 9.15 ขั้นที่ 11 — ใส่ข้อผิดพลาดเพื่อยืนยัน verification flow

ทำเฉพาะสำเนา baseline และแยกแต่ละ experiment ห้ามส่ง fault-injected artifact เข้า release

### Experiment A — DRC spacing fault

1. สำเนา layout ไปยัง experiment_drc
2. เลือก routed signal segment ในบริเวณว่าง ไม่แก้ cell master
3. เลื่อนให้ spacing ระหว่างคนละ net ต่ำกว่ากฎ โดยยังไม่แตะกัน
4. export แล้วรัน required DRC checks
5. ต้องเห็น rule/marker ตรงบริเวณที่แก้ บันทึกตำแหน่งและ checksum
6. ย้อนการเปลี่ยนแปลงหรือกลับไปยัง baseline แล้วรันยืนยันอีกครั้ง

### Experiment B — LVS open fault

1. เริ่มจากสำเนา baseline ใหม่
2. เลือก routing via ของ signal net ที่มีเส้นทางเดียวและตรวจได้ชัด
3. ลบ via ในสำเนา โดยไม่แก้ source reference
4. export แล้วรัน LVS
5. ต้องเห็น connectivity mismatch ที่สัมพันธ์กับ net นั้น
6. DRC อาจผ่านหรือไม่ผ่านขึ้นกับ geometry และ rules; อย่าบังคับ expected DRC outcome
7. คืน baseline แล้วตรวจใหม่

### Experiment C — GLS connectivity fault

1. สำเนา mapped netlist ไป experiment_gls
2. ยืนยันว่า top enable port ไม่ถูกขับภายในและยังใช้ควบคุม counter
3. ในสำเนา netlist เปลี่ยนการใช้ enable ของ logic ให้คงที่ 0 หรือใช้ test-only wrapper ผูก DUT en=0 ขณะที่ TB ยังส่ง en ตามเดิม
4. คง checker และ stimulus เดิม
5. ต้องเกิด mismatch ใน cycle ที่คาดว่าจะเพิ่มค่า และต้องไม่มี GLS_PASS
6. ตรวจ batch exit เป็น failure ด้วย หาก exit ยังเป็น success ให้แก้ run-control ก่อนใช้ใน automation
7. คืน netlist/wrapper เดิมและรันให้ผ่าน

**สิ่งที่ต้องอธิบาย:** wrapper fault ยืนยัน checker และ connectivity ที่ฉีด fault แต่ไม่ได้ยืนยันว่าทุก internal gate fault ถูกตรวจครบ การทดสอบนี้ไม่ใช่ ATPG fault coverage

## 9.16 ขั้นที่ 12 — Regression หลังแก้และตารางผล

| การเปลี่ยนแปลง | ต้องทบทวน/รันใหม่ |
|---|---|
| Signal route/via | DRC, LVS, RC extraction, STA; GLS ถ้า logical connectivity/export เปลี่ยน |
| Cell resize/buffer ECO | DRC, LVS, extraction, STA, GLS และ equivalence ตามแผน |
| PG/tap/filler | DRC, LVS/physical PG checks; power/reliability และ extraction ตามผลกระทบ |
| Simulation models/TB เท่านั้น | compile/elaborate, GLS และยืนยัน model/view consistency |
| Deck/runset/options | verification ที่ใช้ config นั้นและทบทวน baseline interpretation |
| RTL | functional verification, synthesis และ implementation stages ที่เกี่ยวข้องทั้งหมด |

ก่อน release ให้รัน full required DRC/LVS อีกครั้งจาก final exported layout ไม่ใช้ผล local/window check เป็นหลักฐานสุดท้าย และเก็บผล GLS บน final netlist ที่สัมพันธ์กัน

ตัวอย่างตารางรายงานต่อไปนี้เป็นข้อมูลสมมติ:

| Run | DRC unwaived | LVS | GLS | ข้อสรุป |
|---|---:|---|---|---|
| Baseline A | 12 | mismatch | ยังไม่รัน | แก้ via/PG configuration |
| Repair B | 0 | match | fail | ตรวจ functional enable connection |
| Final C | 0 | match | pass, 322 checks | ผ่านเฉพาะ scope ที่ประกาศ |

อย่าใช้ตารางนี้เป็น expected result ที่ผู้เรียนต้องปรับข้อมูลให้ตรง เก็บผลจริงรวม failures และข้อจำกัด

## 9.17 Acceptance criteria

### DRC

- engine จบสมบูรณ์ ไม่มี unresolved input/include หรือ fatal error
- top, layer mapping, process options และ required checks ถูกต้อง
- ไม่มี unwaived violations; ถ้ามี waiver ต้องระบุ rule, location, reason และผู้อนุมัติ
- ไม่มี error cap/truncation ที่ทำให้สรุปผลไม่ครบ
- density/fill/antenna หรือ checks ที่แยก deck มีสถานะชัดเจน ไม่รวมว่า clean โดยไม่ได้รัน

### LVS

- extraction และ comparison จบสมบูรณ์
- report ยืนยัน match/correct ตามเกณฑ์ flow
- ไม่มี unmatched ports/nets/devices หรือ parameter mismatch ที่ยังไม่ยอมรับ
- black boxes, cell recognition, global connections และ exclusions เปิดเผยครบ
- supply/body connectivity มีหลักฐานตามขอบเขต verification plan

### GLS

- gate netlist และ model revision ถูกต้อง ไม่ bind ไปยัง RTL
- reset, enable, hold, increment, wraparound และ reset during operation ผ่าน
- ไม่มี unexplained X/Z หลังช่วง reset/initialization ที่อนุญาต
- มี PASS marker และ check count ตาม TB; negative test ทำให้ fail จริง
- ระบุชัดว่าไม่มี SDF และไม่สรุป timing sign-off จากผลนี้

### ความสอดคล้องของ release

- checks ทุกชุดอ้าง final revision เดียวกันหรือมี view/export relationship ที่ตรวจสอบได้
- route/ECO ล่าสุดมี extraction และ STA ที่เหมาะสม
- เก็บ known limitations และ remaining integration checks สำหรับ analog-on-top

## 9.18 สิ่งที่ต้องส่ง

1. run identity, input checksums และ configuration summary
2. final DRC summary/log/results database พร้อม scope และ waiver list
3. final LVS report/log พร้อม source/layout identities และ black-box policy
4. final mapped netlist, TB, model file list และ GLS transcript ตามสิทธิ์การเผยแพร่
5. หลักฐานอย่างน้อยหนึ่ง violation ก่อน/หลังแก้ พร้อม root cause
6. ผล fault injection ทั้งสาม experiment และหลักฐานกลับสู่ baseline/final ที่ผ่าน
7. post-change STA summary และรายการ checks ที่ยังอยู่นอก Lab
8. README อธิบายวิธี rerun ด้วย launcher จริงของห้องอบรม

แบบฟอร์ม issue log:

```text
Issue ID / run ID:
Check and rule/message:
Affected cell/net/location:
Observed symptom:
Root cause and evidence:
Change made / revision:
Checks rerun:
Before/after result:
Remaining limitations / owner:
```

## 9.19 คำถามท้าย Lab พร้อมแนวคำตอบ

**1. DRC เป็นศูนย์ แต่ LVS fail ได้อย่างไร?**
Geometry อาจถูกกฎแต่ต่อ net ผิด มี open/short หรือ source/configuration ไม่ตรง ตรวจ completion และ deck scope ก่อนสรุป root cause

**2. LVS match แต่ GLS fail ได้อย่างไร?**
Layout อาจตรงกับ reference netlist ที่มีพฤติกรรมผิดอยู่แล้ว หรือ simulation model, reset/test mode, binding และ TB มีปัญหา LVS ไม่ตรวจ specification

**3. เหตุใด functional GLS ผ่านจึงยังไม่ยืนยันความถี่สูงสุด?**
ไม่มีการตรวจ worst-case delays ทุก constrained path และ corner แบบ STA; stimulus ก็ครอบคลุมเพียงกรณีที่ทดสอบ

**4. การใส่ label VSS ลงบน metal ทำให้ต่อ ground เสมอหรือไม่?**
ไม่เสมอ ต้องดู label layer, extraction semantics และ physical connection ไม่ใช้ชื่อแทนการตรวจ geometry

**5. เหตุใดต้องใช้ final implementation netlist สำหรับ LVS/GLS?**
หลัง synthesis/CTS/route อาจมี buffers, tie cells, resized cells และ ECO ที่ RTL หรือ netlist รุ่นเก่าไม่มี

**6. ถ้าทุก standard-cell instance มี error ซ้ำกันควรเริ่มตรงไหน?**
ตรวจ library release, stack/options, master geometry, abutment และ stream/layer mapping ก่อนแก้ individual markers

**7. GLS รันครบเวลาแต่ไม่มี mismatch ถือว่าผ่านหรือไม่?**
ต้องพิสูจน์ว่า checker ทำงานและ test จบครบ มี expected PASS/check count ไม่มี timeout และ negative test ถูกตรวจพบ

**8. ถ้าแก้ DRC ด้วยการเลื่อน route ต้องทำอะไรเพิ่ม?**
ตรวจ connectivity/LVS ตามผลกระทบ update parasitics และ STA; รัน required final checks กับ layout ใหม่

## 9.20 แนวทางประเมินผู้เรียน

| หัวข้อ | คะแนน |
|---|---:|
| Input/configuration traceability | 15 |
| DRC execution และ root-cause repair | 20 |
| LVS execution และ connectivity debug | 25 |
| Self-checking GLS และ model/binding checks | 25 |
| Fault injection, regression และ release evidence | 15 |
| รวม | 100 |

แม้ได้คะแนนรวมสูง ยังถือว่างานไม่ครบหากมี unexplained LVS mismatch, GLS checker ไม่ทำงาน หรือไม่สามารถผูกผลตรวจเข้ากับ final artifact ได้

## 9.21 หัวข้อขยาย — Timing GLS พร้อม SDF

เมื่อ functional GLS ผ่านแล้ว จึงเพิ่ม SDF เป็นการทดลองแยก:

1. ใช้ netlist และ SDF จาก implementation revision เดียวกัน
2. เลือก min/typ/max และ corner อย่างมีที่มา ไม่สรุปว่า max ครอบคลุม hold
3. ตรวจ annotation instance path, hierarchy, cell type, timing arcs และ coverage
4. ตรวจ timescale/time precision และ timing-check/notifier settings
5. ใช้ stimulus ที่ตรง timing contract และ sample strategy ที่ออกแบบสำหรับ timing simulation
6. วิเคราะห์ setup/hold/recovery/removal violations และ X ที่เกิดจาก notifier
7. ไม่ปิด timing checks เพื่อประกาศผ่าน; ถ้าปิดเพื่อ debug ต้องแยก run และระบุชัด

SDF simulation เสริมการตรวจ behavior ภายใต้ delays ที่ annotate แต่ไม่แทน STA/MMMC หรือ CDC/RDC verification

## เอกสารอ้างอิงและขอบเขตการใช้

1. Siemens — Digital Implementation: https://eda.sw.siemens.com/en-US/ic/ic-custom/ams/digital-implementer/
2. Siemens — Tanner L-Edit IC factsheet: https://static.sw.cdn.siemens.com/siemens-disw-assets/public/1rBNeyD3nt6LnA8Tnwvwkv/en-US/Siemens%20SW%20Tanner%20L%20Edit%20IC%20FS%2081552%20C1.pdf
3. Siemens — Transforming IC design flows with Calibre: https://resources.sw.siemens.com/fr-FR/white-paper-transforming-ic-design-flows-with-calibre/
4. คู่มือ DRC/LVS engine และ Questa/ModelSim ของรุ่นที่ติดตั้ง ใช้ตรวจ syntax, binding และ batch failure behavior
5. PDK verification manual, deck release notes, standard-cell simulation/LVS documentation และ approved reference project ของห้องอบรม

เอกสารสาธารณะ [1–3] รองรับบริบทผลิตภัณฑ์และ integration; ไม่ใช่แหล่งยืนยัน deck switches, process rules หรือ CLI ทุกคำสั่งใน Lab ตัวอย่าง TB และขั้นตอนทดลองเป็นแบบฝึกหัดที่ต้อง compile/rerun บน environment ของห้องอบรมก่อนใช้สอน
