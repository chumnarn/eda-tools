--=====================================================================
-- ram8.vhd -- LAB 08 : DUT for the advanced stimulus lab
------------------------------------------------------------------------
-- A 16 x 8 register file (small RAM).
--
-- The data ports use the type BIT_VECTOR on purpose:
--   "hread" (std.textio) can only read a hexadecimal number into a
--   BIT_VECTOR -- it refuses std_logic_vector.  Using bit_vector for
--   the data path therefore keeps the vector file reader simple.
--
-- The address and the control signals stay std_logic.
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram8 is
  generic (
    ADDR_WIDTH : positive := 4              -- 4 address bits -> 16 words
  );
  port (
    clk  : in  std_logic;
    we   : in  std_logic;                   -- write enable
    addr : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    din  : in  bit_vector(7 downto 0);       -- data in  (bit_vector !)
    dout : out bit_vector(7 downto 0)        -- data out (bit_vector !)
  );
end entity ram8;

architecture rtl of ram8 is
  type mem_t is array (0 to 2**ADDR_WIDTH-1) of bit_vector(7 downto 0);
  signal mem : mem_t := (others => (others => '0'));
begin

  -- write port
  process (clk) is
  begin
    if rising_edge(clk) then
      if we = '1' then
        mem(to_integer(unsigned(addr))) <= din;
      end if;
    end if;
  end process;

  -- read port (asynchronous)
  dout <= mem(to_integer(unsigned(addr)));

end architecture rtl;
