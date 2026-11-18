--=====================================================================
-- tb_stimulus.vhd -- LAB 08 : advanced stimulus
--                     (file based, random and parameterised)
------------------------------------------------------------------------
-- The testbench has three parts:
--
--   phase 1  file based stimulus
--            reads "vectors.txt" with std.textio, applies every vector
--            to the register file and compares the read back value with
--            the expected value that is written in the same file.
--
--   phase 2  random stimulus
--            uses ieee.math_real.uniform with TWO seeds.  The sequence
--            is generated twice with the same seed pair, to show that
--            the same seed pair always reproduces the same sequence.
--
--   phase 3  parameterisation
--            the generics below can be overridden from the command line
--            with vsim -g<NAME>=<value>
--
-- IMPORTANT : hread only reads into a BIT_VECTOR, never into a
--              std_logic_vector.  That is why the data path of the DUT
--              (src/ram8.vhd) uses bit_vector.
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
library std;
use std.textio.all;

entity tb_stimulus is
  generic (
    VECTOR_FILE : string   := "vectors.txt";   -- name of the vector file
    NUM_RANDOM  : integer  := 8;               -- number of random vectors
    SEED1       : positive := 12345;           -- first  seed of uniform
    SEED2       : positive := 67890            -- second seed of uniform
  );
end entity tb_stimulus;

architecture sim of tb_stimulus is
  constant CLK_PERIOD : time := 10 ns;

  signal clk  : std_logic := '0';
  signal we   : std_logic := '0';
  signal addr : std_logic_vector(3 downto 0) := (others => '0');
  signal din  : bit_vector(7 downto 0) := (others => '0');
  signal dout : bit_vector(7 downto 0);

  signal n_vec_read : natural := 0;
  signal n_vec_pass : natural := 0;
  signal n_vec_fail : natural := 0;
  signal n_rnd_pass : natural := 0;
  signal n_rnd_fail : natural := 0;

  ---------------------------------------------------------------------
  -- write the verdict into result.txt so that the batch runner does not
  -- have to read the transcript file (which can be locked by the
  -- simulator when the design is re-loaded)
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

  -- integer <-> bit_vector helpers (bit_vector and std_logic_vector are
  -- NOT convertible types, the conversion functions of std_logic_1164
  -- have to be used)
  function int_to_bv(v : integer) return bit_vector is
  begin
    return To_BitVector(To_StdULogicVector(std_logic_vector(to_unsigned(v, 8))));
  end function int_to_bv;

  function bv_to_int(b : bit_vector) return integer is
  begin
    return to_integer(unsigned(To_StdLogicVector(To_StdULogicVector(b))));
  end function bv_to_int;
begin

  ---------------------------------------------------------------------
  -- 50 MHz clock
  ---------------------------------------------------------------------
  clk <= not clk after CLK_PERIOD / 2;

  ---------------------------------------------------------------------
  -- DUT : 16 x 8 register file with a bit_vector data path
  ---------------------------------------------------------------------
  dut : entity work.ram8
    generic map (
      ADDR_WIDTH => 4
    )
    port map (
      clk  => clk,
      we   => we,
      addr => addr,
      din  => din,
      dout => dout
    );

  ---------------------------------------------------------------------
  -- Stimulus
  ---------------------------------------------------------------------
  stim : process is
    file          f       : text;
    variable      l       : line;
    variable      addr_bv : bit_vector(7 downto 0);
    variable      data_bv : bit_vector(7 downto 0);
    variable      exp_bv  : bit_vector(7 downto 0);
    variable      good    : boolean;
    variable      v_op    : character;
    variable      c       : character;
    variable      v_read  : natural := 0;
    variable      v_pass  : natural := 0;
    variable      v_fail  : natural := 0;
    variable      r_pass  : natural := 0;
    variable      r_fail  : natural := 0;
    variable      v_lines : natural := 0;
    type         int_array_t is array (1 to NUM_RANDOM) of integer;
    -- two independent seed pairs : A and B start with exactly the
    -- same values, so they must produce exactly the same sequence
    variable      sa1 : positive := SEED1;
    variable      sa2 : positive := SEED2;
    variable      sb1 : positive := SEED1;
    variable      sb2 : positive := SEED2;
    variable      r_addr, r_data : real;
    variable      a_addr, a_data : int_array_t;
    variable      b_addr, b_data : int_array_t;
    variable      v_same  : boolean := true;
  begin
    -------------------------------------------------------------------
    -- phase 0 : show which parameters the run got
    -------------------------------------------------------------------
    report "tb_stimulus : parameters from the generics" severity note;
    report "tb_stimulus :   VECTOR_FILE = " & VECTOR_FILE severity note;
    report "tb_stimulus :   NUM_RANDOM  = " & integer'image(NUM_RANDOM) severity note;
    report "tb_stimulus :   SEED1       = " & integer'image(SEED1) severity note;
    report "tb_stimulus :   SEED2       = " & integer'image(SEED2) severity note;

    -------------------------------------------------------------------
    -- phase 1 : file based stimulus
    -------------------------------------------------------------------
    report "tb_stimulus : phase 1 - file based stimulus from " & VECTOR_FILE severity note;
    file_open(f, VECTOR_FILE, read_mode);
    while not endfile(f) loop
      readline(f, l);
      v_lines := v_lines + 1;

      -- the address is the first field, hread skips the blanks and
      -- fails on a comment line (a line that starts with '#')
      hread(l, addr_bv, good);
      if not good then
        next;                       -- comment line or empty line
      end if;
      hread(l, data_bv, good);
      hread(l, exp_bv,  good);

      -- The operation letter is the last field.
      -- CAREFUL : READ of a STRING on a LINE wants a string with exactly
      -- the length of the rest of the line (error vsim-3549 otherwise),
      -- so the letter is read character by character and the blanks
      -- that separate it from the previous field are skipped.
      read(l, c);
      while c <= ' ' loop
        read(l, c);
      end loop;
      v_op := c;

      -- write the vector
      if v_op = 'W' then
        addr <= To_StdLogicVector(To_StdULogicVector(addr_bv(3 downto 0)));
        din  <= data_bv;
        we   <= '1';
        wait for 1 ns;
        wait until rising_edge(clk);
        we   <= '0';
      end if;

      -- read it back and compare with the expected value of the file
      addr <= To_StdLogicVector(To_StdULogicVector(addr_bv(3 downto 0)));
      wait for 1 ns;

      v_read := v_read + 1;
      if dout = exp_bv then
        v_pass := v_pass + 1;
        n_vec_pass <= v_pass;
      else
        v_fail := v_fail + 1;
        n_vec_fail <= v_fail;
        assert false
          report "tb_stimulus : VECTOR MISMATCH at address " &
                 to_hstring(To_StdULogicVector(addr_bv)) &
                 " : expected " & to_hstring(To_StdULogicVector(exp_bv)) &
                 " but got " & to_hstring(To_StdULogicVector(dout))
          severity error;
      end if;
      n_vec_read <= v_read;
    end loop;
    file_close(f);

    report "tb_stimulus : phase 1 read " & integer'image(v_read) &
           " vectors from " & integer'image(v_lines) & " lines of the file" severity note;

    -------------------------------------------------------------------
    -- phase 2 : random stimulus
    --
    -- CAREFUL : in ModelSim / QuestaSim the ieee.math_real package
    -- provides UNIFORM as a PROCEDURE :
    --    procedure UNIFORM(variable SEED1, SEED2 : inout POSITIVE;
    --                        variable X : out REAL);
    -- It needs TWO seeds and it returns a number in the open interval
    -- (0.0 , 1.0).  The VHDL-2008 function form
    --    uniform(seed1, seed2, left, right)
    -- does NOT exist in this simulator.
    --
    -- Run A and run B start with exactly the same seed pair, so they
    -- must produce exactly the same sequence.
    -------------------------------------------------------------------
    report "tb_stimulus : phase 2 - random stimulus with ieee.math_real.uniform" severity note;

    -- CAREFUL : uniform() can return a value that is so close to 1.0 that
    --            integer(u * 16.0) becomes 16 -- one more than a 4 bit
    --            address can hold.  With the seed pair (777,888) the very
    --            first value is 9.976514e-01, which gives 16.  Feeding
    --            16 into to_unsigned(..,4) makes the simulator print
    --                ** Warning: NUMERIC_STD.TO_UNSIGNED: vector truncated
    --            and the address silently becomes 0.  The "mod 16" below
    --            keeps the value inside the range of the bus.
    --
    -- run A
    for i in 1 to NUM_RANDOM loop
      uniform(sa1, sa2, r_addr);
      uniform(sa1, sa2, r_data);
      a_addr(i) := integer(r_addr * 16.0) mod 16;   -- 0 .. 15
      a_data(i) := integer(r_data * 256.0);         -- 0 .. 255
    end loop;

    -- run B : the very same seed pair again
    for i in 1 to NUM_RANDOM loop
      uniform(sb1, sb2, r_addr);
      uniform(sb1, sb2, r_data);
      b_addr(i) := integer(r_addr * 16.0) mod 16;
      b_data(i) := integer(r_data * 256.0);
    end loop;

    for i in 1 to NUM_RANDOM loop
      if (a_addr(i) /= b_addr(i)) or (a_data(i) /= b_data(i)) then
        v_same := false;
      end if;
      report "tb_stimulus : random vector " & integer'image(i) &
             " : A addr=" & integer'image(a_addr(i)) &
             " data=" & integer'image(a_data(i)) &
             " | B addr=" & integer'image(b_addr(i)) &
             " data=" & integer'image(b_data(i)) severity note;
    end loop;

    report "tb_stimulus : the same seed pair (" & integer'image(SEED1) &
           "," & integer'image(SEED2) & ") reproduces the same sequence : " &
           boolean'image(v_same) severity note;

    -- apply the random vectors of run A to the DUT and check them
    for i in 1 to NUM_RANDOM loop
      addr <= std_logic_vector(to_unsigned(a_addr(i), 4));
      din  <= int_to_bv(a_data(i));
      we   <= '1';
      wait for 1 ns;
      wait until rising_edge(clk);
      we   <= '0';

      addr <= std_logic_vector(to_unsigned(a_addr(i), 4));
      wait for 1 ns;
      if dout = int_to_bv(a_data(i)) then
        r_pass := r_pass + 1;
        n_rnd_pass <= r_pass;
      else
        r_fail := r_fail + 1;
        n_rnd_fail <= r_fail;
        assert false
          report "tb_stimulus : RANDOM MISMATCH at address " &
                 integer'image(a_addr(i)) &
                 " : expected " & to_hstring(To_StdULogicVector(int_to_bv(a_data(i)))) &
                 " but got " & to_hstring(To_StdULogicVector(dout))
          severity error;
      end if;
    end loop;

    -------------------------------------------------------------------
    -- phase 3 : the report
    -------------------------------------------------------------------
    report "tb_stimulus : file vectors : read=" & integer'image(v_read) &
           " passed=" & integer'image(v_pass) &
           " failed=" & integer'image(v_fail) severity note;
    report "tb_stimulus : random vectors : count=" & integer'image(NUM_RANDOM) &
           " passed=" & integer'image(r_pass) &
           " failed=" & integer'image(r_fail) severity note;

    if (v_fail = 0) and (r_fail = 0) and v_same and (v_read > 0) then
      report "TEST_PASSED : tb_stimulus completed" severity note;
      write_result("result.txt", "PASS");
    else
      write_result("result.txt", "FAIL");
      assert false
        report "TEST_FAILED : file failed=" & integer'image(v_fail) &
               " random failed=" & integer'image(r_fail) &
               " reproducible=" & boolean'image(v_same)
        severity failure;
    end if;

    std.env.finish;
    wait;
  end process stim;

end architecture sim;
