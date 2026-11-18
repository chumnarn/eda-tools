--=====================================================================
-- tb_counter.vhd -- testbench for Lab 01
------------------------------------------------------------------------
-- เรียนรู้:
--   1. การสร้างสัญญาณนาฬิกา (clock) ที่ถูกต้อง
--   2. การป้อนสติมูลัส (stimulus) แบบ sequential ใน process
--   3. การ monitor ค่าของสัญญาณและ report ออกทาง Transcript
--   4. การจบการจำลองอย่างถูกต้องด้วย std.env.finish
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity tb_counter is
end entity tb_counter;

architecture sim of tb_counter is
  constant CLK_PERIOD : time := 10 ns;

  signal clk   : std_logic := '0';
  signal rst_n : std_logic := '0';
  signal en    : std_logic := '0';
  signal up    : std_logic := '1';
  signal cnt   : std_logic_vector(7 downto 0);

  ---------------------------------------------------------------------
  -- เขียนผลการทดสอบลงไฟล์ result.txt
  --   ไฟล์นี้คือ "สัญญา" ระหว่าง testbench กับ batch runner
  --   batch runner จะอ่านไฟล์นี้เพื่อตัดสิน PASS/FAIL และส่งรหัสจบ
  --   การทำงานกลับให้ Windows
  ---------------------------------------------------------------------
  procedure write_result(constant fname : in string; constant verdict : in string) is
    file f : text;
    variable l : line;
  begin
    file_open(f, fname, write_mode);
    write(l, verdict);
    writeline(f, l);
    file_close(f);
  end procedure write_result;
begin

  ---------------------------------------------------------------------
  -- DUT
  ---------------------------------------------------------------------
  dut : entity work.counter
    generic map (
      WIDTH => 8
    )
    port map (
      clk   => clk,
      rst_n => rst_n,
      en    => en,
      up    => up,
      cnt   => cnt
    );

  ---------------------------------------------------------------------
  -- Clock : 50 MHz (period 10 ns)
  --   'not clk after CLK_PERIOD/2'  ต้องอ่าน clk ในนิพจน์
  --   จึง re-evaluate ทุกครั้งที่ clk เปลี่ยน และได้ toggle ต่อเนื่อง
  ---------------------------------------------------------------------
  clk <= not clk after CLK_PERIOD / 2;

  ---------------------------------------------------------------------
  -- Stimulus
  ---------------------------------------------------------------------
  stim : process is
  begin
    report "tb_counter : start" severity note;

    -- 1) กด reset ไว้ 3 รอบนาฬิกา
    rst_n <= '0';
    for i in 1 to 3 loop
      wait until rising_edge(clk);
    end loop;
    wait for 1 ns;
    report "tb_counter : reset released, cnt = " & to_hstring(cnt) severity note;

    -- 2) นับขึ้น 5 ครั้ง
    rst_n <= '1';
    en    <= '1';
    up    <= '1';
    for i in 1 to 5 loop
      wait until rising_edge(clk);
    end loop;
    wait for 1 ns;
    report "tb_counter : after 5 counts up, cnt = " & to_hstring(cnt) severity note;

    -- 3) หยุดนับ (en = '0') แล้วดูว่าค่าคงเดิม
    en <= '0';
    wait for 3 * CLK_PERIOD;
    report "tb_counter : while disabled, cnt = " & to_hstring(cnt) severity note;

    -- 4) นับลง 2 ครั้ง
    en <= '1';
    up <= '0';
    for i in 1 to 2 loop
      wait until rising_edge(clk);
    end loop;
    wait for 1 ns;
    report "tb_counter : after 2 counts down, cnt = " & to_hstring(cnt) severity note;

    report "TEST_PASSED : tb_counter completed" severity note;
    write_result("result.txt", "PASS");
    std.env.finish;
    wait;
  end process stim;

  ---------------------------------------------------------------------
  -- Monitor : พิมพ์ค่าของ cnt ทุกครั้งที่เปลี่ยน
  ---------------------------------------------------------------------
  mon : process is
    variable last : std_logic_vector(7 downto 0) := (others => 'X');
  begin
    wait on cnt;
    report "  [mon] t=" & time'image(now) & " cnt = " & to_hstring(cnt)
      severity note;
    last := cnt;
  end process mon;

end architecture sim;
