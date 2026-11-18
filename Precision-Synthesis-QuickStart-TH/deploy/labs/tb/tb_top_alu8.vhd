-- tb_top_alu8.vhd — testbench แบบตรวจตัวเองสำหรับ top_alu8 (ระดับบอร์ด)
--
-- สิ่งที่ตรวจ
--   1) LED[7:0] ต้องตรงกับผลลัพธ์ ALU ที่คำนวณจาก SW[7:0], SW[15:8] และ BTN
--      (ผลลัพธ์ถูกลงทะเบียนไว้ 1 รอบนาฬิกา จึงต้องรอขอบขึ้นก่อนตรวจ)
--   2) LED[8] = zero, LED[9] = overflow ต้องตรงกับแบบจำลองอ้างอิง
--   3) SEG ต้องเป็นรูปแบบของเลขฐาน 16 หลักใดหลักหนึ่ง (สลับตามจังหวะแบ่งภาพจอ)
--   4) รีเซ็ตต้องทำให้ผลลัพธ์เป็นศูนย์ และหลังปล่อยรีเซ็ตต้องกลับมาคำนวณใหม่
--
-- วิธีรัน
--   ModelSim / QuestaSim:
--     vlib work
--     vcom -2008 ../tb/alu_ref_pkg.vhd
--     vcom -2008 ../rtl/alu8.vhd
--     vcom -2008 ../rtl/hex2seg.vhd
--     vcom -2008 ../rtl/top_alu8.vhd
--     vcom -2008 tb_top_alu8.vhd
--     vsim -c work.tb_top_alu8 -do "run -all; quit -f"
--
--   GHDL:
--     ghdl -a --std=08 tb/alu_ref_pkg.vhd
--     ghdl -a --std=08 rtl/alu8.vhd
--     ghdl -a --std=08 rtl/hex2seg.vhd
--     ghdl -a --std=08 rtl/top_alu8.vhd
--     ghdl -a --std=08 tb/tb_top_alu8.vhd
--     ghdl -e --std=08 tb_top_alu8
--     ghdl -r --std=08 tb_top_alu8 --assert-level=error

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.alu_ref_pkg.all;

entity tb_top_alu8 is
end entity tb_top_alu8;

architecture sim of tb_top_alu8 is

  constant CLK_PERIOD : time := 10 ns;

  -- "others" ใช้ได้เฉพาะใน aggregate assignment ไม่ได้ใน expression
  constant ZERO8 : std_logic_vector(7 downto 0) := (others => '0');

  signal clk        : std_logic := '0';
  signal rst_n      : std_logic := '0';
  signal sw         : std_logic_vector(15 downto 0) := (others => '0');
  signal btn        : std_logic_vector(2 downto 0) := (others => '0');
  signal led        : std_logic_vector(15 downto 0);
  signal an         : std_logic_vector(3 downto 0);
  signal seg        : std_logic_vector(6 downto 0);

begin

  clk <= not clk after CLK_PERIOD/2;

  dut : entity work.top_alu8
    port map (
      CLK100MHZ  => clk,
      CPU_RESETN => rst_n,
      SW         => sw,
      BTN        => btn,
      LED        => led,
      AN         => an,
      SEG        => seg
    );

  stim : process
    variable y_exp    : std_logic_vector(7 downto 0);
    variable ovf_exp  : std_logic;
    variable zero_exp : std_logic;
    variable a_i      : integer;
    variable b_i      : integer;
    variable op_i     : std_logic_vector(2 downto 0);
    variable n_err    : integer := 0;
    variable n_chk    : integer := 0;
    variable seg_lo   : std_logic_vector(6 downto 0);
    variable seg_hi   : std_logic_vector(6 downto 0);
  begin
    -- ปล่อยรีเซ็ต
    rst_n <= '1';
    wait until rising_edge(clk);
    wait for 1 ns;

    ------------------------------------------------------------------
    -- ทดสอบหลายชุด: ค่า operand หลากหลาย + ทุกคำสั่ง
    ------------------------------------------------------------------
    for oi in 0 to 7 loop
      for ai in 0 to 31 loop
        for bi in 0 to 3 loop
          a_i := (ai * 8) mod 256;
          b_i := (bi * 60 + 17) mod 256;

          -- SW[7:0] = ตัวถูก a,  SW[15:8] = ตัวคูณ b
          -- ใน VHDL การต่อสัญญาณ "A & B" เอา A ไว้ที่บิตสูงกว่า
          -- ดังนั้นต้องเขียน byte_of(b) ก่อนแล้วค่อย byte_of(a)
          sw  <= std_logic_vector(byte_of(b_i) & byte_of(a_i));
          btn <= std_logic_vector(to_unsigned(oi, 3));

          -- ผลลัพธ์ถูกลงทะเบียนไว้ 1 รอบนาฬิกา จึงต้องรอขอบขึ้น
          wait until rising_edge(clk);
          wait for 1 ns;

          a_i := int_of(byte_of(a_i));
          b_i := int_of(byte_of(b_i));
          op_i := std_logic_vector(to_unsigned(oi, 3));

          ref_alu(a_i, b_i, op_i, y_exp, ovf_exp, zero_exp);

          n_chk := n_chk + 1;

          if led(7 downto 0) /= y_exp then
            n_err := n_err + 1;
            if n_err <= 10 then
              report "MISMATCH LED: got=" & to_hstring(led(7 downto 0)) &
                     " exp=" & to_hstring(y_exp) severity error;
            end if;
          end if;

          if led(8) /= zero_exp then
            n_err := n_err + 1;
            report "MISMATCH LED zero flag" severity error;
          end if;

          if led(9) /= ovf_exp then
            n_err := n_err + 1;
            report "MISMATCH LED overflow flag" severity error;
          end if;

          -- จอ 7 ส่วน: ต้องเป็นรูปแบบของหลักต่ำหรือหลักสูงเท่านั้น
          seg_lo := seg_of(y_exp(3 downto 0));
          seg_hi := seg_of(y_exp(7 downto 4));
          if (seg /= seg_lo) and (seg /= seg_hi) then
            n_err := n_err + 1;
            if n_err <= 10 then
              report "MISMATCH SEG: got=" & to_hstring(seg) severity error;
            end if;
          end if;
        end loop;
      end loop;
    end loop;

    ------------------------------------------------------------------
    -- ทดสอบรีเซ็ต
    ------------------------------------------------------------------
    sw  <= (others => '1');
    btn <= (others => '0');
    wait until rising_edge(clk);
    wait for 1 ns;

    rst_n <= '0';
    wait until rising_edge(clk);
    wait for 1 ns;

    n_chk := n_chk + 1;
    if led(7 downto 0) /= ZERO8 then
      n_err := n_err + 1;
      report "ERROR: LED output not cleared by reset" severity error;
    end if;

    -- ปล่อยรีเซ็ต: ผลลัพธ์ต้องกลับมาคำนวณใหม่ (a = b = 0xFF, op = ADD)
    rst_n <= '1';
    wait until rising_edge(clk);
    wait for 1 ns;

    n_chk := n_chk + 1;
    if led(7 downto 0) /= byte_of(-2) then
      n_err := n_err + 1;
      report "ERROR: LED output did not resume after reset release" severity error;
    end if;

    report "tb_top_alu8: checked " & integer'image(n_chk) &
           " cases, errors " & integer'image(n_err)
      severity note;

    if n_err = 0 then
      report "PASS" severity note;
      stop;
    else
      assert false report "FAIL: " & integer'image(n_err) & " errors"
        severity failure;
    end if;

    wait;
  end process;

end architecture sim;
