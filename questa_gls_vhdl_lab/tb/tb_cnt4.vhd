--=====================================================================
-- tb_cnt4.vhd -- testbench ที่ใช้ทั้งระดับ RTL และระดับ gate
-----------------------------------------------------------------------
-- จุดสำคัญของคู่มือนี้ : DUT ถูกประกาศเป็น COMPONENT ชื่อ "cnt4"
--   * ระดับ RTL   : คอมไพล์ rtl/cnt4.vhd       -> entity      ชื่อ cnt4 (VHDL)
--   * ระดับ gate  : คอมไพล์ netlist/cnt4_net.v -> module     ชื่อ cnt4 (Verilog)
--
-- testbench ไฟล์เดียวกันนี้ใช้ได้ทั้งสองระดับ
-- เพราะ ModelSim ผูก component ชื่อ cnt4 ให้เข้ากับ design unit
-- ที่มีชื่อเดียวกันในไลบรารี work (default binding ของ mixed-language)
--
-- ชื่อ port ต้องตรงกันทั้งสองฝั่ง และเป็นตัวพิมพ์เล็กทั้งหมด
-- (VHDL แปลงชื่อ port เป็นตัวพิมพ์เล็ก, Verilog เป็น case-sensitive)
--
-- GENERICS (ส่งผ่านทางคำสั่ง vsim -g) :
--   TRACEFILE  : string  = "trace.txt"    ไฟล์ที่เก็บ trace
--   RESULTFILE : string  = "result.txt"   ไฟล์ที่เก็บคำตัดสิน PASS / FAIL
--   GATE       : boolean = false          true = เป็นการจำลองระดับ gate
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity tb_cnt4 is
  generic (
    TRACEFILE  : string  := "trace.txt";
    RESULTFILE : string  := "result.txt";
    GATE       : boolean := false
  );
end entity tb_cnt4;

architecture sim of tb_cnt4 is
  constant CYCLE : time := 10 ns;

  signal clk   : std_logic := '0';
  signal rst_n : std_logic := '0';
  signal en    : std_logic := '1';
  signal q     : std_logic_vector(3 downto 0);

  component cnt4 is
    port (
      clk   : in  std_logic;
      rst_n : in  std_logic;
      en    : in  std_logic;
      q     : out std_logic_vector(3 downto 0)
    );
  end component cnt4;

  procedure write_result(constant fname : in string; constant verdict : in string) is
    file f : text;
    variable l : line;
  begin
    file_open(f, fname, write_mode);
    write(l, verdict);
    writeline(f, l);
    file_close(f);
  end procedure write_result;

  -- integer'image() and time'image() put one blank in front of a
  -- positive value.  This helper removes it, so the numbers written in
  -- the trace file are the same as the "%0d" of the Verilog testbench.
  function nospace(s : string) return string is
    variable r : string(1 to s'length);
    variable n : integer := 0;
  begin
    for i in s'range loop
      if n = 0 and s(i) = ' ' then next; end if;
      n := n + 1;
      r(n) := s(i);
    end loop;
    return r(1 to n);
  end function nospace;

  -- The simulator runs with a resolution of 10 ps, so time'image() would
  -- print something like "26000000 fs".  This helper prints the time in
  -- nanoseconds.
  function timestr(t : time) return string is
  begin
    return nospace(integer'image(integer'(t / 1 ns))) & " ns";
  end function timestr;

begin

  clk <= not clk after CYCLE / 2;

  dut : cnt4
    port map (
      clk   => clk,
      rst_n => rst_n,
      en    => en,
      q     => q
    );

  stim : process is
    file        tf : text;
    variable    l   : line;
    variable    errors  : integer := 0;
    variable    checks  : integer := 0;
    variable    exp_q   : std_logic_vector(3 downto 0);
  begin
    file_open(tf, TRACEFILE, write_mode);

    if GATE then
      report "=== tb_cnt4 : GATE LEVEL ===" severity note;
    else
      report "=== tb_cnt4 : RTL ===" severity note;
    end if;

    -- (1) reset ---------------------------------------------------------
    rst_n <= '0';
    wait for 2 * CYCLE;
    rst_n <= '1';

    checks := checks + 1;
    assert q = "0000"
      report "FAIL after reset : expected 0 but got " & to_hstring(q)
      severity error;
    if q /= "0000" then errors := errors + 1; end if;
    write(l, "q=" & to_hstring(q)); writeline(tf, l);
    report "  t=" & timestr(now) &
           " : after reset         q = " & to_hstring(q) severity note;

    -- (2) count up ------------------------------------------------------
    for i in 1 to 6 loop
      exp_q := std_logic_vector(to_unsigned(i, 4));
      wait until rising_edge(clk);
      wait for 1 ns;
      checks := checks + 1;
      assert q = exp_q
        report "FAIL count up : expected " & to_hstring(exp_q) &
               " but got " & to_hstring(q)
        severity error;
      if q /= exp_q then errors := errors + 1; end if;
      write(l, "q=" & to_hstring(q)); writeline(tf, l);
      report "  t=" & timestr(now) &
             " : count up " & nospace(integer'image(i)) &
             "            q = " & to_hstring(q) severity note;
    end loop;

    -- (3) hold while en = 0 --------------------------------------------
    en <= '0';
    wait for 3 * CYCLE;

    checks := checks + 1;
    assert q = "0110"
      report "FAIL hold : expected 6 but got " & to_hstring(q)
      severity error;
    if q /= "0110" then errors := errors + 1; end if;
    write(l, "q=" & to_hstring(q)); writeline(tf, l);
    report "  t=" & timestr(now) &
           " : hold (en = '0')     q = " & to_hstring(q) severity note;

    -- (4) count up again ------------------------------------------------
    --     en เปิดอีกครั้ง แล้วปล่อยให้นับไป 3 จังหวะ จึงตรวจค่าครั้งเดียว
    en <= '1';
    for i in 1 to 3 loop
      wait until rising_edge(clk);
    end loop;
    wait for 1 ns;

    checks := checks + 1;
    assert q = "1001"
      report "FAIL count up again : expected 9 but got " & to_hstring(q)
      severity error;
    if q /= "1001" then errors := errors + 1; end if;
    write(l, "q=" & to_hstring(q)); writeline(tf, l);
    report "  t=" & timestr(now) &
           " : count up again     q = " & to_hstring(q) severity note;

    file_close(tf);

    report " checks = " & integer'image(checks) &
           " , errors = " & integer'image(errors) severity note;

    if errors = 0 then
      report "TEST_PASSED : tb_cnt4 completed" severity note;
      write_result(RESULTFILE, "PASS");
    else
      report "TEST_FAILED : " & integer'image(errors) & " error(s)" severity error;
      write_result(RESULTFILE, "FAIL");
    end if;

    std.env.finish;
    wait;
  end process stim;

end architecture sim;
