--=====================================================================
-- x_demo.vhd  --  สาธิตการเกิดค่า X (Unknown) ใน VHDL
--=====================================================================
--   มี 3 สัญญาณที่น่าสนใจ
--   1) acc           : register ที่ไม่มี initial value
--                      -> เป็น X ตอน t=0 แต่หายไปหลัง reset (ปกติ)
--   2) never_driven  : ประกาศแล้วไม่เคยถูก assign
--                      -> เป็น X ตลอดการจำลอง (บั๊กจริง)
--   3) eq / eq2      : เอาต์พุตสองแบบที่ให้ผลต่างกันเมื่อเจอ X
--
--   ข้อควรรู้ (วัดได้จริงบน ModelSim DE-64 2026.1) :
--     * ตัว "=" ของ IEEE 1164 คืนค่า FALSE เมื่อ operand มี X/U
--       -> X "ไม่" แพร่ผ่านการเปรียบเทียบ
--     * ตัว xor / and / or และตัวคณิต (numeric_std) แพร่ X
--       -> เอาต์พุตแบบ bitwise จึงกลายเป็น X ตาม
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity x_demo is
  port (
    clk : in  std_logic;
    rst : in  std_logic;
    a   : in  std_logic_vector(7 downto 0);
    b   : in  std_logic_vector(7 downto 0);
    eq  : out std_logic;               -- ใช้ "="        -> X ไม่แพร่
    eq2 : out std_logic;               -- ใช้ xor       -> X แพร่
    sum : out std_logic_vector(8 downto 0)
  );
end entity x_demo;

architecture rtl of x_demo is

  -- ประกาศแบบไม่มีค่าเริ่มต้น -> เริ่มต้นเป็น 'U' (Unknown)
  signal acc          : std_logic_vector(7 downto 0);
  -- ประกาศแล้วไม่มีใคร assign เลย -> เป็น 'U' ตลอดการจำลอง
  signal never_driven : std_logic_vector(7 downto 0);

  -- เปรียบเทียบแบบ bitwise : X จะแพร่ผ่าน xor / and
  function all_eq(x, y : std_logic_vector) return std_logic is
    variable r : std_logic := '1';
  begin
    for i in x'range loop
      r := r and not (x(i) xor y(i));
    end loop;
    return r;
  end function all_eq;

begin

  process (clk) is
  begin
    if rising_edge(clk) then
      if rst = '1' then
        acc <= (others => '0');
      else
        -- ต้องแปลงเป็น unsigned ก่อนบวก (std_logic_vector ไม่มีตัว +)
        acc <= std_logic_vector(unsigned(a) + unsigned(b));
      end if;
    end if;
  end process;

  -- t = 0        : acc เป็น U  -> sum เป็น U (X แพร่ผ่านตัวคณิต)
  -- หลัง reset   : acc = 46    -> sum = 7A  (ค่าที่รู้)
  sum <= std_logic_vector(unsigned('0' & acc) + unsigned('0' & b));

  -- แบบที่ 1 : ใช้ "=" -> ผลลัพธ์เป็น FALSE เมื่อมี X -> ไม่กลายเป็น X
  eq  <= '1' when acc = a else '0';

  -- แบบที่ 2 : ใช้ xor -> X แพร่ผ่าน -> เป็น X ตลอดเวลาที่ never_driven เป็น X
  eq2 <= all_eq(never_driven, a);

end architecture rtl;
