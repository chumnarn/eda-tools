-- tb_int8_mac.vhd — testbench แบบตรวจตัวเองสำหรับ int8_mac
--
-- สิ่งที่ตรวจ
--   1) เฟส 1: ส่ง 40 ค่าแบบไม่มี backpressure -> ผลลัพธ์ต้องเป็นผลสะสม
--      ของผลคูณตามลำดับ (out[k] = prod[0] + ... + prod[k])
--   2) เฟส 2: สั่ง acc_clear แล้วต้องเริ่มสะสมใหม่จากศูนย์
--   3) เฟส 3: ส่ง 20 ค่าแบบมี backpressure สุ่ม -> ต้องไม่มีข้อมูลหาย
--      และลำดับยังถูกต้อง
--
-- วิธีตรวจ handshake ที่ถูกต้อง
--   process ที่ sensitive กับ clk จะเห็นค่าของสัญญาณ combinational ณ ขอบขึ้น
--   ในช่วงก่อนหน้า (ค่า pre-edge) ซึ่งตรงกับค่าที่ DUT ใช้ตัดสินใจ
--   ถ้าใช้ wait until rising_edge(clk) ใน process ที่ไม่ sensitive กับ clk
--   จะได้ค่า post-edge ซึ่งผิดไปหนึ่งรอบ -> ตรวจผิดพลาดปลอม
--
-- วิธีรัน
--   ModelSim / QuestaSim:
--     vlib work
--     vcom -2008 ../rtl/int8_mac.vhd
--     vcom -2008 tb_int8_mac.vhd
--     vsim -c work.tb_int8_mac -do "run -all; quit -f"
--
--   GHDL:
--     ghdl -a --std=08 rtl/int8_mac.vhd
--     ghdl -a --std=08 tb/tb_int8_mac.vhd
--     ghdl -e --std=08 tb_int8_mac
--     ghdl -r --std=08 tb_int8_mac --assert-level=error

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_int8_mac is
end entity tb_int8_mac;

architecture sim of tb_int8_mac is

  constant CLK_PERIOD : time := 10 ns;

  signal clk       : std_logic := '0';
  signal rst_n     : std_logic := '0';
  signal tvalid    : std_logic := '0';
  signal tready    : std_logic;
  signal tdata     : std_logic_vector(15 downto 0) := (others => '0');
  signal svalid    : std_logic;
  signal sready    : std_logic := '1';
  signal sdata     : std_logic_vector(31 downto 0);
  signal acc_clear : std_logic := '0';
  signal bp_en     : std_logic := '0';

  signal accept_cnt : integer := 0;
  signal out_cnt    : integer := 0;

begin

  clk <= not clk after CLK_PERIOD/2;

  dut : entity work.int8_mac
    port map (
      clk       => clk,
      rst_n     => rst_n,
      tvalid    => tvalid,
      tready    => tready,
      tdata     => tdata,
      svalid    => svalid,
      sready    => sready,
      sdata     => sdata,
      acc_clear => acc_clear
    );

  ------------------------------------------------------------------
  -- โมนิเตอร์: ตรวจ handshake และเก็บค่าที่คาดหวังไว้เป็นคิว
  ------------------------------------------------------------------
  mon : process (clk)
    type q_t is array (0 to 1023) of integer;
    variable q     : q_t;
    variable qh    : integer := 0;
    variable qt    : integer := 0;
    variable exp_s : integer := 0;
    variable prod  : integer;
    variable got   : integer;
    variable exp_v : integer;
  begin
    if rising_edge(clk) then
      -- (1) ผลลัพธ์ที่ถูกรับออกไปในรอบนาฬิกานี้
      if (svalid = '1') and (sready = '1') then
        got  := to_integer(signed(sdata));
        exp_v := q(qh);
        qh   := qh + 1;
        if got /= exp_v then
          assert false
            report "MISMATCH sdata: got=" & integer'image(got) &
                   " exp=" & integer'image(exp_v) severity failure;
        end if;
        out_cnt <= out_cnt + 1;
      end if;

      -- (2) มีการรับข้อมูลเข้า -> คำนวณผลสะสมที่คาดหวังแล้วเข้าคิว
      if acc_clear = '1' then
        exp_s := 0;
      elsif (tvalid = '1') and (tready = '1') then
        prod := to_integer(signed(tdata(15 downto 8))) *
                to_integer(signed(tdata(7 downto 0)));
        exp_s := exp_s + prod;
        q(qt) := exp_s;
        qt    := qt + 1;
        accept_cnt <= accept_cnt + 1;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------
  -- ตัวสร้าง backpressure แบบสุ่มแบบกำหนดได้ (LFSR 16 บิต)
  ------------------------------------------------------------------
  lfsr_p : process (clk)
    variable lfsr : unsigned(15 downto 0) := x"ACE1";
  begin
    if rising_edge(clk) then
      lfsr := lfsr(14 downto 0) &
              (lfsr(15) xor lfsr(13) xor lfsr(12) xor lfsr(10));
      if bp_en = '1' then
        sready <= lfsr(3) or lfsr(1);
      else
        sready <= '1';
      end if;
    end if;
  end process;

  ------------------------------------------------------------------
  -- แรงกระตุ้น
  ------------------------------------------------------------------
  stim : process
    variable sent   : integer := 0;
    variable a_v    : integer;
    variable b_v    : integer;
  begin
    rst_n <= '0';
    wait for 5 * CLK_PERIOD;
    rst_n <= '1';
    wait until rising_edge(clk);

    ------------------------------------------------------------------
    -- เฟส 1: 40 ค่า ไม่มี backpressure
    ------------------------------------------------------------------
    bp_en <= '0';
    for i in 0 to 39 loop
      a_v := ((i * 7) mod 256) - 128;
      b_v := ((i * 13 + 5) mod 256) - 128;
      tdata  <= std_logic_vector(to_signed(a_v, 8) & to_signed(b_v, 8));
      tvalid <= '1';
      wait until accept_cnt = sent + 1;
      sent := sent + 1;
      tvalid <= '0';
    end loop;

    ------------------------------------------------------------------
    -- เฟส 2: สั่งล้างตัวสะสม แล้วต้องเริ่มนับใหม่
    ------------------------------------------------------------------
    wait until out_cnt = accept_cnt;      -- รอให้ไปป์ไลน์ว่าง
    wait until rising_edge(clk);
    acc_clear <= '1';
    wait until rising_edge(clk);
    wait for 1 ns;
    acc_clear <= '0';

    for i in 0 to 9 loop
      a_v := ((i * 11 + 3) mod 256) - 128;
      b_v := ((i * 17 + 9) mod 256) - 128;
      tdata  <= std_logic_vector(to_signed(a_v, 8) & to_signed(b_v, 8));
      tvalid <= '1';
      wait until accept_cnt = sent + 1;
      sent := sent + 1;
      tvalid <= '0';
    end loop;

    ------------------------------------------------------------------
    -- เฟส 3: 20 ค่า พร้อม backpressure สุ่ม
    ------------------------------------------------------------------
    wait until out_cnt = accept_cnt;
    bp_en <= '1';
    for i in 0 to 19 loop
      a_v := ((i * 23 + 7) mod 256) - 128;
      b_v := ((i * 29 + 13) mod 256) - 128;
      tdata  <= std_logic_vector(to_signed(a_v, 8) & to_signed(b_v, 8));
      tvalid <= '1';
      wait until accept_cnt = sent + 1;
      sent := sent + 1;
      tvalid <= '0';
    end loop;

    ------------------------------------------------------------------
    -- รอให้ผลลัพธ์สุดท้ายออกครบ
    ------------------------------------------------------------------
    wait until out_cnt = accept_cnt;
    wait for 2 * CLK_PERIOD;

    report "tb_int8_mac: sent " & integer'image(sent) &
           " transactions, received " & integer'image(out_cnt)
      severity note;

    assert out_cnt = sent
      report "FAIL: transaction count mismatch" severity failure;

    report "PASS" severity note;
    stop;

    wait;
  end process;

end architecture sim;
