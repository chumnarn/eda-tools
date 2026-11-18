--=====================================================================
-- sr16.vhd -- LAB 08 : 16-bit shift register   (RTL level, VHDL)
-----------------------------------------------------------------------
-- The VHDL twin of the Verilog rtl/sr16.v of the reference lab.
--   sh : 0 = hold, 1 = shift right, 2 = shift left
--   ld = '1' loads din in parallel (the load wins over the shift)
--
-- The entity name and the port names are identical to the Yosys
-- netlist (module sr16), so ONE testbench component binding works
-- for both the RTL level and the gate level.
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sr16 is
  port (
    clk   : in  std_logic;
    rst_n : in  std_logic;
    ld    : in  std_logic;
    sh    : in  std_logic_vector(1 downto 0);
    din   : in  std_logic_vector(15 downto 0);
    qout  : out std_logic_vector(15 downto 0)
  );
end entity sr16;

architecture rtl of sr16 is
  -- no arithmetic here : the shift is a pure bit shuffle, so plain
  -- std_logic_vector slicing is used (safe for GHDL synthesis).
  signal cq : std_logic_vector(15 downto 0) := (others => '0');
begin

  process (clk, rst_n) is
  begin
    if rst_n = '0' then
      cq <= (others => '0');
    elsif rising_edge(clk) then
      if ld = '1' then
        cq <= din;                        -- parallel load
      else
        case sh is
          when "01" => cq <= '0' & cq(15 downto 1);  -- shift right
          when "10" => cq <= cq(14 downto 0) & '0';  -- shift left
          when others => cq <= cq;                   -- hold
        end case;
      end if;
    end if;
  end process;

  qout <= cq;

end architecture rtl;
