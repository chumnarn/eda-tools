# Module 9 — Physical verification และ simulation หลัง synthesis

## 9.1 เป้าหมายและขอบเขต

บทนี้อธิบายวิธีตรวจว่า geometry ของ layout สร้างได้ตามกฎ เทียบ connectivity กับวงจรอ้างอิงได้ ทำงานตามเวลา และจำลอง netlist ได้อย่างสอดคล้องกัน เหมาะกับหลักสูตร Tanner Digital ASIC Design Implementation โดยใช้ชื่อเมนูและคำสั่งจริงตามรุ่นเครื่องมือที่ติดตั้ง สิทธิ์ใช้งาน และ PDK ของห้องปฏิบัติการ

เมื่อจบบท ผู้เรียนต้องสามารถแยกวัตถุประสงค์ของ DRC/LVS/STA/GLS สืบหาสาเหตุ shorts/opens จัดการ power/ground naming เลือก cell models ให้ตรงกับ netlist และประเมิน SDF annotation coverage ได้ พร้อมจัดทำหลักฐานรับมอบที่ตรวจย้อนกลับถึง layout, netlist, constraints และ rule decks ชุดเดียวกัน

การผ่านบททดลองด้วยกฎที่สร้างขึ้นเพื่อการศึกษาไม่ใช่หลักฐาน sign-off ของโรงงาน การส่งงานจริงต้องใช้ deck, options, tool version และ waiver ที่ผู้รับงานหรือโรงงานยอมรับ

## 9.2 การตรวจสี่ประเภทตอบคำถามต่างกันอย่างไร

| วิธีตรวจ | คำถามหลัก | อินพุตสำคัญ | สิ่งที่ผลผ่านยังไม่ยืนยัน |
|---|---|---|---|
| DRC — Design Rule Checking | รูปร่างและความสัมพันธ์ของชั้นวัสดุตรงตามกฎหรือไม่ | GDS/OASIS, layer mapping, DRC deck, process options | วงจรต่อถูกฟังก์ชันหรือทำงานทันเวลา |
| LVS — Layout Versus Schematic | วงจรที่สกัดจาก layout เทียบได้กับ reference หรือไม่ | Layout, extraction/LVS deck, reference netlist, cell definitions | Reference ถูก specification หรือ timing ผ่าน |
| STA — Static Timing Analysis | เส้นทางที่อยู่ในขอบเขต constraints ผ่าน timing checks หรือไม่ | Netlist, Liberty, SDC, parasitics, corners/modes | Geometry ถูกกฎ หรือ test sequence ทำงานถูก |
| GLS — Gate-Level Simulation | Netlist ตอบสนองต่อ stimulus และ models ที่ใช้ถูกต้องหรือไม่ | Gate netlist, cell/macro models, TB, optional SDF | ทุกเส้นทางและทุก input sequence ถูกตรวจครบ |

คำว่า LVS “schematic” หมายถึงวงจรอ้างอิง ซึ่งอาจมาจาก schematic, CDL/SPICE หรือ netlist ที่แปลงจาก gate-level Verilog ตาม flow ส่วนการพิสูจน์ว่า RTL กับ netlist หลัง synthesis เทียบเท่ากันควรใช้ logic equivalence checking เมื่อมีเครื่องมือ ไม่ควรอ้างว่า LVS หรือ GLS จำนวนจำกัดทดแทนได้

### ตัวอย่างสถานการณ์

- DRC ผ่าน แต่มีสายเชื่อมผิดระหว่างสอง net ที่ geometry ถูกกฎ: LVS อาจพบ short
- LVS ผ่าน แต่ critical path ช้าเกิน period: STA ไม่ผ่าน
- Functional GLS ผ่าน แต่ hold violation เกิดหลัง CTS/route: ต้องตรวจ STA และอาจเห็นผลใน timed GLS
- STA ผ่าน แต่ reset sequence ทำให้สถานะเริ่มต้นผิด: GLS ที่มี self-checking reset test ช่วยเปิดเผยได้
- DRC/LVS/STA/GLS ผ่าน แต่ยังไม่มี IR-drop/EM หรือ ERC ที่โครงการกำหนด: ยังไม่ครบเกณฑ์รับมอบ

## 9.3 จัดชุดอินพุตให้ตรงกันก่อนเริ่มตรวจ

ผล verification มีความหมายเมื่อทราบว่าใช้ตรวจ design revision ใด ควรตรึงชุดข้อมูลอย่างน้อยดังนี้

| หมวด | รายการที่ต้องระบุ |
|---|---|
| Design | Top module/cell, revision, hierarchical configuration |
| Layout | GDS/OASIS, stream-out layer map, DBU/units, macro layout views |
| Netlists | Post-synthesis และ post-route แยกชื่อชัดเจน; reference สำหรับ LVS ระบุแหล่งที่มา |
| Technology | PDK revision, metal stack, device/voltage options, standard-cell/IO/SRAM revisions |
| Verification | DRC/LVS/ERC/antenna/density decks และ revision, run options, include files |
| Timing | SDC, Liberty corners, extracted parasitics, analysis modes, SDF generation options |
| Simulation | Simulator/version, compile options, cell models, macro models, TB, seeds |

ต้องบันทึก checksum ของไฟล์สำคัญและ dependencies ของ deck ด้วย การบันทึก checksum เฉพาะไฟล์ wrapper ไม่เพียงพอถ้าไฟล์ include ภายในเปลี่ยนได้

หลัง physical optimization เครื่องมืออาจเพิ่ม clock buffers, hold buffers, tie cells หรือเปลี่ยนขนาด gate ดังนั้น post-route GLS ต้องใช้ netlist ที่สัมพันธ์กับ post-route SDF ส่วน LVS ต้องใช้ reference ที่ปรับให้ตรงกับ physical implementation ตามวิธีที่ flow อนุมัติ รวมถึงนโยบายการจัดการ physical-only cells

## 9.4 DRC: ตรวจ geometry อย่างมีบริบท

### 9.4.1 กลุ่มกฎพื้นฐาน

1. **Width:** ความกว้างต่ำสุดของ conductor หรือรูปทรงบน layer ที่กำหนด
2. **Spacing:** ระยะห่างระหว่างรูปทรง อาจขึ้นกับความกว้าง ความยาวขนาน หรือความสัมพันธ์ทางไฟฟ้า
3. **Enclosure:** โลหะหรือ diffusion ต้องหุ้ม contact/via ตามระยะที่กฎกำหนด
4. **Extension/overlap:** ส่วนยื่นและการซ้อนทับของชั้นวัสดุ
5. **Minimum area/notch/end-of-line:** พื้นที่ต่ำสุด ร่องแคบ และข้อกำหนดบริเวณปลายสาย
6. **Density/fill:** สัดส่วนพื้นที่วัสดุในหน้าต่างตรวจ ต้องพิจารณาหลังใส่ fill ตาม flow
7. **Well/tap/implant และ boundary rules:** ความสัมพันธ์กับ well, substrate, tap, cell edge และบริเวณต่อ macro

ห้ามนำตัวเลขกฎจากคนละ process มาใช้ ตัวอย่าง width/spacing ในเอกสารสอนต้องติดป้ายว่าเป็นค่าจำลองจนกว่าจะอ้างอิง deck ของ PDK เป้าหมาย

### 9.4.2 ขั้นตอนอ่าน violation

เริ่มจาก rule ID และข้อความเต็ม เปิด marker ใน layout editor แล้วตรวจ layer จริงพร้อมบริบทใกล้เคียง วัด geometry ตามนิยามของกฎ แยกว่าเป็น route, macro boundary, power grid หรือ cell abutment จากนั้นแก้ที่ต้นเหตุและ rerun กฎที่เกี่ยวข้องเพื่อ debug ก่อนรันชุดตรวจเต็ม

ตัวอย่าง via enclosure: การมองเห็นโลหะสองชั้นสัมผัส via และ connectivity checker ผ่าน ยังไม่ยืนยัน enclosure ถูกกฎ ต้องวัดขอบโลหะเทียบกับ cut ทุกด้านตาม deck การเพิ่ม via array อาจทำให้กฎ spacing หรือ enclosure เปลี่ยนด้วย

### 9.4.3 ผล “0 violations” ที่ต้องตรวจเพิ่ม

- งานจบตามปกติหรือหยุดก่อนจบ; มี fatal error หรือ skipped checks หรือไม่
- เลือก top cell, layer map, metal stack และ process options ถูกหรือไม่
- มี layout cell ที่อ่านไม่เข้า หรือ black-box/exclusion ที่ครอบคลุมพื้นที่จริงหรือไม่
- เปิดกฎครบตามขอบเขต sign-off หรือเป็นเพียง subset สำหรับ debug
- รายงานนับก่อนหรือหลัง waiver/filter และมีเอกสารอนุมัติ waiver หรือไม่

Calibre nmDRC เป็นตัวอย่างเครื่องมือสำหรับ sign-off DRC ส่วนการตรวจ subset ระหว่างพัฒนาใช้เพื่อลดรอบ debug และต้องแยกหลักฐานออกจาก final run [R1, R2]

## 9.5 LVS: จากรูปทรงสู่ connectivity และการเปรียบเทียบ

LVS ประกอบด้วยการสกัดวงจรจาก layout แล้วเทียบกับ reference ภายใต้นโยบายของ deck เช่น device recognition, equivalent-device reduction, pin equivalence และ hierarchical matching

ระดับมาตรฐานเซลล์อาจใช้ hierarchical comparison ที่รับรอง cell library แล้ว ส่วน transistor-level comparison ตรวจ devices และการต่อภายในละเอียดขึ้น ความลึกของการตรวจต้องระบุในรายงาน ไม่ควรเขียนเพียง “LVS PASS” โดยไม่ระบุ black boxes และขอบเขต

### 9.5.1 Shorts และ opens

**Short** คือ connectivity ใน layout รวม net ที่ควรแยกกัน อาจเกิดจาก routing bridge, via ผิดตำแหน่ง, label/global-net mapping หรือ supply mapping ผิด

**Open** คือ connectivity ที่ควรต่อกันกลับแยกเป็นหลายส่วน เช่น missing via, pin ไม่แตะ route, macro power pin ไม่เชื่อมจริง หรือรูปทรงบน layer/datatype ที่ extractor ไม่ถือเป็น conductor

การที่สองรูปทรงดูติดกันในหน้าจอไม่ใช่หลักฐานว่าต่อไฟฟ้า และชื่อ label ตรงกันไม่ใช่หลักฐานว่ามีโลหะเชื่อมถึงกัน การตีความ global labels และ virtual connections ต้องอ่านจาก deck และ run options

### 9.5.2 ลำดับ debug ที่ลดความสับสน

1. ตรวจ top name, source netlist parsing และ missing definitions ก่อน
2. ตรวจจำนวน ports และ power/ground correspondence
3. แก้ supply shorts หรือ opens ที่กระทบทั้ง design ก่อน mismatch รายเซลล์
4. แยก device/cell count mismatch ออกจาก net connectivity mismatch
5. ใช้ cross-probe จาก mismatch ไปยัง layout และ reference
6. ตรวจจุดที่ net แตกหรือรวม โดยไล่จาก pin ที่รู้ตำแหน่งและหน้าที่
7. Rerun และเปรียบเทียบผลบน revision ใหม่ เก็บผลก่อนแก้ไว้เพื่อการสอน

Short หนึ่งจุดอาจสร้าง mismatch จำนวนมาก จึงไม่ควรตีความจำนวน mismatch เป็นจำนวนสาเหตุอิสระ

### 9.5.3 จุดเสี่ยงเฉพาะ macro

SRAM/IO ต้องมีชื่อ cell, pin names, pin order ของ SPICE subcircuit, bus indexing และ supply pins ตรงกัน ห้ามเดา positional pin order จาก Verilog หรือ LEF ต้องตรวจ definition ที่ใช้จริง รวมถึง well/bulk pins หาก deck ต้องใช้

Black-box LVS อาจตรวจเฉพาะ boundary connectivity โดยไม่ตรวจวงจรภายใน macro ต้องระบุว่า IP ภายในตรวจด้วยหลักฐานใด ห้ามสรุปว่า transistor-level LVS ทั้งชิปผ่านเมื่อส่วนหนึ่งถูกละไว้

## 9.6 Power/ground naming และ global nets

ชื่อที่พบได้ ได้แก่ `VDD`, `VSS`, `VPWR`, `VGND`, `VDDIO`, `VSSIO`, `IOVDD`, `IOVSS` รวมถึงรูปแบบ global เช่น `VDD!` ชื่อเหล่านี้ไม่เท่ากันโดยอัตโนมัติ และการใช้ตัวพิมพ์ใหญ่เล็กต้องยึด parser และ mapping ของ flow

| Physical pin | Net ของโครงการตัวอย่าง | ความหมาย |
|---|---|---|
| Core cell `VPWR` | `VDD` | Core positive supply |
| Core cell `VGND` | `VSS` | Core ground |
| IO cell `iovdd` | `IOVDD` | IO supply domain |
| IO cell `iovss` | `IOVSS` | IO ground domain |

ตารางนี้เป็นตัวอย่างเชิงแนวคิด ต้องแทนด้วย pin จริงของ library ห้ามรวม IO/core supplies เพียงเพราะต้องการให้ LVS ผ่าน หากโครงการอนุญาตให้ ground สองโดเมนต่อกัน ต้องระบุจุดและวิธีเชื่อมตามสถาปัตยกรรมและกฎที่ใช้

### หลักปฏิบัติ

- สร้าง supply mapping ที่ใช้ร่วมกันระหว่าง RTL wrapper, physical flow, LVS และ simulation
- แยก “logical global connection” ออกจากการมีโลหะและ via ต่อจริง
- ตรวจ power pins ทุกประเภท: core, IO, SRAM, well/bulk, analog และ always-on ตามที่มี
- อย่าเปลี่ยนชื่อ net ด้วย text replacement โดยไม่ดูขอบเขต hierarchy และ domain
- สำหรับ global-net declarations ให้ระบุเครื่องมือ/ภาษาที่ใช้ เพราะ SPICE `.GLOBAL`, special-net objects และ HDL supply nets มีความหมายต่างกัน

ตัวอย่างสำหรับ **Verilog cell models ที่เปิดเผย power ports แบบ explicit**:

```systemverilog
module tb_supply_example;
  supply1 VDD;
  supply0 VSS;
  // เชื่อมเฉพาะเมื่อ netlist ของโครงการประกาศ ports เหล่านี้จริง
  // chip_top dut (.VDD(VDD), .VSS(VSS), ...);
endmodule
```

`supply1/supply0` เป็น digital logic supplies ไม่ได้จำลองแรงดันตกหรือ power ramp ทางแอนะล็อก หาก models ใช้ conditional power pins ต้องกำหนด macro ตามคู่มือของ library อย่างสอดคล้องกันทั้ง compile และ netlist

## 9.7 เชื่อมโยงกับ STA หลัง route

STA ใช้ delay models และ constraints เพื่อตรวจเส้นทางโดยไม่ต้องกระตุ้นทุก input sequence หลัง route ต้องใช้ parasitics ที่สัมพันธ์กับ layout และตรวจ propagated clock, setup/hold, recovery/removal และ electrical constraints ตามขอบเขตโครงการ

ก่อนอ่าน WNS/TNS ต้องตรวจ clocks, generated clocks, unconstrained endpoints, timing exceptions, disabled arcs และ analysis coverage ผล slack บวกไม่มีความหมายสำหรับเส้นทางที่ไม่ได้ถูกตรวจ

ต้องแยก Liberty PVT corner ออกจาก RC corner และระบุ combination ที่ใช้ ไม่ควรสรุปว่า setup ตรวจเฉพาะ slow และ hold ตรวจเฉพาะ fast เสมอ เพราะผลขึ้นกับ clock/data relationship, derating, อุณหภูมิและ RC รวมถึง methodology ของโครงการ

Timed GLS ใช้ delay ที่ถูก back-annotate กับ stimulus ที่เลือก จึงช่วยตรวจ reset/initialization, timing-check response และปฏิสัมพันธ์เชิงเวลา แต่ไม่ทดแทน STA sign-off หรือ CDC verification

## 9.8 GLS หลัง synthesis และหลัง implementation

### Functional GLS

ใช้ mapped netlist และ functional cell models เพื่อทดสอบ behavior โดยไม่มี extracted SDF เหมาะสำหรับตรวจ missing models, port mapping, reset, initialization และความเข้ากันได้ของ TB การไม่มี SDF ไม่ได้แปลว่า models ทุกตัวไม่มี delay เสมอ ต้องอ่าน library และ simulation options

### Timed GLS

เพิ่ม SDF และ timing-capable cell models เพื่อจำลอง delays/timing checks ที่รองรับ เหมาะสำหรับ targeted tests เช่น reset release, clock gating, scan mode transition และ interface timing ที่ต้องสังเกตเชิงเวลา

| ระยะ | Netlist | Delay source | ข้อควรระวัง |
|---|---|---|---|
| หลัง synthesis | Technology-mapped | ไม่มี SDF หรือ synthesis estimate | ยังไม่มี clock tree/routed interconnect จริง |
| หลัง CTS | รวม clock tree และ repair | Estimate ตาม stage | Routing/parasitics อาจยังไม่ final |
| หลัง route | Final implementation revision | SDF จาก timing/extraction flow | ต้องตรงกับ hierarchy และ models |

### 9.8.1 Missing cell models

หาก simulator พบ unresolved module/entity ให้ตรวจชื่อ cell ใน netlist เทียบกับชุด simulation models ไม่ใช่นำ Liberty หรือ LEF มา compile แทน Model ของ SRAM ต้องมี behavior สำหรับ read/write และ latency ตรงกับ macro; black-box declaration ที่พอให้ synthesis ผ่านไม่ได้ให้ behavior สำหรับ simulation

ตรวจ UDP definitions, include paths, power-pin defines, model revisions และ duplicate module definitions ด้วย หลีกเลี่ยงการสร้าง stub ที่ drive output เป็นศูนย์เพื่อทำให้ simulation ผ่าน เพราะจะปกปิดการทำงานที่ไม่ได้ตรวจ

### 9.8.2 X propagation และ timing violations

X อาจเกิดจาก register ไม่ reset, undriven net, memory ไม่ initialize, supply ไม่ต่อ, multiple drivers หรือ timing notifier การแก้ต้องเริ่มจาก X แรกและสาเหตุ ไม่ใช่ force ทุก register เป็นศูนย์

การเห็น X จาก timing check เป็นผลของ digital model ไม่ใช่การจำลอง metastability ทางแอนะล็อกโดยตรง การปิด timing checks หรือ notifiers อาจใช้แยกสาเหตุระหว่าง debug แต่ต้องแยกผลนั้นจากผลตรวจ timed GLS ที่เปิดการตรวจตามเกณฑ์

## 9.9 SDF annotation: โหลดไฟล์ได้ยังไม่เท่ากับครอบคลุม

SDF อาจบรรจุ cell path delays, interconnect delays และ timing checks ขึ้นกับ exporter และ options ต้องตรวจ `TIMESCALE`, instance hierarchy, `CELLTYPE`, pin names, timing arcs และหน่วย/precision ของ simulator

### ตัวอย่าง annotation ภายใน SystemVerilog TB

```systemverilog
`ifdef TIMED_GLS
initial begin
  $sdf_annotate("build/chip_top.sdf", dut);
end
`endif
```

ตัวอย่างนี้แสดง target instance เท่านั้น การเลือก MIN/TYP/MAX, log และ annotation options ต้องกำหนดตาม simulator/version และ SDF ที่ส่งออก หาก annotate ผ่าน command line อยู่แล้ว ห้ามเปิด block นี้ซ้ำ

สำหรับ VHDL testbench มักใช้ simulator-level SDF annotation ไปยัง instance ของ DUT; VHDL ไม่มี `$sdf_annotate` แบบ SystemVerilog หาก TB เป็น VHDL แต่ mapped netlist เป็น Verilog ต้องมี mixed-language capability และ binding ที่รองรับ

### ตัวอย่างแนวทาง Questa/ModelSim

```tcl
# Template: ปรับ paths, model options และ license ตามระบบจริง
vlib work
vlog -sv models/stdcells.v models/macros.v build/chip_top.v tb_gls.sv
# Functional GLS
vsim -c work.tb_gls -do "run -all; quit -f"
# Timed GLS: เลือกใช้ command-line annotation โดยไม่เปิด TIMED_GLS ใน TB
vsim -c -sdfmax /tb_gls/dut=build/chip_top.sdf work.tb_gls \
  -do "run -all; quit -f"
```

ไฟล์ `models/stdcells.v` และ `models/macros.v` เป็น placeholders ของชุด models ที่ได้รับอนุญาต ตัวเลือกและรูปแบบ path ต้องตรวจด้วย help/manual ของรุ่นที่ติดตั้ง ตัวอย่างนี้ไม่ได้ยืนยันว่าได้รันทดสอบบน installation ของผู้เรียน

### 9.9.1 วิธีประเมิน coverage

แยกรายงานอย่างน้อยสี่กลุ่ม: instances, cell/path arcs, interconnect และ timing checks จำนวนรวมของกลุ่มเหล่านี้ใช้แทนกันไม่ได้

ถ้ามี eligible delay entries 20,000 รายการ และ annotate สำเร็จ 19,600 รายการ จะได้ coverage เชิงจำนวนนั้น 98% แต่ยังสรุปผ่านไม่ได้จนทราบว่า 400 รายการที่หายไปอยู่ที่ใด หากเป็น clock tree หรือ critical sequential cells ย่อมมีนัยสำคัญมาก

ต้องบันทึก numerator/denominator, excluded items และนิยามที่ simulator ใช้ ไม่ใช้จำนวน instances ที่โหลดสำเร็จแทน arc coverage และไม่ตีความว่า 100% ของ SDF หมายถึงครบทุก timing arc ที่ควรมีใน design เพราะ exporter อาจไม่ได้ส่งออกบางรายการตั้งแต่ต้น

### 9.9.2 สาเหตุ coverage ต่ำ

| อาการ | สาเหตุที่ควรตรวจ |
|---|---|
| Instance not found | Annotation root ผิด, flatten/rename, SDF คนละ revision |
| CELLTYPE mismatch | Model/netlist/SDF ใช้ cell revision หรือชื่อไม่ตรงกัน |
| IOPATH ไม่พบ | Functional-only models, specify paths ไม่ตรง หรือถูกปิด |
| Timing check ไม่ match | รูปแบบ setup/hold/recovery/removal หรือเงื่อนไข arcs ต่างกัน |
| Delay เล็กกลายเป็นศูนย์ | Time precision หยาบเกิน หรือ units/options ผิด |
| Annotation เฉพาะ cell delays | Interconnect ไม่ถูกส่งออกหรือไม่ match ตาม flow |

ต้องตรวจ negative timing checks และ simulator support ตาม models ที่ใช้ ห้าม clamp หรือเปลี่ยน options โดยไม่บันทึกผลกระทบ การเลือก MIN/TYP/MAX สำหรับ GLS ก็ไม่ใช่การแทน MMMC/OCV STA ทั้งชุด

## 9.10 ตัวอย่าง stimulus และ self-checking สำหรับ GLS

ใช้ counter 8 บิตเป็น DUT ตามสัญญา interface: rising-edge clock, synchronous active-low reset, enable และ output `q[7:0]` ตัวอย่าง TB ต่อไปนี้ใช้ได้กับ functional GLS และนำไปปรับสำหรับ timed GLS โดยกำหนด observation time จาก delay budget ที่ตรวจแล้ว

### SystemVerilog

```systemverilog
`timescale 1ns/1ps
module tb_gls;
  logic clk = 0, rst_n = 0, en = 0;
  wire [7:0] q;
  logic [7:0] expected = 0;
  chip_top dut (.clk(clk), .rst_n(rst_n), .en(en), .q(q));
  always #5 clk = ~clk;

  task automatic step(input bit reset_n, input bit enable);
    @(negedge clk); // drive ห่างจาก active edge
    rst_n = reset_n;
    en = enable;
    @(posedge clk);
    if (!reset_n) expected = 0;
    else if (enable) expected = expected + 8'd1;
    #2; // ตัวอย่าง budget; ต้องแทนด้วยเวลาที่เหมาะกับ design
    if (q !== expected)
      $fatal(1, "Mismatch: expected=%h actual=%h", expected, q);
  endtask

  initial begin
    step(0, 0); step(0, 1);
    step(1, 0);
    repeat (260) step(1, 1); // รวม overflow 255 -> 0
    repeat (4) step(1, 0);   // hold เมื่อ disable
    step(0, 1); step(1, 1); // reset ระหว่างทำงาน
    $display("PASS: counter GLS");
    $finish;
  end
  initial begin
    #10000;
    $fatal(1, "Timeout");
  end
endmodule
```

### VHDL testbench ที่มีสัญญาเดียวกัน

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_gls_vhdl is end entity;
architecture sim of tb_gls_vhdl is
  signal clk   : std_logic := '0';
  signal rst_n : std_logic := '0';
  signal en    : std_logic := '0';
  signal q     : std_logic_vector(7 downto 0);
  component chip_top is
    port (clk, rst_n, en : in std_logic;
          q : out std_logic_vector(7 downto 0));
  end component;
begin
  clk <= not clk after 5 ns;
  dut : chip_top port map (clk => clk, rst_n => rst_n, en => en, q => q);
  process
    variable expected : unsigned(7 downto 0) := (others => '0');
    procedure step(reset_n, enable : std_logic) is
    begin
      wait until falling_edge(clk);
      rst_n <= reset_n;
      en <= enable;
      wait until rising_edge(clk);
      if reset_n = '0' then
        expected := (others => '0');
      elsif enable = '1' then
        expected := expected + 1;
      end if;
      wait for 2 ns; -- ปรับตาม delay budget เช่นเดียวกับ SV
      assert q = std_logic_vector(expected)
        report "GLS counter mismatch" severity failure;
    end procedure;
  begin
    step('0', '0'); step('0', '1'); step('1', '0');
    for i in 1 to 260 loop step('1', '1'); end loop;
    for i in 1 to 4 loop step('1', '0'); end loop;
    step('0', '1'); step('1', '1');
    report "PASS: counter GLS";
    finish;
    wait;
  end process;
  process
  begin
    wait for 10 us;
    assert false report "Timeout" severity failure;
    finish;
    wait;
  end process;
end architecture;
```

VHDL ตัวอย่างนี้ต้องใช้ VHDL-2008 และ binding ของ component ให้เข้ากับ gate netlist จริง หาก netlist ใช้ escaped identifiers หรือเปลี่ยน port representation ให้สร้าง wrapper ที่ตรวจ mapping แล้ว และรวม wrapper ในหลักฐานทดสอบ

เวลาอ่านค่า 2 ns เป็นค่าตัวอย่างภายใต้ period 10 ns ต้องมากกว่า output settling time ที่เกี่ยวข้อง และอยู่ใน valid observation window การเลื่อนเวลาอ่านเพื่อซ่อน violation ไม่ใช่การแก้ timing สำหรับ asynchronous reset ต้องเพิ่ม tests ของ asynchronous assertion และตรวจ synchronous deassertion/recovery/removal ตามโครงสร้างจริง

ตัวอย่างไม่ได้รวม power ports เพราะต้องปรับตาม netlist ของแต่ละ PDK และไม่ได้จำลองความถูกต้องภายใน clock/reset synchronizer หรือพิสูจน์ metastability

## 9.11 ขั้นตอนปฏิบัติสำหรับห้องทดลอง

### งาน A — ตรวจ baseline

รวบรวม final layout/netlist และ reference ที่ตรง revision รัน DRC/LVS ด้วย deck สำหรับการทดลอง บันทึกจำนวน rules ที่เปิดใช้งาน จำนวน markers และ matched/unmatched circuits จากนั้นรัน functional GLS ด้วย TB ที่ตรวจ reset, enable, overflow และ timeout

### งาน B — ใส่ข้อผิดพลาด geometry

ทำสำเนา design สำหรับทดลอง ลด enclosure ของ via หนึ่งตำแหน่งโดยยังให้รูปทรงสัมผัสกันทางไฟฟ้า ตรวจว่า DRC พบกฎที่คาด และอธิบายว่าเหตุใด LVS อาจยังผ่านได้ ขึ้นกับ extractor และรูปทรงที่แก้

### งาน C — ใส่ short/open

ในสำเนาอีกชุด เพิ่ม bridge ระหว่าง signal nets หรือถอด via หนึ่งตำแหน่ง ตรวจ LVS และ cross-probe ให้พบจุดต้นเหตุ อย่าใช้ power short บน design จริงที่เตรียมส่งมอบ

### งาน D — ทำให้ GLS binding ล้มเหลว

นำ simulation model ของ cell หนึ่งชนิดออกจาก compile list ตรวจว่า simulator หยุดด้วย missing model แล้วคืน model ที่ถูกต้อง ต้องไม่แก้ด้วย constant-output stub

### งาน E — ตรวจ SDF coverage

รัน annotation กับ hierarchy ที่ถูกต้อง เก็บสถิติและ warnings จากนั้นตั้ง annotation root ผิดในสำเนา script เพื่อยืนยันว่ากระบวนการรับผลตรวจจับ coverage ลดลงได้ คืนค่าถูกต้องและ rerun

### งาน F — ยืนยัน TB ตรวจ bug ได้

เปลี่ยน expected behavior หรือ netlist สำเนาให้ counter เพิ่มทีละสอง ตรวจว่า scoreboard ล้มเหลว คืน design เดิมแล้วให้ผลผ่าน แบบฝึกนี้ยืนยันว่าการเห็นข้อความ PASS ไม่ได้เกิดจาก TB ไม่มีการตรวจจริง

## 9.12 ตารางสืบหาสาเหตุ

| อาการ | ตรวจลำดับแรก | หลักฐานที่ควรแนบ |
|---|---|---|
| DRC markers จำนวนมากที่ macro edge | Layer map, macro revision, orientation, spacing/blockage | Rule IDs และภาพ cross-probe |
| LVS supply mismatch ทั้งชิป | Global nets, supply mapping, explicit/implicit power pins | Mapping และ mismatched nets |
| LVS device count ต่างมาก | Missing cell definitions, top ผิด, extraction options | Parse/extraction logs และ count summaries |
| GLS output เป็น X ตั้งแต่เริ่ม | Reset, supplies, model binding, SRAM init | Waveform จาก X แรกและ model diagnostics |
| Functional GLS ผ่านแต่ timed GLS fail | Annotation, timing violations, TB drive/sample window | SDF stats, timing logs, waveform |
| STA ผ่านแต่ timed GLS fail | Constraints coverage, stimulus legality, SDF corner, reset checks | STA coverage และ failing check |
| GLS ผ่านแต่ STA fail | Stimulus ไม่กระตุ้น path ที่ fail | STA path report และ test coverage |

## 9.13 เกณฑ์รับมอบและ sign-off

คำว่า sign-off ต้องอ้างถึงข้อตกลงรับงานที่ชัดเจน ไม่ผูกกับชื่อเครื่องมือเพียงอย่างเดียว ต้องตรวจว่า deck/revision ได้รับการยอมรับสำหรับ process และ option ที่ผลิต พร้อม tool version และ invocation ที่รองรับ

| รายการ | เกณฑ์ที่ต้องแสดง |
|---|---|
| DRC | Run จบครบชุดที่กำหนด ไม่มี unwaived violations; waiver ระบุ rule/location/reason/approver |
| LVS | Comparison ผ่านตามระดับที่กำหนด ไม่มี unmatched circuits/nets ที่ไม่ได้อนุมัติ; เปิดเผย black boxes |
| STA | ครบ modes/corners/checks และ constraint coverage ตามเกณฑ์; ไม่มี violations ที่ยังไม่อนุมัติ |
| Functional GLS | Tests ที่กำหนดผ่าน ไม่มี unresolved models หรือ unexplained X/errors |
| Timed GLS | Tests และ delay selections ที่กำหนดผ่าน พร้อม annotation coverage และ warning disposition |
| Checks เพิ่มเติม | ERC, antenna, density/fill, IR/EM และ reliability checks ตามขอบเขตโครงการ |
| Reproducibility | Layout/netlist/model/deck/SDC/SDF revisions และ checksums ตรวจย้อนกลับได้ |

ไม่กำหนดเกณฑ์ SDF coverage เป็นเปอร์เซ็นต์เดียวโดยขาดบริบท รายการที่ไม่ annotate ต้องมีเหตุผลและผลประเมิน โดยเฉพาะ clock paths และ timing checks ของ sequential cells

การแก้หลังตรวจ final เช่น ECO, buffer insertion, reroute, fill insertion หรือ stream-out change ต้องมี impact analysis และ rerun checks ที่ได้รับผลกระทบ การเปลี่ยน physical layout อาจกระทบ parasitics และ timing แม้ logical function ไม่เปลี่ยน

## 9.14 สิ่งที่ผู้เรียนต้องส่ง

ส่ง verification summary พร้อม input manifest, DRC/LVS full logs และ summaries, STA coverage/violating paths, GLS compile/run logs, SDF annotation statistics, test results และรายการ waivers/exclusions แนบกรณีใส่ bug อย่างน้อยหนึ่งกรณีที่เครื่องมือตรวจพบ พร้อมคำอธิบายสาเหตุและหลักฐานหลังแก้

โครงสร้างรายงานควรตอบได้ว่า “ตรวจอะไร บน revision ใด ด้วยกฎและ models ใด ครอบคลุมเท่าใด เหลือข้อยกเว้นอะไร และใครยอมรับข้อยกเว้นนั้น” โดยไม่ต้องเปิด waveform เพื่อเดาสถานะของงาน

## 9.15 คำถามทบทวน

1. เพราะเหตุใด DRC ผ่านจึงยังมี short ที่ผิดวงจรได้?
2. ถ้า LVS ผ่านทั้งที่ SRAM ถูก black-box ผลนั้นยืนยันอะไรและยังไม่ยืนยันอะไร?
3. การประกาศ global VDD ต่างจากการต่อ power metal จริงอย่างไร?
4. เพราะเหตุใดควรเริ่ม functional GLS ก่อน timed GLS?
5. Cell instance coverage 100% แต่ timing-check coverage ต่ำ เกิดได้อย่างไร?
6. เหตุใด max-delay GLS จึงไม่แทน hold sign-off และ MMMC STA?
7. เมื่อเติม metal fill หลัง extraction ต้องทบทวนผลใดบ้าง?
8. หาก deck สำหรับการสอนให้ผลผ่าน ต้องมีหลักฐานเพิ่มอะไรจึงส่งผลิตได้?

## เอกสารอ้างอิงและแนวทางใช้

- [R1] Siemens, Calibre nmDRC: https://www.siemens.com/en-us/products/ic/calibre-design/physical-verification/design-rule-checking/ — บทบาทของ sign-off DRC
- [R2] Siemens, Speeding up early design rule checking with Calibre nmDRC Recon: https://blogs.sw.siemens.com/calibre/2024/06/05/speeding-up-early-design-rule-checking-with-calibre-nmdrc-recon/ — แยก early selective checks จาก full sign-off
- [R3] Siemens, Streamlining IC design verification with Calibre nmLVS Recon: https://blogs.sw.siemens.com/calibre/2024/01/03/streamliningic-design-verification-with-calibre-nmlvs-recon/ — early LVS/connectivity debugging
- [R4] คู่มือ simulator รุ่นที่ติดตั้งจริง, simulation-model README และ PDK verification manual ที่ได้รับอนุญาต — ใช้เป็นข้ออ้างอิงหลักสำหรับ syntax, SDF options, power-pin defines และ supported models ของระบบนั้น

หมายเหตุ: ตัวอย่างคำสั่งและ TB ในบทนี้เป็น teaching templates ไม่ใช่ผลการรันรับรองบน PDK/Siemens installation ใด ต้อง bind models และตรวจ options ก่อนนำไปใช้จริง
