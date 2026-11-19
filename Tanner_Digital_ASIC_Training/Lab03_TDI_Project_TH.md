# Lab 3 — TDI Project: ตั้งค่า top, source, library, technology และ SDC
## คู่มือปฏิบัติ Tanner Digital Implementer สำหรับผู้เริ่มต้นถึงระดับกลาง

เวลาแนะนำ: 2–3 ชั่วโมง  
ผลลัพธ์: โปรเจกต์ counter ที่บันทึกและเปิดซ้ำได้ อ่าน RTL/elaborate ได้ และโหลด technology/library/constraints ได้ถูกต้อง พร้อมหลักฐานการตรวจสอบก่อนเริ่ม implementation

> ขอบเขต: Lab นี้เตรียม digital block สำหรับ analog-on-top ยังไม่ใช่การออกแบบ pad ring หรือการรับรอง sign-off ผู้เรียนต้องใช้ PDK และ reference template ที่รองรับ TDI รุ่นที่ติดตั้งจริง ตัวอย่างชื่อไฟล์และชื่อหน้าการตั้งค่าในบทนี้เป็นคำอธิบายหน้าที่ ไม่ใช่ชื่อเมนูที่รับรองว่าตรงกันทุกรุ่น

## 3.1 วัตถุประสงค์

เมื่อจบ Lab ผู้เรียนต้องสามารถ:

1. สร้างโปรเจกต์จาก setup wizard หรือสำเนา reference project โดยเก็บต้นฉบับไว้
2. แยก design source, simulation source, logical library และ physical library
3. ระบุ top entity/module และตรวจ hierarchy/port/parameter ได้
4. จับคู่ Liberty, cell LEF, technology LEF, RC technology และ layout views ของชุดที่เข้ากัน
5. โหลด SDC และตรวจว่ามี clock, I/O constraints และไม่มี endpoint ที่หลุดโดยไม่อธิบาย
6. แสดงหลักฐานว่า run ใช้ไฟล์ที่ตั้งใจเลือกจริง ไม่ใช่เพียงแสดงหน้าจอ wizard ที่กรอกครบ

Siemens อธิบาย Digital Implementer ว่าเป็น flow ที่เริ่มจาก wizard ใน L-Edit พร้อม Tcl customization สำหรับ RTL-to-GDSII การตั้งค่าที่ครบจึงต้องครอบคลุมทั้งข้อมูล logic, physical และ timing ไม่ใช่เลือก RTL อย่างเดียว [1]

## 3.2 สิ่งที่ต้องเตรียม

| รายการ | สิ่งที่ต้องยืนยัน |
|---|---|
| L-Edit/TDI | รุ่น, build, engine ที่ template เรียกใช้ และ license ผ่านตาม Lab 1 |
| Reference template | ระบุแหล่งที่มา รุ่นเครื่องมือและ PDK ที่รองรับ และผล reference run |
| RTL | counter ที่ผ่าน self-checking test จาก Lab 2 หรือใช้ตัวอย่างในบทนี้ |
| Timing library | Liberty ที่อนุญาตใช้กับ operating voltage/corner ของงาน |
| Physical abstracts | technology LEF และ cell LEF ที่เข้ากับ timing library |
| RC technology | ชุดข้อมูล extraction ที่ engine/template รองรับ |
| Layout views | OA/GDS/OASIS และ layer mapping ตาม release ของ PDK |
| Constraints | SDC ของ block นี้ พร้อมนิยามหน่วยและ external timing contract |
| Run environment | working directory, host, สิทธิ์อ่านไฟล์ และพื้นที่จัดเก็บ |

ห้ามถือว่า PDK ที่เปิดดู layout ใน L-Edit ได้แล้ว จะพร้อมใช้ digital implementation โดยอัตโนมัติ ต้องมี standard-cell views และ technology setup ที่ flow รองรับด้วย

### ข้อมูลประจำการทดลอง

ให้บันทึกก่อนเริ่ม:

```text
Project: lab03_counter_sv หรือ lab03_counter_vhdl
Tool version/build:
Engine/version from run log:
Template name/version/path:
PDK name/release/metal stack:
Standard-cell library/release:
Timing corner:
RC corner:
RTL language/version:
Implementation top: counter
Width: 8
Clock: clk, 10 ns
Reset: rst, synchronous active-high
Power/ground: ใช้ชื่อจริงตาม template
```

ค่า period 10 ns เป็นโจทย์การสอน ไม่ใช่คำรับรองว่า technology ใดจะทำ timing ได้

## 3.3 โครงสร้างโปรเจกต์ที่แนะนำ

สร้าง directory ต่อไปนี้ภายใต้พื้นที่ทำงานของผู้เรียน โดยไม่แก้ไข directory ติดตั้ง PDK:

| Directory | เนื้อหา |
|---|---|
| rtl/sv | counter.sv หรือ counter.v |
| rtl/vhdl | counter.vhd |
| tb | testbench สำหรับ simulation เท่านั้น |
| constraints | counter.sdc |
| project | project setup ที่บันทึกจาก wizard |
| scripts | Tcl ที่ export/generated และ customization ที่รองรับ |
| runs | ผลการรัน แยกตามชื่อ run |
| reports | รายงานสรุปและหลักฐาน |
| docs | README, manifest และ known limitations |

เริ่มด้วยโปรเจกต์ภาษาเดียวต่อหนึ่ง run เพื่อให้วิเคราะห์ปัญหาได้ง่าย ใช้สองโปรเจกต์แยกกันสำหรับเทียบ VHDL กับ SystemVerilog อย่าเพิ่ม RTL ทั้งสองภาษาเป็น design เดียวโดยไม่กำหนด mixed-language binding ให้ชัดเจน

## 3.4 Reference RTL ที่มี interface เดียวกัน

ถ้าใช้ RTL จาก Lab 2 ให้คงชื่อพอร์ตและ reset contract ของไฟล์จริง และปรับ SDC ให้ตรงกัน ตัวอย่างด้านล่างเป็น design อิสระสำหรับสาธิตการตั้งค่า ไม่ได้สมมติว่าชื่อพอร์ตเหมือน Lab 2

### A. SystemVerilog — rtl/sv/counter.sv

```systemverilog
module counter #(
  parameter int unsigned WIDTH = 8
) (
  input  logic             clk,
  input  logic             rst,
  input  logic             en,
  output logic [WIDTH-1:0]  q
);
  always_ff @(posedge clk) begin
    if (rst)
      q <= '0;
    else if (en)
      q <= q + 1'b1;
  end
endmodule
```

ใช้ WIDTH >= 1 เท่านั้น สำหรับ Lab นี้คงค่า 8 และยืนยันผล elaboration ว่า q กว้าง 8 บิต ไม่ต้องใส่ testbench หรือ delay ใน source สำหรับ synthesis

### B. Verilog-2001 — rtl/sv/counter.v

```verilog
module counter #(
  parameter WIDTH = 8
) (
  input wire clk,
  input wire rst,
  input wire en,
  output reg [WIDTH-1:0] q
);
  always @(posedge clk) begin
    if (rst)
      q <= {WIDTH{1'b0}};
    else if (en)
      q <= q + 1'b1;
  end
endmodule
```

เลือก counter.sv หรือ counter.v เพียงไฟล์เดียวต่อโปรเจกต์ เพราะทั้งสองประกาศ module ชื่อ counter เหมือนกัน

### C. VHDL — rtl/vhdl/counter.vhd

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
  generic (WIDTH : positive := 8);
  port (
    clk : in  std_logic;
    rst : in  std_logic;
    en  : in  std_logic;
    q   : out std_logic_vector(WIDTH-1 downto 0)
  );
end entity counter;

architecture rtl of counter is
  signal count_reg : unsigned(WIDTH-1 downto 0);
begin
  process (clk)
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
end architecture rtl;
```

counter คือ implementation top; rtl คือ architecture ที่ต้อง bind หากเครื่องมือให้เลือก อย่าสับสน VHDL logical library เช่น work กับ standard-cell technology library

ทั้งสามแบบมี synchronous reset: rst มีผลเมื่อเกิด rising edge เท่านั้น จึงกำหนด timing ของ rst เป็น synchronous input ใน SDC ไม่ใช่ false path แบบ asynchronous reset

## 3.5 Step 1 — เลือกวิธีเริ่มโปรเจกต์

### วิธี A: เริ่มจาก reference project ที่เคยรันผ่าน

1. เปิด reference project ที่ตรงกับรุ่นเครื่องมือ, PDK และ metal stack
2. ตรวจว่า reference ใช้ standard-cell family และ supply ที่ต้องการ
3. ทำสำเนาเป็นชื่อ lab03_counter_sv หรือ lab03_counter_vhdl
4. เปลี่ยน working/run directory ให้เป็นของผู้เรียน
5. ตรวจรายการ source, top, SDC และ output cell ที่ติดมาจากตัวอย่าง
6. เก็บ technology settings ที่ผ่านการตรวจแล้ว แต่ทบทวนว่ามี setting ของ reference design ค้างอยู่หรือไม่

ระวัง inherited settings เช่น top เก่า, DEF floorplan เก่า, macro placement, pin constraints, scan/UPF options และ SDC ที่อ้างพอร์ตของตัวอย่างเดิม การคัดลอกโปรเจกต์ไม่แปลว่าค่าทุกตัวนำมาใช้กับ counter ได้

### วิธี B: สร้างผ่าน setup wizard

1. เปิด L-Edit ใน environment ที่ผ่าน Lab 1
2. เปิดช่องทาง Digital Implementer/project setup ของรุ่นที่ติดตั้ง โดยดู installed Help หรือ training reference
3. สร้าง project/run directory ใหม่
4. เลือก technology/reference configuration ที่ผู้สอนเตรียมไว้
5. กรอกข้อมูล design, libraries, technology และ timing ตามขั้นตอนถัดไป
6. บันทึก project ก่อนเริ่มรัน และบันทึก summary ของค่าที่เลือก

ชื่อ toolbar อาจเป็นชื่อ Digital Implementer หรือชื่อ engine ใน release เก่า ให้ใช้คู่มือรุ่นที่ติดตั้ง ไม่แทนที่ด้วยเมนู Aprisa หรือเครื่องมืออื่นโดยคาดเดา

**Checkpoint 1:** ระบุได้ว่า project setup อยู่ที่ใด และ run จะเขียนผลที่ใด โดยไม่ทับ reference

## 3.6 Step 2 — ตั้ง working directory และเส้นทางไฟล์

1. กำหนด project root ที่ชื่อเรียบง่าย และไม่มีไฟล์ผลลัพธ์จากงานอื่นปะปน
2. เลือก path แบบ absolute สำหรับ shared PDK และแบบ relative สำหรับ RTL/SDC หาก project รองรับ
3. ตรวจว่า engine ที่รันจริงสามารถอ่าน path นั้นได้
4. หาก GUI กับ engine อยู่คนละเครื่อง ให้ตรวจ path mapping และสิทธิ์ที่ฝั่ง engine
5. หลีกเลี่ยงการสมมติว่า Windows path หรือ WSL path จะใช้กับ Linux engine ได้โดยตรง
6. บันทึก resolved paths ที่ปรากฏใน log หรือ generated setup

ตัวอย่าง: GUI เห็นไฟล์ C:/training/lab03/rtl/counter.sv แต่ engine บน Linux ต้องมี path ที่เข้าถึงไฟล์เดียวกันได้จริง การ browse ไฟล์สำเร็จที่ GUI จึงยังไม่ยืนยันว่า remote run อ่านได้

**Checkpoint 2:** ไม่มี file-not-found หรือ permission-denied และ log แสดงไฟล์ที่ตั้งใจใช้

## 3.7 Step 3 — เพิ่ม source และกำหนดภาษา

1. เพิ่มเฉพาะ source สำหรับ hardware implementation
2. สำหรับ SV เลือก SystemVerilog mode ที่ frontend รองรับ อย่าพึ่งนามสกุลไฟล์อย่างเดียว
3. สำหรับ Verilog ใช้ Verilog-2001 หรือ mode ที่รองรับ syntax ในไฟล์
4. สำหรับ VHDL เลือก standard ที่ frontend รองรับ และ mapping ของ logical library
5. ถ้ามี package ให้เรียง package ก่อน entity/module ที่เรียกใช้
6. กำหนด include directories และ defines ตาม design จริง
7. ตัด testbench, simulation-only models และ behavioral delay ออกจาก synthesis source set
8. ตรวจว่าไม่มี module/entity ซ้ำจากสำเนาเก่า

สำหรับ counter ตัวอย่างไม่มี include หรือ user package เพิ่ม ไม่ต้องใส่ defines เพื่อเลียนแบบ reference design โดยไม่มีเหตุผล

| Source group | รวมในการ synthesis หรือไม่ |
|---|---|
| counter.sv / counter.v / counter.vhd | รวม โดยเลือกหนึ่ง implementation |
| tb_counter.* | ไม่รวม |
| cell functional simulation models | โดยทั่วไปไม่ใช่ RTL source; ใช้ตาม flow ที่ระบุ |
| SRAM macro | ใช้ views/black box ตาม integration flow ไม่แทนด้วย model ที่มี delay |
| SDC | โหลดในส่วน timing constraints ไม่ใช่ HDL source |

## 3.8 Step 4 — ตั้ง top และตรวจ elaboration

1. ตั้ง top เป็น counter ด้วยตัวพิมพ์ที่ตรงกับ Verilog/SV
2. VHDL ให้เลือก entity counter และ architecture rtl หากมีหลาย architecture
3. คง WIDTH=8 หรือระบุ override ในช่องที่ template รองรับ
4. รัน analyze/elaborate หรือขั้นเทียบเท่าของ reference flow
5. เปิด hierarchy/port summary และอ่าน log

ผลที่ต้องตรวจ:

- Top คือ counter ไม่ใช่ tb_counter
- มี input clk, rst, en และ output q กว้าง 8 บิต
- ไม่มี unresolved reference, duplicate definition หรือ unintended black box
- ไม่มี latch จาก RTL นี้
- state ที่เป็น counter มี 8 บิตก่อน optimization ทั้งนี้จำนวน mapped cells อาจต่างจากจำนวน RTL bits
- ไม่มี gated clock ที่สร้างจาก combinational expression

หาก GUI ไม่มีปุ่ม elaborate แยก ให้ใช้ earliest synthesis/import stage ที่ template รองรับและตรวจผลส่วนนั้น ไม่สร้างคำสั่ง TDI ขึ้นเอง

**Checkpoint 3:** แนบ hierarchy summary และบรรทัดที่ยืนยัน top/parameter/language

## 3.9 Step 5 — เลือก timing library

1. เริ่มจากชุด Liberty ที่ reference flow ใช้สำเร็จกับ PDK release เดียวกัน
2. เลือก standard-cell family/threshold-voltage ตามโจทย์
3. ระบุ PVT corner และ operating voltage/temperature
4. ตรวจหน่วย time, capacitance และ resistance ที่เกี่ยวข้อง
5. ตรวจว่ามี sequential cell สำหรับ implementation ของ counter
6. ตรวจ dont-use/allowed-cell policy ที่ template ตั้งไว้
7. หากใช้หลาย corner ให้บันทึก library set ที่ใช้แต่ละ analysis view ตาม flow จริง

อย่าเพิ่มทุก .lib ใน directory โดยอัตโนมัติ เพราะอาจมีชื่อ cell ซ้ำหลาย corner หรือคนละ variant และทำให้ library binding ไม่ตรงความตั้งใจ

### ความหมายของ library ที่ต้องแยก

| คำว่า library | หน้าที่ |
|---|---|
| VHDL work/logic library | จัดเก็บ design units ระหว่าง compile |
| Liberty timing library | function, timing, transition/capacitance และข้อมูล power |
| Cell LEF library | ขนาด cell, pin geometry, obstruction และ site |
| OA/layout library | layout view สำหรับดูและประกอบ design |
| Simulation library | model ของ cell สำหรับ netlist simulation |

การเลือก OA library ถูกต้องไม่ได้ยืนยันว่า Liberty หรือ LEF ถูกชุด ต้องตรวจแต่ละ view แยกกัน

## 3.10 Step 6 — เลือก technology และ physical views

ตั้งค่าตามชุด reference ที่รองรับ ห้ามแทนไฟล์ด้วยของ process อื่นเพราะชื่อใกล้เคียงกัน

1. โหลด technology LEF หรือ technology setup ที่ template กำหนด
2. โหลด cell LEF หลังจาก technology definitions ตามลำดับที่ flow ต้องการ
3. เลือก RC technology เช่น ITF/PTF หรือรูปแบบที่ engine รองรับจริง
4. ตรวจ metal stack, routing layers, via definitions และ database units
5. ตรวจ site name/row height กับ cell LEF
6. ตรวจ power/ground pin names และ global-net mapping
7. ตรวจ layout view mapping และ layer map สำหรับ import/export
8. ยืนยันว่ามี physical views ของ cells ที่ flow อาจแทรก เช่น buffer, clock cell, tie, filler, tap และ endcap ตามข้อกำหนด PDK

### ตารางจับคู่ที่ผู้เรียนต้องกรอก

| ข้อมูล | ไฟล์/ชื่อที่เลือก | หลักฐาน |
|---|---|---|
| Liberty | ระบุ path และ corner | library summary |
| Cell LEF | ระบุ path/release | macro/site/pin summary |
| Technology LEF/setup | ระบุ path/stack | layer/via summary |
| RC technology | ระบุ path/corner | load log |
| Layout library | ระบุ OA/GDS mapping | view availability |
| Power/ground | ชื่อ net และชื่อ cell pin | global connection policy |

Timing corner และ RC corner เป็นคนละมิติ อย่าใช้คำว่า slow เพียงคำเดียวแทนทั้งสองอย่าง การจับคู่ worst setup/hold ต้องเป็น analysis view ที่ flow/PDK รองรับ ไม่ใช่เลือกจากชื่อไฟล์อย่างเดียว

**Checkpoint 4:** ไม่มี missing LEF macro, unknown layer/site หรือ undefined via; ชื่อ cell/pin ในแต่ละ view สอดคล้องกัน

## 3.11 Step 7 — เตรียม SDC ที่ตรงกับ interface

ตัวอย่างนี้กำหนด synchronous interface แบบหนึ่ง clock และใช้ rst synchronous active-high ค่า I/O เป็นโจทย์ฝึก ไม่ใช่ค่าจาก board หรือระบบจริง

ก่อนใช้ต้องยืนยันว่า timing engine ใช้หน่วย ns และ pF ตัวเลข set_load จะตีความตาม capacitance unit ของ library/engine ห้ามสมมติหน่วยจากข้อความ comment อย่างเดียว

ไฟล์ constraints/counter.sdc:

```tcl
# Teaching contract: verify engine/library time=ns, capacitance=pF.
# Interface: clk, rst, en, q[7:0]; synchronous active-high reset.

create_clock -name core_clk -period 10.000 [get_ports clk]

set_clock_uncertainty -setup 0.200 [get_clocks core_clk]
set_clock_uncertainty -hold  0.050 [get_clocks core_clk]

set_input_delay  -clock core_clk -max 2.000 [get_ports {rst en}]
set_input_delay  -clock core_clk -min 0.200 [get_ports {rst en}]

set_output_delay -clock core_clk -max 2.000 [get_ports {q*}]
set_output_delay -clock core_clk -min 0.000 [get_ports {q*}]

set_input_transition 0.100 [get_ports {rst en}]
set_load 0.020 [get_ports {q*}]
```

### อธิบายทีละส่วน

- create_clock สร้าง clock constraint ไม่ได้สร้างวงจร clock หรือ clock port ใหม่
- Period 10 ns เท่ากับ 100 MHz ภายใต้หน่วย ns
- Setup/hold uncertainty แยกกันเพื่อไม่ใช้ margin โดยไม่ตั้งใจ
- Input delay -max และ -min ระบุขอบเขต arrival จาก external launching logic
- rst เป็น synchronous input จึงต้องมี timing contract เหมือน en
- Output delay สะท้อน requirement ของ external receiving logic รวม board/interconnect ตาม boundary ที่ตกลงกัน
- ตัวอย่าง -min 0.000 เป็นสมมติฐานฝึก ค่า hold ภายนอกจริงอาจทำให้ต้องใช้ค่าติดลบตามนิยาม SDC
- set_load 0.020 เท่ากับ 20 fF เฉพาะเมื่อหน่วย capacitance เป็น pF
- clk ไม่อยู่ในรายการ data input delay; source clock waveform/transition ให้กำหนดตาม clock-model policy ของ template
- q* ต้อง resolve ได้ output 8 บิตหรือรูปแบบ bus collection ที่เทียบเท่าของ engine ต้องตรวจสมาชิกจริง

การใช้ pattern ครอบ q อาจขึ้นกับชื่อพอร์ตหลัง elaboration หาก match ไม่ครบให้ใช้ชื่อ bus ที่ engine แสดงพร้อม Tcl braces เช่น {q[0]} เพื่อหลีกเลี่ยง Tcl command substitution ตรวจ membership ก่อนใช้ อย่าแก้จน warning หายโดยขยาย pattern ครอบพอร์ตที่ไม่เกี่ยวข้อง

### เหตุใดไม่ใช้ false path กับ reset

RTL นี้ sample rst ที่ clock edge การ false-path rst จะซ่อน timing ของ synchronous reset และอาจทำให้ผล STA ดูดีโดยไม่ตรงการทำงานจริง หากเปลี่ยนเป็น asynchronous reset ต้องเปลี่ยนทั้ง RTL, TB, release contract และ treatment ของ recovery/removal รวมถึง synchronous deassertion ตาม architecture ไม่ใช่เพียงเพิ่ม set_false_path

### สิ่งที่ยังไม่ควรใส่

ไม่ใส่ multicycle, false path, generated clock หรือ propagated-clock setting โดยคัดลอกจากงานอื่น หาก template มีข้อกำหนด pre-CTS/post-CTS ให้ใช้ stage policy นั้น การสร้าง constraint จาก wizard และโหลด SDC ซ้ำอาจสร้าง clock ซ้ำหรือทับค่า ต้องเลือกแหล่ง timing หลักให้ชัดเจน

## 3.12 Step 8 — โหลด SDC และตรวจว่ามีผลจริง

1. เลือก counter.sdc ในส่วน timing ของ project setup
2. ถ้ามี wizard-generated clock ให้ตรวจและป้องกันความซ้ำซ้อนกับไฟล์ SDC
3. ตรวจ stage ที่ flow อ่าน SDC ว่าเป็น design ที่มีชื่อพอร์ตตรงกับ constraint
4. เริ่ม validation/import/elaboration ตาม reference flow
5. ตรวจ log ว่าอ่าน SDC path ที่ถูกต้อง
6. ตรวจ clock summary: core_clk, 10 ns และ source clk
7. ตรวจ input/output delay, load และ uncertainty ใน report
8. ตรวจ timing coverage: ไม่มี data endpoint ที่ unconstrained โดยไม่อธิบาย
9. แยก missing constraint ออกจาก violation และแยก empty collection ออกจาก syntax error

ตัวอย่าง diagnostic Tcl ต่อไปนี้ใช้แนว SDC ทั่วไป ให้ใช้เฉพาะเมื่อ command help ของ engine รองรับ:

```tcl
get_ports *
get_clocks *
get_ports {rst en}
get_ports {q*}
```

ชื่อคำสั่งรายงาน timing/check constraints ให้เปิด Help ของ engine รุ่นจริง บทนี้ไม่ถือว่า report_* ของ OpenSTA, PrimeTime หรือเครื่องมืออื่นใช้กับ TDI ได้ทั้งหมด

**Checkpoint 5:** SDC parse ผ่าน, collection ไม่ว่าง, clock ถูกต้อง และมี coverage report การเห็นไฟล์อยู่ใน project tree ยังไม่เพียงพอ

## 3.13 Step 9 — ทบทวนค่าที่ inherited จาก template

ก่อนกด run ให้ตรวจ:

| Setting | สิ่งที่ต้องทำ |
|---|---|
| Top/source | เปลี่ยนจาก design ตัวอย่างเป็น counter |
| Parameters/generics | WIDTH=8 |
| SDC | เปลี่ยน path และพอร์ตเป็นของ counter |
| Floorplan | เลือก auto/small-block configuration ที่ reference รองรับ |
| Existing DEF | เอาออกหรือเปลี่ยนเมื่อเป็นของ reference design เก่า |
| Pin constraints | ตรวจชื่อพอร์ตและ boundary ที่เกี่ยวข้อง |
| Power plan | ใช้ supply/pin/layer ที่ PDK รองรับ |
| Special cells | คง policy ที่เหมาะสมของ technology |
| UPF/DFT/macros | ปิดหรือปรับเฉพาะเมื่อยืนยันว่าตัวอย่าง counter ไม่ใช้ |
| Output cell/view | เปลี่ยนชื่อไม่ให้ทับ reference |
| Run directory | สร้าง run ใหม่ที่ระบุภาษาและ revision |

Lab นี้ยังไม่ optimize floorplan หรือ CTS หากจำเป็นต้องกรอกค่าก่อน validate ให้ใช้ค่าจาก small-block template ที่ผู้สอนตรวจแล้ว พร้อมบันทึกว่าเป็น initial setting

## 3.14 Step 10 — บันทึก setup และรัน smoke check

1. บันทึก project/wizard settings
2. Export generated Tcl/run setup หากรุ่นนั้นรองรับ
3. เก็บสำเนาสำหรับตรวจ ไม่แก้ generated file โดยไม่ทราบว่าจะถูกสร้างทับหรือไม่
4. เริ่มรันเพียงถึง import/elaboration หรือ initial synthesis ตามความสามารถของ template
5. ถ้าหยุดเฉพาะ stage ไม่ได้ ใช้ flow ที่รองรับและตรวจผลส่วน setup ก่อนตีความผล stage หลัง
6. อ่าน error แรกที่เป็นสาเหตุ ไม่เริ่มจาก error จำนวนมากที่ตามมา
7. เก็บ log เต็มและสรุป warning ที่ยังมีผลต่อ correctness
8. ปิดและเปิด project ใหม่ ตรวจว่า top/source/library/SDC ยังอยู่ครบ

### ผลที่คาดหวัง

- RTL อ่านได้ในภาษาที่กำหนด
- Top และ bus width ถูกต้อง
- Library และ technology โหลดได้ครบ
- ไม่มี unresolved design reference หรือ missing physical cell
- Clock และ I/O timing contract มีผลจริง
- ไม่มี unintended latch
- ไม่มี syntax/file-access error

Timing slack ติดลบใน smoke run ไม่ได้แปลว่า project setup ผิดเสมอไป ต้องแยก constraint/load/library error ออกจากปัญหา implementation และ pre-route timing ยังไม่ใช่ post-route sign-off

## 3.15 Step 11 — เทียบ VHDL กับ Verilog/SystemVerilog

สร้างโปรเจกต์ที่สองโดยใช้ technology และ constraint contract เดียวกัน เปลี่ยนเฉพาะ source language/source files และชื่อ run/output

| สิ่งที่เทียบ | ผลที่ควรตรงกัน |
|---|---|
| Interface | clk/rst/en/q กว้างเท่ากัน |
| Reset | synchronous active-high |
| Enable | en=0 คงค่า, en=1 เพิ่มหนึ่ง |
| Wraparound | modulo 256 เมื่อ WIDTH=8 |
| Top/generic | counter และ WIDTH=8 |
| Timing contract | clock, delays, load และ uncertainty เท่ากัน |

Mapped cell count และ area ไม่จำเป็นต้องเท่ากันทุกบิต เพราะ frontend และ optimization อาจต่างกัน Functional simulation ของทั้งสอง implementation ต้องผ่าน และการพิสูจน์ formal equivalence หากต้องการเป็นงานแยกต่างหาก

## 3.16 Troubleshooting

| อาการ | สาเหตุที่ควรตรวจ | วิธีแก้และหลักฐาน |
|---|---|---|
| หา top ไม่พบ | ชื่อผิด, source ไม่ถูกอ่าน, compile ล้มเหลวก่อนหน้า | ตรวจไฟล์และ error แรก; ยืนยัน hierarchy |
| เลือก tb_counter เป็น top | TB อยู่ synthesis source set | เอา TB ออก; เลือก counter |
| always_ff syntax error | SV mode ไม่ถูกต้องหรือ frontend ไม่รองรับ | ตั้ง language mode หรือใช้ Verilog variant |
| VHDL package/entity ไม่พบ | logical library/order ไม่ถูก | compile package ก่อนผู้ใช้; ตรวจ work mapping |
| q กว้างผิด | generic/parameter override ค้าง | ตรวจ elaborated ports และเอา override เก่าออก |
| Duplicate module | เพิ่มทั้ง .v และ .sv | เลือกเพียงหนึ่ง source |
| Liberty โหลดได้แต่ map ไม่ได้ | cell policy/target library ผิด | ตรวจ allowed cells และ mapping diagnostics |
| Missing LEF macro | Liberty/LEF คนละ release หรือ special cells ขาด | จับคู่ views และเพิ่มชุดที่ถูกต้อง |
| Unknown site/layer/via | tech setup/stack/order ผิด | ใช้ชุด reference ที่เข้ากัน |
| No clock | SDC ไม่ถูกอ่านหรือ clk ไม่ match | ตรวจ path/load log และ source collection |
| Empty collection | พอร์ตเปลี่ยนชื่อหรือ bus notation ต่าง | ตรวจ get_ports และแก้เฉพาะชื่อที่ตั้งใจ |
| Clock ซ้ำ | wizard และ SDC สร้าง clock ทั้งคู่ | กำหนด timing source หลักและตรวจ report |
| Unconstrained endpoints | I/O delay/clock/analysis view ขาด | ตรวจ coverage; ไม่แก้ด้วย blanket false path |
| Delay/load สูงผิดปกติ | หน่วยไม่ตรง | ตรวจ library/engine units และ report ค่าที่มีผล |
| Run อ่านไฟล์ไม่ได้ | host/path/permission ไม่ตรง | ตรวจจาก engine host และ resolved path |
| เปิดใหม่แล้วค่าไม่อยู่ | บันทึกคนละ setup หรือใช้ directory ชั่วคราว | บันทึก project และทดลอง reopen |

## 3.17 แบบฝึกหัดตรวจจับความผิดพลาด

ทำในสำเนาโปรเจกต์ทีละกรณี แล้วคืนค่าก่อนกรณีถัดไป:

1. เปลี่ยน top เป็น counter_typo: ต้องตรวจพบว่า top ไม่ถูกต้อง
2. เปลี่ยน source mode ของ SV ให้ผิด: บันทึก error จาก frontend
3. เปลี่ยนชื่อ clock port ในสำเนา SDC เป็น clk_typo: ต้องพบ empty collection หรือ missing clock
4. ตัด output delay ของ q ออก: ตรวจว่า coverage/constraint review ตรวจพบ
5. เปลี่ยน WIDTH เป็น 4 แต่คงเอกสารไว้ 8: ตรวจว่าการทบทวน interface จับความไม่ตรงกันได้

หากเครื่องมือไม่เตือนเอง ให้บันทึกเป็นข้อจำกัดและเพิ่ม manual checklist ไม่ถือว่าการรันจบยืนยันว่า setup ถูกต้อง ห้ามทำแบบฝึกหัดแก้ไข shared PDK หรือ shared template

## 3.18 หลักฐานและเกณฑ์ผ่าน

ส่งมอบรายการต่อไปนี้:

1. Project setup ที่เปิดซ้ำได้ และ README วิธีเปิด/รันตาม environment จริง
2. RTL revision และ source list แยกจาก TB
3. Library/technology manifest ระบุ release, corner และ resolved paths
4. counter.sdc พร้อมคำอธิบายหน่วยและ external timing assumptions
5. Log ของ analyze/elaborate/import หรือ initial synthesis
6. Reports ของ top/ports, libraries, clock และ timing coverage
7. ตาราง warning/known limitations และผลแบบฝึกหัดอย่างน้อยสองกรณี
8. ตารางเทียบ VHDL กับ Verilog/SystemVerilog

**เกณฑ์ผ่าน:** top/source ถูกต้อง, ไม่มี unresolved references, physical/timing views จับคู่ได้, constraint มีผลตามที่ตั้งใจ, ไม่มี endpoint หลุดโดยไม่อธิบาย และเปิดโปรเจกต์ซ้ำได้

**ยังไม่ใช่เกณฑ์ผ่าน sign-off:** การจบ wizard, การเห็น layout, การมี WNS เป็นบวกครั้งเดียว หรือการรันไม่มี fatal error ไม่ทดแทน DRC/LVS, post-route STA, power connectivity และ release review

### ตัวอย่าง README สรุปสำหรับผู้รับงาน

```text
Design: counter
Language: SystemVerilog / Verilog / VHDL (ระบุที่ใช้จริง)
Top: counter
Width: 8
Clock: clk, 10 ns, rising edge
Reset: rst, synchronous active-high
Sources: ระบุรายการจริง
Constraints: constraints/counter.sdc
Tool/template/PDK/library revisions: ระบุจริง
Open project: ระบุไฟล์หรือขั้นตอนที่ใช้จริง
Run: ใช้ wizard/reference launcher ที่ทดสอบแล้ว
Last validated stage:
Evidence:
Known limitations:
```

หากมี checksum ของไฟล์ ให้แนบ hash ของ RTL/SDC/setup ที่รันจริง ส่วนข้อมูล PDK ที่มีข้อจำกัดสิทธิ์ให้บันทึก identifier/path ตามนโยบายองค์กร ไม่แจกจ่ายเนื้อหา PDK ในชุดส่งมอบ

## 3.19 คำถามท้าย Lab

1. เพราะเหตุใดการเลือก top ถูกแต่เพิ่ม TB เข้า source set จึงยังเป็นปัญหา?
2. VHDL logical library แตกต่างจาก Liberty library อย่างไร?
3. Liberty โหลดสำเร็จ แต่ cell LEF ขาดจะส่งผลใน stage ใด?
4. เหตุใด rst ในตัวอย่างนี้ไม่ควรถูก false-path?
5. การตั้งค่าบน wizard ต่างจากการพิสูจน์ว่า engine ใช้ค่าจริงอย่างไร?
6. Timing corner และ RC corner ต่างกันอย่างไร?
7. เพราะเหตุใด load 0.020 จึงอาจถูกตีความผิดได้?
8. หาก RTL ทั้งสองภาษาให้ mapped area ต่างกัน จะสรุปว่าฟังก์ชันต่างกันได้หรือไม่?

## 3.20 เอกสารอ้างอิงและขอบเขตการตรวจสอบ

[1] Siemens EDA, “Digital Implementation” — อธิบาย wizard ใน L-Edit, Tcl customization และขอบเขต implementation:
https://eda.sw.siemens.com/en-US/ic/ic-custom/ams/digital-implementer/

[2] Siemens, “Documentation and downloads” — ช่องทางเข้าถึง Support Center สำหรับคู่มือรุ่นที่ติดตั้ง:
https://www.siemens.com/en-us/support/documentation-downloads/

ตรวจสอบแหล่งข้อมูลสาธารณะวันที่ 16 ตุลาคม 2026 ชื่อหน้า wizard, project format, คำสั่งรายงาน, engine และรูปแบบ technology ที่รองรับต้องยึด installed documentation และ reference template ของระบบจริง ตัวอย่าง RTL/SDC ในบทนี้เป็นตัวอย่างประกอบการสอน ยังไม่ได้รันกับ TDI/PDK ของผู้เรียน จึงต้องเก็บผลตรวจจริงตาม checkpoints ก่อนนำไปใช้ต่อใน Lab implementation

