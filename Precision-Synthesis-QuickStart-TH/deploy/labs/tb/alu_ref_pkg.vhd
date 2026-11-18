-- alu_ref_pkg.vhd — แบบจำลองอ้างอิง (golden model) สำหรับตรวจ ALU
--
-- หลักการสำคัญที่สอนในไฟล์นี้:
--   แบบจำลองอ้างอิงต้อง "คนละวิธี" กับตัวออกแบบจริงเสมอ
--   ถ้าใช้ตรรกะเดียวกัน บั๊กทั้งสองฝั่งจะหายไปพร้อมกันและการตรวจจะไม่มีความหมาย
--
--   RTL จริง  -> ใช้ numeric_std บนสัญญาณแบบ signed
--   แบบจำลอง -> ใช้เลขจำนวนเต็ม (integer) ซึ่งเป็น arithmetic อิสระจาก RTL
--
--   การใช้ integer ยังทำให้ตรวจ overflow ได้ง่าย เพราะผลบวกไม่ถูกตัดที่ 8 บิต
--   จึงเห็นค่าจริงก่อนการตัด แล้วค่อยตัดเองทีหลัง

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package alu_ref_pkg is

  -- แปลงเลขจำนวนเต็ม (อาจเป็นลบ) ให้เป็นไบต์ 8 บิตแบบ two's complement
  function byte_of(x : integer) return std_logic_vector;

  -- แปลงไบต์ 8 บิตให้เป็นเลขจำนวนเต็มแบบมีเครื่องหมาย
  function int_of(v : std_logic_vector) return integer;

  -- หารแบบตัดเศษลง (floor) สำหรับเลขลบ ตรงกับการเลื่อนขวาเชิงอารีเมติก
  function fdiv(x : integer; d : integer) return integer;

  -- แบบจำลองอ้างอิงของ ALU 8 บิต
  procedure ref_alu(
    a_i    : in  integer;
    b_i    : in  integer;
    op_i   : in  std_logic_vector(2 downto 0);
    y_o    : out std_logic_vector(7 downto 0);
    ovf_o  : out std_logic;
    zero_o : out std_logic);

  -- รูปแบบจอ 7 ส่วน (common anode) ของตัวเลขฐาน 16 หนึ่งหลัก
  function seg_of(hex : std_logic_vector(3 downto 0)) return std_logic_vector;

end package alu_ref_pkg;

package body alu_ref_pkg is

  -- ค่าศูนย์ 8 บิต: ใช้ constant เพราะ "others" ใช้ได้เฉพาะ aggregate assignment
  constant ZERO8 : std_logic_vector(7 downto 0) := (others => '0');

  function byte_of(x : integer) return std_logic_vector is
  begin
    -- mod กับบวกเสมอให้ผลไม่ติดลบ จึงได้ two's complement ที่ถูกต้อง
    return std_logic_vector(to_unsigned(x mod 256, 8));
  end function byte_of;

  function int_of(v : std_logic_vector) return integer is
  begin
    if v(7) = '1' then
      return to_integer(unsigned(v)) - 256;
    else
      return to_integer(unsigned(v));
    end if;
  end function int_of;

  function fdiv(x : integer; d : integer) return integer is
    variable q : integer;
  begin
    q := x / d;
    if (x mod d) /= 0 then
      if x < 0 then
        q := q - 1;
      end if;
    end if;
    return q;
  end function fdiv;

  procedure ref_alu(
    a_i    : in  integer;
    b_i    : in  integer;
    op_i   : in  std_logic_vector(2 downto 0);
    y_o    : out std_logic_vector(7 downto 0);
    ovf_o  : out std_logic;
    zero_o : out std_logic) is
    variable ab    : std_logic_vector(7 downto 0);
    variable bb    : std_logic_vector(7 downto 0);
    variable full  : integer;
    variable sh    : integer;
  begin
    ab      := byte_of(a_i);
    bb      := byte_of(b_i);
    y_o     := (others => '0');
    ovf_o   := '0';

    case op_i is
      when "000" =>                        -- ADD
        full := a_i + b_i;
        if (full > 127) or (full < -128) then
          ovf_o := '1';
        end if;
        y_o := byte_of(full);

      when "001" =>                        -- SUB
        full := a_i - b_i;
        if (full > 127) or (full < -128) then
          ovf_o := '1';
        end if;
        y_o := byte_of(full);

      when "010" =>                        -- AND
        y_o := ab and bb;

      when "011" =>                        -- OR
        y_o := ab or bb;

      when "100" =>                        -- XOR
        y_o := ab xor bb;

      when "101" =>                        -- SLT (เปรียบเทียบแบบมีเครื่องหมาย)
        if a_i < b_i then
          y_o := byte_of(1);
        end if;

      when "110" =>                        -- SHL (เลื่อนซ้ายเชิงตรรกะ)
        sh  := b_i mod 8;
        y_o := byte_of(to_integer(unsigned(ab)) * (2 ** sh));

      when "111" =>                        -- SHR (เลื่อนขวาเชิงอารีเมติก)
        sh  := b_i mod 8;
        y_o := byte_of(fdiv(a_i, 2 ** sh));

      when others =>
        y_o := (others => '0');
    end case;

    if y_o = ZERO8 then
      zero_o := '1';
    else
      zero_o := '0';
    end if;
  end procedure ref_alu;

  function seg_of(hex : std_logic_vector(3 downto 0)) return std_logic_vector is
  begin
    case hex is
      when "0000" => return "0111111";
      when "0001" => return "0000110";
      when "0010" => return "1011011";
      when "0011" => return "1001111";
      when "0100" => return "1100110";
      when "0101" => return "1101101";
      when "0110" => return "1111101";
      when "0111" => return "0000111";
      when "1000" => return "1111111";
      when "1001" => return "1101111";
      when "1010" => return "1110111";
      when "1011" => return "1111100";
      when "1100" => return "0111001";
      when "1101" => return "1011110";
      when "1110" => return "1111001";
      when others => return "1110001";
    end case;
  end function seg_of;

end package body alu_ref_pkg;
