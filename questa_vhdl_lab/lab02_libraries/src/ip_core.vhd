--=====================================================================
-- ip_core.vhd  --  "IP core" ที่จะคอมไพล์แยกไปไว้ในไลบรารี ip_lib
--   ใช้สอนเรื่อง : แยก design unit ไปคนละไลบรารี แล้วเรียกใช้ข้าม
--                   ไลบรารีด้วย entity ip_lib.ip_core
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ip_core is
  generic (
    WIDTH : positive := 8
  );
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    en    : in  std_logic;
    value : out std_logic_vector(WIDTH-1 downto 0)
  );
end entity ip_core;

architecture rtl of ip_core is
  signal cnt : unsigned(WIDTH-1 downto 0) := (others => '0');
begin
  process (clk) is
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cnt <= (others => '0');
      elsif en = '1' then
        cnt <= cnt + 1;
      end if;
    end if;
  end process;

  value <= std_logic_vector(cnt);
end architecture rtl;
