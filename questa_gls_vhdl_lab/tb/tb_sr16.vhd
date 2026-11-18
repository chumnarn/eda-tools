--=====================================================================
-- tb_sr16.vhd -- LAB 08 : self checking testbench for sr16
-----------------------------------------------------------------------
-- The SAME file runs against the RTL level and against the gate level :
-- the DUT is declared as a COMPONENT named "sr16", so ModelSim binds it
-- to the VHDL entity sr16 (rtl/sr16.vhd) or to the Verilog module sr16
-- (netlist/sr16_net.v), whichever design unit sits in the work library.
--
--   generics : TRACEFILE, RESULTFILE, GATE
--   trace line format (same as the Verilog lab) :
--      qout=<hex>
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity tb_sr16 is
  generic (
    TRACEFILE  : string  := "trace.txt";
    RESULTFILE : string  := "result.txt";
    GATE       : boolean := false
  );
end entity tb_sr16;

architecture sim of tb_sr16 is
  constant CYCLE : time := 10 ns;

  signal clk   : std_logic := '0';
  signal rst_n : std_logic := '0';
  signal ld    : std_logic := '0';
  signal sh    : std_logic_vector(1 downto 0) := (others => '0');
  signal din   : std_logic_vector(15 downto 0) := (others => '0');
  signal qout  : std_logic_vector(15 downto 0);

  component sr16 is
    port (
      clk   : in  std_logic;
      rst_n : in  std_logic;
      ld    : in  std_logic;
      sh    : in  std_logic_vector(1 downto 0);
      din   : in  std_logic_vector(15 downto 0);
      qout  : out std_logic_vector(15 downto 0)
    );
  end component sr16;

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

  dut : sr16
    port map (
      clk   => clk,
      rst_n => rst_n,
      ld    => ld,
      sh    => sh,
      din   => din,
      qout  => qout
    );

  stim : process is
    file f : text;
    variable l : line;
    variable errors : integer := 0;
    variable checks : integer := 0;

    procedure check_qout(constant got  : std_logic_vector(15 downto 0);
                         constant exp  : std_logic_vector(15 downto 0);
                         constant what : string) is
    begin
      checks := checks + 1;
      assert got = exp
        report "FAIL " & what & " : expected " & to_hstring(exp) &
               " but got " & to_hstring(got)
        severity error;
      if got /= exp then errors := errors + 1; end if;
      write(l, "qout=" & to_hstring(got));
      writeline(f, l);
      report "  t=" & timestr(now) & " : " & what &
             " -> qout = " & to_hstring(got) severity note;
    end procedure check_qout;

  begin
    file_open(f, TRACEFILE, write_mode);
    if GATE then
      report "=== tb_sr16 : GATE LEVEL ===" severity note;
    else
      report "=== tb_sr16 : RTL ===" severity note;
    end if;

    -- (1) reset : the register must be empty -----------------------------
    rst_n <= '0';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait for 1 ns;
    check_qout(qout, X"0000", "after reset");

    -- (2) parallel load --------------------------------------------------
    rst_n <= '1';
    ld    <= '1';
    din   <= X"A5C3";
    wait until rising_edge(clk);
    wait for 1 ns;
    check_qout(qout, X"A5C3", "parallel load");

    -- (3) shift left -----------------------------------------------------
    ld <= '0';
    sh <= "10";
    wait until rising_edge(clk);
    wait for 1 ns;
    check_qout(qout, X"4B86", "shift left");

    -- (4) shift right ----------------------------------------------------
    sh <= "01";
    wait until rising_edge(clk);
    wait for 1 ns;
    check_qout(qout, X"25C3", "shift right");

    -- (5) hold -----------------------------------------------------------
    sh <= "00";
    wait until rising_edge(clk);
    wait for 1 ns;
    check_qout(qout, X"25C3", "hold");

    file_close(f);

    report " checks = " & integer'image(checks) &
           " , errors = " & integer'image(errors) severity note;

    if errors = 0 then
      report "TEST_PASSED : tb_sr16 completed" severity note;
      write_result(RESULTFILE, "PASS");
    else
      report "TEST_FAILED : " & integer'image(errors) & " error(s)" severity error;
      write_result(RESULTFILE, "FAIL");
    end if;

    std.env.finish;
    wait;
  end process stim;

end architecture sim;
