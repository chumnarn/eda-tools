# คู่มือการใช้งาน QuestaSim สำหรับการจำลองและตรวจสอบวงจร VHDL

**(QuestaSim VHDL Simulation & Verification Tutorial)**

คู่มือฉบับนี้อธิบายกระบวนการพัฒนาและจำลองการทำงานของวงจรดิจิทัลด้วยภาษา **VHDL (VHDL-93 / VHDL-2008)** บนเครื่องมือ **Siemens QuestaSim** ตั้งแต่การจัดการไลบรารี การคอมไพล์ การปรับแต่งโครงสร้าง (Elaboration & Optimization) การตรวจสอบสัญญาณ Waveform ไปจนถึงการวัดค่า Code Coverage และการรันแบบอัตโนมัติ

---

### 1. สถาปัตยกรรมและขั้นตอนการทำงาน (QuestaSim VHDL 3-Step Flow)

QuestaSim ประมวลผลโค้ด VHDL ผ่านกระบวนการหลัก 3 ขั้นตอน:

```
[VHDL Source (*.vhd)]
         │
         ▼
  1. Compilation      (vcom)  ──> วิเคราะห์ไวยากรณ์ (Syntax) และเก็บลงในไลบรารี 'work'
         │
         ▼
  2. Optimization     (vopt)  ──> เชื่อมโยงโมดูล (Binding), ยุบรวม Hierarchy, และเพิ่มความเร็วจำลอง
         │
         ▼
  3. Simulation       (vsim)  ──> โหลดเอนจินจำลอง, ป้อน Stimulus, บันทึก Waveform และ Coverage

```

---

### 2. ตารางสรุปพารามิเตอร์สำคัญของคำสั่ง `vcom`

| แฟล็กคำสั่ง | คำอธิบายและการใช้งาน |
| --- | --- |
| `-93` | คอมไพล์ตามมาตรฐาน **VHDL-1993** (ค่ามาตรฐานที่โรงงานผลิตชิปและ Synthesis Tool ส่วนใหญ่รองรับ) |
| `-2008` | เปิดใช้งานมาตรฐาน **VHDL-2008** (รองรับ Context Blocks, Expressions in Port Maps, Logic Ops บน Vectors) |
| `-work <lib>` | ระบุไดเรกทอรีไลบรารีปลายทาง (เช่น `-work work`) |
| `-check_synthesis` | ตรวจสอบว่ามีคำสั่งหรือโครงสร้างที่ไม่สามารถนำไปสังเคราะห์เป็นฮาร์ดแวร์ได้หรือไม่ |
| `+cover=bcestf` | สั่งแทรกจุดดักจับ Code Coverage สำหรับ VHDL (Branch, Condition, Expression, Statement, Toggle, FSM) |
| `-explicit` | แก้ปัญหาฟังก์ชัน Overloading ที่คลุมเครือในแพ็กเกจ `ieee.std_logic_arith` |

---

### 3. ตัวอย่างโปรเจกต์ภาคปฏิบัติ (Hands-on VHDL Project)

ตัวอย่างนี้ใช้ระบบ **Synchronous FIFO Buffer ขนาด Parameterized** พร้อมพอยน์เตอร์ควบคุมและสัญญาณแฟล็ก

#### โค้ดวงจร (DUT): `rtl/sync_fifo.vhd`

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sync_fifo is
    generic (
        DATA_WIDTH : integer := 8;
        FIFO_DEPTH : integer := 16
    );
    port (
        clk     : in  std_logic;
        rst_n   : in  std_logic;
        wr_en   : in  std_logic;
        rd_en   : in  std_logic;
        wr_data : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        rd_data : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        full    : out std_logic;
        empty   : out std_logic
    );
end entity sync_fifo;

architecture rtl of sync_fifo is
    type ram_type is array (0 to FIFO_DEPTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal fifo_ram : ram_type := (others => (others => '0'));

    signal wr_ptr   : integer range 0 to FIFO_DEPTH - 1 := 0;
    signal rd_ptr   : integer range 0 to FIFO_DEPTH - 1 := 0;
    signal count    : integer range 0 to FIFO_DEPTH     := 0;
begin

    -- สัญญาณแฟล็กแสดงสถานะ FIFO
    full  <= '1' when (count = FIFO_DEPTH) else '0';
    empty <= '1' when (count = 0)          else '0';

    -- กระบวนการบันทึกและอ่านข้อมูลแบบ Synchronous
    fifo_proc : process(clk, rst_n)
    begin
        if rst_n = '0' then
            wr_ptr  <= 0;
            rd_ptr  <= 0;
            count   <= 0;
            rd_data <= (others => '0');
        elsif rising_edge(clk) then
            -- การเขียนข้อมูลเข้า (Write Operation)
            if (wr_en = '1' and count < FIFO_DEPTH) then
                fifo_ram(wr_ptr) <= wr_data;
                if wr_ptr = FIFO_DEPTH - 1 then
                    wr_ptr <= 0;
                else
                    wr_ptr <= wr_ptr + 1;
                end if;
            end if;

            -- การอ่านข้อมูลออก (Read Operation)
            if (rd_en = '1' and count > 0) then
                rd_data <= fifo_ram(rd_ptr);
                if rd_ptr = FIFO_DEPTH - 1 then
                    rd_ptr <= 0;
                else
                    rd_ptr <= rd_ptr + 1;
                end if;
            end if;

            -- การคำนวณจำนวนข้อมูลที่ตกค้างใน FIFO (Count Tracking)
            if (wr_en = '1' and rd_en = '0' and count < FIFO_DEPTH) then
                count <= count + 1;
            elsif (wr_en = '0' and rd_en = '1' and count > 0) then
                count <= count - 1;
            end if;
        end if;
    end process fifo_proc;

end architecture rtl;

```

#### โค้ด Self-Checking Testbench: `tb/tb_sync_fifo.vhd`

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_sync_fifo is
end entity tb_sync_fifo;

architecture sim of tb_sync_fifo is
    constant DATA_WIDTH : integer := 8;
    constant FIFO_DEPTH : integer := 16;
    constant CLK_PERIOD : time    := 10 ns;

    signal clk     : std_logic := '0';
    signal rst_n   : std_logic := '0';
    signal wr_en   : std_logic := '0';
    signal rd_en   : std_logic := '0';
    signal wr_data : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal rd_data : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal full    : std_logic;
    signal empty   : std_logic;

    -- Procedure สำหรับการเขียนข้อมูล 1 Byte
    procedure write_byte(
        constant data_in : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        signal   s_clk   : in  std_logic;
        signal   s_wren  : out std_logic;
        signal   s_wdata : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    ) is
    begin
        wait until rising_edge(s_clk);
        s_wren  <= '1';
        s_wdata <= data_in;
        wait until rising_edge(s_clk);
        s_wren  <= '0';
        s_wdata <= (others => '0');
    end procedure;
begin

    -- ติดตั้ง DUT
    dut : entity work.sync_fifo(rtl)
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            FIFO_DEPTH => FIFO_DEPTH
        )
        port map (
            clk     => clk,
            rst_n   => rst_n,
            wr_en   => wr_en,
            rd_en   => rd_en,
            wr_data => wr_data,
            rd_data => rd_data,
            full    => full,
            empty   => empty
        );

    -- กำเนิดสัญญาณ Clock (100 MHz)
    clk_gen : process
    begin
        clk <= '0'; wait for CLK_PERIOD / 2;
        clk <= '1'; wait for CLK_PERIOD / 2;
    end process;

    -- Stimulus และการตรวจสอบความถูกต้อง
    stim_proc : process
    begin
        -- 1. ทำการ Reset ระบบ
        rst_n <= '0';
        wait for 35 ns;
        rst_n <= '1';
        wait until rising_edge(clk);

        -- ตรวจสอบสถานะเริ่มต้นหลัง Reset
        assert (empty = '1' and full = '0')
            report "ERROR: FIFO should be empty after reset!"
            severity error;

        -- 2. เขียนข้อมูล 2 ค่าเข้าไปใน FIFO
        write_byte(x"A5", clk, wr_en, wr_data);
        write_byte(x"5A", clk, wr_en, wr_data);

        -- 3. อ่านข้อมูลแรกออกและตรวจสอบผล
        wait until rising_edge(clk);
        rd_en <= '1';
        wait until rising_edge(clk);
        rd_en <= '0';
        wait for 1 ns; -- เลื่อนจุดแซมเปิลหลังขอบคล็อก

        assert (rd_data = x"A5")
            report "ERROR: Data mismatch! Expected 0xA5, got 0x" & to_hstring(rd_data)
            severity failure;

        -- 4. อ่านข้อมูลชุดที่สองออกและตรวจสอบผล
        wait until rising_edge(clk);
        rd_en <= '1';
        wait until rising_edge(clk);
        rd_en <= '0';
        wait for 1 ns;

        assert (rd_data = x"5A")
            report "ERROR: Data mismatch! Expected 0x5A, got 0x" & to_hstring(rd_data)
            severity failure;

        report ">>> SUCCESS: All VHDL FIFO Tests Passed! <<<" severity note;
        wait;
    end process stim_proc;

end architecture sim;

```

---

### 4. การรันสคริปต์อัตโนมัติ (TCL Automation Script)

สร้างไฟล์สคริปต์ชื่อ `sim_vhdl.do` เพื่อควบคุมทุกขั้นตอนของ QuestaSim:

```tcl
# 1. ล้างและสร้าง Library ใหม่
if [file exists work] {
    vdel -lib work -all
}
vlib work
vmap work work

# 2. คอมไพล์ไฟล์ VHDL (ใช้มาตรฐาน VHDL-2008)
vcom -2008 -work work rtl/sync_fifo.vhd
vcom -2008 -work work tb/tb_sync_fifo.vhd

# 3. รวมและปรับแต่งสถาปัตยกรรม (เปิด +acc เพื่อให้เห็นสัญญาณภายใน DUT ทั้งหมด)
vopt work.tb_sync_fifo +acc -o top_opt

# 4. เรียกใช้เอนจินจำลองการทำงาน
vsim -t 1ps work.top_opt

# 5. จัดระเบียบสัญญาณในหน้าต่าง Waveform
add wave -divider "System Controls"
add wave -format logic /tb_sync_fifo/clk
add wave -format logic /tb_sync_fifo/rst_n

add wave -divider "FIFO Flags"
add wave -format logic /tb_sync_fifo/full
add wave -format logic /tb_sync_fifo/empty
add wave -format literal -radix unsigned /tb_sync_fifo/dut/count

add wave -divider "Write Interface"
add wave -format logic /tb_sync_fifo/wr_en
add wave -format literal -radix hex /tb_sync_fifo/wr_data
add wave -format literal -radix unsigned /tb_sync_fifo/dut/wr_ptr

add wave -divider "Read Interface"
add wave -format logic /tb_sync_fifo/rd_en
add wave -format literal -radix hex /tb_sync_fifo/rd_data
add wave -format literal -radix unsigned /tb_sync_fifo/dut/rd_ptr

# 6. ตั้งค่าการแสดงผลและรันการจำลอง
configure wave -namecolwidth 180
configure wave -valuecolwidth 80
configure wave -signalnamestyle 1

run -all
wave zoom full

```

คำสั่งรันจาก Terminal:

```bash
vsim -do sim_vhdl.do

```

---

### 5. เทคนิคการดีบัก VHDL บน Waveform GUI

1. **การแสดงค่า Enumeration ของ FSM:**
* สัญญาณประเภท `type state_type is (IDLE, READ, WRITE, DONE);` จะแสดงชื่อตัวอักษรของสถานะบน Waveform โดยอัตโนมัติ หากต้องการสลับดูค่ารหัสฐานสอง ให้คลิกขวาที่สัญญาณแล้วเลือก **Radix $\rightarrow$ Binary**


2. **การกางดูข้อมูลใน VHDL Record หรือ Array:**
* ตัวแปร Array เช่น `fifo_ram` สามารถกางเครื่องหมาย `+` หน้าชื่อสัญญาณเพื่อดูข้อมูลแยกรายตำแหน่ง (Index `(0)` ถึง `(15)`)


3. **การอ่านสถานะสัญญาณ 9 ค่าของ IEEE `std_logic`:**
* `'U'` (Uninitialized): เส้นสีแดงหนา สัญญาณยังไม่ถูกกำหนดค่าเริ่มต้นหรือไม่มี Reset
* `'X'` (Unknown / Conflict): เส้นสีแดง มีไดรเวอร์สองตัวขับสัญญาณสวนทางกัน (เช่น '0' และ '1' ชนกัน)
* `'Z'` (High Impedance): เส้นสีเหลืองตรงกลาง บัสลอยหรือ Tristate Buffer ปิดการทำงาน


4. **การบันทึกมุมมอง Waveform (`.do` format):**
* เมื่อจัดกลุ่มสัญญาณ ปรับสี และตั้งค่า Radix เรียบร้อย ให้ไปที่ **File $\rightarrow$ Save Format...** เพื่อบันทึกเป็นไฟล์ `wave.do` สำหรับนำกลับมาโหลดซ้ำด้วยคำสั่ง `do wave.do`



---

### 6. การตรวจวัด Code Coverage ใน VHDL

การเปิดฟังก์ชันเก็บค่าความครอบคลุมเพื่อวัดประสิทธิภาพของ Testbench:

```tcl
# 1. คอมไพล์พร้อมเปิดแฟล็ก Coverage
vcom -2008 -cover bcst -work work rtl/sync_fifo.vhd
vcom -2008 -work work tb/tb_sync_fifo.vhd

# 2. ทำ Optimization พร้อมคงค่าตาราง Coverage
vopt work.tb_sync_fifo +cover=bcst +acc -o top_cov_opt

# 3. รันการจำลองและบันทึกผล
vsim -coverage work.top_cov_opt
run -all

# 4. บันทึกฐานข้อมูล Coverage (.ucdb) และสร้างรายงาน HTML
coverage save vhdl_fifo_cov.ucdb
vcover report -html -output vhdl_coverage_html vhdl_fifo_cov.ucdb
vcover report -summary vhdl_fifo_cov.ucdb

```

---

### 7. ข้อผิดพลาดที่พบบ่อยใน VHDL บน QuestaSim และวิธีแก้ไข

* **สัญญาณแสดงสถานะ `'U'` ค้างยาวตลอดการจำลอง:**
* *สาเหตุ:* ลืมกำหนดค่าเริ่มต้นให้กับสัญญาณใน Testbench หรือไม่ได้สั่ง Pulse สัญญาณ Reset เข้าสู่วงจร
* *วิธีแก้:* ตรวจสอบลำดับการปลด Reset ในกระบวนการ `stim_proc`


* **ข้อผิดพลาด `Array index out of range`:**
* *สาเหตุ:* พอยน์เตอร์ชนิด Integer หรือ Unsigned เข้าถึงตำแหน่งเกินขอบเขตของ Array ในแรม
* *วิธีแก้:* จำกัดขอบเขตของตัวแปรด้วยคำสั่ง `range 0 to FIFO_DEPTH - 1` หรือตรวจสอบเงื่อนไขก่อนเพิ่มค่า


* **ความคลาดเคลื่อนจาก Delta Delay ใน Testbench:**
* *สาเหตุ:* ดักอ่านค่าสัญญาณเอาต์พุตที่เวลาเดียวกันกับขอบสัญญาณนาฬิกา (`rising_edge(clk)`) ทำให้ได้ค่าเก่าก่อนการประเมินผล
* *วิธีแก้:* ใส่คำสั่งเลื่อนเวลาเล็กน้อย เช่น `wait for 1 ns;` หลังขอบสัญญาณนาฬิกา ก่อนทำการ `assert` ตรวจสอบผล