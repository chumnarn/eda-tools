# คู่มือการใช้งาน ModelSim สำหรับการจำลองและตรวจสอบวงจร VHDL

**(ModelSim VHDL Simulation & Verification Tutorial)**

คู่มือฉบับนี้สรุปขั้นตอนการทำงานบน **Siemens / Mentor Graphics ModelSim** สำหรับการออกแบบและทดสอบวงจรดิจิทัลด้วยภาษา VHDL ครอบคลุมทั้งการทำงานผ่านหน้าต่างกราฟิก (GUI) และการสั่งการผ่านสคริปต์อัตโนมัติ (Macro `.do`)

---

### 1. ภาพรวมกระบวนการทำงาน (ModelSim 2-Step Flow)

ต่างจาก QuestaSim ที่เน้น 3-Step Flow ตัว ModelSim มาตรฐานใช้กระบวนการจำลองแบบ **2-Step Flow** (Compile $\rightarrow$ Simulate) ซึ่งกระชับและเหมาะกับการทดสอบวงจรระดับ RTL ทั่วไป:

```
[VHDL Source Files (*.vhd)]
             │
             ▼
      1. Compile (vcom)       ──> วิเคราะห์ไวยากรณ์ จัดเก็บลงไลบรารี 'work'
             │
             ▼
      2. Simulate (vsim)      ──> โหลด Design เข้าสู่หน่วยความจำ พร้อมตั้งค่า -voptargs="+acc"
             │
             ▼
  [Waveform Debug & Transcript]

```

---

### 2. ตารางเปรียบเทียบคำสั่งหลักบน ModelSim CLI

| คำสั่ง | รูปแบบและพารามิเตอร์ | การทำงาน |
| --- | --- | --- |
| `vlib` | `vlib work` | สร้างไดเรกทอรีสำหรับเก็บข้อมูลไบนารีของไลบรารี |
| `vmap` | `vmap work work` | แมปชื่อเชิงตรรกะ `work` เข้ากับโฟลเดอร์บนระบบไฟล์ |
| `vcom` | `vcom -93 -work work <file.vhd>` | คอมไพล์ซอร์สโค้ด VHDL (VHDL-93 หรือ `-2008`) |
| `vsim` | `vsim -voptargs="+acc" work.<top>` | โหลดวงจรเข้าสู่โหมดจำลอง พร้อมเปิดการเข้าถึงสัญญาณภายในทุกระดับ |
| `add wave` | `add wave -r /*` | นำสัญญาณทั้งหมดในโครงสร้างวงจรลงสู่หน้าต่าง Waveform |
| `restart` | `restart -f` | รีเซ็ตเวลาการจำลองกลับไปที่ 0 ps โดยไม่ต้องปิดโปรแกรม |
| `run` | `run 500 ns` หรือ `run -all` | เดินหน้าเวลาการจำลองตามระยะที่ระบุ หรือรันจนจบเงื่อนไข |

---

### 3. ตัวอย่างการทดลอง: 8-bit Arithmetic Logic Unit (ALU)

#### โค้ด RTL: `alu_8bit.vhd`

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_8bit is
    port (
        clk    : in  std_logic;
        rst_n  : in  std_logic;
        opcode : in  std_logic_vector(2 downto 0);
        a      : in  std_logic_vector(7 downto 0);
        b      : in  std_logic_vector(7 downto 0);
        result : out std_logic_vector(7 downto 0);
        zero   : out std_logic;
        carry  : out std_logic
    );
end entity alu_8bit;

architecture rtl of alu_8bit is
    signal res_reg   : unsigned(8 downto 0) := (others => '0');
    signal zero_reg  : std_logic := '0';
begin

    process(clk, rst_n)
        variable u_a : unsigned(8 downto 0);
        variable u_b : unsigned(8 downto 0);
    begin
        if rst_n = '0' then
            res_reg  <= (others => '0');
            zero_reg <= '0';
        elsif rising_edge(clk) then
            u_a := unsigned('0' & a);
            u_b := unsigned('0' & b);

            case opcode is
                when "000" => res_reg <= u_a + u_b;                 -- ADD
                when "001" => res_reg <= u_a - u_b;                 -- SUB
                when "010" => res_reg <= u_a and u_b;               -- AND
                when "011" => res_reg <= u_a or u_b;                -- OR
                when "100" => res_reg <= u_a xor u_b;               -- XOR
                when "101" => res_reg <= shift_left(u_a, 1);        -- SHL
                when "110" => res_reg <= shift_right(u_a, 1);       -- SHR
                when others => res_reg <= (others => '0');
            end case;

            -- ตรวจสอบเงื่อนไข Zero Flag
            if res_reg(7 downto 0) = x"00" then
                zero_reg <= '1';
            else
                zero_reg <= '0';
            end if;
        end if;
    end process;

    result <= std_logic_vector(res_reg(7 downto 0));
    carry  <= res_reg(8);
    zero   <= zero_reg;

end architecture rtl;

```

#### โค้ด Testbench: `tb_alu_8bit.vhd`

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_alu_8bit is
end entity tb_alu_8bit;

architecture test of tb_alu_8bit is
    constant CLK_PERIOD : time := 10 ns;

    signal clk    : std_logic := '0';
    signal rst_n  : std_logic := '0';
    signal opcode : std_logic_vector(2 downto 0) := "000";
    signal a      : std_logic_vector(7 downto 0) := (others => '0');
    signal b      : std_logic_vector(7 downto 0) := (others => '0');
    signal result : std_logic_vector(7 downto 0);
    signal zero   : std_logic;
    signal carry  : std_logic;
begin

    -- ติดตั้ง DUT
    dut : entity work.alu_8bit(rtl)
        port map (
            clk    => clk,
            rst_n  => rst_n,
            opcode => opcode,
            a      => a,
            b      => b,
            result => result,
            zero   => zero,
            carry  => carry
        );

    -- กำเนิดสัญญาณนาฬิกา
    clk_gen : process
    begin
        clk <= '0'; wait for CLK_PERIOD / 2;
        clk <= '1'; wait for CLK_PERIOD / 2;
    end process;

    -- Stimulus และการตรวจสอบความถูกต้องอัตโนมัติ
    stim_proc : process
    begin
        -- ปลด Reset
        rst_n <= '0';
        wait for 25 ns;
        rst_n <= '1';
        wait until rising_edge(clk);

        -- Test 1: ADD (0x15 + 0x2A = 0x3F)
        opcode <= "000"; a <= x"15"; b <= x"2A";
        wait until rising_edge(clk);
        wait for 1 ns;
        assert (result = x"3F" and carry = '0')
            report "Test 1 Failed: ADD calculation error" severity error;

        -- Test 2: ADD with Carry (0xFF + 0x01 = 0x00, Carry = 1)
        opcode <= "000"; a <= x"FF"; b <= x"01";
        wait until rising_edge(clk);
        wait for 1 ns;
        assert (result = x"00" and carry = '1')
            report "Test 2 Failed: Carry flag error" severity error;

        -- Test 3: XOR (0xAA xor 0x55 = 0xFF)
        opcode <= "100"; a <= x"AA"; b <= x"55";
        wait until rising_edge(clk);
        wait for 1 ns;
        assert (result = x"FF")
            report "Test 3 Failed: XOR calculation error" severity error;

        report ">>> All ALU Tests Passed Successfully! <<<" severity note;
        wait;
    end process stim_proc;

end architecture test;

```

---

### 4. การจำลองผ่านสคริปต์อัตโนมัติ (ModelSim Macro Script)

สร้างไฟล์ชื่อ `run_alu.do` ไว้ในโฟลเดอร์โปรเจกต์:

```tcl
# 1. ปิดเซสชันเดิมและเคลียร์ไลบรารี
quit -sim
if [file exists work] {
    vdel -lib work -all
}
vlib work
vmap work work

# 2. คอมไพล์ VHDL
vcom -93 -work work alu_8bit.vhd
vcom -93 -work work tb_alu_8bit.vhd

# 3. เริ่มการจำลอง (เปิดการมองเห็นสัญญาณด้วย -voptargs="+acc")
vsim -t 1ns -voptargs="+acc" work.tb_alu_8bit

# 4. จัดรูปแบบหน้าต่างสัญญาณ Waveform
add wave -divider "Clocks & Control"
add wave -format logic /tb_alu_8bit/clk
add wave -format logic /tb_alu_8bit/rst_n
add wave -format literal -radix bin /tb_alu_8bit/opcode

add wave -divider "Inputs"
add wave -format literal -radix hex /tb_alu_8bit/a
add wave -format literal -radix hex /tb_alu_8bit/b

add wave -divider "Outputs & Flags"
add wave -format literal -radix hex /tb_alu_8bit/result
add wave -format logic /tb_alu_8bit/zero
add wave -format logic /tb_alu_8bit/carry

# 5. ปรับความกว้างของคอลัมน์ชื่อสัญญาณและเริ่มรัน
configure wave -namecolwidth 160
configure wave -valuecolwidth 80
configure wave -signalnamestyle 1

run -all
wave zoom full

```

คำสั่งรันจาก Terminal:

```bash
modelsim -do run_alu.do

```

*(หากต้องการรันแบบคอมมานด์ไลน์โดยไม่เปิดหน้าต่าง GUI ให้ใช้คำสั่ง `vsim -c -do run_alu.do`)*

---

### 5. ขั้นตอนการใช้งานผ่านหน้าต่างกราฟิก (GUI Step-by-Step)

1. **สร้างและบันทึกโปรเจกต์:** ไปที่เมนู **File $\rightarrow$ New $\rightarrow$ Project...** ตั้งชื่อโปรเจกต์และระบุโฟลเดอร์ทำงาน
2. **เพิ่มไฟล์เข้าสู่โปรเจกต์:** เลือก **Add Existing File** เพื่อนำไฟล์ `.vhd` ทั้งหมดเข้ามา
3. **การคอมไพล์:** คลิกขวาที่ไฟล์ในหน้าต่าง Project แล้วเลือก **Compile $\rightarrow$ Compile All** ตรวจสอบว่าไอคอนหน้าชื่อไฟล์เปลี่ยนเป็นเครื่องหมายถูกสีเขียว
4. **เริ่มการจำลอง:** ไปที่แท็บ **Library** ด้านซ้าย กางโฟลเดอร์ `work` คลิกขวาที่ `tb_alu_8bit` เลือก **Simulate**
5. **เพิ่มสัญญาณลง Waveform:** ในหน้าต่าง **Objects** ลากคลุมสัญญาณที่ต้องการแล้วลากไปวางในหน้าต่าง **Wave** (หรือกด `Ctrl+W`)
6. **ควบคุมการรัน:** ใช้แถบเครื่องมือด้านบน กดปุ่ม **Run** (กำหนดเวลา เช่น 100 ns) หรือพิมพ์คำสั่ง `run 100 ns` ในช่อง Transcript ด้านล่าง

---

### 6. เทคนิคการวิเคราะห์และดีบักใน ModelSim

* **การแก้ไขและคอมไพล์ซ้ำอย่างรวดเร็ว (Edit-Recompile-Restart):**
เมื่อแก้ไขโค้ด VHDL ให้พิมพ์ชุดคำสั่งนี้ใน Transcript โดยไม่ต้องปิดหน้าต่าง Waveform:
```tcl
vcom -93 -work work alu_8bit.vhd
restart -f
run -all

```


* **การใช้งาน Cursors เพื่อวัดเวลาหน่วง:**
* คลิกซ้ายลงบนกราฟเพื่อปัก Cursor ตำแหน่งแรก
* คลิกขวาเลือก **Add Cursor** เพื่อสร้าง Cursor ที่สอง หน้าต่างจะแสดงผลต่างเวลา ($\Delta t$) และความถี่ของสัญญาณระหว่างสองจุดให้อัตโนมัติ


* **การดู Delta Delays:**
หากต้องการตรวจสอบการเปลี่ยนแปลงของสัญญาณภายในรอบเวลาเดียวกัน (ก่อนขอบสัญญาณนาฬิกาถัดไป) ให้เปิดหน้าต่าง **View $\rightarrow$ List** หรือขยายมุมมองเวลาใน Waveform เพื่อตรวจจับ Glitch ระดับเสี้ยวสัญญาณ

---

### 7. ข้อควรระวังและแนวทางแก้ไขปัญหาทั่วไป

* **สัญญาณใน DUT ไม่แสดงในหน้าต่าง Objects หรือหาไม่พบ:**
* *สาเหตุ:* โหมด Optimization ของ ModelSim ตัดสัญญาณที่ไม่ได้ต่อออกภายนอกทิ้ง
* *วิธีแก้:* ตรวจสอบว่าได้ใส่พารามิเตอร์ `-voptargs="+acc"` ในคำสั่ง `vsim` หรือไปที่ **Simulate $\rightarrow$ Start Simulation $\rightarrow$ Optimization Options $\rightarrow$ Apply full visibility (+acc)**


* **ข้อผิดพลาด `(vcom-1141) Identifier is already declared in this scope`:**
* *สาเหตุ:* มีการประกาศชื่อตัวแปร สัญญาณ หรือพอร์ตซ้ำกันภายใน Block เดียวกัน หรือประกาศชื่อ Entity ซ้ำในหลายสถาปัตยกรรม
* *วิธีแก้:* ตรวจสอบส่วนหัวของ Entity และ Architecture เพื่อเปลี่ยนชื่อตัวแปรที่ซ้ำซ้อน


* **ข้อความแจ้งเตือน `Metastability detected` หรือค่าสัญญาณกลายเป็น `'X'`:**
* *สาเหตุ:* ขารีเซตยังไม่ถูกดึงลงต่ำก่อนเริ่มกระบวนการ หรือมีช่วงเวลาที่ไม่มีไดรเวอร์ขับสัญญาณ
* *วิธีแก้:* ตรวจสอบลำดับการกำหนดค่าเริ่มต้นในไฟล์ Testbench ให้เริ่มจากสถานะรีเซตเสมอ