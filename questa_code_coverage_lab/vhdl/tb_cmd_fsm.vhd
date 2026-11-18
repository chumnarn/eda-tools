--=============================================================================
-- tb_cmd_fsm.vhd  --  ONE testbench, TWO tests, selected by a generic
-------------------------------------------------------------------------------
-- VHDL counterpart of tb/tb_cmd_fsm.v.
--
-- VHDL has no plusargs, so the test is selected with a generic:
--     vsim -coverage -gTEST=extra work.tb_cmd_fsm
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_cmd_fsm is
    generic (
        TEST : string := "basic"
    );
end entity tb_cmd_fsm;

architecture sim of tb_cmd_fsm is

    signal clk, rst_n, en : std_logic := '0';
    signal cmd, a, b      : std_logic_vector(3 downto 0) := (others => '0');
    signal result         : std_logic_vector(3 downto 0);
    signal zero, parity   : std_logic;
    signal done           : std_logic;
    signal state_o        : std_logic_vector(1 downto 0);

    signal clk_stop : boolean := false;

begin

    dut : entity work.cmd_fsm
        port map (
            clk     => clk,
            rst_n   => rst_n,
            en      => en,
            cmd     => cmd,
            a       => a,
            b       => b,
            result  => result,
            zero    => zero,
            parity  => parity,
            done    => done,
            state_o => state_o
        );

    ---------------------------------------------------------------------
    -- 100 MHz clock
    ---------------------------------------------------------------------
    clk <= not clk after 5 ns when not clk_stop else '0';

    ---------------------------------------------------------------------
    -- Stimulus
    ---------------------------------------------------------------------
    stim : process

        procedure step (c, av, bv : std_logic_vector(3 downto 0);
                         e         : std_logic) is
        begin
            wait until falling_edge(clk);
            cmd <= c; a <= av; b <= bv; en <= e;
            wait until rising_edge(clk);
            wait until falling_edge(clk);
            report "cmd=" & to_hstring(cmd) &
                   " a=" & to_hstring(a) &
                   " b=" & to_hstring(b) &
                   " en=" & std_logic'image(en) &
                   " -> result=" & to_hstring(result) &
                   " zero=" & std_logic'image(zero) &
                   " parity=" & std_logic'image(parity) &
                   " state=" & to_hstring(state_o) &
                   " done=" & std_logic'image(done);
        end procedure;

        procedure pulse_reset is
        begin
            wait until falling_edge(clk);
            rst_n <= '0';
            wait until rising_edge(clk);
            wait until falling_edge(clk);
            rst_n <= '1';
        end procedure;

    begin
        rst_n <= '0'; en <= '0'; cmd <= (others => '0');
        a <= (others => '0'); b <= (others => '0');
        for i in 1 to 2 loop
            wait until falling_edge(clk);
        end loop;
        rst_n <= '1';

        if TEST = "extra" then
            report "=== TEST 'extra' : start ===";
            step("0011", "0110", "0011", '1');
            step("0100", "1100", "0011", '1');
            step("0101", "0010", "0111", '1');
            step("0000", "0000", "0000", '0');
            step("0000", "0101", "0101", '1');
            step("0000", "0000", "0000", '0');
            report "=== TEST 'extra' : finished ===";

        elsif TEST = "edge" then
            report "=== TEST 'edge' : start ===";
            -- expression coverage of the parity expression
            step("0000", "0010", "1010", '1');
            step("0000", "0110", "0010", '1');
            step("0000", "1111", "1111", '1');
            step("0000", "0000", "0001", '1');
            step("0000", "0010", "0001", '1');
            -- toggle coverage : cmd[3] and b[3] must change value
            step("1000", "1000", "1100", '1');
            step("0000", "1000", "0000", '1');
            -- reset while the FSM is in ST_EXEC
            step("0000", "0001", "0010", '1');
            pulse_reset;
            -- sit in ST_WAIT while a /= b
            step("0000", "0001", "0010", '1');
            step("0000", "0001", "0010", '0');
            step("0000", "0001", "0010", '0');
            -- reset while the FSM is in ST_WAIT
            pulse_reset;
            report "=== TEST 'edge' : finished ===";

        else
            report "=== TEST 'basic' : start ===";
            step("0001", "0101", "0011", '1');
            step("0001", "1001", "0010", '1');
            step("0010", "1000", "0011", '1');
            step("0001", "0101", "0101", '1');
            step("0000", "0000", "0000", '0');
            report "=== TEST 'basic' : finished ===";
        end if;

        clk_stop <= true;
        wait;
    end process;

end architecture sim;
