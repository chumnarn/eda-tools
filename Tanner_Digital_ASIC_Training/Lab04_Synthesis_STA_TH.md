# Lab 4 — Synthesis/STA: รัน synthesis ตรวจ mapping และ timing coverage

หลักสูตร Tanner Digital ASIC Design Implementation — คู่มือปฏิบัติทีละขั้น

เวลาแนะนำ 3–4 ชั่วโมง แบ่งเป็น synthesis 60 นาที, mapping audit 45 นาที, constraints/STA 60 นาที และการทดลองข้อผิดพลาดกับสรุปผล 45 นาที

## 4.1 เป้าหมายและขอบเขต

Lab นี้เปลี่ยน RTL counter เป็น netlist ที่ใช้ standard cells ของ library เป้าหมาย แล้วพิสูจน์ว่ารายงาน timing วิเคราะห์เส้นทางที่ต้องการครบ ผู้เรียนต้องตอบให้ได้ทั้ง “วงจรถูก map เป็นอะไร” และ “ตัวเลข slack ครอบคลุมเงื่อนไขใด” ก่อนส่งต่อ floorplan และ placement

เมื่อจบ Lab ผู้เรียนต้องสามารถ:

1. รัน elaboration และ synthesis ด้วย top, source list และ library ที่ตรวจสอบย้อนกลับได้
2. แยก generic operators ออกจาก technology-mapped cells และตรวจ unresolved references
3. อธิบาย register, incrementer, enable feedback และ reset logic ใน mapped netlist
4. ตรวจ clock coverage, I/O constraints, exceptions และ unconstrained endpoints
5. อ่าน setup/hold path report และเชื่อมโยงกับ external timing contract
6. ทำ negative test ให้ coverage audit ตรวจพบ constraint ที่หายไป
7. ส่งมอบ netlist, constraints, reports และข้อจำกัดของผล pre-layout อย่างชัดเจน

**ขอบเขตผลลัพธ์:** เป็น synthesis และ pre-layout STA สำหรับ digital block ยังไม่ใช่ post-route sign-off ไม่ได้พิสูจน์ DRC/LVS, power connectivity, IR drop หรือความพร้อมผลิตชิป

Siemens ระบุว่า Digital Implementer ใช้ Oasys synthesis และ Nitro place-and-route engines [1] อย่างไรก็ตาม ชื่อเมนู คำสั่งเรียก engine และ Tcl reporting APIs ต้องยึดคู่มือที่ติดตั้งกับรุ่นของห้องปฏิบัติการ บทนี้ใช้ชื่อขั้นตอนตามหน้าที่ ไม่สมมติว่าเป็นชื่อเมนูจริงทุกเวอร์ชัน

## 4.2 ความต่อเนื่องจาก Lab 2 และ Lab 3

| รายการ | Baseline ของ Lab 4 ตามตัวอย่าง Lab 3 | ทางเลือกจาก Lab 2 |
|---|---|---|
| Top | counter | counter |
| ความกว้าง | WIDTH=8 | N=4 |
| Clock | clk, rising edge | clk, rising edge |
| Reset | rst, synchronous active-high | rst_n, asynchronous active-low |
| Enable | en, synchronous | en, synchronous |
| Output | q[7:0] | q[3:0] |
| Reset timing | input-to-register data path | recovery/removal และ reset distribution |

เลือก baseline เพียงแบบเดียวต่อ run แล้วบันทึกใน manifest ห้ามเปลี่ยนชื่อ rst_n เป็น rst ใน SDC โดยไม่เปลี่ยน semantics ของ RTL และห้ามนำ testbench แบบ asynchronous reset มาใช้ตรวจ synchronous-reset DUT โดยไม่ปรับ reference model

ถ้าต่อยอดโปรเจกต์จริงจาก Lab 3 ซึ่งผู้เรียนเลือกใช้ RTL ของ Lab 2 ไว้แล้ว ให้รักษา interface นั้นและใช้แนวทาง reset ในหัวข้อ 4.17 แทน baseline ด้านล่าง

### Reference SystemVerilog

```systemverilog
module counter #(parameter int unsigned WIDTH = 8) (
  input  logic             clk,
  input  logic             rst,
  input  logic             en,
  output logic [WIDTH-1:0]  q
);
  always_ff @(posedge clk) begin
    if (rst)     q <= '0;
    else if (en) q <= q + 1'b1;
  end
endmodule
```

สำหรับ Verilog-2001 ให้ใช้ parameter WIDTH=8, input wire, output reg, always @(posedge clk) และแทน '0 ด้วย {WIDTH{1'b0}} โดยคง nonblocking assignment

### Reference VHDL

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
  generic (WIDTH : positive := 8);
  port (
    clk : in std_logic;
    rst : in std_logic;
    en  : in std_logic;
    q   : out std_logic_vector(WIDTH-1 downto 0)
  );
end entity;

architecture rtl of counter is
  signal count_reg : unsigned(WIDTH-1 downto 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        count_reg <= (others => '0');
      elsif en = '1' then
        count_reg <= count_reg + 1;
      end if;
    end if;
  end process;
  q <= std_logic_vector(count_reg);
end architecture;
```

เลือกภาษาเดียวต่อ project/run และเลือก architecture rtl เมื่อ flow ต้องการ explicit binding หาก frontend ไม่รองรับภาษาหรือมาตรฐานที่เลือก ต้องใช้เส้นทางที่ผู้จัดหาหรือ reference flow รองรับ และบันทึกขั้นตอนแปลงกับการตรวจ equivalence ไม่ถือว่าการเปลี่ยนนามสกุลไฟล์เป็นการแปลงภาษา

## 4.3 Step 1 — Freeze inputs ก่อนรัน

1. เปิดสำเนาโปรเจกต์ที่ผ่าน Lab 3 ตั้งชื่อ run เช่น lab04_sv_baseline หรือ lab04_vhdl_baseline
2. ตรวจ implementation top เป็น counter ไม่ใช่ tb_counter
3. ตรวจ parameter/generic override เป็น 8 สำหรับ baseline
4. แยก RTL ออกจาก simulation source: ไม่ส่ง clock generator, scoreboard หรือ assertions ของ testbench เข้า synthesis
5. ตรวจ path ของ Liberty, technology setup และ SDC จากค่าที่ engine อ่านจริง
6. บันทึก tool/build, engine, PDK release, cell-library release, PVT corner และ wire-delay model
7. เก็บ source list และ checksum ก่อนรัน ห้ามแก้ source ระหว่าง engine กำลังทำงาน

โครงสร้างผลลัพธ์ที่แนะนำ:

| ที่จัดเก็บ | เนื้อหา |
|---|---|
| runs/lab04_sv_baseline/logs | transcript และ engine logs |
| runs/lab04_sv_baseline/netlist | mapped netlist |
| runs/lab04_sv_baseline/reports | structural, mapping และ timing reports |
| runs/lab04_sv_baseline/constraints | input SDC และ exported/effective constraints |
| runs/lab04_sv_baseline/scripts | generated/exported scripts ของ run |
| runs/lab04_sv_baseline/docs | manifest, warning review และ summary |

ตัวอย่างตรวจ hash บน PowerShell:

```powershell
Get-FileHash -Algorithm SHA256 -LiteralPath .\rtl\sv\counter.sv
Get-FileHash -Algorithm SHA256 -LiteralPath .\constraints\counter.sdc
```

ใช้ path ของโปรเจกต์จริง และเก็บผลลง manifest; สำหรับ VHDL ให้ hash counter.vhd แทน

**Checkpoint 1:** ชื่อ top, port names, width และ reset contract ตรงกันระหว่าง RTL, project และ SDC

## 4.4 Step 2 — ตรวจ timing library และหน่วย

1. เปิด library summary ผ่านเครื่องมือหรือรายงานที่ template รองรับ
2. ยืนยันชื่อ logical library และ library files ที่โหลดสำเร็จ
3. ตรวจ process, voltage, temperature และ operating condition
4. ตรวจ time_unit และ capacitive_load_unit ของ Liberty
5. ตรวจหน่วยที่ STA session ใช้จริง เพราะ SDC ตัวเลขล้วนไม่ได้ประกาศหน่วยในแต่ละบรรทัด
6. ตรวจว่ามี flip-flop, combinational cells และ timing arcs ที่งานต้องใช้
7. บันทึกรายการ dont_use หรือ cell restrictions ที่รับมาจาก reference template

ตัวอย่าง 0.02 ใน set_load หมายถึง 0.02 pF ก็ต่อเมื่อ session ใช้หน่วย pF จริง ไม่ใช่ข้อกำหนดสากลของ SDC ถ้า session ใช้ fF ต้องแปลงค่าตามนั้น ห้ามเดาหน่วยจากขนาดตัวเลข

อย่ารวม Liberty ของคนละ PVT เป็น link library ก้อนเดียวโดยไม่มี corner association ตาม flow เพราะอาจเลือก cell/timing view ผิด ใน Lab เริ่มด้วย corner เดียวที่ระบุชัด แล้วจึงเพิ่ม setup/hold views ตาม reference methodology

**Checkpoint 2:** รายงานระบุ PVT และหน่วยครบ; ไม่มี library read error หรือ unsupported timing model ที่ยังไม่ได้ทบทวน

## 4.5 Step 3 — เตรียม SDC baseline

ตัวอย่างนี้สมมติ session ใช้ ns และ pF ค่าเป็น timing contract เพื่อการสอน ไม่ใช่ค่าที่ได้จากระบบภายนอกหรือคำรับรอง PPA ของ PDK

```tcl
# constraints/counter.sdc
# Assumptions: rising-edge interface; time ns; capacitance pF.
create_clock -name core_clk -period 10.000 [get_ports {clk}]

set_clock_uncertainty -setup 0.200 [get_clocks {core_clk}]
set_clock_uncertainty -hold  0.050 [get_clocks {core_clk}]

# rst is synchronous in this baseline and must be timed.
set_input_delay -clock [get_clocks {core_clk}] -max 2.000 \
  [get_ports {rst en}]
set_input_delay -clock [get_clocks {core_clk}] -min 0.200 \
  [get_ports {rst en}]

set_output_delay -clock [get_clocks {core_clk}] -max 2.000 \
  [get_ports {q*}]
set_output_delay -clock [get_clocks {core_clk}] -min -0.200 \
  [get_ports {q*}]

set_input_transition 0.100 [get_ports {rst en}]
set_load 0.020 [get_ports {q*}]
```

ก่อนใช้งานจริงให้ตรวจ command/options ที่ engine รองรับ รูปแบบ collection และ wildcard ต้องทดสอบใน session นั้น `q*` ต้องเลือก output q ทั้ง 8 บิตเท่านั้น โดยตรวจรายชื่อและจำนวน ห้ามยอมรับ empty collection หรือ selection ที่กว้างเกินความตั้งใจ

### ความหมายของ contract

| Constraint | ความหมายในโจทย์นี้ |
|---|---|
| period 10 ns | หนึ่ง cycle ของ core_clk |
| input max 2 ns | ข้อมูลภายนอกมาถึง input ช้าที่สุด 2 ns หลัง reference edge |
| input min 0.2 ns | ข้อมูลภายนอกอาจเปลี่ยนเร็วสุด 0.2 ns หลัง edge |
| output max 2 ns | งบภายนอกด้าน setup รวมตาม interface contract |
| output min −0.2 ns | ตัวอย่าง receiver hold requirement 0.2 ns เมื่อไม่คิด board skew |
| input transition 0.1 ns | slew ของ data/control ที่ขอบ block |
| output load 0.02 pF | load ที่ขอบ block ตามสมมติฐาน |

เครื่องหมายลบใน output min เป็นส่วนหนึ่งของการจำลอง hold requirement ภายนอก ไม่ได้หมายความว่า hold ผ่านเอง ระบบจริงต้องรวม external clock arrival, board/interconnect delay และ reference-clock convention ให้ถูกต้อง

SDC ใช้ input/output delays อ้างอิง clock เพื่อจำลอง environment [2] ต้องระบุ min/max ให้ชัด หลีกเลี่ยงการพึ่ง default ที่ engine อาจตีความต่างกัน ตรวจ effective constraints หลังโหลดเสมอ

Clock transition/drive ให้ใช้ค่าจาก reference template หรือเพิ่มตามคำสั่งที่รุ่นนั้นรองรับ แล้วบันทึกค่า effective ห้ามใช้ set_input_transition กับ data อย่างเดียวแล้วสรุปว่า clock slew ถูกกำหนดแล้ว

**ห้ามใช้กับ baseline:** set_false_path -from [get_ports {rst}] เพราะ rst เป็น synchronous data/control input ต้องตรวจ setup/hold ไปยัง register ที่ได้รับผล

## 4.6 Step 4 — ตรวจ elaboration ก่อน mapping

1. เรียกขั้นอ่าน HDL/elaboration ของ flow
2. เปิด transcript ตั้งแต่บรรทัดแรกของ run ไม่ดูเฉพาะสถานะสีเขียวท้าย GUI
3. ตรวจ module/entity และ architecture ที่เลือก
4. ตรวจค่า WIDTH=8 และ q จำนวน 8 บิต
5. ตรวจ hierarchical references และ binding ให้ครบ
6. ตรวจ unresolved module/entity, multiple drivers, undriven signals และ width mismatch
7. เปิด elaborated schematic/hierarchy หาก flow มีให้ใช้

สำหรับ counter ควรเห็น state storage เทียบเท่า 8 บิต พร้อม logic เพิ่มหนึ่งและเลือก hold/reset อาจยังเป็น generic operators ซึ่งเป็นเรื่องปกติในระยะ elaboration แต่ต้องไม่ใช่ final technology-mapped deliverable

### Warning ที่ต้องตัดสินใจก่อนรันต่อ

| ประเด็น | แนวทาง |
|---|---|
| Unresolved reference | หยุด ตรวจ source list, binding และ search path |
| Testbench เป็น top | หยุด แก้ top และ source classification |
| Truncation ใน increment | ตรวจ intentional modulo และความกว้าง operand; ไม่ waive ทุก truncation |
| Inferred latch | baseline ไม่ควรมี; ตรวจ process และ assignment coverage |
| Register removed | ตรวจ observability, constants และการต่อ output |
| Unsupported construct | ใช้ RTL subset ที่ frontend รองรับแล้วจำลองซ้ำ |

**Checkpoint 3:** ไม่มีข้อผิดพลาดเชิงโครงสร้างที่ยังไม่ได้แก้ และ warning ทุกกลุ่มมีเหตุผลบันทึกไว้

## 4.7 Step 5 — โหลด constraints และตรวจว่า apply จริง

1. รันขั้นโหลด SDC ที่ reference flow กำหนด
2. ตรวจ log ว่าอ่านไฟล์ path ที่ตั้งใจ ไม่ใช่ SDC ของ reference design เก่า
3. ตรวจ error/warning เช่น object not found, empty collection, unknown command หรือ ignored constraint
4. เปิด clock report ยืนยัน core_clk, period 10 ns และ source port clk
5. ตรวจ I/O delay reports ยืนยัน rst, en และ q ทุกบิตมี min/max
6. ตรวจ uncertainty ว่าถูกผูกกับ core_clk ตามที่ต้องการ
7. ตรวจ exceptions และ case analysis ที่อาจสืบทอดจาก template
8. บันทึกรายงาน effective constraints ก่อน optimization

การที่ SDC “อ่านจบ” ไม่ได้ยืนยันว่า collections จับ object ได้ถูกต้อง และการที่รายงานมี clock หนึ่งตัวก็ไม่ยืนยันว่า clock ไปถึง register ทุกตัว

### รายการเป้าหมายสำหรับ baseline

| Object | จำนวนคาดหมายก่อน optimization | หลักฐาน |
|---|---:|---|
| Primary clock | 1 | clock report |
| Clock source port | 1: clk | clock definition |
| Synchronous input bits | 2: rst, en | min/max input-delay report |
| Output bits | 8: q | min/max output-delay report |
| Register state bits | 8 | elaboration/mapping report |

จำนวน physical instances อาจไม่เท่ากับจำนวน state bits เช่น multi-bit flop จึงต้องระบุว่ารายงานนับอะไร

## 4.8 Step 6 — รัน synthesis และ technology mapping

1. บันทึก project configuration และ run name
2. เลือกขั้น synthesis ตาม flow ที่ตรวจผ่านใน Lab 1–3
3. ตรวจ library mapping target, optimization effort และ clock-gating/retiming settings
4. สำหรับ baseline คง reference settings ที่ทราบผล และบันทึกหากเปิด retiming หรือ automatic clock gating
5. เริ่มรัน ติดตาม syntax/elaboration errors ก่อนดู optimization progress
6. ตรวจ log ว่า mapping ใช้ standard-cell family ที่ต้องการจริง
7. เมื่อจบ ตรวจ completion status และ fatal/error messages ทั้งหมด
8. บันทึก mapped netlist, synthesis database/checkpoint และ reports ผ่านคำสั่ง export ของ flow

ถ้า flow ใช้ timing-driven physical synthesis ให้บันทึกด้วยว่ามี provisional placement/RC estimation ใดแล้ว ผลยังต้องแยกจาก final routed parasitics

### การใช้ Tcl อย่างถูกต้อง

ให้ export/generated script จาก wizard หรือ reference template ที่รันได้จริง แล้วค้นหาช่วงที่ทำหน้าที่ต่อไปนี้:

| หน้าที่ | สิ่งที่ต้องยืนยันใน script/log |
|---|---|
| Read HDL | รายการไฟล์ ภาษา และ defines/includes |
| Elaborate/link | top, generic/parameter และ libraries |
| Read constraints | path ของ SDC และเวลาที่โหลดใน flow |
| Synthesis/map | target library, effort และ restrictions |
| Write outputs | mapped netlist และ database |
| Report | area, references, checks และ timing |

ไม่ใช้คำสั่งจาก Synopsys DC, OpenSTA หรือ Yosys แทนคำสั่ง TDI โดยอนุมานจากชื่อที่คล้ายกัน สำหรับ Tcl console ให้ค้น help ของ engine ที่ติดตั้งก่อนใช้คำสั่ง report ใด ๆ หากไม่มี report เฉพาะ ให้ใช้ GUI/export หรือวิธีที่คู่มือรุ่นนั้นรองรับ พร้อมบันทึกสิ่งที่ยังตรวจไม่ได้

## 4.9 Step 7 — ตรวจ technology mapping

### A. ตรวจ reference resolution

1. เปิด cell-reference/cell-usage report
2. ตรวจว่า functional leaf cells resolve ไปยัง target Liberty
3. ตรวจ unresolved references เป็นศูนย์สำหรับ counter นี้
4. ตรวจว่าไม่มี generic arithmetic/behavioral placeholders ค้างใน final mapped representation
5. แยก hierarchical wrapper ออกจาก unresolved leaf cell; wrapper ที่เป็น module ไม่ได้แปลว่า mapping ล้มเหลว
6. แยก physical-only cells ที่อนุญาตตาม flow ออกจาก logic ที่ขาด timing model

สำหรับ Lab counter ไม่มี SRAM/IP black box จึงไม่ควรอ้าง “ตั้งใจเป็น black box” เพื่อผ่านเกณฑ์ ถ้ามี macro ในงานอื่น ต้องมี abstraction และ timing arcs ตาม contract แยกต่างหาก

### B. ตรวจ sequential logic

baseline ต้องมี storage เทียบเท่า 8 บิต ไม่มี unintended latch และใช้ rising-edge clock ตาม specification synchronous reset อาจถูก map เป็น synchronous-reset flop หรือเป็น mux/gate logic หน้า D pin ขึ้นกับ library และ optimization

Enable อาจเป็น feedback mux หรือ integrated enable flop ไม่จำเป็นต้องมี cell ชื่อ EN โดยตรง Incrementer อาจแตกเป็น XOR/AND/AOI/OAI หรือ adder-related cells จึงไม่ควรบังคับว่าต้องมี full adder จำนวนตายตัว

### C. ตรวจ connectivity และ observability

1. Trace clk ไปยัง clock pins ของ register ทุก state bit
2. Trace rst ไปยัง logic ที่ควบคุมการเป็นศูนย์ใน cycle ที่ reset ถูก sample
3. Trace en ไปยัง enable/feedback selection
4. Trace q ทั้ง 8 บิตกลับไปยัง storage
5. ตรวจ constant propagation: q ไม่ควรถูก tie เป็นศูนย์ทั้งหมด
6. ตรวจ combinational loops และ nets ที่ขาด driver
7. ถ้ามี clock-gating cell ปรากฏ ให้ตรวจว่าเป็นผลจาก setting ใด มี clock/test model และ constraints รองรับหรือไม่

การค้นข้อความใน netlist ช่วย triage แต่ไม่แทน library-link report เพราะชื่อ cell อาจไม่ใช้ prefix ที่เดาไว้ และ bus escaping อาจต่างจาก RTL

### D. ตรวจ area

รายงาน total mapped cell area พร้อมหน่วยและ library corner ที่ใช้คำนวณ ระบุว่าเป็นผลรวม area ของ cells ตาม library หรือ metric ใดของเครื่องมือ ไม่ใช้คำว่า die/core area แทน cell area

เปรียบเทียบ SV กับ VHDL ได้เมื่อ width, constraints, library, effort และ settings เหมือนกัน ผลไม่จำเป็นต้องตรงทุก instance เพราะ frontend/optimization อาจต่างกัน

**Checkpoint 4:** Mapping ผ่านทั้ง reference resolution, state-bit accounting และ connectivity ไม่ใช่ผ่านเพียง engine return code

## 4.10 Step 8 — สร้างหรืออัปเดต timing graph

1. ใช้ mapped design ที่ export จาก run นี้
2. ถ้าเปิด STA session แยก ให้โหลด netlist, matching Liberty, top และ SDC ของ run เดียวกัน
3. ตรวจ link และ timing graph warnings อีกครั้ง
4. ตรวจ clock mode: baseline pre-CTS มักใช้ ideal clock ตาม methodology ของ template
5. ระบุ wire delay เป็น zero-wire, wire-load, estimated RC หรือ physical estimate แบบใด
6. ตรวจ clock transition/latency และค่า default ที่ engine ใช้
7. Update timing ตาม flow แล้วบันทึก timing-model summary

อย่ากำหนด propagated clock เพื่อให้ดูเหมือน post-CTS หากยังไม่มี clock tree และ parasitic model ที่รองรับ คำว่า propagated ไม่สามารถสร้างข้อมูลทางกายภาพที่ยังไม่มีได้

## 4.11 Step 9 — ตรวจ timing coverage ก่อนดู WNS/TNS

coverage ต้องอ้างถึง “required checks ที่ถูกวิเคราะห์” ไม่ใช่จำนวนเส้นทางที่ report_timing พิมพ์ออกมา รายงาน top 10 paths ไม่ได้หมายความว่าวิเคราะห์เพียง 10 paths และการมี 100% ตาม metric ของเครื่องมืออาจยังซ่อน paths ที่ถูกตัดด้วย exceptions

### ตาราง coverage audit ของ counter

| กลุ่ม | เส้นทาง/การตรวจที่ต้องมี | หลักฐาน |
|---|---|---|
| Register-to-register | state Q → increment/enable/reset logic → D | max และ min timing paths |
| Input-to-register | en/rst → D หรือ synchronous control check ที่ library นิยาม | input delays และ path/check reports |
| Register-to-output | state Q → q port | output delays และ path reports |
| Clock coverage | clock ไปถึงทุก sequential clock pin | clock/register coverage report |
| Combinational integrity | ไม่มี combinational loop/undriven timing node | timing/design checks |
| Exceptions | ไม่มี false/multicycle/case analysis ที่ไม่ตั้งใจ | effective exception report |

Counter นี้ไม่มี input-to-output combinational path โดยหน้าที่ จึงบันทึก N/A พร้อม topology ไม่ต้องสร้าง fake constraint เพื่อให้ทุกหมวดมีเลขมากกว่าศูนย์

### ขั้นตรวจละเอียด

1. หา register ที่ไม่มี clock หรือ clock ไม่รู้จัก และแก้ให้เป็นศูนย์สำหรับ baseline
2. หา endpoints ที่ไม่มี required time หรือ missing input/output delays
3. ตรวจ missing min แยกจาก missing max
4. ตรวจ disabled timing arcs และเหตุผลว่าเกิดจาก library, case analysis หรือ exception
5. ตรวจ constants และ unused ports ว่าเกิดจาก specification จริง
6. ตรวจ setup/hold checks ที่ถูกตัดออก และ false-path collections ที่กว้างเกินไป
7. ยืนยัน q ทุกบิตได้รับ output constraint ไม่ใช่แค่บิตแรก
8. ยืนยัน rst และ en มี path/check ที่ตรงกับชนิด input
9. บันทึกชื่อ report category ตามเครื่องมือจริง ไม่เปลี่ยนชื่อ untested เป็น unconstrained โดยอัตโนมัติ

ถ้าใช้ coverage percentage ในเอกสาร ต้องระบุ numerator, denominator และประเภท checks เช่น setup checks ที่ทดสอบแล้ว/required setup checks หลังทบทวน exclusions แยก legitimate N/A, approved exception และ missing constraint ออกจากกัน ห้ามรวม exceptions เป็น “ตรวจผ่าน”

**Checkpoint 5:** ไม่มี unexplained unconstrained endpoints, no-clock registers หรือ ignored SDC objects และ exceptions ทั้งหมดมีเหตุผลราย object/path group

## 4.12 Step 10 — อ่าน setup timing report

เลือก worst register-to-register path หนึ่งเส้น และ input-to-register/output path อย่างละหนึ่งกลุ่มเท่าที่ topology มี ใช้รายงาน max/setup ตามชื่อที่ engine รองรับ

จด startpoint, endpoint, launch/capture clock, edge times, clock arrivals, cell/net delays, input slew, output load, uncertainty, setup requirement และ slack

สำหรับ register-to-register ขอบขาขึ้นหนึ่ง cycle ไม่มี exception และนิยาม skew = capture arrival − launch arrival:

```text
setup slack = Tperiod + skew − Tsetup − Usetup − Tcq,max − Tdata,max
```

ตัวอย่างเพื่อฝึกคำนวณ ไม่ใช่ผล TDI จริง:

| รายการ | ค่า ns |
|---|---:|
| Period | 10.00 |
| Skew | 0.00 |
| Tcq,max | 0.20 |
| Tdata,max | 8.90 |
| Tsetup | 0.30 |
| Usetup | 0.20 |
| Slack | +0.40 |

หาก skew เป็น +0.10 ns จะได้ +0.50 ns ภายใต้สมมติฐานเดิม รายงานจริงอาจมี derates, clock latency, edge conventions และ common-path pessimism removal จึงต้องคำนวณจาก arrival/required time ของรายงานก่อน แล้วจึงใช้สมการนี้ตรวจความเข้าใจ

สำหรับ input-to-register ใช้ input delay แทน launch flop Tcq และสำหรับ register-to-output ใช้ external output requirement แทน capture flop setup ห้ามนำสมการ reg-to-reg ไปแทนทุก path โดยไม่ปรับ boundary terms

### WNS/TNS และ path groups

WNS/TNS ต้องอ่านคู่กับนิยามของ engine และ grouping บางรายงานแสดง worst slack เป็นค่าบวกเมื่อผ่าน บาง metric แสดง worst negative slack เป็นศูนย์เมื่อไม่มี violation ส่วน TNS อาจรวม worst violation ต่อ endpoint หรือใช้กติกาอื่น ห้ามรวม top-N printed paths เองแล้วเรียกเป็น TNS โดยไม่อธิบาย

## 4.13 Step 11 — อ่าน hold/min timing report

เลือก short path จาก register ไปยัง register หรือ I/O path ที่มี hold requirement ตรวจว่ามี min-delay analysis จริง ไม่ใช่เปิด setup report ซ้ำ

```text
hold slack = Tcq,min + Tdata,min − Thold − Uhold − skew
```

ตัวอย่าง ideal clocks: Tcq,min=0.08 ns, Tdata,min=0.06 ns, Thold=0.10 ns, Uhold=0.05 ns และ skew=0 ให้ slack=−0.01 ns หาก skew=+0.10 ns จะกลายเป็น −0.11 ns ภายใต้สมมติฐานเดียวกัน

Positive skew ช่วย setup แต่ทำให้ hold ยากขึ้น การเพิ่ม period โดยทั่วไปไม่แก้ same-edge reg-to-reg hold violation จึงไม่ควรใช้การลดความถี่เป็นคำตอบอัตโนมัติของ hold

pre-layout hold อาจ optimistic จาก wire delay ต่ำหรือแตกต่างจาก post-CTS มาก ต้องบันทึก violation และ model ที่ใช้ แต่ยังไม่ใส่ buffer สุ่ม ๆ จนเพิ่ม area เพราะ final clock skew และ routing ยังเปลี่ยนได้ การแก้ hold ให้ทำตามขั้นตอนและ restrictions ของ flow

## 4.14 Step 12 — ตรวจ electrical constraints

ตรวจ max transition, max capacitance และ max fanout ตามข้อกำหนดที่ library/flow ใช้จริง รายงาน timing ผ่านไม่ได้แปลว่า design-rule constraints ผ่านทั้งหมด

1. หา driver ของ net ที่ slew/capacitance เกิน
2. ตรวจ output load ว่าหน่วยถูกต้อง
3. ตรวจ rst/en high fanout เมื่อขยาย width
4. ตรวจ clock load แยกจาก data load และบันทึกว่ายังไม่มี CTS
5. ถ้าระบบไม่รองรับการตรวจบางประเภท ให้บันทึก “ยังไม่ได้ตรวจ” พร้อมขั้นตอนที่จะตรวจภายหลัง

อย่าระบุว่า power ผ่านจากการที่ synthesis ไม่มี error หากไม่มี activity และ power methodology ที่เหมาะสม ค่า power estimate ก็ต้องระบุสมมติฐานแยกจาก Lab timing นี้

## 4.15 Step 13 — Negative test เพื่อพิสูจน์ coverage audit

ทำในสำเนา run เท่านั้น แล้วคืน baseline ก่อนส่งงาน เป้าหมายคือให้ขั้นตรวจพบปัญหา ไม่ใช่ให้ engine ต้องล้มเหลวทุกครั้ง เพราะบาง engine มี default constraints

### การทดลอง A: เอา output-delay constraints ออก

1. ทำสำเนา SDC เป็น counter_missing_output.sdc
2. เอา set_output_delay ทั้ง min/max ออก แต่คง load และ clock
3. รัน STA ด้วย settings อื่นเหมือน baseline
4. ตรวจ missing output-delay/unconstrained endpoint report
5. ถ้า report ไม่เตือน ให้ตรวจว่า tool ใส่ default หรือมี inherited constraints หรือไม่
6. ยืนยัน audit ยังระบุได้ว่า q ไม่มี explicit external timing contract

**ข้อสังเกตที่ต้องได้:** WNS ที่ดีขึ้นหลังลบ constraints ไม่ใช่หลักฐานว่าวงจรดีขึ้น เพราะปัญหาและจำนวน checks ที่ถูกวิเคราะห์เปลี่ยนไป

### การทดลอง B: ใส่ชื่อ input ผิด

เปลี่ยน en เป็น enable_typo ในสำเนา SDC รันโหลด constraints แล้วเก็บ empty collection/object-not-found evidence ตรวจว่า flow หยุดหรือ audit ตรวจพบ ถ้าเครื่องมือเงียบ ต้องเพิ่ม object-count review ในขั้นตอนตรวจรับ

### การทดลอง C: ลด period เพื่อศึกษาความไว

สร้างอีก run ที่ period 5 ns โดยคง I/O delays และ assumptions เดิม เปรียบเทียบ setup slack, mapped area และ cell usage ถ้ารัน synthesis ใหม่ เครื่องมืออาจเปลี่ยน netlist จึงไม่คาดหวังว่า slack ลดลงเท่ากับ 5 ns พอดี

หากต้องการแยกผลของ constraints อย่างเดียว ให้ใช้ netlist เดิมแล้วเปลี่ยน period ใน STA session โดยระบุว่าเป็น fixed-netlist experiment อย่าบิดความหมายของ external interface เพื่อทำให้ผ่าน

**Checkpoint 6:** แสดงหลักฐานอย่างน้อยหนึ่งกรณีว่า audit ตรวจ missing/incorrect constraint ได้ และ baseline ถูกกู้กลับครบ

## 4.16 Step 14 — เปรียบเทียบ VHDL และ SystemVerilog

รันแยกสอง projects ด้วย WIDTH=8, synchronous reset, Liberty, corner, SDC, effort และ settings เดียวกัน ตรวจ RTL simulation ของทั้งสองให้ผ่านก่อนใช้ผลเปรียบเทียบ

| Metric | SV | VHDL | การตีความ |
|---|---|---|---|
| State bits | กรอก | กรอก | คาดเทียบเท่า 8 บิต |
| Unresolved leaf refs | กรอก | กรอก | ต้องเป็น 0 |
| Unintended latch | กรอก | กรอก | ต้องเป็น 0 |
| Mapped cell area/units | กรอก | กรอก | ไม่ใช่ core area |
| Worst setup slack/group | กรอก | กรอก | ต้องใช้ model เดียวกัน |
| Worst hold slack/group | กรอก | กรอก | ตรวจ min constraints ด้วย |
| Unexplained coverage gaps | กรอก | กรอก | ต้องเป็น 0 |
| Electrical violations | กรอก | กรอก | ระบุ category |

ผล area/timing ใกล้กันไม่ได้พิสูจน์ functional equivalence หากมี equivalence tool ที่ licensed และรองรับ flow ให้ใช้ตาม reference methodology มิฉะนั้นให้ระบุหลักฐานว่าเป็น RTL simulation, mapped-netlist simulation หรือการตรวจโครงสร้างชนิดใด ห้ามเรียก simulation ว่า formal proof

## 4.17 ทางเลือก — ใช้ asynchronous reset จาก Lab 2

สำหรับ counter N=4, rst_n active-low asynchronous ให้รักษา RTL เดิมและปรับ constraint review ดังนี้:

1. ตรวจ mapping ว่า async reset polarity และ function ถูกต้อง อาจมี inversion ตาม library
2. ตรวจ clear/reset arcs และ recovery/removal models ใน Liberty
3. ตกลง reset source, deassertion behavior และ clock-domain relationship ก่อนกำหนด timing exceptions
4. ถ้าเป็น external asynchronous reset จริง การรับรอง reset release ต้องมี architecture เช่น asynchronous assert/synchronous deassert และ reset distribution ที่เหมาะสม ไม่ใช้ SDC บรรทัดเดียวแทนสถาปัตยกรรม
5. ถ้าใช้ synchronized reset release ให้ตรวจ timing จาก synchronizer stage สุดท้ายไปยัง reset pins รวม recovery/removal ตาม methodology
6. ระบุจุดที่ได้รับ waiver และ checks ที่ยังต้องทำในขั้น post-CTS/post-route
7. ให้ en และ q มี min/max I/O contract เช่นเดิม แต่ q มีเพียง 4 บิต

ห้าม blanket false path จาก rst_n แล้วรายงานว่า reset timing ผ่าน เพราะ recovery/removal หรือ checks อื่นอาจถูกตัดออกตาม exception semantics ของ engine ต้องดู effective exceptions และ coverage หลัง apply จริง

การปล่อย rst_n ห่างจาก clock edge ใน testbench ช่วยหลีกเลี่ยง simulation race แต่ไม่ได้พิสูจน์ reset release ของชิปจริง สำหรับ Lab 4 baseline จึงใช้ synchronous reset เพื่อฝึก coverage โดยไม่ซ่อนปัญหา reset architecture

## 4.18 Troubleshooting

| อาการ | สิ่งที่ต้องตรวจ | วิธีจัดการ |
|---|---|---|
| Cell count เป็นศูนย์หรือน้อยผิดปกติ | top, output observability, case analysis | แก้ input/setup แล้วรันใหม่ |
| Generic cells ค้าง | mapping stage, target library, unsupported operators | ยืนยันว่า export หลัง map และ cell functions มีพร้อม |
| Unknown cell ใน STA | library release, missing Liberty, naming | โหลด matching timing view และ relink |
| Missing module เฉพาะ VHDL | logical library, architecture binding | ตรวจ compile order และ work mapping |
| No clock registers | clock port/collection, graph connectivity | ตรวจ source และ clock pin trace |
| Unconstrained q บางบิต | wildcard/bus syntax | ตรวจ expanded collections ทุกบิต |
| Setup ดีผิดปกติ | false paths, no output delays, constants | audit coverage ก่อนเชื่อ WNS |
| rst ไม่มี timing path | reset semantics, exceptions, case analysis | ตรวจ sync/async classification และ checks |
| Huge output delay/load | units หรือ external contract | ตรวจหน่วยและที่มาค่า |
| Hold fail เมื่อเพิ่ม frequency แล้วไม่ดีขึ้น | same-edge hold, min model, skew | วิเคราะห์ minimum path; ไม่แก้ด้วย period อย่างเดียว |
| SV/VHDL area ต่างมาก | width/reset/effort ไม่เท่ากัน | ทำ configuration ให้เท่ากันก่อนสรุป |
| Results ไม่เปลี่ยนหลังแก้ SDC | cached session, path เก่า, failed reload | เปิด clean run และตรวจ effective constraints |

## 4.19 รายการส่งมอบ

1. RTL และ source manifest พร้อม hashes ของไฟล์ที่ใช้
2. Project configuration และ generated/exported scripts ของรุ่นที่ใช้งาน
3. Input SDC และ effective/exported constraints ถ้าเครื่องมือรองรับ
4. Mapped netlist และ database/checkpoint ที่เปิดซ้ำได้
5. Elaboration/design checks, cell-reference/mapping และ area reports
6. Clock report, constraint/exception report และ coverage audit
7. Setup/max และ hold/min reports โดยระบุ path groups และ corner
8. Electrical-constraint report หรือข้อจำกัดหากยังตรวจไม่ได้
9. Negative-test evidence และตารางเทียบกับ baseline
10. Run summary ที่แยกผลวัดจริง สมมติฐาน และสิ่งที่ยังไม่ตรวจ

### แม่แบบ Run Summary

```text
Run ID / date:
Tool / build / synthesis & STA engine:
RTL language / top / width / reset contract:
Source and SDC hashes:
PDK / standard-cell release:
Liberty files / PVT / RC or wire-delay model:
Time and capacitance units:
Clock period / uncertainty / clock mode:
Mapped state bits / cell instances / cell area and units:
Unresolved references / unintended latches / structural errors:
Worst setup slack / group / corner:
Worst hold slack / group / corner:
Timing coverage gaps and approved exclusions:
Electrical violations:
Negative-test finding:
Status: PASS / FAIL / CONDITIONAL (explain):
Known limitations / next action:
```

ไม่กรอกค่าจากตัวอย่างคำนวณในหัวข้อ 4.12–4.13 เป็นผล run จริง และไม่ใช้ N/A แทน “ยังไม่ได้ตรวจ”

## 4.20 เกณฑ์ผ่านและการส่งต่อ

| หมวด | เกณฑ์ตรวจรับ |
|---|---|
| Reproducibility | เปิด project/checkpoint และระบุ inputs/settings ของ run ได้ |
| Elaboration | top/width/reset ตรง specification ไม่มี unresolved design references |
| Mapping | logic mapped ไปยัง target library; state accounting ถูกต้อง ไม่มี unintended latch |
| Structural integrity | ไม่มี unexplained undriven/multiple-driver/loop issues |
| Coverage | ไม่มี unexplained unclocked registers, missing min/max boundary constraints หรือ ignored collections |
| Exceptions | ทุก exception มี scope และเหตุผลตรวจสอบได้ |
| Timing | setup/hold ถูกตรวจแยกและรายงาน violation ตามจริง |
| Negative test | ตรวจพบ constraint ที่ถูกนำออกหรืออ้าง object ผิด |
| Handoff | netlist, constraints, library manifest และ limitations ครบ |

แยกสถานะ **Lab competency PASS** ออกจาก **design readiness**: ผู้เรียนอาจวิเคราะห์ violation ได้ถูกต้องจนผ่านการเรียนรู้ แต่ design ยังต้อง FAIL หรือ CONDITIONAL ตามเกณฑ์ส่งต่อของโครงการ การส่งต่อเพื่อศึกษาต่อทำได้เมื่อระบุ blocker ชัด ไม่ใช้คำว่า timing-clean หากยังมี violation หรือยังมี coverage gap

หลัง Lab นี้ ขั้น floorplan/placement ต้องใช้ netlist และ constraints ชุดที่ตรวจแล้ว ตรวจ matching physical abstracts เพิ่มเติม และรัน STA ใหม่ตาม physical/RC estimates ที่ดีขึ้น หลัง CTS ต้องทบทวน skew, insertion delay และ hold อีกครั้ง และหลัง route ต้องใช้ extracted parasitics ตาม flow ที่ยอมรับ

## 4.21 คำถามท้าย Lab

1. เหตุใด synthesis completed จึงไม่ยืนยันว่า mapping ถูก library?
2. เหตุใด clock report มีหนึ่ง clock จึงยังไม่พิสูจน์ clock coverage ครบ?
3. synchronous reset กับ asynchronous reset ต้องตรวจ timing ต่างกันอย่างไร?
4. เหตุใดการลบ output delay อาจทำให้ WNS ดีขึ้นโดยวงจรไม่ได้เปลี่ยน?
5. multi-bit flop ทำให้จำนวน cell instances ต่างจาก state bits อย่างไร?
6. หากลด period แล้ว resynthesize เหตุใด slack อาจไม่ลดลงตาม period ตรง ๆ?
7. ความต่างระหว่าง zero unconstrained endpoints กับ complete timing contract คืออะไร?
8. pre-layout hold-clean ยังมีข้อจำกัดใดเมื่อสร้าง clock tree จริง?

แนวคำตอบสำคัญ: ต้องตรวจ target references, clock ถึงทุก sequential pin, reset checks ตาม semantics, external boundary contract และ effective exceptions รวมถึงระบุ parasitic/clock model ทุกครั้ง ตัวเลข slack มีความหมายเมื่อ model และ coverage ถูกต้องเท่านั้น

## 4.22 เอกสารอ้างอิงและการใช้งาน

[1] Siemens — Digital Implementation / Digital Implementer: https://www.siemens.com/en-gb/products/ic/ic-custom/ams/digital-implementer/ ใช้ยืนยันขอบเขตผลิตภัณฑ์และ engines ไม่ใช้แทน command reference ของรุ่นที่ติดตั้ง

[2] Intel — Timing Analyzer, Input Constraints (set_input_delay): https://www.intel.com/content/www/us/en/docs/programmable/683243/25-1/input-constraints-set-input-delay.html ใช้อธิบายหลัก SDC input-delay semantics เท่านั้น ไม่ใช่ Tcl API reference ของ TDI

[3] เอกสารติดตั้งจริงในห้องปฏิบัติการ: TDI User Guide, synthesis/STA engine command reference, release notes, PDK integration guide และ reference-template README ให้ผู้สอนกรอกชื่อ revision และ path ที่ได้รับอนุญาตก่อนแจกคู่มือ

สถานะเอกสาร: คู่มือขั้นตอนและตัวอย่าง constraints; ยังไม่ได้รันกับ TDI/PDK ของห้องปฏิบัติการในงานเขียนนี้ ตัวเลขในตัวอย่าง timing เป็นโจทย์คำนวณ ไม่ใช่ benchmark หรือผล sign-off
