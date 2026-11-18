--=====================================================================
-- tb_cnt4_x.vhd -- LAB 06 : what happens when an input becomes 'x' ?
-----------------------------------------------------------------------
-- THIS TESTBENCH DOES NOT JUDGE.  It only OBSERVES and writes what it
-- saw into the trace file, because the interesting part of this lab is
-- that the RTL and the gate level do NOT behave the same way:
--
--   RTL  : "if (en = '1')" with en = 'x'  ->  the condition is not true
--           -> the else branch is taken -> the register HOLDS its value
--
--   GLS  : 'en' goes through real gates (xor / and) -> 'x' propagates
--           -> the D input of the flip-flop becomes 'x' -> the register
--           captures 'x'
--
-- The batch script compares the two observations and decides whether
-- the difference was seen.
--
--   generics : TRACEFILE, RESULTFILE, GATE
--   trace line format (same as the Verilog lab) :
--      observed=<hex>
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity tb_cnt4_x is
  generic (
    TRACEFILE  : string  := "trace.txt";
    RESULTFILE : string  := "result.txt";
    GATE       : boolean := false
  );
end entity tb_cnt4_x;

architecture sim of tb_cnt4_x is
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

  -- The simulator runs with a resolution of 1 fs, so time'image() would
  -- print "26000000 fs".  This helper prints the time in nanoseconds.
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
    file f : text;
    variable l : line;
    variable errors : integer := 0;   -- this testbench does not judge
    variable checks : integer := 0;
  begin
    file_open(f, TRACEFILE, write_mode);
    if GATE then
      report "=== tb_cnt4_x : GATE LEVEL ===" severity note;
    else
      report "=== tb_cnt4_x : RTL ===" severity note;
    end if;
    report "note : this testbench only observes, it does not judge" severity note;

    -- (1) reset and count to 3 -------------------------------------------
    rst_n <= '0';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait for 1 ns;
    rst_n <= '1';
    for i in 1 to 3 loop
      wait until rising_edge(clk);
      wait for 1 ns;
    end loop;
    report "  t=" & timestr(now) &
           " : before the 'x'      q = " & to_hstring(q) severity note;

    -- (2) drive 'x' into the enable --------------------------------------
    en <= 'X';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait for 1 ns;
    report "  t=" & timestr(now) &
           " : after  en = 'x'     q = " & to_hstring(q) severity note;

    -- (3) write down what we saw -----------------------------------------
    write(l, "observed=" & to_hstring(q));
    writeline(f, l);
    file_close(f);

    report " checks = " & integer'image(checks) &
           " , errors = " & integer'image(errors) severity note;

    if errors = 0 then
      report "=== tb_cnt4_x finished ===" severity note;
      report "TEST_PASSED : tb_cnt4_x completed" severity note;
      write_result(RESULTFILE, "PASS");
    else
      report "TEST_FAILED : " & integer'image(errors) & " error(s)" severity error;
      write_result(RESULTFILE, "FAIL");
    end if;

    std.env.finish;
    wait;
  end process stim;

end architecture sim;
