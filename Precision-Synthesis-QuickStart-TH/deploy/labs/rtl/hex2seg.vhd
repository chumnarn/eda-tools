-- hex2seg.vhd — ตัวถอดรหัสเลขฐาน 16 ไปยังรูปแบบจอ 7 ส่วน
--
-- บอร์ด Nexys A7-100T ใช้จอ 7 ส่วนแบบ common anode
--   -> ส่วนที่ "ติด" คือสัญญาณ 0 (แอโนดที่ต่อกับ VCC)
--   -> ตัวบิตเรียงจากน้อยไปมากคือ a, b, c, d, e, f, g
--      โดย seg(0) = a (ส่วนบน) ... seg(6) = g (ส่วนกลาง)
--
-- รูปแบบจอ 7 ส่วนมาตรฐานของ Nexys:
--   0: a b c d e f    |  1: b c        |  2: a b d e g  |  3: a b c d g
--   4: b c f g        |  5: a c d f g  |  6: a c d e f g |  7: a b c
--   8: a b c d e f g  |  9: a b c d f g
--   A: a b c e f g    |  b: c d e f g  |  C: a d e f    |  d: b c d e g
--   E: a d e f g      |  F: a e f g

library ieee;
use ieee.std_logic_1164.all;

entity hex2seg is
  port (
    hex : in  std_logic_vector(3 downto 0);
    seg : out std_logic_vector(6 downto 0)   -- {g,f,e,d,c,b,a}
  );
end entity hex2seg;

architecture rtl of hex2seg is
begin

  process (hex)
    variable s_v : std_logic_vector(6 downto 0);
  begin
    case hex is
      when "0000" => s_v := "0111111";  -- 0
      when "0001" => s_v := "0000110";  -- 1
      when "0010" => s_v := "1011011";  -- 2
      when "0011" => s_v := "1001111";  -- 3
      when "0100" => s_v := "1100110";  -- 4
      when "0101" => s_v := "1101101";  -- 5
      when "0110" => s_v := "1111101";  -- 6
      when "0111" => s_v := "0000111";  -- 7
      when "1000" => s_v := "1111111";  -- 8
      when "1001" => s_v := "1101111";  -- 9
      when "1010" => s_v := "1110111";  -- A
      when "1011" => s_v := "1111100";  -- b
      when "1100" => s_v := "0111001";  -- C
      when "1101" => s_v := "1011110";  -- d
      when "1110" => s_v := "1111001";  -- E
      when others => s_v := "1110001";  -- F
    end case;
    seg <= s_v;
  end process;

end architecture rtl;
