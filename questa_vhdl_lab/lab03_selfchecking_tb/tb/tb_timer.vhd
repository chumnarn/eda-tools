--=====================================================================
-- tb_timer.vhd  --  testbench แบบ "ตรวจตัวเอง" (self-checking)
--=====================================================================
--   เรียนรู้ :
--   1. severity ของ assert : note / warning / error / failure
--   2. นับจำนวน error ด้วย VARIABLE (ไม่ใช่ signal)
--   3. Moore output ต้องตรวจหลังขอบขึ้นของนาฬิกา 1 ns
--      (ถ้าตรวจทันทีที่ขอบขึ้น จะเห็นค่าของรอบก่อนหน้า -> เพี้ยนทั้งชุด)
--   4. รายงานสรุปและส่ง exit code กลับให้ batch runner
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity tb_timer is
  generic (
    INJECT_ERROR : boolean := false   -- true = จงใจให้ check หนึ่งอัน fail
  );
end entity tb_timer;

architecture sim of tb_timer is
  constant CYCLE : time := 10 ns;

  signal clk   : std_logic := '0';
  signal rst   : std_logic := '0';
  signal start : std_logic := '0';

  signal cnt  : std_logic_vector(1 downto 0);
  signal done : std_logic;

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

  clk <= not clk after CYCLE / 2;

  dut : entity work.fsm_timer
    port map (
      clk   => clk,
      rst   => rst,
      start => start,
      cnt   => cnt,
      done  => done
    );

  ---------------------------------------------------------------------
  -- Stimulus + checker
  ---------------------------------------------------------------------
  stim : process is
    variable errors  : integer := 0;   -- ใช้ variable เสมอ ไม่ใช่ signal
    variable checks  : integer := 0;
    variable exp_cnt : std_logic_vector(1 downto 0);
  begin
    report "--------------------------------------------------" severity note;
    report " tb_timer : start"                            severity note;
    report "--------------------------------------------------" severity note;

    -- (1) reset ---------------------------------------------------------
    rst <= '1';
    wait for 2 * CYCLE;
    rst <= '0';

    checks  := checks + 1;
    assert cnt = "00"
      report "FAIL: cnt is not 00 after reset, got " & to_hstring(cnt)
      severity error;
    if cnt /= "00" then errors := errors + 1; end if;

    -- (2) เริ่มทำงาน : สั่ง start ----------------------------------------
    --     ที่ขอบขึ้นนี้ FSM จะเปลี่ยนจาก ST_IDLE เป็น ST_RUN และ cnt ยังเป็น 00
    start <= '1';
    wait until rising_edge(clk);
    wait for 1 ns;                     -- <<< สำคัญ : Moore ต้องรอ 1 ns
    checks  := checks + 1;
    assert done = '0'
      report "FAIL: done asserted too early"
      severity error;
    if done /= '0' then errors := errors + 1; end if;

    checks := checks + 1;
    assert cnt = "00"
      report "FAIL: cnt should be 00 just after start, got " & to_hstring(cnt)
      severity error;
    if cnt /= "00" then errors := errors + 1; end if;

    -- (3) นับขึ้น 1,2,3 --------------------------------------------------
    --     ทุกขอบขึ้นที่ผ่านไป cnt จะเพิ่มขึ้น 1 (Moore จึงเห็นค่าใหม่หลัง 1 ns)
    for i in 1 to 3 loop
      exp_cnt := std_logic_vector(to_unsigned(i, 2));
      wait until rising_edge(clk);
      wait for 1 ns;                   -- <<< สำคัญ : ตรวจหลังขอบขึ้น 1 ns
      checks := checks + 1;
      assert cnt = exp_cnt
        report "FAIL: cnt expected " & to_hstring(exp_cnt) &
               " got " & to_hstring(cnt)
        severity error;
      if cnt /= exp_cnt then errors := errors + 1; end if;
    end loop;

    -- (4) ต้องเข้า ST_DONE : done = '1' ----------------------------------
    wait until rising_edge(clk);
    wait for 1 ns;
    checks := checks + 1;
    assert done = '1'
      report "FAIL: done not asserted at end of sequence"
      severity error;
    if done /= '1' then errors := errors + 1; end if;

    -- (5) จงใจสร้าง error เพื่อสาธิต severity failure -------------------
    --     เขียนผล FAIL ลง result.txt ก่อน เพราะ severity failure จะหยุด
    --     process ตรงนี้ บรรทัดสรุปผลข้างล่างจะไม่ได้ทำงานเลย
    if INJECT_ERROR then
      checks := checks + 1;
      write_result("result.txt", "FAIL");
      assert false
        report "FAIL: injected error (INJECT_ERROR = true)"
        severity failure;
    end if;

    -- (6) สรุปผล --------------------------------------------------------
    report "--------------------------------------------------" severity note;
    report " checks = " & integer'image(checks) &
           " , errors = " & integer'image(errors)        severity note;
    report "--------------------------------------------------" severity note;

    if errors = 0 then
      report "TEST_PASSED : lab03_selfchecking_tb" severity note;
      write_result("result.txt", "PASS");
    else
      report "TEST FAILED : " & integer'image(errors) & " error(s)" severity error;
      write_result("result.txt", "FAIL");
    end if;

    std.env.finish;
    wait;
  end process stim;

end architecture sim;
