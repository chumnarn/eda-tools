# หลักสูตร Tanner Digital ASIC Design Implementation
## ระดับเริ่มต้นถึงระดับกลาง — ทฤษฎีและปฏิบัติ 5 วัน 30 ชั่วโมง

ฉบับออกแบบหลักสูตร วันที่ 16 ตุลาคม 2026

## 1. แนวคิดและขอบเขต

หลักสูตรพาผู้เรียนพัฒนา digital block ขนาดเล็กจาก specification → RTL → functional simulation → synthesis → floorplan → power planning → placement → CTS → routing → physical verification และจัดส่งผลลัพธ์ โดยใช้ Tanner Digital Implementer (TDI) ร่วมกับ L-Edit เป็นแกนหลัก เหมาะกับ digital control block ในชิป analog/mixed-signal และงาน ASIC ขนาดเล็กถึงปานกลางตามขีดความสามารถของรุ่นและไลเซนส์ที่ติดตั้ง

Siemens อธิบาย TDI ว่าใช้ Oasys synthesis และ Nitro place-and-route เชื่อมกับ L-Edit ไม่ควรนำชื่อขั้นตอนหรือคำสั่งของ Aprisa, OpenROAD หรือ Synopsys มาใช้แทนโดยถือว่าเข้ากันได้โดยอัตโนมัติ

ตัวอย่างใช้ VHDL และ Verilog/SystemVerilog ควบคู่กัน: RTL มี VHDL, Verilog-2001 และ SystemVerilog; self-checking testbench มี VHDL-2008 และ SystemVerilog ใช้ specification, test cases และ acceptance criteria เดียวกัน ผู้สอนต้องตรวจ language subset ของ synthesis frontend ใน TDI รุ่นที่ติดตั้ง แยกความสามารถของ simulator ออกจาก synthesis และเลือก implementation source เพียงภาษาหนึ่งต่อ run

การผ่านหลักสูตรหมายถึงสร้างและตรวจสอบ block implementation ตาม acceptance criteria ของแล็บ ไม่ใช่การรับรองว่าไฟล์พร้อมส่ง foundry โดยไม่ผ่านกระบวนการ sign-off ที่กำหนด

## 2. กลุ่มเป้าหมายและพื้นฐาน

- นักศึกษา วิศวกร FPGA และนักออกแบบวงจรที่เริ่มทำ ASIC
- ผู้ออกแบบ analog/MEMS ที่ต้องการ digital controller สำหรับเชื่อมกับวงจรของตน
- รู้จัก combinational logic, flip-flop, binary arithmetic และ waveform
- ใช้ editor และ terminal ได้; มีพื้นฐาน HDL จะช่วยให้เรียนได้เร็ว

จัด pre-course 3 ชั่วโมงแยกจากหลักสูตรสำหรับผู้ไม่มีพื้นฐาน HDL: Boolean logic, clocked process, blocking/nonblocking assignment และ testbench

## 3. ผลลัพธ์การเรียนรู้

เมื่อจบ ผู้เรียนสามารถ:

1. อธิบายความต่างระหว่าง RTL simulation, synthesis, STA, DRC และ LVS
2. เขียน RTL แบบ synchronous ที่ไม่มี latch และสร้าง self-checking testbench
3. ตรวจความสัมพันธ์ของ Liberty, LEF, GDS/OASIS, cell models และ PDK
4. สร้าง clock และ I/O timing constraints พร้อมอธิบายสมมติฐาน
5. ใช้ TDI/L-Edit ทำ block implementation ทีละ checkpoint
6. วิเคราะห์ setup/hold, congestion และ power connectivity เบื้องต้น
7. เปรียบเทียบผล PPA ด้วยเงื่อนไขเดียวกันและจัดทำ release package ที่ตรวจย้อนกลับได้

## 4. เครื่องมือและข้อมูลที่ต้องเตรียม

| เครื่องมือ/ข้อมูล | บทบาท | เงื่อนไขก่อนอบรม |
|---|---|---|
| Tanner Digital Implementer + L-Edit | Synthesis และ physical implementation | ตรวจ feature license, รุ่น และ example flow ที่รันได้ |
| Questa/ModelSim edition ที่รองรับ HDL ของแล็บ | RTL และ gate-level simulation | ตรวจ compiler, simulator และ license |
| Calibre พร้อม qualified decks | DRC/LVS ตามชุดกฎที่เลือก | ไลเซนส์และ foundry decks แยกตามการติดตั้ง |
| Standard-cell library | Timing, mapping และ physical views | Cell names, corner, power pins และ units ต้องตรงกัน |
| Technology data | Routing layers, vias, grid, RC และ stream map | ตรวจว่าใช้กับ TDI/L-Edit รุ่นนั้นได้ |
| Editor, Tcl, Git | จัดไฟล์และทำซ้ำ | เตรียมโครงงานแยกต่อผู้เรียน |

S-Edit ใช้ประกอบการสอน hierarchical/custom integration เมื่อจำเป็น Precision ใช้เป็นเส้นทาง FPGA prototype แยกต่างหาก หากสอนเพิ่มเติมต้องจัดเวลาและไลเซนส์เพิ่ม

การมี IHP SG13G2, SKY130 หรือ GF180MCU PDK ไม่ได้ยืนยันว่าพร้อมใช้กับ TDI โดยตรง ต้องตรวจและเตรียม technology/library integration, routing/RC data, stream map และ verification decks ก่อนอบรม ทางเลือกที่เหมาะกับคลาสแรกคือ training PDK และ reference project ที่ทีมผู้สอนทดสอบครบ flow แล้ว

## 5. แผนอบรม 5 วัน

แต่ละวัน 6 ชั่วโมง ไม่รวมพัก รวมทฤษฎี 12 ชั่วโมง ปฏิบัติ 18 ชั่วโมง

| วัน | ทฤษฎี | ปฏิบัติ | ผลงานเมื่อจบวัน |
|---|---|---|---|
| 1: RTL และ verification | 2.5 ชม.: ASIC flow, synchronous design, reset, HDL subset | 3.5 ชม.: Lab 1–2 ตรวจเครื่องมือ เขียน counter และ TB | RTL ผ่านการตรวจเชิงพฤติกรรม |
| 2: Library, constraints, synthesis | 2.5 ชม.: Liberty/LEF, mapping, timing paths, SDC | 3.5 ชม.: Lab 3–4 สร้าง TDI project และ mapped netlist | Netlist, constraints, area/timing reports |
| 3: Floorplan, PDN, placement | 2.5 ชม.: utilization, pin access, power, congestion | 3.5 ชม.: Lab 5–6 วาง block, PDN และ cells | Floorplan/placement checkpoint |
| 4: CTS, routing, timing | 2.5 ชม.: skew, latency, setup/hold, RC, antenna | 3.5 ชม.: Lab 7–8 ทำ CTS/routing และวิเคราะห์ paths | Routed checkpoint และ timing analysis |
| 5: Verification และ mini-project | 2 ชม.: DRC/LVS, GLS, PPA และ release | 4 ชม.: Lab 9–10 แก้ปัญหาและสรุปโครงงาน | Layout, verification evidence, release report |

## 6. เนื้อหาทฤษฎีรายโมดูล

### Module 1 — ภาพรวม ASIC implementation

อธิบายความสัมพันธ์ระหว่าง specification, RTL, netlist และ geometry; FPGA LUT แตกต่างจาก ASIC standard cell อย่างไร; PPA ได้แก่ performance, power, area และเหตุใดผล synthesis ยังไม่ใช่ผลหลัง route ตัวอย่างคำถาม: RTL simulation ผ่าน แต่ชิปยังล้มเหลวจาก timing หรือ power connectivity ได้อย่างไร

### Module 2 — RTL ที่เหมาะกับ ASIC

Combinational และ sequential processes, assignment semantics, bit width, signedness, reset polarity, clock enable, latch inference และ FSM ใช้ clock enable แทนการนำ combinational logic ไป gate clock โดยตรง สอนหลัก asynchronous assert/synchronous deassert เมื่อจำเป็นและการตรวจ recovery/removal ผู้เรียนต้องบอกได้ว่าสัญญาณใด synchronous และสัญญาณใดต้องผ่าน CDC treatment

### Module 3 — Functional verification

Directed tests, reference model, scoreboard, assertions, boundary conditions, reset/enable behavior และ timeout การเห็น waveform ดูถูกต้องเพียงบางช่วงไม่ทดแทน self-checking tests ควรให้ผู้เรียนใส่ bug โดยตั้งใจหนึ่งครั้งเพื่อยืนยันว่า TB ตรวจพบ

### Module 4 — PDK และ standard-cell views

Liberty กำหนด function/timing/power; LEF ให้ abstract geometry และ pin access; GDS/OASIS ให้ layout จริง; Verilog models ใช้ simulation; SPICE/CDL ใช้ตาม LVS flow ตรวจชื่อ cell, power pin, bus notation และ time/capacitance units ให้สัมพันธ์กัน อธิบาย PVT corner, operating voltage และ RC corner แยกกัน

### Module 5 — Constraints และ synthesis

Elaboration, optimization, technology mapping, unconnected ports, undriven nets, unintended latches และ unresolved references SDC ต้องอธิบาย external environment ได้จริง ตรวจ clock coverage และ unconstrained endpoints ก่อนตีความ WNS/TNS; area ต้องระบุว่า cell area หรือ core area

### Module 6 — Floorplan และ power planning

กำหนดขนาด block, aspect ratio, utilization, pin locations, placement rows, blockages, power rails/straps และ special cells ขนาด core โดยประมาณ A_core ≈ A_placeable_cells/U โดย U เป็น utilization ที่นิยามตรงกับเครื่องมือ ต้องเผื่อ CTS/buffer/filler และ routing resources เพิ่มตาม flow

### Module 7 — Placement และ CTS

Placement legality, density, wirelength, congestion, high fanout และ buffering แยก ideal clock จาก propagated clock; วิเคราะห์ insertion delay, skew, clock transition และ clock load การสร้าง CTS ไม่ได้ยืนยันว่า setup/hold จะผ่านทันที

### Module 8 — Routing และ STA

Global/detailed routing, RC extraction, pin access, via, antenna และ timing repair สำหรับ register-to-register แบบหนึ่งคล็อกและไม่รวม exception:

T_cq,max + T_data,max + T_setup + U_setup ≤ T_period + skew

T_cq,min + T_data,min ≥ T_hold + U_hold + skew

นิยาม skew = capture clock arrival − launch clock arrival ดังนั้น positive skew ช่วย setup แต่ทำให้ hold ยากขึ้น รายงานจริงอาจรวม derates และ common-path pessimism removal เพิ่ม ต้องอ่านตามรูปแบบเครื่องมือ

ตัวอย่าง setup: period 10 ns, skew 0.10 ns, Tcq 0.20 ns, data 8.90 ns, setup 0.30 ns, uncertainty 0.20 ns ให้ slack 0.50 ns ตัวอย่าง hold: Tcq,min 0.08 ns, data,min 0.05 ns, hold 0.10 ns, uncertainty 0.02 ns และ skew 0.10 ns ให้ slack −0.09 ns

### Module 9 — Physical verification และ simulation หลัง synthesis

DRC ตรวจ geometry; LVS ตรวจความสอดคล้องทางไฟฟ้าของ layout และ reference netlist; STA ตรวจ timing ตาม constraints; GLS ตรวจการจำลอง netlist พูดถึง power/ground naming, global nets, shorts/opens, missing cell models และ SDF annotation coverage ต้องใช้ sign-off decks ที่ผู้รับงานยอมรับ

### Module 10 — Integration และ release

สร้าง digital block สำหรับ analog-on-top โดยกำหนด boundary, signal pins, supply pins, voltage และ timing contract แยก block implementation ออกจาก full-chip pad ring/ESD/package จัดเก็บ versions, constraints, run settings, reports และ known limitations อย่างชัดเจน

## 7. ชุดแล็บและเกณฑ์ผ่าน

| Lab | ขั้นตอนหลัก | สิ่งที่ส่ง/เกณฑ์ผ่าน |
|---|---|---|
| 1 — Environment audit | เปิด L-Edit/TDI, ตรวจ license, รัน reference design, ตรวจ library views | บันทึกรุ่น/PDK/corner และ reference flow ผ่าน |
| 2 — RTL/TB | สร้าง counter, test reset/enable/wraparound, จำลอง | Scoreboard ผ่านทุกกรณีและตรวจพบ injected bug |
| 3 — TDI project | ใช้ setup wizard/reference template เลือก top, source, library, tech และ SDC | ไม่มี unresolved references; units/cell views ตรง |
| 4 — Synthesis/STA | รัน synthesis ตรวจ mapping และ timing coverage | ไม่มี unintended latch; timing report มี clock/path ที่คาดหวัง |
| 5 — Floorplan/PDN | กำหนด block boundary, pins, rows, supplies และ PG connections | Placement area ถูกต้อง; ไม่มี PG open/short ตาม checks ที่มี |
| 6 — Placement | รัน placement เปรียบเทียบ utilization เช่น 40%/60% | Legal placement พร้อมวิเคราะห์ area/timing/congestion |
| 7 — CTS | ตรวจ clock definition, รัน CTS, ดู propagated timing | Clock sinks ครบ; skew/transition และ setup/hold มีรายงาน |
| 8 — Routing | Route, extract RC, ดู critical paths และแก้หนึ่งปัญหา | ไม่มี signal open/short ตาม router checks; สรุป timing หลัง route |
| 9 — DRC/LVS/GLS | รัน decks ที่เตรียมไว้, แก้ violation, functional GLS | DRC ตามเกณฑ์แล็บ; LVS match; GLS ผ่านเมื่อมี models ครบ |
| 10 — Mini-project/release | เพิ่ม PWM, ตรวจ regression, เปรียบเทียบ PPA และส่ง layout | ผ่าน functional/physical/timing acceptance ที่กำหนดไว้ |

สำหรับ utilization sweep ต้องอธิบายว่าถ้าเปลี่ยน core area ผล routing distance ก็เปลี่ยน และอาจเกิด congestion เฉพาะจุดแม้ utilization เฉลี่ยต่ำ

## 8. ตัวอย่าง RTL: counter 8 บิต

โครงงานตั้งต้นใช้คล็อกเดียว reset แบบ synchronous active-low และ clock enable ข้อกำหนดคือ reset → 0, enable → เพิ่มค่า modulo 256, disable → คงค่า สัญญาณ inputs ทั้งหมดเป็น synchronous ต่อ clk ในแบบฝึกนี้

ไฟล์ `rtl/counter8.sv`:

```systemverilog
module counter8 (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       en,
    output logic [7:0] count
);
    always_ff @(posedge clk) begin
        if (!rst_n) count <= 8'h00;
        else if (en) count <= count + 8'd1;
    end
endmodule
```

ไฟล์ `tb/tb_counter8.sv`:

```systemverilog
module tb_counter8;
    timeunit 1ns;
    timeprecision 1ps;
    logic clk = 0;
    logic rst_n = 0;
    logic en = 0;
    logic [7:0] count;
    logic [7:0] expected = 0;
    counter8 dut (.*);
    always #5 clk = ~clk;

    task automatic tick(input logic r, input logic e);
        @(negedge clk);
        rst_n = r;
        en = e;
        @(posedge clk);
        if (!r) expected = 0;
        else if (e) expected = expected + 8'd1;
        #1; // หลัง NBA update
        if (count !== expected)
            $fatal(1, "count=%0d expected=%0d", count, expected);
    endtask

    initial begin
        tick(0, 0);
        repeat (3) tick(1, 0);
        repeat (260) tick(1, 1); // รวม wraparound
        repeat (7) tick(1, 0);
        tick(0, 1); // reset มี priority เหนือ enable
        repeat (4) tick(1, 1);
        $display("PASS: counter8");
        $finish;
    end

    initial begin
        #10000;
        $fatal(1, "TIMEOUT");
    end
endmodule
```

ไฟล์ `sim/run.do` รันจาก project root:

```tcl
onerror {quit -code 1 -force}
onbreak {quit -code 1 -force}
if {![file isdirectory work]} {vlib work}
vmap work work
vlog -sv rtl/counter8.sv tb/tb_counter8.sv
vsim work.tb_counter8
run -all
quit -code 0 -force
```

คำสั่ง terminal หลังตั้ง PATH และไลเซนส์เรียบร้อย:

```text
vsim -c -do sim/run.do -l sim/counter8.log
```

ให้ตรวจว่ามี `PASS: counter8` และไม่มี fatal/error ทดสอบเปลี่ยน RTL จาก +1 เป็น +2 แล้วต้องตรวจพบ failure ก่อนคืนโค้ดเดิม รูปแบบการคืน exit status จาก HDL fatal ต้องตรวจใน simulator release ที่ติดตั้งก่อนใช้ automation

### 8.1 Counter แบบ VHDL

ใช้ `numeric_std` สำหรับ unsigned arithmetic และแยก internal unsigned register จาก output `std_logic_vector` เพื่อให้ interface เทียบกับ Verilog ได้ง่าย RTL นี้ใช้รูปแบบที่ไม่จำเป็นต้องพึ่ง VHDL-2008 ส่วน testbench ด้านล่างใช้ VHDL-2008

ไฟล์ `rtl/vhdl/counter8.vhd`:

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter8 is
    port (
        clk   : in  std_logic;
        rst_n : in  std_logic;
        en    : in  std_logic;
        count : out std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of counter8 is
    signal count_q : unsigned(7 downto 0);
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                count_q <= (others => '0');
            elsif en = '1' then
                count_q <= count_q + 1;
            end if;
        end if;
    end process;
    count <= std_logic_vector(count_q);
end architecture;
```

### 8.2 Counter แบบ Verilog-2001

ไฟล์ `rtl/verilog/counter8.v` เป็นทางเลือกสำหรับ frontend ที่ใช้ Verilog-2001 ให้เลือกไฟล์นี้หรือ `rtl/counter8.sv` เพียงหนึ่งไฟล์ เนื่องจากใช้ชื่อ module เดียวกัน

```verilog
module counter8 (
    input wire clk,
    input wire rst_n,
    input wire en,
    output reg [7:0] count
);
    always @(posedge clk) begin
        if (!rst_n) count <= 8'h00;
        else if (en) count <= count + 8'd1;
    end
endmodule
```

### 8.3 Self-checking testbench แบบ VHDL-2008

ไฟล์ `tb/vhdl/tb_counter8.vhd` ใช้ลำดับทดสอบตรงกับ SystemVerilog: reset, hold, นับข้าม 255, hold, reset ขณะ enable และเริ่มนับใหม่ Stimulus เปลี่ยนที่ falling edge และตรวจหลัง rising edge 1 ns เพื่อหลีกเลี่ยง race/delta-cycle effects

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_counter8 is
end entity;

architecture sim of tb_counter8 is
    signal clk   : std_logic := '0';
    signal rst_n : std_logic := '0';
    signal en    : std_logic := '0';
    signal count : std_logic_vector(7 downto 0);
begin
    clk <= not clk after 5 ns;
    dut : entity work.counter8(rtl)
        port map (clk => clk, rst_n => rst_n, en => en, count => count);

    stimulus : process
        variable expected : unsigned(7 downto 0) := (others => '0');
        procedure tick(constant r : std_logic; constant e : std_logic) is
        begin
            wait until falling_edge(clk);
            rst_n <= r;
            en <= e;
            wait until rising_edge(clk);
            if r = '0' then
                expected := (others => '0');
            elsif e = '1' then
                expected := expected + 1;
            end if;
            wait for 1 ns;
            assert count = std_logic_vector(expected)
                report "Counter mismatch" severity failure;
        end procedure;
    begin
        tick('0', '0');
        for i in 1 to 3 loop tick('1', '0'); end loop;
        for i in 1 to 260 loop tick('1', '1'); end loop;
        for i in 1 to 7 loop tick('1', '0'); end loop;
        tick('0', '1');
        for i in 1 to 4 loop tick('1', '1'); end loop;
        report "PASS: counter8" severity note;
        finish;
        wait;
    end process;

    watchdog : process
    begin
        wait for 10 us;
        assert false report "TIMEOUT" severity failure;
        wait;
    end process;
end architecture;
```

ไฟล์ `sim/run_vhdl.do`:

```tcl
onerror {quit -code 1 -force}
onbreak {quit -code 1 -force}
if {![file isdirectory work_vhdl]} {vlib work_vhdl}
vmap work_vhdl work_vhdl
vcom -2008 -work work_vhdl rtl/vhdl/counter8.vhd tb/vhdl/tb_counter8.vhd
vsim -onfinish stop work_vhdl.tb_counter8
set BreakOnAssertion 2
run -all
quit -code 0 -force
```

`BreakOnAssertion 2` ให้ simulator หยุดเมื่อ assertion ระดับ error ขึ้นไป และ `onbreak` คืน exit code 1; ตรวจพฤติกรรมนี้กับรุ่นติดตั้งด้วย negative test เสมอ

```text
vsim -c -do sim/run_vhdl.do -l sim/counter8_vhdl.log
```

หากต้องการทดสอบ Verilog-2001 กับ SystemVerilog TB ให้ใช้ไฟล์ `sim/run_verilog.do` แยกจาก run เดิม:

```tcl
onerror {quit -code 1 -force}
onbreak {quit -code 1 -force}
if {![file isdirectory work_verilog]} {vlib work_verilog}
vmap work_verilog work_verilog
vlog -work work_verilog rtl/verilog/counter8.v
vlog -sv -work work_verilog tb/tb_counter8.sv
vsim work_verilog.tb_counter8
run -all
quit -code 0 -force
```

```text
vsim -c -do sim/run_verilog.do -l sim/counter8_verilog.log
```

การแยก logical libraries ป้องกันชื่อ entity/module ซ้ำ ส่วน VHDL `work` ภายใน source หมายถึง library ที่กำลัง compile จึงผูกกับ `work_vhdl` ใน run นี้

### 8.4 ประเด็นสอนเทียบภาษา

| แนวคิด | VHDL | Verilog/SystemVerilog |
|---|---|---|
| Interface | entity/port | module/ports |
| Implementation | architecture | module body |
| Clocked process | process + rising_edge | always @(posedge) / always_ff |
| Register update | signal assignment `<=` | nonblocking assignment `<=` |
| Reference model | variable assignment `:=` | blocking assignment `=` |
| Unsigned arithmetic | unsigned + numeric_std | unsigned vectors; ระวัง signed declarations |
| Combinational process | process(all) ใน VHDL-2008 | always @* / always_comb |
| เลือกผลแบบต่อเนื่อง | concurrent conditional assignment | assign + ternary operator |

ความหมายของ VHDL signal assignment กับ Verilog nonblocking assignment ใกล้เคียงกันสำหรับ synchronous RTL ตัวอย่างนี้ แต่ scheduling model ไม่เหมือนกันทุกกรณี เปรียบเทียบ behavior บนค่าลอจิก 0/1 ตาม specification; ไม่ถือว่า X/U/Z semantics เหมือนกันทั้งหมด

## 9. ตัวอย่าง SDC สำหรับแล็บ

ไฟล์ `constraints/counter8.sdc` เป็นตัวอย่างสมมติว่า time unit ของ timing library คือ ns และ capacitance คือ pF ต้องตรวจหน่วยจริงก่อนใช้ ค่า delay/load เป็นข้อกำหนดการสอน ไม่ใช่ค่าของทุก PDK

```tcl
create_clock -name core_clk -period 10.000 [get_ports clk]
set_clock_uncertainty 0.200 [get_clocks core_clk]

set_input_delay -clock core_clk -max 2.000 [get_ports {rst_n en}]
set_input_delay -clock core_clk -min 0.500 [get_ports {rst_n en}]
set_output_delay -clock core_clk -max 2.000 [get_ports {count[*]}]
set_output_delay -clock core_clk -min -0.200 [get_ports {count[*]}]

set_input_transition 0.100 [get_ports {rst_n en}]
set_load 0.020 [get_ports {count[*]}]
```

Output-delay min −0.2 ns แทน external hold requirement +0.2 ns ภายใต้ reference clock และสมมติฐาน board skew ของตัวอย่าง ซึ่งต้องปรับหาก clock/data reference ต่างไป Reset ของตัวอย่างเป็น synchronous จึงต้องวิเคราะห์เป็น timed data input; ไม่ใส่ false path ให้ reset เพื่อซ่อนปัญหา

ให้ผู้เรียนอธิบายแต่ละ constraint และยืนยันว่า port collections ไม่ว่าง การ constrain clk transition/source latency และการเปลี่ยนเป็น propagated clock หลัง CTS ให้ใช้วิธีที่ reference flow ของรุ่นนั้นกำหนด เพื่อป้องกันการนับ clock effects ซ้ำ

## 10. ขั้นตอนใช้ Tanner Digital Implementer

ชื่อเมนูและ syntax แตกต่างตาม release ให้ใช้หน้าจอ setup และ reference flow ที่ติดตั้งจริง ขั้นตอนต่อไปนี้เป็น workflow ไม่ใช่คำสั่ง Tcl ของ TDI ที่รับรองข้ามรุ่น

1. เปิด L-Edit และสร้าง/เปิด design library ด้วย technology ที่ผู้สอนทดสอบแล้ว
2. เปิดส่วนตั้งค่า Digital Implementer ตามเมนูของ release; สร้าง project แยกจาก reference ต้นฉบับ
3. ระบุ top `counter8`, source RTL, synthesis libraries, physical libraries และ timing constraints
4. กำหนด routing layers, via/RC data, timing corners และ supply names ตาม technology package
5. สร้างหรือคัดลอก project scripts ผ่านวิธีที่ release รองรับ แล้วเก็บ baseline ใน version control
6. รัน synthesis; ตรวจ log, mapped netlist, latch count, cell usage และ constraint coverage ก่อนเดินต่อ
7. สร้าง floorplan และ pins; เชื่อม power/ground กับ standard cells และเพิ่ม special cells ตามกฎ library
8. รัน placement; ตรวจ legality/congestion และบันทึก checkpoint
9. รัน CTS; ตรวจ clock coverage, skew และ setup/hold ทั้ง min/max corners ที่กำหนด
10. รัน routing และ extraction; ตรวจ routing connectivity, DRC และ timing อีกครั้ง
11. Export ผลกลับมาตรวจใน L-Edit; ตรวจ units, hierarchy, cell origin, layer map และ power labels
12. รัน DRC/LVS ด้วย qualified decks และจัดเก็บผลลัพธ์ตามข้อกำหนด release

เอกสาร Siemens แสดงตัวอย่างลำดับสคริปต์ `0_import.tcl`, `1_place.tcl`, `2_clock.tcl`, `3_route.tcl`, `4_export.tcl` สำหรับ import/place/clock/route/export ตามลำดับ ชื่อและรายละเอียดใน training installation อาจต่างออกไป ต้องใช้ไฟล์จริงของ release

ตัวอย่าง Tcl ต่อไปนี้เป็นการตรวจรายชื่อ stage files เท่านั้น รันใน Tcl shell ได้ แต่ไม่ได้เรียก synthesis/P&R:

```tcl
set stages {
    0_import.tcl 1_place.tcl 2_clock.tcl
    3_route.tcl 4_export.tcl
}
foreach stage $stages {
    if {![file exists $stage]} {error "Missing stage: $stage"}
    puts "Found: $stage"
}
```

การใช้ `source` สคริปต์เหล่านี้ต้องทำภายใน engine/session ที่ reference flow กำหนด ไม่เรียกด้วย `tclsh` ทั่วไปแล้วคาดหวังว่าจะมีคำสั่ง EDA พร้อมใช้งาน ผู้สอนควรแนบ launcher และ scripts ที่ทดสอบบน installation จริงเป็นชุดประกอบแล็บ

## 11. Mini-project: programmable PWM

ใช้ counter8 เป็นฐาน เพิ่ม duty input 8 บิตและ output pwm ตามตัวอย่างด้านล่าง โดย `count` มาจาก instance ของ counter8 และ input duty ต้อง synchronous ต่อ clk:

```systemverilog
assign pwm = (count < duty);
```

VHDL ที่ให้พฤติกรรมเดียวกันสำหรับ count/duty แบบ `std_logic_vector(7 downto 0)` ต้องใช้ `numeric_std` และแปลงเป็น unsigned:

```vhdl
pwm <= '1' when unsigned(count) < unsigned(duty) else '0';
```

ตัวอย่าง top ที่ครบ interface แบบ VHDL (`rtl/vhdl/pwm8.vhd`):

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity pwm8 is
    port (
        clk, rst_n, en : in std_logic;
        duty : in std_logic_vector(7 downto 0);
        pwm : out std_logic
    );
end entity;
architecture rtl of pwm8 is
    signal count : std_logic_vector(7 downto 0);
begin
    u_counter : entity work.counter8(rtl)
        port map (clk => clk, rst_n => rst_n, en => en, count => count);
    pwm <= '1' when unsigned(count) < unsigned(duty) else '0';
end architecture;
```

แบบ Verilog-2001 ซึ่งใช้เป็น SystemVerilog ได้ด้วย (`rtl/verilog/pwm8.v`):

```verilog
module pwm8 (
    input wire clk, rst_n, en,
    input wire [7:0] duty,
    output wire pwm
);
    wire [7:0] count;
    counter8 u_counter (
        .clk(clk), .rst_n(rst_n), .en(en), .count(count)
    );
    assign pwm = (count < duty);
endmodule
```

Compile counter ก่อน PWM ใน VHDL และเลือก top `pwm8` เมื่อทำ mini-project สร้าง SDC ของ PWM ให้มี constraints ของ duty และ pwm โดยตรง ห้ามนำ SDC counter ที่อ้าง output count มาใช้ทั้งไฟล์ เพราะ port นี้ไม่ได้เปิดออกที่ top PWM

นิยาม duty cycle ในช่วงนับเต็ม 256 cycles คือ duty/256: duty=0 ให้ 0%; duty=128 ให้ 50%; duty=255 ให้ 255/256 ซึ่งยังไม่ใช่ 100% หากต้องการ full-on ต้องเพิ่มโหมดหรือขยาย representation

ตัวอย่างนี้เป็น combinational comparator output จึงต้องอภิปราย glitch จากการเปลี่ยน count หลายบิต ถ้าระบบต้องการ output ปลอด glitch ให้ register output และระบุ latency รวมทั้งทดสอบ phase alignment ใหม่ การเปลี่ยน duty กลาง period อาจทำให้ pulse สั้น/ยาวผิดคาด; ระดับกลางให้เพิ่ม shadow duty register และ update เมื่อเริ่มรอบใหม่

### ข้อกำหนดงาน

- Baseline: duty คงที่ระหว่างแต่ละ period, single clock และ synchronous reset
- เพิ่ม test กรณี duty=0, 1, 128, 255 รวมอย่างน้อยหนึ่ง period เต็มต่อค่า
- ตั้ง period 10 ns เป็นเป้าหมายเริ่มต้นที่ต้องพิสูจน์กับ library จริง
- เปรียบเทียบ implementation สองแบบ เช่น registered output เทียบ combinational output โดยระบุ functional latency ที่ต่างกัน
- จัดตาราง cell area, core area, WNS, TNS, hold violations และ routing metrics พร้อม corner/stage
- หากมี power report ต้องระบุ activity, voltage, frequency และวิธีประมาณ; ไม่สรุป power จาก cell count อย่างเดียว

## 12. วิธีวิเคราะห์ปัญหาเบื้องต้น

| อาการ | ตรวจเป็นอันดับแรก | แนวทางแก้ |
|---|---|---|
| Unresolved cell/module | Source list, language mode, library names | เพิ่ม view/source ที่ตรงกันและ re-elaborate |
| Latch inference | Combinational assignment ครบทุก branch หรือไม่ | เพิ่ม default/ครบ branch หรือออกแบบ storage ให้ชัด |
| ไม่มี timing paths | Clock object, top ports, case analysis, exceptions | แก้ constraints และตรวจ coverage ก่อนปรับ RTL |
| Setup violation | Corner, path type, cell/net delay, fanout | ลด logic depth, buffer/resize หรือแก้ placement |
| Hold violation | Min corner, skew, short data path | ใช้ flow-supported hold repair; ตรวจ setup หลังแก้ |
| Congestion | Local density, pins, blockages, PG consumption | ปรับ pin plan/core/placement และ routing resources |
| LVS power mismatch | Global nets, supply pin names, reference netlist | แก้ consistent PG mapping และตรวจ reference |
| DRC จำนวนมาก | Technology, stream map, units, cell GDS | แก้ setup/library ก่อนแก้ geometry รายจุด |
| GLS ไม่ทำงาน | Cell models, supply handling, reset/TB timing | โหลด models ถูกชุดและตรวจ reset sequence |

การเพิ่ม clock period ช่วยเปลี่ยน setup requirement แต่ไม่แก้ short-path hold โดยทั่วไป ส่วนการใส่ false path ต้องมี functional justification ไม่ใช้เพื่อทำรายงานให้ผ่าน

## 13. การประเมินผล

| รายการ | คะแนน |
|---|---:|
| ความเข้าใจ flow/library/timing และแบบทดสอบ | 20 |
| RTL และ self-checking verification | 20 |
| Constraints และ synthesis analysis | 15 |
| Physical implementation และ debugging | 25 |
| Mini-project/release report | 20 |

เสนอเกณฑ์ผ่านรวม 70/100 และต้องผ่าน functional tests, ไม่มี unresolved implementation cells และส่ง verification/timing evidence ครบ หากยังมี violation ต้องระบุสาเหตุและ corrective plan ไม่ถือว่า sign-off ผ่าน

## 14. Release package ที่ผู้เรียนส่ง

1. README: top, tools/releases, PDK/library versions และคำสั่งเริ่มงาน
2. RTL, TB, simulation script และ functional test log
3. SDC พร้อมสมมติฐาน external timing และรายการ exceptions
4. Project setup/reference flow scripts ที่สิทธิ์ใช้งานอนุญาตให้ส่งต่อ
5. Mapped/post-route netlists และ checkpoints ตาม flow
6. Layout stream และ layer-map reference ตามกฎการแจกจ่าย PDK
7. Reports: synthesis, STA, clock, routing, DRC/LVS และ power เมื่อมี
8. ตาราง PPA และรายการ limitations/waivers พร้อมผู้อนุมัติเมื่อเกี่ยวข้อง

แยก foundry-proprietary PDK/decks ออกจากไฟล์ที่แจกนักศึกษา ใช้ version/path manifest อ้างอิงแทนเมื่อไม่มีสิทธิ์แจกจ่าย

## 15. การเตรียมสำหรับผู้สอน

ก่อนเปิดคลาส ต้องรัน counter และ PWM ครบ flow บนรุ่น/PDK/ไลเซนส์เดียวกับห้องเรียน เตรียม checkpoint หลัง synthesis, placement และ routing เพื่อใช้เมื่อเวลาจำกัด ตรวจจำนวน concurrent licenses และระยะเวลารันจริงต่อเครื่อง เก็บ deliberate error cases อย่างน้อย latch, missing clock, wrong power mapping และ congestion ให้ผู้เรียนฝึกอ่านรายงาน

ตัวอย่างโค้ดในเอกสารนี้เป็น teaching examples ยังไม่ได้รันบน Siemens installation ของผู้ใช้ ไม่ควรประกาศเป็น vendor-validated executable lab package จนกว่าจะทดสอบ launcher, TDI project และ decks บนระบบจริงครบแล้ว

## 16. ทางเลือกการขยายหลักสูตร

### วิธีสอนสองภาษาควบคู่โดยคงเวลา 30 ชั่วโมง

- วัน 1: ผู้สอนอธิบาย counter สามรูปแบบและ TB สองภาษาเทียบกัน ผู้เรียนใช้ภาษาที่ถนัดเป็นหลักและรัน regression ของอีกภาษาจากตัวอย่าง
- วัน 2: สร้าง synthesis runs แยก VHDL และ Verilog/SystemVerilog โดยใช้ library, clock/I/O constraints และ settings เดียวกัน ตรวจ top-level port names หลัง elaboration รวมถึงรูปแบบ bus ที่เครื่องมือสร้าง
- วัน 3–4: ทำ implementation เต็มด้วยภาษาหลัก อีกภาษาใช้ checkpoint ที่ผู้สอนเตรียมไว้เพื่อเปรียบเทียบ หากต้องการให้ทุกคนทำสอง flow เต็มควรขยายเวลา
- วัน 5: ส่งผล simulation ทั้งสองภาษาและรายงาน PPA ของภาษาหลัก พร้อมเปรียบเทียบ synthesis ของอีกภาษาเมื่อ frontend รองรับ
- Lab 2/4/10 ใช้ specification เดียวกัน ไม่ให้คะแนนจากความสั้นของ syntax การให้ผล simulation ตรงกันใน test cases เป็น regression evidence และยังไม่ใช่ formal equivalence proof
- RTL ต่างภาษาอาจให้ netlist/area ต่างกันจาก elaboration และ optimization ต้องวิเคราะห์รายงานจริง ไม่คาดหวังให้ cell count ตรงทุกตัว
- SDC, floorplan, CTS, routing และ DRC/LVS สอนร่วมกันหลัง mapping โดยตรวจชื่อ ports และ netlist interface ก่อนใช้ constraints ร่วม

- 3 วัน 18 ชั่วโมง: ใช้ RTL/TB และ technology project ที่เตรียมไว้ เน้น synthesis-to-layout
- 5 วัน 30 ชั่วโมง: รูปแบบหลักตามเอกสาร เหมาะกับเริ่มต้นถึงกลาง
- 8 วัน 48 ชั่วโมง: เพิ่ม UART/register interface, reset synchronization, advanced STA, functional GLS/SDF, analog-top integration และ full-chip introduction

หัวข้อ full-chip pad ring/ESD, SRAM macros, multi-clock CDC, DFT/scan และ IR/EM sign-off ควรเป็นภาคต่อพร้อมเครื่องมือ/ข้อมูลที่เหมาะสม

## 17. แหล่งอ้างอิงหลัก

1. Siemens — Digital Implementer: https://www.siemens.com/it-it/products/ic/ic-custom/ams/digital-implementer/
2. Siemens — A full-flow solution for analog/mixed-signal IC design (ตัวอย่าง TDI staged flow): https://static.sw.cdn.siemens.com/siemens-disw-assets/public/1xqViRATpGkS6iFOXguaxE/en-US/Siemens-SW-Full-flow-solution-for-analog-mixed-signal-IC-design-WP-84095-D9.pdf
3. Siemens — L-Edit IC: https://www.siemens.com/en-us/products/ic/ic-custom/ams/l-edit-ic/
4. Altera — QuestaSim simulator setup script example: https://www.intel.com/content/www/us/en/docs/programmable/683870/25-1/sourcing-questasim-simulator-setup-scripts.html
5. คู่มือ TDI/Oasys/Nitro, Questa และ Calibre ที่ตรง release ติดตั้ง: ใช้ installation documentation หรือ Siemens Support Center ตามสิทธิ์ของหน่วยงาน

Product pages ใช้ยืนยันบทบาทเครื่องมือ ส่วน syntax และ feature availability ต้องตรวจจากคู่มือ release จริง
