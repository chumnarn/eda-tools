--=====================================================================
-- tb_x.vhd  --  testbench ของ Lab 06 (dataflow / หาสาเหตุ X)
--=====================================================================
--   เรียนรู้ :
--   1) X (U) ตอน t=0 ของ register ที่ไม่มี initial value เป็นเรื่องปกติ
--   2) X ที่ยังอยู่หลัง reset แปลว่ามีบั๊กจริง
--   3) วิธีแยกว่า X มาจากสัญญาณใด : ดูทีละชั้นของ hierarchy
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity tb_x is
end entity tb_x;

architecture sim of tb_x is
  constant CYCLE : time := 10 ns;

  signal clk : std_logic := '0';
  signal rst : std_logic := '0';
  signal a   : std_logic_vector(7 downto 0) := (others => '0');
  signal b   : std_logic_vector(7 downto 0) := (others => '0');

  signal eq  : std_logic;
  signal eq2 : std_logic;
  signal sum : std_logic_vector(8 downto 0);

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

  dut : entity work.x_demo
    port map (
      clk => clk,
      rst => rst,
      a   => a,
      b   => b,
      eq  => eq,
      eq2 => eq2,
      sum => sum
    );

  stim : process is
    variable errors : integer := 0;
  begin
    report "===========================================================" severity note;
    report " X-propagation demo" severity note;
    report "===========================================================" severity note;

    -- (1) ก่อน reset : acc ยังไม่เคยถูกเขียน -> เป็น U ------------------
    wait for 1 ns;
    report " t=1ns (no reset yet) : sum = " & to_hstring(sum) &
           "  eq = " & std_logic'image(eq) &
           "  eq2 = " & std_logic'image(eq2) severity note;
    report "   -> X here is NORMAL (register not initialised yet)" severity note;
    report "   -> eq  uses '=' so it stays '0' even with X" severity note;
    report "   -> eq2 uses xor so the X propagates" severity note;

    -- (2) reset ------------------------------------------------------------
    rst <= '1';
    wait for 2 * CYCLE;
    rst <= '0';
    a   <= x"12";
    b   <= x"34";
    wait for 3 * CYCLE;

    report " after reset          : sum = " & to_hstring(sum) &
           "  eq = " & std_logic'image(eq) severity note;
    report "                        eq2 = " & std_logic'image(eq2) severity note;

    -- (3) ตรวจว่าสัญญาณที่ "ควรหาย" หายจริงหรือยัง -------------------
    --     sum ต้องเป็นค่าที่รู้ (0x12 + 0x34 = 0x46)
    if is_x(sum) then
      errors := errors + 1;
      report "FAIL: sum is still unknown after reset" severity error;
    else
      -- sum = acc + b = 0x46 + 0x34 = 0x7A = 9 บิต => 001111010
      assert sum = "001111010"
        report "FAIL: sum wrong, got " & to_hstring(sum) severity error;
      if sum /= "001111010" then errors := errors + 1; end if;
    end if;

    --     eq2 ยังเป็น U เสมอ เพราะ never_driven ไม่เคยถูก assign
    if not is_x(eq2) then
      errors := errors + 1;
      report "FAIL: eq2 should still be unknown" severity error;
    else
      report "   -> eq2 is X forever : root cause is never_driven" &
             " which is never assigned (this is the bug)" severity note;
    end if;

    report "===========================================================" severity note;
    report " errors = " & integer'image(errors)                      severity note;
    report "===========================================================" severity note;

    if errors = 0 then
      report "TEST_PASSED : lab06_dataflow" severity note;
      write_result("result.txt", "PASS");
    else
      report "TEST FAILED : " & integer'image(errors) & " error(s)" severity error;
      write_result("result.txt", "FAIL");
    end if;

    std.env.finish;
    wait;
  end process stim;

end architecture sim;
