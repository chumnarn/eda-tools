# Module 3 — Functional verification

หลักสูตร Tanner Digital ASIC Design Implementation — ระดับเริ่มต้นถึงระดับกลาง

## 3.1 เป้าหมายและขอบเขต

Functional verification คือการตรวจว่าพฤติกรรมของวงจรตรงกับ specification ภายใต้ลำดับเหตุการณ์ที่กำหนด ทั้งข้อมูลปกติ ขอบเขตข้อมูล และการเปลี่ยนสถานะควบคุม เป้าหมายไม่ใช่เพียงทำให้ simulation จบ แต่ต้องมีหลักฐานว่า input ใดถูกทดสอบ output ใดถูกตรวจ และข้อกำหนดใดยังไม่ได้ตรวจ

เมื่อจบบท ผู้เรียนต้องสามารถแปลงข้อกำหนดเป็น directed tests สร้าง reference model และ scoreboard เขียน assertions จัดการ reset/enable และ timeout และแสดงหลักฐานว่า testbench ตรวจจับ bug ที่ใส่โดยตั้งใจได้

RTL simulation ไม่พิสูจน์ setup/hold, recovery/removal, metastability, clock-tree quality หรือ power connectivity เรื่องเหล่านี้ต้องใช้ STA, CDC/RDC analysis และ physical verification ประกอบ ส่วนการจำลองระดับ RTL เหมาะกับการหาความผิดพลาดของอัลกอริทึม ลำดับเหตุการณ์ และ interface contract

## 3.2 เหตุใด waveform อย่างเดียวจึงไม่เพียงพอ

Waveform ช่วยอธิบายสาเหตุของ failure แต่การดูด้วยตาเพียงบางช่วงอาจพลาดเหตุการณ์ที่เกิดหลังหลายร้อยรอบ เช่น wraparound, reset ระหว่างทำงาน หรือ enable หยุดตรงค่าขอบเขต การทดสอบที่ดีจึงให้เครื่องตรวจทุกจุดที่มีความหมาย และใช้ waveform เพื่อตามหาสาเหตุเมื่อผลไม่ตรง

ผลลัพธ์ต้องแบ่งชัดเจนเป็น PASS, FAIL และ INCOMPLETE เช่น simulator ถูกหยุดด้วยเวลาสูงสุดโดยยังไม่ถึงข้อความ PASS ต้องถือว่างานยังไม่สำเร็จ ห้ามนับว่าไม่มี error จึงผ่าน

## 3.3 เริ่มจาก specification ที่ตรวจได้

ใช้ synchronous up-counter ขนาด 4 บิตเป็นกรณีศึกษา เพื่อให้มองเห็นปัญหาด้าน scheduling และขอบเขตได้ครบก่อนขยายไปยัง FIFO หรือ SoC

| รายการ | ข้อกำหนด |
|---|---|
| Clock | ขอบขาขึ้น, คาบจำลอง 10 ns |
| Reset | `rst_n` active-low แบบ synchronous |
| ลำดับความสำคัญ | reset สูงกว่า enable |
| Enable | `en=1` เพิ่มหนึ่ง, `en=0` คงค่า |
| Overflow | 15 → 0 ตาม modulo 16 |
| Output | สถานะปัจจุบันของ register หลัง clock edge |
| ก่อน reset แรก | ไม่รับประกันค่าเริ่มต้น |
| Input contract | `rst_n` และ `en` ต้องเป็น 0 หรือ 1 และเสถียรรอบขอบ clock |

นิยาม mathematical model โดยให้ q[k] เป็นค่าหลังขอบ clock ครั้งที่ k:

\[
q[k+1]=\begin{cases}0 & rst_n[k+1]=0\\(q[k]+1)\bmod16 & rst_n[k+1]=1\land en[k+1]=1\\q[k] & \text{otherwise}\end{cases}
\]

สัญลักษณ์ input ในสมการหมายถึงค่าที่ถูก sample ณ ขอบนั้น ต้องนิยามให้แน่นอน เพราะความคลุมเครือว่าเป็นค่าก่อนหรือหลังขอบ clock ทำให้ scoreboard ผิดหนึ่งรอบได้

## 3.4 Testbench architecture

| ส่วน | หน้าที่ | ข้อควรระวัง |
|---|---|---|
| Stimulus / driver | สร้าง input ตาม scenario | หลีกเลี่ยงเปลี่ยน input ตรงขอบที่ DUT sample |
| DUT | RTL ที่ต้องการตรวจ | compile source และ top ให้ถูกชุด |
| Monitor | เก็บสิ่งที่เกิดจริง | เก็บตาม interface acceptance ไม่ใช่ความตั้งใจของ driver |
| Reference model | คำนวณคำตอบจากข้อกำหนด | หลีกเลี่ยงคัดลอกโครงสร้าง RTL ทั้งก้อน |
| Scoreboard | จับคู่ expected กับ actual | ต้องมี accounting และตรวจรายการค้างตอนจบ |
| Assertions | ตรวจ invariant หรือ temporal rule | ต้องมี trigger เกิดจริงและเปิดใช้งานใน simulator |
| Coverage / summary | บอกสิ่งที่เกิดแล้ว | coverage ไม่ใช่หลักฐานความถูกต้องโดยลำพัง |

ตัวอย่างเล็กสามารถรวมหลายส่วนไว้ใน process เดียวได้ แต่ต้องอธิบายบทบาทให้ชัด เมื่อเป็น bus หรือ pipeline ควรแยก driver กับ monitor เพื่อไม่ให้ scoreboard ตรวจเพียง input ที่ driver ตั้งใจส่ง แม้ DUT ไม่เคยรับจริง

## 3.5 Directed test plan และ boundary conditions

| ID | Scenario | สิ่งที่ต้องตรวจ |
|---|---|---|
| T01 | reset โดย en=0 | ขอบ clock ทำให้ q=0 |
| T02 | reset โดย en=1 | reset ชนะ enable |
| T03 | ปลด reset แต่ en=0 | q คงที่ที่ศูนย์ |
| T04 | en=1 หนึ่งรอบ | q เพิ่มหนึ่งครั้ง |
| T05 | en=0 หลายรอบที่ q≠0 | register คงค่า |
| T06 | นับผ่าน 14, 15, 0, 1 | ตรวจ wraparound |
| T07 | หยุดนับเมื่อ q=15 | ไม่ wrap จนกว่า en=1 |
| T08 | reset ระหว่างนับที่ q≠0 | ล้างค่าทันทีที่ขอบถัดไป |
| T09 | enable สลับ 0/1 | เพิ่มเฉพาะรอบที่ enable |
| T10 | clock หยุด / test ไม่จบ | watchdog ทำให้ FAIL |

Boundary ไม่ได้หมายถึงเพียงเลขสูงสุด แต่รวมถึง first transaction หลัง reset, last transaction ก่อน reset, ระยะห่างระหว่างคำขอ และลำดับ control พร้อมกัน สำหรับ FIFO ให้เพิ่ม empty/full, simultaneous push/pop และ overflow/underflow ตาม contract สำหรับ ALU ให้เพิ่ม zero, all-ones, signed minimum/maximum, carry และ shift เท่ากับหรือมากกว่าความกว้างตามนิยาม ISA

## 3.6 ตัวอย่าง DUT — SystemVerilog

บันทึกเป็น `counter.sv` การใช้ SystemVerilog ในส่วน DUT ยังคงเป็น RTL แบบง่ายที่นำไปสังเคราะห์ได้ ส่วน testbench เป็น simulation-only

```systemverilog
module counter(input logic clk, rst_n, en,
               output logic [3:0] q);
  always_ff @(posedge clk) begin
    if (!rst_n) q <= 4'd0;
    else if (en) q <= q + 4'd1;
  end
endmodule
```

Verilog-2001 สามารถใช้ `always @(posedge clk)` และประกาศ q เป็น `reg [3:0]` แทนได้ พฤติกรรม sequential ยังคงใช้ nonblocking assignment

## 3.7 Self-checking testbench — SystemVerilog

บันทึกเป็น `tb_counter.sv` ใช้ reference model แบบ integer และ modulo แทนการคัดลอกนิพจน์ vector ของ DUT โดยตรง การใช้ `!==` ทำให้ output ที่มี X/Z ถูกนับเป็น mismatch ด้วย

```systemverilog
`timescale 1ns/1ps
module tb_counter;
  logic clk=0, rst_n=0, en=0;
  wire [3:0] q;
  integer expected=0, checks=0;
  counter dut(.clk(clk), .rst_n(rst_n), .en(en), .q(q));
  always #5 clk = ~clk;

  task automatic step(input bit reset_value, input bit enable_value);
    @(negedge clk);
    rst_n = reset_value;
    en = enable_value;
    @(posedge clk);
    if (!reset_value) expected = 0;
    else if (enable_value) expected = (expected + 1) % 16;
    #1; // RTL-only sampling: allow nonblocking updates to settle
    checks = checks + 1;
    if (q !== expected[3:0])
      $fatal(1,"MISMATCH check=%0d rst_n=%b en=%b exp=%0d got=%b",
                checks,rst_n,en,expected,q);
  endtask

  initial begin
    step(0,0);
    step(0,1);
    step(1,0);
    step(1,1);
    repeat(3) step(1,0);
    repeat(14) step(1,1); // q becomes 15
    repeat(2) step(1,0);  // hold at maximum
    step(1,1);           // 15 -> 0
    step(1,1);           // 0 -> 1
    step(0,1);           // reset while active
    repeat(8) begin
      step(1,1);
      step(1,0);
    end
    if (checks != 42) $fatal(1,"INCOMPLETE checks=%0d",checks);
    $display("PASS checks=%0d",checks);
    $finish;
  end

  initial begin
    #2000;
    $fatal(1,"TIMEOUT: test did not complete");
  end
endmodule
```

ในตัวอย่างนี้ checker ตรวจ 42 ขอบที่กำหนดไว้ ขอบแรกก่อน task เริ่มทำงานมี reset asserted อยู่แล้ว และไม่ถูกนับเป็น check เวลา `#1` เป็นวิธีสอนสำหรับ RTL zero-delay โดยมีคาบ 10 ns ห้ามนำไปใช้กับ timed GLS โดยไม่ทบทวน delay และ sampling protocol ในงานขนาดใหญ่ควรใช้ clocking block หรือ monitor sampling convention ที่กำหนดเป็นมาตรฐานโครงการ

คำสั่งอ้างอิงด้วย Icarus Verilog:

```sh
iverilog -g2012 -s tb_counter -o sim_counter counter.sv tb_counter.sv
vvp sim_counter
```

ต้องตรวจทั้ง exit status และข้อความ `PASS checks=42` หาก compile ไม่สำเร็จต้องไม่รัน executable เก่าต่อ การเขียน regression runner ควรแยก build directory ต่อ test หรือหยุดทันทีเมื่อ compile ล้มเหลว

## 3.8 ตัวอย่าง DUT — VHDL

บันทึกเป็น `counter.vhd` ใช้ `numeric_std` เพื่อระบุการคำนวณ unsigned อย่างชัดเจน

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
  port (clk, rst_n, en : in std_logic;
        q : out std_logic_vector(3 downto 0));
end entity;

architecture rtl of counter is
  signal count : unsigned(3 downto 0);
begin
  q <= std_logic_vector(count);
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        count <= (others => '0');
      elsif en = '1' then
        count <= count + 1;
      end if;
    end if;
  end process;
end architecture;
```

## 3.9 Self-checking testbench — VHDL-2008

บันทึกเป็น `tb_counter.vhd` ใช้ assertion severity failure เพื่อหยุดเมื่อ mismatch และใช้ `std.env.finish` เมื่อผ่าน ต้องมี watchdog อิสระจาก process ทดสอบ เพื่อให้ยังจับการค้างได้เมื่อ process หลักรอ clock ที่ไม่มา

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_counter is end entity;

architecture sim of tb_counter is
  signal clk : std_logic := '0';
  signal rst_n : std_logic := '0';
  signal en : std_logic := '0';
  signal q : std_logic_vector(3 downto 0);
begin
  clk <= not clk after 5 ns;
  dut : entity work.counter(rtl)
    port map(clk => clk, rst_n => rst_n, en => en, q => q);

  stimulus : process
    variable expected : natural range 0 to 15 := 0;
    variable checks : natural := 0;
    procedure step(constant r, e : in std_logic) is
    begin
      wait until falling_edge(clk);
      rst_n <= r;
      en <= e;
      wait until rising_edge(clk);
      if r = '0' then
        expected := 0;
      elsif e = '1' then
        expected := (expected + 1) mod 16;
      end if;
      wait for 1 ns;
      checks := checks + 1;
      assert q = std_logic_vector(to_unsigned(expected, 4))
        report "MISMATCH check=" & integer'image(checks) &
               " expected=" & integer'image(expected) &
               " actual_hex=" & to_hstring(q)
        severity failure;
    end procedure;
  begin
    step('0','0');
    step('0','1');
    step('1','0');
    step('1','1');
    for i in 1 to 3 loop step('1','0'); end loop;
    for i in 1 to 14 loop step('1','1'); end loop;
    for i in 1 to 2 loop step('1','0'); end loop;
    step('1','1');
    step('1','1');
    step('0','1');
    for i in 1 to 8 loop
      step('1','1');
      step('1','0');
    end loop;
    assert checks = 42 report "INCOMPLETE" severity failure;
    report "PASS checks=" & integer'image(checks) severity note;
    finish;
    wait;
  end process;

  watchdog : process
  begin
    wait for 2 us;
    assert false report "TIMEOUT: test did not complete" severity failure;
    wait;
  end process;
end architecture;
```

คำสั่งอ้างอิงสำหรับ GHDL:

```sh
ghdl -a --std=08 counter.vhd tb_counter.vhd
ghdl -e --std=08 tb_counter
ghdl -r --std=08 tb_counter --assert-level=error
```

GHDL อนุญาตกำหนด severity ที่ทำให้หยุด simulation ด้วย `--assert-level` การใช้ `--assert-level=none` จึงไม่เหมาะกับ regression ที่อาศัย assertion เป็นตัวตัดสิน fail ส่วน `--stop-time` เป็นเพียงขีดจำกัดเวลาจำลอง ต้องไม่ใช้แทน watchdog ที่รายงานความล้มเหลว

## 3.10 Scheduling: สาเหตุที่ checker อาจอ่านค่าผิดรอบ

SystemVerilog nonblocking assignment อัปเดต register หลังการประเมิน procedural code บางส่วนของ time slot นั้น ส่วน VHDL signal assignment อัปเดตผ่าน simulation cycle/delta cycle การอ่าน output ทันทีหลัง `posedge` หรือ `rising_edge` จึงอาจยังเห็นค่าเก่า

หลักปฏิบัติในบทนี้คือ drive ที่ falling edge, DUT sample ที่ rising edge และ checker อ่านหลัง update เสร็จ การหน่วงใน testbench ไม่ใช่ delay ที่สังเคราะห์ลงชิป และไม่ใช่การแก้ timing violation หาก checker fail ต้องตรวจ scheduling ก่อนแก้ RTL

ใน VHDL ตัวอย่างนี้ count เปลี่ยนก่อน concurrent assignment ไปยัง q จะส่งผลครบ การรอเพียง `wait for 0 ns` หนึ่งครั้งอาจยังไม่ครอบคลุมทุก delta ที่ต้องการ การใช้เวลา 1 ns ภายใต้สมมติฐาน RTL ที่กำหนดช่วยให้ตัวอย่างอ่านง่ายและมีจุด sample ชัดเจน

## 3.11 Assertions: ตรวจเงื่อนไขเฉพาะจุดและข้ามเวลา

Immediate assertion เหมาะกับเงื่อนไขที่ต้องตรวจ ณ จุดประมวลผลหนึ่ง เช่น counter มีค่าอยู่ในช่วง หรือ input control ไม่มี X/Z ส่วน concurrent assertion เหมาะกับความสัมพันธ์ข้าม clock เช่น disable แล้วรอบถัดไปต้องคงค่า

ตัวอย่าง SVA ต่อไปนี้เป็น checker เสริมสำหรับ DUT เดิม ใช้กับ simulator ที่รองรับ SVA รูปแบบนี้ ไม่รวมในชุด Icarus ขั้นพื้นฐานข้างต้น

```systemverilog
ap_reset: assert property (@(posedge clk)
  (!rst_n) |=> (q == 4'd0));

ap_hold: assert property (@(posedge clk) disable iff (!rst_n)
  (!en) |=> $stable(q));

ap_increment: assert property (@(posedge clk) disable iff (!rst_n)
  (en) |=> (q == (($past(q) + 4'd1) & 4'hf)));

cp_enabled: cover property (@(posedge clk)
  rst_n && en);
```

Concurrent assertions sample q ก่อน NBA update ณ ขอบนั้น จึงใช้ non-overlapped implication `|=>` เพื่อตรวจผลจากการทำงานที่ขอบก่อนหน้าใน sampled value ของขอบถัดไป สำหรับ reset แบบ synchronous ของตัวอย่างนี้ reset property ไม่ใช้ `disable iff (!rst_n)` เพราะจะปิดการตรวจเงื่อนไข reset ที่ต้องการพิสูจน์เอง ส่วน disable iff มีความหมายในการ abort assertion attempt และไม่ใช่โมเดลของ synchronous reset โดยอัตโนมัติ

การใช้ disable iff กับ hold/increment ทำให้บาง attempt ถูกยกเลิกเมื่อ reset asserted จึงต้องมี directed reset tests แยกต่างหาก Assertions เหล่านี้ไม่ได้แทน scoreboard หรือการตรวจ reset priority ทั้งหมด และควรทำ negative test เพื่อยืนยันว่า assertion ถูก compile และเปิดใช้จริง

VHDL ใช้ sequential assert ภายใน monitor ได้โดยบันทึกค่าก่อน edge คำนวณ expected และตรวจหลัง settling ตามตัวอย่างข้างต้น หากใช้ PSL ให้ตรวจการรองรับและตัวเลือกเปิดใช้ของ simulator ก่อน

### Vacuous pass

Property รูป `request |=> response` อาจไม่เคย fail เพราะ request ไม่เคยเป็นจริง จึงต้องมี coverage ของ antecedent หรือ counter ว่า trigger เกิดกี่ครั้ง แม้ assertions ทุกข้อผ่าน ก็ยังต้องถามว่ามีโอกาสตรวจเงื่อนไขเหล่านั้นจริงหรือไม่

## 3.12 Reset และ enable: สิ่งที่ต้องทดสอบแยก

สำหรับ synchronous reset ให้ตรวจว่า reset ที่ครอบคลุมขอบ clock ล้าง state จริง พัลส์ reset ที่ไม่ครอบคลุมขอบอาจไม่ส่งผลตามนิยามและไม่ใช่ bug โดยตัวมันเอง ให้ทดสอบทั้ง reset ตอนเริ่มต้นและระหว่างทำงาน โดยเฉพาะเมื่อ enable=1

สำหรับ asynchronous reset ให้เพิ่มการ assert ระหว่างขอบ clock และตรวจหลัง propagation ของ RTL รวมถึง reset pulse ตามข้อกำหนด การปลด reset จริงในชิปต้องอาศัย reset architecture เช่น asynchronous assert/synchronous deassert ตาม clock domain และตรวจ recovery/removal ด้วยเครื่องมือที่เหมาะสม RTL simulation ไม่สามารถแสดง metastability ทางกายภาพได้อย่างครบถ้วน

สำหรับ enable ต้องตรวจ hold ที่ค่าศูนย์ ค่ากลาง และค่าสูงสุด และตรวจ disable → enable → disable เพราะการตรวจ hold เฉพาะ q=0 อาจพลาด bug ที่ล้างค่าแทนการคงค่า

อย่า force ค่าเริ่มต้นของ DUT เพื่อทำให้ test ผ่าน หาก specification กำหนดว่าต้องผ่าน reset ก่อนใช้งาน ต้องสร้าง reset sequence จริงและเริ่ม validity ของ checker หลัง reset อย่างชัดเจน

## 3.13 Reference model และ scoreboard สำหรับวงจรที่ซับซ้อนขึ้น

Reference model ควรเรียบง่ายกว่า implementation เช่น multiplier ใช้ integer arithmetic ภายในช่วงที่ไม่ overflow, CRC ใช้อัลกอริทึม bit-serial อิสระจาก parallel RTL และ FIFO ใช้ queue ใน testbench ต้องนิยาม bit width, signedness, truncation และ saturation ให้ตรง specification เสมอ

สำหรับ ready/valid interface transaction ถูกยอมรับเมื่อ `valid && ready` ณ clock edge ที่กำหนดเท่านั้น การสร้าง expected result ทุกครั้งที่ valid=1 จะนับซ้ำเมื่อ backpressure ค้างหลายรอบ

Scoreboard สำหรับ in-order pipeline ควรทำงานดังนี้:

1. Monitor ตรวจ input acceptance แล้วเพิ่ม expected item ลง queue พร้อม transaction index
2. Monitor ตรวจ output acceptance แล้วนำ expected item ที่ตรงลำดับมาเปรียบเทียบ
3. หาก output มาแต่ queue ว่าง ให้ fail ว่า unexpected output
4. หากข้อมูลผิด ให้รายงาน expected/actual, index และเวลา
5. ตอนจบ ต้องไม่มี expected ค้าง และจำนวน accepted/output ตรงตาม reset/flush contract

หาก input และ output เกิดขอบเดียวกัน ต้องกำหนด semantics ว่า zero-latency ถูกอนุญาตหรือไม่ และจัดการ queue/monitor ให้ไม่เกิด race หากเป็น out-of-order ต้องจับคู่ด้วย ID แทน pop ตามลำดับ

Reset ระหว่างมีรายการค้างต้องนิยามว่าจะยกเลิกรายการทั้งหมด คงรายการ หรือ drain ก่อน reset อย่าล้าง scoreboard โดยไม่มีข้อกำหนด เพราะอาจซ่อนการทำข้อมูลหายที่เป็น bug จริง

## 3.14 Timeout สองระดับ

Global timeout จำกัดเวลารวมของ test และต้องทำงานได้แม้ clock หยุด Local transaction timeout จำกัด latency ต่อคำขอ เช่น response ต้องกลับภายใน L clock cycles เมื่อไม่มีข้อยกเว้นจาก backpressure

ค่า timeout ต้องมาจาก contract ไม่ใช่เพิ่มไปเรื่อย ๆ จน test ผ่าน สำหรับ protocol ที่ยอมให้รอได้ไม่จำกัด ต้องกำหนด environment assumption หรือ progress rule ของ test ให้ชัด เช่น ready จะกลับมาเป็น 1 ภายในจำนวนรอบที่กำหนด

เมื่อ timeout ให้รายงาน cycle ล่าสุด รายการค้าง จำนวน request/response และ control state ที่เกี่ยวข้อง Test ที่ล้มเหลวเพราะ mismatch กับ test ที่ค้างต้องแยกสาเหตุได้

## 3.15 พิสูจน์ testbench ด้วย intentional bug

การทดสอบ testbench เป็นส่วนหนึ่งของ lab ไม่ใช่งานเสริม ผู้เรียนต้องแสดงลำดับ baseline PASS → mutant FAIL ที่ถูกสาเหตุ → restore PASS โดยเปลี่ยนเฉพาะ DUT และคง stimulus/reference model เดิม

Mutation หลัก: เปลี่ยนการเพิ่มค่าจาก +1 เป็น +2

```systemverilog
else if (en) q <= q + 4'd2; // intentional bug
```

```vhdl
count <= count + 2; -- intentional bug
```

Expected failure ของ test ทั้งสองภาษาคือ check 4 ซึ่งเป็น enabled cycle แรกหลัง reset: expected=1 แต่ actual=2 หาก mutant ยัง PASS ให้ตรวจว่า compile source ถูกไฟล์หรือไม่ รัน executable เก่าหรือไม่ checker ถูกเรียกจริงหรือไม่ และเกิด enabled cycle จริงหรือไม่

ห้ามแก้ expected ให้เป็น +2 ตาม bug เพื่อทำให้ test ผ่าน เพราะจะทำลายความเป็นอิสระของ oracle หลังเก็บ failure log แล้วต้องคืน DUT เป็น +1 และรัน baseline ใหม่

Mutation เพิ่มเติมสำหรับฝึกวิเคราะห์ detection gap:

| Mutation | Test ที่ควรตรวจพบ |
|---|---|
| เอาเงื่อนไข en ออก | T03/T05/T07 |
| ให้ enable ชนะ reset | T02 หรือ T08 เมื่อ state ไม่ใช่ศูนย์ |
| q=15 แล้ว saturate | T06 |
| en=0 แล้วล้าง q | T05 ที่ q≠0 |
| ทำ clock generator ไม่วิ่ง | Global watchdog |

การตรวจพบ mutant หนึ่งตัวพิสูจน์ได้เพียงว่า test มีความไวต่อ bug นั้น ไม่ได้พิสูจน์ว่าครอบคลุมทุก bug ต้องเลือก mutation ตาม requirement และเก็บผลการตรวจจับอย่างมีเหตุผล

## 3.16 จาก directed ไปสู่ random และ regression

เริ่มจาก directed tests ที่อธิบายเหตุผลได้ก่อน แล้วเพิ่ม pseudo-random enable/reset ที่มี seed คงที่เพื่อทำซ้ำได้ Random test ต้องใช้ scoreboard เดิม และต้องรายงาน seed พร้อมจำนวนรอบ ห้ามใช้ random จำนวนมากแทน boundary tests ที่ตั้งใจสร้าง

Functional coverage ควรผูกกับ test plan เช่น reset-while-enabled, hold-at-maximum, wraparound และ enable-toggle ส่วน code coverage เช่น line/branch/toggle บอกว่ามีส่วนใดของ RTL ถูกกระตุ้น แต่ branch ถูกกระตุ้นไม่ได้หมายความว่า output ถูกตรวจ

Regression record ควรมี test name, source revision, simulator/version, compile options, seed, checks, PASS/FAIL, first failure และ runtime กำหนดให้ compile error, assertion error, timeout, missing PASS marker และ queue ค้าง ทำให้ job ไม่ผ่านทั้งหมด

## 3.17 การใช้กับ Siemens EDA workflow

แนวคิด driver/model/scoreboard ใช้ได้กับ simulator ที่โครงการมีสิทธิ์ใช้งาน เช่น Questa โดยเลือก language mode และ top-level testbench ให้ถูกต้อง ตัวอย่าง Tcl สำหรับ installation ที่มีคำสั่งเหล่านี้:

```tcl
vlib work
vlog -sv counter.sv tb_counter.sv
vsim work.tb_counter
run -all
```

สำหรับ VHDL ให้ใช้ work library ใหม่หรือแยก run directory เพื่อไม่ให้ชนกับ module/entity ชื่อเดียวกัน:

```tcl
vlib work
vcom -2008 counter.vhd tb_counter.vhd
vsim work.tb_counter
run -all
```

คำสั่งนี้เป็นตัวอย่าง interactive flow ไม่ใช่ batch exit policy ที่สมบูรณ์ การทำ CI ต้องกำหนดให้ assertion/fatal/timeout ส่งผลเป็น nonzero exit status ตามรุ่นและการตั้งค่าของ simulator จริง และตรวจ mutation เพื่อยืนยัน policy ห้ามสมมติว่า log มีคำว่า error แล้วระบบ CI จะ fail เอง

Functional verification เป็น gate ก่อน synthesis ของ Tanner/Siemens implementation flow เก็บ RTL snapshot และ simulation log ที่ตรงกับ snapshot ที่ส่ง synthesis หากแก้ RTL ภายหลังต้อง rerun tests ที่เกี่ยวข้อง

## 3.18 ขั้นตอนปฏิบัติและสิ่งส่งมอบ

1. เขียน specification ของ counter รวม reset priority และ overflow ก่อนเปิด simulator
2. สร้าง DUT และ TB ทั้งสองภาษาใน directory แยกกัน
3. Compile และรัน baseline เก็บ log ที่มี PASS checks=42
4. ตรวจ waveform เฉพาะช่วง reset, hold และ wrap เพื่อเชื่อมความเข้าใจกับ checker
5. ใส่ +2 mutation ใน DUT รันใหม่โดยไม่แก้ TB เก็บ mismatch ที่ check 4 และ exit status
6. คืน DUT เป็น +1 แล้วรันใหม่ให้ PASS
7. เพิ่ม directed case ของตนเองหนึ่งกรณี พร้อมอธิบาย requirement ที่เพิ่มการตรวจ
8. ทดลองทำ clock หยุดเพื่อยืนยัน watchdog แล้วคืน clock generator
9. ส่ง source, test plan, baseline/mutant/restored logs และสรุป coverage gap

หากเพิ่มจำนวน step ต้องปรับ expected total checks โดยอธิบายจำนวนที่เพิ่ม มิฉะนั้น assertion INCOMPLETE จะ fail แม้ DUT ทำงานถูก การมี count guard ช่วยตรวจ test ที่จบก่อนรัน scenario ครบ

## 3.19 เกณฑ์ผ่าน

| หัวข้อ | หลักฐานขั้นต่ำ |
|---|---|
| ข้อกำหนด | ระบุ reset, enable, width, overflow และ sampling edge |
| Self-checking | ทุก step เปรียบเทียบผล ไม่อาศัยการดู waveform |
| Boundary | มี hold ที่ q≠0 และ q=15 พร้อม 15→0 |
| Reset | ตรวจ reset พร้อม enable และ reset ระหว่างทำงาน |
| Timeout | พิสูจน์ watchdog โดยทำให้ test ค้าง |
| TB validation | baseline PASS, +2 mutant FAIL, restored PASS |
| Reproducibility | ระบุ source, tool/version, คำสั่ง และ log |
| ขอบเขตความเชื่อมั่น | บอกได้ว่า functional PASS ยังไม่ใช่ timing/CDC sign-off |

## 3.20 คำถามอภิปราย

1. เหตุใดการตรวจ hold เฉพาะ q=0 จึงตรวจไม่พบ bug ที่ล้าง q ทุกครั้งเมื่อ en=0?
2. ทำไม checker ที่อ่าน q ทันทีที่ขอบ clock จึงอาจผิดหนึ่งรอบ?
3. หาก request ไม่เคยเกิด assertion request→response ที่ไม่ fail บอกอะไรได้บ้าง?
4. Simulator หยุดเมื่อถึง stop-time แต่ไม่มี PASS ควรให้ผลใด?
5. เมื่อ reset ทำให้ pipeline ยกเลิกรายการค้าง scoreboard ต้องเปลี่ยนอย่างไรตาม contract?
6. เหตุใดการพบ bug จาก mutation หนึ่งตัวจึงยังไม่แสดงว่า verification ครบถ้วน?

## เอกสารอ้างอิง

- GHDL, Simulation runtime options: https://ghdl.github.io/ghdl/using/Simulation.html — assertion severity และเวลาหยุดจำลอง
- GHDL, Simulation quick start: https://ghdl.github.io/ghdl/quick_start/simulation/index.html — analysis/elaboration/run
- Verilator, Input Languages: https://verilator.org/guide/latest/languages.html — ขอบเขต language/timing support
- Verilator, Executable arguments: https://verilator.org/guide/latest/exe_verilator.html — ตรวจตัวเลือกเปิด assertion และ timing ตามรุ่นที่ติดตั้ง

หมายเหตุการตรวจสอบเอกสาร: ได้ตรวจลำดับ directed tests และจำนวน 42 checks จากโค้ด แต่ยังไม่ยืนยันผลจำลองจริงในสภาพแวดล้อมนี้ เพราะ Icarus Verilog ที่ติดตั้งยุติระหว่าง compile ด้วย Windows exit code 3221225477 (access violation) และไม่มี GHDL พร้อมใช้งาน ข้อความ PASS/FAIL และ check 4 ที่อธิบายในบทจึงเป็นผลที่คาดหวัง ผู้เรียนต้องรันยืนยันกับ simulator ของห้องปฏิบัติการ รวมถึงตรวจการรองรับ SVA, VHDL-2008 และ exit policy ตามรุ่นจริง
