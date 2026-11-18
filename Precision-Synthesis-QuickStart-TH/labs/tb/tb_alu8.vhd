-- tb_alu8.vhd — testbench แบบตรวจตัวเอง (self-checking) สำหรับ alu8
--
-- วิธีตรวจ
--   1) ไล่ค่า a ทั้ง 256 ค่า
--   2) ใช้ค่า b ที่ "เลือกมาเพื่อชนกรณีเลข" (0,1,7,8,15,127,128,255 ฯลฯ)
--   3) ทดสอบทั้ง 8 คำสั่ง
--   4) เทียบผลกับแบบจำลองอ้างอิงใน alu_ref_pkg (คนละวิธีคำนวณกับ RTL)
--   5) ตรวจแฟล็ก zero และ overflow ด้วย
--
-- ข้อควรรู้: ภาษา VHDL อนุญาตอักขระได้เฉพาะ basic character set ใน string
-- literal จึงเขียนข้อความใน report เป็นภาษาอังกฤษ ส่วนคำอธิบายภาษาไทย
-- ไว้ใน comment ได้ตามปกติ (ข้อควรระวังนี้พบระหว่างทำแล็บจริง)
--
-- วิธีรัน
--   ModelSim / QuestaSim:
--     vlib work
--     vcom -2008 ../tb/alu_ref_pkg.vhd
--     vcom -2008 ../rtl/alu8.vhd
--     vcom -2008 tb_alu8.vhd
--     vsim -c work.tb_alu8 -do "run -all; quit -f"
--
--   GHDL (ตรวจได้ฟรีบนเครื่องที่ไม่มีใบอนุญาต):
--     ghdl -a --std=08 --workdir=build ../tb/alu_ref_pkg.vhd
--     ghdl -a --std=08 --workdir=build ../rtl/alu8.vhd
--     ghdl -a --std=08 --workdir=build tb_alu8.vhd
--     ghdl -e --std=08 --workdir=build tb_alu8
--     ghdl -r --std=08 --workdir=build tb_alu8 --assert-level=error

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.alu_ref_pkg.all;

entity tb_alu8 is
end entity tb_alu8;

architecture sim of tb_alu8 is

  signal a_s     : signed(7 downto 0) := (others => '0');
  signal b_s     : signed(7 downto 0) := (others => '0');
  signal op_s    : std_logic_vector(2 downto 0) := (others => '0');
  signal y_s     : signed(7 downto 0);
  signal zero_s  : std_logic;
  signal ovf_s   : std_logic;

begin

  dut : entity work.alu8
    port map (
      a        => a_s,
      b        => b_s,
      op       => op_s,
      y        => y_s,
      zero     => zero_s,
      overflow => ovf_s
    );

  stim : process
    type b_list_t is array (natural range <>) of integer;
    constant B_LIST : b_list_t := (
      0, 1, 2, 3, 4, 5, 6, 7, 8,
      9, 15, 16, 31, 63, 64, 100,
      126, 127, 128, 129, 200, 254, 255);

    variable y_exp    : std_logic_vector(7 downto 0);
    variable ovf_exp  : std_logic;
    variable zero_exp : std_logic;
    variable a_v      : integer;
    variable b_v      : integer;
    variable op_v     : std_logic_vector(2 downto 0);
    variable n_err    : integer := 0;
    variable n_chk    : integer := 0;
  begin
    for ai in 0 to 255 loop
      for bi in B_LIST'range loop
        for oi in 0 to 7 loop
          a_v  := ai;
          b_v  := B_LIST(bi);
          op_v := std_logic_vector(to_unsigned(oi, 3));

          -- แบบจำลองอ้างอิงตีความค่าเป็นเลขมีเครื่องหมาย
          -- (RTL เห็นเป็นรูปแบบบิต จึงต้องแปลงก่อนส่งเข้าแบบจำลอง)
          a_v := int_of(byte_of(a_v));
          b_v := int_of(byte_of(b_v));

          ref_alu(a_v, b_v, op_v, y_exp, ovf_exp, zero_exp);

          a_s  <= signed(byte_of(a_v));
          b_s  <= signed(byte_of(b_v));
          op_s <= op_v;
          wait for 1 ns;

          n_chk := n_chk + 1;

          if std_logic_vector(y_s) /= y_exp then
            n_err := n_err + 1;
            if n_err <= 10 then
              report "MISMATCH y: a=" & integer'image(a_v) &
                     " b=" & integer'image(b_v) &
                     " op=" & integer'image(oi) &
                     " got=" & to_hstring(std_logic_vector(y_s)) &
                     " exp=" & to_hstring(y_exp)
                severity error;
            end if;
          end if;

          if ovf_s /= ovf_exp then
            n_err := n_err + 1;
            if n_err <= 10 then
              report "MISMATCH overflow: a=" & integer'image(a_v) &
                     " b=" & integer'image(b_v) &
                     " op=" & integer'image(oi) &
                     " got=" & std_logic'image(ovf_s) &
                     " exp=" & std_logic'image(ovf_exp)
                severity error;
            end if;
          end if;

          if zero_s /= zero_exp then
            n_err := n_err + 1;
            if n_err <= 10 then
              report "MISMATCH zero: a=" & integer'image(a_v) &
                     " b=" & integer'image(b_v) &
                     " op=" & integer'image(oi)
                severity error;
            end if;
          end if;
        end loop;
      end loop;
    end loop;

    report "tb_alu8: checked " & integer'image(n_chk) &
           " cases, errors " & integer'image(n_err)
      severity note;

    if n_err = 0 then
      report "PASS" severity note;
      stop;
    else
      assert false report "FAIL: " & integer'image(n_err) & " mismatches"
        severity failure;
    end if;

    wait;
  end process;

end architecture sim;
