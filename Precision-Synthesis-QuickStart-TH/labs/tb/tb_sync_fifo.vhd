-- tb_sync_fifo.vhd — testbench แบบตรวจตัวเองสำหรับ sync_fifo
--
-- สิ่งที่ตรวจ
--   1) หลังรีเซ็ต FIFO ต้องว่าง (empty = 1) และไม่เต็ม (full = 0)
--   2) เขียนครบ 8 ช่อง -> full ต้องเป็น 1
--   3) เขียนเกิน (ช่องที่ 9) -> ข้อมูลเดิมต้องไม่ถูกเขียนทับ
--   4) อ่านคืนตามลำดับ -> ข้อมูลต้องตรงกับที่เขียนไป
--   5) อ่านหมดแล้ว -> empty ต้องกลับมาเป็น 1
--   6) เขียน/อ่านสลับกันในขณะที่ FIFO ไม่ว่าง
--
-- วิธีรัน
--   ModelSim / QuestaSim:
--     vlib work
--     vcom -2008 ../rtl/sync_fifo.vhd
--     vcom -2008 tb_sync_fifo.vhd
--     vsim -c work.tb_sync_fifo -do "run -all; quit -f"
--
--   GHDL:
--     ghdl -a --std=08 rtl/sync_fifo.vhd
--     ghdl -a --std=08 tb/tb_sync_fifo.vhd
--     ghdl -e --std=08 tb_sync_fifo
--     ghdl -r --std=08 tb_sync_fifo --assert-level=error

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_sync_fifo is
end entity tb_sync_fifo;

architecture sim of tb_sync_fifo is

  constant CLK_PERIOD : time := 10 ns;

  signal clk     : std_logic := '0';
  signal rst_n   : std_logic := '0';
  signal wr_en   : std_logic := '0';
  signal wr_data : std_logic_vector(31 downto 0) := (others => '0');
  signal full    : std_logic;
  signal rd_en   : std_logic := '0';
  signal rd_data : std_logic_vector(31 downto 0);
  signal empty   : std_logic;

begin

  clk <= not clk after CLK_PERIOD/2;

  dut : entity work.sync_fifo
    port map (
      clk     => clk,
      rst_n   => rst_n,
      wr_en   => wr_en,
      wr_data => wr_data,
      full    => full,
      rd_en   => rd_en,
      rd_data => rd_data,
      empty   => empty
    );

  stim : process
    variable n_err   : integer := 0;
    variable n_chk   : integer := 0;
    variable rd_v    : std_logic_vector(31 downto 0);
    variable expect  : std_logic_vector(31 downto 0);
  begin
    ------------------------------------------------------------------
    -- 1) รีเซ็ต
    ------------------------------------------------------------------
    rst_n <= '0';
    wait for 5 * CLK_PERIOD;
    rst_n <= '1';
    wait until rising_edge(clk);
    wait for 1 ns;

    if empty /= '1' then
      n_err := n_err + 1;
      report "ERROR: FIFO should be empty after reset" severity error;
    end if;
    if full /= '0' then
      n_err := n_err + 1;
      report "ERROR: FIFO should not be full after reset" severity error;
    end if;

    ------------------------------------------------------------------
    -- 2) เขียนครบ 8 ช่อง
    ------------------------------------------------------------------
    for i in 0 to 7 loop
      wr_data <= std_logic_vector(to_unsigned(16#1000# + i, 32));
      wr_en   <= '1';
      wait until rising_edge(clk);
      wait for 1 ns;

      if i < 7 then
        if full = '1' then
          n_err := n_err + 1;
          report "ERROR: FIFO reported full too early (after " &
                 integer'image(i+1) & " writes)" severity error;
        end if;
      end if;
    end loop;

    wr_en <= '0';
    wait for 1 ns;

    if full /= '1' then
      n_err := n_err + 1;
      report "ERROR: FIFO should be full after 8 writes" severity error;
    end if;
    if empty = '1' then
      n_err := n_err + 1;
      report "ERROR: FIFO should not be empty after 8 writes" severity error;
    end if;

    ------------------------------------------------------------------
    -- 3) เขียนเกิน: ข้อมูลเดิมต้องไม่ถูกทับ
    ------------------------------------------------------------------
    wr_data <= std_logic_vector(to_unsigned(16#DEAD#, 32));
    wr_en   <= '1';
    wait until rising_edge(clk);
    wait for 1 ns;
    wr_en <= '0';
    wait for 1 ns;

    if full /= '1' then
      n_err := n_err + 1;
      report "ERROR: FIFO lost the full flag" severity error;
    end if;

    ------------------------------------------------------------------
    -- 4) อ่านคืนตามลำดับ
    ------------------------------------------------------------------
    for i in 0 to 7 loop
      expect := std_logic_vector(to_unsigned(16#1000# + i, 32));
      rd_v   := rd_data;          -- ค่าที่จะถูกอ่านในรอบนาฬิกาถัดไป
      rd_en  <= '1';
      wait until rising_edge(clk);
      wait for 1 ns;

      n_chk := n_chk + 1;
      if rd_v /= expect then
        n_err := n_err + 1;
        report "ERROR: read mismatch at index " & integer'image(i) &
               " got=" & to_hstring(rd_v) & " exp=" & to_hstring(expect)
          severity error;
      end if;

      if i < 7 then
        if empty = '1' then
          n_err := n_err + 1;
          report "ERROR: FIFO reported empty too early" severity error;
        end if;
      end if;
    end loop;

    rd_en <= '0';
    wait for 1 ns;

    ------------------------------------------------------------------
    -- 5) อ่านหมดแล้ว
    ------------------------------------------------------------------
    if empty /= '1' then
      n_err := n_err + 1;
      report "ERROR: FIFO should be empty after reading all 8 items"
        severity error;
    end if;
    if full /= '0' then
      n_err := n_err + 1;
      report "ERROR: FIFO should not be full after reading all 8 items"
        severity error;
    end if;

    ------------------------------------------------------------------
    -- 6) เขียน/อ่านสลับกัน
    ------------------------------------------------------------------
    for i in 0 to 7 loop
      wr_data <= std_logic_vector(to_unsigned(16#2000# + i, 32));
      wr_en   <= '1';
      wait until rising_edge(clk);
      wait for 1 ns;
      wr_en   <= '0';        -- ปล่อยมือก่อนขอบของการอ่าน กันเขียนซ้ำสองครั้ง

      expect := std_logic_vector(to_unsigned(16#2000# + i, 32));
      rd_v   := rd_data;
      rd_en  <= '1';
      wait until rising_edge(clk);
      wait for 1 ns;
      rd_en <= '0';

      n_chk := n_chk + 1;
      if rd_v /= expect then
        n_err := n_err + 1;
        report "ERROR: interleaved read mismatch at index " & integer'image(i) &
               " got=" & to_hstring(rd_v) & " exp=" & to_hstring(expect)
          severity error;
      end if;
    end loop;

    wr_en <= '0';
    wait for 1 ns;

    report "tb_sync_fifo: checked " & integer'image(n_chk) &
           " items, errors " & integer'image(n_err)
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
