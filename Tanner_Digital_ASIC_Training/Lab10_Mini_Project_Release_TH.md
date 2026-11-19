# Lab 10 — Mini-project/release: เพิ่ม PWM, ตรวจ regression, เปรียบเทียบ PPA และส่งมอบ layout

## 10.1 เป้าหมายและขอบเขต

Lab นี้เป็นงานบูรณาการปิดหลักสูตร Tanner Digital ASIC Design Implementation ผู้เรียนเพิ่ม PWM ลงใน digital block ที่พัฒนาจากบทก่อน แล้วทำ implementation ใหม่ตั้งแต่ RTL ถึง layout ตรวจ functional regression, physical verification และ extracted timing ก่อนสร้าง release package ที่ผู้อื่นสามารถเปิด ตรวจสอบ และนำไป integration ได้

ผลสำเร็จคือ **หลักฐานที่ผูกกับไฟล์ release รุ่นเดียวกัน** ว่าผ่าน acceptance ที่ตกลงไว้ ไม่ใช่เพียง screenshot ที่แสดงว่า route เสร็จ การมี GDS/OASIS ไม่ได้ยืนยันว่า DRC/LVS/timing ผ่าน

ตัวอย่างนี้เป็น digital block สำหรับ analog-on-top ใช้ clock เดียวและ standard cells ไม่รวม full-chip pad ring, ESD, package, analog PWM driver หรือ power transistor เอาต์พุต PWM เป็น logic signal; หากต่อไปยังแรงดันอื่นต้องกำหนด level shifter และ domain contract ในขั้น integration

เอกสารนี้ให้ RTL คู่ขนาน SystemVerilog/VHDL และขั้นตอนปฏิบัติแบบไม่ผูกชื่อเมนูของ TDI รุ่นใดรุ่นหนึ่ง ให้ใช้ project wizard และ reference scripts ของรุ่นที่ติดตั้งจริง ไม่ถือว่าชื่อกิจกรรมด้านล่างเป็น Tcl command ของ TDI ตัวอย่าง shell ใช้ Bash ใน Linux/WSL สำหรับจัดการหลักฐาน; คำสั่ง simulator ต้องปรับ license และ library ตามสถานที่อบรม

## 10.2 สิ่งที่ต้องเตรียม

1. Reference project ที่เปิดได้ พร้อม tool version/license และ project technology ที่ถูกต้อง
2. RTL และ TB เดิมที่ผ่าน regression พร้อม baseline netlist/SDC/report จาก Lab ก่อน
3. Standard-cell views ที่เข้าชุดกัน: Liberty, LEF, GDS/OASIS, simulation models และ CDL/SPICE ตาม LVS flow
4. Technology layer map, extraction settings, RC corners และ DRC/LVS decks ที่ผู้รับงานยอมรับ
5. Clock, reset, I/O timing/load, supply voltage และชื่อ PG nets ที่ยืนยันแล้ว
6. จุดกู้คืนก่อนแก้ไขและพื้นที่สำหรับแต่ละ run แยกจากกัน

ก่อนเริ่มให้บันทึกเวอร์ชันทุก input รวมถึง deck revision และ checksum ห้ามสลับ library ระหว่าง sweep โดยไม่ระบุ

## 10.3 Freeze acceptance ก่อนเริ่ม

ตารางนี้เป็นข้อกำหนดตัวอย่างสำหรับการสอน ให้ผู้สอนเติมค่าที่สอดคล้องกับ PDK และ block integration ก่อนรันจริง ห้ามปรับเกณฑ์ย้อนหลังเพื่อให้ผลผ่าน

| หมวด | Acceptance | หลักฐานขั้นต่ำ |
|---|---|---|
| Functional | Directed/random regression ผ่านทั้งหมด; scoreboard mismatch = 0; timeout = 0 | log, test list, seed, source revision |
| TB sensitivity | ใส่ bug โดยตั้งใจแล้ว TB ต้อง fail; คืน RTL ถูกต้องแล้วผ่าน | negative-test log และ revision |
| RTL/synthesis | ไม่มี unintended latch, unresolved reference, undriven functional net; warning ที่เหลือต้องอธิบาย | elaboration/synthesis reports |
| Constraints | ทุก clock และ timing endpoint ที่ต้องวิเคราะห์ถูกครอบคลุม; exception มีเหตุผล | SDC, clock/coverage/exception reports |
| Setup | WNS ≥ 0 ns, TNS = 0 ns ทุก mode/corner ที่กำหนด | post-route extracted STA |
| Hold | worst hold slack ≥ 0 ns, hold TNS = 0 ns ทุก mode/corner ที่กำหนด | min-delay STA |
| Timing checks อื่น | recovery/removal, transition, capacitance, fanout และ pulse width ผ่านตามที่ใช้ | check reports พร้อมขอบเขตที่รองรับ |
| Routing/PG | ไม่มี signal/PG open หรือ short ตาม checks ที่กำหนด; placement ถูกกฎ | connectivity/legality reports |
| DRC | unwaived violation = 0; waiver ต้องได้รับการยอมรับและระบุ rule/location | final-stream DRC summary/detail |
| LVS | match ตาม approved extraction/reference flow; ไม่มี unresolved mismatch | final-stream LVS report |
| GLS | functional gate-level regression ผ่านพร้อม cell models ที่ครบ | simulator log และ model list |
| PPA | ผ่าน timing/physical ก่อน แล้วอยู่ใน area/power budget ที่กำหนด | comparison table พร้อมวิธีวัด |
| Release | เปิด stream ได้, top/layer/pin/PG ถูกต้อง, checksum ครบ | round-trip inspection และ manifest |

ตัวอย่างตั้ง clock period 10 ns เพื่อฝึกเท่านั้น ไม่ใช่ข้อรับรองว่า PDK ทุกชุดจะทำได้ ถ้าไม่มี power engine หรือ activity annotation ที่น่าเชื่อถือ ให้ระบุ power = N/A พร้อมเหตุผล ห้ามแทนด้วยศูนย์หรืออ้างว่าเป็นผล PPA ครบทั้งสามด้าน

การผ่าน connectivity check ไม่ทดแทน DRC enclosure/width/via geometry และ DRC ผ่านไม่ทดแทน LVS หรือ STA

## 10.4 กำหนด PWM contract

ใช้ phase counter ขนาด W บิต รอบละ N = 2^W clock เอาต์พุตลงทะเบียนเพื่อลด combinational glitch ในระดับ RTL มีข้อกำหนดดังนี้

| สัญญาณ/เหตุการณ์ | พฤติกรรม |
|---|---|
| clk | active rising edge |
| rst_n | synchronous reset, active low; ต้องครอบคลุมอย่างน้อยหนึ่ง rising edge |
| en = 0 | phase = 0, pwm = 0 ที่ rising edge ถัดไป |
| duty | unsigned W+1 บิต; 0…N แทน high cycles ต่อรอบ |
| duty > N | clamp เป็น 100% โดยพฤติกรรม comparator |
| en = 1 | pwm ใช้ phase ก่อน edge เทียบกับ duty ที่ sample ณ edge; phase เพิ่ม modulo N |
| เปลี่ยน duty ระหว่างรอบ | มีผล ณ edge ถัดไป อาจเปลี่ยนรูป pulse ในรอบนั้น |
| enable ใหม่ | เริ่มจาก phase 0; high/low แรกเกิดที่ rising edge ที่ en เป็น 1 |

สำหรับ duty คงที่ 0 ≤ D ≤ N:

\[
f_{PWM}=f_{clk}/2^W,\qquad duty\ ratio=D/2^W
\]

เช่น W = 8, fclk = 100 MHz ได้ fPWM = 390.625 kHz และ duty = 64 ได้ 25% การนับความถี่ต้องใช้ clock ทุก edge เพราะ en ในแบบนี้เป็น run control ไม่ใช่ tick divider

**ข้อจำกัด:** en และ duty ต้อง synchronous กับ clk การต่อสวิตช์หรือ MCU ต่าง clock โดยตรงไม่อยู่ใน contract นี้ ข้อมูล duty หลายบิตต้องใช้ handshake/coherent transfer; synchronizer ทีละบิตไม่รับรองความสอดคล้อง หากระบบต้องการ pulse สมบูรณ์ทุกครั้งที่อัปเดต ให้ขยายเป็น shadow/active duty ที่ commit ณ frame boundary และเพิ่ม verification; อย่าอ้างว่า RTL ตัวอย่างมีคุณสมบัตินั้น

## 10.5 ขั้นที่ 1 — บันทึก baseline

1. เปิด project เดิม ยืนยัน top, source list, constraints และ technology
2. รัน regression เดิมโดยไม่แก้ source เก็บ transcript และ exit status
3. เก็บ post-route baseline ที่มี report ครบ หากยังไม่มีให้สร้างก่อนเพิ่ม PWM
4. บันทึก cell area, core area, clock period, post-route setup/hold, wirelength, cell/clock-buffer count และ power methodology
5. ตั้งชื่อ baseline เช่น counter_base_r0 และแยก PWM candidate เช่น counter_pwm_r1

ต้องแยกการเปรียบเทียบสองคำถาม: “เพิ่ม PWM ทำให้ทรัพยากรเปลี่ยนเท่าใด” กับ “PWM ตัวเดียวกันควรใช้ floorplan ใด” อย่ารวมเป็น sweep เดียวแล้วสรุปว่า utilization เป็นสาเหตุทั้งหมด

## 10.6 ขั้นที่ 2 — เพิ่ม RTL SystemVerilog

บันทึกเป็น rtl/pwm_core.sv ตัวอย่างรองรับ W ≥ 1

```systemverilog
module pwm_core #(parameter int unsigned W = 8) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         en,
  input  logic [W:0]   duty,
  output logic         pwm
);
  logic [W-1:0] phase;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      phase <= '0;
      pwm   <= 1'b0;
    end else if (!en) begin
      phase <= '0;
      pwm   <= 1'b0;
    end else begin
      pwm   <= ({1'b0, phase} < duty);
      phase <= phase + 1'b1;
    end
  end
endmodule
```

Comparator ใช้ W+1 บิตอย่างชัดเจน ทำให้ duty = 2^W ให้ high ตลอดได้ หากใช้ duty เพียง W บิต ค่าสูงสุดจะเป็น N−1 และไม่สามารถแทน 100% ด้วยสมการเดิมได้ ไม่ควรแก้ด้วยการปล่อยให้ literal ล้นความกว้าง

## 10.7 ขั้นที่ 3 — RTL VHDL ที่มีพฤติกรรมเดียวกัน

บันทึกเป็น rtl/pwm_core.vhd และเลือก compile เฉพาะ implementation ภาษาที่ใช้ใน run นั้น

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pwm_core is
  generic (W : positive := 8);
  port (
    clk   : in  std_logic;
    rst_n : in  std_logic;
    en    : in  std_logic;
    duty  : in  unsigned(W downto 0);
    pwm   : out std_logic
  );
end entity;

architecture rtl of pwm_core is
  signal phase : unsigned(W-1 downto 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        phase <= (others => '0');
        pwm   <= '0';
      elsif en = '0' then
        phase <= (others => '0');
        pwm   <= '0';
      else
        if resize(phase, W+1) < duty then
          pwm <= '1';
        else
          pwm <= '0';
        end if;
        phase <= phase + 1;
      end if;
    end if;
  end process;
end architecture;
```

ทั้งสองแบบใช้ค่าของ phase ก่อน edge และลงทะเบียน output เหมือนกัน ให้ใช้ stimulus/expected result เดียวกันตรวจภาษาแต่ละแบบ ไม่จำเป็นต้องคาดว่าการ mapping หรือ area ต้องเท่ากันทุก cell แม้ function เท่ากัน

## 10.8 ขั้นที่ 4 — ต่อเข้ากับ block เดิม

1. เพิ่ม instance PWM และใช้ clock/reset ตาม contract เดิม
2. เลือก expose en/duty/pwm ที่ block interface หรือเชื่อมกับ register เดิมโดยระบุ bit mapping
3. เพิ่ม pwm ที่ signal pin และกำหนด external load; pin ใหม่อาจเปลี่ยน pin access และ congestion
4. ห้ามนำ pwm ไปใช้เป็น internal clock โดยไม่มี generated-clock/clock-domain design ที่เหมาะสม ใน Lab นี้ pwm เป็น data output
5. ถ้า reset เดิมเป็น asynchronous ให้กำหนด boundary/reset architecture ใหม่อย่างชัดเจน ตัวอย่าง PWM ใช้ synchronous reset จึงไม่ควรเพียงต่อชื่อเดียวกันแล้วสมมติว่าพฤติกรรมเหมือนกัน
6. ตรวจว่าขา en/duty ถูกผูกกับ stimulus หรือ register จริง ไม่ใช่ constant ที่ทำให้ synthesis optimize PWM ทิ้ง

## 10.9 ขั้นที่ 5 — Self-checking regression

### A. Reference model และ cycle alignment

ขับ stimulus ที่ falling edge ตรวจ output หลัง rising edge เมื่อ nonblocking/signal update เสร็จแล้ว Reference model ต้องคำนวณ output จาก phase เดิมก่อนเพิ่ม phase ห้ามเทียบกับ phase หลังเพิ่ม มิฉะนั้นเกิด off-by-one

ตัวอย่าง TB SystemVerilog สำหรับ standalone PWM (W = 4 เพื่อให้ทดสอบครบช่วงได้เร็ว) บันทึก tb/tb_pwm.sv:

```systemverilog
`timescale 1ns/1ps
module tb_pwm;
  localparam int W = 4;
  localparam int N = 1 << W;
  logic clk = 0, rst_n = 0, en = 0;
  logic [W:0] duty = 0;
  wire pwm;
  int phase_ref = 0;
  int checks = 0;
  bit expected;
  pwm_core #(.W(W)) dut(.*);
  always #5 clk = ~clk;

  task automatic step(input bit r, input bit e, input int d);
    @(negedge clk);
    rst_n = r; en = e; duty = d;
    @(posedge clk);
    if (!r || !e) begin
      expected = 0;
      phase_ref = 0;
    end else begin
      expected = (phase_ref < d);
      phase_ref = (phase_ref + 1) % N;
    end
    #1;
    if (pwm !== expected)
      $fatal(1, "PWM mismatch check=%0d expected=%0b got=%0b",
             checks, expected, pwm);
    checks++;
  endtask

  initial begin
    step(0, 0, 0);
    // Exhaustive fixed-duty tests, including clamp region.
    for (int d = 0; d < 2*N; d++) begin
      step(1, 0, d);
      repeat (2*N) step(1, 1, d);
    end
    // Change duty mid-frame, disable, restart, reset while running.
    for (int k = 0; k < 200; k++) begin
      step(1, 1, (k*7) % (2*N));
      if (k % 11 == 0) step(1, 0, 3);
      if (k % 17 == 0) step(0, 1, 9);
    end
    step(1, 0, 0);
    $display("PASS checks=%0d", checks);
    $finish;
  end
  initial begin
    #100000;
    $fatal(1, "TIMEOUT");
  end
endmodule
```

TB นี้เป็น deterministic starter ไม่ใช่ regression ครบระดับ block ให้เพิ่ม random stimulus โดยบันทึก seed และใช้ scoreboard เดียวกัน รวมถึงทดสอบที่ W = 8 ซึ่งจะนำไป implementation

ตัวอย่าง Questa compile/run สำหรับ SystemVerilog:

```bash
mkdir -p logs
vlib work
vlog -sv rtl/pwm_core.sv tb/tb_pwm.sv
vsim -c work.tb_pwm -do 'onerror {quit -code 1}; run -all; quit -code 0' \
  > logs/pwm_sv.log 2>&1
```

ตรวจทั้ง process status และข้อความ PASS; ตรวจว่า $fatal ถูก simulator รุ่นที่ใช้ส่งเป็น failure จริง ห้ามใช้เพียง grep ว่าไม่มีคำว่า error

สำหรับ VHDL ให้ทำ TB ของภาษาเดียวกันโดยใช้ algorithm เดียวกัน: drive ที่ falling_edge, คำนวณ expected ที่ rising_edge แล้ว wait for 1 ns ก่อน assert; ใช้ std.env.finish และ timeout ที่ severity failure ตัวอย่าง compile เมื่อสร้าง tb_pwm_vhdl แล้ว:

```bash
vcom -2008 rtl/pwm_core.vhd tb/tb_pwm_vhdl.vhd
vsim -c work.tb_pwm_vhdl -do 'onerror {quit -code 1}; run -all; quit -code 0'
```

คำสั่ง VHDL นี้เป็นแบบแผนการเรียก ไม่ได้หมายความว่าไฟล์ TB VHDL ถูกแนบไว้ในบทนี้ หากใช้ mixed-language TB ให้ตรวจการ bind entity/generic และ mapping ของ unsigned vector ตาม simulator ก่อน

### B. Regression matrix ที่ต้องส่ง

| Test | Stimulus | Expected |
|---|---|---|
| Reset | rst_n = 0 ครอบคลุม rising edge ขณะ run | output = 0 และ phase เริ่มใหม่ |
| Disable | en = 0 หลายรอบ แล้วเปิดใหม่ | low ขณะ disable; restart จาก phase 0 |
| 0% | D = 0 | high count = 0 ต่อ N samples |
| ต่ำสุด | D = 1 | high count = 1 ต่อ N samples |
| 25/50/75% | D = N/4, N/2, 3N/4 | high count = D และ period ถูกต้อง |
| เกือบเต็ม | D = N−1 | low count = 1 ต่อ N samples |
| 100%/เกินช่วง | D = N และ D > N | high count = N |
| Wraparound | สังเกตอย่างน้อยสอง frame ต่อค่า D | ไม่หลุดหรือซ้ำ cycle |
| Dynamic duty | เปลี่ยนกลาง frame | ตรง cycle model ตาม contract |
| Existing block | รัน counter/reset/enable tests เดิม | พฤติกรรมเดิมยังผ่าน |
| Integration | register write/read และ PWM ที่ top | bit mapping และ latency ถูกต้อง |

สำหรับ high-count test ให้ disable เพื่อจัด alignment ก่อนเปิด run แล้วนับ N output samples หลัง edge ให้ครบ ห้ามรวม sample ก่อน enable หรือ sample จาก frame ถัดไป

Negative test: เปลี่ยน comparator ชั่วคราวจาก < เป็น <= โดยใช้สำเนา RTL แล้วรัน D = 0; TB ต้องพบ output ผิด บันทึก log จากนั้นคืน source และ rerun ทั้ง suite อย่านำ mutant source เข้า release

## 10.10 ขั้นที่ 6 — Synthesis และ constraint audit

1. Clone project configuration ไป candidate เลือก top/source ใหม่และ parameter W ที่อนุมัติ
2. Elaborate และตรวจ width/signedness, multiple drivers, unresolved cell และ latch
3. Synthesize ด้วย library/corner และ effort เดียวกับ baseline
4. ยืนยันว่า netlist มี counter/comparator/output register หรือโครงสร้างเทียบเท่าที่ optimize แล้ว และ PWM ไม่ถูก constant-fold จากขาที่ไม่ได้ต่อ
5. ตรวจ mapped netlist simulation และเมื่อมี flow ให้ทำ RTL-to-netlist equivalence เพิ่ม
6. ตรวจ SDC coverage ใหม่ทุกครั้งที่เพิ่ม port

ตัวอย่าง SDC แนวทางมาตรฐานสำหรับ standalone top (หน่วยต้องตรวจจาก library/tool):

```tcl
create_clock -name core_clk -period 10.0 [get_ports clk]
set_clock_uncertainty 0.20 [get_clocks core_clk]
set_input_delay -clock core_clk -max 2.0 [get_ports {rst_n en duty*}]
set_input_delay -clock core_clk -min 0.2 [get_ports {rst_n en duty*}]
set_output_delay -clock core_clk -max 2.0 [get_ports pwm]
set_output_delay -clock core_clk -min 0.0 [get_ports pwm]
# ใส่ค่าจริงตาม external driver และ load contract:
# set_input_transition <value> [get_ports {rst_n en duty*}]
# set_load <value> [get_ports pwm]
```

ตรวจว่า wildcard ขา duty resolve ครบ W+1 บิต และไม่มี empty collection; สำหรับ top รวมต้องรวมขาเดิมด้วย ค่าข้างต้นเป็นตัวอย่าง ไม่ใช่ environment ที่ยืนยันแล้ว synchronous rst_n ต้องถูก timing analysis ตาม input contract ห้ามตั้ง false path ครอบ reset โดยอัตโนมัติ หลัง CTS ให้เปลี่ยนไปใช้ propagated-clock analysis ตาม flow และหลีกเลี่ยงการนับ uncertainty/latency ซ้ำ

## 10.11 ขั้นที่ 7 — ออกแบบ utilization sweep อย่างมีเหตุผล

### 10.11.1 แยกคำว่า utilization, placement density และ routing demand

Utilization ต้องระบุนิยาม numerator/denominator เช่น standard-cell area ต่อพื้นที่ rows ที่วางได้ อาจต่างจาก cell area ต่อ core rectangle เมื่อมี macros/blockages/hálo หรือพื้นที่ที่วางไม่ได้ ค่า target placement density ของ algorithm อาจไม่ใช่ measured utilization ห้ามใช้สองค่านี้แทนกันโดยไม่ตรวจคู่มือเครื่องมือ

สำหรับ block ไม่มี macro ใช้ประมาณเริ่มต้น:

\[
A_{core}\approx A_{cells,ref}/U,\quad
W_{core}=\sqrt{A_{core}r},\quad H_{core}=\sqrt{A_{core}/r}
\]

r = Wcore/Hcore และ Acells,ref ต้องเป็นฐานเดียวกัน เช่น mapped netlist ก่อน PnR หลังจากนั้น snap dimensions ลง placement grid และรายงานขนาดจริง ไม่ใช้ค่าคำนวณแทนผลจริง

ตัวอย่าง Acells,ref = 10,000 µm², r = 1:

| เป้าหมาย U | core area เริ่มต้น | ด้านของ core โดยประมาณ |
|---|---:|---:|
| 40% | 25,000 µm² | 158.11 µm |
| 50% | 20,000 µm² | 141.42 µm |
| 60% | 16,666.67 µm² | 129.10 µm |

ตัวเลขนี้เป็นการคำนวณประกอบการสอน ไม่ใช่ผลรันจริง และยังไม่หักพื้นที่ใช้ไม่ได้หรือเพิ่มพื้นที่สำหรับ CTS/repair

### 10.11.2 ข้อสรุปที่ต้องเข้าใจ

**เมื่อเปลี่ยน core area ระยะ routing ก็เปลี่ยน** การเปรียบเทียบ U40 กับ U60 แบบเปลี่ยนขนาด core เป็นการเปรียบเทียบ floorplan ทั้งระบบ รวมผลของระยะระหว่าง cells, pin positions, clock distribution, wire RC และ routing capacity ด้วย ไม่สามารถสรุปว่าผลต่างทั้งหมดเกิดจากความหนาแน่น cell เพียงอย่างเดียว

ในตัวอย่าง core 40% มีด้านยาวกว่าของ 60% เป็น sqrt(1.5) ≈ 1.225 เท่า ระยะเชิงเรขาคณิตบางเส้นจึงอาจยาวขึ้น แต่ **ไม่ได้แปลว่าทุก net หรือ total routed length เพิ่ม 22.5%** เพราะ placement, buffering, topology และ detour เปลี่ยนได้ Core ใหญ่อาจช่วยลดการแออัด แต่ wire ที่ยาวขึ้นอาจเพิ่ม capacitance, delay, clock buffers และ dynamic power ขณะที่ core เล็กอาจลดระยะตรงแต่เพิ่ม routing detour/vias จน timing แย่ลง

**Utilization เฉลี่ยต่ำก็ยังเกิด congestion เฉพาะจุดได้** โดยเฉพาะ pin bank ที่แออัด, macro edge, narrow channel, bus/comparator cluster, blockage corner หรือบริเวณที่ PDN ใช้ tracks จำนวนมาก ตัวอย่าง block เฉลี่ย 40% อาจมีหน้าต่างเล็กที่มี cell/pin demand สูงและเหลือ routing tracks น้อย จึงต้องดู heatmap แยกพื้นที่และ layer ไม่ใช้ค่าเฉลี่ยตัดสิน

ให้แยก cell-density heatmap ออกจาก routing-congestion heatmap Routing demand ยังขึ้นกับ pin access, net topology, layer direction และ via resources การมี whitespace ไม่รับรองว่ามี tracks ใช้งานได้

### 10.11.3 ทำการทดลองสองชุด

**ชุด A — Core-area sweep:** ใช้ netlist/SDC/PDK เดียวกัน กำหนด core จาก U40/U50/U60; คง aspect ratio, pin-order policy และ layer/PDN policy โดยบันทึกตำแหน่ง pin และ PG ที่เกิดขึ้นจริงทุก run การย้าย pin ตามขอบ block ที่เปลี่ยนขนาดเป็นส่วนหนึ่งของ floorplan change

**ชุด B — Placement-density study ที่ core คงที่:** ล็อก core, pins, macro/blockages และ PDN แล้วปรับ target density/spacing เฉพาะที่เครื่องมือรองรับ สิ่งนี้เปลี่ยนการกระจาย cells แต่ไม่เปลี่ยน global utilization ที่คำนวณจาก netlist เดิมต่อ core เดิมโดยตรง ผล cell area หลัง repair อาจเปลี่ยนได้ จึงวัดจริงอีกครั้ง

ถ้าขนาด block เป็น contract ของ analog-on-top อยู่แล้ว ให้ใช้ชุด B เป็นการเลือก implementation ภายใน boundary ส่วนชุด A เป็น feasibility study จนกว่าเจ้าของ top จะยอมรับ boundary ใหม่

### 10.11.4 ตัวแปรควบคุมและข้อมูลที่ต้องเก็บ

คง tool/version, source/netlist checksum, SDC, PVT/RC, libraries, effort, routing layers, clock target, activity workload และ seed หากตั้งได้ ถ้าเครื่องมือรองรับและมีทรัพยากร ให้ใช้หลาย seed ต่อ configuration แล้วรายงานช่วงผล ห้ามเลือก seed ดีที่สุดเพียงตัวเดียวแล้วอ้างแนวโน้มทั่วไป

ตาราง input ของทุก run ต้องระบุ requested U, actual dimensions, actual utilization, density target, pin policy และผลการ snap grid CTS/fix buffers ทำให้ final cell area และ utilization เปลี่ยนจากค่าที่ตั้งไว้ได้

## 10.12 ขั้นที่ 8 — รัน implementation แต่ละ candidate

ทำครบ flow ต่อ candidate ไม่ใช้ placement-only timing แทน post-route timing

1. **Floorplan:** กำหนด boundary/rows/pins และตรวจ placement area ที่ใช้งานได้
2. **PDN:** ต่อ supply ทุก cell ตาม flow ตรวจ opens/shorts และ geometry ที่ deck รองรับ
3. **Placement:** ตรวจ legality, local density, high-fanout, congestion heatmap และ critical paths
4. **CTS:** ตรวจ clock definition, insertion delay, skew, transition และ buffer count
5. **Routing:** global/detailed route; ตรวจ overflow/unrouted nets, detours, via และ pin access
6. **Extraction:** สร้าง parasitics จาก routed design ด้วย RC corner ที่กำหนด ตรวจ missing/unannotated nets
7. **STA:** setup/hold และ electrical checks ทุก required scenario ด้วย propagated clocks
8. **Physical verification:** DRC/LVS และ connectivity จาก final exported layout/netlist ตาม flow
9. **GLS:** functional netlist regression ด้วย functional cell models; power pins ต้องตรง model
10. เก็บ checkpoint/report ของ candidate แยก run ID และห้าม overwrite

ถ้า GUI แสดง route completed แต่รายงานยังมี unrouted net หรือ deck ยังไม่ได้รัน ให้จัดสถานะเป็น incomplete เมื่อแก้ ECO ให้รัน extraction/STA/verification ที่ได้รับผลกระทบใหม่ และ refresh final stream จาก database ล่าสุด

### วิเคราะห์ congestion อย่างเป็นขั้นตอน

1. เปิด routing heatmap แยก layer แล้วระบุพิกัด hotspot
2. เทียบกับ cell/pin density, blockages, PDN straps และทิศทาง preferred routing
3. เปิด nets สำคัญบริเวณนั้น ตรวจว่ามี bus รวมตัวหรือ fanout มาก
4. ตรวจ demand/capacity และ overflow ตามนิยาม report ของเครื่องมือ; หาก capacity = 0 อย่าคำนวณ demand/capacity เองโดยไม่มีนิยามรองรับ
5. ดู detailed route เพราะ global routing ที่ดูดีอาจยังมี pin-access/via DRC
6. ทดลองแก้เพียงหนึ่งนโยบายต่อรอบ เช่น กระจาย pins, ปรับ spacing เฉพาะจุด, ย้าย cluster หรือจัด blockage แล้วเก็บก่อน/หลัง
7. หากแก้ floorplan/PDN ต้องตรวจ PG/geometry ใหม่ ห้ามลด power straps เพียงเพื่อให้ routing ผ่านโดยไม่ประเมิน supply integrity

## 10.13 ขั้นที่ 9 — เปรียบเทียบ PPA และเลือก candidate

แยก synthesis area, final standard-cell area, core area และ block footprint; อย่าใช้คำว่า area เพียงค่าเดียว Final cell area ต้องระบุว่ารวม CTS/tie/filler/decap อย่างไร Total routed wirelength ต้องระบุว่ารวม clock/PG หรือเฉพาะ signal

| Run | Core W×H | Actual U | Final cell area | Routed length/vias | Setup WNS/TNS | Hold worst/TNS | Power | Local congestion | DRC/LVS | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| Baseline | วัดจริง | วัดจริง | วัดจริง | วัดจริง | วัดจริง | วัดจริง | วัดจริง/N/A | ระบุ hotspot | ผลจริง | pass/fail |
| PWM-U40 | วัดจริง | วัดจริง | วัดจริง | วัดจริง | วัดจริง | วัดจริง | วัดจริง/N/A | ระบุ hotspot | ผลจริง | pass/fail |
| PWM-U50 | วัดจริง | วัดจริง | วัดจริง | วัดจริง | วัดจริง | วัดจริง | วัดจริง/N/A | ระบุ hotspot | ผลจริง | pass/fail |
| PWM-U60 | วัดจริง | วัดจริง | วัดจริง | วัดจริง | วัดจริง | วัดจริง | วัดจริง/N/A | ระบุ hotspot | ผลจริง | pass/fail |

คำนวณ relative change สำหรับ metric ที่มี baseline ไม่เป็นศูนย์:

\[
\Delta X(\%)=100(X_{candidate}-X_{baseline})/X_{baseline}
\]

ห้ามคำนวณ % change ของ WNS จาก baseline = 0 ให้รายงานต่างกันกี่ ns พร้อม corner/path group การเทียบ setup slack ต้องใช้ clock/I/O contract และ scenarios เดียวกัน Hold ไม่ควรถูกยุบเป็น Fmax และการประมาณ Fmax จาก path หนึ่งไม่ยืนยันว่าทุก I/O/clock check ผ่าน

Power ต้องเทียบ voltage/frequency/corner, stimulus window, duty/en workload และ annotation coverage เดียวกัน แยก leakage/internal/switching ตาม report หากผลมาจาก vectorless estimate ให้ติดป้ายชัดเจน อย่าสรุปว่า PWM ลด power จากการที่ output มี duty ต่ำ เพราะ counter/comparator/clock ยังสลับอยู่

ลำดับเลือก candidate:

1. ตัดตัวที่ functional/physical/timing ไม่ผ่านออกจากรายชื่อ release
2. ตรวจว่า boundary/pin/supply ตรง integration contract
3. เปรียบเทียบ PPA ตาม objective เช่น core เล็กสุดภายใต้ timing/power budget
4. พิจารณา margin และ hotspot ไม่เลือกจาก WNS หรือ area ค่าเดียว
5. ระบุเหตุผลที่เลือกพร้อมข้อแลกเปลี่ยน เช่น U50 มี core ใหญ่กว่า U60 แต่ลด detour และผ่าน hold ทุก corner

การเลือกนี้เป็นการตัดสินบนหลักฐานของ run จริง ไม่ใช่กฎว่า utilization ต่ำดีกว่าเสมอ

## 10.14 ขั้นที่ 10 — Regression หลัง implementation

1. รัน RTL suite เดิมทั้งหมดกับ source revision ที่จะ release
2. รัน mapped-netlist functional GLS ด้วย stimulus/scoreboard ที่สอดคล้องกับ top
3. รัน post-route functional GLS หาก netlist เปลี่ยนจาก CTS/repair; ใส่ model ของ clock/tie/special cells ตามที่ simulator ต้องใช้
4. ตรวจ no missing models, unknown output หลัง initialization ตาม contract และ PG mapping ถูกต้อง
5. หากกำหนด timing GLS/SDF ให้บันทึก SDF corner, min/typ/max selection, hierarchy และ annotation coverage; ตรวจ unmatched instances/arcs และ timing-check violations
6. อย่าปิด timing checks/notifier เพื่อประกาศ pass หากจำเป็นสำหรับ debug ให้แยก debug result ออกจาก acceptance

Functional GLS แบบไม่มี SDF ยืนยัน functional behavior ของ netlist แต่ไม่ทดแทน extracted STA ส่วน timing GLS ไม่ใช่การวิเคราะห์ timing ครบทุก path/corner

TB starter ที่ sample หลัง 1 ns ใช้สำหรับ RTL/zero-delay functional GLS เป็นหลัก หากใส่ delay จริง ต้องจัด output sampling ให้สอดคล้องกับ latency/interface และ timing budget ห้ามเพิ่ม delay ใน TB แบบสุ่มจนผลผ่าน

## 10.15 ขั้นที่ 11 — Final-layout acceptance

1. Freeze candidate database และตั้ง release ID
2. Stream out GDSII/OASIS ด้วย layer map, units และ hierarchy policy ที่อนุมัติ
3. ยืนยันว่ามี cell geometry ครบตามการส่งแบบ merged stream หรือมี companion library stream ที่ผู้รับงานตกลงไว้ ไม่ปล่อย unresolved cell references
4. เปิด stream ใหม่ใน session/database สะอาด ตรวจ top name, bbox, units, layers, signal/PG pin labels และ orientation
5. รัน final DRC/LVS บน stream นี้ตาม deck และ extraction/reference setup ที่ยอมรับ
6. ตรวจว่า stream ตรงกับ implementation database ที่สร้าง post-route netlist/parasitics/STA ถ้ามี seal/metal fill หรือแก้ geometry ที่กระทบ extraction ให้ประเมินและรันใหม่ตาม sign-off flow
7. ตรวจ block integration abstract เช่น LEF ว่า boundary, pins, obstruction และ PG ตรงกับ layout
8. บันทึก exceptions/limitations ที่ยังมี ห้ามใช้คำว่า tapeout-ready ถ้ายังไม่ได้ทำ checks ที่ foundry/ผู้รับงานต้องการ

การส่ง layout ให้ผู้รับงานเป็น package ของ Lab ไม่ใช่การส่ง foundry อัตโนมัติ การทำ block-level DRC/LVS ผ่านยังไม่ยืนยัน full-chip ESD, latch-up, density, EM/IR หรือ interaction กับ analog top หากอยู่นอกขอบเขตให้ระบุใน release notes

## 10.16 ขั้นที่ 12 — จัด release package

โครงสร้างแนะนำ ใช้เฉพาะไฟล์ที่สร้างจริงและระบุ N/A สำหรับรายการที่ flow ไม่ส่งออก:

```text
release_pwm_r1/
  README.md
  RELEASE_NOTES.md
  acceptance.csv
  manifest.csv
  SHA256SUMS
  rtl/
  constraints/
  scripts/
  config/
  netlist/
  layout/
  abstract/
  parasitics/
  timing/
  verification/
  ppa/
```

| โฟลเดอร์/ไฟล์ | เนื้อหาที่ต้องมี |
|---|---|
| README | top, interface, clock/reset, supply, voltage, boundary, วิธีเปิด/รัน |
| RELEASE_NOTES | release ID, source revision, known limitations, PWM contract และผลสรุป |
| acceptance.csv | criterion, threshold, measured result, evidence path, pass/fail/N/A และเหตุผล |
| manifest.csv | file path, purpose, origin run ID, tool/version และ scenario ตามความเหมาะสม |
| constraints/config/scripts | SDC, selected settings, source lists และ flow scripts ที่ใช้จริง |
| netlist | final functional/timing netlist และ LVS reference ตาม flow แยกชื่อชัดเจน |
| layout/abstract | final stream, optional DEF และ LEF/abstract ที่อนุมัติ |
| parasitics/timing | extracted RC files, STA reports และ SDF หากกำหนด |
| verification | DRC/LVS, connectivity, GLS/regression logs, waiver records |
| ppa | raw reports, comparison CSV, heatmap พร้อม run/layer/scale |

ไม่แจก PDK/decks/library ที่มีข้อจำกัดสิทธิ์ ให้ระบุ approved path/version/checksum และวิธีเตรียมแทนตามสิทธิ์ใช้งาน

ตัวอย่างสร้าง checksum ภายใน release directory หลังคัดลอกไฟล์ครบ:

```bash
python3 - <<'PY'
from pathlib import Path
import hashlib
root = Path('release_pwm_r1')
if not root.is_dir():
    raise SystemExit('release directory missing')
records = []
for p in sorted(root.rglob('*')):
    if p.is_file() and p.name != 'SHA256SUMS':
        h = hashlib.sha256()
        with p.open('rb') as f:
            for chunk in iter(lambda: f.read(1024*1024), b''):
                h.update(chunk)
        records.append(f'{h.hexdigest()}  {p.relative_to(root).as_posix()}')
(root/'SHA256SUMS').write_text('\n'.join(records)+'\n', encoding='utf-8')
PY
(cd release_pwm_r1 && sha256sum -c SHA256SUMS)
tar -czf release_pwm_r1.tar.gz release_pwm_r1
sha256sum release_pwm_r1.tar.gz > release_pwm_r1.tar.gz.sha256
```

Checksum ยืนยัน byte integrity ไม่ยืนยัน correctness ทุกการแก้หลัง freeze ต้องอัปเดต release ID/evidence/checksum ให้สอดคล้องกัน ก่อนส่งให้ทดลอง unpack ใน directory ใหม่ เปิด stream และใช้ README ตรวจ prerequisites/run commands อีกครั้ง

## 10.17 Troubleshooting

| อาการ | จุดตรวจ | แนวทางแก้และตรวจซ้ำ |
|---|---|---|
| PWM ผิดหนึ่ง cycle | sample alignment, pre/post increment | ยึด contract และแก้ model/RTL ให้ตรง; rerun boundaries |
| ทำ 100% ไม่ได้ | duty width มีเพียง W บิต | ใช้ W+1 บิตหรือกำหนด saturation contract ใหม่ |
| PWM หายหลัง synthesis | input constants, unconnected output | ตรวจ top connectivity/port constraints แล้ว synthesize ใหม่ |
| RTL ผ่าน แต่ GLS X | reset edge, cell models, PG pins, notifier | แยก initialization/model/timing issue และใช้ model ที่เข้าชุด |
| U40 timing แย่กว่า U60 | wire RC, clock load, pin distance | ดู extracted path และ route จริง; อย่าสรุปจาก U อย่างเดียว |
| U ต่ำแต่ route fail | local pin cluster/PDN blockage | ดู congestion ราย layer/ตำแหน่ง แล้วแก้ hotspot |
| setup ผ่าน hold fail | min RC/cell corner, skew, short paths | ทำ hold repair ตาม flow แล้ว recheck setup/physical |
| DRC ผ่าน LVS fail | PG naming, reference netlist, extraction map | ตรวจ opens/shorts/ports และ deck inputs |
| report ผ่านแต่ไฟล์ส่งไม่ตรง | stale stream/checkpoint | export ใหม่จาก frozen database แล้วตรวจ final stream |
| power ต่ำผิดปกติ | activity coverage/workload | ตรวจ annotation และ clock toggle; รายงาน N/A หากวัดไม่ได้ |

## 10.18 งานที่ผู้เรียนต้องส่งและเกณฑ์ประเมิน

1. PWM specification และ RTL ทั้งสองภาษา พร้อมระบุภาษาที่ใช้สร้าง layout
2. Regression matrix, self-checking evidence, boundary tests และ negative-test log
3. Baseline และ utilization sweep อย่างน้อยสองจุด เช่น 40%/60%; แนะนำ 50% เพิ่มเพื่อดูแนวโน้ม
4. ตาราง actual core/cell area, timing ทุก required scenario, route metrics, congestion และ power methodology
5. วิเคราะห์ hotspot อย่างน้อยหนึ่งตำแหน่ง แม้ค่า utilization เฉลี่ยต่ำ พร้อมระบุเหตุและการแก้
6. Acceptance matrix ที่อ้าง evidence จาก release เดียวกันครบทุกข้อ
7. Final layout/netlist/constraints/abstract/reports และ manifest/checksum
8. บันทึกข้อจำกัดและ integration contract สำหรับ analog-on-top

คะแนนแนะนำ: functional/regression 25%, constraints/timing 20%, physical verification 20%, การวิเคราะห์ sweep/PPA 20%, release reproducibility 15% อย่างไรก็ตามการมีคะแนนรวมสูงไม่ทดแทน mandatory acceptance หาก functional, required timing หรือ unwaived physical checks ไม่ผ่าน ต้องจัดสถานะ release เป็น FAIL/INCOMPLETE

คำถามท้าย Lab:

- ทำไม core ที่ใหญ่ขึ้นจึงอาจช่วย routability แต่ทำให้ extracted timing แย่ลง?
- เหตุใด global utilization เท่ากันจึงมี local congestion ต่างกันได้?
- เมื่อปรับ target density โดย core คงที่ ค่า global utilization จำเป็นต้องเปลี่ยนหรือไม่?
- ถ้า final cell area เพิ่มหลัง CTS ตัวเลข utilization ที่ตั้งก่อน floorplan ยังใช้แทน measured utilization ได้หรือไม่?
- ทำไม functional GLS ผ่านจึงยังไม่เพียงพอสำหรับ timing acceptance?
- หาก stream out เกิดก่อน ECO แต่ STA เกิดหลัง ECO จะยอมรับ release ได้หรือไม่?

## 10.19 เอกสารอ้างอิงและการใช้งานในบทนี้

1. Siemens, Digital Implementer: https://www.siemens.com/lv-lv/products/ic/ic-custom/ams/digital-implementer/ — ใช้ยืนยันบริบทผลิตภัณฑ์และ workflow ระดับสูง; syntax/เมนูจริงต้องตรวจ help/reference ของ installation ที่ใช้
2. OpenROAD, Global Placement: https://openroad.readthedocs.io/en/latest/main/src/gpl/README.html — ใช้ประกอบแนวคิดแยก density และ routability-driven placement; ไม่ใช่คู่มือคำสั่ง TDI
3. OpenROAD, Global Routing: https://openroad.readthedocs.io/en/latest/main/src/grt/README.html — ใช้ประกอบการอ่าน congestion และข้อแตกต่างระหว่างการสร้างผล routing กับการไม่มี congestion; ไม่ใช้แทน sign-off deck
4. เอกสารภายในที่ต้องแนบชื่อ/version ในแต่ละสถานที่อบรม: TDI user guide/reference flow, PDK integration guide, approved DRC/LVS runsets, extraction guide และ standard-cell library release notes

สถานะเอกสาร: เป็นคู่มือและโค้ดตัวอย่างสำหรับจัด Lab ยังไม่ได้รัน TDI/PDK หรือ simulator จริงในสภาพแวดล้อมของผู้เรียน จึงไม่อ้างว่ามี measured PPA หรือผ่าน sign-off แล้ว
