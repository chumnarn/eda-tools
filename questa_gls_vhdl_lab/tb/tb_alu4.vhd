--=====================================================================
-- tb_alu4.vhd -- LAB 08 : self checking testbench for alu4
-----------------------------------------------------------------------
-- The SAME file runs against the RTL level and against the gate level :
-- the DUT is declared as a COMPONENT named "alu4", so ModelSim binds it
-- to the VHDL entity alu4 (rtl/alu4.vhd) or to the Verilog module alu4
-- (netlist/alu4_net.v), whichever design unit sits in the work library.
--
--   generics : TRACEFILE, RESULTFILE, GATE
--   trace line format (same as the Verilog lab) :
--      op=<dec> a=<hex> b=<hex> y=<hex> zero=<0|1>
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity tb_alu4 is
  generic (
    TRACEFILE  : string  := "trace.txt";
    RESULTFILE : string  := "result.txt";
    GATE       : boolean := false
  );
end entity tb_alu4;

architecture sim of tb_alu4 is
  constant CYCLE : time := 10 ns;

  signal clk   : std_logic := '0';
  signal rst_n : std_logic := '0';
  signal op    : std_logic_vector(2 downto 0) := (others => '0');
  signal a     : std_logic_vector(3 downto 0) := (others => '0');
  signal b     : std_logic_vector(3 downto 0) := (others => '0');
  signal y     : std_logic_vector(3 downto 0);
  signal zero  : std_logic;

  component alu4 is
    port (
      clk   : in  std_logic;
      rst_n : in  std_logic;
      op    : in  std_logic_vector(2 downto 0);
      a     : in  std_logic_vector(3 downto 0);
      b     : in  std_logic_vector(3 downto 0);
      y     : out std_logic_vector(3 downto 0);
      zero  : out std_logic
    );
  end component alu4;

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

  dut : alu4
    port map (
      clk   => clk,
      rst_n => rst_n,
      op    => op,
      a     => a,
      b     => b,
      y     => y,
      zero  => zero
    );

  stim : process is
    file f : text;
    variable l : line;
    variable errors : integer := 0;
    variable checks : integer := 0;

    procedure do_op(constant o    : std_logic_vector(2 downto 0);
                    constant av   : std_logic_vector(3 downto 0);
                    constant bv   : std_logic_vector(3 downto 0);
                    constant exp  : std_logic_vector(3 downto 0);
                    constant what : string) is
    begin
      op <= o;
      a  <= av;
      b  <= bv;
      wait until rising_edge(clk);
      wait for 1 ns;
      checks := checks + 1;
      assert y = exp
        report "FAIL " & what & " : expected " & to_hstring(exp) &
               " but got " & to_hstring(y)
        severity error;
      if y /= exp then errors := errors + 1; end if;
      write(l, "op=" & nospace(integer'image(to_integer(unsigned(o)))) &
                " a=" & to_hstring(av) &
                " b=" & to_hstring(bv) &
                " y=" & to_hstring(y) &
                " zero=" & to_string(zero));
      writeline(f, l);
      report "  t=" & timestr(now) & " : " & what &
             " -> y = " & to_hstring(y) &
             " (zero = " & to_string(zero) & ")" severity note;
    end procedure do_op;

  begin
    file_open(f, TRACEFILE, write_mode);
    if GATE then
      report "=== tb_alu4 : GATE LEVEL ===" severity note;
    else
      report "=== tb_alu4 : RTL ===" severity note;
    end if;

    -- (1) reset ----------------------------------------------------------
    rst_n <= '0';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait for 1 ns;
    rst_n <= '1';

    -- (2) the six operations of the Verilog lab --------------------------
    do_op("000", "0111", "0101", "1100", "add");
    do_op("001", "0111", "0101", "0010", "sub");
    do_op("010", "1100", "1010", "1000", "and");
    do_op("011", "1100", "1010", "1110", "or");
    do_op("100", "1100", "1010", "0110", "xor");
    do_op("000", "1111", "0001", "0000", "add with carry out");

    file_close(f);

    report " checks = " & integer'image(checks) &
           " , errors = " & integer'image(errors) severity note;

    if errors = 0 then
      report "TEST_PASSED : tb_alu4 completed" severity note;
      write_result(RESULTFILE, "PASS");
    else
      report "TEST_FAILED : " & integer'image(errors) & " error(s)" severity error;
      write_result(RESULTFILE, "FAIL");
    end if;

    std.env.finish;
    wait;
  end process stim;

end architecture sim;
