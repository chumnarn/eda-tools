--=============================================================================
--  tb_alu_fsm_alt.vhd -- PITFALL DEMO ONLY
-------------------------------------------------------------------------------
--  This is a COPY of tb/tb_alu_fsm.vhd whose ENTITY NAME is different.
--  The instance path of the DUT therefore becomes
--      /tb_alu_fsm_alt/dut
--  instead of
--      /tb_alu_fsm/dut
--
--  Coverage data is stored per instance path.  When the UCDB of this
--  testbench is merged with the UCDB of tb_alu_fsm, the merged database
--  holds TWO COPIES of every bin of the DUT, so the bin count is
--  inflated and the percentage no longer means anything.
--
--  The fix is trivial : always use the SAME testbench and select the
--  test with a generic.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_alu_fsm_alt is
    generic (
        TEST : string := "basic"
    );
end entity tb_alu_fsm_alt;

architecture sim of tb_alu_fsm_alt is

    signal clk    : std_logic := '0';
    signal rst_n  : std_logic := '0';
    signal start  : std_logic := '0';
    signal abort  : std_logic := '0';
    signal opcode : std_logic_vector(2 downto 0) := (others => '0');
    signal a      : std_logic_vector(7 downto 0) := (others => '0');
    signal b      : std_logic_vector(7 downto 0) := (others => '0');
    signal dout   : std_logic_vector(7 downto 0);
    signal done   : std_logic;
    signal state_o: std_logic_vector(2 downto 0);
    signal clk_stop : boolean := false;

begin

    dut : entity work.alu_fsm
        port map (
            clk    => clk,
            rst_n  => rst_n,
            start  => start,
            abort  => abort,
            opcode => opcode,
            a      => a,
            b      => b,
            dout   => dout,
            done   => done,
            state_o=> state_o
        );

    clk <= not clk after 5 ns when not clk_stop else '0';

    stim : process
    begin
        rst_n <= '0';
        for i in 1 to 3 loop
            wait until falling_edge(clk);
        end loop;
        rst_n <= '1';

        report "=== ALT testbench, instance path is /tb_alu_fsm_alt/dut ===";
        report "TEST_PASSED : alt testbench finished without errors";
        clk_stop <= true;
        std.env.stop;
        wait;
    end process;

end architecture sim;
