--=====================================================================
-- tb_ram.vhd -- LAB 07 : testbench for the RAM / memory debugging lab
------------------------------------------------------------------------
-- The testbench does three things:
--
--   phase 1  Read back all 256 words and compare them with the values
--            that "mem load" was asked to put into the memory
--            (mem_init.txt).  This proves that the simulator really
--            wrote into the VHDL array.
--
--   phase 2  Write a known pattern with the write port and read it
--            back with the read port.
--
--   phase 3  Print a report with the values that were really measured
--            and finish with the line TEST_PASSED.
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_ram is
end entity tb_ram;

architecture sim of tb_ram is
  constant CLK_PERIOD : time := 10 ns;
  constant RAM_SIZE   : natural := 256;

  type byte_array_t is array (0 to RAM_SIZE-1) of std_logic_vector(7 downto 0);

  ---------------------------------------------------------------------
  -- The content of mem_init.txt : word N holds the value N+1 (mod 256)
  ---------------------------------------------------------------------
  constant EXPECTED_INIT : byte_array_t := (
      0 => x"01",   1 => x"02",   2 => x"03",   3 => x"04",   4 => x"05",   5 => x"06",   6 => x"07",   7 => x"08",   8 => x"09",   9 => x"0A",  10 => x"0B",  11 => x"0C",  12 => x"0D",  13 => x"0E",  14 => x"0F",  15 => x"10",
     16 => x"11",  17 => x"12",  18 => x"13",  19 => x"14",  20 => x"15",  21 => x"16",  22 => x"17",  23 => x"18",  24 => x"19",  25 => x"1A",  26 => x"1B",  27 => x"1C",  28 => x"1D",  29 => x"1E",  30 => x"1F",  31 => x"20",
     32 => x"21",  33 => x"22",  34 => x"23",  35 => x"24",  36 => x"25",  37 => x"26",  38 => x"27",  39 => x"28",  40 => x"29",  41 => x"2A",  42 => x"2B",  43 => x"2C",  44 => x"2D",  45 => x"2E",  46 => x"2F",  47 => x"30",
     48 => x"31",  49 => x"32",  50 => x"33",  51 => x"34",  52 => x"35",  53 => x"36",  54 => x"37",  55 => x"38",  56 => x"39",  57 => x"3A",  58 => x"3B",  59 => x"3C",  60 => x"3D",  61 => x"3E",  62 => x"3F",  63 => x"40",
     64 => x"41",  65 => x"42",  66 => x"43",  67 => x"44",  68 => x"45",  69 => x"46",  70 => x"47",  71 => x"48",  72 => x"49",  73 => x"4A",  74 => x"4B",  75 => x"4C",  76 => x"4D",  77 => x"4E",  78 => x"4F",  79 => x"50",
     80 => x"51",  81 => x"52",  82 => x"53",  83 => x"54",  84 => x"55",  85 => x"56",  86 => x"57",  87 => x"58",  88 => x"59",  89 => x"5A",  90 => x"5B",  91 => x"5C",  92 => x"5D",  93 => x"5E",  94 => x"5F",  95 => x"60",
     96 => x"61",  97 => x"62",  98 => x"63",  99 => x"64", 100 => x"65", 101 => x"66", 102 => x"67", 103 => x"68", 104 => x"69", 105 => x"6A", 106 => x"6B", 107 => x"6C", 108 => x"6D", 109 => x"6E", 110 => x"6F", 111 => x"70",
    112 => x"71", 113 => x"72", 114 => x"73", 115 => x"74", 116 => x"75", 117 => x"76", 118 => x"77", 119 => x"78", 120 => x"79", 121 => x"7A", 122 => x"7B", 123 => x"7C", 124 => x"7D", 125 => x"7E", 126 => x"7F", 127 => x"80",
    128 => x"81", 129 => x"82", 130 => x"83", 131 => x"84", 132 => x"85", 133 => x"86", 134 => x"87", 135 => x"88", 136 => x"89", 137 => x"8A", 138 => x"8B", 139 => x"8C", 140 => x"8D", 141 => x"8E", 142 => x"8F", 143 => x"90",
    144 => x"91", 145 => x"92", 146 => x"93", 147 => x"94", 148 => x"95", 149 => x"96", 150 => x"97", 151 => x"98", 152 => x"99", 153 => x"9A", 154 => x"9B", 155 => x"9C", 156 => x"9D", 157 => x"9E", 158 => x"9F", 159 => x"A0",
    160 => x"A1", 161 => x"A2", 162 => x"A3", 163 => x"A4", 164 => x"A5", 165 => x"A6", 166 => x"A7", 167 => x"A8", 168 => x"A9", 169 => x"AA", 170 => x"AB", 171 => x"AC", 172 => x"AD", 173 => x"AE", 174 => x"AF", 175 => x"B0",
    176 => x"B1", 177 => x"B2", 178 => x"B3", 179 => x"B4", 180 => x"B5", 181 => x"B6", 182 => x"B7", 183 => x"B8", 184 => x"B9", 185 => x"BA", 186 => x"BB", 187 => x"BC", 188 => x"BD", 189 => x"BE", 190 => x"BF", 191 => x"C0",
    192 => x"C1", 193 => x"C2", 194 => x"C3", 195 => x"C4", 196 => x"C5", 197 => x"C6", 198 => x"C7", 199 => x"C8", 200 => x"C9", 201 => x"CA", 202 => x"CB", 203 => x"CC", 204 => x"CD", 205 => x"CE", 206 => x"CF", 207 => x"D0",
    208 => x"D1", 209 => x"D2", 210 => x"D3", 211 => x"D4", 212 => x"D5", 213 => x"D6", 214 => x"D7", 215 => x"D8", 216 => x"D9", 217 => x"DA", 218 => x"DB", 219 => x"DC", 220 => x"DD", 221 => x"DE", 222 => x"DF", 223 => x"E0",
    224 => x"E1", 225 => x"E2", 226 => x"E3", 227 => x"E4", 228 => x"E5", 229 => x"E6", 230 => x"E7", 231 => x"E8", 232 => x"E9", 233 => x"EA", 234 => x"EB", 235 => x"EC", 236 => x"ED", 237 => x"EE", 238 => x"EF", 239 => x"F0",
    240 => x"F1", 241 => x"F2", 242 => x"F3", 243 => x"F4", 244 => x"F5", 245 => x"F6", 246 => x"F7", 247 => x"F8", 248 => x"F9", 249 => x"FA", 250 => x"FB", 251 => x"FC", 252 => x"FD", 253 => x"FE", 254 => x"FF", 255 => x"00"
  );

  ---------------------------------------------------------------------
  -- The pattern that phase 2 writes with the write port
  ---------------------------------------------------------------------
  constant PATTERN_BASE  : natural := 16#5A#;    -- word 0 gets 5A, 1 gets 5B ...
  constant PATTERN_LAST  : natural := 15;        -- words 0 .. 15
  constant LAST_ADDR     : natural := 255;       -- and the very last word
  constant LAST_VALUE    : natural := 16#EE#;

  signal clk    : std_logic := '0';
  signal we     : std_logic := '0';
  signal w_addr : std_logic_vector(7 downto 0) := (others => '0');
  signal w_data : std_logic_vector(7 downto 0) := (others => '0');
  signal r_addr : std_logic_vector(7 downto 0) := (others => '0');
  signal r_data : std_logic_vector(7 downto 0);

  signal n_checked : natural := 0;
  signal n_errors  : natural := 0;
begin

  ---------------------------------------------------------------------
  -- 50 MHz clock
  ---------------------------------------------------------------------
  clk <= not clk after CLK_PERIOD / 2;

  ---------------------------------------------------------------------
  -- DUT : the wrapper that owns the memory array
  ---------------------------------------------------------------------
  dut : entity work.ram_wrap
    generic map (
      ADDR_WIDTH => 8
    )
    port map (
      clk    => clk,
      we     => we,
      w_addr => w_addr,
      w_data => w_data,
      r_addr => r_addr,
      r_data => r_data
    );

  ---------------------------------------------------------------------
  -- Stimulus + self checking
  ---------------------------------------------------------------------
  stim : process is
    variable v_read   : byte_array_t;
    variable v_err    : natural := 0;
    variable v_check  : natural := 0;
    variable v_reported : natural := 0;
    variable v_expect : std_logic_vector(7 downto 0);
  begin
    report "tb_ram : start" severity note;

    -- The "mem load" happened at time 0, before the simulation started.
    wait for 1 ns;

    -------------------------------------------------------------------
    -- phase 1 : read back everything that was loaded from mem_init.txt
    -------------------------------------------------------------------
    report "tb_ram : phase 1 - read back the memory loaded from mem_init.txt" severity note;
    for i in 0 to RAM_SIZE-1 loop
      r_addr <= std_logic_vector(to_unsigned(i, 8));
      wait for 1 ns;
      v_read(i) := r_data;
      v_check  := v_check + 1;
      if r_data /= EXPECTED_INIT(i) then
        v_err := v_err + 1;
        if v_reported < 5 then
          v_reported := v_reported + 1;
          assert false
            report "tb_ram : MISMATCH at address " & integer'image(i) &
                   " : expected " & to_hstring(EXPECTED_INIT(i)) &
                   " but got " & to_hstring(r_data)
            severity error;
        end if;
      end if;
    end loop;

    report "tb_ram : phase 1 checked " & integer'image(v_check) &
           " words, mismatches = " & integer'image(v_err) severity note;
    report "tb_ram : measured mem[0]=" & to_hstring(v_read(0)) &
           " mem[1]=" & to_hstring(v_read(1)) &
           " mem[10]=" & to_hstring(v_read(10)) &
           " mem[62]=" & to_hstring(v_read(62)) &
           " mem[254]=" & to_hstring(v_read(254)) &
           " mem[255]=" & to_hstring(v_read(255)) severity note;

    -------------------------------------------------------------------
    -- phase 2 : write a known pattern, then read it back
    -------------------------------------------------------------------
    report "tb_ram : phase 2 - write a known pattern and read it back" severity note;
    for i in 0 to PATTERN_LAST loop
      w_data <= std_logic_vector(to_unsigned(PATTERN_BASE + i, 8));
      w_addr <= std_logic_vector(to_unsigned(i, 8));
      we     <= '1';
      wait for 1 ns;
      wait until rising_edge(clk);
    end loop;

    -- one extra word at the very end of the array
    w_data <= std_logic_vector(to_unsigned(LAST_VALUE, 8));
    w_addr <= std_logic_vector(to_unsigned(LAST_ADDR, 8));
    we     <= '1';
    wait for 1 ns;
    wait until rising_edge(clk);
    we     <= '0';

    for i in 0 to PATTERN_LAST loop
      r_addr <= std_logic_vector(to_unsigned(i, 8));
      wait for 1 ns;
      v_expect := std_logic_vector(to_unsigned(PATTERN_BASE + i, 8));
      v_check  := v_check + 1;
      if r_data /= v_expect then
        v_err := v_err + 1;
        if v_reported < 5 then
          v_reported := v_reported + 1;
          assert false
            report "tb_ram : MISMATCH after write at address " & integer'image(i) &
                   " : expected " & to_hstring(v_expect) &
                   " but got " & to_hstring(r_data)
            severity error;
        end if;
      end if;
    end loop;

    r_addr <= std_logic_vector(to_unsigned(LAST_ADDR, 8));
    wait for 1 ns;
    v_check := v_check + 1;
    if r_data /= std_logic_vector(to_unsigned(LAST_VALUE, 8)) then
      v_err := v_err + 1;
      assert false
        report "tb_ram : MISMATCH after write at address " & integer'image(LAST_ADDR) &
               " : expected " & to_hstring(std_logic_vector(to_unsigned(LAST_VALUE, 8))) &
               " but got " & to_hstring(r_data)
        severity error;
    end if;

    report "tb_ram : phase 2 wrote 17 words (0..15 and 255) and read them back" severity note;
    report "tb_ram : measured mem[0]=" & to_hstring(v_read(0)) &
           " (still the loaded value), mem[255]=" & to_hstring(r_data) severity note;

    -------------------------------------------------------------------
    -- phase 3 : the report
    -------------------------------------------------------------------
    n_checked <= v_check;
    n_errors  <= v_err;

    report "tb_ram : words checked = " & integer'image(v_check) &
           " , errors = " & integer'image(v_err) severity note;

    if v_err = 0 then
      report "TEST_PASSED : tb_ram memory checks completed" severity note;
    else
      assert false
        report "TEST_FAILED : " & integer'image(v_err) & " memory mismatches"
        severity failure;
    end if;

    -- end the simulation so that "run -all" returns to the script
    std.env.finish;
    wait;
  end process stim;

  ---------------------------------------------------------------------
  -- Monitor : print every word that is really written on the clock edge
  ---------------------------------------------------------------------
  mon : process (clk) is
  begin
    if rising_edge(clk) and we = '1' then
      report "  [mon] t=" & time'image(now) & " write addr=" & to_hstring(w_addr) &
             " data=" & to_hstring(w_data) severity note;
    end if;
  end process mon;

end architecture sim;
