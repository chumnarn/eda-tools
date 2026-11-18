--=====================================================================
-- counter_top.vhd  --  top ที่ "ยืม" design unit จากคนละไลบรารี
--   1) package adder_pkg อยู่ใน work
--   2) entity ip_core อยู่ใน ip_lib
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ข้อความสำคัญ : ใน VHDL "use" clause เลือกได้เฉพาะ PACKAGE เท่านั้น
--   use ip_lib.ip_core.all;   <-- ผิด ! (ip_core เป็น entity ไม่ใช่ package)
--   วิธีที่ถูกต้องคือ
--       library ip_lib;                      -- ประกาศให้ชื่อไลบรารีอยู่ใน context
--       core : entity ip_lib.ip_core ...    -- แล้วจึงอ้างได้

library ip_lib;                -- ทำให้ชื่อ "ip_lib" มองเห็นได้ใน context นี้

use work.adder_pkg.all;          -- package จาก work (ใช้ได้ เพราะเป็น package)

entity counter_top is
  generic (
    WIDTH : positive := 8
  );
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    en    : in  std_logic;
    value : out std_logic_vector(WIDTH-1 downto 0);
    par   : out std_logic          -- บิต parity คำนวณด้วยฟังก์ชันใน package
  );
end entity counter_top;

architecture rtl of counter_top is
  signal core_val : std_logic_vector(WIDTH-1 downto 0);
begin
  -- สร้างแบบ direct entity instantiation : ข้ามไลบรารีได้โดยไม่ต้องสร้าง component
  core : entity ip_lib.ip_core
    generic map (
      WIDTH => WIDTH
    )
    port map (
      clk   => clk,
      rst   => rst,
      en    => en,
      value => core_val
    );

  value <= core_val;
  par   <= parity(unsigned(core_val));
end architecture rtl;
