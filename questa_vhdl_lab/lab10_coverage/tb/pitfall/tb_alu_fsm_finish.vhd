--=============================================================================
--  tb_alu_fsm_finish.vhd -- PITFALL DEMO ONLY
-------------------------------------------------------------------------------
--  This testbench calls std.env.finish (the VHDL-2008 equivalent of
--  $finish) instead of std.env.stop.
--
--  In "vsim -c" mode (batch, no GUI) the default -onfinish mode is "ask",
--  which in a non interactive session ends the WHOLE session.  Every
--  command that follows in the -do string is then silently skipped:
--
--      vsim -c work.tb_alu_fsm_finish -do "run -all; coverage save x.ucdb; quit -f"
--                ^^^^^^^^^^^^^ the session dies here, "coverage save" never runs
--
--  The fix is to always add  -onfinish stop  to the vsim command line.
--  Then $finish / std.env.finish only stops the simulation, the session
--  stays alive and the remaining commands are executed.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_alu_fsm_finish is
end entity tb_alu_fsm_finish;

architecture sim of tb_alu_fsm_finish is

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

    clk <= not clk after 5 ns;

    stim : process
    begin
        rst_n <= '0';
        for i in 1 to 3 loop
            wait until falling_edge(clk);
        end loop;
        rst_n <= '1';
        wait for 100 ns;

        report "PITFALL : calling std.env.finish now -- without -onfinish stop";
        report "          the whole vsim session ends here";
        std.env.finish;
        wait;
    end process;

end architecture sim;
