-- alu8.vhd — หน่วยคำนวณ 8 บิตแบบมีเครื่องหมาย (มีทะเบียนกำกับ)
--
-- ใช้เป็นตัวอย่างหลักตลอดคู่มือ Precision Synthesis:
--   บทที่ 1 — สร้างและตรวจ RTL
--   บทที่ 2 — ตั้งค่าโปรเจกต์ Precision และสังเคราะห์
--   บทที่ 3 — วิเคราะห์ QoR และย้อน critical path กลับไป HDL
--   บทที่ 4 — ส่งต่อ Vivado
--
-- ข้อสังเกตเชิงวิศวกรรมที่ตั้งใจสอนในไฟล์นี้:
--   1) ใช้ process(all) และกำหนดค่าเริ่มต้นให้ทุกเอาต์พุตทุกครั้ง
--      จึงไม่เกิด latch โดยไม่ตั้งใจ (เทียบกับ always @(*) ฝั่ง Verilog)
--   2) ความกว้างของจำนวนบิตเลื่อนคำนวณที่ elaboration time ด้วยฟังก์ชันคงที่
--      เพื่อให้แอบอิลเวอร์สังเคราะห์เป็น barrel shifter ได้จริง
--   3) การขยายสัญญาณแบบมีเครื่องหมายทำด้วย resize() ไม่ใช่การต่อบิตด้วยมือ
--   4) ไม่มี after/wait/initial ในโค้ดที่ต้องสังเคราะห์

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu8 is
  generic (
    W : positive := 8                       -- ความกว้างข้อมูล (บิต)
  );
  port (
    a        : in  signed(W-1 downto 0);     -- ตัวถูก
    b        : in  signed(W-1 downto 0);     -- ตัวคูณ
    op       : in  std_logic_vector(2 downto 0); -- รหัสคำสั่ง
    y        : out signed(W-1 downto 0);     -- ผลลัพธ์
    zero     : out std_logic;               -- ผลลัพธ์เป็นศูนย์
    overflow : out std_logic                -- เกิดขอบเขต
  );
end entity alu8;

architecture rtl of alu8 is

  -- ------------------------------------------------------------------
  -- รหัสคำสั่ง: ประกาศเป็น constant เพื่อให้ใช้ใน case ได้
  -- ------------------------------------------------------------------
  constant OP_ADD : std_logic_vector(2 downto 0) := "000";
  constant OP_SUB : std_logic_vector(2 downto 0) := "001";
  constant OP_AND : std_logic_vector(2 downto 0) := "010";
  constant OP_OR  : std_logic_vector(2 downto 0) := "011";
  constant OP_XOR : std_logic_vector(2 downto 0) := "100";
  constant OP_SLT : std_logic_vector(2 downto 0) := "101";
  constant OP_SHL : std_logic_vector(2 downto 0) := "110";
  constant OP_SHR : std_logic_vector(2 downto 0) := "111";

  -- ------------------------------------------------------------------
  -- clog2 แบบคงที่: ประเมินค่า ณ เวลาเอลาโบเรต ไม่ต้องใช้แพ็กเกจภายนอก
  -- ผลลัพธ์คงที่ จึงเขียนแล้วสังเคราะห์เป็นตัวเลขแบบตายตัวได้
  -- ------------------------------------------------------------------
  function clog2(n : positive) return positive is
    variable r : integer := 0;
    variable v : integer := n - 1;
  begin
    while v > 0 loop
      r    := r + 1;
      v    := v / 2;
    end loop;
    if r = 0 then
      r := 1;
    end if;
    return r;
  end function clog2;

  constant SHW : positive := clog2(W);      -- จำนวนบิตของค่าเลื่อน

  -- ค่าศูนย์สำหรับเปรียบเทียบ (ใช้ constant เพราะ "others" ใช้ได้เฉพาะใน
  -- aggregate assignment ไม่ได้ใน expression สำหรับการเปรียบเทียบ)
  constant ZERO_VAL : signed(W-1 downto 0) := (others => '0');

begin

  -- ------------------------------------------------------------------
  -- หน่วยคำนวณแบบ combinational
  -- ------------------------------------------------------------------
  process (all)
    variable y_v    : signed(W-1 downto 0);
    variable ov_v   : std_logic;
    variable s_v    : signed(W downto 0);    -- ผลบวก/ลบที่ขยาย 1 บิต
    variable a_ext  : signed(W downto 0);
    variable b_ext  : signed(W downto 0);
    variable sh_u   : unsigned(SHW-1 downto 0);
    variable sh_n   : natural;
  begin
    -- ค่าเริ่มต้นของทุกเอาต์พุต: กัน latch ที่โผล่เงียบ ๆ
    y_v  := (others => '0');
    ov_v := '0';

    -- ขยายสัญญาณแบบมีเครื่องหมาย 1 บิต เพื่อตรวจ overflow
    a_ext := resize(a, W+1);
    b_ext := resize(b, W+1);

    -- ค่าเลื่อนต้อง mask ก่อนเสมอ มิฉะนั้นเลื่อนเกินความกว้างข้อมูล
    -- แล้วผลจะเป็นศูนย์ทั้งหมด (บทเรียนจากบั๊กจริงในเวอร์ชัน Verilog)
    sh_u := unsigned(b(SHW-1 downto 0));
    sh_n := to_integer(sh_u);

    case op is
      when OP_ADD =>
        s_v   := a_ext + b_ext;
        y_v   := s_v(W-1 downto 0);
        if s_v(W) /= s_v(W-1) then
          ov_v := '1';
        end if;

      when OP_SUB =>
        s_v   := a_ext - b_ext;
        y_v   := s_v(W-1 downto 0);
        if s_v(W) /= s_v(W-1) then
          ov_v := '1';
        end if;

      when OP_AND =>
        y_v := a and b;

      when OP_OR =>
        y_v := a or b;

      when OP_XOR =>
        y_v := a xor b;

      when OP_SLT =>
        -- เปรียบเทียบแบบมีเครื่องหมาย: ทั้ง a และ b เป็น signed อยู่แล้ว
        if a < b then
          y_v(0) := '1';
        end if;

      when OP_SHL =>
        -- เลื่อนซ้ายเชิงตรรกะ: ศูนย์เข้ามาทางขวา (เติม 0 ทางขวา)
        y_v := shift_left(a, sh_n);

      when OP_SHR =>
        -- เลื่อนขวาเชิงอารีเมติก: คงเครื่องหมายไว้
        y_v := shift_right(a, sh_n);

      when others =>
        y_v := (others => '0');
    end case;

    y        <= y_v;
    overflow <= ov_v;
    if y_v = ZERO_VAL then
      zero <= '1';
    else
      zero <= '0';
    end if;
  end process;

end architecture rtl;
