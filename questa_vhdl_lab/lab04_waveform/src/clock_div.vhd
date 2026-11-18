--=====================================================================
-- clock_div.vhd  --  ตัวหารแบ่งความถี่นาฬิกา
--   ใช้สอนเรื่อง : การอ่าน waveform -- วัดความระยะห่างระหว่างขอบ
--                   และเปรียบเทียบสัญญาณที่หารกัน
--
--   div_clk เปลี่ยนสถานะทุก ๆ DIV ขอบขึ้นของ clk
--   => คาบของ div_clk  = 2 x DIV x (คาบของ clk)
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clock_div is
  generic (
    DIV : positive := 4
  );
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    div_clk : out std_logic;
    count   : out std_logic_vector(7 downto 0)
  );
end entity clock_div;

architecture rtl of clock_div is
  signal cnt  : unsigned(7 downto 0) := (others => '0');
  signal dclk : std_logic := '0';
begin

  process (clk) is
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cnt  <= (others => '0');
        dclk <= '0';
      else
        if cnt = to_unsigned(DIV - 1, 8) then
          cnt  <= (others => '0');
          dclk <= not dclk;            -- <<< เปลี่ยนสถานะทุก ๆ DIV รอบ
        else
          cnt <= cnt + 1;
        end if;
      end if;
    end if;
  end process;

  div_clk <= dclk;
  count   <= std_logic_vector(cnt);

end architecture rtl;
