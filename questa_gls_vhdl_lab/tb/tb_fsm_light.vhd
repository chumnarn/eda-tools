--=====================================================================
-- tb_fsm_light.vhd -- LAB 08 : self checking testbench for fsm_light
-----------------------------------------------------------------------
-- The SAME file runs against the RTL level and against the gate level :
-- the DUT is declared as a COMPONENT named "fsm_light", so ModelSim binds
-- it to the VHDL entity fsm_light (rtl/fsm_light.vhd) or to the Verilog
-- module fsm_light (netlist/fsm_light_net.v), whichever is in the work
-- library.
--
--   generics : TRACEFILE, RESULTFILE, GATE
--   trace line format (same as the Verilog lab) :
--      state=<hex> red=<0|1> green=<0|1> yellow=<0|1>
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity tb_fsm_light is
  generic (
    TRACEFILE  : string  := "trace.txt";
    RESULTFILE : string  := "result.txt";
    GATE       : boolean := false
  );
end entity tb_fsm_light;

architecture sim of tb_fsm_light is
  constant CYCLE : time := 10 ns;

  signal clk    : std_logic := '0';
  signal rst_n  : std_logic := '0';
  signal state  : std_logic_vector(1 downto 0);
  signal red    : std_logic;
  signal green  : std_logic;
  signal yellow : std_logic;

  component fsm_light is
    port (
      clk    : in  std_logic;
      rst_n  : in  std_logic;
      state  : out std_logic_vector(1 downto 0);
      red    : out std_logic;
      green  : out std_logic;
      yellow : out std_logic
    );
  end component fsm_light;

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

  dut : fsm_light
    port map (
      clk    => clk,
      rst_n  => rst_n,
      state  => state,
      red    => red,
      green  => green,
      yellow => yellow
    );

  stim : process is
    file f : text;
    variable l : line;
    variable errors : integer := 0;
    variable checks : integer := 0;

    procedure check_state(constant exp_state  : std_logic_vector(1 downto 0);
                          constant exp_red    : std_logic;
                          constant exp_green  : std_logic;
                          constant exp_yellow : std_logic;
                          constant what       : string) is
      variable ok : boolean;
    begin
      ok := (state = exp_state) and (red = exp_red) and
            (green = exp_green) and (yellow = exp_yellow);
      checks := checks + 1;
      assert ok
        report "FAIL " & what & " : state=" & to_hstring(state) &
               " red=" & to_string(red) &
               " green=" & to_string(green) &
               " yellow=" & to_string(yellow)
        severity error;
      if not ok then errors := errors + 1; end if;
      write(l, "state=" & to_hstring(state) &
                " red=" & to_string(red) &
                " green=" & to_string(green) &
                " yellow=" & to_string(yellow));
      writeline(f, l);
      report "  t=" & timestr(now) & " : " & what &
             " -> state=" & to_hstring(state) &
             " red=" & to_string(red) &
             " green=" & to_string(green) &
             " yellow=" & to_string(yellow) severity note;
    end procedure check_state;

  begin
    file_open(f, TRACEFILE, write_mode);
    if GATE then
      report "=== tb_fsm_light : GATE LEVEL ===" severity note;
    else
      report "=== tb_fsm_light : RTL ===" severity note;
    end if;

    -- (1) reset : the FSM must stay in RED -------------------------------
    rst_n <= '0';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait for 1 ns;
    rst_n <= '1';
    wait for 1 ns;
    check_state("00", '1', '0', '0', "after reset");

    -- (2) follow the state sequence --------------------------------------
    wait until rising_edge(clk);
    wait for 1 ns;
    check_state("01", '0', '1', '0', "RED -> GREEN");

    wait until rising_edge(clk);
    wait for 1 ns;
    check_state("10", '0', '0', '1', "GREEN -> YELLOW");

    wait until rising_edge(clk);
    wait for 1 ns;
    check_state("00", '1', '0', '0', "YELLOW -> RED");

    wait until rising_edge(clk);
    wait for 1 ns;
    check_state("01", '0', '1', '0', "RED -> GREEN again");

    file_close(f);

    report " checks = " & integer'image(checks) &
           " , errors = " & integer'image(errors) severity note;

    if errors = 0 then
      report "TEST_PASSED : tb_fsm_light completed" severity note;
      write_result(RESULTFILE, "PASS");
    else
      report "TEST_FAILED : " & integer'image(errors) & " error(s)" severity error;
      write_result(RESULTFILE, "FAIL");
    end if;

    std.env.finish;
    wait;
  end process stim;

end architecture sim;
