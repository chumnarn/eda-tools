# Module 2 — RTL ที่เหมาะกับ ASIC

## 2.1 เป้าหมายและแนวคิดของบทเรียน

RTL เป็นคำอธิบายวงจรที่ทำงานพร้อมกันหลายส่วน ไม่ใช่โปรแกรมที่ CPU ประมวลผลทีละบรรทัด นักออกแบบต้องเชื่อมโยงโค้ดกับ flip-flop, multiplexer, arithmetic logic, clock และ reset ที่จะเกิดขึ้นจริงได้ การจำลองผ่านยืนยันพฤติกรรมเฉพาะกรณีที่ทดสอบ แต่ไม่ได้ยืนยันว่าไม่มี latch, ไม่มี CDC error หรือปิด timing ได้หลังวางและเดินสาย

เมื่อจบบทเรียน ผู้เรียนต้องสามารถ:

1. แยก combinational process ออกจาก sequential process และทำนายฮาร์ดแวร์ที่อนุมานได้
2. อธิบาย blocking/nonblocking assignment และ VHDL signal/variable assignment
3. กำหนดความกว้างและ signedness ของนิพจน์โดยไม่อาศัยการแปลงชนิดโดยปริยาย
4. เลือก reset และ clock enable ตามความต้องการระบบและ standard-cell library
5. ตรวจ latch inference และสร้าง FSM ที่มีพฤติกรรมครบถ้วน
6. จำแนก synchronous, asynchronous, CDC และ reset domain crossing (RDC)
7. อธิบาย asynchronous assert/synchronous deassert และเหตุผลที่ยังต้องตรวจ recovery/removal หลัง implementation

ตัวอย่างใช้ SystemVerilog และ VHDL-2008 เป็นหลัก โดยแสดงแนวทาง Verilog-2001 เมื่อจำเป็น โค้ดตัวอย่างเป็นรูปแบบการสอน ไม่ได้อ้างว่าผ่าน compile หรือ sign-off กับเครื่องมือ/PDK เฉพาะรุ่นแล้ว การรองรับภาษาและ attribute ต้องตรวจจาก configuration ของโครงการ

## 2.2 คิดจากวงจรก่อนเขียน process

| ความต้องการ | วงจรที่คาดหวัง | รูปแบบ RTL |
|---|---|---|
| เอาต์พุตเป็นฟังก์ชันของอินพุตปัจจุบัน | Combinational logic | continuous assignment หรือ combinational process |
| เก็บค่าเมื่อขอบ clock มาถึง | Edge-triggered flip-flop | clocked process |
| เก็บค่าเมื่อ enable ไม่ทำงาน | Flip-flop และ feedback mux หรือเซลล์ที่รองรับ enable | clocked process พร้อม if enable |
| โปร่งใสตลอดช่วง enable | Level-sensitive latch | latch process โดยตั้งใจ |
| ปิดการสวิตช์ของ clock tree | Integrated clock-gating cell (ICG) | flow และเซลล์เฉพาะ ไม่ใช่ AND gate ทั่วไป |

ชื่อ process ไม่มีผลกำหนดวงจร สิ่งที่มีผลคือ event control, เงื่อนไข และความครบถ้วนของ assignment หนึ่ง register ควรมีเจ้าของคือ sequential process เดียว หลีกเลี่ยงการขับสัญญาณเดียวจากหลาย process

## 2.3 Combinational process: ต้องกำหนดทุกเอาต์พุตในทุกเส้นทาง

ตัวอย่าง multiplexer 8 บิต:

```systemverilog
module mux8 (
  input  logic [7:0] a, b,
  input  logic       sel,
  output logic [7:0] y
);
  always_comb begin
    y = a;
    if (sel) y = b;
  end
endmodule
```

```vhdl
library ieee;
use ieee.std_logic_1164.all;

entity mux8 is
  port (a, b : in  std_logic_vector(7 downto 0);
        sel  : in  std_logic;
        y    : out std_logic_vector(7 downto 0));
end entity;

architecture rtl of mux8 is
begin
  process(all)
  begin
    y <= a;
    if sel = '1' then
      y <= b;
    end if;
  end process;
end architecture;
```

กำหนด default ก่อนแล้ว override ตามเงื่อนไขช่วยให้โค้ดครบถ้วน สำหรับ Verilog-2001 ใช้ `always @*` และตัวแปรเอาต์พุตประเภท `reg`; คำว่า `reg` ไม่ได้แปลว่าต้องได้ flip-flop เสมอไป สำหรับ VHDL รุ่นก่อน 2008 ต้องใส่สัญญาณที่อ่านทุกตัวใน sensitivity list หากตกหล่น simulation อาจไม่อัปเดตตามอินพุต ทั้งที่ synthesis สร้าง combinational logic

`always_comb` มีการตรวจข้อจำกัดของตัวภาษาเพิ่มเติม แต่ไม่ได้รับประกันว่าโค้ดจะไม่มี latch เครื่องมืออาจแจ้ง error หรือ warning เมื่อพบ assignment ไม่ครบ

### ตัวอย่างที่ทำให้เกิด latch

```systemverilog
always_comb begin
  if (en) y = d; // ไม่มี assignment เมื่อ en=0
end
```

```vhdl
process(all)
begin
  if en = '1' then
    y <= d; -- ต้องเก็บค่าเดิมเมื่อ en='0'
  end if;
end process;
```

หากต้องการ combinational logic ให้กำหนดค่าใน branch ที่ขาด หากต้องการเก็บค่าเมื่อขอบ clock ให้เปลี่ยนเป็น clocked process การเติม `y = y` หรือ `y <= y` ไม่ได้แก้ปัญหา เพราะยังร้องขอการเก็บสถานะ

Latch อาจเป็นส่วนหนึ่งของ ASIC ที่ออกแบบโดยตั้งใจ เช่นภายใน ICG แต่ latch ที่เกิดโดยไม่ได้ตั้งใจทำให้เกิดเส้นทาง timing แบบโปร่งใสและเพิ่มความซับซ้อนของการวิเคราะห์ บทฝึกพื้นฐานกำหนดว่า latch count ต้องเป็นศูนย์ ยกเว้นรายการที่อนุมัติอย่างชัดเจน

## 2.4 Sequential process และ assignment semantics

### Pipeline สองขั้น

```systemverilog
always_ff @(posedge clk) begin
  q1 <= d;
  q2 <= q1;
end
```

```vhdl
process(clk)
begin
  if rising_edge(clk) then
    q1 <= d;
    q2 <= q1;
  end if;
end process;
```

เมื่อถึงขอบ clock ทั้งสองขั้นอ่านค่าเดิมก่อนการอัปเดต ดังนั้น `q2` รับค่าเก่าของ `q1` เป็น pipeline จริงสองขั้น สำหรับ Verilog-2001 ใช้ `always @(posedge clk)` และ nonblocking assignment เช่นเดียวกัน

| ภาษา/รูปแบบ | ความหมายใน process | แนวทางใช้ |
|---|---|---|
| SystemVerilog `=` | Blocking: statement ถัดไปเห็นค่าที่เพิ่ง assign | Combinational calculation |
| SystemVerilog `<=` | Nonblocking: ประเมิน RHS แล้วกำหนดอัปเดตภายหลังใน NBA region | Register update |
| VHDL signal `<=` | กำหนด transaction; ค่า signal ไม่เปลี่ยนทันทีในลำดับการทำงานของ process | Combinational output และ register |
| VHDL variable `:=` | ค่า variable เปลี่ยนทันทีภายใน process | คำนวณค่าชั่วคราว |

VHDL ใช้ signal assignment ใน combinational process ได้ จึงไม่ควรแปลกฎ `=`/`<=` ของ Verilog มาใช้ตรงตัวกับ VHDL

ตัวอย่างความผิดพลาด:

```systemverilog
always @(posedge clk) begin
  q1 = d;
  q2 = q1;
end
```

ใน process นี้ `q2` เห็นค่าใหม่ของ `q1` จึงไม่ใช่ pipeline ตามที่ตั้งใจ และหาก process อื่นอ่าน `q1` ที่ขอบเดียวกันอาจเกิด simulation race หลักปฏิบัติคือใช้ nonblocking กับ state/register และไม่ผสม blocking/nonblocking เพื่อขับ register เดียวกัน

VHDL variable ที่อ่านก่อนเขียนใน clocked process อาจเก็บค่าข้ามรอบและอนุมาน register ได้ จึงไม่ใช่ว่า variable ทุกตัวเป็นเพียงสายหรือ temporary combinational logic เสมอ

### คำนวณผลลัพธ์ชั่วคราวอย่างชัดเจน

```systemverilog
logic [8:0] sum_d;
always_comb sum_d = {1'b0, a} + {1'b0, b};
always_ff @(posedge clk) sum_q <= sum_d;
```

```vhdl
-- a,b : unsigned(7 downto 0); sum_q : unsigned(8 downto 0)
process(clk)
  variable tmp : unsigned(8 downto 0);
begin
  if rising_edge(clk) then
    tmp := resize(a, tmp'length) + resize(b, tmp'length);
    sum_q <= tmp;
  end if;
end process;
```

## 2.5 Bit width: กำหนดก่อนคำนวณ ไม่ใช่หลังข้อมูลหาย

ผลบวก unsigned N บิตสองจำนวนต้องใช้ N+1 บิตเพื่อเก็บ carry; ผลคูณเต็มความกว้างของ M และ N บิตต้องใช้ M+N บิต การบวกสะสม K ค่า unsigned N บิตสามารถใช้ N+ceil(log2 K) บิตเป็นขอบเขตที่เพียงพอ แต่ควรพิสูจน์จากค่าสูงสุดจริง

ตัวอย่าง `255 + 1 = 256` ต้องใช้ 9 บิต ถ้าตัดเหลือ 8 บิตจะเป็นศูนย์ นี่คือ wraparound ไม่ใช่ saturation

```systemverilog
logic [7:0] a, b;
logic [8:0] sum_full;
logic [7:0] sum_wrap, sum_sat;
assign sum_full = {1'b0, a} + {1'b0, b};
assign sum_wrap = sum_full[7:0];
assign sum_sat  = sum_full[8] ? 8'hff : sum_full[7:0];
```

```vhdl
-- library ieee; use ieee.numeric_std.all;
-- a,b,sum_wrap,sum_sat : unsigned(7 downto 0)
-- sum_full : unsigned(8 downto 0)
sum_full <= resize(a, 9) + resize(b, 9);
sum_wrap <= sum_full(7 downto 0);
sum_sat  <= (others => '1') when sum_full(8) = '1'
            else sum_full(7 downto 0);
```

SystemVerilog มีกฎ sizing ทั้งแบบ self-determined และ context-determined การขยายปลายทางอย่างเดียวทำให้ผู้อ่านตรวจสอบยาก โดยเฉพาะนิพจน์ซ้อน, concatenation และ cast จึงขยาย operand ให้ชัดก่อนคำนวณ ใช้ literal ที่ระบุขนาดใน datapath เช่น `8'd1` หรือกำหนดค่าคงที่ชนิดตรงกับข้อมูล

สำหรับพารามิเตอร์ counter ควรป้องกัน `$clog2(1)=0` ด้วย `localparam int W = (DEPTH <= 1) ? 1 : $clog2(DEPTH);` และตรวจขอบเขตเมื่อ DEPTH ไม่ใช่กำลังสอง การมี register W บิตไม่ได้ทำให้มัน wrap ที่ DEPTH-1 โดยอัตโนมัติ

## 2.6 Signedness: รูปบิตเดียวกันอาจมีคนละความหมาย

`8'hff` เป็น unsigned 255 แต่ signed 8 บิตแบบ two's complement คือ -1 การเปรียบเทียบ ขยายบิต และเลื่อนบิตต้องใช้ชนิดตามความหมายของข้อมูล

```systemverilog
logic signed [7:0] a_s, b_s;
logic signed [8:0] sum_s;
assign sum_s = $signed({a_s[7], a_s})
             + $signed({b_s[7], b_s});
// ทั้งสอง operand มีขนาด 9 และเป็น signed
```

```vhdl
-- a_s,b_s : signed(7 downto 0); sum_s : signed(8 downto 0)
sum_s <= resize(a_s, 9) + resize(b_s, 9);
```

ข้อควรตรวจ:

- `$signed(x)` เปลี่ยนการตีความ ไม่ได้เพิ่มความกว้างของ x ด้วยตัวเอง
- Concatenation และ part-select ใน SystemVerilog อาจทำให้ signedness เปลี่ยนจากที่คาด ต้อง cast และกำหนดขนาดก่อนใช้
- `>>>` ทำ arithmetic right shift เมื่อ operand ซ้ายเป็น signed; หาก unsigned ผลไม่ใช่ sign extension ตามที่ต้องการ
- VHDL `std_logic_vector` เป็นกลุ่มบิต ไม่ได้ระบุ arithmetic meaning ใช้ `numeric_std` พร้อม `unsigned` หรือ `signed` อย่างชัดเจน
- การแปลง unsigned เป็น signed ที่ขนาดเท่าเดิมไม่ได้รับประกันว่าค่าจำนวนบวกจะคงเดิม เช่น 8 บิต 200 ต้องขยายเป็น 9 บิตก่อนตีความ signed หากต้องการเก็บค่า +200

แบบฝึกหัด: ให้คาดการณ์ค่า -1 เทียบกับ +1 ในชนิด signed และ unsigned พร้อมอธิบายผลของการผสม operand คนละชนิด ห้ามตอบจาก waveform อย่างเดียว ต้องแสดงชนิดและขนาดของแต่ละนิพจน์

## 2.7 Reset: แยก polarity, assertion และ synchronization

Active-low/active-high บอกระดับที่ reset ทำงาน ส่วน synchronous/asynchronous บอกว่าการ reset ต้องรอขอบ clock หรือไม่ เป็นคนละแกนของการออกแบบ ชื่อ `rst_n` ควรหมายถึง active-low เท่านั้น ไม่ได้ยืนยันว่าเป็น asynchronous

### Synchronous active-low reset พร้อม clock enable

```systemverilog
always_ff @(posedge clk) begin
  if (!rst_n) q <= '0;
  else if (ce) q <= d;
end
```

```vhdl
process(clk)
begin
  if rising_edge(clk) then
    if rst_n = '0' then
      q <= (others => '0');
    elsif ce = '1' then
      q <= d;
    end if;
  end if;
end process;
```

Reset มี priority เหนือ enable ถ้าเขียน enable ครอบ reset อีกชั้นหนึ่ง reset อาจไม่ทำงานเมื่อ enable ปิด Synchronous reset ต้องมี clock เพื่อให้ register เปลี่ยนสถานะ และ reset input ต้องสัมพันธ์กับ clock หรือผ่านกระบวนการรับสัญญาณที่เหมาะสม

### Asynchronous active-low reset

```systemverilog
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) q <= '0;
  else if (ce) q <= d;
end
```

```vhdl
process(clk, rst_n)
begin
  if rst_n = '0' then
    q <= (others => '0');
  elsif rising_edge(clk) then
    if ce = '1' then
      q <= d;
    end if;
  end if;
end process;
```

| ประเด็น | Synchronous reset | Asynchronous reset |
|---|---|---|
| ยืนยัน reset เมื่อ clock หยุด | ไม่เปลี่ยน register จนมี edge | ทำได้เมื่อเซลล์/แหล่ง reset รองรับ |
| ข้อกำหนด timing หลัก | Setup/hold ของเส้นทาง reset ที่เกี่ยวข้อง | Recovery/removal ตอนปล่อย และ minimum pulse width |
| การ mapping | ขึ้นกับ library อาจเป็น D-path mux/logic | ต้องมีเซลล์ที่รองรับ async control ตามต้องการ |
| ความเสี่ยงสำคัญ | Clock ไม่เดินหรือ pulse ไม่ถูก sample | ปล่อยใกล้ edge, reset skew, glitch |

ASIC ไม่ควรอาศัยค่าเริ่มต้นของ register จาก declaration หรือ `initial` เพื่อแทน power-on reset เว้นแต่เทคโนโลยีและ flow รับรองโดยเฉพาะ ไม่จำเป็นต้อง reset ทุก datapath bit เสมอไป หาก valid/control รับประกันว่าไม่ใช้ค่าก่อน initialize แต่ต้องพิสูจน์พฤติกรรมรวมถึง X-propagation, test และข้อกำหนดระบบ

## 2.8 Asynchronous assert / synchronous deassert

เมื่อระบบต้อง reset ได้แม้ clock หยุด แต่ต้องปล่อย reset อย่างสัมพันธ์กับ clock ให้สร้าง reset synchronizer ต่อ destination clock domain

```systemverilog
module reset_sync (
  input  logic clk,
  input  logic arst_n,
  output logic rst_n
);
  logic [1:0] release_ff;
  always_ff @(posedge clk or negedge arst_n) begin
    if (!arst_n) release_ff <= 2'b00;
    else         release_ff <= {release_ff[0], 1'b1};
  end
  assign rst_n = release_ff[1];
endmodule
```

```vhdl
library ieee;
use ieee.std_logic_1164.all;
entity reset_sync is
  port (clk, arst_n : in std_logic; rst_n : out std_logic);
end entity;
architecture rtl of reset_sync is
  signal release_ff : std_logic_vector(1 downto 0);
begin
  process(clk, arst_n)
  begin
    if arst_n = '0' then
      release_ff <= "00";
    elsif rising_edge(clk) then
      release_ff <= release_ff(0) & '1';
    end if;
  end process;
  rst_n <= release_ff(1);
end architecture;
```

เมื่อ `arst_n=0` ทั้งสองขั้นถูก clear โดยไม่รอ clock เมื่อปล่อย `arst_n=1` ค่า 1 เคลื่อนผ่าน chain ตามขอบ clock โดยปกติ rst_n ปล่อยหลังขอบที่สอง ส่วน register ปลายทางซึ่งใช้ขอบเดียวกันจะเริ่มทำงานในขอบถัดไป เนื่องจากก่อนขอบปล่อยยังเห็น reset active ต้องรวม latency นี้ใน protocol เริ่มระบบ และเผื่อความไม่แน่นอนจาก metastability ตามเกณฑ์ความเชื่อถือได้

จำนวนสองขั้นเป็นจุดเริ่มต้น ไม่ใช่การรับประกัน MTBF สำหรับทุกความถี่/เทคโนโลยี ต้องใช้เซลล์และ synchronizer attributes/constraints ที่ flow รองรับ ป้องกัน retiming/duplication ที่ทำลายโครงสร้าง และวาง register chain ให้เหมาะสม

ข้อกำหนดสำคัญ:

1. แต่ละ clock domain มี reset synchronizer ของตนเอง ห้ามใช้ reset ที่ synchronize ด้วย clk_a แล้วถือว่าปลอดภัยต่อ clk_b
2. ถ้า clock ปลายทางยังไม่ทำงาน reset ต้องคง active จน clock กลับมาและผ่านลำดับปล่อยครบ
3. หลีกเลี่ยง combinational logic ที่อาจเกิด glitch หลัง reset synchronizer
4. ใช้ reset tree ที่ควบคุม fanout, transition และ skew; ขา async reset ยังมีข้อจำกัดทางกายภาพ
5. Domain ที่ปล่อย reset ต่างเวลาอาจต้องมี ready handshake เพื่อไม่รับข้อมูลก่อนอีกฝั่งพร้อม และต้องตรวจ RDC เพิ่มเติม
6. แหล่ง reset ต้องมี pulse width และคุณภาพสัญญาณตาม library; synchronizer ไม่ใช่วงจรกรอง glitch หรือ debounce ที่สมบูรณ์

### Recovery และ removal

Recovery คือเวลาขั้นต่ำที่ reset ต้อง inactive ก่อนขอบ clock ที่เกี่ยวข้อง คล้ายแนวคิด setup ส่วน removal คือระยะที่ต้องคง reset active หลังขอบ clock ก่อนปล่อย คล้ายแนวคิด hold ต้องตรวจตาม timing arc และ polarity ของเซลล์จริง

ตัวอย่างเพื่อความเข้าใจ: หาก clock มาถึง endpoint ที่ 10.0 ns, recovery=0.2 ns และ removal=0.1 ns การปล่อย reset ในช่วงใกล้ขอบตั้งแต่ 9.8 ถึง 10.1 ns อยู่ในบริเวณที่อาจละเมิด check นั้น ตัวเลขนี้สมมติ ไม่ใช่ค่าของ PDK และการคำนวณจริงต้องรวม clock/reset arrival, uncertainty, derating และ corner

แม้ reset synchronizer ปล่อยหลังขอบ clock ก็ยังต้องตรวจ removal ในรอบปัจจุบันและ recovery ก่อนรอบถัดไปที่ endpoint เพราะ clock skew และ reset-tree delay เปลี่ยนระยะห่างได้ หากตั้ง false path ครอบ reset ทั้งต้นไม้จน checks หาย จะสูญเสียหลักฐานส่วนนี้

ข้อยกเว้นของ raw asynchronous reset ที่ขา synchronizer ต้องกำหนดเฉพาะตำแหน่งตาม methodology และตรวจว่าไม่ได้ตัด timing ของ synchronized reset distribution ไม่ควรคัดลอก `set_false_path -from reset` ไปใช้โดยไม่ตรวจรายงาน endpoint และชนิด timing check

## 2.9 Clock enable และเหตุผลที่ห้าม AND clock โดยตรง

```systemverilog
// รูปแบบที่หลีกเลี่ยง
assign gclk = clk & en;
always @(posedge gclk) q <= d;
```

ถ้า clk กำลังเป็น 1 และ en เปลี่ยน 0→1 จะเกิดขอบขาขึ้นของ gclk กลางคาบ ถ้า en เปลี่ยน 1→0 จะตัด pulse ให้สั้น การจำลองที่ en เปลี่ยนเฉพาะเวลาสวยงามอาจซ่อนปัญหานี้ วงจรจริงยังมี delay และ glitch ของเส้นทาง enable

รูปแบบพื้นฐานที่แนะนำคือใช้ clock เดิมและ if enable ตามตัวอย่างในหัวข้อ 2.7 การไม่มี else ใน clocked process หมายถึง register ถือค่าเดิม ซึ่งเป็นพฤติกรรมที่ต้องการ ไม่ใช่ latch

CE ต้องผ่าน setup/hold เช่นเดียวกับ synchronous control อื่น หากมาจากขาภายนอกหรืออีก domain ต้องจัดการ CDC ก่อน Clock enable ไม่ได้ทำให้ asynchronous input ปลอดภัย และ CE ที่เปิดทุก 4 คาบไม่ได้ให้สิทธิ์ตั้ง multicycle 4 โดยอัตโนมัติ ต้องพิสูจน์เงื่อนไข launch/capture และ hold constraints ก่อน

ใน ASIC การเขียน CE อาจ mapping เป็น mux ที่ D input ซึ่งไม่หยุด clock tree และ internal clock pin power หากต้องประหยัด clock power ให้ใช้ flow ที่แปลงเป็น ICG อย่างถูกต้อง พร้อม test-enable, clock-gating checks และ CTS รองรับ ICG มักเก็บ enable ในช่วง clock ที่ไม่ active เพื่อให้ enable คงที่ตลอด pulse ที่ active แต่ห้ามแทนที่ด้วย latch ที่เขียนเองโดยไม่ผ่าน methodology ของโครงการ

## 2.10 FSM: แยก state register, next-state และ output

ตัวอย่าง handshake controller: IDLE รอ start, BUSY รอ complete, DONE ส่ง done หนึ่งคาบก่อนกลับ IDLE สัญญาณ start/complete ในตัวอย่างต้อง synchronous กับ clk; start ต้องเป็น pulse หรือมี protocol รับรองว่าไม่ค้างจน trigger งานใหม่

```systemverilog
typedef enum logic [1:0] {IDLE, BUSY, DONE} state_t;
state_t state_q, state_d;

always_comb begin
  state_d = state_q;
  busy = 1'b0;
  done = 1'b0;
  case (state_q)
    IDLE: if (start) state_d = BUSY;
    BUSY: begin
      busy = 1'b1;
      if (complete) state_d = DONE;
    end
    DONE: begin
      done = 1'b1;
      state_d = IDLE;
    end
    default: state_d = IDLE;
  endcase
end

always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) state_q <= IDLE;
  else        state_q <= state_d;
end
```

```vhdl
-- ประกาศใน architecture
type state_t is (IDLE, BUSY, DONE);
signal state_q, state_d : state_t;
-- ส่วน concurrent หลัง begin
process(all)
begin
  state_d <= state_q;
  busy <= '0';
  done <= '0';
  case state_q is
    when IDLE =>
      if start = '1' then state_d <= BUSY; end if;
    when BUSY =>
      busy <= '1';
      if complete = '1' then state_d <= DONE; end if;
    when DONE =>
      done <= '1';
      state_d <= IDLE;
  end case;
end process;

process(clk, rst_n)
begin
  if rst_n = '0' then
    state_q <= IDLE;
  elsif rising_edge(clk) then
    state_q <= state_d;
  end if;
end process;
```

ข้อพิจารณา ASIC:

- Moore output อ้างอิง state ส่วน Mealy output อ้างอิง state และ input ต้องพิจารณา combinational path และ glitch
- Moore output แบบ combinational decode ก็ยังอาจ glitch จาก state-bit skew หากใช้เป็น control ที่ห้าม glitch ให้ register เอาต์พุตหรือออกแบบ interface ให้รับเฉพาะ clock edge
- Binary encoding ใช้ state bits น้อยกว่า one-hot แต่ one-hot อาจลด decode depth ต้องเทียบ synthesis และ physical timing จริง
- `default` ใน RTL ไม่ใช่หลักฐานว่าฮาร์ดแวร์ฟื้นจาก illegal encoding ได้เสมอ synthesis อาจ recode/optimize; งาน safety ต้องมี safe-state methodology, netlist inspection และ fault verification
- VHDL enum simulation แสดงเฉพาะค่าที่ประกาศ จึงไม่ได้จำลอง illegal physical bit pattern โดยอัตโนมัติ
- หลีกเลี่ยง `casex` เพื่อซ่อน X และไม่ใช้ X เป็นค่าเริ่มต้นของ control ที่ต้องปลอดภัยโดยไม่มีเหตุผลและการตรวจ equivalence

## 2.11 แยก synchronous signal ออกจาก CDC

สัญญาณ synchronous ต่อ destination เมื่อความสัมพันธ์ launch/capture clock เป็นที่ทราบและมี timing constraints ครอบคลุม ไม่ใช่เพียงเพราะชื่อ clock คล้ายกัน หรือมีความถี่เท่ากัน สอง oscillator ที่ 100 MHz เท่ากันยังเป็น asynchronous ต่อกัน ส่วน clock ที่หารจากแหล่งเดียวกันอาจวิเคราะห์แบบ related clocks ได้เมื่อ phase/clock generation ถูกนิยามและ STA ครอบคลุม

| สัญญาณ/ต้นทาง → ปลายทาง | การจำแนก | วิธีจัดการ |
|---|---|---|
| q ของ register clk_a → d ของ register clk_a | Synchronous | Setup/hold ปกติ |
| ขา input จากอุปกรณ์ที่ส่งด้วย clock อ้างอิงที่ทราบ | Synchronous interface เมื่อ constrained ถูกต้อง | Input delay รวม board/interface timing |
| ปุ่มกด/interrupt ภายนอก → clk_a | Asynchronous | Synchronize แล้ว debounce/edge detect ตามความหมาย |
| ระดับ flag ที่ค้างนาน clk_a → clk_b ที่ไม่สัมพันธ์กัน | Single-bit CDC | Synchronizer chain พร้อมเงื่อนไขเสถียรภาพ |
| Pulse สั้น clk_a → clk_b ช้ากว่า | Event CDC | Handshake, pulse stretching ที่พิสูจน์ได้ หรือ toggle protocol |
| Data bus ที่เปลี่ยนพร้อมกัน → อีก domain | Multi-bit CDC | Handshake พร้อม stable-data window หรือ async FIFO |
| FIFO pointer → อีก domain | Structured CDC | Gray encoding และ constraints/skew ที่เหมาะสม |
| External reset → async reset pins | Reset crossing | Per-domain reset synchronization และ RDC analysis |
| Related generated clock → parent clock | ตรวจความสัมพันธ์ก่อน | Generated-clock constraints และ STA หรือ CDC methodology ตามสถาปัตยกรรม |
| enable ภายนอก → register CE | Asynchronous control | CDC treatment ก่อนนำไปใช้ |

### Single-bit level synchronizer

```systemverilog
logic meta_q, sync_q;
always_ff @(posedge clk_dst or negedge rst_dst_n) begin
  if (!rst_dst_n) begin
    meta_q <= 1'b0;
    sync_q <= 1'b0;
  end else begin
    meta_q <= async_level;
    sync_q <= meta_q;
  end
end
```

```vhdl
process(clk_dst, rst_dst_n)
begin
  if rst_dst_n = '0' then
    meta_q <= '0';
    sync_q <= '0';
  elsif rising_edge(clk_dst) then
    meta_q <= async_level;
    sync_q <= meta_q;
  end if;
end process;
```

ให้ logic ปลายทางใช้เฉพาะ sync_q ไม่ใช้ meta_q และไม่ใส่ combinational logic ระหว่างขั้น Register แรกอาจ metastable; ขั้นต่อมาช่วยลดโอกาสที่ metastability แพร่ไปถึง logic แต่ไม่ได้ทำให้ความเสี่ยงเป็นศูนย์ ต้องรักษา resolution time ด้วยการวางและ timing ของ chain

Synchronizer แบบนี้ไม่รับประกันการจับ pulse สั้น หาก pulse เกิดและหายระหว่าง destination edges จะสูญหายได้ ทั้งยังไม่ใช่วงจร debounce และไม่รักษาความสอดคล้องของ bus หลายบิต

### ทำไม synchronize bus ทีละบิตไม่พอ

ถ้า bus เปลี่ยนจาก 0111 เป็น 1000 แต่แต่ละบิตถูก sample คนละรอบ ปลายทางอาจเห็นค่าผสมที่ไม่เคยถูกส่ง เช่น 0000 หรือ 1111 วิธีที่เหมาะสมคือ:

- Handshake: ต้นทางเก็บ bus คงที่ ส่ง req ข้าม domain ปลายทาง capture เมื่อข้อมูลมีเวลา settle เพียงพอและส่ง ack กลับ ต้นทางจึงเปลี่ยนข้อมูล ต้องออกแบบและ constrain data settling window จริง
- Async FIFO: ใช้สำหรับ stream ต่อเนื่อง มี pointer synchronization, full/empty logic และ reset protocol ที่ตรวจแล้ว
- Gray-coded counter: ใช้กับตัวแปรที่เหมาะกับการเปลี่ยนทีละบิต ไม่ใช่การแปลง arbitrary data bus แล้วถือว่าปลอดภัย ต้องควบคุม skew/max delay เพื่อรักษาคุณสมบัติที่ปลายทาง

Toggle event อาจทำ event หายได้หากต้นทาง toggle ซ้ำก่อนปลายทางสังเกต จึงต้องมีข้อจำกัดอัตรา event หรือ acknowledgement Reset ที่เริ่ม toggle คนละสถานะอาจสร้าง event ปลอม ต้องทดสอบ startup และ independent reset ด้วย

CDC verification ต้องดู structure, protocol และ constraints ร่วมกัน RTL simulation ทั่วไปไม่จำลอง analog metastability และการใส่ false path ไม่ได้สร้าง synchronizer ให้ฮาร์ดแวร์

## 2.12 กรณีศึกษา: counter รับปุ่มจากภายนอก

ข้อกำหนด: counter 8 บิตเพิ่มค่าหนึ่งครั้งต่อการกดปุ่ม ใช้ clk เดียว มี external active-low reset

ลำดับวงจรที่เหมาะสมคือ external reset → reset synchronizer ของ clk; ปุ่ม → level synchronizer → debounce ด้วย clk และ CE → edge detector → increment enable ของ counter

ห้ามนำปุ่มไปเป็น clock ห้ามนำ debounce pulse ไปสร้าง clock ใหม่ และห้ามถือว่าต่อปุ่มเข้าขา CE แล้วปลอดภัย การ synchronize จัดการความเสี่ยง metastability ส่วน debounce จัดการ contact bounce เป็นคนละปัญหา

```systemverilog
// btn_clean ต้องเป็นผลลัพธ์ synchronous หลัง synchronize และ debounce
logic btn_prev;
logic [7:0] count;
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    btn_prev <= 1'b0;
    count    <= 8'd0;
  end else begin
    btn_prev <= btn_clean;
    if (btn_clean && !btn_prev) count <= count + 8'd1;
  end
end
```

```vhdl
-- count : unsigned(7 downto 0); btn_prev : std_logic
process(clk, rst_n)
begin
  if rst_n = '0' then
    btn_prev <= '0';
    count <= (others => '0');
  elsif rising_edge(clk) then
    btn_prev <= btn_clean;
    if btn_clean = '1' and btn_prev = '0' then
      count <= count + to_unsigned(1, count'length);
    end if;
  end if;
end process;
```

หากปุ่มถูกกดค้างตั้งแต่ก่อน reset release โค้ดนี้อาจนับหนึ่งครั้งเมื่อ btn_clean กลายเป็น 1 ต้องกำหนด specification ว่าพฤติกรรมนี้ถูกต้องหรือให้รอปล่อยปุ่มก่อนจึง arm ระบบ

## 2.13 แผนภาคปฏิบัติและหลักฐานที่ต้องส่ง

### Lab 2.1 — ทำนายวงจรจาก process

สร้าง mux, DFF, DFF+CE และ latch ที่ผิดโดยตั้งใจทั้งสองภาษา วาดวงจรที่คาดก่อน synthesis แล้วเทียบจำนวน register/latch/mux จากรายงาน แก้ latch ด้วย assignment ครบ และยืนยันว่าไม่ได้แก้ด้วยการใส่ self-assignment

### Lab 2.2 — Assignment และ pipeline

ป้อนข้อมูล 11, 22, 33 ต่อเนื่องเข้าสู่ pipeline สองขั้น เปรียบเทียบ nonblocking กับ blocking ใน SystemVerilog และ signal กับ temporary variable ใน VHDL Testbench ต้อง sample หลัง register update ตาม scheduling ของ simulator เช่นรอขอบตรงข้ามสำหรับการตรวจพื้นฐาน หลีกเลี่ยงอ่านเอาต์พุตใน active region ของขอบเดียวกันโดยไม่ควบคุม race

### Lab 2.3 — Width และ signed arithmetic

ทดสอบ unsigned 255+1, 128+128, signed -128+(-1), -1+1 และการเปรียบเทียบค่าติดลบ แสดง full precision, wraparound และ saturation ตามข้อกำหนดแยกกัน ตรวจทั้งค่าและความกว้างที่แต่ละขั้น

### Lab 2.4 — Reset และ CE

ยืนยัน reset ระหว่าง clock หยุด ปล่อย reset หลายตำแหน่งในคาบ ทดสอบ ce=0 ระหว่าง reset และหลัง reset เปรียบเทียบ synchronous reset กับ async-assert/sync-deassert ตรวจว่าปล่อย reset หลังจำนวน edge ที่ตั้งไว้ และไม่มี update เมื่อ CE ปิด

การ sweep เวลา reset release ใน RTL simulation ช่วยตรวจลำดับเหตุการณ์ แต่ไม่พิสูจน์ recovery/removal หรือ MTBF ต้องมี STA/netlist timing checks และการตรวจ reset methodology เพิ่มเติม

### Lab 2.5 — FSM และ CDC classification

ทำ FSM ข้างต้นให้ start มาจากอีก clock domain เลือก protocol ที่รักษา event ได้ อธิบายเหตุผลที่ two-flop level synchronizer อาจไม่พอ ส่งตารางทุก interface ระบุ source clock, destination clock, reset domain, signal type, treatment, latency และหลักฐานการตรวจ

### เกณฑ์รับงาน

| หมวด | หลักฐานที่ต้องเห็น |
|---|---|
| Functional | Self-checking simulation ครอบคลุม reset, CE, boundary arithmetic และ FSM transitions |
| RTL quality | ไม่มี unintended latch, multiple driver, implicit truncation หรือ signedness warning ที่ยังไม่ตัดสินใจ |
| Clock | ไม่มี combinational clock gating ที่ไม่ได้อนุมัติ; ใช้ CE หรือ ICG flow ตามข้อกำหนด |
| Reset | ระบุ polarity/type/priority; มี per-domain release และ startup protocol |
| CDC/RDC | Interface ทุกตัวจำแนกครบ; waiver มีเหตุผลและขอบเขต ไม่ใช่เพียงตัด timing |
| Synthesis | Register/latch/FSM mapping สอดคล้องกับสถาปัตยกรรม; warning ถูกอธิบาย |
| Timing | Synchronous data/CE/reset paths ถูก constrain; recovery/removal และ pulse width ไม่ถูกซ่อนโดย exception |

## 2.14 คำถามทบทวนพร้อมแนวคำตอบ

1. **ทำไม if ไม่มี else บางกรณีเกิด latch แต่บางกรณีไม่เกิด?** ใน combinational process ต้องรักษาเอาต์พุตเมื่อไม่ assign จึงอนุมาน storage; ใน edge-triggered process มี flip-flop อยู่แล้ว และการไม่ assign คือ hold
2. **rst_n เป็น asynchronous เสมอหรือไม่?** ไม่ใช่ `_n` บอก polarity ต้องอ่าน event control และโครงสร้าง process
3. **Clock สองตัวความถี่เท่ากันถือว่า synchronous หรือไม่?** ไม่เสมอ ต้องรู้ phase relationship และมี constraints/STA ที่รับรอง
4. **ใส่ two-flop ให้ bus ทุกบิตแล้วจบหรือไม่?** ไม่จบ เพราะแต่ละบิตอาจข้ามรอบต่างกัน ต้องรักษา coherency ด้วย protocol
5. **ใช้ CE แล้วหยุด clock power ทั้งหมดหรือไม่?** ไม่เสมอ CE อาจเป็น D-input mux และ clock tree ยังสวิตช์
6. **Async-assert/sync-deassert ทำให้ไม่ต้องตรวจ reset timing หรือไม่?** ยังต้องตรวจ endpoint timing, tree skew, pulse width และเงื่อนไขการทำงานของ synchronizer
7. **ทำไม raw external reset ไม่ควรใช้เป็นตัวปล่อยทุก domain โดยตรง?** การปล่อยสัมพันธ์กับแต่ละ clock ต่างกัน อาจละเมิด recovery/removal และทำให้ register เริ่มคนละรอบ
8. **Simulation ไม่มี X แปลว่าไม่มี metastability หรือไม่?** ไม่ใช่ digital RTL simulation ทั่วไปไม่ได้จำลองปรากฏการณ์ analog นี้
9. **FSM มี default แล้วฟื้นจาก SEU ได้แน่นอนหรือไม่?** ต้องยืนยันหลัง mapping และตาม safety methodology เพราะ encoding และ logic อาจถูก optimize
10. **ตัด false path ข้าม clock แล้วถือว่า CDC ผ่านหรือไม่?** ไม่ใช่ exception บอก STA ว่าไม่วิเคราะห์เส้นทางบางแบบ แต่ไม่ได้รักษาข้อมูลหรือ protocol

## 2.15 Checklist ก่อนส่ง RTL เข้าสู่ ASIC flow

- ทุก process มีหน้าที่ชัดเจนและ register มีเจ้าของเดียว
- Combinational assignments ครบทุก branch; latch ที่ตั้งใจใช้มีรายการอนุมัติ
- Sequential state ใช้ assignment semantics ถูกต้อง; testbench ไม่อ่านแข่งกับ DUT
- ความกว้าง ชนิด signed/unsigned การขยายและการตัดบิตมีเหตุผลตาม specification
- Reset polarity/type/priority ชัดเจน; ไม่อาศัย simulator initialization แทน hardware startup
- Clock enable เป็น synchronous ต่อ clock ที่ใช้; ไม่สร้าง gated clock ด้วย combinational logic ทั่วไป
- Reset synchronizer แยกต่อ domain; ตรวจ RDC และการเริ่มทำงานระหว่าง domain
- FSM outputs/illegal state/encoding ถูกพิจารณาตามข้อกำหนดจริง
- Single-bit, pulse และ bus CDC ใช้วิธีต่างกันตามความหมายและอัตราข้อมูล
- Constraints ไม่ซ่อน synchronous timing, synchronizer stage-to-stage timing หรือ reset distribution checks ที่จำเป็น

## เอกสารอ่านประกอบ

เอกสารด้านล่างบางฉบับอธิบายในบริบท FPGA ใช้อ้างอิงหลัก reset/CDC/clock enable เท่านั้น การเลือกเซลล์ ICG, reset tree, Liberty timing arcs และ sign-off ของ ASIC ต้องใช้เอกสาร library/เครื่องมือของโครงการ

1. Intel, *AN 545: Design Guidelines and Timing Closure Techniques for HardCopy ASICs*, หัวข้อ metastability-safe reset: https://cdrdv2-public.intel.com/654507/an545.pdf
2. Intel, *Timing Analysis Basic Concepts*, recovery/removal และ metastability: https://www.intel.com/content/www/us/en/docs/programmable/683243/24-1/timing-analysis-basic-concepts.html
3. AMD, *UG949 — Using Gated Clocks*: https://docs.amd.com/r/en-US/ug949-vivado-design-methodology/Using-Gated-Clocks
4. AMD, *UG949 — Clock Domain Crossing*: https://docs.amd.com/r/en-US/ug949-vivado-design-methodology/Clock-Domain-Crossing
5. AMD, *UG949 — Multi-Bit CDC*: https://docs.amd.com/r/en-US/ug949-vivado-design-methodology/Multi-Bit-CDC
