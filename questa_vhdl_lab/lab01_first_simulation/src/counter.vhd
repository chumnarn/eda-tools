--=====================================================================
-- counter.vhd -- 8-bit up/down counter with enable and synchronous reset
-- Lab 01 : first simulation with QuestaSim
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
  generic (
    WIDTH : positive := 8
  );
  port (
    clk   : in  std_logic;
    rst_n : in  std_logic;
    en    : in  std_logic;
    up    : in  std_logic;                  -- '1' = up, '0' = down
    cnt   : out std_logic_vector(WIDTH-1 downto 0)
  );
end entity counter;

architecture rtl of counter is
  signal cnt_r : unsigned(WIDTH-1 downto 0) := (others => '0');
begin
  process (clk) is
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        cnt_r <= (others => '0');
      elsif en = '1' then
        if up = '1' then
          cnt_r <= cnt_r + 1;
        else
          cnt_r <= cnt_r - 1;
        end if;
      end if;
    end if;
  end process;

  cnt <= std_logic_vector(cnt_r);
end architecture rtl;
