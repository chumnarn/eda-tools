# Lab 7 — Clock Tree Synthesis (CTS) และ Propagated Timing

หลักสูตร Tanner Digital ASIC Design Implementation — ระดับเริ่มต้นถึงกลาง

## 1. เป้าหมายของปฏิบัติการ

ปฏิบัติการนี้ต่อจาก placement โดยใช้ฐานข้อมูลที่วางเซลล์ถูกกฎหมายแล้ว ผู้เรียนจะตรวจว่าคล็อกถูกนิยามและไปถึง sequential elements ที่ตั้งใจ จากนั้นสร้าง clock distribution network ตรวจคุณภาพของ tree และอ่าน timing โดยรวม delay ของ clock path จริงตามโมเดลที่ flow มีอยู่

เมื่อจบ Lab ผู้เรียนต้องทำได้ดังนี้

1. อธิบาย clock source, clock root, clock sink, source latency และ network latency ได้
2. ตรวจ period, waveform, clock coverage และ timing exceptions ก่อน CTS
3. ตั้งค่า CTS จาก standard-cell library และ technology ที่ได้รับอนุมัติ
4. รัน CTS พร้อมตรวจ legality, connectivity, clock transition และ clock load
5. แสดงหลักฐานว่า STA ใช้ propagated clocks และอ่าน launch/capture clock paths ได้
6. คำนวณ setup/hold slack จากรายงานและอธิบายผลของ skew ได้ถูกทิศทาง
7. จัดเก็บ checkpoint และรายงานที่ทำซ้ำได้สำหรับส่งต่อ routing

**ขอบเขต:** digital block หนึ่งคล็อก ไม่มี clock gating, divider หรือ clock mux เป็น baseline ใช้ top จาก Lab 2–6 ได้ทั้ง VHDL และ Verilog/SystemVerilog โดยทำ CTS บน mapped netlist ไม่ใช่บน RTL โดยตรง หากทดลองหลายภาษา ให้ใช้ project/run แยกกันและเทียบที่ specification ไม่คาดหวังชื่อ instance หรือ cell count เหมือนกันทุกประการ

## 2. ข้อกำหนดเกี่ยวกับ TDI และคำสั่งในคู่มือ

Siemens ระบุว่า Digital Implementer รองรับ Clock Tree Synthesis และใช้ synthesis/place-and-route engines ใน flow [1] อย่างไรก็ตาม ชื่อเมนู task, options และ Tcl API ขึ้นกับ release และ reference project ของแต่ละสถานที่

ขั้นตอน GUI ในบทนี้ระบุ **หน้าที่ที่ต้องค้นหา** ไม่ได้อ้างว่าข้อความในเครื่องหมายคำพูดเป็นชื่อเมนูจริง ส่วน code block ระบุชัดว่าเป็น SDC ตัวอย่างหรือ pseudocode ห้ามนำคำสั่ง CTS จากเครื่องมืออื่นมาใช้ใน TDI โดยไม่ได้ตรวจสอบ

ก่อนสอน ผู้สอนต้องเปิด Help/User Guide และ reference flow ของ TDI รุ่นติดตั้ง เติมตารางนี้ให้ครบ แล้วบันทึก command log ที่ GUI สร้างหาก release นั้นรองรับ

| หน้าที่ | เมนู/คำสั่งที่ตรวจสอบในรุ่นติดตั้ง | หลักฐาน |
|---|---|---|
| เปิด/บันทึก checkpoint | ผู้สอนกรอก | คู่มือและ run log |
| โหลด/ตรวจ SDC และ clock coverage | ผู้สอนกรอก | รายงาน clocks/constraints |
| ตั้งค่าและรัน CTS | ผู้สอนกรอก | reference script หรือ GUI log |
| แสดง clock tree/sinks | ผู้สอนกรอก | tree view/report |
| เปิด propagated clock analysis | ผู้สอนกรอก หรือระบุว่า flow ทำอัตโนมัติ | full clock timing path |
| อัปเดต RC และ timing | ผู้สอนกรอก | RC method และ timing log |
| รายงาน max/min paths และ electrical checks | ผู้สอนกรอก | setup/hold และ clock DRC reports |

## 3. สิ่งที่ต้องเตรียมและเกณฑ์ก่อนเริ่ม

ใช้ checkpoint จาก Lab 6 ที่มี floorplan, rows, PG planning, placed cells และ signal pin locations ครบ ต้องไม่มี overlap หรือ off-row placement ที่ยังไม่อธิบาย รวมทั้งไม่มี unresolved references และ missing timing models สำหรับเซลล์ที่นำมาวิเคราะห์

| รายการ | สิ่งที่ต้องตรวจ |
|---|---|
| Design | top, mapped netlist, parameter และ configuration ถูกชุด |
| Timing library | PVT, units, clock buffer/inverter และ sequential cell timing arcs |
| Physical library | LEF/technology, site, layer/via และ physical views ของ CTS cells |
| Constraints | clock, I/O min/max delay, uncertainty และข้อยกเว้นที่มีเหตุผล |
| Placement | legal, มีพื้นที่สำหรับ CTS/repair, ไม่มีการขยับ fixed cells ผิดเจตนา |
| Power | supply association ของ CTS cells และ PG connection strategy พร้อม |
| Analysis | setup/hold views และ RC assumptions ที่ flow รองรับ |

อย่าแก้ข้อผิดพลาดของ Lab 6 ด้วยการรัน CTS ต่อ หาก placement ใช้พื้นที่แน่นจนเพิ่ม buffer ไม่ได้ ให้ย้อนแก้ floorplan/density ก่อน

ระยะเวลาแนะนำ 3–4 ชั่วโมง: ตรวจ input 30 นาที, baseline 30 นาที, CTS 45 นาที, วิเคราะห์/ทดลอง 60–90 นาที และจัดทำผล 30 นาที ทั้งนี้เวลารันขึ้นกับขนาด block และเครื่อง

## 4. แนวคิดที่ต้องเข้าใจก่อนรัน

### 4.1 Ideal clock กับ propagated clock

ก่อน CTS มักวิเคราะห์ clock network แบบ ideal โดยใช้ latency/uncertainty ที่กำหนดเป็นโมเดลตาม flow ค่า ideal ไม่จำเป็นต้องเป็นศูนย์เสมอไป

หลัง CTS มี clock buffers/inverters และเส้นทางไปยัง sink pins แล้ว การตั้ง propagated clock ให้ STA คำนวณ clock arrival ตาม timing arcs และ interconnect model ที่มีอยู่ การมี tree ใน layout เพียงอย่างเดียวไม่พิสูจน์ว่า timing engine ใช้ tree นั้น

**Propagated ไม่ได้แปลว่า extracted หลัง route แล้ว:** post-CTS อาจใช้ placement-based RC หรือ RC จาก clock routing บางส่วน ขณะที่ signal nets ยังเป็น estimate ต้องระบุชัดในรายงาน และยืนยันอีกครั้งหลัง routing/extraction

### 4.2 คำจำกัดความและขอบเขตการวัด

| คำ | ความหมายสำหรับ Lab นี้ |
|---|---|
| Source latency | delay จาก external reference ถึง clock definition point ของ block |
| Network latency | delay จาก clock definition/root ตามขอบเขตที่กำหนด ถึง clock pin ของ sink |
| Insertion delay | ในตาราง Lab ใช้เท่ากับ root-to-sink network latency; หากเครื่องมือใช้ขอบเขตอื่นต้องระบุ |
| Clock sink | ปลายทางที่ CTS รับผิดชอบ เช่น clock pin ของ flip-flop |
| Clock transition | rise/fall slew ที่ clock pin; ต้องอ่านนิยามและ units ของ library |
| Global skew | ช่วง max−min ของ sink arrivals ภายใต้ชุด edge/view ที่กำหนด |
| Path skew | capture arrival − launch arrival ของ timing path ที่พิจารณา |

Global skew ไม่ใช่ skew ของ critical path เสมอไป และการนำ early/late arrivals คนละเงื่อนไขมาลบกันเองอาจไม่ตรงกับนิยามของรายงาน ต้องบอก view, edge และ convention ทุกครั้ง

Clock load ไม่ได้มีเพียงจำนวน sinks แต่รวม input capacitance และ interconnect capacitance ที่แต่ละ driver เห็น จำนวน sinks เท่ากันจึงอาจต้องใช้ tree ต่างกัน

## 5. ขั้นที่ 1 — แยก run และบันทึกฐานข้อมูลตั้งต้น

1. เปิด TDI project จาก Lab 6 และยืนยันชื่อ top และ checkpoint
2. สร้าง run `lab07_cts_baseline` โดยไม่เขียนทับผล placement
3. บันทึก checkpoint `pre_cts` ด้วยรูปแบบ native ของรุ่นติดตั้ง
4. บันทึก TDI build/version, library release, PVT/RC views, SDC และ settings
5. ส่งออกรายงาน cell count, sequential count, cell area, utilization และ placement legality
6. ตรวจว่า clocks และ constraints โหลดสำเร็จ ไม่มี ignored command หรือ object matching warning ที่ปล่อยไว้

โครงสร้างผลส่งมอบแนะนำ (ชื่อ directory ไม่ใช่ข้อกำหนดของ TDI)

```text
lab07_cts/
  manifest.txt
  constraints/pre_cts.sdc
  constraints/post_cts.sdc
  scripts/verified_flow.tcl
  checkpoints/pre_cts/
  checkpoints/post_cts/
  reports/pre_cts/
  reports/post_cts/
  figures/
  comparison.csv
  conclusions.md
```

`verified_flow.tcl` ต้องมาจากคำสั่งที่ตรวจสอบกับ TDI จริง หากใช้ GUI อย่างเดียว ให้ส่ง GUI procedure และ command log ที่มีอยู่แทน ไม่สร้าง Tcl ที่ดูเหมือนรันได้แต่ไม่เคยตรวจสอบ

## 6. ขั้นที่ 2 — ตรวจ clock definition และ constraint contract

### 6.1 ตรวจ clock source จากวงจร

เปิด mapped netlist/schematic จาก clock input เดินไปยัง clock pins ของ flip-flops ตรวจชื่อ port, polarity และ active edge เทียบกับ RTL ทั้งสองภาษา

| พฤติกรรม | VHDL | SystemVerilog |
|---|---|---|
| Rising-edge storage | `if rising_edge(clk) then` | `always_ff @(posedge clk)` |
| Clock enable | `elsif rising_edge(clk) then` แล้วตรวจ `en` ภายใน | ตรวจ `en` ภายใน `posedge clk` process |
| Clock sink | clock pin ของ mapped flop | clock pin ของ mapped flop |

Enable เป็น data/control input ไม่ใช่ clock ใหม่ ส่วน reset ต้องวิเคราะห์ตาม synchronous/asynchronous behavior ของ RTL และ mapped cell อย่าใส่ reset หรือ enable เป็น CTS root

### 6.2 ตัวอย่าง SDC สำหรับ baseline

ตัวอย่างต่อไปนี้สมมติ top มี `clk`, `en`, `q[7:0]` เท่านั้นในส่วน I/O ที่นำมา constrain ใช้หน่วย ns/pF **เมื่อยืนยัน units ของ flow แล้ว** ปรับชื่อและ budget ให้ตรง design จริง หากมี reset/ports อื่นต้องกำหนด contract แยก ไม่ปล่อยหลุด coverage

```tcl
# Illustrative SDC: verify support and units in the installed TDI release.
create_clock -name core_clk -period 10.000 \
    -waveform {0.000 5.000} [get_ports clk]

set_clock_uncertainty -setup 0.200 [get_clocks core_clk]
set_clock_uncertainty -hold  0.100 [get_clocks core_clk]

# External synchronous environment: example values, not PDK defaults.
set_input_delay  -clock core_clk -max 2.000 [get_ports en]
set_input_delay  -clock core_clk -min 0.200 [get_ports en]
set_output_delay -clock core_clk -max 2.000 [get_ports {q[*]}]
set_output_delay -clock core_clk -min 0.200 [get_ports {q[*]}]
set_load 0.020 [get_ports {q[*]}]
```

`set_output_delay -min` ต้องมาจาก external hold requirement และ board/interface timing; บาง interface ต้องเป็นค่าลบ อย่าคัดลอกค่าบวกในตัวอย่างเป็นกฎทั่วไป การตั้ง uncertainty ก็ต้องมาจาก clock budget ไม่ใช่ใช้ค่าใน Lab เป็น sign-off specification

### 6.3 รายการตรวจที่ต้องตอบจากรายงาน

1. มี `core_clk` จริง period 10 ns และ waveform rising 0/falling 5 ns หรือไม่
2. `get_ports clk` และ collection ของ data ports match object ที่ต้องการจริงหรือไม่ ตรวจด้วยวิธีรายงาน collection ของ TDI รุ่นนั้น
3. Clock definition ถูกสร้างซ้ำ/ทับจาก SDC หลายไฟล์หรือไม่
4. Clock ไปถึง sequential clock pins ทั้งหมดที่ควรอยู่ใน domain นี้หรือไม่
5. จำนวน clock pins ที่ STA เห็นสัมพันธ์กับ sequential instances หรือไม่ โดยคำนึงถึง multi-bit flop, gating หรือ special cells ถ้ามี
6. มี input/output, sequential endpoint หรือ timing arc ที่ยังไม่ถูก constrain หรือถูก disable หรือไม่
7. มี false path หรือ multicycle ที่กว้างจนซ่อน path หรือไม่
8. มี `dont_touch`/ideal-network settings บน clock ที่ขัดขวาง CTS หรือไม่ อย่าลบทั้งหมดโดยไม่อ่านเหตุผลของ reference flow

อย่าใช้เพียงรายงาน WNS เป็นหลักฐานว่า constraint ครบ หากไม่มี clock หรือไม่มี timed paths ค่า WNS อาจว่างหรือดูดีโดยที่ไม่ได้ตรวจสิ่งที่ต้องการ

### 6.4 Reset และ generated clocks

สำหรับ asynchronous reset ให้ตรวจ recovery/removal ตาม flow และแผน reset release หากมี reset synchronizer ให้คงสถาปัตยกรรมและ constraints ที่ได้รับการทบทวนแล้ว ห้าม false-path reset ทั้งระบบเพื่อทำให้รายงานสะอาดโดยไม่มีเหตุผล

หากพบ divider output ที่ใช้ clock sequential logic ให้หยุด baseline และจัดทำ generated-clock definition ตาม source, divide ratio และ waveform ที่ถูกต้อง การใช้ `create_clock` ใหม่ที่ divider output โดยละเลยความสัมพันธ์อาจเปลี่ยน timing interpretation เช่นเดียวกับ mux/gated clocks ที่ต้องมี mode/gating constraints เพิ่ม

**หลักฐานขั้นนี้:** clock report, clock coverage report, constraint warnings และรายการ exceptions พร้อมเหตุผล

## 7. ขั้นที่ 3 — เก็บ pre-CTS timing

1. เลือก setup และ hold analysis views ที่ reference flow รองรับ บันทึก PVT และ RC assumption อย่าเหมารวมว่า setup ต้องมี worst corner เดียวเสมอไป
2. อัปเดต timing ตาม placement-based interconnect model
3. รายงาน setup/max และ hold/min แยกกัน เก็บ WNS, TNS และจำนวน violating endpoints
4. เก็บ full clock path ของตัวอย่าง register-to-register อย่างน้อยหนึ่งเส้นต่อชนิด check
5. บันทึกว่า clock เป็น ideal หรือมี modeled network latency เท่าไร และแยก source latency ออกจาก network latency
6. เก็บ max transition/capacitance/fanout violations ตาม checks ที่รุ่นนั้นมี

ถ้า counter ขนาดเล็กไม่มี timing violation ให้ใช้เป็นผลที่ถูกต้อง ไม่ต้องทำให้ fail เพื่อให้ Lab ดูสมบูรณ์ Counter เพียงไม่กี่ flops อาจทำให้ CTS เพิ่มเซลล์น้อยมากหรือไม่จำเป็นต้องเพิ่ม ขึ้นกับ load และข้อกำหนด หากต้องการเห็น topology ให้ใช้ register bank/pipeline ที่มี outputs ถูกใช้งานและไม่ถูก optimize ทิ้งเป็นการทดลองแยก

## 8. ขั้นที่ 4 — ตั้งค่า CTS

ใน GUI เปิด task/configuration ที่รับผิดชอบ clock-tree synthesis ตาม reference flow แล้วตรวจรายละเอียดต่อไปนี้ก่อนกด Run

| การตั้งค่า | วิธีเลือก/ตรวจ | ผลเมื่อผิด |
|---|---|---|
| Root | clock port/pin ที่ CTS อ้างอิงจริง | tree เริ่มผิดจุดหรือไม่ครอบคลุม sinks |
| Sink set | sequential clock pins ที่อยู่ใน domain | clock ขาดบางส่วนหรือรวมวงจรที่ไม่ตั้งใจ |
| Buffer/inverter list | cells ที่ flow/PDK อนุญาตและมีทุก view | unresolved cells, slew ผิด หรือ physical import ล้มเหลว |
| Polarity | inverter stages ต้องคง edge relationship | functional clock polarity ผิด |
| Transition/capacitance | ตาม Liberty และ implementation rules | clock electrical violations |
| Skew/latency goals | ตาม project budget และความเป็นไปได้ | over-buffering หรือ timing ไม่บรรลุ |
| Routing layers | ตาม tech, PG occupancy และ reference flow | congestion/via เพิ่มหรือใช้ layer ไม่อนุญาต |
| Spacing/NDR | ใช้เมื่อ reference flow รองรับและมีเหตุผล | กิน routing resource โดยไม่จำเป็น |
| Obstructions | macro/blockages และ fixed cells | tree อ้อมหรือวาง buffer ไม่ได้ |
| Optimization | ตรวจว่ารวม legalization/hold repair หรือไม่ | อ่านผล CTS ปนกับ repair โดยไม่รู้ตัว |

เริ่มจาก reference defaults ที่ตรวจสอบแล้ว อย่าตั้ง target skew เป็นศูนย์ ค่าที่เข้มขึ้นอาจเพิ่ม clock area, wirelength, power และ congestion โดยไม่ช่วย critical paths ทุกเส้น

แยก **optimization target** ออกจาก **acceptance limit** เป้าหมายของ CTS ไม่ใช่หลักฐานว่าผลรันทำได้ตามนั้น ค่า skew/latency/transition ที่ใช้ต้องระบุ units และ view

## 9. ขั้นที่ 5 — รัน CTS และตรวจ log

1. บันทึก settings และ checkpoint ก่อนเริ่ม
2. รัน CTS task ของ TDI รุ่นติดตั้ง
3. ตรวจ log ว่ารับรู้ clock root และ sinks ที่คาดไว้
4. ตรวจจำนวน added buffers/inverters, tree levels และ messages เรื่อง unbalanced/ignored/excluded sinks
5. ตรวจ missing cell, library mismatch, placement failure และ routing resource warnings
6. ตรวจว่า flow ทำ clock routing, parasitic estimation, optimization และ legalization ขั้นใดแล้ว
7. บันทึก checkpoint `post_cts_raw` ก่อน repair เพิ่ม หาก reference flow สามารถแยกขั้นได้
8. ทำ legalization/PG association และ repair ตาม reference flow แล้วบันทึก `post_cts`

โครงลำดับเชิงแนวคิดต่อไปนี้เป็น **pseudocode ไม่ใช่ Tcl ของ TDI**

```text
load placed checkpoint
validate clocks, sinks, libraries and constraints
configure approved CTS cells and physical targets
build clock trees using the installed flow
legalize and perform supported post-CTS optimization
connect/check supplies for inserted cells
update parasitics using the current implementation stage
activate or verify propagated clock analysis
update timing and write reports
save post-CTS checkpoint
```

หากรันซ้ำ ให้ย้อนโหลด `pre_cts` ก่อนเสมอในการเปรียบเทียบ options การรัน CTS ต่อบน tree เดิมอาจเป็น incremental optimization และไม่ใช่การทดลองภายใต้ baseline เดียวกัน

## 10. ขั้นที่ 6 — ตรวจ topology, legality และ clock electrical quality

เปิด clock-tree visualization หรือ highlight nets จาก root ถึง sink ที่เลือกอย่างน้อย 3 ตำแหน่ง: ใกล้ root, ไกล root และอยู่บริเวณ placement หนาแน่น ตรวจ root→trunk→branch→sink ในกรณีที่ design มีหลายระดับ

สิ่งที่ต้องตรวจและเก็บหลักฐาน:

1. ทุก intended sink อยู่ใน tree และไม่มี unexpected clock sinks
2. ไม่มี clock net ขาด/driver หลายตัว/วงวนที่ไม่ตั้งใจ
3. Buffers อยู่บน rows และไม่ทับเซลล์หรือ blockages
4. Clock polarity และ active edge ที่ sinks ตรงตาม design
5. Clock buffer supplies เชื่อมโยงกับ power domain ถูกต้อง โดยแยก logical PG association จาก physical metal connectivity ที่อาจยังต้องตรวจต่อหลัง route
6. Clock transition และ capacitance ผ่านข้อจำกัดของ library/project ตามมุมวิเคราะห์
7. Minimum pulse width และ checks ที่เกี่ยวข้องถูกประเมินเมื่อ flow มีข้อมูลรองรับ; skew ต่ำอย่างเดียวไม่ยืนยัน pulse width ผ่าน
8. Cell area และ local density หลังเพิ่ม CTS/repair cells ยังรองรับ routing ได้

บันทึก latency min/max, skew, worst rise/fall transition, max driver load และ clock cell count พร้อม measurement scope หาก GUI ไม่รองรับ metric บางรายการ ให้ระบุ N/A พร้อมข้อจำกัด ห้ามใส่ศูนย์แทนค่าที่ไม่เคยวัด

## 11. ขั้นที่ 7 — เปิดและพิสูจน์ propagated timing

บาง flow เปิด propagated analysis อัตโนมัติหลัง CTS บาง flow ต้องกำหนดเอง ก่อนเปลี่ยน SDC ให้ตรวจ constraint state และคู่มือรุ่นติดตั้ง

ตัวอย่าง SDC ที่พบใน STA tools ซึ่งรองรับคำสั่งนี้ [2]:

```tcl
# Apply only if supported and required by the installed TDI flow.
set_propagated_clock [get_clocks core_clk]
```

คำสั่งนี้เพียงเลือกวิธีวิเคราะห์ ไม่ได้สร้าง clock tree ไม่ได้ route และไม่ได้ extract RC ให้เอง

ตรวจประเด็นต่อไปนี้หลังเปิด propagated timing:

1. โหลด post-CTS netlist/database จริง ไม่ใช่ checkpoint ก่อน CTS
2. Timing arcs ของ CTS cells และ interconnect model พร้อม ไม่มี annotation/load warnings ที่ข้ามไป
3. อ่าน full launch/capture clock path เห็น root, inserted cells และ delay increments ที่สัมพันธ์กับ tree
4. Clock network delay ระบุ propagated หรือมีหลักฐานเทียบเท่าตามรูปแบบรายงานของเครื่องมือ
5. Source latency ที่เป็น external contract ยังคงถูกต้อง ส่วน pre-CTS estimated network latency ถูกแทน/ละเลยอย่างถูกต้องตาม semantics ของเครื่องมือ ไม่ถูกนับซ้ำกับ tree
6. หากมี ideal-network/ideal-latency override ให้ตรวจว่ากระทบส่วนใดก่อนแก้ ไม่ลบ source latency ที่จำเป็น
7. คง jitter และ residual uncertainty ที่ยังจำเป็น การเปิด propagated clock ไม่ใช่เหตุผลให้ตั้ง uncertainty เป็นศูนย์ หาก pre-CTS uncertainty รวม estimated skew ให้แยก budget และบันทึกการเปลี่ยนอย่างมีเหตุผล
8. อัปเดต timing แล้วเก็บ setup/hold, recovery/removal และ pulse-width reports ที่รองรับ

**เกณฑ์พิสูจน์:** ต้องส่ง path report ที่เห็น delay ของ clock network ของทั้ง launch และ capture ตามโมเดลปัจจุบัน การถ่ายภาพ layout ที่มี buffers หรือการพิมพ์ `set_propagated_clock` สำเร็จอย่างเดียวไม่เพียงพอ

## 12. ขั้นที่ 8 — อ่าน setup/hold ด้วย full clock paths

สำหรับ register-to-register หนึ่งคล็อก rising-to-rising ไม่มี exception และใช้สมการแบบ simplified กำหนด

`skew = capture clock arrival − launch clock arrival`

โดยใช้ reference เดียวกัน จะแสดง setup slack ได้เป็น

```text
Setup slack = Tperiod + skew
              − (Tcq,max + Tdata,max + Tsetup + Usetup)

Hold slack  = Tcq,min + Tdata,min
              − (Thold + Uhold + skew)
```

Positive skew จึงช่วย setup แต่ทำให้ hold ยากขึ้น ในรายงานจริง early/late derates, edge relationship และ common-path pessimism removal อาจเพิ่มรายละเอียด ต้องเทียบกับ arrival/required calculation ของ path นั้น ไม่ยัดค่าจากคนละ view ลงสมการเดียวกัน

### 12.1 ตัวอย่าง setup ที่คำนวณด้วยมือ

ใช้ launch arrival 0.60 ns, capture arrival 0.75 ns จึงมี skew +0.15 ns กำหนด period 10.00 ns, Tcq,max 0.20 ns, Tdata,max 8.90 ns, Tsetup 0.30 ns และ Usetup 0.20 ns

```text
Data arrival = 0.60 + 0.20 + 8.90 = 9.70 ns
Required     = 10.00 + 0.75 − 0.30 − 0.20 = 10.25 ns
Setup slack  = 10.25 − 9.70 = +0.55 ns
```

### 12.2 ตัวอย่าง hold ที่แยกจาก setup view

สมมติ hold view ให้ launch arrival 0.40 ns, capture arrival 0.55 ns จึงมี skew +0.15 ns, Tcq,min 0.08 ns, Tdata,min 0.10 ns, Thold 0.06 ns และ Uhold 0.05 ns

```text
Earliest data arrival = 0.40 + 0.08 + 0.10 = 0.58 ns
Hold required        = 0.55 + 0.06 + 0.05 = 0.66 ns
Hold slack           = 0.58 − 0.66 = −0.08 ns
```

หากเพิ่ม data-path delay ได้ 0.10 ns โดยสมมติอย่างอื่นคงที่ hold slack เป็น +0.02 ns แต่ต้องรันจริงเพื่อตรวจ setup, slew, load และ parasitic changes ใหม่ การเพิ่ม delay cell ไม่ได้ทำให้ max/min delay เพิ่มเท่ากันทุก corner

การเพิ่ม clock period โดยลำพังไม่แก้ same-edge hold ในตัวอย่างนี้ เพราะ hold constraint ไม่ได้รอ clock รอบถัดไป

### 12.3 แบบฝึกอ่านรายงานจริง

เลือก setup path 1 เส้นและ hold path 1 เส้น แล้วกรอก startpoint, endpoint, view, launch/capture edges, source/network latency, Tcq, combinational cell delay, net delay, setup/hold time, uncertainty, derates/CPPR ถ้ามี และ slack ตรวจว่าผลรวมตรงรายงานภายใน rounding tolerance ที่ประกาศ

Counter ที่ใช้ clock enable อาจมี combinational mux/enable arcs ใน data path อย่าตีความ enable เป็น gated clock โดยอัตโนมัติ ต้องดู mapped structure จริง

## 13. ขั้นที่ 9 — เปรียบเทียบก่อนและหลัง CTS

| Metric | Pre-CTS | Post-CTS | หมายเหตุที่ต้องเขียน |
|---|---|---|---|
| Clock model | ideal/modeled | propagated | หลักฐานจาก full path |
| PVT/RC method | กรอก | กรอก | ระบุเมื่อ method เปลี่ยน |
| Intended/covered sinks | กรอก | กรอก | อธิบายจำนวนที่เปลี่ยน |
| Clock cells/area | กรอก | กรอก | แยก CTS และ data repair ถ้ารายงานได้ |
| Total cell area | กรอก | กรอก | ไม่เรียกว่า core area |
| Core area | กรอก | กรอก | มักคงเดิมในการรันเดียว |
| Insertion min/max | estimate/N/A | กรอก | root-to-sink, edge, view |
| Global/path skew | model/N/A | กรอก | อย่านำคนละนิยามมาเทียบ |
| Worst clock slew/load | model/N/A | กรอก | rise/fall, units |
| Setup WNS/TNS/endpoints | กรอก | กรอก | ใช้ views/constraints ที่บันทึก |
| Hold WNS/TNS/endpoints | กรอก | กรอก | แยกจาก setup |
| Legality/clock electrical violations | กรอก | กรอก | รายการและ severity |

อย่าสรุปว่า CTS ทำให้ดีขึ้น/แย่ลงจาก WNS อย่างเดียว Critical path อาจเปลี่ยนเพราะ clock arrival, data repair, placement movement และ RC update หากต้องการเทียบผล clock model โดยเฉพาะ อาจวิเคราะห์ ideal/propagated บนสำเนา **post-CTS database เดียวกัน** โดยใช้ settings อื่นคงที่ ผล ideal นี้เป็น diagnostic experiment ไม่ใช่ผลส่งต่อ implementation

## 14. ขั้นที่ 10 — การทดลองแบบควบคุม

### Experiment A: baseline จาก placement สอง utilization

หาก Lab 6 มี 40%/60% ให้ทำ CTS จากแต่ละ checkpoint โดยคง netlist input, PVT/views, I/O constraints และ CTS policy เท่ากัน บันทึกว่า core dimensions และ placement ต่างกัน จึงเป็นการศึกษา system-level trade-off ไม่ใช่เปลี่ยนตัวแปรทางเรขาคณิตเพียงตัวเดียว

ตั้งสมมติฐานก่อนรัน: block ที่ใหญ่ขึ้นอาจมี clock wirelength เพิ่ม แต่ block แน่นขึ้นอาจจำกัดตำแหน่ง buffer และ routing resources ผลจริงขึ้นกับ geometry และ placement ไม่ใช่กฎว่า utilization ต่ำกว่าจะมี skew ดีกว่าเสมอ

### Experiment B: เปลี่ยน CTS goal หนึ่งรายการ

1. คัดลอก `pre_cts` เดิมเป็น run B
2. เปลี่ยนเฉพาะ target skew หรือ target transition หนึ่งค่าในช่วงที่ library/reference flow อนุญาต
3. คง uncertainty และ external timing contract เดิม
4. รันและเทียบ clock cells/area, latency, skew, slew, setup/hold และ congestion estimate
5. สรุปว่า trade-off คุ้มค่าหรือไม่ อย่าเลือกจาก skew ต่ำที่สุดอย่างเดียว

หาก counter เล็กเกินไปจนไม่เห็นความต่าง ให้รายงานผลนั้นและใช้ extended register-bank design แยก อย่าเพิ่ม buffer ด้วยมือเพื่อสร้างภาพผลลัพธ์

## 15. แนวทางแก้ปัญหา

| อาการ | ตรวจสาเหตุก่อน | แนวแก้ |
|---|---|---|
| ไม่พบ clock/sink | SDC match, optimized flops, checkpoint | แก้ clock source และ coverage |
| CTS ไม่เพิ่ม buffer | sink count/load, existing tree, targets | ตรวจว่าเป็นผลที่เหมาะสมก่อนสรุปว่าล้มเหลว |
| Missing CTS cell view | ชื่อ cell และ library list | ใช้ approved cells ที่มี timing/physical views ครบ |
| วาง buffer ไม่ได้ | density, blockages, legal sites | แก้ placement/floorplan และรันจาก pre-CTS |
| Skew สูง | outlier sinks, obstacles, tree/load | ตรวจ branch และ geometry; ปรับ settings อย่างควบคุม |
| Slew/capacitance fail | fanout, net RC, drive strength | ปรับ tree/driver ตาม flow แล้วตรวจ min/max ใหม่ |
| Clock timing ยัง ideal | analysis state, overrides, DB ที่โหลด | เปิด propagation ตาม flow และตรวจ full clock path |
| Network delay เป็นศูนย์ผิดคาด | ideal state, wire model, cell arcs | ตรวจ timing arcs/RC/units; อย่าเหมารวมว่าศูนย์ทุกกรณีผิด |
| Hold แย่หลัง CTS | positive path skew, short data path | ใช้ supported hold repair และตรวจ setup ซ้ำ |
| Setup แย่หลัง repair | data delay/buffering/RC เพิ่ม | แก้ critical path และ balance trade-off |
| PG warning หลัง CTS | inserted cells supply mapping | เชื่อม domain และตรวจด้วย PG checks ของ stage นั้น |
| Latency สูงแต่ skew ต่ำ | tree ทุก branch ช้าใกล้กัน | ตรวจ slew, I/O timing และ power; skew ต่ำยังไม่พอ |
| รายงานดูผ่านแต่ path น้อย | unconstrained/disabled paths | แก้ coverage และ exceptions ก่อนรับผล |

## 16. เกณฑ์ตรวจรับและการส่งต่อ routing

แยกสองสถานะให้ชัดเจน

**Lab complete:** มีหลักฐานครบและวิเคราะห์ผลได้ แม้มี violation ที่ระบุ owner/next action แล้ว ผู้สอนอาจรับเป็นผลการทดลองได้ แต่ห้ามติดป้ายว่าผ่าน implementation

**พร้อมส่งต่อ routing ตามข้อกำหนดของ flow:**

- Clock source/period/waveform ถูกต้อง และ intended sinks ครบ ไม่มี unexplained coverage gap
- CTS จบโดยไม่มี unresolved fatal/error และไม่มี unexplained excluded sinks
- Placement legal และ supplies ของ inserted cells ถูกต้องตาม checks ที่มีใน stage นี้
- Propagated analysis ถูกพิสูจน์จาก full clock paths และ RC method ถูกบันทึก
- Clock electrical limits และ pulse-width checks ที่จำเป็นผ่าน หรือมี disposition ที่ flow อนุมัติ
- Setup/hold ผ่านเกณฑ์ intermediate-stage ของ project หรือมี timing-closure plan ที่ผู้รับขั้นถัดไปยอมรับอย่างชัดเจน
- Checkpoints, constraints, settings และรายงานสัมพันธ์กับ run เดียวกัน

Post-CTS ผ่านยังไม่ใช่ sign-off เพราะ detailed routing และ extraction อาจเปลี่ยน RC, skew และ timing ต้องตรวจซ้ำหลัง route รวมถึง physical verification ตาม flow

## 17. ผลส่งมอบ

1. `manifest.txt`: top, language, tool build, library/PDK release, views, units และ RC method
2. Pre/post-CTS checkpoints และ constraints ที่ใช้งานจริง
3. CTS settings และ verified commands หรือ GUI procedure
4. Clock definition/coverage และ exceptions report
5. CTS summary, topology image, legality และ clock electrical reports
6. Full setup/hold reports พร้อมการคำนวณมืออย่างละหนึ่ง path
7. ตารางเปรียบเทียบ pre/post และ controlled experiment อย่างน้อยหนึ่งแบบ
8. บทสรุป: ผ่านอะไร ยังไม่ผ่านอะไร สาเหตุที่มีหลักฐาน และงานที่ต้องทำก่อน/หลัง routing

ภาพสำหรับคู่มือต้องเป็นผลรันจริง ระบุ run/view และ annotate root/sinks หรือ critical path ไม่ใช้ภาพประกอบแทนหลักฐานเชิงตัวเลข

## 18. คำถามท้าย Lab พร้อมแนวคำตอบ

1. **สร้าง tree แล้วแต่ยังใช้ ideal clock ได้หรือไม่?** ได้ ขึ้นกับ analysis state จึงต้องตรวจ full clock path
2. **Skew ต่ำยืนยัน timing ผ่านหรือไม่?** ไม่ ต้องดู data delay, uncertainty, electrical checks และ setup/hold ของแต่ละ path
3. **Positive skew ช่วยอะไร?** ช่วย setup และลด hold slack ภายใต้นิยาม capture−launch ที่ใช้ในบทนี้
4. **ทำไมเพิ่ม period ไม่แก้ hold ตัวอย่างนี้?** เพราะเป็น same-edge minimum-delay check
5. **Propagated clock หมายถึง post-route extraction หรือไม่?** ไม่ ต้องระบุ interconnect model แยก
6. **เปิด propagated แล้วลบ uncertainty ทั้งหมดได้หรือไม่?** ไม่ ยังมี jitter/residual margin ตาม clock budget
7. **จำนวน sinks ต้องเท่าจำนวน RTL registers เสมอหรือไม่?** ไม่ optimization และ mapping อาจเปลี่ยน structure ต้องตรวจ mapped clock pins
8. **Clock enable ควรเป็น CTS root หรือไม่?** ไม่ ใน baseline เป็น synchronous control ของ data path
9. **เหตุใดต้องตรวจ PG หลัง CTS?** เพราะมี inserted cells ใหม่ที่ต้องได้รับ supplies ถูก domain
10. **เหตุใดทดลอง CTS options ต้องย้อน pre-CTS?** เพื่อไม่ให้ผล incremental tree/repair เดิมปนกับ baseline

## 19. เอกสารอ้างอิงและขอบเขตหลักฐาน

[1] Siemens, Digital Implementation — ข้อมูลผลิตภัณฑ์และความสามารถ CTS; ไม่ใช้เป็นหลักฐานชื่อเมนูหรือ Tcl API เฉพาะ release: https://www.siemens.com/en-us/products/ic/ic-custom/ams/digital-implementer/

[2] OpenSTA, official source repository — เอกสารและ implementation สำหรับ ideal/propagated clock, latency และ timing checks ใช้อ้างอิงแนวคิด/SDC ตัวอย่าง ไม่ใช่ TDI command reference: https://github.com/The-OpenROAD-Project/OpenSTA และ https://github.com/The-OpenROAD-Project/OpenSTA/blob/master/search/Search.tcl

[3] TDI User Guide/Command Reference, reference flow และ PDK/library documentation ของรุ่นที่ติดตั้ง — ผู้สอนต้องบันทึก release และหัวข้อที่ใช้จริงสำหรับ CTS options, propagation, reporting, allowed cells และ electrical limits ก่อนนำ Lab ไปใช้

เอกสารนี้เป็นคู่มือขั้นตอนและแบบบันทึก ยังไม่ได้รัน TDI หรือยืนยันผลกับ PDK เฉพาะของห้องปฏิบัติการ ตัวเลขในตัวอย่างคำนวณและ SDC เป็นค่าฝึก ไม่ใช่ผลวัดหรือข้อกำหนด sign-off
