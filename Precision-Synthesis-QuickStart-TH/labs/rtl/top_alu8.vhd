-- top_alu8.vhd — โมดูลบนสุดสำหรับบอร์ด Digilent Nexys A7-100T
--
-- หน้าที่ของโมดูลนี้
--   รับตัวเลขสองตัวจากสวิตช์ (16 ตัว) -> คำนวณด้วย alu8
--   เลือกคำสั่งจากปุ่มกด 3 ปุ่ม (BTNU/BTNL/BTNR)
--   แสดงผลลัพธ์บน LED 8 ดวง + สถานะ zero/overflow อีก 2 ดวง
--   และแสดงผลลัพธ์เป็นเลขฐาน 16 สองหลักบนจอ 7 ส่วน (แบบมัลติเพล็กซ์)
--
-- การแบ่งขั้นที่ 2: ตัวนับถอดหลัง / แบ่งภาพจอ
--   นาฬิกา 100 MHz หารด้วย 2**16 = 1526 Hz เพื่อสลับหลักจอ
--   ตัวนับนี้เป็นตัวนับแบบ "ป้องกันการเพี้ยน" ตรรกะของ divider ในการสังเคราะห์
--
-- ข้อกำหนดเวลาของบอร์ด (ใช้ใน SDC และ XDC)
--   คาบเวลานาฬิกา = 10.000 ns (100 MHz) -> ค่า slack เป็นบวกได้ก็คือผ่าน

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_alu8 is
  port (
    CLK100MHZ  : in  std_logic;                  -- นาฬิกา 100 MHz (พิน E3)
    CPU_RESETN : in  std_logic;                  -- รีเซ็ต active low (พิน C12)
    SW         : in  std_logic_vector(15 downto 0);-- สวิตช์ 16 ตัว
    BTN        : in  std_logic_vector(2 downto 0); -- ปุ่ม BTNU, BTNL, BTNR
    LED        : out std_logic_vector(15 downto 0);-- LED 16 ดวง
    AN         : out std_logic_vector(3 downto 0); -- ตัวเลือกหลักจอ (common anode)
    SEG        : out std_logic_vector(6 downto 0)  -- ข้อมูลหลักจอ {g..a}
  );
end entity top_alu8;

architecture rtl of top_alu8 is

  constant CLK_PERIOD : time := 10 ns;           -- 100 MHz

  signal y_alu    : signed(7 downto 0);
  signal zero_s   : std_logic;
  signal ovf_s    : std_logic;

  -- ผลลัพธ์ที่ลงทะเบียนไว้ (กัน LED กะพริบเมื่อผู้ใช้โยกสวิตช์)
  signal y_r      : signed(7 downto 0) := (others => '0');
  signal zero_r   : std_logic := '0';
  signal ovf_r    : std_logic := '0';

  -- ตัวนับสำหรับแบ่งภาพจอ
  signal cnt      : unsigned(15 downto 0) := (others => '0');
  signal digit_hi : std_logic;

  signal seg_lo   : std_logic_vector(6 downto 0);
  signal seg_hi   : std_logic_vector(6 downto 0);
  signal seg_mux  : std_logic_vector(6 downto 0);

begin

  ------------------------------------------------------------------
  -- หน่วยคำนวณ
  ------------------------------------------------------------------
  u_alu : entity work.alu8
    port map (
      a        => signed(SW(7 downto 0)),
      b        => signed(SW(15 downto 8)),
      op       => BTN,
      y        => y_alu,
      zero     => zero_s,
      overflow => ovf_s
    );

  ------------------------------------------------------------------
  -- ลงทะเบียนผลลัพธ์
  --
  -- ขั้นตอนนี้สร้างเส้นทางเวลาสองเส้นให้เห็นในรายงานของ Precision:
  --   เส้นทางที่ 1: SW/BTN (อินพุต) -> รีจิสเตอร์   (ถูกจำกัดด้วย set_input_delay)
  --   เส้นทางที่ 2: รีจิสเตอร์ -> LED/จอ (เอาต์พุต) (ถูกจำกัดด้วย set_output_delay)
  -- ------------------------------------------------------------------
  process (CLK100MHZ)
  begin
    if rising_edge(CLK100MHZ) then
      if CPU_RESETN = '0' then
        y_r    <= (others => '0');
        zero_r <= '0';
        ovf_r  <= '0';
      else
        y_r    <= y_alu;
        zero_r <= zero_s;
        ovf_r  <= ovf_s;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------
  -- LED
  ------------------------------------------------------------------
  LED(7 downto 0) <= std_logic_vector(y_r);
  LED(8)          <= zero_r;
  LED(9)          <= ovf_r;
  LED(15 downto 10) <= (others => '0');

  ------------------------------------------------------------------
  -- ตัวนับแบ่งภาพจอ: สลับทุก 65536 รอบนาฬิกา
  ------------------------------------------------------------------
  process (CLK100MHZ)
  begin
    if rising_edge(CLK100MHZ) then
      if CPU_RESETN = '0' then
        cnt <= (others => '0');
      else
        cnt <= cnt + 1;
      end if;
    end if;
  end process;

  digit_hi <= cnt(15);

  ------------------------------------------------------------------
  -- จอ 7 ส่วน: แสดงผลลัพธ์เป็นเลขฐาน 16 สองหลัก
  -- ------------------------------------------------------------------
  u_seg_lo : entity work.hex2seg
    port map (
      hex => std_logic_vector(unsigned(y_r(3 downto 0))),
      seg => seg_lo
    );

  u_seg_hi : entity work.hex2seg
    port map (
      hex => std_logic_vector(unsigned(y_r(7 downto 4))),
      seg => seg_hi
    );

  process (digit_hi, seg_lo, seg_hi)
  begin
    if digit_hi = '0' then
      seg_mux <= seg_lo;
    else
      seg_mux <= seg_hi;
    end if;
  end process;

  SEG <= seg_mux;

  -- ตัวเลือกหลักจอ: common anode -> 0 คือเปิด
  AN <= "1101" when digit_hi = '0' else "1011";

end architecture rtl;
