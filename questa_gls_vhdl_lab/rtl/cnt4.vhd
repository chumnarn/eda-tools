--=====================================================================
-- cnt4.vhd -- RTL ที่ใช้ทั้งคู่มือ : ตัวนับ 4 บิต (asynchronous reset)
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cnt4 is
  port (
    clk   : in  std_logic;
    rst_n : in  std_logic;
    en    : in  std_logic;
    q     : out std_logic_vector(3 downto 0)
  );
end entity cnt4;

architecture rtl of cnt4 is
  signal cq : unsigned(3 downto 0) := (others => '0');
begin

  process (clk, rst_n) is
  begin
    if rst_n = '0' then
      cq <= (others => '0');
    elsif rising_edge(clk) then
      if en = '1' then
        cq <= cq + 1;          -- unsigned + natural  (numeric_std)
      end if;
    end if;
  end process;

  q <= std_logic_vector(cq);

end architecture rtl;
