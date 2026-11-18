-- sync_fifo.vhd — FIFO แบบตรง (synchronous) ลึก 8 ช่อง กว้าง 32 บิต
--
-- หลักการที่สอนในไฟล์นี้
--   1) ตัวชี้แบบ Gray code: เปลี่ยนสถานะทีละบิต ทำให้ไม่เกิด metastability
--      เมื่อส่งข้ามสัญญาณนาฬิกา และเป็นวิธีมาตรฐานของ FIFO แบบ async FIFO
--   2) ตัวชี้มีบิตเกินหนึ่งบิตเพื่อแยกสถานะ "เต็ม" ออกจาก "ว่าง"
--   3) เงื่อนไขเขียนต้องกันการเขียนทับข้อมูลเดิมเมื่อ FIFO เต็ม
--   4) การอ่านแบบ combinational ให้สังเคราะห์เป็น mux ต่อหน่วยความจำ
--      (บน FPGA จะสังเคราะห์เป็น LUTRAM/FF ไม่ใช่ BRAM — ใช้เป็นจุดสังเกต
--       ว่า Precision Synthesis เลือกโครงสร้างความจำอย่างไร)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sync_fifo is
  generic (
    DW : positive := 32;                    -- ความกว้างข้อมูล (บิต)
    AW : positive := 3                      -- จำนวนช่อง = 2**AW (8 ช่องเมื่อ AW = 3)
  );
  port (
    clk     : in  std_logic;
    rst_n   : in  std_logic;                -- รีเซ็ตแบบ active low

    -- ฝั่งเขียน
    wr_en   : in  std_logic;
    wr_data : in  std_logic_vector(DW-1 downto 0);
    full    : out std_logic;

    -- ฝั่งอ่าน
    rd_en   : in  std_logic;
    rd_data : out std_logic_vector(DW-1 downto 0);
    empty   : out std_logic
  );
end entity sync_fifo;

architecture rtl of sync_fifo is

  constant DEPTH : positive := 2 ** AW;

  type mem_t is array (0 to DEPTH-1) of std_logic_vector(DW-1 downto 0);
  signal mem : mem_t;

  signal wr_ptr : unsigned(AW downto 0) := (others => '0');
  signal rd_ptr : unsigned(AW downto 0) := (others => '0');

  -- ------------------------------------------------------------------
  -- แปลงเลขฐานสองเป็น Gray code: g = b xor (b srl 1)
  -- ------------------------------------------------------------------
  function bin2gray(bin : unsigned) return unsigned is
  begin
    return bin xor (bin srl 1);
  end function bin2gray;

  signal wr_gray : unsigned(AW downto 0);
  signal rd_gray : unsigned(AW downto 0);
  signal full_i  : std_logic;
  signal empty_i : std_logic;

begin

  wr_gray <= bin2gray(wr_ptr);
  rd_gray <= bin2gray(rd_ptr);

  -- เต็มเมื่อ Gray pointer ของฝั่งเขียน ตรงกับ Gray pointer ของฝั่งอ่าน
  -- ที่กลับบิตสองบิตบนสุด (invert สองบิตบนสุดของ rd_gray)
  process (wr_gray, rd_gray)
    variable cmp_v : unsigned(AW downto 0);
  begin
    cmp_v := (not rd_gray(AW downto AW-1)) & rd_gray(AW-2 downto 0);
    if wr_gray = cmp_v then
      full_i <= '1';
    else
      full_i <= '0';
    end if;

    if wr_gray = rd_gray then
      empty_i <= '1';
    else
      empty_i <= '0';
    end if;
  end process;

  full  <= full_i;
  empty <= empty_i;

  -- อ่านแบบ combinational (asynchronous read)
  rd_data <= mem(to_integer(rd_ptr(AW-1 downto 0)));

  -- ------------------------------------------------------------------
  -- ตัวชี้เขียน / อ่าน
  --
  -- ข้อควรระวัง (บั๊กที่พบระหว่างทำแล็บ): process ที่ sensitive กับ clk จะ
  -- ทำงานทุกครั้งที่ clk เปลี่ยนระดับ ทั้งขอบขึ้นและขอบลง ถ้าไม่มีเงื่อนไข
  -- rising_edge(clk) ตัวชี้จะเดินสองครั้งต่อหนึ่งรอบนาฬิกา และ FIFO จะ
  -- "เต็ม" หลังเขียนเพียงครึ่งหนึ่งของความจุ
  -- ------------------------------------------------------------------
  process (clk, rst_n)
  begin
    if rst_n = '0' then
      wr_ptr <= (others => '0');
      rd_ptr <= (others => '0');
    elsif rising_edge(clk) then
      if (wr_en = '1') and (full_i = '0') then
        wr_ptr <= wr_ptr + 1;
      end if;

      if (rd_en = '1') and (empty_i = '0') then
        rd_ptr <= rd_ptr + 1;
      end if;
    end if;
  end process;

  -- ------------------------------------------------------------------
  -- หน่วยความจำ: เขียนเมื่อ wr_en และ FIFO ไม่เต็มเท่านั้น
  -- ------------------------------------------------------------------
  process (clk)
  begin
    if rising_edge(clk) then
      if (wr_en = '1') and (full_i = '0') then
        mem(to_integer(wr_ptr(AW-1 downto 0))) <= wr_data;
      end if;
    end if;
  end process;

end architecture rtl;
