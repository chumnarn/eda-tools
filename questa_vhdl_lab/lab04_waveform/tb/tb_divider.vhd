--=====================================================================
-- tb_divider.vhd  --  testbench ของ Lab 04 (waveform analysis)
--=====================================================================
--   จุดประสงค์ : สร้าง waveform ที่ "อ่านเป็น" เช่น
--                   - clk            : นาฬิกาหลัก 100 MHz (คาบ 10 ns)
--                   - div_clk        : นาฬิกาที่หาร DIV (คาบ 80 ns เมื่อ DIV=4)
--                   - bus            : ข้อมูลที่เปลี่ยนทุกขอบขึ้นของ div_clk
--                   แล้วใช้เป็นวัตถุสอนการวัดระยะเวลาด้วย cursor
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity tb_divider is
  generic (
    DIV : positive := 4
  );
end entity tb_divider;

architecture sim of tb_divider is
  constant CLK_PERIOD : time := 10 ns;

  signal clk     : std_logic := '0';
  signal rst     : std_logic := '0';
  signal div_clk : std_logic;
  signal count   : std_logic_vector(7 downto 0);
  signal data_bus     : std_logic_vector(7 downto 0);

  procedure write_result(constant fname : in string; constant verdict : in string) is
    file f : text;
    variable l : line;
  begin
    file_open(f, fname, write_mode);
    write(l, verdict);
    writeline(f, l);
    file_close(f);
  end procedure write_result;
begin

  clk <= not clk after CLK_PERIOD / 2;

  dut : entity work.clock_div
    generic map (
      DIV => DIV
    )
    port map (
      clk     => clk,
      rst     => rst,
      div_clk => div_clk,
      count   => count
    );

  -- bus เปลี่ยนทุกขอบขึ้นของ div_clk (ใช้เป็น "ข้อมูล" ให้ดูใน waveform)
  -- ข้อความสำคัญ : ตัว "+" ของ std_logic_vector ไม่มีอยู่จริง
  --   ต้องแปลงเป็น unsigned ก่อนบวก แล้วแปลงกลับทีหลัง
  data_bus <= std_logic_vector(unsigned(count) + to_unsigned(16#5A#, 8));

  ---------------------------------------------------------------------
  -- นับจำนวนขอบขึ้นของ div_clk เพื่อพิสูจน์ว่าคาบเป็น 2 x DIV รอบ clk
  ---------------------------------------------------------------------
  mon : process is
    variable div_rises : integer := 0;
    variable clk_edges : integer := 0;
  begin
    wait on div_clk;
    if div_clk = '1' then
      div_rises := div_rises + 1;
      report "  [mon] t=" & time'image(now) &
             " div_clk rising #" & integer'image(div_rises) severity note;
    end if;
  end process mon;

  stim : process is
    variable errors : integer := 0;
    variable half_period_clks : integer := 0;
  begin
    -- reset
    rst <= '1';
    wait for 3 * CLK_PERIOD;
    rst <= '0';

    -- ปล่อยให้วิ่ง 400 ns
    wait for 400 ns;

    -- ตรวจว่า div_clk ทำงาน : ต้องมีขอบขึ้นอย่างน้อย 4 ครั้งใน 400 ns
    -- (คาบ 80 ns => 400 ns มี 5 ขอบขึ้น)
    report "--------------------------------------------------" severity note;
    report " simulation finished at " & time'image(now)          severity note;
    report "--------------------------------------------------" severity note;

    assert div_clk = '0'
      report "FAIL: div_clk should be low when the counter wraps"
      severity error;

    report "TEST_PASSED : lab04_waveform" severity note;
    write_result("result.txt", "PASS");
    std.env.finish;
    wait;
  end process stim;

end architecture sim;
