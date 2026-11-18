--=====================================================================
-- ram.vhd -- LAB 07 : single-port RAM built on a VHDL array memory
------------------------------------------------------------------------
-- Two entities are provided:
--
--   entity ram       The RAM core.  One write port (clk, we, w_addr,
--                    w_data) and one read port (r_addr, r_data).
--                    The storage array is handed in through the "mem"
--                    port, so whoever owns the data stays in control.
--
--   entity ram_wrap  The IP wrapper that the testbench instantiates.
--                    The memory array lives HERE, as an internal
--                    signal, which is exactly what the simulator's
--                    "mem" commands need.  Debug path of the array:
--                       /tb_ram/dut/mem
--
-- The array type is:
--   type ram_t is array (0 to 255) of std_logic_vector(7 downto 0);
-- It is declared in package work.ram_pkg because the wrapper owns the
-- storage and has to pass it to the core through a port; inside the
-- architecture of the core it is visible as the subtype "ram_t".
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;

package ram_pkg is
  type ram_t is array (0 to 255) of std_logic_vector(7 downto 0);
end package ram_pkg;

------------------------------------------------------------------------
-- The RAM core
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ram_pkg;

entity ram is
  generic (
    ADDR_WIDTH : positive := 8             -- 8 address bits -> 256 words
  );
  port (
    clk    : in  std_logic;                -- clock
    we     : in  std_logic;                -- write enable
    w_addr : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    w_data : in  std_logic_vector(7 downto 0);
    r_addr : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    r_data : out std_logic_vector(7 downto 0);
    mem    : inout ram_pkg.ram_t           -- the storage array
  );
end entity ram;

architecture rtl of ram is
  -- The array type as seen inside this architecture:
  --   type ram_t is array (0 to 255) of std_logic_vector(7 downto 0);
  subtype ram_t is ram_pkg.ram_t;
begin

  -- Write port : one word per clock edge while we = '1'
  process (clk) is
  begin
    if rising_edge(clk) then
      if we = '1' then
        mem(to_integer(unsigned(w_addr))) <= w_data;
      end if;
    end if;
  end process;

  -- Read port : asynchronous read out of the array
  r_data <= mem(to_integer(unsigned(r_addr)));

end architecture rtl;

------------------------------------------------------------------------
-- The IP wrapper : owner of the memory array
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.ram_pkg;

entity ram_wrap is
  generic (
    ADDR_WIDTH : positive := 8
  );
  port (
    clk    : in  std_logic;
    we     : in  std_logic;
    w_addr : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    w_data : in  std_logic_vector(7 downto 0);
    r_addr : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    r_data : out std_logic_vector(7 downto 0)
  );
end entity ram_wrap;

architecture struct of ram_wrap is
  subtype ram_t is ram_pkg.ram_t;
  -- The memory : an INTERNAL signal of this wrapper entity.
  -- This is the object the simulator's "mem" commands work on.
  signal mem : ram_t := (others => (others => '0'));
begin

  ram_inst : entity work.ram
    generic map (
      ADDR_WIDTH => ADDR_WIDTH
    )
    port map (
      clk    => clk,
      we     => we,
      w_addr => w_addr,
      w_data => w_data,
      r_addr => r_addr,
      r_data => r_data,
      mem    => mem
    );

end architecture struct;
