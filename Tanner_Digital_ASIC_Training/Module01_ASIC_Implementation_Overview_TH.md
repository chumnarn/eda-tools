# Module 1 — ภาพรวม ASIC implementation

หลักสูตร Tanner Digital ASIC Design Implementation ระดับเริ่มต้นถึงระดับกลาง

## 1.1 เป้าหมายและแนวคิดหลัก

ASIC implementation คือกระบวนการเปลี่ยนข้อกำหนดของวงจรให้กลายเป็นโครงสร้างทางกายภาพที่ผลิตได้จริง และตรวจสอบว่าพฤติกรรม เวลา การใช้พลังงาน และกฎของเทคโนโลยีสอดคล้องกับข้อกำหนด การได้ไฟล์ GDSII เพียงอย่างเดียวจึงยังไม่ใช่หลักฐานว่าวงจรพร้อมผลิต ต้องมีผลตรวจและชุดข้อมูลที่สอดคล้องกับ revision เดียวกันด้วย

เมื่อเรียนจบ ผู้เรียนควรสามารถ:

1. อธิบายความสัมพันธ์ระหว่าง specification, RTL, gate-level netlist และ geometry
2. แยกความแตกต่างของการ implement บน FPGA และ ASIC
3. อ่านตัวชี้วัด performance, power และ area โดยระบุเงื่อนไขที่ใช้วัด
4. อธิบายเหตุที่ผล synthesis เปลี่ยนไปหลัง placement, CTS และ routing
5. วิเคราะห์กรณี RTL simulation ผ่าน แต่ชิปล้มเหลวจาก timing หรือระบบจ่ายไฟ

ระยะเวลาที่แนะนำ: ทฤษฎี 90 นาที กิจกรรมวิเคราะห์ 45 นาที และอภิปราย 15 นาที

## 1.2 จาก specification สู่ geometry

การออกแบบหนึ่งชุดถูกอธิบายผ่านหลาย abstraction แต่ละระดับตอบคำถามคนละด้าน และต้องรักษาความสอดคล้องระหว่างกัน

| ระดับ | คำถามที่ต้องตอบ | ตัวอย่างข้อมูล | วิธีตรวจหลัก |
|---|---|---|---|
| Specification | วงจรต้องทำอะไร ภายใต้เงื่อนไขใด | ฟังก์ชัน ความถี่ latency reset แรงดัน และงบพลังงาน | Review, requirement traceability และ acceptance criteria |
| RTL | ข้อมูลและสถานะเปลี่ยนอย่างไรในแต่ละ clock | VHDL, Verilog, SystemVerilog | Simulation, assertions, lint และ CDC/RDC ตามลักษณะวงจร |
| Netlist | ใช้ cell ใดและต่อถึงกันอย่างไร | Instances ของ standard cells และ macros พร้อม nets | Equivalence, structural checks และ STA |
| Geometry | วางอุปกรณ์และเดินโลหะที่ตำแหน่งใด | Layout polygons, vias, pins และข้อมูล GDSII/OASIS | DRC, LVS, extraction, STA และ power integrity |

### 1.2.1 Specification ต้องกำหนดมากกว่าฟังก์ชัน

ตัวอย่างข้อกำหนดของ accumulator ขนาด 8 บิต:

- รับ `data_i` เมื่อ `en_i = 1` ที่ขอบขาขึ้นของ `clk_i`
- เก็บผลบวกแบบ modulo 256 และคงค่าเดิมเมื่อ `en_i = 0`
- reset แบบ synchronous active-high ทำให้ผลลัพธ์เป็นศูนย์ที่ขอบ clock
- ใช้ clock เป้าหมาย 100 MHz หรือ period 10 ns
- กำหนด input/output timing จากอุปกรณ์ที่เชื่อมต่อ รวมทั้ง input transition และ output load
- ระบุ power domains, operating voltage, ช่วงอุณหภูมิ และ corner ที่ต้องผ่าน
- ระบุเงื่อนไข workload สำหรับประเมิน power และนิยามว่า area หมายถึง cell area, core area หรือ die area

ข้อกำหนด “ทำงานที่ 100 MHz” ยังไม่ครบ หากไม่ระบุว่า input มาถึงเมื่อใด output ต้องพร้อมเมื่อใด และต้องผ่าน PVT corner ใด การใช้ RTL เดียวกันแต่เปลี่ยน constraints สามารถให้ netlist และผล PPA ต่างกันได้

### 1.2.2 RTL อธิบายพฤติกรรมและโครงสร้างที่อนุมานได้

RTL แบบ synthesizable ระบุ registers, combinational operations และการอัปเดตสถานะ RTL ไม่ได้ระบุตำแหน่งทางกายภาพ ความยาวสาย หรือจำนวน vias โดยตรง ขณะเดียวกัน RTL ก็มีผลต่อ implementation อย่างมาก เช่น จำนวน pipeline stages, ความกว้างข้อมูล และลักษณะการเลือกข้อมูล

### 1.2.3 Netlist ระบุ cell และ connectivity

หลัง technology mapping ตัวดำเนินการบวกและ register ใน RTL จะถูกแทนด้วย cells ที่มีอยู่ใน library จริง เช่น flip-flops, NAND/NOR, XOR, multiplexers และ buffers การบวกอาจถูกสร้างเป็นเครือข่าย gates หลายชนิดตาม library และเป้าหมาย optimization จึงไม่ควรคาดว่าจะมี cell ชื่อ `ADD8` เสมอไป

Netlist อาจเปลี่ยนต่อระหว่าง physical implementation จาก buffering, resizing, clock-tree insertion และ timing repair การตรวจ equivalence ในจุดที่เหมาะสมช่วยยืนยันว่าการเปลี่ยนโครงสร้างยังรักษาพฤติกรรมตามวิธีตรวจและ assumptions ที่กำหนด

### 1.2.4 Geometry ทำให้ connectivity มีต้นทุนทางกายภาพ

เมื่อวาง cells และเดินสาย net หนึ่งเส้นจะกลายเป็น metal segments และ vias ที่มี resistance และ capacitance สัญญาณจึงเดินทางด้วย delay ที่ขึ้นกับทั้ง driver, load และ interconnect

GDSII/OASIS เก็บรูปทรงและโครงสร้างลำดับชั้นของ layout ส่วน LEF เป็น abstract view ที่ใช้ในการวางและเดินสาย เช่น ขนาด cell, ตำแหน่ง pins และ obstructions ทั้งสองชนิดไม่ใช่ข้อมูลแทนกันทั้งหมด

ความสัมพันธ์จึงมีสองทิศทาง: specification กำหนด RTL และ constraints ขณะที่ผลทางกายภาพอาจบังคับให้ย้อนกลับไปปรับ architecture หรือ RTL เช่น เพิ่ม pipeline เมื่อเส้นทาง combinational ยาวเกินงบเวลา

## 1.3 ตัวอย่าง RTL: VHDL และ SystemVerilog ควบคู่กัน

ตัวอย่างทั้งสองมีพฤติกรรมเดียวกัน ใช้ synchronous reset และผลบวกขนาด 8 บิตแบบ wraparound

### VHDL

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity accumulator8 is
  port (
    clk_i  : in  std_logic;
    rst_i  : in  std_logic;
    en_i   : in  std_logic;
    data_i : in  std_logic_vector(7 downto 0);
    sum_o  : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of accumulator8 is
  signal sum_q : unsigned(7 downto 0);
begin
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '1' then
        sum_q <= (others => '0');
      elsif en_i = '1' then
        sum_q <= sum_q + unsigned(data_i);
      end if;
    end if;
  end process;
  sum_o <= std_logic_vector(sum_q);
end architecture;
```

### SystemVerilog

```systemverilog
module accumulator8 (
  input  logic       clk_i,
  input  logic       rst_i,
  input  logic       en_i,
  input  logic [7:0] data_i,
  output logic [7:0] sum_o
);
  logic [7:0] sum_q;

  always_ff @(posedge clk_i) begin
    if (rst_i)
      sum_q <= 8'h00;
    else if (en_i)
      sum_q <= sum_q + data_i;
  end

  assign sum_o = sum_q;
endmodule
```

`always_ff` เป็นไวยากรณ์ SystemVerilog หากใช้ Verilog-2001 ให้ใช้ `always @(posedge clk_i)` ประกาศ `sum_q` เป็น `reg [7:0]` และปรับชนิด ports ให้เหมาะสม โดยคง nonblocking assignments สำหรับ sequential logic

วงจรที่คาดว่าจะอนุมานได้คือ register 8 บิต วงจรบวก และ logic สำหรับ reset/enable แต่ implementation อาจใช้ flip-flop ที่มี enable หรือใช้ mux หน้า D input ขึ้นกับ cells และวิธี mapping ไม่มีการกำหนดตำแหน่งหรือเส้นทางโลหะจากโค้ดนี้

ข้อควรตรวจใน testbench ได้แก่ reset, enable, การ hold ค่า, ผลบวกปกติ และ overflow เช่น 250 + 10 ต้องได้ 4 ทั้งสองภาษาไม่ควรอาศัยค่าเริ่มต้นของ register ก่อน reset เป็นส่วนหนึ่งของ specification โดยไม่มีวงจรและเงื่อนไขรองรับ

## 1.4 FPGA LUT แตกต่างจาก ASIC standard cell อย่างไร

LUT คือทรัพยากรตรรกะที่ตั้งโปรแกรมให้สร้าง Boolean function ตามจำนวน inputs ที่รองรับ ส่วน ASIC standard cell เป็น layout ของวงจรทรานซิสเตอร์ที่ออกแบบและ characterize ไว้แล้ว เช่น NAND2, XOR2 หรือ D flip-flop เครื่องมือเลือกชนิดและขนาด cell แล้วเชื่อมต่อด้วยสายที่สร้างขึ้นสำหรับชิปนั้น

| ประเด็น | FPGA | ASIC standard-cell implementation |
|---|---|---|
| หน่วยตรรกะหลัก | LUTs, flip-flops และ dedicated resources | Gates, flip-flops, buffers และ macros จาก library |
| การเชื่อมต่อ | Programmable routing บน silicon ที่ผลิตไว้แล้ว | Metal routing ที่สร้างเฉพาะตาม layout |
| การบวก | อาจใช้ dedicated carry chain | Mapping เป็น cells/โครงสร้างที่ library และ flow รองรับ |
| Clock | ใช้ทรัพยากร clock ที่มีและข้อกำหนดของอุปกรณ์ | สร้าง clock tree ภายใต้ข้อจำกัดของเทคโนโลยี |
| หน่วยความจำ | Block RAM, distributed RAM และทรัพยากรเฉพาะรุ่น | SRAM macros หรือ register-based memory |
| ผลลัพธ์ | Configuration/bitstream สำหรับอุปกรณ์ | Layout และชุดข้อมูลส่งต่อการผลิต |
| การแก้หลังผลิต | มักโหลด configuration ใหม่ได้ | ตรรกะที่ผลิตแล้วแก้ไม่ได้ เว้นแต่มีความสามารถรองรับไว้ |
| การรายงาน area | LUT/FF/BRAM/DSP utilization | Cell area, macro area, core area และ die area |

LUT ไม่ใช่ gate เพียงตัวเดียว และ standard cell ก็ไม่ใช่ LUT ที่เล็กลง ตัวอย่าง XOR หลาย inputs อาจกิน LUT จำนวนน้อยใน FPGA แต่ต้องสร้างเป็นเครือข่าย XOR cells ใน ASIC ในทางกลับกัน ASIC สามารถเลือก complex gates และ drive strengths ที่เหมาะกับเส้นทางได้

ห้ามแปลง “หนึ่ง LUT = กี่ตารางไมโครเมตรของ ASIC” ด้วยค่าคงที่ทั่วไป เพราะขึ้นกับฟังก์ชัน library เทคโนโลยี constraints และการใช้ทรัพยากรเฉพาะ เช่น DSP หรือ SRAM ผล prototype บน FPGA จึงช่วยพิสูจน์ฟังก์ชันและ software ได้มาก แต่ไม่ยืนยัน ASIC timing หรือ power integrity

## 1.5 PPA: Performance, Power และ Area

### 1.5.1 Performance

Performance อาจหมายถึงความถี่สูงสุด throughput หรือ latency ต้องระบุตัวชี้วัดให้ชัดเจน การเพิ่ม pipeline มักช่วยให้ทำงานที่ clock สูงขึ้น แต่เพิ่ม latency ที่นับเป็นจำนวน cycles และเพิ่ม registers/clock load จึงต้องเทียบกับข้อกำหนดของระบบ

สำหรับ register-to-register path แบบ single-cycle ให้กำหนด clock skew เป็นเวลาที่ capture clock มาถึงลบเวลาที่ launch clock มาถึง โดยสมการอย่างง่ายเป็น:

`setup slack = T + skew − uncertainty_setup − (tCQ_max + tcomb_max + twire_max + tsetup)`

เมื่อ slack เป็นลบ ข้อมูลมาถึงช้ากว่าที่ capture register ต้องการ ส่วน hold เป็นข้อกำหนดด้านข้อมูลที่มาถึงเร็วเกินไป:

`hold slack = tCQ_min + tcomb_min + twire_min − (skew + thold + uncertainty_hold)`

สมการเหล่านี้ใช้เพื่ออธิบายแนวคิด ต้องอ่านรายงาน STA จริงที่รวม clock paths, derating, exceptions และวิธีวิเคราะห์ของ flow ด้วย Positive skew ช่วย setup แต่ทำให้ hold ยากขึ้นในตัวอย่างนี้ และการลดความถี่เพียงอย่างเดียวโดยทั่วไปไม่แก้ hold violation

WNS คือ worst negative slack ตามนิยามการรายงานของเครื่องมือ ส่วน TNS รวม negative slack ของ endpoints/paths ตามวิธีรายงาน ต้องตรวจ setup และ hold แยกกัน พร้อม timing coverage การไม่มี violation ในรายงานไม่ได้ยืนยันความครบถ้วน หากบาง paths ไม่ถูก constrain

### 1.5.2 Power

กำลังไฟฟ้าโดยประมาณแยกเป็น switching, internal และ leakage power โดยโมเดล switching แบบย่อคือ:

`P_switching ≈ α × C × V² × f`

ในที่นี้กำหนด α เป็นจำนวนการชาร์จแบบ 0→1 เฉลี่ยต่อ cycle เพื่อให้สอดคล้องกับรูปสมการ ส่วน C คือ capacitance ที่ถูกชาร์จ V คือแรงดัน และ f คือความถี่ แหล่งอ้างอิงหรือเครื่องมือที่นิยาม activity ต่างกันอาจใช้ตัวประกอบต่างกัน

- Switching power ขึ้นกับ activity และ capacitance ของ loads/interconnect
- Internal power เกิดภายใน cell เช่น การชาร์จโหนดภายในและกระแสช่วงเปลี่ยนสถานะ ตามโมเดล characterization
- Leakage power ขึ้นกับ cell, state, voltage, temperature และ process

การประเมิน power ต้องระบุ workload, activity coverage, clock frequency, voltage, corner และขั้นตอนของ flow การใช้ default activity ที่ต่ำเกินจริงอาจให้ตัวเลข power สวย แต่ไม่สะท้อนการใช้งานจริง นอกจากนี้ average power ต่ำไม่ได้ยืนยันว่า transient droop หรือ EM จะผ่าน

### 1.5.3 Area

Cell area คือผลรวมพื้นที่ cells ตามขอบเขตที่รายงาน Core area ต้องเผื่อ placement whitespace, routing, clock/power distribution และ macros ส่วน die area รวมบริเวณอื่นตามรูปแบบชิป เช่น IO ring และระยะขอบที่กำหนด

สำหรับตัวอย่างที่ไม่มี macros และนิยาม utilization เป็น standard-cell area หารด้วยพื้นที่วาง cell ที่ใช้ได้ หาก cell area = 20,000 µm² และเป้าหมาย utilization = 0.50 จะต้องมีพื้นที่วาง cell ประมาณ 40,000 µm² แต่ค่านี้ยังไม่ใช่ die area และต้องระวังนิยามพื้นที่ในเครื่องมือแต่ละตัว

### 1.5.4 Trade-offs ที่ต้องตีความร่วมกัน

| การเปลี่ยนแปลง | ผลที่มักคาดหวัง | ต้นทุนหรือข้อจำกัด |
|---|---|---|
| เพิ่ม drive strength | ลดบางส่วนของ cell delay | Area/input capacitance/power อาจเพิ่ม และ upstream path อาจช้าลง |
| เพิ่ม pipeline | ลดงาน combinational ต่อ cycle | Registers, clock power, latency และ control complexity เพิ่ม |
| ลดแรงดัน | ลด switching power | Delay เพิ่ม และต้องมี library/operating conditions รองรับ |
| ลด utilization | เพิ่มพื้นที่ให้ placement/routing | Core ใหญ่ขึ้นและบาง nets อาจยาวขึ้น |
| Clock gating | ลด clock switching ในส่วนที่ไม่ใช้งาน | ต้องมีวงจร gating ที่ถูกต้องและตรวจ timing/test requirements |

ผลกระทบเป็นแนวโน้ม ไม่ใช่กฎที่รับประกันทุกกรณี ต้องทดลองและวัดภายใต้เงื่อนไขเดียวกัน

## 1.6 เหตุใดผล synthesis ยังไม่ใช่ผลหลัง route

Synthesis เลือกและปรับโครงสร้างตรรกะโดยอาศัย libraries และ constraints การประมาณ interconnect อาจเป็นแบบหยาบหรือใช้ physical guidance ขึ้นกับ flow แต่ยังไม่เท่ากับ parasitics ที่สกัดจากเส้นทางสุดท้าย

| ขั้นตอน | ข้อมูลที่เพิ่มขึ้น | ผลที่อาจเกิดกับ PPA |
|---|---|---|
| Synthesis | Mapped cells และ delay/load models | ได้ cell count/area และ timing estimate |
| Floorplan/placement | ตำแหน่ง cells/macros และข้อจำกัดพื้นที่ | พบระยะทางจริงมากขึ้น ต้อง buffer/resize หรือแก้ congestion |
| CTS | Clock tree และ clock arrival ของแต่ละ register | Clock area/power เพิ่ม และ setup/hold เปลี่ยนตาม skew/latency |
| Routing | เส้นทาง metal, vias และการอ้อมสิ่งกีดขวาง | Wire delay/capacitance เปลี่ยน อาจต้อง repair เพิ่ม |
| Extraction/analysis | Parasitics จาก geometry และเงื่อนไขวิเคราะห์ | ประเมิน timing/power ได้ใกล้โครงสร้างสุดท้ายมากขึ้น |

หลัง route อาจดีขึ้นหรือแย่ลงจาก synthesis ก็ได้ เพราะทั้งข้อมูลประมาณและ optimization เปลี่ยนไป จึงควรเก็บผลแต่ละขั้นเพื่อดูแนวโน้ม แต่ใช้ผลที่เหมาะกับ sign-off criteria เป็นเกณฑ์ตัดสินสุดท้าย

### ตัวอย่างคำนวณ setup ก่อนและหลัง route

สมมติ period = 10 ns, setup uncertainty = 0.30 ns และ setup time = 0.20 ns ตัวเลขทั้งหมดต่อไปนี้เป็นตัวอย่างเพื่อการสอน

| รายการ | ประมาณหลัง synthesis | หลัง route |
|---|---:|---:|
| tCQ_max | 0.40 ns | 0.40 ns |
| Combinational cell delay | 7.80 ns | 7.70 ns |
| Wire delay | 0.50 ns | 2.00 ns |
| Capture−launch skew | 0.00 ns | −0.10 ns |
| Setup slack | +0.80 ns | −0.70 ns |

คำนวณหลัง route:

`10 − 0.10 − 0.30 − (0.40 + 7.70 + 2.00 + 0.20) = −0.70 ns`

แม้ cell delay ลดลงเล็กน้อย แต่ wire delay เพิ่มและ skew เป็นลบ ทำให้ไม่ผ่าน timing ตัวอย่างนี้ยังไม่ได้รวมรายละเอียดอย่าง derating หรือ signal integrity จึงไม่ควรนำตัวเลขไปแทนรายงาน STA ของงานจริง

## 1.7 RTL simulation ผ่าน แต่ชิปยังล้มเหลวได้อย่างไร

RTL simulation มักใช้ clock และสัญญาณเชิงตรรกะในแบบจำลองที่ไม่ได้รวม delay ทางกายภาพหรือแรงดันจริง การผ่าน simulation แสดงว่าผลลัพธ์ตรงกับ testbench ในสถานการณ์ที่ทดสอบ ไม่ได้ยืนยันทุกพฤติกรรมหรือทุกเงื่อนไขการทำงาน

### กรณี A: Setup violation

Testbench ป้อนข้อมูลก่อนขอบ clock และคำนวณผลลัพธ์จาก RTL ได้ถูกต้อง แต่ชิปจริงมี combinational delay และ wire delay จนข้อมูลมาถึง D input หลัง setup window Register อาจจับค่ารอบก่อนหน้า จับค่าผิด หรือเข้าสู่ metastability แล้วแต่สถานการณ์

หลักฐานที่ต้องดูคือ post-route STA ของ path ที่เกี่ยวข้อง: startpoint, endpoint, corner, clock arrivals, cell/wire contributions และข้อกำหนด setup วิธีแก้อาจเป็นปรับ RTL, pipeline, placement หรือ cell sizing โดยต้องตรวจผลต่อ paths อื่นด้วย

### กรณี B: Hold violation

เส้นทางข้อมูลสั้นมาก ขณะที่ capture clock มาถึงช้ากว่า launch clock ข้อมูลใหม่จึงมาถึงเร็วเกิน hold window ของ capture register RTL ไม่ได้จำลองความแตกต่างของ clock arrivals นี้โดยปกติ วิธีแก้มักเพิ่ม data-path delay หรือปรับ clock/placement ตาม flow แล้วตรวจ setup ซ้ำ

### กรณี C: Power connectivity ผิด

Macro อาจมี power pins หลายชุด เช่น `VDD`, `VSS`, `IOVDD`, `IOVSS` ตามนิยามของ library จริง หากเชื่อมเฉพาะ logic signals แต่ปล่อย supply บางขาลอย macro จะไม่ทำงานตามข้อกำหนด แม้ behavioral model จะยังให้ผลถูกต้อง เพราะ model นั้นอาจไม่มี power pins หรือไม่ได้ใช้ supply ในการคำนวณ

ตัวอย่างสถานการณ์: register core ต่อไฟถูกต้อง แต่ IO pad ขาด supply ของ IO domain Internal output จึงเปลี่ยนตามที่จำลอง ขณะที่แรงดันที่ขาภายนอกไม่เป็นไปตามข้อกำหนด อีกกรณีคือ SRAM model อ่านเขียนได้ใน RTL แต่ layout ไม่มีการเชื่อม supply ครบทุกขาของ macro

ต้องตรวจตั้งแต่ power intent/net names, pin mapping, global connections, PDN connectivity และ supply topology ของ pad/core/macro ไปจนถึงการต่อกับ package ตามขอบเขตงาน การที่ชื่อ net ตรงกันไม่ได้แปลว่า metal และ vias เชื่อมต่อจริง

### กรณี D: ต่อไฟครบ แต่แรงดันไม่เพียงพอ

PDN อาจต่อถึงทุกขาแต่มี resistance สูงเกินไป เมื่อโหลดใช้กระแสจะเกิด IR drop โดยแนวคิดแบบย่อ `ΔV = I × R` ทำให้แรงดันที่ cell ต่ำลงและ delay เพิ่ม การกระชากกระแสและ package effects ยังทำให้ dynamic droop ได้ ส่วน EM เป็นข้อจำกัดความทนทานของ interconnect ภายใต้กระแสและเงื่อนไขที่กำหนด

Connectivity check จึงตอบว่า “ต่อถึงหรือไม่” แต่ไม่ได้ตอบว่า “จ่ายกระแสและรักษาแรงดันได้เพียงพอหรือไม่” ต้องใช้ power-integrity analysis ที่เหมาะสมกับแบบและข้อมูลกระแส

### กรณี E: ปัญหานอกขอบเขต timing ปกติ

CDC/RDC ที่ไม่ถูกต้อง, reset release, IO voltage mismatch, ข้อผิดพลาดของ testbench และ specification ที่ตกหล่นก็ทำให้ชิปล้มเหลวได้ STA, simulation และ physical verification มีหน้าที่เสริมกัน ไม่มีวิธีใดวิธีหนึ่งครอบคลุมทั้งหมด

## 1.8 แยกหน้าที่ของการตรวจให้ถูกต้อง

| วิธีตรวจ | คำถามหลัก | สิ่งที่ผลผ่านเพียงอย่างเดียวยังไม่ยืนยัน |
|---|---|---|
| RTL simulation | พฤติกรรมตรงตาม test scenarios หรือไม่ | Timing ทางกายภาพและ supply connectivity |
| Equivalence | สอง representation เทียบเท่าภายใต้ assumptions หรือไม่ | ความครบถ้วนของ specification และ power integrity |
| STA | Timing paths ภายใต้ constraints/corners ผ่านหรือไม่ | ฟังก์ชันทุกกรณีและ paths ที่ไม่ได้ constrain |
| DRC | Geometry ผ่านกฎที่เปิดตรวจหรือไม่ | วงจรต่อถูกตาม schematic/netlist หรือไม่ |
| LVS | Extracted connectivity/devices ตรงกับ reference หรือไม่ | Timing และกำลังการจ่ายกระแสของ PDN |
| PDN connectivity | Supply graph ต่อถึงตามวิธีตรวจหรือไม่ | IR drop, EM และความถูกต้องของ geometry ทุกกฎ |
| IR/EM analysis | แรงดันตกและกระแสในโครงข่ายผ่านเกณฑ์หรือไม่ | ฟังก์ชันดิจิทัลและความครบถ้วนของ workload ที่ไม่ได้วิเคราะห์ |

Timed gate-level simulation พร้อม SDF ช่วยตรวจสถานการณ์เชิงเวลาบางประเภทและ timing checks ของ models ได้ แต่ผลขึ้นกับ annotation coverage, models และ stimulus จึงใช้ร่วมกับ STA ไม่ใช่หลักฐานแทน STA ทุก paths/corners

## 1.9 เชื่อมเนื้อหากับ workflow ของหลักสูตร

ในหลักสูตรที่ใช้ Tanner และเครื่องมือ Siemens ร่วมกัน ให้เริ่มจากหน้าที่ของขั้นตอน แล้วจับคู่กับเครื่องมือและ licenses ที่มีจริง การใช้ simulator ตรวจ RTL การ synthesis เพื่อสร้าง ASIC netlist การทำ physical implementation และการตรวจ layout เป็นคนละหน้าที่ ชื่อชุดซอฟต์แวร์ไม่ได้รับประกันว่าทุกฟังก์ชันหรือทุก interface มีอยู่ในรุ่นที่ติดตั้ง

ก่อนเริ่ม lab ให้ผู้สอนระบุเวอร์ชันของเครื่องมือ, PDK revision, standard-cell library, macro views และผู้รับผิดชอบแต่ละขั้นตอนอย่างชัดเจน ใช้คำสั่งจริงจาก installation ที่ตรวจแล้วในโมดูลปฏิบัติ และแยกคำสั่งของเครื่องมืออื่นออกจาก Tanner commands

หลักฐานที่ควรเก็บในแต่ละ checkpoint:

1. Specification และ constraints พร้อม revision
2. RTL และผล verification ที่เชื่อมโยงกับ revision นั้น
3. Mapped netlist พร้อม synthesis reports และ library/corner ที่ใช้
4. Placement/CTS/routing databases พร้อม timing reports ในแต่ละขั้น
5. Final netlist, layout, extracted parasitics และผล physical/power/timing checks ตาม acceptance criteria

## 1.10 กิจกรรมฝึกปฏิบัติ: อ่านวงจรเดียวกันจากหลายมุม

### กิจกรรมที่ 1 — แปลง specification เป็นวงจรที่คาดหวัง

อ่าน accumulator ทั้งสองภาษา แล้ววาด register, adder และเส้นทาง feedback ระบุว่าทำไมต้องมี logic สำหรับ enable/reset และอธิบายว่าเหตุใดจึงยังสรุปจำนวน mapped cells ที่แน่นอนไม่ได้

ทดสอบลำดับ: reset → บวก 5 → disable หนึ่ง cycle → บวก 250 → บวก 10 ผลลัพธ์หลังขอบ clock ที่เกี่ยวข้องต้องเป็น 0 → 5 → 5 → 255 → 9 โดย testbench ต้องเปลี่ยน inputs ห่างจากขอบ sampling และตรวจ outputs หลังการอัปเดต sequential logic เพื่อหลีกเลี่ยง simulation race

### กิจกรรมที่ 2 — วิเคราะห์รายงาน timing

ใช้ตัวอย่างในหัวข้อ 1.6 ให้ผู้เรียนแยก cell delay, wire delay และ skew แล้วคำนวณ slack ทั้งก่อนและหลัง route จากนั้นเสนอวิธีแก้อย่างน้อยสองแนวทาง พร้อมระบุผลข้างเคียงด้าน PPA

### กิจกรรมที่ 3 — วิเคราะห์ power failure

สถานการณ์สมมติ: functional simulation ผ่าน แต่ตรวจพบ power pin ของ macro หนึ่งขาไม่มีเส้นทางไปยัง supply source ให้ผู้เรียนตอบว่า behavioral model เหตุใดจึงยังทำงานได้ ต้องดูข้อมูลใดเพื่อยืนยัน และหลังแก้ connectivity แล้วต้องตรวจอะไรต่อ

คำตอบที่คาดหวัง: ตรวจ model/black-box interface, library pin definitions, supply mapping, layout connectivity และผล LVS/PDN checks จากนั้นตรวจ geometry และ power integrity ตาม flow ไม่สรุปจากชื่อ supply net เพียงอย่างเดียว

### เกณฑ์ส่งงาน

- ตารางเชื่อม specification → RTL construct → โครงสร้าง netlist ที่คาดหวัง → ประเด็นทางกายภาพ อย่างน้อยสี่รายการ
- ผลทดสอบ accumulator ตามลำดับที่กำหนด พร้อมอธิบาย wraparound
- การคำนวณ setup slack สองกรณีที่ถูกต้อง
- คำอธิบายความต่างระหว่าง functional correctness, timing correctness และ power integrity

## 1.11 คำถามทบทวนและแนวคำตอบ

**1. RTL simulation ผ่านแล้ว เหตุใดชิปยังผิดพลาดที่ความถี่เป้าหมาย?**

เพราะ RTL simulation โดยทั่วไปไม่ได้รวม cell/wire delay และ clock skew ทางกายภาพ วงจรอาจมี setup/hold violation นอกจากนี้ stimulus อาจไม่ครอบคลุมทุกกรณี ต้องตรวจ timing coverage และ STA ภายใต้ corners ที่กำหนดร่วมกับ functional verification

**2. ทำไมลดความถี่แล้วบางปัญหายังไม่หาย?**

Hold violation ขึ้นกับ minimum data delay เทียบกับ clock arrival และ hold requirement ในขอบที่เกี่ยวข้อง การเพิ่ม period จึงโดยทั่วไปไม่ช่วย อีกทั้ง supply ขาด, CDC ผิด หรือ reset ผิดก็ไม่ได้ถูกแก้ด้วยการลดความถี่เพียงอย่างเดียว

**3. Netlist กับ geometry ต่างกันอย่างไร?**

Netlist ระบุ instances และการเชื่อมต่อ ส่วน geometry ระบุตำแหน่ง รูปทรง layers และ vias ที่ทำให้การเชื่อมต่อเกิดขึ้นจริง Geometry เป็นฐานของการสกัด parasitics และการตรวจข้อกำหนดทางกายภาพ

**4. LUT utilization ต่ำหมายความว่า ASIC area ต่ำหรือไม่?**

ยังสรุปไม่ได้ เพราะ FPGA และ ASIC มีทรัพยากรและวิธี mapping ต่างกัน ต้อง synthesis ด้วย ASIC library และ constraints ที่เหมาะสม รวมถึงพิจารณา macros และพื้นที่ทางกายภาพ

**5. DRC ผ่านแล้ว supply ต้องต่อครบหรือไม่?**

ไม่จำเป็น DRC ตรวจ geometry ตาม rule deck ไม่ได้ยืนยันทุกความสัมพันธ์ด้าน connectivity ต้องมี LVS และ power connectivity checks ที่ตั้งค่าและครอบคลุมอย่างเหมาะสม

**6. ทำไมผล power หลัง synthesis กับหลัง route จึงต่างกัน?**

เพราะ capacitance, clock tree, cell sizes, buffers และบางครั้ง activity/glitches เปลี่ยนไป ต้องเปรียบเทียบด้วย workload, corner, voltage และขอบเขตการรายงานเดียวกัน

## 1.12 ข้อความสำคัญสำหรับผู้เรียน

การ implement ASIC คือการรักษาข้อกำหนดของระบบผ่านหลาย representation พร้อมพิสูจน์คุณสมบัติที่เพิ่มขึ้นในแต่ละระดับ RTL บอกพฤติกรรม netlist บอกโครงสร้าง และ geometry ทำให้โครงสร้างนั้นเกิดขึ้นจริงพร้อมต้นทุนด้านเวลา พลังงาน และพื้นที่ ผล synthesis เป็น checkpoint สำหรับตัดสินใจ ส่วนความพร้อมของชิปต้องอาศัยผลตรวจที่สอดคล้องกับ implementation สุดท้ายและเงื่อนไขการใช้งานที่กำหนด
