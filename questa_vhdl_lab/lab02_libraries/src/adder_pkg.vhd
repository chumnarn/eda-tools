--=====================================================================
-- adder_pkg.vhd  --  package ที่อยู่ในไลบรารี work
--   ใช้สอนเรื่อง : package เป็น design unit หนึ่งที่ต้องคอมไพล์แยก
--                   และอ้างอิงข้ามไลบรารีด้วย work.adder_pkg
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package adder_pkg is
  constant PKG_VERSION : string := "1.0.0";

  -- คืนค่า parity (0/1) ของเลขไบนารี
  function parity(x : unsigned) return std_logic;

  -- แปลง unsigned เป็นเลขฐานสิบหก
  function to_hex(x : unsigned) return string;
end package adder_pkg;

package body adder_pkg is

  function parity(x : unsigned) return std_logic is
    variable p : std_logic := '0';
  begin
    for i in x'range loop
      p := p xor x(i);
    end loop;
    return p;
  end function parity;

  function to_hex(x : unsigned) return string is
  begin
    return to_hstring(std_logic_vector(x));
  end function to_hex;

end package body adder_pkg;
