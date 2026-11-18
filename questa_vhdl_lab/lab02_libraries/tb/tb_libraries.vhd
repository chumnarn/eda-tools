--=====================================================================
-- tb_libraries.vhd  --  testbench ของ Lab 02
--   จุดประสงค์ : ยืนยันว่า DUT ที่เรียกใช้ design unit จาก 2 ไลบรารี
--                (work และ ip_lib) ทำงานถูกต้อง
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

use work.adder_pkg.all;

entity tb_libraries is
end entity tb_libraries;

architecture sim of tb_libraries is
  constant CYCLE : time := 10 ns;

  signal clk : std_logic := '0';
  signal rst : std_logic := '0';
  signal en  : std_logic := '0';

  signal value : std_logic_vector(7 downto 0);
  signal par   : std_logic;

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

  dut : entity work.counter_top
    generic map (
      WIDTH => 8
    )
    port map (
      clk   => clk,
      rst   => rst,
      en    => en,
      value => value,
      par   => par
    );

  stim : process is
  begin
    report "==============================================" severity note;
    report " adder_pkg version = " & PKG_VERSION         severity note;
    report "==============================================" severity note;

    -- reset
    rst <= '1';
    wait for 2 * CYCLE;
    rst <= '0';

    -- นับ 6 ครั้ง
    en <= '1';
    for i in 1 to 6 loop
      wait until rising_edge(clk);
    end loop;
    wait for 1 ns;

    report "value  = " & to_hex(unsigned(value))         severity note;
    report "parity = " & std_logic'image(par)            severity note;

    -- ตรวจค่า : หลัง reset แล้วนับ 6 ครั้ง ต้องได้ 6
    assert value = "00000110"
      report "value mismatch, expected 06, got " & to_hex(unsigned(value))
      severity failure;

    report "TEST_PASSED : lab02_libraries" severity note;
    write_result("result.txt", "PASS");
    std.env.finish;
    wait;
  end process stim;

  mon : process is
  begin
    wait on par;
    report "  [mon] t=" & time'image(now) &
           " value=" & to_hex(unsigned(value)) &
           " parity=" & std_logic'image(par) severity note;
  end process mon;

end architecture sim;
