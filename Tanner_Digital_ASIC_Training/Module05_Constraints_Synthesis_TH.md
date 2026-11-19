# Module 5 — Constraints และ Synthesis

## 5.1 วัตถุประสงค์และแนวคิดสำคัญ

Synthesis คือการแปลงคำอธิบายพฤติกรรมและโครงสร้างใน RTL ให้เป็นวงจรที่สร้างได้ด้วยเซลล์ใน technology library ภายใต้ข้อกำหนดของโครงการ ผลลัพธ์ที่ต้องการจึงไม่ใช่เพียง netlist ที่สร้างสำเร็จ แต่เป็น netlist ที่รักษาฟังก์ชัน มีโครงสร้างครบถ้วน ใช้เซลล์ถูกชนิด และได้รับการประเมินภายใต้สมมติฐานด้าน timing ที่ตรวจสอบได้

Constraints ทำหน้าที่อธิบายสัญญาระหว่างวงจรกับสภาพแวดล้อม ได้แก่ clock ที่เข้ามา เวลาที่ข้อมูลขาเข้ามาถึง เวลาที่อุปกรณ์ปลายทางต้องการข้อมูล ความเร็วของขอบสัญญาณขาเข้า และโหลดที่ขาออก หากสัญญานี้ผิด การ optimize อาจทำงานได้ดีต่อโจทย์ที่ผิด และรายงาน timing อาจดูดีโดยที่ชิปใช้งานจริงไม่ได้

เมื่อเรียนจบ ผู้เรียนต้องสามารถ:

- แยก elaboration, optimization และ technology mapping ออกจากกันได้
- ตรวจ unconnected ports, undriven nets, unintended latches และ unresolved references พร้อมอธิบายผลกระทบ
- สร้าง SDC จาก interface specification โดยระบุทั้ง early และ late environment
- ตรวจ clock coverage, I/O delay coverage และ unconstrained endpoints ก่อนตีความ WNS/TNS
- รายงาน cell area พร้อมหน่วยและขอบเขต โดยไม่สับสนกับ core area หรือ die area
- อธิบายข้อจำกัดของผล timing และ area ก่อน physical implementation ได้

## 5.2 Input และ output ของงาน synthesis

| Input | สิ่งที่ต้องยืนยัน |
|---|---|
| RTL และ source manifest | top ถูกตัว, compile order ถูกต้อง, ไม่มีไฟล์ testbench ปะปน |
| Parameters/generics/defines | configuration ตรงกับสินค้าที่จะสร้าง |
| Technology Liberty | function, sequential behavior, timing และ corner ถูกต้อง |
| Macro models | SRAM/ROM/IP มี interface และ timing model ตรงกัน |
| Constraints | clock, I/O, load, transition, exceptions ครบและมีที่มา |
| Tool settings | HDL version, target library, forbidden cells, optimization policy |

ผลลัพธ์ควรมี mapped netlist, synthesis log, structural checks, cell statistics, timing reports, constraint coverage และข้อมูลเวอร์ชันที่ทำให้รันซ้ำได้ หาก flow ส่งออก SDC หลัง synthesis ต้องตรวจว่าชื่อ object และ clock relations ยังถูกต้อง อย่าเชื่อว่าไฟล์ที่ถูกเขียนออกมาใหม่ย่อมสมบูรณ์โดยอัตโนมัติ

ในหลักสูตร Tanner Digital ASIC Design Implementation ให้ใช้หลักการเดียวกันนี้กับ synthesis engine และ timing analyzer ที่ติดตั้งจริง คำสั่งของ Oasys-RTL, Precision, Tanner รุ่นต่าง ๆ หรือเครื่องมืออื่นไม่ควรถูกสันนิษฐานว่าใช้แทนกันได้ ตัวอย่าง Yosys/OpenSTA ในบทนี้เป็นเส้นทางสาธิตที่ระบุเครื่องมือชัดเจน ไม่ใช่คำสั่ง Tanner โดยตรง

## 5.3 Elaboration: จาก source code สู่โครงสร้างที่แน่นอน

### 5.3.1 สิ่งที่เกิดระหว่าง elaboration

เครื่องมืออ่าน HDL ตรวจ syntax และชนิดข้อมูล ผูก module/entity กับ instance ประเมิน parameter/generic ขยาย generate และ loop ที่ใช้สร้างฮาร์ดแวร์ และกำหนดความกว้างของสัญญาณ โครงสร้างหลังขั้นนี้ต้องมีความหมายแน่นอนสำหรับ configuration ที่เลือก

ตัวอย่าง `WIDTH=8` และ `WIDTH=32` ไม่ได้เป็นวงจรเดียวกันที่ใช้พื้นที่เท่ากัน จำนวน flip-flop, adder width, comparator และเส้นทาง carry เปลี่ยนไปด้วย เช่นเดียวกับการเปิด debug, multiplier หรือ SRAM option ผ่าน define

ควรบันทึก configuration เป็นตาราง:

| รายการ | ตัวอย่าง |
|---|---|
| Top | `accum` |
| Data width | 8 bits |
| Reset | synchronous, active high |
| Clock domain | `clk`, 100 MHz |
| Enable | synchronous กับ `clk` |
| Arithmetic | unsigned, wrap modulo 256 |

### 5.3.2 Compile order และ unresolved references

VHDL ต้องวิเคราะห์ package และ entity ที่จำเป็นก่อนผู้เรียกใช้ และต้องเลือก library/architecture ให้ถูกต้อง SystemVerilog ต้องจัด package, include paths, macro definitions และ source order ให้ตรงกับ frontend

Unresolved reference หมายถึง instance อ้างถึง design unit หรือ cell ที่เครื่องมือผูกไม่ได้ สาเหตุอาจเป็นไฟล์ตกหล่น ชื่อสะกดผิด define ปิดส่วนที่จำเป็น หรือ IP ไม่มี model ห้ามแก้ด้วยการประกาศ black box ทุกตัวเพียงเพื่อให้ flow ผ่าน

Black box ใช้ได้เมื่อเป็นสิ่งตั้งใจ เช่น SRAM hard macro แต่ต้องมีหลักฐานครบสำหรับขั้นถัดไป: logical interface, Liberty, LEF และ layout/LVS views ตาม flow นอกจากนี้ต้องมี simulation model ใน verification environment และต้องตรวจว่าขา clock, control, bus order และ power pins ตรงกัน Black box declaration อย่างเดียวไม่ให้ timing ภายในหรือ timing arcs ของ macro

## 5.4 ตัวอย่าง RTL คู่ขนาน: accumulator พร้อม enable

วงจรต่อไปนี้ใช้ synchronous reset เพื่อให้ตัวอย่าง timing เน้น synchronous paths ทั้งหมด `rst`, `en` และ `din` ต้องได้รับการขับตาม interface timing ที่กำหนด ไม่ใช่สัญญาณ asynchronous ที่ต่อเข้ามาโดยตรง

### SystemVerilog

```systemverilog
module accum #(
  parameter int unsigned WIDTH = 8
) (
  input  logic             clk,
  input  logic             rst,
  input  logic             en,
  input  logic [WIDTH-1:0] din,
  output logic [WIDTH-1:0] q
);
  always_ff @(posedge clk) begin
    if (rst)
      q <= '0;
    else if (en)
      q <= q + din;
  end
endmodule
```

### VHDL-2008

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity accum is
  generic (WIDTH : positive := 8);
  port (
    clk : in  std_logic;
    rst : in  std_logic;
    en  : in  std_logic;
    din : in  unsigned(WIDTH-1 downto 0);
    q   : out unsigned(WIDTH-1 downto 0)
  );
end entity;

architecture rtl of accum is
  signal q_reg : unsigned(WIDTH-1 downto 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        q_reg <= (others => '0');
      elsif en = '1' then
        q_reg <= q_reg + din;
      end if;
    end if;
  end process;
  q <= q_reg;
end architecture;
```

เมื่อ enable เป็นศูนย์ register คงค่าเดิม การไม่มี `else` ใน clocked process นี้ไม่ใช่ latch ส่วนผลบวกที่เกิน WIDTH ถูกตัดทิ้งตามเจตนา wrap arithmetic หากต้องเก็บ carry ต้องเพิ่มบิตอย่างชัดเจนทั้งสองภาษา

โครงสร้างคาดหมายคือ register WIDTH บิต, adder และวงจรเลือก/ควบคุมข้อมูล รูปแบบ mapped netlist อาจต่างกันได้ตาม library เช่นใช้ mux ก่อน D pin หรือเซลล์ sequential ที่รองรับ enable ห้ามกำหนดจำนวน gate ตายตัวก่อนทราบ library และ optimization settings

## 5.5 Optimization: รักษาความหมายและปรับโครงสร้าง

Optimization อาจทำ constant propagation, Boolean simplification, dead-code removal, resource sharing, mux restructuring, FSM optimization และการปรับความกว้างของ logic ที่พิสูจน์ได้ว่าไม่จำเป็น

ตัวอย่าง หาก output ไม่ถูกใช้งาน cone ที่ขับ output นั้นอาจถูกลบทิ้ง ถ้า enable ถูกผูกศูนย์ accumulator อาจเหลือเพียงค่าคงที่หลัง reset พื้นที่ที่ลดลงมากจึงอาจสะท้อนวงจรที่ถูกตัดออกเพราะการเชื่อมต่อผิด มากกว่าคุณภาพของการ optimize

ก่อนยอมรับผลต้องถามว่า:

1. Register และ interface สำคัญยังอยู่ครบหรือไม่?
2. Constant ที่แพร่กระจายมีที่มาจาก specification หรือการผูกสัญญาณผิด?
3. Width/sign extension ตรงกับ RTL intent หรือไม่?
4. FSM encoding และ reset state เปลี่ยนโดยยังรักษาพฤติกรรมหรือไม่?
5. มีการเปลี่ยน boundary ของ register เช่น retiming หรือไม่ และ verification รองรับหรือยัง?

การเทียบ waveform เพียงไม่กี่ช่วงไม่พิสูจน์ equivalence ทั้งวงจร ใช้ self-checking regression และ formal equivalence เมื่อ flow รองรับ โดยเฉพาะหลังปรับ optimization policy หรือทำ ECO

## 5.6 Technology mapping: เลือกวงจรจากเซลล์จริง

Technology mapping แปลง generic operators เช่น AND, mux, adder และ flip-flop ให้เป็นเซลล์จาก target library เซลล์ที่มี function เหมือนกันอาจมี drive strength, pin capacitance, delay, leakage และ area ต่างกัน

การลด delay ด้วยเซลล์ใหญ่ขึ้นอาจเพิ่ม capacitance ที่ stage ก่อนหน้าเห็น เพิ่ม dynamic power และพื้นที่ บางครั้งต้องเปลี่ยนโครงสร้าง logic หรือเพิ่ม pipeline จึงจะได้ผลตามเป้าหมาย ไม่ใช่เพิ่ม drive strength ไปเรื่อย ๆ

สิ่งที่ต้องตรวจหลัง mapping:

- ไม่มี generic cell ที่ขั้น physical implementation ไม่รู้จักหลงเหลือ
- Sequential cells มี clock edge, reset/set polarity และ behavior ถูกต้อง
- ทุก mapped cell resolve ได้กับ library ที่ใช้ใน STA และ physical views
- ไม่ใช้เซลล์ที่โครงการห้าม เช่น scan-only หรือเซลล์ที่ไม่มี physical view
- Macro instances ยังคงอยู่ตามแผน ไม่ถูกแทนด้วย implementation ที่ไม่ตั้งใจ

Timing-driven synthesis ต้องมี interface ส่ง constraints เข้าสู่ optimizer จริง การมีไฟล์ SDC อยู่ในโฟลเดอร์ไม่ได้แปลว่า mapper ใช้มัน ตัวอย่าง Yosys แบบพื้นฐานในบทนี้ไม่ได้อ่าน SDC ทั้งชุดเพื่อ optimize ตามทุก path constraint

## 5.7 Structural checks และการจัดการ warning

| ปัญหา | ความหมายและผลกระทบ | วิธีจัดการ |
|---|---|---|
| Unconnected input | ขา instance ไม่มีแหล่งขับที่ตั้งใจ | ต่อสัญญาณหรือ tie ตาม specification; อย่าปล่อยลอย |
| Unconnected output | ผลลัพธ์ไม่ถูกใช้งาน | อาจตั้งใจได้ แต่ต้องทบทวนว่าฟังก์ชันหายหรือไม่ |
| Undriven net | มีผู้ใช้สัญญาณแต่ไม่มี driver | ตรวจ typo, missing assignment, generate และ black box interface |
| Multiple drivers | สัญญาณมีผู้ขับขัดแย้ง | รวม ownership ของ register/net; ตรวจ tri-state ที่รองรับจริง |
| Unintended latch | combinational process ต้องจำค่าเดิมบางเงื่อนไข | กำหนด default หรือครอบคลุมทุก branch |
| Unresolved reference | ไม่พบ module/entity/cell definition | แก้ manifest/library binding; อนุมัติ black box เฉพาะที่ตั้งใจ |
| Combinational loop | feedback ไม่มี storage ที่นิยามถูกต้อง | ตรวจ feedback, handshake และ assignment |

Unconnected port กับ undriven net ไม่ใช่คำเดียวกัน: output ที่ตั้งใจไม่ใช้ต่างจาก net ที่ถูกอ่านโดยไม่มี driver และ top-level input มี driver จากภายนอกจึงไม่ใช่ undriven เพียงเพราะไม่มี logic ภายในขับมัน

### ตัวอย่าง latch ที่ไม่ตั้งใจ

```systemverilog
// ผิดสำหรับ combinational mux: ไม่มี assignment เมื่อ sel=0
always_comb begin
  if (sel) y = a;
end

// ถูก: กำหนดทุกทางเลือก
always_comb begin
  y = b;
  if (sel) y = a;
end
```

```vhdl
-- ผิดสำหรับ combinational mux
process(all)
begin
  if sel = '1' then
    y <= a;
  end if;
end process;

-- ถูก
process(all)
begin
  y <= b;
  if sel = '1' then
    y <= a;
  end if;
end process;
```

Latch ที่ตั้งใจใช้งานต้องมี architecture, timing model และ STA methodology รองรับ สำหรับบทเริ่มต้นนี้ตั้งเป้า unintended latch = 0 อย่าลบ warning ด้วยการซ่อนข้อความหรือเปลี่ยนค่าที่ไม่ทราบเป็นศูนย์โดยไม่ตรวจความหมาย

## 5.8 SDC คือโมเดลของ external environment

### 5.8.1 เริ่มจาก interface specification

ก่อนเขียนคำสั่งต้องตอบให้ได้ว่า external device launch/capture ด้วย clock ใด ข้อมูลเปลี่ยนเร็วที่สุดและช้าที่สุดเมื่อใด มี PCB delay เท่าใด และ output ขับอะไร

สำหรับ input ที่มาจาก register ภายนอกโดยอ้างอิง clock เดียวกันในโมเดลง่าย:

`input_delay_max = external_tCQ_max + data_board_delay_max`

`input_delay_min = external_tCQ_min + data_board_delay_min`

สำหรับ output ไป register ภายนอก:

`output_delay_max = external_tsetup + data_board_delay_max`

`output_delay_min = data_board_delay_min - external_thold`

สมการนี้สมมติ reference clock และ clock-board skew ถูกจัดการไว้แล้ว หาก clock arrival ของต้นทางและปลายทางต่างกัน ต้องใส่ความสัมพันธ์นั้นในโมเดล clock/latency หรือ delay budget ให้ถูกต้อง โดยไม่บวกซ้ำ

ค่า output delay min เป็นลบได้: หาก board delay ต่ำสุด 0.10 ns และ receiver hold 0.30 ns จะได้ −0.20 ns นี่คือข้อกำหนดให้ข้อมูลคงอยู่หลัง reference edge ตามเวลาที่เหลือ ไม่ใช่ propagation delay ติดลบ

### 5.8.2 ตัวอย่าง budget สำหรับ accumulator

| รายการ | ค่าเพื่อการสอน | ที่มาในงานจริง |
|---|---:|---|
| Clock period | 10.00 ns | system frequency specification |
| Input late arrival | 2.00 ns | external tCQ max + board max |
| Input early arrival | 0.40 ns | external tCQ min + board min |
| Output setup budget | 1.50 ns | receiver setup + board max |
| Output hold budget | −0.20 ns | board min − receiver hold |
| Setup uncertainty | 0.25 ns | jitter และ margin ที่จัดสรร |
| Hold uncertainty | 0.10 ns | hold uncertainty model |
| Input transition | 0.15 ns | driver/pad/board characterization |
| Output capacitance | 0.03 pF | receiver pin + board model |

ตัวเลขทั้งหมดเป็นสมมติฐานสำหรับแบบฝึกหัด ไม่ใช่ค่ามาตรฐานของ PDK หรือบอร์ดใด ต้องแทนด้วยข้อมูลจริงก่อนนำไปใช้กับชิป

### 5.8.3 ตัวอย่าง SDC

```tcl
# accum.sdc
# สมมติ tool ใช้หน่วยเวลา ns และ capacitance pF: ตรวจ units ก่อนอ่าน
create_clock -name SYS_CLK -period 10.000 [get_ports clk]

set_clock_uncertainty -setup 0.250 [get_clocks SYS_CLK]
set_clock_uncertainty -hold  0.100 [get_clocks SYS_CLK]

# ทั้งสามกลุ่มเป็น synchronous data/control inputs
set data_in [get_ports {din* en rst}]
set_input_delay -clock SYS_CLK -max 2.000 $data_in
set_input_delay -clock SYS_CLK -min 0.400 $data_in
set_input_transition 0.150 $data_in

set data_out [get_ports {q*}]
set_output_delay -clock SYS_CLK -max  1.500 $data_out
set_output_delay -clock SYS_CLK -min -0.200 $data_out
set_load 0.030 $data_out
```

ตรวจ collection ทุกครั้งว่า `din*`, `q*` และชื่อ clock จับ object ที่ต้องการจริง จำนวนที่คาดหมายเมื่อ WIDTH=8 คือ data_in 10 ports และ data_out 8 ports เครื่องมือบางตัวใช้ collection object แทน Tcl list จึงต้องใช้คำสั่ง count ตาม API ของเครื่องมือนั้น ไม่ใช้ `llength` ข้ามทุกเครื่องมือโดยไม่ตรวจ

อย่าใช้ `all_inputs` อย่างไม่พิจารณา เพราะอาจรวม clock, asynchronous reset, JTAG หรือ analog control ที่ต้องมีโมเดลคนละแบบ ส่วนการกำหนดเฉพาะ `-max` ไม่อธิบาย early environment ครบถ้วน และค่า default ของเครื่องมืออาจทำให้ hold analysis ผิดจากสิ่งที่ตั้งใจ

สำหรับ OpenSTA หน่วยคำสั่งและรายงานอ้างอิงจาก Liberty แรกที่อ่าน จึงต้องตรวจหน่วยก่อนนำตัวอย่างไปใช้ หาก capacitance unit เป็น fF ค่า `0.030` จะไม่เท่ากับ 0.03 pF คำสั่ง `set_load` อธิบาย capacitive load ไม่ได้ทดแทน distributed board interconnect model ทั้งหมด

## 5.9 Clock modeling และ exceptions

Primary clock ต้องถูกสร้างที่จุดกำเนิดที่ถูกต้อง Clock ที่เกิดจาก divider หรือวงจรสร้าง clock ต้องมี generated-clock relationship ตามโครงสร้างจริง อย่าสร้าง independent clock แยกกันจนความสัมพันธ์ระหว่างต้นทางและปลายทางหายไป

ก่อน CTS มักใช้ ideal clock พร้อม uncertainty/latency ตาม methodology หลัง CTS ต้องใช้ propagated clock และ parasitics ตาม stage การนำ skew margin ก่อน CTS มาบวกซ้ำกับ clock tree จริงอาจทำให้ budget ผิด

### Reset และ CDC

ในตัวอย่าง accumulator reset เป็น synchronous จึงต้องตรวจ setup/hold เหมือน control input อื่น ห้ามใส่ false path ให้ reset เพียงเพราะชื่อว่า reset

หากใช้ asynchronous reset ต้องกำหนด reset architecture, asynchronous assertion/synchronous deassertion และวิธีตรวจ recovery/removal ที่สัมพันธ์กับ implementation จริง การยกเว้น path เข้า async pin แบบครอบคลุมทั้งโครงการอาจซ่อนการปล่อย reset ที่ไม่ปลอดภัย

Async clock groups หรือ false paths ตัดการวิเคราะห์ timing บางความสัมพันธ์ แต่ไม่ได้สร้าง synchronizer และไม่พิสูจน์ CDC correctness ต้องตรวจ CDC แยกด้วยโครงสร้างและ protocol ที่เหมาะสม

### False path และ multicycle path

- False path ใช้เมื่อพิสูจน์ได้ว่า path ไม่ต้องถูกตรวจตาม timing relationship นั้น ไม่ใช่ใช้แก้ slack ติดลบ
- Multicycle path ต้องมี protocol หรือ enable condition รับรองว่าข้อมูลมีหลาย cycle จริง และต้องตรวจทั้ง setup และ hold edge ที่เปลี่ยนไป
- ค่าที่มักสอนเป็น setup N และ hold N−1 ใช้กับเงื่อนไข clock/edge ที่เหมาะสมเท่านั้น ต้องตรวจ expanded timing report ไม่คัดลอกเป็นสูตรทั่วไป
- Case analysis ต้องตรงกับ mode ที่กำลังวิเคราะห์ และทุก functional/test mode ที่ใช้งานจริงต้องมี scenario ครอบคลุม

ทุก exception ควรมี owner, เหตุผล, source/destination, mode และหลักฐาน verification พร้อมจำนวน paths/objects ที่ครอบคลุม หาก collection ว่างหรือกว้างเกินไปต้องถือเป็นปัญหาของ constraints

## 5.10 ตรวจ coverage ก่อนอ่าน WNS/TNS

รายงาน slack มีความหมายเฉพาะส่วนที่ถูกสร้าง timing graph และได้รับ constraints อย่างเหมาะสม ดังนั้นลำดับตรวจที่ถูกต้องคือ:

1. ตรวจ link/library completeness และ timing arcs ของ sequential cells/macros
2. ตรวจ clocks: จำนวน, period, waveform, source และ generated relationships
3. ตรวจทุก register clock pin ว่าได้รับ clock ตาม domain ที่ออกแบบ
4. ตรวจ input/output delay ว่าครบทั้ง min/max สำหรับ interface ที่ต้องตรวจ
5. ตรวจ unconstrained endpoints และ paths ที่ไม่มี reference clock หรือ required time
6. ตรวจ disabled arcs, exceptions และ mode constants ว่าไม่ตัดเส้นทางสำคัญ
7. ตรวจ transition/capacitance/fanout violations
8. จึงพิจารณา setup/hold slack และหา root cause ของ critical paths

Clock coverage กับ timing coverage ต่างกัน Register อาจมี clock แล้ว แต่ output ยังไม่มี delay หรือ data input ยังไม่มี arrival model ได้ และ endpoint ที่มี slack ก็อาจใช้ clock relation ผิดได้เช่นกัน

### ตาราง audit ที่ควรแนบรายงาน

| รายการ | เกณฑ์ผ่าน |
|---|---|
| Expected clock domains | พบครบและความสัมพันธ์ถูกต้อง |
| Sequential clock pins without clock | 0 หรือมีเหตุผลเฉพาะ mode ที่อนุมัติ |
| Unconstrained functional endpoints | 0 |
| Missing I/O min/max delay | 0 สำหรับ interface ที่ต้องตรวจ |
| Missing macro timing models | 0 สำหรับ macro ที่อยู่ใน timing paths |
| Unexpected exceptions/disabled arcs | 0 |
| Unintended latches/unresolved references | 0 |

อย่ากำหนดเป้าหมาย “unconstrained = 0” ด้วยการเติม delay ศูนย์หรือ false path ให้ทุก port เพื่อปิด warning ต้องแก้ให้โมเดลอธิบายระบบจริง

## 5.11 การตีความ WNS, TNS และ timing paths

สำหรับ setup:

`slack_setup = required_time − arrival_time`

สำหรับ hold:

`slack_hold = earliest_arrival_time − required_hold_time`

WNS ใช้สรุป worst negative slack; บางเครื่องมือแสดงศูนย์เมื่อไม่มี violation ขณะที่รายงาน worst slack อาจแสดงค่าบวก ต้องดูนิยามของ report TNS โดยทั่วไปสะสม negative slack ตาม endpoint หรือ report convention ของเครื่องมือ ไม่ใช่ผลรวม delay และไม่ใช่ผลรวมทุก possible path เสมอไป

ตัวอย่าง WNS = −0.30 ns และ TNS = −8.40 ns บอกได้ว่ามี violation แต่ยังบอกไม่ได้ว่ามีกี่ endpoint หรือกระจุกอยู่ path group ใด ต้องอ่าน violating endpoint count และ detailed paths เพิ่ม ส่วน WNS=0/TNS=0 พร้อม unconstrained endpoints 80 จุดยังไม่ใช่ timing pass ที่ยอมรับได้

สำหรับ register-to-register path ที่ใช้ clock เดียวกัน แบบประมาณก่อน CTS:

`Tclk ≥ tCQ_max + tlogic_max + twire_max + tsetup + setup_uncertainty`

หาก Tclk=10 ns, tCQ=0.25, logic=6.80, wire=1.20, setup=0.20 และ uncertainty=0.25 ns จะมี required budget รวม 8.70 ns หรือ setup slack ประมาณ 1.30 ns ภายใต้สมมติฐานนี้ หลัง route ต้องแทน wire estimate ด้วย extracted parasitics และรวม clock insertion/skew ตามรายงานจริง

ห้ามนำ input delay หรือ output delay ไปบวกกับ register-to-register path โดยอัตโนมัติ เพราะ path classes มีสมการคนละส่วน ต้องแยก input-to-register, register-to-register, register-to-output และ input-to-output

เมื่ออ่าน critical path ให้ตรวจ startpoint, endpoint, launch/capture edge, path group, corner, cell delay, net delay, slew, capacitance และ uncertainty ก่อนตัดสินใจแก้ RTL

## 5.12 ตัวอย่างคำสั่งสาธิต synthesis และ STA

### 5.12.1 Yosys: SystemVerilog subset และ structural mapping

```tcl
# synth.ys — รันด้วย yosys -s synth.ys
# แทน path ให้ตรงกับ standard-cell library ที่โครงการอนุมัติ
read_liberty -lib /path/to/cells.lib
read_verilog -sv accum.sv
hierarchy -check -top accum
proc
check -assert
synth -top accum
dfflibmap -liberty /path/to/cells.lib
abc -liberty /path/to/cells.lib
clean
check -assert
stat -liberty /path/to/cells.lib
write_verilog -noattr accum_mapped.v
```

ตัวอย่างนี้ไม่ใช่ full SDC-driven synthesis flow และไม่ได้รับประกันว่า flop type ทุกชนิด map ได้ในทุก library ต้องตรวจ log, remaining generic cells และ mapped cell list ก่อนใช้ต่อ `check` ตรวจปัญหาโครงสร้างบางประเภท แต่ไม่ทดแทน latch policy, timing audit หรือ formal equivalence

สำหรับ VHDL ให้ใช้ VHDL frontend ที่ flow รองรับ หรือ export ด้วย GHDL synthesis ก่อนเข้าสู่ Verilog backend ตัวอย่างการแปลงใน environment ที่ติดตั้ง GHDL พร้อม synthesis support:

```bash
ghdl --synth --std=08 --out=verilog accum.vhd -e accum > accum_from_vhdl.v
```

จากนั้นเปลี่ยน `read_verilog -sv accum.sv` เป็นการอ่านไฟล์ที่ export แล้ว ชื่อ ports และ arithmetic behavior ต้องตรวจอีกครั้งกับ RTL reference การผ่านขั้น export ไม่พิสูจน์ equivalence อัตโนมัติ

### 5.12.2 OpenSTA: แยก validation ออกจาก optimization

```tcl
# sta.tcl — รันด้วย sta sta.tcl
read_liberty /path/to/cells.lib
read_verilog accum_mapped.v
link_design accum
read_sdc accum.sdc

report_units
report_clock_properties [all_clocks]
check_setup -verbose
report_checks -path_delay max -format full_clock_expanded
report_checks -path_delay min -format full_clock_expanded
report_wns
report_tns
```

ตรวจ `help` และ manual ของ build ที่ใช้จริงสำหรับ options และคำสั่งตรวจ missing I/O delays/unconstrained paths บางรุ่นใช้ `check_setup` ขณะที่ build ใหม่อาจมี `check_timing` เพิ่มเติม ต้องเก็บ coverage report ตามความสามารถของเวอร์ชันนั้น ไม่ถือว่า report script ชุดเดียวใช้ได้กับทุก release

การรันตัวอย่างนี้โดยไม่มี SPEF หรือ wire model เป็นการประเมิน timing ของ netlist ภายใต้ interconnect model ที่มี ณ ขั้นนั้น ไม่ใช่ post-route sign-off และไม่ใช่ผล timing optimization ของ mapper ต่อ SDC ทั้งหมด

## 5.13 Area: cell area, core area และ die area

### Cell area

โดยทั่วไปเป็นผลรวม `area` ของ mapped cell instances ตาม library/report convention:

`A_cells = Σ A_library(cell_instance)`

ต้องตรวจว่า Liberty `area` ถูกนิยามเป็น µm² หรือ library-specific units และ macro ถูกนับหรือไม่ การรวม library ที่มี area convention ต่างกันอาจทำให้ผลรวมไม่มีความหมายทางกายภาพ

### Core area

คือพื้นที่เขต core ที่กำหนดใน floorplan มีทั้งตำแหน่งวางเซลล์และพื้นที่สำหรับ routing, whitespace, blockages, macros หรือโครงสร้างอื่นตามนิยามของ flow จึงไม่เท่ากับผลรวม cell area

สำหรับ block ไม่มี macro อาจใช้ประมาณการเริ่มต้น:

`A_core ≈ A_standard_cells / target_utilization`

หาก cell area=12,000 µm² และ utilization=0.40 จะได้ core area ประมาณ 30,000 µm² หรือสี่เหลี่ยมจัตุรัสด้านประมาณ 173.2 µm ก่อนปรับ row/site snapping และ margin สูตรนี้เป็น starting estimate ไม่ใช่ floorplan acceptance criterion

เมื่อมี macros ควรแยก available standard-cell placement area ออกจาก macro area, halos และ blockages และใช้ utilization definition ของเครื่องมือจริง Die area รวมพื้นที่รอบ core เช่น IO ring และโครงสร้างขอบชิปตามการออกแบบ

### ตัวอย่างข้อความรายงานที่ถูกต้อง

“หลัง synthesis ได้ standard-cell area 12,000 µm² ตาม Liberty ของ corner ที่ระบุ ไม่รวม SRAM macro และ physical-only cells; core area ตั้งต้น 30,000 µm² ที่ target utilization 40%; ยังไม่ใช่พื้นที่หลัง CTS/route”

หลัง physical implementation อาจมี clock buffers, hold buffers, tie cells, tap/endcap/filler และการ resize เพิ่มขึ้น ต้องระบุว่า area report รวมเซลล์ประเภทใด ห้ามนำตัวเลขจากคนละ stage มาเปรียบเทียบโดยไม่ปรับขอบเขต

## 5.14 Workshop: Constraints ที่ถูกต้องสำคัญกว่า slack ที่ดูดี

### ขั้นที่ 1 — สร้าง baseline

ใช้ accumulator WIDTH=8 ทั้งสองภาษา ตรวจ reset, enable, overflow และข้อมูลต่อเนื่องด้วย self-checking testbench เก็บ source/configuration พร้อมผล regression แล้ว synthesize ด้วย target library เดียวกัน

### ขั้นที่ 2 — ตรวจโครงสร้าง

ยืนยัน hierarchy, flop width, arithmetic width, latch count, driver checks และ unresolved references หาก mapped area ต่ำผิดปกติ ให้ตรวจ cone ที่ถูกลบก่อนสรุปว่าได้วงจรที่มีประสิทธิภาพสูง

### ขั้นที่ 3 — สร้าง SDC จาก budget

เขียนที่มาของตัวเลขทุกค่าในตาราง external environment ตรวจ unit และ object matching จากนั้นอ่าน SDC เข้า STA และเก็บ clock/I/O coverage ก่อนเก็บ WNS/TNS

### ขั้นที่ 4 — ทดลองใส่ข้อผิดพลาด

| การทดลอง | สิ่งที่ต้องตรวจพบ |
|---|---|
| ลบ `create_clock` | sequential timing ขาด clock/reference |
| ลบ output delay | output endpoints ขาด required-time environment |
| สะกด `din*` ผิด | collection ว่างหรือ coverage ไม่ครบ |
| ต่อ enable เป็นศูนย์ | logic ถูกลดรูปจาก configuration ที่ผิด |
| ลบ default ใน combinational mux | latch inference หรือ frontend diagnostic |
| ลบ source ของ child module | hierarchy/link failure |
| ใส่ false path กว้างเกินจริง | exception review พบ functional paths ถูกตัด |

ผู้เรียนต้องอธิบายได้ว่าทำไมบางการทดลองทำให้ WNS/TNS ดูดีขึ้นทั้งที่โมเดลแย่ลง แล้วคืน baseline ก่อนดำเนินการต่อ

### ขั้นที่ 5 — Sweep clock period

ทดลอง 20, 10 และ 5 ns หาก synthesis engine รองรับ timing constraints จริง ให้ optimize ใหม่ทุกจุดและเทียบ area/timing หากเพียงเปลี่ยน SDC ใน STA บน netlist เดิม ต้องรายงานว่าเป็นการเปลี่ยน requirement เพื่อประเมิน slack โดยโครงสร้างและ cell area ยังเดิม

### ขั้นที่ 6 — ส่งผลและประเมิน

Deliverables ประกอบด้วย RTL สองภาษา, manifest, constraints พร้อม budget, synthesis/STA scripts, logs, coverage audit, mapped netlist และตารางผลแยก stage/library/corner หน่วย timing และ area ต้องชัดเจน

เกณฑ์ผ่าน: functional regression ผ่าน, ไม่มี unintended latches/undriven nets/unresolved references, clock coverage ครบ, ไม่มี unconstrained functional endpoints, exceptions มีเหตุผล และแยก cell area/core area ได้ถูกต้อง การผ่าน setup ก่อน route ไม่ถูกนำไปอ้างว่า sign-off ผ่านแล้ว

## 5.15 แนวทางวิเคราะห์ปัญหา

| อาการ | ตรวจเป็นอันดับแรก | แนวทางแก้ |
|---|---|---|
| WNS ดีผิดปกติ | clock/I/O coverage, constants, exceptions | ซ่อมโมเดลก่อน optimize |
| Area เล็กผิดปกติ | top ผิด, output ไม่ใช้, reset/enable ค้าง | ซ่อม configuration และ connectivity |
| Area ใหญ่ผิดปกติ | width, inferred memory, unrolled logic | ปรับ architecture และ macro inference |
| Setup violation | clock relation, logic depth, slew/load | ปรับ logic/pipeline/drive ตาม root cause |
| Hold violation | min delay, early input, clock relation | ใช้ hold methodology ตาม stage; ไม่แก้ด้วยการลด frequency |
| Macro path ไม่มี timing | Liberty/link/clock/control arcs | ใช้ model ที่ถูกต้องและตรวจ coverage |
| RTL sim ผ่าน แต่ netlist ผิด | signedness, X assumptions, unsupported HDL | ลด testcase และตรวจ equivalence |

## 5.16 คำถามทบทวนและแนวคำตอบ

1. **WNS=0 และ TNS=0 เพียงพอหรือไม่?** ไม่เพียงพอ ต้องตรวจ coverage, clocks, exceptions, corners และ checks ที่เกี่ยวข้องก่อน
2. **ทำไม input delay ต้องมี min และ max?** เพื่ออธิบายเวลามาถึงเร็วสุดและช้าสุด ซึ่งมีผลต่อ hold และ setup ตามลำดับ
3. **ทำไม output delay min จึงติดลบได้?** เพราะอาจต้องคงข้อมูลหลัง reference edge เพื่อให้ผ่าน external hold เมื่อหัก board min delay แล้ว
4. **ทำไม cell area ไม่ใช่ core area?** Cell area รวมพื้นที่ตามเซลล์ที่นับ ขณะที่ core มี whitespace และข้อจำกัดทาง physical implementation ด้วย
5. **Unconnected output ทุกตัวเป็น error หรือไม่?** อาจตั้งใจไม่ใช้ได้ แต่ต้องตรวจว่าไม่ได้ตัดฟังก์ชันสำคัญและบันทึกเหตุผล
6. **False path แก้ CDC ได้หรือไม่?** ไม่ได้ มันเปลี่ยนขอบเขตการวิเคราะห์ timing แต่ไม่สร้างวงจร CDC ที่ปลอดภัย
7. **เปลี่ยน clock จาก 10 เป็น 20 ns แก้ hold ได้หรือไม่?** โดยทั่วไปไม่แก้ same-edge hold violation ต้องวิเคราะห์ min path และ clock relationship
8. **อ่าน SDC ใน STA แล้วหมายความว่า synthesis ใช้ SDC หรือไม่?** ไม่ใช่ ต้องตรวจ integration ของ optimizer แยกกัน

## 5.17 เอกสารอ้างอิงและขอบเขตการใช้งาน

- OpenSTA, Commands: https://opensta.readthedocs.io/en/latest/Commands/
- OpenSTA, Examples และหน่วยจาก Liberty: https://opensta.readthedocs.io/en/latest/Examples/
- YosysHQ, Synthesis commands: https://yosyshq.readthedocs.io/projects/yosys/en/latest/using_yosys/synthesis/synth.html
- YosysHQ, Synthesis starter: https://yosyshq.readthedocs.io/projects/yosys/en/v0.70/getting_started/example_synth.html
- คู่มือของ synthesis/STA engine และ PDK release ที่ติดตั้งจริงเป็นแหล่งอ้างอิงหลักสำหรับคำสั่ง ข้อจำกัด HDL และ sign-off requirements ของโครงการ

ตัวอย่างโค้ดและตัวเลขในบทนี้เป็นเนื้อหาสาธิตที่ต้องตรวจด้วย toolchain และ library ของผู้เรียน ยังไม่มีการรัน synthesis/STA กับ PDK จริงเพื่อยืนยันผล PPA ในเอกสารนี้
