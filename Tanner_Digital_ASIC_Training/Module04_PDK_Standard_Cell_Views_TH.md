# Module 4 — PDK และ standard-cell views

## 4.1 เป้าหมายและแนวคิดหลัก

เมื่อจบบทนี้ ผู้เรียนต้องอธิบายหน้าที่ของ Liberty, LEF, GDS/OASIS, Verilog และ SPICE/CDL ได้ ตรวจความสัมพันธ์ของชื่อ cell และ pin ข้าม view ได้ และเลือกชุด PVT กับ RC corner ตาม analysis scenario โดยไม่สับสนระหว่างคุณสมบัติของทรานซิสเตอร์กับคุณสมบัติของสายโลหะ

Standard cell หนึ่งตัวมีหลาย view เพราะเครื่องมือแต่ละขั้นต้องการรายละเอียดต่างกัน เช่น synthesis ต้องรู้ว่า cell ทำฟังก์ชันอะไรและมี delay เท่าใด ส่วน placer ต้องรู้ขนาดและตำแหน่งขา ขณะที่ LVS ต้องเปรียบเทียบการเชื่อมต่อของอุปกรณ์จริง การที่ view ใด view หนึ่งอ่านได้สำเร็จจึงยังไม่ยืนยันว่า library ทั้งชุดใช้งานร่วมกันได้

**หลักสำคัญ:** ทุก view ต้องอ้างถึง cell รุ่นเดียวกันและมีความหมายทางไฟฟ้าที่สอดคล้องกัน แต่ไม่จำเป็นต้องมีรายการ cell เท่ากันทั้งหมด เช่น filler อาจมีเฉพาะ physical view และไม่มี timing function

## 4.2 PDK, reference library และ flow configuration

PDK เป็นชุดข้อมูลเชื่อมเทคโนโลยีการผลิตกับเครื่องมือออกแบบ ครอบคลุมกฎ layout, layer mapping, device models, extraction และ verification decks ตามขอบเขตที่ผู้จัดทำส่งมอบ ส่วน standard-cell library เป็นชุดวงจรที่ผ่านการออกแบบ layout และ characterization เพื่อใช้ประกอบ digital design

ควรแยกข้อมูลสามระดับ:

| ระดับ | ตัวอย่าง | หน้าที่ |
|---|---|---|
| Technology data | technology LEF, routing layers, vias, DRC/LVS decks, RC models | กำหนดความหมายและข้อจำกัดของเทคโนโลยี |
| Reference library | standard cells, IO, SRAM; Liberty/LEF/layout/netlists | ให้ building blocks ที่นำไป instantiate หรือ map |
| Flow configuration | corner mapping, cell exclusions, power mapping, layer limits | เลือกและเชื่อมข้อมูลให้เหมาะกับเครื่องมือและโครงการ |

Technology LEF กับ cell LEF ทำหน้าที่ต่างกัน: ตัวแรกอธิบาย routing technology และอาจมี site/via definitions ส่วนตัวหลังอธิบาย abstract ของแต่ละ cell การแบ่งไฟล์จริงขึ้นกับผู้จัดทำ PDK ห้ามสมมติจากนามสกุลเพียงอย่างเดียว

ก่อนเริ่มงานให้บันทึก PDK revision, library release, metal stack, tool version และไฟล์ configuration ที่ใช้ การผสมไฟล์จากคนละ release อาจยังอ่านผ่าน แต่สร้างปัญหา pin geometry หรือ LVS ในช่วงท้าย

## 4.3 ตาราง standard-cell views

| View | ข้อมูลหลัก | ขั้นตอนที่ใช้ | สิ่งที่ไม่ควรอนุมาน |
|---|---|---|---|
| Liberty `.lib` | Boolean/sequential function, timing arcs, constraints, capacitance, power และ operating conditions | mapping, STA, power analysis | ไม่ใช่รายละเอียด layout และไม่รับประกัน pin access |
| Cell LEF `.lef` | boundary, site, symmetry, pins, routing obstructions | placement, routing, physical integration | ไม่ใช่ transistor layout และใช้แทน GDS สำหรับ LVS ไม่ได้ |
| GDSII/OASIS | hierarchical layout geometry บน layer/datatype | stream-out merge, DRC, extraction/LVS | รูปทรงอย่างเดียวไม่ได้ให้ timing characterization |
| Verilog/SystemVerilog | functional หรือ timing simulation model ตามรุ่นที่ส่งมอบ | gate-level simulation | ไม่ใช่ analog model และไม่ได้แทน STA ครบทุก path |
| SPICE/CDL | device connectivity, subcircuits และอาจมี device parameters | LVS, characterization หรือ circuit simulation ตามชนิดไฟล์ | CDL สำหรับ LVS อาจไม่พร้อมจำลองใน SPICE simulator |

นอกจากนี้อาจมี schematic symbols, antenna data, characterization scripts, SDF และ proprietary compiled libraries ต้องระบุแหล่งกำเนิดและความเข้ากันได้ของแต่ละไฟล์เสมอ

## 4.4 Liberty: function, timing และ power

### 4.4.1 โครงสร้างและหน่วย

ตัวอย่างต่อไปนี้เป็น **ข้อความสาธิตบางส่วน ไม่ใช่ library ที่พร้อมใช้จริง**:

```liberty
library (teaching_tt) {
  time_unit : "1ns";
  voltage_unit : "1V";
  current_unit : "1mA";
  capacitive_load_unit (1, pf);
  leakage_power_unit : "1nW";
  nom_voltage : 1.20;
  nom_temperature : 25;
  cell (INV_X1) {
    area : 2.0;
    pg_pin (VDD) {
      pg_type : primary_power;
      voltage_name : VDD;
    }
    pg_pin (VSS) {
      pg_type : primary_ground;
      voltage_name : VSS;
    }
    pin (A) { direction : input; capacitance : 0.003; }
    pin (Y) {
      direction : output;
      function : "!A";
      related_power_pin : VDD;
      related_ground_pin : VSS;
    }
  }
}
```

ในตัวอย่าง capacitance = 0.003 pF = 3 fF และค่า delay 0.080 ใน timing table ที่ใช้ time unit เดียวกันจะหมายถึง 80 ps หากตีความ 0.003 เป็น fF โดยตรงจะผิด 1,000 เท่า ต้องอ่าน unit declarations ก่อนแปลตัวเลขทุกครั้ง

`nom_voltage` เป็น metadata ของ characterization ไม่ใช่คำสั่งจ่ายไฟให้ชิป การเปลี่ยนตัวเลขนี้ไม่ทำให้ library กลายเป็น corner แรงดันใหม่ และไม่สามารถใช้แทนการ characterization ที่แรงดันนั้นได้

### 4.4.2 Timing arcs

Combinational timing arc เชื่อม related input กับ output และอาจมีเงื่อนไข `when` สำหรับ state บางแบบ Inverter มักมี negative-unate arc: input ขึ้นทำให้ output ลง ส่วน buffer มักเป็น positive-unate และ XOR อาจเป็น non-unate

สำหรับ NLDM ค่า delay และ output transition มักเป็นฟังก์ชันของ input slew กับ output load แต่ต้องอ่าน `lu_table_template` จริงเพื่อทราบความหมายและลำดับแกน ไม่ควรถือว่า index_1 เป็น slew ในทุก table ทุกประเภท โมเดลแบบ CCS/ECSM มีรายละเอียด waveform/current เพิ่มเติม และต้องตรวจความสามารถของเครื่องมือที่อ่าน

Sequential cell ต้องมีทั้ง functional state definition และ timing constraints ที่เกี่ยวข้อง เช่น clock-to-Q, setup, hold, recovery, removal และ minimum pulse width ตามชนิด cell การมีเพียง function ของ Q ไม่เพียงพอสำหรับ timing sign-off

Delay ของ cell ต่างจาก delay ของ net: ตัวแรกมาจากโมเดล cell ภายใต้ slew/load ส่วนตัวหลังขึ้นกับ interconnect parasitics และวิธีคำนวณของ timing engine ทั้งสองมีปฏิสัมพันธ์กัน เพราะ net ทำให้ slew ที่ cell ถัดไปเปลี่ยน

### 4.4.3 Power model

แยก leakage power, internal switching power และ net switching power ออกจากกันโดยอ้างอิงนิยามของเครื่องมือ Internal power table อาจขึ้นกับ transition และ load ส่วน leakage อาจมี state dependence การมี power tables ไม่ทำให้รายงานกำลังไฟแม่นยำโดยอัตโนมัติ ต้องมี activity, clock frequency, voltage, capacitance และ scenario ที่เหมาะสม

ประมาณการ capacitive switching ใช้ P ≈ α C V² f ได้ โดยต้องนิยาม α ให้ชัดว่าเป็นอัตราเหตุการณ์ที่นับอย่างไร หากนำจำนวนทั้ง rising และ falling transitions มาใช้กับสูตรที่ตั้งใจนับเฉพาะ charging events อาจคลาดเคลื่อนเป็นเท่าตัวได้

## 4.5 LEF: abstract geometry และ pin access

LEF ลดรายละเอียดที่ไม่จำเป็นต่อ placement/routing แต่ยังต้องคง boundary, pin shapes และ obstructions ที่ถูกต้อง ตัวอย่างบางส่วน:

```lef
MACRO INV_X1
  CLASS CORE ;
  ORIGIN 0 0 ;
  SIZE 1.0 BY 2.0 ;
  SYMMETRY X Y ;
  SITE CORE_SITE ;
  PIN A
    DIRECTION INPUT ;
    USE SIGNAL ;
    PORT
      LAYER M1 ;
      RECT 0.10 0.80 0.20 1.00 ;
    END
  END A
END INV_X1
```

ข้อความนี้เป็น abstract สาธิตที่ยังขาด output และ power pins ห้ามนำไปใช้จริง ตัวเลข geometry ของ LEF โดยทั่วไปแสดงเป็นไมโครเมตร ส่วน `UNITS DATABASE MICRONS` กำหนดความละเอียด database ตรวจ manufacturing grid และการแปลงหน่วยด้วย

Pin access คือความสามารถในการสร้างทางเชื่อมที่ถูกกฎจาก routing grid เข้าถึง pin shape ไม่ใช่แค่การเห็น pin rectangle ใน viewer ปัจจัยที่กระทบได้แก่ track alignment, pin width, via enclosure, neighboring obstructions และ orientation หลัง placement

ตรวจอย่างน้อย:

1. Cell height และ site สอดคล้องกับ placement rows; multi-height cells มีกติกาเฉพาะ
2. Width สอดคล้องกับ site grid ตามข้อกำหนด library
3. Symmetry และ allowed orientations รองรับการวางสลับ row โดย power rails ยังตรงกัน
4. Signal/power pin layers อยู่ใน technology stack ที่เลือก
5. `USE POWER/GROUND` และ obstructions ถูกต้อง
6. LEF boundary กับ layout boundary ใช้ origin และขนาดสอดคล้องกัน

LEF อาจมี antenna attributes แต่การผ่าน routing ด้วย abstract ไม่ได้ยืนยันว่า final layout ผ่าน antenna deck จริง

## 4.6 GDS/OASIS: layout จริงและการส่งต่อ sign-off

GDSII และ OASIS เก็บ geometry แบบ hierarchical ซึ่งต้องแปลผ่าน layer map ที่ตรงกับเทคโนโลยี การเปิดไฟล์แล้วเห็นรูปร่างได้ไม่ได้ยืนยันว่า layer mapping ถูกต้อง เช่น drawing layer กับ pin/text purpose อาจถูกแปลต่างกัน

ขั้นตอน stream-out ต้องรวม standard cells, IO และ macros ที่อ้างอิงใน top layout ให้ครบ ตรวจ unresolved references และ duplicate cell names หากมี cell ชื่อเดียวกันแต่ geometry ต่างกัน ต้องแก้ที่แหล่งข้อมูลและนโยบาย merge ไม่ควรยอมให้เครื่องมือเลือกทับอย่างเงียบ ๆ

Layout จริงใช้สำหรับ DRC และ extraction แต่ LVS ยังต้องมี rule deck, source netlist, device recognition และ power/global-net policy ที่ถูกต้องด้วย ทั้งนี้ foundry acceptance ต้องยึด qualified flow และ deck ที่กำหนดสำหรับโครงการ

## 4.7 Verilog models และความสัมพันธ์กับ VHDL

ตัวอย่าง model แบบมี power ports ชัดเจน:

```verilog
module INV_X1(input wire A, output wire Y,
              inout wire VDD, inout wire VSS);
  assign Y = ~A;
endmodule
```

Model นี้ตรวจ Boolean function เท่านั้น **ไม่ได้ตรวจแรงดันหรือความต่อเนื่องของ power rails** แม้มี VDD/VSS ports อยู่ใน module การจำลองขาดไฟยังให้ output ตาม assign ได้ จนกว่าจะใช้ power-aware model หรือ simulation methodology ที่กำหนด

Library บางชุดซ่อน supply ports ผ่าน compile-time macros บางชุดประกาศตลอดเวลา จึงต้องให้ netlist, model และ compiler defines ตรงกัน ตรวจชื่อ macro จาก model จริง ห้ามสมมติชื่อ define ว่าเหมือนกันทุก PDK

RTL ที่เขียนด้วย VHDL และ SystemVerilog สามารถ map ไป cell ชุดเดียวกันได้ แต่หลัง synthesis netlist อาจเป็น Verilog ผู้ใช้ VHDL จึงอาจต้องใช้ mixed-language simulation หรือ simulator configuration ที่รองรับ vendor models ห้ามสร้าง VHDL behavioral model แบบย่อแล้วอ้างว่าเทียบเท่า timing model ที่ qualified โดยอัตโนมัติ

สำหรับ timed GLS ให้ตรวจ model `specify`, SDF instance hierarchy, timescale/time precision และ annotation coverage ส่วน functional GLS ต้องระบุชัดว่ารันแบบไม่มี delay หรือมี delay ประเภทใด

## 4.8 SPICE/CDL และ LVS flow

```spice
.SUBCKT INV_X1 A Y VDD VSS
MP0 Y A VDD VDD PMOS_MODEL W=1u L=0.13u
MN0 Y A VSS VSS NMOS_MODEL W=0.5u L=0.13u
.ENDS INV_X1
```

ตัวอย่างนี้เป็น topology สาธิต ไม่ใช่ device naming หรือขนาดที่รับรองสำหรับ PDK ใด การเรียก subcircuit ของ SPICE โดยทั่วไปใช้ลำดับ node แบบ positional จึงต้องตรวจ `.SUBCKT` port order คู่กับ instance จริง โดยเฉพาะ VDD/VSS และ bulk terminals

CDL เป็น netlist dialect ที่มักใช้ใน LVS อาจมี constructs, device naming หรือ parameter conventions ที่ simulator อ่านไม่ได้โดยตรง การใช้ไฟล์หนึ่งสำหรับทั้ง LVS และ simulation ต้องยืนยัน compatibility พร้อม model includes และ unit scaling

ต้องระบุว่า LVS ใช้ transistor-level comparison, hierarchical cell matching หรือ black-box policy แบบใด การ black-box standard cells หรือ macros อาจจำกัดสิ่งที่ตรวจพิสูจน์ได้ ไม่ควรตีความ LVS ผ่านว่าได้ตรวจ transistor ภายในทุก block หาก flow ไม่ได้ทำเช่นนั้น

## 4.9 Cross-view consistency audit

| รายการ | สิ่งที่ตรวจ | ตัวอย่างความเสียหาย |
|---|---|---|
| Cell identity | Liberty cell, LEF MACRO, layout structure, module, SUBCKT | mapping ผ่านแต่ layout merge หา cell ไม่พบ |
| Signal pins | ชื่อ direction และ function | A/Y สลับหรือ reset polarity ต่างกัน |
| Power pins | pg_pin, LEF USE, model ports, source/extracted nets | simulation ผ่าน แต่ physical power ขาด |
| Bus notation | `D[0]`, `D<0>`, escaped identifiers และ bit ordering | บิตสลับหรือ LVS port mismatch |
| Units | time, capacitance, geometry, device scaling | timing/load ผิดหลายลำดับขนาด |
| Physical boundary | origin, size, site, orientation | rows ทับกันหรือ rail ไม่ต่อ |
| Revision | release และ checksum | ชื่อเหมือนกันแต่ pin geometry เปลี่ยน |

อย่าเปรียบเทียบเพียงจำนวน pins รวม เพราะ Liberty อาจแยก `pg_pin` ออกจาก signal `pin` และ Verilog อาจซ่อน power ports ให้เปรียบเทียบตาม logical pin identity พร้อมบันทึก mapping ที่อนุญาต

สำหรับ bus ให้ตรวจ `BUSBITCHARS` ใน LEF, bus naming/type ใน Liberty และ netlist escaping เช่น Verilog identifier ที่เริ่มด้วย backslash ต้องมี whitespace ปิดท้าย การแทนที่ `[]` เป็น `<>` แบบ global อาจทำให้ hierarchy หรือ identifier อื่นเสียหาย ต้องใช้ parser หรือ mapping ของเครื่องมือ

Cell sets ไม่จำเป็นต้องเท่ากันทั้งหมด ควรจัดเป็น logic cells, physical-only cells และ macros แล้วกำหนด required views ของแต่ละกลุ่ม ตัวอย่าง filler ไม่ต้องมี Boolean timing arc แต่ต้องมี physical data และ LVS handling ตาม flow

## 4.10 PVT corner, operating voltage และ RC corner

### 4.10.1 PVT เป็นสภาวะของ cell/device

P = process condition จากความแปรผันการผลิต, V = supply voltage และ T = temperature ที่ใช้สร้าง model สำหรับการวิเคราะห์ ชื่อ TT/SS/FF เป็น convention ที่พบได้บ่อย แต่ความหมายและความสัมพันธ์กับ model จริงต้องอ่านเอกสาร library โดยเฉพาะ mixed-device corners

ตัวอย่าง `slow_1p08V_125C` บอกเงื่อนไขตาม naming convention ของผู้จัดทำเท่านั้น ต้องตรวจ operating conditions และ characterization metadata ภายในไฟล์ประกอบ ชื่อไฟล์อาจเป็น alias ที่ flow สร้างขึ้น

### 4.10.2 Operating voltage และ voltage domains

Operating voltage คือแรงดันใช้งานที่ออกแบบให้แต่ละ domain ได้รับ ต้องอยู่ในช่วงที่ technology และ cells รองรับ และมี timing/power models ครอบคลุม scenario ที่วิเคราะห์ แรงดัน nominal 1.20 V ไม่ได้หมายความว่า sign-off ใช้เฉพาะ 1.20 V เพราะ supply tolerance และระบบจ่ายไฟอาจทำให้ต้องตรวจเงื่อนไขอื่น

Core กับ IO อาจมีแรงดันต่างกัน IO model อาจมีมากกว่าหนึ่ง supply voltage ต้องเลือก library ที่ตรงทั้ง core-side และ pad-side voltage พร้อมตรวจ level shifting, input tolerance และ power sequencing จากข้อกำหนดจริง ตัวอย่างจาก IHP documentation มี IO Liberty ชื่อที่ระบุทั้ง 1.2 V และ 3.3 V [3]

IR drop ทำให้แรงดัน ณ cell ต่างจากแรงดันที่แหล่งจ่าย แต่การใช้ low-voltage corner ทั่วชิปไม่เท่ากับวิเคราะห์ spatial/dynamic IR drop ต้องระบุ methodology และ guardband แยกกัน

### 4.10.3 RC corner เป็นสภาวะของ interconnect

RC corner อธิบายการเปลี่ยน resistance/capacitance ของสายและ vias ตาม geometry, material และ process assumptions ของ extraction technology อาจพบชื่อ typical, RCmax, RCmin, Cmax หรือ Cmin แต่ห้ามถือว่า RCmax = Rmax และ Cmax ทุกองค์ประกอบโดยไม่มีเอกสารรับรอง

PVT corner และ RC corner เป็นคนละแกน: เลือก Liberty เพื่อกำหนดพฤติกรรม cell และเลือก extraction model/SPEF เพื่อกำหนด interconnect การเลือก Liberty slow ไม่ได้ทำให้ parasitic nets กลายเป็น RCmax โดยอัตโนมัติ

| Scenario สาธิต | Cell condition | Interconnect condition | วัตถุประสงค์ |
|---|---|---|---|
| nominal | typical / nominal V / nominal T | RC typical | baseline/debug |
| setup candidate | slow / low V / selected T | qualified RC corner | ตรวจ late arrival |
| hold candidate | fast / high V / selected T | qualified RC corner | ตรวจ early arrival |

ตารางนี้เป็นแนวคิดเริ่มต้น ไม่ใช่ sign-off matrix ที่ใช้ได้ทุกเทคโนโลยี Temperature inversion, clock/data topology และ coupling อาจทำให้ worst case ไม่เป็นไปตามคำจำ TT/SS/FF แบบง่าย ๆ ต้องใช้ scenario matrix ที่โครงการรับรอง รวมทั้ง OCV/AOCV/POCV ตามที่มีข้อมูลและเครื่องมือรองรับ

Setup และ hold ขึ้นกับทั้ง data และ clock paths จึงไม่ควรสรุปว่าใช้ RCmax สำหรับ setup และ RCmin สำหรับ hold เสมอโดยไม่ตรวจผลจริง RC corner ไม่ได้แทน derating และ derating ก็ไม่ได้แทน RC extraction

## 4.11 ขั้นตอนปฏิบัติ: library bring-up

### ขั้นที่ 1 — ทำ manifest

บันทึกตารางที่มี logical library name, release, cell family, voltage domain, PVT, RC corner, metal stack, path และ checksum แยก Liberty สำหรับ standard cells/IO/SRAM ให้ครบ อย่าผูก corner จากการเดาชื่อไฟล์เพียงอย่างเดียว

### ขั้นที่ 2 — ตรวจข้อความเบื้องต้น

คำสั่งต่อไปนี้ใช้ใน Bash/WSL โดยเปลี่ยน paths ให้ตรงกับชุดข้อมูลจริง:

```bash
rg -n 'time_unit|capacitive_load_unit|voltage_unit|nom_voltage|nom_temperature' lib/cells.lib
rg -n 'cell\s*\(|pg_pin\s*\(|pg_type|voltage_name' lib/cells.lib
rg -n 'BUSBITCHARS|DATABASE MICRONS|MACRO|SITE|USE POWER|USE GROUND' lef/cells.lef
rg -n '^\s*module\b|inout|supply0|supply1|ifdef' verilog/cells.v
rg -ni '^\s*\.subckt' spice/cells.cdl
sha256sum lib/cells.lib lef/cells.lef verilog/cells.v spice/cells.cdl
```

`rg` เป็นการคัดกรอง ไม่ใช่ parser หรือหลักฐานว่าทุก syntax ถูกต้อง เช่น multiline declarations และ escaped names ต้องให้เครื่องมือจริงอ่านยืนยัน

### ขั้นที่ 3 — อ่านด้วยเครื่องมือจริง

ตัวอย่าง OpenROAD Tcl สำหรับตรวจ linking ขั้นพื้นฐาน โดย environment variables ต้องชี้ไฟล์ที่มีอยู่จริง:

```tcl
read_lef $::env(TECH_LEF)
read_lef $::env(CELL_LEF)
read_liberty $::env(CELL_LIB)
read_verilog $::env(TEST_NETLIST)
link_design view_probe
write_db view_probe.odb
```

ทดสอบด้วย netlist เล็กที่มี inverter, combinational cell และ flip-flop ที่เลือกจาก library จริง ตรวจ warnings เรื่อง missing masters, missing pins, undefined cells และ unsupported constructs เพิ่ม IO/SRAM libraries เมื่อ probe ใช้ cell เหล่านั้น ลำดับและคำสั่งนี้อ้างอิง OpenROAD API; ไม่ใช่คำสั่งรับรองสำหรับ Tanner ทุกรุ่น [1]

สำหรับ Tanner/Siemens ให้ map หน้าที่เดียวกันไปยัง library setup/import ของรุ่นที่ติดตั้ง และใช้เอกสารรุ่นนั้นตรวจ syntax ห้ามนำคำสั่งของ OpenROAD ไปถือเป็นคำสั่งของ Tanner โดยตรง

### ขั้นที่ 4 — จำลอง functional probe

ใช้ cell models จริง ขับ directed patterns ของ combinational cells และตรวจ clock/reset/enable ของ sequential cells ด้วย self-checking testbench ทดสอบ active level และ async/sync reset ตาม function ที่ระบุ การใช้ RTL testbench ของ Module 3 ต่อกับ gate netlist ช่วยตรวจ semantic mismatch แต่ต้องปรับ sampling ให้เหมาะกับ delay model

### ขั้นที่ 5 — ตรวจ physical probe

วาง cells ใน rows ที่ถูกต้อง ต่อ signal และ power ตาม policy ของ flow แล้วตรวจ pin access, rail alignment และ layout merge จากนั้นใช้ qualified DRC/LVS setup ตามขอบเขตการทดสอบ การอ่าน LEF ผ่านเพียงอย่างเดียวไม่ครอบคลุมขั้นนี้

### ขั้นที่ 6 — ตรวจหน่วยใน STA

ตรวจ unit report/log ของ timing tool และแปล test case ด้วยมือ เช่น delay 0.08 ns และ load 0.003 pF ต้องได้ 80 ps และ 3 fF เอกสาร OpenSTA ระบุว่าหน่วยสำหรับ command arguments และ reports มาจาก Liberty แรกที่อ่าน จึงต้องตรวจลำดับโหลดและ unit handling ของรุ่นที่ใช้ [2]

## 4.12 Lab — ตรวจ library และใส่ข้อผิดพลาดโดยตั้งใจ

ให้ผู้เรียนใช้สำเนาชุดข้อมูลสำหรับการทดลอง เก็บ original read-only และทำ audit สามรอบ: baseline, injected failure และ restored baseline

| การทดลอง | วิธี | หลักฐานที่ต้องเห็น |
|---|---|---|
| Cell-name mismatch | เปลี่ยน cell reference ใน probe เป็นชื่อที่ไม่มีจริง | linker/physical reader แจ้ง unresolved cell |
| Power-pin mismatch | เปลี่ยน mapping VDD เป็นชื่อผิดในสำเนา config | connectivity checker พบ pin/net ที่ไม่ถูกต่อ |
| Unit interpretation | ให้ load เป็นตัวเลขเดียวกันแต่ตีความ pF/fF ต่างกันในใบคำนวณ | ผู้เรียนแสดงความผิด 1,000 เท่าได้ |
| Wrong voltage scenario | จับคู่ domain กับ Liberty ที่ไม่ตรง manifest | audit ปฏิเสธก่อนรัน implementation |
| Bus mapping | สลับ mapping D[0] และ D[1] ของ probe bus | directed one-hot test ตรวจพบ |

ไม่ควรแก้ time_unit ภายใน Liberty แล้วถือว่าได้แปลง library สำเร็จ เพราะ table values และ attributes ที่เกี่ยวข้องต้องแปลงครบ การทดลองหน่วยใน lab ให้เน้นการตรวจจับและตีความ มากกว่าสร้าง library ที่ผิดแล้วนำกลับเข้าผลิตจริง

สิ่งส่งมอบ: manifest, view/pin mapping table, logs การอ่านจริง, ผล simulation, ภาพ pin geometry พร้อมคำอธิบาย และ failure report ที่ระบุว่าด่านใดตรวจพบ injected bug หากข้อผิดพลาดผ่านทุกด่าน ต้องปรับ audit/test ให้ตรวจพบก่อนจบ lab

## 4.13 Troubleshooting

| อาการ | สาเหตุที่ควรตรวจ | แนวทางแก้ |
|---|---|---|
| Synthesis ผ่าน แต่ place ไม่ได้ | Liberty cell ไม่มี LEF master | ใช้ release ที่ตรงกันหรือตัด cell ออกจาก mapping ตาม policy |
| Route เข้าขาไม่ได้ | pin access, tracks, vias, obstruction | ตรวจ abstract กับ tech LEF และ geometry จริง |
| GLS หา module ไม่พบ | model list, model variant, defines | compile library models ที่ตรง netlist |
| LVS power mismatch | global nets, explicit ports, bulk connection | ตรวจ source/extraction naming และ deck policy |
| Timing ผิดขนาดมาก | time/cap units, corner หรือ constraints | ตรวจ metadata และคำนวณ sanity check |
| GDS มี missing references | ไม่รวม macro/standard-cell layout | แก้ stream-out source list และ top hierarchy |
| Simulation ถูกแต่ไฟเลี้ยงขาด | Boolean model ไม่ตรวจ PG connectivity | ใช้ physical connectivity checks เพิ่ม |

## 4.14 เกณฑ์ผ่านและคำถามทบทวน

ผ่าน Module เมื่อผู้เรียนมีหลักฐานว่า logic cells ที่ใช้มี required views ครบ ชื่อและขาสัมพันธ์กัน physical-only cells มี handling ที่ชัดเจน หน่วยถูกต้อง power domains ถูก map และทุก analysis scenario ระบุ PVT กับ RC แยกกัน รวมทั้งเปิดเผยข้อจำกัดของการทดสอบที่ยังไม่ได้ทำ

คำถามทบทวน:

1. เหตุใดมี Liberty ครบจึงยังไม่รับประกันว่า router เข้าถึง pin ได้?
2. ทำไม Verilog model ที่มี VDD/VSS ports อาจจำลองผ่านแม้ไม่ต่อไฟ?
3. ถ้า Liberty ใช้ ns และ pF ค่า 0.025 และ 0.006 หมายถึงกี่ ps และ fF? **ตอบ:** 25 ps และ 6 fF
4. เปลี่ยน `nom_voltage` เพียงอย่างเดียวถือว่าสร้าง corner ใหม่หรือไม่? **ตอบ:** ไม่ได้
5. RC corner ต่างจาก transistor process corner อย่างไร?
6. เหตุใดไม่ควรบังคับให้จำนวน cells ใน Liberty กับ LEF เท่ากันทุกตัว?
7. LVS แบบ black-box macro ยืนยันอะไรได้และยังไม่ได้ยืนยันอะไร?
8. ต้องเก็บข้อมูลใดเพื่อให้ผู้อื่นทำซ้ำ library bring-up ได้?

## เอกสารอ้างอิง

เนื้อหาและ code snippets ในบทนี้เป็นคำอธิบายเพื่อการสอน ตัวอย่างสมมติไม่ใช่ sign-off models หรือ foundry-qualified collateral ตรวจเอกสาร release และ tool manuals ของโครงการก่อนใช้งานจริง

1. OpenROAD API — การอ่าน LEF, Liberty, Verilog และ linking: https://openroad.readthedocs.io/en/latest/main/src/README.html
2. OpenSTA Examples — หน่วยของ command arguments/reports: https://openroad.readthedocs.io/en/latest/main/src/sta/doc/Examples.html
3. IHP OpenPDK, Output Drive Strength — ตัวอย่าง IO Liberty และแรงดันสอง domain: https://ihp-open-pdk-docs.readthedocs.io/en/latest/contents/io_library/02_drive_strength.html
4. IHP OpenPDK, Technology Libraries — การจัดกลุ่ม technology และ library-specific flow data: https://ihp-open-pdk-docs.readthedocs.io/en/latest/contents/technology_libraries/index.html

