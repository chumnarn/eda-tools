# Lab 2 — RTL/TB: Counter และการจำลองแบบ Self-checking

หลักสูตร Tanner Digital ASIC Design Implementation

## 1. เป้าหมายและขอบเขต

Lab นี้สร้าง unsigned binary counter ด้วย VHDL และ SystemVerilog ที่มีพฤติกรรมเหมือนกัน แล้วใช้ testbench ตรวจผลอัตโนมัติ ครอบคลุม reset, enable, hold, wraparound และ reset ระหว่างทำงาน ผลที่ได้คือ RTL และหลักฐาน functional simulation สำหรับส่งต่อขั้น synthesis ไม่ใช่การรับรอง timing หรือความพร้อมผลิตชิป

ระยะเวลาแนะนำ 2–3 ชั่วโมง ผู้เรียนควรผ่าน Lab 1 และทราบ simulator ที่ได้รับอนุญาตให้ใช้ในห้องปฏิบัติการแล้ว L-Edit ใช้กับงาน layout ส่วนการจำลอง HDL ใน Lab นี้ใช้ simulator เช่น ModelSim/Questa ที่ติดตั้งและมี license รองรับ ไม่สมมติว่าเปิด L-Edit แล้วจะมี HDL simulator พร้อมเสมอ

เมื่อจบ ผู้เรียนต้องอธิบายการเปลี่ยน state ที่ขอบ clock, priority ของ reset, เหตุผลที่ต้องรอให้ RTL update ก่อนตรวจค่า และแสดงว่า testbench ตรวจพบ bug ที่ใส่โดยตั้งใจได้

## 2. Specification ที่ต้องตกลงก่อนเขียนโค้ด

| รายการ | ข้อกำหนด |
|---|---|
| ความกว้าง | N บิต, N ≥ 1; Lab ใช้ N=4 |
| Clock | ขอบขาขึ้น; testbench ใช้คาบ 10 ns |
| Reset | rst_n active-low, asynchronous assertion; reset มี priority สูงสุด |
| Enable | synchronous active-high; อ่านที่ขอบขาขึ้น |
| en=1 | q_next = (q+1) mod 2^N |
| en=0 | q_next = q |
| rst_n=0 | q=0 โดยไม่ต้องรอขอบ clock และคง 0 แม้ en=1 |
| Wraparound | 15 → 0 สำหรับ N=4; ไม่มี carry output |
| Input ใน Lab | เป็น 0/1 ที่ทราบค่า; ไม่มีการใช้ X เพื่อแทน don't-care |

สมการ state เมื่อไม่มี reset คือ q[k+1] = en[k] ? ((q[k]+1) mod 2^N) : q[k]

ตัวอย่างขอบ clock ต่อเนื่องหลัง reset:

| ขอบ | en ที่ถูก sample | q ก่อนขอบ | q หลังขอบ |
|---|---:|---:|---:|
| 1 | 0 | 0 | 0 |
| 2 | 1 | 0 | 1 |
| 3 | 1 | 1 | 2 |
| 4 | 0 | 2 | 2 |

reset แบบ asynchronous ใน RTL นี้เป็นตัวอย่างสำหรับศึกษา assertion เท่านั้น การปล่อย reset ใน testbench จะทำห่างจากขอบขาขึ้นเพื่อหลีกเลี่ยง race ใน simulation สำหรับชิปจริงต้องออกแบบ reset distribution และใช้ asynchronous assert/synchronous deassert ตาม clock domain เมื่อจำเป็น พร้อมตรวจ recovery/removal; RTL simulation ไม่จำลอง metastability ทางกายภาพ

## 3. ขั้นที่ 1 — เตรียมโฟลเดอร์และบันทึก environment

สร้าง working directory ของ Lab แล้ววางไฟล์ดังนี้:

```text
lab02/
  counter.sv
  tb_counter.sv
  counter.vhd
  tb_counter.vhd
  reports/
```

บันทึกชื่อ simulator, version, OS, วันที่, top-level testbench, N และภาษาใน reports/environment.txt ใช้คำสั่ง `vsim -version` หาก executable ของ ModelSim/Questa อยู่ใน PATH การเรียก simulator จาก terminal ต้องใช้ environment ที่ตั้งไว้ใน Lab 1 อย่าคัดลอกตัวแปร license ของเครื่องอื่นมาใช้

แต่ละภาษาใช้ library จำลองแยกกัน เพื่อลดปัญหาชื่อ design unit ซ้ำกัน Lab นี้ไม่ต้องใช้ standard-cell simulation models เพราะเป็น RTL simulation

## 4. ขั้นที่ 2 — เขียน SystemVerilog RTL

บันทึกเป็น counter.sv:

```systemverilog
module counter #(parameter int unsigned N = 4) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         en,
  output logic [N-1:0] q
);
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) q <= '0;
    else if (en) q <= q + 1'b1;
  end
endmodule
```

ใช้ nonblocking assignment (`<=`) กับ state ของ flip-flop ไม่มี else ในกรณี en=0 เพราะ register ต้องเก็บค่าเดิม โครงสร้างนี้ไม่ใช่ combinational process จึงไม่ได้หมายถึง latch การบวกเก็บลง N บิตทำให้ผลล้นถูกตัดเป็น modulo 2^N

`always_ff` และชนิด `logic` เป็น SystemVerilog ต้อง compile ด้วยโหมด SystemVerilog หากต้องใช้ Verilog-2001 ให้เปลี่ยน `logic` ของ output เป็น `reg`, input เป็น `wire`, parameter เป็น `parameter N=4`, `always_ff` เป็น `always` และ `'0` เป็น `{N{1'b0}}` โดยคง nonblocking assignment เดิม

## 5. ขั้นที่ 3 — เขียน VHDL RTL ที่เทียบเท่ากัน

บันทึกเป็น counter.vhd:

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
  generic (N : positive := 4);
  port (
    clk   : in  std_logic;
    rst_n : in  std_logic;
    en    : in  std_logic;
    q     : out std_logic_vector(N-1 downto 0)
  );
end entity;

architecture rtl of counter is
  signal count : unsigned(N-1 downto 0);
begin
  q <= std_logic_vector(count);
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      count <= (others => '0');
    elsif rising_edge(clk) then
      if en = '1' then
        count <= count + 1;
      end if;
    end if;
  end process;
end architecture;
```

ใช้ `numeric_std` และ `unsigned` เพื่อระบุความหมายเลขฐานสองแบบไม่ติดเครื่องหมายอย่างชัดเจน ไม่ผสมแพ็กเกจ arithmetic ที่มี overload ขัดกัน ตัวแปร N เป็น positive จึงไม่ยอมให้ N=0 ใช้ signal ภายในเพื่อไม่ต้องอ่าน output port กลับ

## 6. ขั้นที่ 4 — วางแผน testbench

testbench มี DUT, clock generator, stimulus, reference model, checker และ timeout ให้ stimulus เปลี่ยนที่ขอบขาลง และตรวจหลังขอบขาขึ้น 1 ns เพื่อให้ nonblocking assignments/delta cycles เสร็จก่อน ค่า 1 ns เป็น sampling offset ของ testbench ไม่ใช่ propagation delay ของวงจร

reference model ใช้ integer และ modulo แยกจากนิพจน์ bit-vector ใน DUT การตรวจต้องหยุด simulation เมื่อพบ mismatch และรายงาน expected/actual ไม่ปล่อยให้ข้อความ PASS ปรากฏหลัง failure

| Test | สิ่งที่ต้องพิสูจน์ |
|---|---|
| Initial reset | เริ่มจากค่าไม่ทราบแล้วถูก reset เป็นศูนย์ |
| Hold at zero | en=0 ไม่เพิ่มค่า |
| Count | en=1 เพิ่มหนึ่งต่อขอบขาขึ้น |
| Pause/resume | hold ที่ค่าที่ไม่ใช่ศูนย์ และกลับมานับต่อ |
| Wrap | ผ่านขอบเขต 15→0 มากกว่าหนึ่งครั้ง |
| Mid-run reset | reset ที่อยู่นอกขอบ clock ล้างค่าทันที |
| Reset priority | ระหว่าง reset มี en=1 ก็ยังเป็นศูนย์ |
| Mixed enables | รูปแบบ enable สลับกันยาวพอให้ตรวจ state ต่อเนื่อง |
| Timeout | simulation ที่ไม่จบต้องถูกตัดเป็น failure |

## 7. ขั้นที่ 5 — SystemVerilog self-checking testbench

บันทึกเป็น tb_counter.sv โค้ดจำกัด N=4 ตามการทดลองนี้ การใช้ integer model กับ N ขนาดใหญ่มากต้องเปลี่ยนชนิด reference model ให้รองรับช่วงค่าด้วย

```systemverilog
`timescale 1ns/1ps
module tb_counter;
  localparam int N=4;
  localparam int MODULUS=2**N;
  logic clk=0, rst_n=1, en=0;
  logic [N-1:0] q;
  int expected=0, checks=0, wraps=0;
  counter #(.N(N)) dut(.*);
  always #5 clk = ~clk;

  task automatic check_q(input string label_text);
    if (q !== N'(expected))
      $fatal(1,"%s t=%0t expected=%0d actual=%b",
             label_text,$time,expected,q);
    checks++;
  endtask

  task automatic tick(input bit enable_value);
    @(negedge clk);
    en=enable_value;
    @(posedge clk);
    if (!rst_n) expected=0;
    else if (enable_value) begin
      if (expected==MODULUS-1) wraps++;
      expected=(expected+1)%MODULUS;
    end
    #1;
    check_q("tick");
  endtask

  initial begin
    // Assert between clock edges; verify before the next rising edge.
    #2; rst_n=0; expected=0;
    #1; check_q("initial async reset");
    tick(1); tick(1); // reset overrides enable
    @(negedge clk); rst_n=1; en=0;
    repeat(3) tick(0);
    repeat(5) tick(1);
    repeat(4) tick(0);
    repeat(2*MODULUS+3) tick(1);
    // q is nonzero here; clear it before the next rising edge.
    @(negedge clk); en=1;
    #2; rst_n=0; expected=0;
    #1; check_q("mid-run async reset");
    tick(1); tick(1);
    @(negedge clk); rst_n=1; en=0;
    for (int i=0;i<64;i++) tick((i%3)!=0);
    if (wraps<2) $fatal(1,"insufficient wrap coverage");
    $display("PASS checks=%0d wraps=%0d",checks,wraps);
    $finish;
  end
  initial begin
    #10000;
    $fatal(1,"TIMEOUT");
  end
endmodule
```

`!==` จับ X/Z ได้เมื่อเทียบกับ expected ที่ทราบค่า ต่างจากการใช้ comparison ที่อาจให้ผล X แล้วทำให้ checker เงียบ ตัวแปร wraps นับเฉพาะการล้นที่คาดจาก model; ทุกเหตุการณ์ยังต้องผ่าน checker ของ q จึงถือว่าพฤติกรรม wrap ถูกต้อง

## 8. ขั้นที่ 6 — VHDL self-checking testbench

บันทึกเป็น tb_counter.vhd ใช้ VHDL-2008 เพื่อเรียก `std.env.finish`:

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_counter is end entity;
architecture sim of tb_counter is
  constant N : positive := 4;
  constant MODULUS : positive := 2**N;
  signal clk : std_logic := '0';
  signal rst_n : std_logic := '1';
  signal en : std_logic := '0';
  signal q : std_logic_vector(N-1 downto 0);
begin
  clk <= not clk after 5 ns;
  dut : entity work.counter(rtl)
    generic map(N=>N)
    port map(clk=>clk, rst_n=>rst_n, en=>en, q=>q);

  stimulus : process
    variable expected : natural := 0;
    variable checks : natural := 0;
    variable wraps : natural := 0;
    procedure check_q(label_text : string) is
    begin
      assert q = std_logic_vector(to_unsigned(expected,N))
        report label_text & " expected=" & integer'image(expected) &
               " actual=0x" & to_hstring(q)
        severity failure;
      checks := checks+1;
    end procedure;
    procedure tick(enable_value : std_logic) is
    begin
      wait until falling_edge(clk);
      en <= enable_value;
      wait until rising_edge(clk);
      if rst_n='0' then
        expected := 0;
      elsif enable_value='1' then
        if expected=MODULUS-1 then wraps := wraps+1; end if;
        expected := (expected+1) mod MODULUS;
      end if;
      wait for 1 ns;
      check_q("tick");
    end procedure;
  begin
    wait for 2 ns;
    rst_n <= '0'; expected := 0;
    wait for 1 ns;
    check_q("initial async reset");
    tick('1'); tick('1');
    wait until falling_edge(clk);
    rst_n <= '1'; en <= '0';
    for i in 1 to 3 loop tick('0'); end loop;
    for i in 1 to 5 loop tick('1'); end loop;
    for i in 1 to 4 loop tick('0'); end loop;
    for i in 1 to 2*MODULUS+3 loop tick('1'); end loop;
    wait until falling_edge(clk);
    en <= '1';
    wait for 2 ns;
    rst_n <= '0'; expected := 0;
    wait for 1 ns;
    check_q("mid-run async reset");
    tick('1'); tick('1');
    wait until falling_edge(clk);
    rst_n <= '1'; en <= '0';
    for i in 0 to 63 loop
      if (i mod 3)=0 then tick('0'); else tick('1'); end if;
    end loop;
    assert wraps>=2 report "insufficient wrap coverage" severity failure;
    report "PASS checks=" & integer'image(checks) &
           " wraps=" & integer'image(wraps) severity note;
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

การเปรียบเทียบ std_logic_vector กับค่าที่มีแต่ 0/1 จะไม่ยอมให้ U/X/Z ใน q ผ่าน ต้องตั้ง simulator ให้ severity failure หยุดจริง ห้ามกด Continue หลัง assertion failure แล้วตีความข้อความภายหลังเป็นผลผ่าน

## 9. ขั้นที่ 7 — Compile และจำลองด้วย ModelSim/Questa

คำสั่งต่อไปนี้เป็น flow มาตรฐานสำหรับเครื่องที่มี vlib/vlog/vcom/vsim ใน PATH และมี license ที่เหมาะสม รายละเอียด edition, startup และ GUI อาจต่างกัน ให้ตรวจ `-help` ของรุ่นที่ติดตั้งหาก option ไม่ตรง เรียกจากโฟลเดอร์ lab02

### 9.1 SystemVerilog

```tcl
vlib work_sv
vlog -work work_sv -sv counter.sv tb_counter.sv
vsim -c work_sv.tb_counter -do "onerror {quit -code 1}; onbreak {quit -code 1}; run -all; quit -code 0"
```

### 9.2 VHDL

VHDL testbench อ้าง `work.counter` ซึ่งจะชี้ working library ที่ compile design unit อยู่ ให้ compile RTL และ TB ลง library เดียวกัน:

```tcl
vlib work_vhdl
vcom -work work_vhdl -2008 counter.vhd tb_counter.vhd
vsim -c work_vhdl.tb_counter -do "onerror {quit -code 1}; onbreak {quit -code 1}; set BreakOnAssertion 3; run -all; quit -code 0"
```

รันจาก terminal ทีละคำสั่งและตรวจ compile exit status ก่อนจำลอง ใน automation อย่ารัน simulator ต่อเมื่อ compile ล้มเหลว เพราะอาจโหลด design เก่าที่เคย compile ไว้ได้ สำหรับ VHDL บางรุ่น `finish` อาจเข้าสู่ finish dialog/behavior ตามการตั้งค่า ให้ตรวจว่า batch จบเองและ exit status ถูกต้องก่อนใช้ใน regression

### 9.3 ดู waveform

เปิด GUI ด้วย `vsim work_sv.tb_counter` หรือ `vsim work_vhdl.tb_counter` แล้วใช้ Transcript:

```tcl
add wave sim:/tb_counter/clk
add wave sim:/tb_counter/rst_n
add wave sim:/tb_counter/en
add wave -radix unsigned sim:/tb_counter/q
run -all
```

หาก internal signals ถูก optimize ให้ใช้ตัวเลือก visibility/access ตามคู่มือของรุ่นที่ติดตั้ง ไม่ควรเดา optimization flags ของทุก edition ว่าเหมือนกัน

ตรวจ cursor ที่ reset assertion ระหว่างขอบ clock, ช่วง hold ที่ q=5, wrap 15→0 และการเริ่มนับหลัง reset ช่วง reset ไม่ต้องมี clock edge ก็ล้าง state ได้ แต่ waveform ที่ดูถูกต้องบางช่วงยังไม่ทดแทน self-checking result

## 10. ขั้นที่ 8 — ทางเลือกด้วย Icarus Verilog และ GHDL

ใช้สำหรับทบทวนพฤติกรรม RTL บนเครื่องที่ไม่มี ModelSim/Questa โดยยังต้องตรวจความสามารถภาษาและ version ที่ติดตั้ง

```sh
# SystemVerilog
iverilog -g2012 -s tb_counter -o counter_sim tb_counter.sv counter.sv
vvp counter_sim

# VHDL-2008: run in a separate clean working directory if needed
ghdl -a --std=08 counter.vhd tb_counter.vhd
ghdl -e --std=08 tb_counter
ghdl -r --std=08 tb_counter --assert-level=error --wave=counter.ghw
```

Icarus ไม่สร้าง waveform โดยอัตโนมัติ หากต้องการ VCD ให้เพิ่มใน testbench module ก่อน compile ใหม่:

```systemverilog
initial begin
  $dumpfile("counter.vcd");
  $dumpvars(0,tb_counter);
end
```

## 11. ขั้นที่ 9 — ผลที่คาดหมายและการอ่านรายงาน

สำหรับโค้ดที่ให้มา N=4 จะได้ `PASS checks=117 wraps=4` โดย checks รวมการตรวจ asynchronous reset สองครั้ง ไม่รวม timeout ค่า wraps รวมก่อนและหลัง mid-run reset ผล SV/VHDL ต้องตรงกันในเชิงค่าและลำดับ แม้ข้อความ timestamp หรือรูปแบบ log ต่างกัน

ก่อนยืนยัน PASS ตรวจให้ครบว่า compile สำเร็จ, โหลด top ถูกตัว, run ถึงจุดจบตามปกติ, ไม่มี assertion/fatal/error, ไม่มี timeout และมีข้อความ PASS จาก testbench การหยุดที่เวลาใดเวลาหนึ่งด้วยมือยังไม่ถือว่าผ่าน

ผลทั้งหมดในหัวข้อนี้เป็น expected results จาก test plan ผู้สอนต้องแนบ log ที่รันจริงของ environment ที่ใช้ฝึกอบรมแยกต่างหาก

## 12. ขั้นที่ 10 — Fault injection: พิสูจน์ว่า TB จับ bug ได้

1. เก็บสำเนา RTL ที่ถูกต้องหรือ commit ก่อนแก้
2. SV เปลี่ยน `else if (en)` เป็น `else if (!en)` หรือ VHDL เปลี่ยน `if en = '1'` เป็น `if en = '0'`
3. compile ใหม่และจำลอง ต้อง fail ที่ช่วง hold/count พร้อม expected/actual
4. คืน RTL และทดสอบอีกครั้ง ต้อง PASS
5. ทำอีกกรณีโดยเปลี่ยน reset เป็น synchronous: SV เอา `or negedge rst_n` ออก; VHDL ย้ายการตรวจ reset เข้าใน rising_edge(clk) แล้วจำลอง ต้อง fail ที่การตรวจ reset เวลา 3 ns ก่อนขอบขาขึ้นแรก
6. คืน RTL, compile และจำลองให้ผ่านก่อนส่งงาน

ห้ามแก้ expected ให้ตาม bug ใน DUT หาก assertion ไม่ fail หลังใส่ bug ให้ตรวจ compile path, library, top และการใช้ไฟล์เก่าก่อนเชื่อ testbench

## 13. การแก้ปัญหาที่พบบ่อย

| อาการ | สาเหตุที่ควรตรวจ | วิธีแก้ |
|---|---|---|
| ไม่รู้จัก always_ff | compile เป็น Verilog | ใช้ -sv หรือ -g2012 |
| ไม่รู้จัก std.env | ไม่ได้เปิด VHDL-2008 | compile/elaborate/run ให้ใช้มาตรฐานเดียวกัน |
| q เป็น X/U ตลอด | reset ไม่เกิดหรือ DUT ต่อผิด | ตรวจ rst_n, port mapping และ top |
| คลาดหนึ่ง count | checker sample ก่อน update หรือ model ไม่ตรง edge | รอหลัง posedge/delta และทบทวน stimulus timing |
| en=0 แต่ q เปลี่ยน | DUT enable ผิดหรือ stimulus ชน edge | ตรวจ polarity และเปลี่ยน stimulus ที่ falling edge |
| reset กลางคาบไม่ล้าง | เขียน synchronous reset | เทียบ RTL กับ specification |
| Wrap ไม่เกิด | รันสั้นหรือ model ไม่จำกัดช่วง | เปิด enable ให้ครบมากกว่า 2^N ขอบ |
| บอก PASS ทั้งที่แก้ผิด | compile ไม่สำเร็จแล้วโหลด library เก่า | หยุดเมื่อ compile fail และตรวจ path |
| GUI หยุดที่ assertion | simulator break ตาม severity | อ่าน failure; อย่ากด Continue เพื่อให้ดูเหมือนผ่าน |
| Sim ไม่จบ | ใช้ run จำกัดเวลา/ไม่มี finish | ใช้ run -all, termination และ watchdog |

## 14. เชื่อมโยงกับ ASIC implementation

RTL counter นี้สื่อถึง state N บิต พร้อม enable และ asynchronous reset รูปแบบ cell ที่ได้จริงอาจเป็น resettable flip-flop ร่วมกับ feedback mux หรือโครงสร้างอื่นตาม library และ synthesis การจำลองผ่านไม่ได้รับรองว่าจะมี cell ตรงกับ reset/enable ทุกแบบ

คาบ clock 10 ns ใน testbench เป็นเพียง stimulus ไม่ได้สร้าง SDC ให้ synthesis/STA โดยอัตโนมัติ Lab ถัดไปต้องกำหนด clock, I/O environment, reset treatment และตรวจ timing coverage ห้าม false-path ทุกอย่างเพื่อให้รายงาน timing ดูผ่าน

en ในการทดลองถือว่า synchronous กับ clk หากมาจากปุ่มกดหรืออีก clock domain ต้องเพิ่ม CDC treatment และอาจต้อง debounce ตามแหล่งสัญญาณ อย่านำ en ไป AND กับ clk โดยตรงเพื่อสร้าง clock ใหม่ การเริ่ม q เป็นศูนย์ใน testbench ด้วย reset ยังไม่รับรอง power-up state ของ silicon หากระบบจริงไม่มี reset ที่ถูกต้อง

## 15. งานส่งและเกณฑ์ประเมิน

ส่ง RTL สองภาษา, testbench สองภาษา, simulator/version, คำสั่งรันจริง, compile/simulation logs, waveform จุดสำคัญ และ log fault injection อย่างน้อยหนึ่งกรณี พร้อมระบุสิ่งที่แก้และจุดที่ checker จับได้

| เกณฑ์ | คะแนน |
|---|---:|
| Specification/RTL ตรงกันทั้งสองภาษา | 25 |
| Self-checking reset/enable/hold/wrap และ timeout | 35 |
| Compile/run ที่ทำซ้ำได้และหลักฐานผลจริง | 20 |
| Fault injection fail และ restore แล้ว pass | 15 |
| อธิบายข้อจำกัด simulation และ reset/CDC | 5 |

เงื่อนไขผ่านหลัก: ทั้งสองภาษาต้องผ่านทุก test และ TB ต้องตรวจพบ bug ที่ใส่จริง ข้อผิดพลาดด้าน reset/enable/wrap ถือว่ายังไม่ผ่านแม้คะแนนส่วนอื่นสูง

คำถามท้าย Lab: เหตุใดต้องมี sampling offset? ไม่มี else ใน sequential process ต่างจาก combinational process อย่างไร? ทำไม positive-edge reset release ใน testbench จึงเสี่ยง race? คาบ clock ใน TB ต่างจาก timing constraint อย่างไร? หากเปลี่ยน N=1 จะต้องเห็นลำดับอะไร? ถ้า en มาจากอีก domain ต้องแก้ส่วนใดก่อนใช้งานจริง?

## 16. ผลตรวจโค้ดในสภาพแวดล้อมที่จัดทำคู่มือ

SystemVerilog compile และจำลองด้วย Icarus Verilog สำเร็จ ได้ `PASS checks=117 wraps=4` การใส่ bug กลับ polarity ของ enable ทำให้ simulation จบด้วย failure ที่เวลา 46 ns (expected=0, actual=0010) จึงยืนยันได้ว่า checker จับกรณี hold ผิดได้

VHDL ยังไม่ได้ยืนยันด้วยการจำลองจริงในสภาพแวดล้อมนี้: executable ของ ModelSim ที่ติดตั้งเปิดไม่สำเร็จ โดย Windows รายงาน WinError 623 (Illegal System DLL Relocation) จึงต้องรันส่วน VHDL บนเครื่องฝึกอบรมที่เปิด simulator ได้ก่อนใช้เป็นชุด Lab ที่ผ่านการตรวจครบสองภาษา

