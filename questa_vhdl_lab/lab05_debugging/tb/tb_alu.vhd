--=====================================================================
-- tb_alu.vhd  --  testbench ของ Lab 05 (debugging)
--=====================================================================
--   ผลลัพธ์ที่คาดหวัง : จะ FAIL เพราะ ALU มีบั๊ก
--   นักเรียนต้องใช้ breakpoint + examine หาเส้นที่ผิด
--
--   หมายเหตุ : บรรทัดของ vector ที่ทำให้พังถูกทำเครื่องหมายไว้
--               เพื่อให้เห็นว่า "ไม่ใช่ทุก testcase จะพัง"
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity tb_alu is
end entity tb_alu;

architecture sim of tb_alu is

  -- ข้อความอธิบายแต่ละเคส : ใช้ enumerated type แทน string เพราะ
  -- array ของ unconstrained string ใน VHDL-2008 ต้องมีความยาวเท่ากัน
  -- ทุกช่อง (ModelSim บังคับ) และ string ต้องใช้ index เป็น POSITIVE
  -- จึงห้ามเขียน string(0 to n)
  type note_id_t is (N_ADD, N_SUB, N_AND, N_OR);

  function note_text(n : note_id_t) return string is
  begin
    case n is
      when N_ADD => return "ADD ok";
      when N_SUB => return "SUB exposes the bug";
      when N_AND => return "AND ok";
      when N_OR  => return "OR ok";
    end case;
  end function note_text;

  type vector_t is record
    op  : std_logic_vector(1 downto 0);
    a   : std_logic_vector(7 downto 0);
    b   : std_logic_vector(7 downto 0);
    exp : std_logic_vector(7 downto 0);
    id  : note_id_t;
  end record;

  type vector_array is array (natural range <>) of vector_t;

  constant VECTORS : vector_array := (
    (op => "00", a => x"0A", b => x"05", exp => x"0F", id => N_ADD),
    (op => "01", a => x"0A", b => x"05", exp => x"05", id => N_SUB),
    (op => "10", a => x"F0", b => x"3C", exp => x"30", id => N_AND),
    (op => "11", a => x"F0", b => x"3C", exp => x"FC", id => N_OR)
  );

  signal a    : std_logic_vector(7 downto 0) := (others => '0');
  signal b    : std_logic_vector(7 downto 0) := (others => '0');
  signal op   : std_logic_vector(1 downto 0) := "00";
  signal y    : std_logic_vector(7 downto 0);
  signal zero : std_logic;

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

  dut : entity work.alu
    port map (
      a    => a,
      b    => b,
      op   => op,
      y    => y,
      zero => zero
    );

  stim : process is
    variable errors : integer := 0;
    variable checks : integer := 0;
  begin
    report "--------------------------------------------------" severity note;
    report " tb_alu : start" severity note;
    report "--------------------------------------------------" severity note;

    for i in VECTORS'range loop
      -- ใส่ค่าแล้วรอ 1 ns ให้ combinational logic คำนวณเสร็จ
      a  <= VECTORS(i).a;
      b  <= VECTORS(i).b;
      op <= VECTORS(i).op;
      wait for 1 ns;

      checks := checks + 1;
      if y /= VECTORS(i).exp then
        errors := errors + 1;
        report "FAIL : op=" & to_hstring(VECTORS(i).op) &
               " a=" & to_hstring(VECTORS(i).a) &
               " b=" & to_hstring(VECTORS(i).b) &
               " expected=" & to_hstring(VECTORS(i).exp) &
               " got=" & to_hstring(y) &
               "   [" & note_text(VECTORS(i).id) & "]" severity error;
      else
        report "PASS : op=" & to_hstring(VECTORS(i).op) &
               " got=" & to_hstring(y) severity note;
      end if;
    end loop;

    report "--------------------------------------------------" severity note;
    report " checks = " & integer'image(checks) &
           " , errors = " & integer'image(errors) severity note;
    report "--------------------------------------------------" severity note;

    if errors = 0 then
      report "TEST_PASSED : lab05_debugging" severity note;
      write_result("result.txt", "PASS");
    else
      report "TEST FAILED : " & integer'image(errors) & " error(s)" severity error;
      write_result("result.txt", "FAIL");
    end if;

    std.env.finish;
    wait;
  end process stim;

end architecture sim;
