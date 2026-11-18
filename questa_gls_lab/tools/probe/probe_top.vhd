--=====================================================================
-- probe_top.vhd  --  design จิ๋วสำหรับ "license probe"
--=====================================================================
--   ไฟล์นี้ถูกคอมไพล์แล้วโหลดขึ้นจำลองเพื่อตรวจว่า license ยังว่าง
--   การ "โหลด design" เท่านั้นที่ทำให้เครื่องมือเช็ค license
--   (คำสั่ง quit -f อย่างเดียวไม่เช็ค)
--
--   หมายเหตุ : vcom ไม่ต้องใช้ license ของ simulator
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;

entity probe_top is
  port (
    clk : in std_logic
  );
end entity probe_top;

architecture rtl of probe_top is
begin
end architecture rtl;
