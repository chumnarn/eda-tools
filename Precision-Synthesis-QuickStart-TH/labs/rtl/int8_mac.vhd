-- int8_mac.vhd — หน่วยคูณสะสม INT8 แบบมีสัญญาณไหล (AXI-Stream ย่อ)
--
-- หลักการที่สอนในไฟล์นี้
--   1) แบ่ง pipeline 2 ขั้น: คูณ -> สะสม เพื่อลดคาบเวลาและรับได้ 1 ค่า/รอบนาฬิกา
--   2) backpressure: ผู้ส่งต้องคง tvalid และ tdata ไว้จนกว่า tready จะเป็น 1
--   3) tready สื่อว่า "ขั้นที่ 1 รับข้อมูลได้ทันที" ไม่ใช่ "ผลลัพธ์พร้อม"
--   4) ตัวคูณ 8x8 ใน VHDL ให้ผลเป็น signed ความกว้าง 16 บิตโดยอัตโนมัติ
--      และสังเคราะห์เป็น DSP48E1 ได้ในบอร์ด Nexys A7-100T

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity int8_mac is
  generic (
    DATA_W : positive := 16;                -- ข้อมูลเข้า: {a[7:0], b[7:0]} แบบมีเครื่องหมาย
    ACC_W  : positive := 32                 -- ความกว้างตัวสะสมและผลลัพธ์
  );
  port (
    clk      : in  std_logic;
    rst_n    : in  std_logic;

    -- ช่องทางเข้า
    tvalid   : in  std_logic;
    tready   : out std_logic;
    tdata    : in  std_logic_vector(DATA_W-1 downto 0);

    -- ช่องทางออก
    svalid   : out std_logic;
    sready   : in  std_logic;
    sdata    : out std_logic_vector(ACC_W-1 downto 0);

    -- สั่งล้างตัวสะสม (มีผลทันทีในรอบนาฬิกาปัจจุบัน)
    acc_clear : in  std_logic
  );
end entity int8_mac;

architecture rtl of int8_mac is

  constant PRODUCT_W : positive := 16;     -- ผลคูณ 8 x 8 ต้องใช้ 16 บิต

  -- ขั้นที่ 1: คูณ
  signal v_s1  : std_logic := '0';
  signal p_s1  : signed(PRODUCT_W-1 downto 0) := (others => '0');

  -- ขั้นที่ 2: สะสม
  signal acc       : signed(ACC_W-1 downto 0) := (others => '0');
  signal svalid_r  : std_logic := '0';
  signal sdata_r   : std_logic_vector(ACC_W-1 downto 0) := (others => '0');

  -- ขั้นที่ 2 พร้อมรับผลลัพธ์เมื่อไม่มีผลค้าง หรือผลค้างถูกรับออกไปแล้ว
  signal s2_ready : std_logic;

  -- ท่อส่งผ่านมีจุดเดียว จึงเชื่อม tready กับ s2_ready ได้เลย
  signal p_in : signed(PRODUCT_W-1 downto 0);

  signal acc_base : signed(ACC_W-1 downto 0);
  signal acc_sum  : signed(ACC_W-1 downto 0);

begin

  s2_ready <= (not svalid_r) or sready;
  tready   <= s2_ready;

  -- ตัวคูณ 8x8 แบบมีเครื่องหมาย: ผลลัพธ์กว้าง 16 บิตโดยอัตโนมัติ
  p_in <= signed(tdata(DATA_W-1 downto 8)) * signed(tdata(7 downto 0));

  -- ค่าตัวสะสมก่อนอัปเดตในรอบนี้ (acc_clear มีผลทันที)
  process (acc_clear, acc)
  begin
    if acc_clear = '1' then
      acc_base <= (others => '0');
    else
      acc_base <= acc;
    end if;
  end process;

  -- ผลรวมของรอบนี้: ตัวสะสมเดิม + ผลคูณที่ค้างอยู่ในขั้นที่ 1
  acc_sum <= acc_base + resize(p_s1, ACC_W);

  -- ------------------------------------------------------------------
  -- บันทึกสถานะ
  --
  -- ข้อควรระวัง (บั๊กที่พบระหว่างทำแล็บ): ต้องมี rising_edge(clk) เสมอ
  -- มิฉะนั้น process จะทำงานทั้งขอบขึ้นและขอบลง ทำให้ตัวสะสมถูกบวก
  -- ซ้ำสองรอบต่อหนึ่งรอบนาฬิกา และผลลัพธ์จะเป็นสองเท่าของที่ควรเป็น
  -- ------------------------------------------------------------------
  process (clk, rst_n)
  begin
    if rst_n = '0' then
      v_s1     <= '0';
      p_s1     <= (others => '0');
      acc      <= (others => '0');
      svalid_r <= '0';
      sdata_r  <= (others => '0');
    elsif rising_edge(clk) then
      -- จับข้อมูลเข้าขั้นที่ 1
      if (tvalid = '1') and (s2_ready = '1') then
        p_s1  <= p_in;
        v_s1  <= '1';
      elsif s2_ready = '1' then
        -- ข้อมูลในขั้นที่ 1 ถูกขั้นที่ 2 รับไปแล้ว -> ว่าง
        v_s1 <= '0';
      end if;

      -- สะสมเข้าตัวสะสม
      if acc_clear = '1' then
        acc <= (others => '0');
      elsif (v_s1 = '1') and (s2_ready = '1') then
        acc <= acc_sum;
      end if;

      -- ส่งผลลัพธ์ออก
      if s2_ready = '1' then
        svalid_r <= v_s1;
        if v_s1 = '1' then
          sdata_r <= std_logic_vector(acc_sum);
        end if;
      end if;
    end if;
  end process;

  svalid <= svalid_r;
  sdata  <= sdata_r;

end architecture rtl;
