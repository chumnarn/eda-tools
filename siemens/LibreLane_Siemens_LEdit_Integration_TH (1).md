# คู่มือ Integrating LibreLane with Siemens L-Edit IC

**กรณีศึกษา IHP SG13G2 · Digital layout review และการรวม Digital Macro ในชิป Mixed-Signal**

LibreLane ทำ synthesis และ physical implementation ของ digital block แล้วส่งมอบ GDSII ให้ L-Edit IC ใช้เปิดตรวจ layout หรือวางเป็น hierarchical macro ใน custom top-level งาน integration นี้อาศัยสัญญาระหว่างเครื่องมือสามส่วน ได้แก่ **ชื่อ cell และลำดับชั้น, พิกัดและหน่วย, และ GDS layer/purpose** ส่วนสัญญาด้านไฟฟ้าต้องจัดการผ่าน pin list, schematic/netlist และ verification deck ของโครงการ

คู่มือนี้ใช้ขั้นตอนตามหน้าที่ของคำสั่ง Stream Import/Export เนื่องจากชื่อเมนูและรูปแบบ layer map ขึ้นกับรุ่น L-Edit และชนิดฐานข้อมูลที่ใช้งาน ให้เทียบกับ Help ของรุ่นที่ติดตั้ง ขั้นตอนฝั่ง L-Edit ยังไม่ได้ทดสอบบน installation จริง

## 1. เลือกขอบเขตของงาน

| งาน | จุดเริ่ม | ผลที่ต้องตรวจ |
|---|---|---|
| เปิดตรวจ digital block | GDSII ของ block | top cell, hierarchy, ขนาด, layer/purpose, label |
| นำ digital macro ไปวางใน mixed-signal top | GDSII ของ core และ pin/netlist contract | origin, orientation, interface, power domains, top DRC/LVS |
| เปิดตรวจ digital full chip | GDSII ของ chip top | pad ring, bond pads, seal ring และ fill ตาม release manifest |
| ส่ง GDSII ออกจาก L-Edit | ฐานข้อมูลที่ import หรือแก้แล้ว | round-trip comparison หรือ ECO verification ตามชนิดงาน |

สำหรับ lab แรกให้เลือก **digital core ขนาดเล็กที่มี clock, reset, data I/O และ power rails** งาน full chip ให้ใช้ top ตาม release manifest หาก macro จะอยู่ใต้ custom padframe ให้เลือก core ที่เตรียมมาเพื่อประกอบเป็น macro

## 2. เตรียมเครื่องมือและ PDK

1. ฝั่ง LibreLane เตรียม run ที่จบตาม flow ที่ต้องการ เช่น Classic หรือ Chip และระบุ run tag ที่จะใช้
2. ฝั่ง Windows หรือ Linux เตรียม Siemens L-Edit IC ที่เปิดใช้งานได้ พร้อม write access ใน work library และบันทึกรุ่นเครื่องมือ
3. เตรียม KLayout สำหรับเปิด GDS ต้นฉบับและเปรียบเทียบไฟล์ที่ส่งออก
4. บันทึก revision ของ IHP SG13G2 ที่ LibreLane ใช้ แล้วรวบรวม layer map และ verification decks ของ revision ที่โครงการกำหนด
5. ตรวจสิทธิ์และความพร้อมของ **L-Edit technology/PDK และ Calibre decks แยกกัน** เอกสาร IHP OpenPDK ระบุชุดเทคโนโลยีสำหรับ KLayout, Magic และเครื่องมืออื่นตามโครงสร้างที่เผยแพร่ ให้ตรวจจากชุดติดตั้งหรือผู้ดูแล PDK ว่ามี L-Edit technology สำหรับงานนี้หรือไม่

| สภาพแวดล้อม | แนวทาง |
|---|---|
| มี L-Edit technology ที่ตรง process และตรวจสอบแล้ว | สร้าง work library ภายใต้ technology นั้นและใช้ stream map ของรุ่นที่ติดตั้ง |
| มีเฉพาะ IHP OpenPDK สำหรับ KLayout/Magic | ใช้ L-Edit เป็นพื้นที่ตรวจรูปทรงโดยคงหมายเลข GDS ทุกคู่ ถ้ารุ่นที่ใช้รองรับการสร้างหรือแมปเลเยอร์เหล่านั้น |
| ไม่สามารถเก็บคู่ layer/type ครบ | หยุดก่อน export เพื่อใช้งานต่อ และเปิดต้นฉบับใน KLayout สำหรับตรวจ |

ไฟล์ `.lyp` ใช้แสดง layer properties ใน KLayout ส่วน `.map` ของ IHP เป็นข้อมูลอ้างอิงสำหรับสร้างตารางเทียบกับ technology ใน L-Edit ต้องตรวจรูปแบบไฟล์ stream map ของ L-Edit ก่อนนำไปใช้

## 3. คัด GDSII จาก run ที่เลือก

LibreLane เก็บมุมมองส่งมอบใน `final/` โดยปกติเริ่มจาก `final/gds/` ตรวจว่าเป็น GDS หลักของ flow และมีขั้นตอน fill/การประกอบ padframe ตามที่ release กำหนด `final/klayout_gds/` และ `final/mag_gds/` อาจมี stream จากคนละเครื่องมือ ขึ้นกับ configuration และ step ที่รัน ตรวจ log และ `PRIMARY_GDSII_STREAMOUT_TOOL` หาก flow ของรุ่นนั้นใช้ตัวแปรนี้

ตัวอย่าง Bash ให้เปลี่ยน run tag และชื่อไฟล์ให้ตรงกับผลจริง

```bash
set -euo pipefail
run_dir='runs/my_run'
find "$run_dir/final" -maxdepth 2 -type f -name '*.gds' -print

source_gds="$run_dir/final/gds/digital_core.gds"
test -s "$source_gds"
mkdir handoff
cp -- "$source_gds" handoff/source.gds
(
  cd handoff
  sha256sum source.gds > SHA256SUMS
  sha256sum -c SHA256SUMS
)
```

ใช้โฟลเดอร์ handoff ใหม่สำหรับแต่ละ baseline คำสั่ง `mkdir handoff` จะหยุดหากมีโฟลเดอร์เดิมอยู่แล้ว เมื่อย้ายไป Windows ตรวจ SHA-256 ด้วย `Get-FileHash .\handoff\source.gds -Algorithm SHA256` แล้วเทียบกับ `SHA256SUMS`

เก็บ run tag, design revision, LibreLane version, PDK revision, top cell, สถานะ fill และ checksum ไว้ด้วย เก็บ layout source และ reference netlist ที่เป็นคู่กัน หากต้องใช้ STA หรือ LVS ในภายหลัง ให้เก็บรายงานและ views ที่สอดคล้องกับ run นั้น

## 4. สร้าง baseline ใน KLayout

1. เปิด `source.gds` ด้วย KLayout และเลือก top cell ตาม manifest ชื่อไฟล์และชื่อ cell อาจต่างกัน
2. บันทึก database unit (DBU), bounding box ทั้งสี่ค่าใน µm, จุดอ้างอิงของ macro และระยะระหว่าง features ที่วัดซ้ำได้สองจุด ตัวอย่างเช่นขอบของ pin สองตัวที่อยู่ต่างแนว
3. บันทึก cell สำคัญและตำแหน่งของ instances เช่น SRAM, pad cell และ digital macro ตรวจด้วยว่ามี geometry อยู่ใน cell ที่คาดหวัง
4. จดคู่ GDS layer/type **ที่ปรากฏจริง** รวมถึงชนิด record ของ polygon/path และ text สำหรับ text ให้เก็บ `TEXTTYPE` แยกจาก `DATATYPE` ของ geometry
5. บันทึก pin geometry และข้อความอ้างอิง เช่น `clk`, `rst_n`, `VDD`, `VSS` โดยใช้ชื่อจริงใน design และระบุกรณีที่ release ใช้ไฟล์ pin contract แทน label ใน stream

### ตาราง layer map ที่ใช้ตรวจสอบ

กรอกหมายเลขจาก map ของ PDK revision ที่ pin ไว้และจาก GDS ที่ตรวจจริง ตารางนี้ใช้สำหรับ audit ก่อนแปลงเป็นรูปแบบที่รุ่น L-Edit รองรับ

| สิ่งที่ตรวจ | คู่ตัวเลขต้นทาง | ปลายทางใน L-Edit | ตรวจหลัง export |
|---|---|---|---|
| Routing metal geometry | layer / DATATYPE | Metal drawing | คู่เดิมและรูปทรงเดิม |
| Pin geometry | layer / DATATYPE | Pin purpose | คู่เดิมและตำแหน่งเดิม |
| Label | layer / TEXTTYPE | Text หรือ label purpose | string, layer/type, จุดอ้างอิงและ orientation |
| Via cut | layer / DATATYPE | Via drawing | คู่เดิมและแนวซ้อนกับ metal |
| Fill, boundary, passivation หรือ marker | layer / DATATYPE | purpose ตาม PDK | คู่และรูปทรงตามรายการส่งมอบ |

ตรวจทุกคู่ที่พบ รวมถึงคู่ที่มาจาก SRAM, I/O หรือ seal ring ระวังการแมปคู่ GDS หลายคู่ลงปลายทางเดียว เพราะ export อาจแยกกลับเป็นคู่เดิมไม่ได้ หากต้องเก็บเลเยอร์ที่ยังไม่รู้ความหมาย ให้คงคู่ตัวเลขแยกกันและระบุสถานะรอตรวจสอบ

## 5. Import เข้า L-Edit

1. สร้าง design/library ชั่วคราว เช่น `ll_import_review` ภายใต้ technology ที่เลือก ตรวจ database resolution และ grid ของ technology
2. เปิดคำสั่ง Import สำหรับ GDSII/Stream แล้วเลือก `source.gds` และกำหนด import layer map ถ้ารุ่นที่ใช้รองรับ
3. ใช้ scaling ตาม units ของ stream โดยคงขนาดทางกายภาพเดิม หลีกเลี่ยง manual scaling หรือการ snap เรขาคณิตทั้งหมดเข้ากริดโดยอัตโนมัติ
4. เก็บ hierarchy, cell references, arrays และ text เท่าที่ตัวเลือกในรุ่นนั้นรองรับ นำเข้าใน work library ว่างเพื่อหลีกเลี่ยงชื่อ cell ชนกับฐานข้อมูลเดิม
5. เก็บ import log ตรวจ unknown layers, skipped records, duplicate cell names, unresolved references และข้อความเตือนเรื่อง precision
6. เปิด top cell ที่ระบุใน manifest ใช้ fit view แล้วเพิ่มระดับการแสดง hierarchy หากเห็นเฉพาะ instance boxes เปิดการมองเห็น layer/purpose ที่ต้องการ
7. เทียบ bounding box, ตำแหน่ง macro, ขนาดอ้างอิง และ pin/label กับ baseline ตรวจด้าน mirror และ rotation ด้วยจุดอ้างอิงที่ไม่สมมาตร

ถ้า layer สีต่างกันแต่หมายเลขและ purpose ถูกต้อง ให้แยกเป็นประเด็นการแสดงผล หาก shapes, labels หรือ instances หาย ให้แก้ setup แล้วนำเข้าจากต้นฉบับใหม่ใน work library ว่าง

## 6. ทดสอบ round-trip ก่อนเริ่มแก้ไข

1. Export layout ที่เพิ่ง import เป็น `roundtrip.gds` โดยกำหนด export map ให้คืนทุกคู่ตัวเลขเดิม และเลือกขอบเขต export เป็น top พร้อม descendants
2. เปิด `source.gds` และ `roundtrip.gds` ใน KLayout เลือก top ที่เทียบกัน ตรวจหน่วยและตำแหน่งอ้างอิง ห้ามย้ายหรือ rescale ไฟล์เพื่อกลบความต่าง
3. ใช้ **Tools → XOR Tool** เปรียบเทียบเรขาคณิตทุกเลเยอร์ที่เกี่ยวข้อง โดยเริ่มจาก tolerance ศูนย์ ตรวจว่าครอบคลุมคู่ที่มีอยู่เพียงไฟล์เดียวด้วย สำหรับ layout ใหญ่ใช้ tiling หรือเครื่องมือที่รองรับ hierarchical comparison ตามขนาดงาน
4. ใช้ **Diff Tool** และตรวจ text/pin โดยเฉพาะ เปรียบเทียบ cell/instance, array transforms, label strings, text layer/type และตำแหน่ง label บันทึกความต่างเชิง representation เช่น polygon ถูก fracture หรือชื่อ cell ถูกเปลี่ยนตาม policy
5. เกณฑ์ผ่านสำหรับรอบที่ไม่มี ECO คือ geometry XOR ว่างในขอบเขตที่ตรวจ, ไม่มีเลเยอร์หรือ label ที่ต้องใช้สูญหาย และโครงสร้าง macro ที่ต้องใช้งานยังครบ เก็บ diff report และข้อยกเว้นที่ตรวจสอบแล้ว

SHA-256 ของสอง stream อาจต่างกันจาก record ordering, timestamps หรือรูปแบบ geometry ที่เครื่องมือเขียนกลับ ใช้ checksum ระบุไฟล์แต่ละฉบับ และใช้ XOR/Diff ตรวจความเทียบเท่าในระดับที่ต้องการ

## 7. นำไปประกอบเป็น Mixed-Signal Top

### 7.1 สร้าง interface contract

| รายการ | สิ่งที่ต้องระบุ |
|---|---|
| Boundary / origin | ขอบวาง macro, จุดอ้างอิง, orientation ที่อนุญาต, keepout |
| Signal pins | ชื่อ, bus syntax/order, direction, access layer และตำแหน่ง |
| Power pins | supply domain, ชื่อ rail, ตำแหน่งและชั้นเชื่อมต่อ, ชื่อใน schematic/LVS |
| Logical view | netlist หรือ subcircuit ที่ตรงกับ layout และลำดับพอร์ต |
| Timing view | Liberty/ข้อจำกัด interface เมื่อใช้วิเคราะห์ timing ระดับ top |
| Verification view | deck, revision, extraction และข้อตกลง hierarchical LVS |

ใช้ LEF ของ macro หากมีเพื่ออ้างอิงขอบและจุดเข้าถึง pins ตรวจคู่กับ GDS และ source netlist โดยคำนึงถึงพิกัด origin ของแต่ละ view ตัวอย่างเช่น label `VDD` ที่เห็นใน stream ยังต้องมี geometry ที่ extraction deck ยอมรับและเส้นทางโลหะเชื่อมกับ rail ระดับ top

### 7.2 วางและต่อใน top

1. สร้าง custom top cell แล้ว instantiate digital core เป็น subcell เก็บ library reference หรือ include definition ให้ครบเมื่อ stream out
2. วาง macro ตาม orientation ที่อนุญาต ตรวจ pin access, routing clearance, ระยะจาก analog block และข้อกำหนด isolation ของโครงการ
3. เชื่อม supply/ground ให้ตรง domain และวาง routes สำหรับ clock, reset, data I/O ตรวจ polarity และ bus order กับ schematic
4. สำหรับ padframe ตรวจ pad-to-core mapping, rail ของ core และ I/O, bondpad/passivation และผลของ seal ring/fill ตาม checklist โครงการ
5. Export top ไปยังชื่อไฟล์ใหม่ จากนั้นทำ top-level DRC และ LVS กับ reference schematic/netlist ด้วย decks ที่โครงการรับรอง หากใช้ Calibre ให้ยืนยัน license, rule decks และ layer conventions ก่อน การใช้ hierarchical LVS หรือ black-box macro ให้ใช้ตามวิธีที่ deck และโครงการกำหนด พร้อมหลักฐานว่า macro ผ่านการตรวจในขอบเขตของตนเอง
6. เมื่อมีการแก้ geometry ที่เกี่ยวกับสัญญาณหรือ power ให้ตรวจ extraction/STA, antenna, density และ IR/EM ตามผลกระทบและข้อกำหนดของโครงการ ผลจาก run เดิมใช้เป็น baseline สำหรับเทียบ

สำหรับ digital ECO ที่กระทบ netlist หรือ routing ให้กำหนดเจ้าของการเปลี่ยนและสร้าง GDS/LEF/netlist/timing views จาก revision เดียวกัน ตัวอย่าง workflow คือแก้ใน RTL/LibreLane แล้วเปลี่ยน macro instance ใน custom top พร้อมรัน verification ใหม่ตามขอบเขต

## 8. Lab 90 นาที

| เวลา | งาน | หลักฐาน |
|---|---|---|
| 15 นาที | เลือก final GDS และบันทึก baseline ใน KLayout | SHA-256, top cell, DBU, bbox |
| 20 นาที | ทำตาราง map และ import ลง library ว่าง | layer audit, import log |
| 20 นาที | Export โดยไม่มี ECO และเทียบ XOR/Diff | ผล geometry และ text/hierarchy |
| 20 นาที | Instantiate digital macro ใน top สำหรับฝึก | ภาพ layout และ pin/power contract |
| 15 นาที | ทำ negative test และสรุปผล | อาการที่พบและหลักฐานการตรวจจับ |

**Negative test** ใช้ work library แยกและ map สำเนา เลือก label หนึ่งคู่ที่ยืนยันว่ามีจริง แล้วตั้งให้ข้ามคู่ดังกล่าวหากรุ่นเครื่องมือรองรับ หรือ remap ไปยังคู่ทดสอบที่ไม่ได้ใช้ในไฟล์ จากนั้น export และตรวจว่าการเปรียบเทียบ text ตรวจพบความต่าง แม้ geometry XOR อาจยังว่าง เก็บ GDS ของ negative test แยกจาก release candidate

### Troubleshooting

| อาการ | ตรวจแรก | วิธีแก้ |
|---|---|---|
| เปิดได้แต่จอว่าง | top cell, fit view, hierarchy depth, layer visibility | เลือก top ที่ถูกและเปิดชั้นที่เกี่ยวข้อง |
| ขนาดต่างเป็นเท่าตัว | หน่วย stream, scale, DBU | แก้ import setup แล้วนำเข้าใหม่ |
| ขอบตำแหน่งคลาดเล็กน้อย | quantization และ snap grid | ตั้ง resolution ให้รองรับพิกัดต้นทาง |
| Metal เห็น แต่ vias หรือ labels หาย | mapping ของ cut และ text type | แยก geometry/text mapping และดู import log |
| Macro แสดงเป็นกล่อง | hierarchy display และ cell definition | เพิ่ม display depth และตรวจ references/definitions |
| XOR ว่างแต่ LVS fail | label semantics, netlist, supply, pin order | ตรวจ extraction deck และ top interface |
| DRC เพิ่มหลังประกอบ top | ขอบ macro, pin access, via, fill, pad/seal interaction | แก้ที่ top หรือส่งกลับเจ้าของ macro ตามตำแหน่ง violation |

### เกณฑ์ส่งงาน

ส่งต้นฉบับและ round-trip GDS, manifest และ checksum, layer-map audit, import/export logs, ผล XOR และ text/hierarchy check ถ้าเป็นงาน mixed-signal assembly ให้แนบ interface contract, top GDS, reference netlist และรายงาน verification ตามขอบเขตด้วย

## เอกสารอ้างอิง

- [Siemens L-Edit IC](https://www.siemens.com/en-gb/products/ic/ic-custom/ams/l-edit-ic/) — hierarchical layout, OpenAccess และ Calibre integration
- [LibreLane Newcomers’ Tutorial](https://librelane.readthedocs.io/en/stable/getting_started/newcomers/index.html) — โครงสร้าง final views
- [LibreLane Built-in Steps](https://librelane.readthedocs.io/en/latest/reference/step_config_vars.html) — StreamOut และการเลือก GDS หลัก
- [IHP OpenPDK Technology Libraries](https://ihp-open-pdk-docs.readthedocs.io/en/latest/contents/technology_libraries/index.html) — ตำแหน่ง technology files และ layer map
- [KLayout XOR Tool](https://klayout.de/doc/manual/xor.html) และ [Diff Tool](https://klayout.de/doc/manual/diff.html) — เปรียบเทียบ geometry และโครงสร้าง
