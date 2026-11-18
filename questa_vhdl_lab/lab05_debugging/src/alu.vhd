--=====================================================================
-- alu.vhd  --  ALU 8 บิต  (มีบั๊กจริง 1 จุด ให้นักเรียนไล่หา)
--=====================================================================
--   op = "00" : A + B
--   op = "01" : A - B      <-- บั๊กอยู่ตรงนี้ (ใช้ + แทน -)
--   op = "10" : A AND B
--   op = "11" : A OR  B
--
--   zero = '1' เมื่อผลลัพธ์เป็นศูนย์
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
  port (
    a    : in  std_logic_vector(7 downto 0);
    b    : in  std_logic_vector(7 downto 0);
    op   : in  std_logic_vector(1 downto 0);
    y    : out std_logic_vector(7 downto 0);
    zero : out std_logic
  );
end entity alu;

architecture rtl of alu is
begin

  comb : process (a, b, op) is
    variable tmp : unsigned(8 downto 0);
  begin
    tmp := (others => '0');
    case op is
      when "00" =>
        tmp := ('0' & unsigned(a)) + ('0' & unsigned(b));
      when "01" =>
        tmp := ('0' & unsigned(a)) + ('0' & unsigned(b));   -- <<< BUG : ต้องเป็น "-"
      when "10" =>
        tmp := ('0' & unsigned(a)) and ('0' & unsigned(b));
      when others =>
        tmp := ('0' & unsigned(a)) or ('0' & unsigned(b));
    end case;

    y    <= std_logic_vector(tmp(7 downto 0));
    zero <= '1' when tmp(8 downto 0) = 0 else '0';
  end process comb;

end architecture rtl;
