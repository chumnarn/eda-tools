# Module 10 — Integration และ release

## 10.1 วัตถุประสงค์และขอบเขต

บทนี้อธิบายการส่งมอบ digital block ที่ทำ physical implementation แล้ว เพื่อให้ทีม analog/mixed-signal นำไปประกอบเป็นระบบแบบ **analog-on-top** โดยต้องส่งทั้งข้อมูลที่ใช้ประกอบและหลักฐานว่าข้อมูลนั้นใช้ได้ภายใต้เงื่อนไขใด

เมื่อจบบท ผู้เรียนต้องสามารถกำหนด boundary ของ block จัดทำ signal/supply/voltage/timing contract ตรวจความสอดคล้องของแต่ละ view สร้าง release ที่ตรวจสอบย้อนกลับได้ และอธิบายได้ว่ารายงานระดับ block ใดต้องตรวจซ้ำที่ระดับ full chip

คำว่า release ในที่นี้หมายถึงชุดข้อมูลที่ถูก freeze พร้อมสถานะการตรวจรับ ไม่ได้หมายความว่าผ่าน tape-out โดยอัตโนมัติ ส่วนคำว่า sign-off ต้องระบุขอบเขต corner, mode, deck และเกณฑ์ที่ผู้รับงานยอมรับเสมอ

Siemens วาง Digital Implementer ไว้ในบริบทของการทำ digital implementation สำหรับงาน analog/mixed-signal [1] อย่างไรก็ตาม ชื่อเมนู รูปแบบฐานข้อมูล คำสั่ง export และความสามารถที่เปิดใช้งานขึ้นกับรุ่นและ license ที่ติดตั้ง บทนี้จึงใช้ workflow และ deliverable contract เป็นหลัก ส่วนตัวอย่าง SDC เป็นแนวทางมาตรฐานที่ต้องตรวจ syntax และหน่วยกับเครื่องมือจริง

## 10.2 สถาปัตยกรรม analog-on-top

ใน analog-on-top ทีม top-level มักใช้ schematic และ custom layout เป็นจุดรวม analog circuits, digital macros, clocks, power domains และวงจร I/O ขณะที่ digital block ถูกนำเข้าเป็น hard macro พร้อม interface ที่กำหนดแล้ว

digital block ควรมีอย่างน้อยสามตัวแทนที่สัมพันธ์กัน:

1. **Logical view**: interface และ gate-level netlist สำหรับเชื่อมวงจรและตรวจ connectivity
2. **Physical view**: layout จริง พร้อม abstract ที่บอก boundary, pins และ routing obstructions
3. **Behavior/timing view**: simulation model, timing model หรือ netlist พร้อม timing collateral ตามวิธีวิเคราะห์ที่ตกลงกัน

ตัว schematic symbol มีหน้าที่ช่วยเชื่อมต่อ ไม่ได้ยืนยันว่าระดับแรงดันถูกต้อง ตัว LEF abstract มีหน้าที่ให้ข้อมูลทางกายภาพสำหรับ integration ไม่ได้แทน geometry ทั้งหมดใน GDS/OASIS และการมี functional model ไม่ได้หมายความว่ามี timing model ที่ผ่าน characterization แล้ว

### ตารางแบ่งความรับผิดชอบ

| หัวข้อ | ทีม digital block | ทีม full-chip/analog-on-top |
|---|---|---|
| RTL และการทำงาน | สร้างและตรวจตาม block specification | ตรวจการทำงานร่วมกับระบบ |
| Placement/CTS/routing ภายใน | รับผิดชอบ implementation ภายใน boundary | ตรวจผลกระทบจากบริบท top-level |
| Power ภายใน block | rails/straps และการเข้าถึง supply pins | จ่ายไฟถึง block, เชื่อม power domains, ตรวจเครือข่ายรวม |
| Timing | ปิด timing ตาม interface budget | ตรวจ inter-block path และ clock relationships จริง |
| Isolation/level shifter | ทำตามตำแหน่งที่ contract ระบุ | ตรวจ crossing ทั้งระบบและ power sequence |
| Pad ring/ESD | ระบุความต้องการ I/O ของ block | จัด pad cells, clamps, discharge paths และตรวจ ESD |
| Package | ให้ข้อมูล activity/current และ timing ที่จำเป็น | จัด bond map, package parasitics และข้อจำกัด package |
| Physical verification | block DRC/LVS ตามขอบเขต | full-chip DRC/LVS/ERC และ boundary interactions |

ต้องระบุเจ้าของให้ชัดเจนเป็นรายโครงการ โดยเฉพาะ level shifter, isolation, well ties, guard rings และขอบเขต power straps ซึ่งอาจอยู่ฝั่งใดฝั่งหนึ่งได้

## 10.3 กำหนด physical boundary ก่อนเริ่ม integration

boundary ไม่ใช่เพียงกรอบภาพ ต้องระบุอย่างน้อย:

- ชื่อ top cell, ขนาดกว้าง/สูง, origin และหน่วยพิกัด
- ระบุว่าขนาดนั้นหมายถึง core, placement area หรือ macro boundary
- รูปทรง boundary และ placement orientations ที่อนุญาต
- โลหะที่ใช้ภายใน ชั้นที่สงวนให้ top-level และบริเวณห้ามเดินสาย
- พิกัด รูปทรง ชั้นโลหะ และจำนวน access shapes ของแต่ละ pin
- ระยะ keepout/halo และพื้นที่สำหรับ top-level routing/power access
- เจ้าของ well, substrate contacts, guard rings, boundary cells และ fill

ตัวอย่างสำหรับการสอน: macro `dig_ctrl` ขนาด 200 × 150 µm มี origin ที่มุมซ้ายล่าง อนุญาตเฉพาะ R0 จนกว่าจะตรวจ orientation อื่นแล้ว ใช้ M1–M4 ภายในและเปิด supply access บน M4 ค่าเหล่านี้เป็นสมมติฐานการฝึก ไม่ใช่ข้อกำหนด PDK ใด

การย้ายหรือหมุน macro ต้อง transform pin coordinates, power access และ keepout อย่างสอดคล้องกัน ห้ามถือว่า macro ที่วางแบบ R0 ผ่านแล้วจะ mirror ได้ทุกกรณี เพราะข้อจำกัดเรื่อง well, power connection หรือ layout-dependent effects อาจต่างกัน

**จุดตรวจสำคัญ:** LEF size/origin และ GDS boundary ต้องตรงกันตาม convention ที่ตกลง ส่วน pin shapes ต้องตกบน geometry ของ net เดียวกันจริง ไม่ใช่เพียงมีชื่อเดียวกัน

## 10.4 Signal contract

signal contract ต้องตอบได้ว่าสัญญาณแต่ละเส้นถูกขับจากที่ใด รับที่ใด อยู่ใน clock/voltage domain ใด และมีพฤติกรรมอย่างไรระหว่าง reset กับ power transitions

| Pin | ทิศทางจาก block | Domain | ความหมายและข้อกำหนด |
|---|---|---|---|
| `clk_i` | Input | VDDD | clock หลัก; ระบุ period, duty cycle, slew, jitter |
| `rst_ni` | Input | VDDD | reset active-low; ระบุ assertion/deassertion protocol |
| `enable_i` | Input | VDDD | synchronous กับ `clk_i`; ต้องผ่าน setup/hold |
| `code_i[7:0]` | Input | VDDD | unsigned code; รับค่าเมื่อ enable เป็น 1 |
| `code_o[7:0]` | Output | VDDD | registered code; valid หลัง sampling edge |
| `valid_o` | Output | VDDD | ระบุว่า output ถูกอัปเดตในรอบนั้น |
| `VDDD` | Supply | Digital | positive supply ของ block |
| `VSSD` | Supply | Digital | reference return ของ block |

สำหรับ bus ต้องระบุ bit ordering และ mapping เช่น `code_i[7]` คือ MSB รวมทั้งวิธีแปลงชื่อระหว่าง HDL, schematic, extraction และ layout เช่น square brackets หรือ angle brackets ต้องมี mapping ที่ตรวจสอบได้ ไม่ใช้การเปลี่ยนชื่อแบบคาดเดา

ถ้า signal มาจาก comparator หรือวงจร analog จะยังไม่ถือว่า synchronous เพียงเพราะเปลี่ยนช้ากว่า clock ต้องวิเคราะห์ metastability, pulse width และ protocol สัญญาณ single-bit อาจใช้ synchronizer ตามความเหมาะสม แต่ multi-bit data ต้องใช้ handshake, stable-data window, asynchronous FIFO หรือวิธีที่พิสูจน์ความสอดคล้องของข้อมูลได้ ไม่ส่งแต่ละ bit ผ่าน synchronizer อิสระแล้วถือว่าคำข้อมูลถูกต้อง

## 10.5 Supply และ voltage contract

ต้องแยก **ชื่อ supply** ออกจาก **คุณสมบัติทางไฟฟ้า** การตั้งชื่อเป็น `VDDD` ไม่ได้บอก nominal voltage, tolerance หรือ sequence

| รายการ | สิ่งที่ต้องระบุ |
|---|---|
| แรงดัน | nominal/min/max operating voltage และ PVT ที่ตรวจ |
| Library compatibility | cell library และ voltage domains ที่ใช้ได้ |
| Logic compatibility | VIH/VIL/VOH/VOL หรือข้อกำหนดของ receiver/driver ที่เกี่ยวข้อง |
| Supply access | pin shapes/layers และวิธีเชื่อมเข้ากับ power grid |
| Power sequence | ลำดับเปิด/ปิด, reset, isolation และสถานะ output |
| Current | average/peak ตาม workload พร้อมวิธีได้มาและช่วงเวลา |
| Return path | ตำแหน่ง return และข้อกำหนด noise/ground reference |
| Verification | global-net rules, ERC checks และขอบเขต IR/EM ที่ตรวจ |

ห้ามใช้ค่า absolute maximum rating แทน operating voltage และห้ามต่อสัญญาณข้ามแรงดันโดยอาศัยเพียงว่า logic simulation ให้ค่า 0/1 ถูกต้อง

### 10.5.1 Mapping ของ power pins

จัดตารางชื่อในทุก view เช่น:

| ความหมาย | Top schematic | Block physical pin | Cell-library pin | LVS treatment |
|---|---|---|---|---|
| Digital supply | `VDDD_TOP` | `VDDD` | ชื่อจริงตาม library | ระบุ connection/mapping อย่างชัดเจน |
| Digital return | `VSSD_TOP` | `VSSD` | ชื่อจริงตาม library | ระบุ connection/mapping อย่างชัดเจน |

ตรวจว่า netlist สำหรับ LVS มี power representation ตาม deck ที่ใช้ บาง flow ใช้ explicit pins บาง flow ใช้ global nets และบาง flow ต้องมี netlist สำหรับ simulation กับ LVS แยกกัน การเพิ่ม `inout VDDD` ใน HDL อย่างเดียวไม่ได้เชื่อม standard-cell power pins หรือสร้าง power grid

ต้องตรวจ connectivity ของ rails, straps, vias, well/substrate ties และ pin access ทั้งหมด Global-net declaration เป็นกฎทาง connectivity ไม่ใช่หลักฐานว่าโลหะเชื่อมถึงกันจริง และห้ามใช้ alias ที่ทำให้คนละ power domain รวมกันเพื่อให้ LVS ผ่าน

### 10.5.2 Noise และ mixed-signal behavior

digital switching current อาจกระทบ analog ผ่าน supply impedance, return paths, substrate และ coupling การแยกชื่อ VDDD/VDDA หรือ VSSD/VSSA ไม่ได้ทำให้ noise แยกกันโดยอัตโนมัติ ต้องออกแบบเส้นทางกระแสและการเชื่อมต่อให้สอดคล้องกับ PDK และระบบจริง

พิจารณาการวาง macro ให้ห่าง sensitive nodes, การกำหนด routing keepout, shielding ที่มี return เหมาะสม, decoupling และช่วงเวลาการเปลี่ยน digital outputs หาก analog มี sampling window ต้องกำหนด quiet window เป็นข้อกำหนดที่ตรวจได้ ไม่ใช้คำว่า “digital noise ต่ำ” โดยไม่มีเงื่อนไขวัด

## 10.6 Timing contract ที่ boundary

Timing contract ควรระบุ clock source, frequency range, waveform, uncertainty, input delay min/max, output requirement min/max, input transition, output load และ modes/corners ที่ต้องผ่าน รวมถึง clock/reset ที่อาจหยุดหรือเปลี่ยนระหว่าง power states

สำหรับ synchronous interface ให้กำหนด reference edge และตำแหน่งอ้างอิงอย่างชัดเจนว่า clock ถูกวัดที่ block port หรือ top-level source ค่า input delay ต้องรวมส่วน external path ที่ตกลงแล้ว ส่วน clock latency/skew ต้องใช้ convention เดียวกันเพื่อไม่ให้คิดซ้ำ

### ตัวอย่างการแบ่ง timing budget

สมมติ clock period 10 ns และ input arrival สูงสุดที่ block boundary เท่ากับ 2 ns หลัง reference edge เวลาที่เหลือสำหรับเส้นทางภายในถึง register จึงต้องหัก setup, uncertainty และ clock relationship เพิ่ม ตัวเลข 8 ns เป็นเพียงส่วนต่างเบื้องต้น ไม่ใช่ internal path budget สุดท้าย

สำหรับ output หากภายนอกต้องใช้ 4 ns สำหรับ route + receiver setup ตาม reference ที่กำหนด การตั้ง output delay max เป็น 4 ns จะจองเวลานั้นให้ภายนอก ทั้งนี้ output delay min ต้องมาจาก hold budget แยกต่างหาก และอาจมีค่าเป็นลบได้ตาม convention

### ตัวอย่าง SDC สำหรับ block

ตัวอย่างต่อไปนี้สมมติหน่วย time = ns และ capacitance = pF ตาม library ที่โหลด ต้องตรวจหน่วยจริงก่อนใช้ OpenSTA ใช้หน่วยจาก Liberty ตัวแรกที่อ่าน [2] ตัวเลขเป็นโจทย์ฝึก ไม่ใช่ sign-off constraints ของโครงการ

```tcl
create_clock -name core_clk -period 10.000 [get_ports clk_i]
set_clock_uncertainty -setup 0.200 [get_clocks core_clk]
set_clock_uncertainty -hold  0.100 [get_clocks core_clk]

set din [get_ports {enable_i code_i[*]}]
set dout [get_ports {code_o[*] valid_o}]

set_input_delay -clock core_clk -max 2.000 $din
set_input_delay -clock core_clk -min 0.300 $din
set_input_transition 0.150 $din

set_output_delay -clock core_clk -max 4.000 $dout
set_output_delay -clock core_clk -min -0.200 $dout
set_load 0.030 $dout
```

ต้องตรวจว่า collections ได้ pins ครบตามที่ตั้งใจ เครื่องมือบางตัวมีวิธีจับ bus names ต่างกัน ตัวอย่างนี้จงใจยังไม่กำหนด reset exception เพราะต้องตกลง reset protocol ก่อน ห้ามคัดลอก `set_false_path -from [get_ports rst_ni]` แล้วถือว่าการปล่อย reset ปลอดภัย ต้องตรวจ recovery/removal, reset-domain crossing และการปล่อย reset พร้อมกันตามสถาปัตยกรรม

ก่อน CTS มักวิเคราะห์ด้วย ideal clock และ budget ของ clock network หลัง CTS ต้องใช้ propagated-clock analysis ตาม flow ที่เหมาะสม แยก top-level clock arrival ถึง macro boundary ออกจาก internal clock insertion delay เพื่อไม่บวกซ้ำ

### Timing model สำหรับผู้รับ block

เลือกวิธีที่ผู้รับนำไปใช้ได้จริง เช่น flattened gate netlist + parasitics หรือ hierarchical timing model ที่เครื่องมือรองรับ หากส่ง Liberty ของ macro ต้องผ่านขั้นตอนสร้าง/ตรวจ model ตาม flow ไม่สร้างเพียง truth table แล้วเรียกว่า timing sign-off model

ระบุว่า model ครอบคลุม arcs, modes, generated clocks, setup/hold และ asynchronous checks ใดบ้าง พร้อม validation เทียบ full block analysis อย่านำ SDF ไปใช้แทน timing abstraction สำหรับ STA โดยอัตโนมัติ เพราะหน้าที่และข้อมูลที่ใช้ต่างกัน

## 10.7 ตัวอย่าง RTL ควบคู่ VHDL และ SystemVerilog

ตัวอย่างเป็น register interface ที่ reset แบบ synchronous active-low เพื่อให้ semantics ชัดเจน ทั้งสองชุดเป็น **ทางเลือกสำหรับ block เดียวกัน** ไม่ใช่ให้นำมาต่อเป็นสอง block ภายในชิป เมื่อ reset เป็น 0 ที่ rising edge จะล้าง output; เมื่อ enable เป็น 1 จะรับ code และตั้ง valid; รอบอื่น valid เป็น 0 แต่ code คงเดิม

### SystemVerilog

```systemverilog
module dig_ctrl (
  input  logic       clk_i,
  input  logic       rst_ni,
  input  logic       enable_i,
  input  logic [7:0] code_i,
  output logic [7:0] code_o,
  output logic       valid_o
);
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      code_o  <= '0;
      valid_o <= 1'b0;
    end else begin
      valid_o <= enable_i;
      if (enable_i) code_o <= code_i;
    end
  end
endmodule
```

### VHDL

```vhdl
library ieee;
use ieee.std_logic_1164.all;

entity dig_ctrl is
  port (
    clk_i    : in  std_logic;
    rst_ni   : in  std_logic;
    enable_i : in  std_logic;
    code_i   : in  std_logic_vector(7 downto 0);
    code_o   : out std_logic_vector(7 downto 0);
    valid_o  : out std_logic
  );
end entity;

architecture rtl of dig_ctrl is
begin
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_ni = '0' then
        code_o  <= (others => '0');
        valid_o <= '0';
      else
        valid_o <= enable_i;
        if enable_i = '1' then
          code_o <= code_i;
        end if;
      end if;
    end if;
  end process;
end architecture;
```

เงื่อนไข integration: ต้องมี clock edge ขณะ reset active อย่างน้อยหนึ่งครั้ง; enable/code ต้อง synchronous; output ต้องรับโหลดไม่เกิน contract; ตัวอย่างไม่ได้รวม CDC, level shifter, isolation หรือ power-aware behavior

Supply pins ไม่ปรากฏใน behavioral RTL นี้ ให้ flow สร้างและเชื่อม physical supply representation ตาม library และ LVS methodology ที่กำหนด พร้อม supply-aware simulation models เมื่อจำเป็น ห้ามถือว่า output code จะเป็นศูนย์ทันทีขณะ clock หยุดเพียงเพราะ `rst_ni` ต่ำ เพราะ reset ตัวอย่างนี้เป็น synchronous

ถ้า analog ต้องการ output ที่ปลอดภัยตั้งแต่ก่อน clock ทำงาน ต้องเปลี่ยนสถาปัตยกรรม เช่น reset scheme หรือ isolation ที่เหมาะสม พร้อมตรวจผลทาง timing และ power sequence ใหม่

## 10.8 ชุด views ที่ต้องส่งมอบ

| Deliverable | หน้าที่ | จุดตรวจรับ |
|---|---|---|
| GDSII/OASIS | geometry จริง | top cell, units, layers, dependencies, fill status |
| LEF/abstract | boundary/pins/obstructions | ตรง layout และเปิด power access เพียงพอ |
| Gate-level netlist | simulation/STA/integration | top/port/cell references และสถานะ power pins |
| LVS netlist/CDL/SPICE | reference สำหรับ LVS | model mapping, supplies, bus naming, hierarchy |
| SDC | timing environment | mode/corner scope, coverage, exceptions |
| SPEF/RC collateral | parasitics ตาม flow | net naming, RC corner และ extraction stage |
| SDF ถ้าต้องใช้ | timed GLS | source netlist, corner, annotation coverage |
| Timing abstraction ถ้าต้องใช้ | hierarchical STA | tool compatibility และ model validation |
| Symbol/pin map | schematic integration | pin order, direction, bus และ supplies |
| Reports | หลักฐานตรวจรับ | design hash, deck/corner, result summary |
| Integration guide | วิธีใช้งานและข้อจำกัด | voltage/reset/CDC/power/physical contract |

ไม่ใช่ทุกโครงการต้องใช้ทุก format แต่สิ่งที่ไม่ส่งต้องระบุว่าไม่เกี่ยวข้อง หรือระบุวิธีทดแทนที่ผู้รับยอมรับ ตัวอย่างเช่น DEF เป็นข้อมูลเพิ่มเติมที่อาจจำเป็นสำหรับ debug แต่ไม่ควรถือว่าแทน final layout ได้

Abstract ต้องมี obstructions ตามสิ่งที่ต้องป้องกันจริง การ export pin shapes อย่างเดียวอาจทำให้ top-level เดินสายทับโลหะภายในได้ OpenROAD มี abstract LEF writer ที่ส่งออก external pins และ metal obstructions [3] แต่คำสั่งและตัวเลือกของ TDI ต้องอ้างอิงคู่มือรุ่นที่ติดตั้ง

## 10.9 ขั้นตอน integration ใน Tanner/custom top-level

### ขั้นที่ 1 — Freeze contract

ให้ทีม digital และ analog ตรวจ pin list, boundary, voltage และ timing budget ร่วมกัน เก็บ revision ของ contract เป็นส่วนหนึ่งของ input baseline การแก้ interface หลังจากนี้ต้องประเมินผลกับทุก view

### ขั้นที่ 2 — Implement และตรวจ block

ทำ synthesis, floorplan/PDN, placement, CTS, routing, extraction และ verification ตามบทก่อนหน้า เก็บ final database ที่ใช้ export จริง ตรวจว่าไม่มี unresolved cells, floating supplies หรือ intentional exceptions ที่ยังไม่มีคำอธิบาย

### ขั้นที่ 3 — Export จาก final state เดียวกัน

ส่งออก layout, netlists, abstract และ timing collateral จาก design state ที่ freeze เดียวกัน ระบุขั้นตอนก่อน/หลัง fill และ ECO ถ้ามีการแก้ netlist หรือ layout ต้อง regenerate collateral ที่ได้รับผลกระทบ ไม่ใช้ไฟล์เดิมเพียงเพราะชื่อเหมือนกัน

### ขั้นที่ 4 — Import ใน integration workspace ใหม่

โหลด technology/layer map/library dependencies ที่กำหนด นำ macro เข้า custom layout เช่น L-Edit ตาม flow ขององค์กร สร้างหรือนำเข้า symbol และตรวจ mapping ถึง physical cell ห้ามถือว่า symbol pin order ตรง CDL โดยไม่ตรวจ

### ขั้นที่ 5 — เชื่อม signal และ supplies

วาง macro ใน orientation ที่อนุญาต ต่อ signal pins ตาม map ต่อ supply shapes ด้วยโลหะและ vias ที่เหมาะสม ตรวจว่าจุดต่อ power ไม่ถูก obstruction หรือ keepout ปิดกั้น และตรวจ short/open หลังต่อจริง

### ขั้นที่ 6 — ตรวจในบริบท top-level

ทำ full-chip connectivity/LVS, boundary DRC, well/substrate checks, timing ข้าม block และ mixed-signal tests ตามข้อกำหนด รวม package/pad effects ในการวิเคราะห์ที่ต้องใช้ แม้ block DRC ผ่านแล้ว การวางติด analog macro หรือการเติมโลหะระดับ top ก็สร้าง violation ใหม่ได้

### ขั้นที่ 7 — บันทึก acceptance

ระบุ release ID ที่นำเข้า เครื่องมือ/deck ที่ใช้ ผลทดสอบ และรายการ open issues ที่ผู้รับยอมรับ ข้อจำกัดที่รับไว้ต้องอยู่ในเอกสาร ไม่ใช่ข้อความแชตที่ค้นย้อนหลังไม่ได้

## 10.10 แยก block จาก pad ring, ESD และ package

Digital block ภายในชิปควรเชื่อมกับ standard-cell interface หรือ interface cells ตามสถาปัตยกรรม ไม่ใส่ pad cells ในทุก port เพียงเพราะ port ถูกเรียกว่า input/output การต่อออก package เป็นอีกระดับหนึ่งที่ต้องเลือก I/O cell และตรวจ voltage/ESD ให้ถูกต้อง

Block ที่ไม่มี pad ring ยังเป็น deliverable ที่สมบูรณ์ได้เมื่อ contract กำหนดเช่นนั้น แต่ห้ามเรียกว่าผ่าน full-chip ESD การมี I/O pads ก็ยังไม่ยืนยัน ESD หากไม่มี clamps, supply-domain discharge paths หรือ topology ที่ถูกต้อง

Package เพิ่ม resistance, inductance, capacitance และข้อจำกัดด้าน current/return path ผล block STA ที่ boundary จึงไม่ครอบคลุม board/package interface เว้นแต่ environment นั้นถูก model ไว้อย่างชัดเจน

## 10.11 โครงสร้าง release package

ตัวอย่างการจัดหมวดเอกสารและข้อมูล:

| Directory/file | เนื้อหา |
|---|---|
| `README.md` | release ID, สถานะ, quick integration steps |
| `docs/interface_contract.md` | pin/voltage/timing/power contract |
| `docs/integration_guide.md` | physical integration และ dependency setup |
| `docs/known_limitations.md` | ข้อจำกัดและผลกระทบ |
| `rtl/` | RTL baseline ที่ใช้จริง หรือ reference ไปยัง immutable source |
| `netlist/` | final netlist และ LVS reference แยกชื่อชัดเจน |
| `layout/` | final GDS/OASIS และ dependency policy |
| `abstract/` | LEF, pin map, symbol collateral |
| `timing/` | SDC, parasitics, timing models/SDF ตาม scope |
| `scripts/` | scripts และ run settings สำหรับสร้างซ้ำ |
| `reports/` | STA/DRC/LVS/GLS และการตรวจอื่นตาม scope |
| `manifest.yaml` | source/tool/PDK versions, configuration และ provenance |
| `SHA256SUMS` | checksums ของ payload ที่ freeze |

ห้ามเผยแพร่ PDK หรือ proprietary libraries เกินสิทธิ์ที่มี ถ้าส่งไฟล์ไม่ได้ ให้ระบุชื่อรุ่น checksum และวิธีที่ผู้รับเข้าถึง dependency ที่ได้รับอนุญาต หลีกเลี่ยง absolute paths ส่วนบุคคลใน scripts; ใช้ project root หรือ environment variables พร้อม preflight checks

### ตัวอย่าง manifest

```yaml
release_id: dig_ctrl_1.0.0_rc1
status: integration_candidate
top_cell: dig_ctrl
source:
  git_commit: REPLACE_WITH_ACTUAL_COMMIT
  dirty_tree: false
contract_revision: IFACE_003
tools:
  implementation: RECORD_EXACT_TOOL_AND_BUILD
  simulator: RECORD_EXACT_TOOL_AND_BUILD
pdk:
  name: RECORD_ACTUAL_PDK
  revision: RECORD_ACTUAL_REVISION
  drc_deck: RECORD_DECK_ID_AND_HASH
  lvs_deck: RECORD_DECK_ID_AND_HASH
analysis:
  modes: [functional]
  pvt_corners: [RECORD_ACTUAL_CORNERS]
  rc_corners: [RECORD_ACTUAL_RC_CORNERS]
  timing_reference: block_ports
verification:
  drc: SEE_REPORT_AND_WAIVER_LIST
  lvs: SEE_REPORT
  sta: SEE_COVERAGE_AND_CORNER_SUMMARY
  gls: SEE_TEST_SUMMARY
limitations: docs/known_limitations.md
```

ค่าตัวอย่างทั้งหมดต้องแทนด้วยข้อมูลจริงก่อน release ห้ามเขียน PASS โดยอิงเพียง process exit code หาก log ยังมี unmatched cells, skipped checks หรือ incomplete annotation

Checksum พิสูจน์ว่า bytes ตรงกัน ไม่ได้พิสูจน์ว่าการออกแบบถูกต้อง และ checksum ของไฟล์แต่ละชนิดที่ครบก็ยังไม่ยืนยันว่าไฟล์เหล่านั้นสัมพันธ์กัน ต้องตรวจ provenance กับ cross-view consistency เพิ่ม

## 10.12 Release gates และหลักฐานการตรวจรับ

| Gate | เกณฑ์ที่ต้องตกลงและตรวจ |
|---|---|
| Interface | pin names/directions/widths ตรงทุก view และ contract |
| Physical | boundary/origin/layers/power access/obstructions ถูกต้อง |
| Connectivity | supply mapping ครบ; ไม่มี short/open ที่ไม่ได้ยอมรับ |
| Timing | modes/corners ครบ; ไม่มี unconstrained paths ที่ยังไม่วิเคราะห์ |
| Verification | DRC/LVS และ simulation ตาม scope พร้อม deck/model IDs |
| Reproducibility | source/configuration/dependencies และ seeds/options ครบ |
| Integration | import และ smoke test จาก release package ในพื้นที่ใหม่ผ่าน |
| Limitations | unresolved issues มี impact, owner และขอบเขตการใช้งาน |

สำหรับ STA ต้องสรุป setup/hold, clock coverage, recovery/removal ที่เกี่ยวข้อง และเหตุผลของ exceptions ไม่ใช้ WNS ≥ 0 เพียงค่าเดียวเป็นเกณฑ์ สำหรับ DRC ต้องมี rule counts และ waiver ที่อนุมัติตามกระบวนการ สำหรับ LVS ต้องระบุ netlist/geometry ที่เทียบและสถานะ black-boxing

สำหรับ GLS ให้ระบุ functional/timed, test list, simulator models, reset initialization และ SDF annotation coverage ถ้าใช้ timed GLS การจำลองผ่าน test เดียวไม่ได้พิสูจน์ corner coverage ทั้งหมด

### ตัวอย่าง known limitation ที่ตรวจรับได้

> ID: LIM-004 — ตรวจเฉพาะ functional mode ที่ clock period 10 ns ตาม SDC revision 003 ยังไม่วิเคราะห์ scan/test mode ห้ามใช้ release นี้อ้างอิง test-mode timing sign-off ผู้รับผิดชอบ: digital timing owner; ขั้นปิดประเด็น: เพิ่ม test-mode constraints และตรวจทุก corner ที่ตกลง

ข้อความ “อาจมี timing issue” ไม่เพียงพอ เพราะไม่ระบุ trigger, scope หรือผลกระทบ ข้อจำกัดต้องไม่ถูกใช้แทนการแก้ fatal issue ที่อยู่นอกเกณฑ์รับงาน

## 10.13 การทำซ้ำและการควบคุม ECO

Reproducible release ต้องเก็บ RTL commit, uncommitted patches ถ้ามี, constraints, floorplan, pin placement, library/PDK/deck revision, tool build, command line, environment ที่สำคัญ, threads/seeds และ logs หากไม่สามารถสร้างผลแบบ bit-identical ต้องระบุความแปรผันที่คาดหวังและเกณฑ์เทียบผล

เมื่อมี ECO ให้ระบุว่าเปลี่ยน logic, timing, routing, pins หรือ boundary แล้ววิเคราะห์ collateral ที่ได้รับผลกระทบ เช่น:

| ECO | สิ่งที่ต้องทบทวน |
|---|---|
| เปลี่ยน buffer/route | netlist/layout/parasitics/timing/DRC/LVS และ SDF ถ้าใช้ |
| ย้าย pin | abstract/pin map/top-level route และ timing budget |
| เปลี่ยน supply mapping | netlists/layout/global rules/ERC/LVS/power checks |
| เปลี่ยน RTL interface | ทุก view และ integration contract |

ห้ามแก้ไฟล์ใน release เดิมแบบเงียบ ๆ ให้สร้าง revision ใหม่ เก็บ changelog และระบุว่า release ใดถูก supersede ผู้รับต้องทราบว่ารายงานใดหมดอายุหลัง ECO

## 10.14 Lab — สร้าง integration candidate และตรวจรับ

**โจทย์:** ใช้ `dig_ctrl` จาก VHDL หรือ SystemVerilog สร้าง hard macro สำหรับ analog-on-top พร้อม release package โดยไม่รวม pad ring

1. เขียน interface contract รวม synchronous reset, clock 10 ns, signal pins, supply policy และ voltage ที่เลือกจาก library จริง
2. กำหนด boundary/origin/pin locations พร้อม power access และ routing keepout
3. ทำ implementation ตาม flow ที่ติดตั้ง บันทึกทุก input และ run settings
4. ตรวจ block timing/DRC/LVS และ simulation ตาม scope; สรุป unsupported checks อย่างตรงไปตรงมา
5. Export views จาก final database เดียวกัน และตรวจ port/bus/power mapping
6. สร้าง package ตามตาราง พร้อม manifest, reports และ known limitations
7. เปิด integration workspace ใหม่ นำเข้าเฉพาะ package และ dependencies ที่ระบุ ตรวจ top cell, boundary, pins และ supplies
8. สร้าง top schematic/layout ตัวอย่าง เชื่อม macro และตรวจ connectivity กับ boundary interactions
9. ทำ negative test หนึ่งกรณี เช่น สลับ bus pin หรือทำ supply ขาดในสำเนาทดสอบ ยืนยันว่าการตรวจจับพบ แล้วทิ้งสำเนาทดสอบและตรวจ release ที่ถูกต้องอีกครั้ง
10. ลงบันทึก acceptance โดยระบุ release ID และผลของแต่ละ gate

**เกณฑ์ผ่าน:** ผู้รับอีกคนสามารถ import และเชื่อม macro ได้โดยไม่ต้องเดาชื่อ pin, supply, voltage หรือ timing reference และไม่มีรายงานใดอ้างอิงคนละ design revision กับ payload

### คำถามทบทวน

1. เหตุใด block LVS ผ่านจึงยังเกิด full-chip LVS mismatch ได้?
2. การตั้งชื่อ VDDD/VSSD ช่วยอะไร และยังต้องตรวจเรื่องใดเพิ่มเติม?
3. เพราะเหตุใด output load และ input transition จึงต้องอยู่ใน timing contract?
4. ถ้า output ใช้ขับ analog control node โดยตรง จะต้องเพิ่มการวิเคราะห์อะไร?
5. เหตุใดการเปลี่ยนเพียง pin location จึงต้องออก release revision ใหม่?
6. ถ้าไม่มี hierarchical timing model ผู้รับจะตรวจ timing ด้วยวิธีใด และต้องได้รับข้อมูลใด?
7. ถ้า synchronous reset ถูก assert ขณะ clock หยุด ตัวอย่าง RTL จะมีพฤติกรรมอย่างไร?

### แนวคำตอบ

1. Top-level อาจเชื่อมผิด รวม supplies ผิด mapping หรือใช้คนละ view/version รวมถึงเกิด short/open ใหม่หลัง integration
2. ช่วยระบุ domain และ mapping แต่ยังต้องตรวจ voltage, connectivity, return path, sequencing และ physical network
3. Delay และ slew ของ cell ขึ้นกับ input waveform และโหลด; constraints ที่ไม่แทน environment จริงอาจให้ผล timing ที่ใช้ไม่ได้
4. ต้องตรวจ voltage compatibility, loading, transition/glitch, noise, sampling window และ power-off behavior ตามหน้าที่ของ node
5. Abstract, routing และ parasitics ที่ boundary เปลี่ยน ผู้รับจึงต้องทราบและตรวจ integration ใหม่
6. อาจใช้ gate-level netlist พร้อม libraries/parasitics และ constraints ที่เหมาะสมตาม flow ที่ผู้รับรองรับ
7. ค่า output ยังไม่ถูก reset จนกว่าจะมี rising edge ที่เห็น reset active

## 10.15 เอกสารอ้างอิง

เอกสารต่อไปนี้รองรับบริบทผลิตภัณฑ์และตัวอย่าง format/STA; ขั้นตอน release gates และ contract ในบทนี้เป็นแนวทางทางวิศวกรรมที่ต้องปรับเข้ากับโครงการ ไม่ใช่การอ้างว่าผู้ขายรับรอง release ใด

1. Siemens EDA, Digital Implementer: https://eda.sw.siemens.com/en-US/ic/ic-custom/ams/digital-implementer/
2. OpenSTA documentation, Examples และข้อกำหนดหน่วยจาก Liberty: https://openroad.readthedocs.io/en/latest/main/src/sta/doc/Examples.html
3. OpenROAD API documentation, abstract LEF และ database I/O: https://openroad.readthedocs.io/en/latest/main/src/README.html

ให้ใช้ installed user guide/release notes ของ TDI, simulator และ physical verification tools ร่วมกับ PDK integration manual, sign-off decks และ package/ESD requirements ที่ผู้รับงานยอมรับ
