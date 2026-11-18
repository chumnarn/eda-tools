--=====================================================================
-- alu4.vhd -- LAB 08 : 4-bit ALU   (RTL level, VHDL)
-----------------------------------------------------------------------
-- The VHDL twin of the Verilog rtl/alu4.v of the reference lab.
--   op : 0 = add, 1 = subtract, 2 = and, 3 = or, 4 = xor, else 0
--   y    : registered result, it appears on the clock edge
--   zero : combinational, '1' when y is all zeros
--
-- The entity name and the port names are identical to the Yosys
-- netlist (module alu4), so ONE testbench component binding works
-- for both the RTL level and the gate level.
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu4 is
  port (
    clk   : in  std_logic;
    rst_n : in  std_logic;
    op    : in  std_logic_vector(2 downto 0);
    a     : in  std_logic_vector(3 downto 0);
    b     : in  std_logic_vector(3 downto 0);
    y     : out std_logic_vector(3 downto 0);
    zero  : out std_logic
  );
end entity alu4;

architecture rtl of alu4 is
  -- The arithmetic uses "unsigned" : numeric_std has no
  -- "std_logic_vector + integer", but "unsigned + unsigned" exists.
  signal cq : unsigned(3 downto 0) := (others => '0');
begin

  process (clk, rst_n) is
    variable ua : unsigned(3 downto 0);
    variable ub : unsigned(3 downto 0);
  begin
    if rst_n = '0' then
      cq <= (others => '0');
    elsif rising_edge(clk) then
      ua := unsigned(a);
      ub := unsigned(b);
      case op is
        when "000" => cq <= ua + ub;    -- add      (4 bit, wraps around)
        when "001" => cq <= ua - ub;    -- subtract (4 bit, wraps around)
        when "010" => cq <= ua and ub;  -- and
        when "011" => cq <= ua or ub;   -- or
        when "100" => cq <= ua xor ub;  -- xor
        when others => cq <= (others => '0');
      end case;
    end if;
  end process;

  y    <= std_logic_vector(cq);
  zero <= '1' when cq = to_unsigned(0, cq'length) else '0';

end architecture rtl;
