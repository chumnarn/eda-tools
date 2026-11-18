--=====================================================================
-- fsm_light.vhd -- LAB 08 : traffic light FSM   (RTL level, VHDL)
-----------------------------------------------------------------------
-- The VHDL twin of the Verilog rtl/fsm_light.v of the reference lab.
--   Three states : RED(0) -> GREEN(1) -> YELLOW(2) -> RED(0)
--   After the reset : state = RED, red = '1', green = '0', yellow = '0'
--
-- The entity name and the port names are identical to the Yosys
-- netlist (module fsm_light), so ONE testbench component binding
-- works for both the RTL level and the gate level.
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fsm_light is
  port (
    clk    : in  std_logic;
    rst_n  : in  std_logic;
    state  : out std_logic_vector(1 downto 0);
    red    : out std_logic;
    green  : out std_logic;
    yellow : out std_logic
  );
end entity fsm_light;

architecture rtl of fsm_light is
  constant ST_RED    : std_logic_vector(1 downto 0) := "00";
  constant ST_GREEN  : std_logic_vector(1 downto 0) := "01";
  constant ST_YELLOW : std_logic_vector(1 downto 0) := "10";
  -- no arithmetic here : the state is a plain bit pattern
  signal cstate : std_logic_vector(1 downto 0) := ST_RED;
begin

  process (clk, rst_n) is
  begin
    if rst_n = '0' then
      cstate <= ST_RED;
      red    <= '1';
      green  <= '0';
      yellow <= '0';
    elsif rising_edge(clk) then
      case cstate is
        when ST_RED =>
          red    <= '0';
          green  <= '1';
          yellow <= '0';
          cstate <= ST_GREEN;
        when ST_GREEN =>
          red    <= '0';
          green  <= '0';
          yellow <= '1';
          cstate <= ST_YELLOW;
        when ST_YELLOW =>
          red    <= '1';
          green  <= '0';
          yellow <= '0';
          cstate <= ST_RED;
        when others =>
          cstate <= ST_RED;
          red    <= '1';
          green  <= '0';
          yellow <= '0';
      end case;
    end if;
  end process;

  state <= cstate;

end architecture rtl;
