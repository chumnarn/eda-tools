--=============================================================================
--  tb_alu_fsm.vhd -- ONE testbench, THREE tests, selected by a generic
-------------------------------------------------------------------------------
--  VHDL has no plusargs, so the test is selected with a generic:
--      vsim -coverage work.tb_alu_fsm -gTEST=basic
--      vsim -coverage work.tb_alu_fsm -gTEST=extra
--      vsim -coverage work.tb_alu_fsm -gTEST=edge
--
--  IMPORTANT : the testbench NAME must stay the same for every test.
--  The coverage database is stored per INSTANCE PATH.  If the same RTL is
--  driven by two different testbench names, the merged database contains
--  two copies of every bin and the percentage becomes meaningless.
--  See tb/pitfall/tb_alu_fsm_alt.vhd for the demonstration.
--
--  The testbench itself is compiled WITHOUT coverage, so every number in
--  the report belongs to the DUT and not to the stimulus code.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_alu_fsm is
    generic (
        TEST : string := "basic"
    );
end entity tb_alu_fsm;

architecture sim of tb_alu_fsm is

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

    -----------------------------------------------------------------------
    -- 100 MHz clock
    -----------------------------------------------------------------------
    clk <= not clk after 5 ns when not clk_stop else '0';

    -----------------------------------------------------------------------
    -- Stimulus
    -----------------------------------------------------------------------
    stim : process
        variable errors : natural := 0;

        -------------------------------------------------------------------
        -- one normal transaction : IDLE -> LOAD -> EXEC -> WAIT -> DONE
        -------------------------------------------------------------------
        procedure transact (constant op : std_logic_vector(2 downto 0);
                             constant av : std_logic_vector(7 downto 0);
                             constant bv : std_logic_vector(7 downto 0)) is
            variable ok : boolean := false;
        begin
            opcode <= op;
            a      <= av;
            b      <= bv;
            start  <= '1';
            abort  <= '0';
            for i in 0 to 30 loop
                wait until rising_edge(clk);
                wait for 1 ns;
                if done = '1' then
                    ok := true;
                    exit;
                end if;
            end loop;
            if not ok then
                report "ERROR : transaction op=" & to_hstring(op) &
                       " timed out" severity error;
                errors := errors + 1;
            else
                report "op=" & to_hstring(op) & " a=" & to_hstring(av) &
                       " b=" & to_hstring(bv) & " -> dout=" & to_hstring(dout) &
                       " state=" & to_hstring(state_o);
            end if;
            start <= '0';
            for i in 0 to 5 loop
                wait until rising_edge(clk);
                wait for 1 ns;
                if state_o = "000" then
                    exit;
                end if;
            end loop;
        end procedure;

        -------------------------------------------------------------------
        -- an aborted transaction : IDLE -> LOAD -> EXEC -> IDLE
        -------------------------------------------------------------------
        procedure do_abort is
        begin
            opcode <= "010";
            start  <= '1';
            abort  <= '1';
            for i in 0 to 5 loop
                wait until rising_edge(clk);
                wait for 1 ns;
                if state_o = "000" then
                    exit;
                end if;
            end loop;
            abort <= '0';
            start <= '0';
            report "abort transaction done, state=" & to_hstring(state_o);
        end procedure;

        -------------------------------------------------------------------
        -- a reset in the middle of a transaction
        -------------------------------------------------------------------
        procedure reset_mid is
        begin
            opcode <= "000";
            a      <= x"5A";
            b      <= x"A5";
            start  <= '1';
            wait until rising_edge(clk);
            wait until rising_edge(clk);
            wait for 1 ns;
            rst_n <= '0';
            wait until rising_edge(clk);
            wait for 1 ns;
            rst_n <= '1';
            start  <= '0';
            report "reset in the middle of a transaction, state=" & to_hstring(state_o);
        end procedure;

    begin
        -------------------------------------------------------------------
        -- reset
        -------------------------------------------------------------------
        rst_n  <= '0';
        start  <= '0';
        abort  <= '0';
        opcode <= (others => '0');
        a      <= (others => '0');
        b      <= (others => '0');
        for i in 1 to 3 loop
            wait until falling_edge(clk);
        end loop;
        rst_n <= '1';
        wait until falling_edge(clk);

        if TEST = "extra" then
            report "=== TEST 'extra' : start ===";
            -- bit wise AND and XOR
            transact("010", x"F0", x"3C");
            transact("011", x"FF", x"0F");
            -- unsigned underflow
            transact("001", x"03", x"0A");
            -- "a > b" is false for the ADD, so the overflow flag stays 0
            transact("000", x"01", x"F9");
            report "=== TEST 'extra' : finished ===";

        elsif TEST = "edge" then
            report "=== TEST 'edge' : start ===";
            -- the abort path : EXEC -> IDLE without a result
            do_abort;
            -- ADD with an overflow : the lane sum is added to the result
            transact("000", x"FF", x"01");
            -- XOR with all zero
            transact("011", x"00", x"FF");
            -- reset in the middle of a transaction
            reset_mid;
            report "=== TEST 'edge' : finished ===";

        else
            report "=== TEST 'basic' : start ===";
            -- ADD with "a > b" : the overflow flag is set
            transact("000", x"05", x"03");
            -- SUB
            transact("001", x"0A", x"02");
            -- ADD with "a < b" : the overflow flag stays 0
            transact("000", x"01", x"F9");
            report "=== TEST 'basic' : finished ===";
        end if;

        clk_stop <= true;

        -------------------------------------------------------------------
        -- verdict
        -------------------------------------------------------------------
        if errors = 0 then
            report "TEST_PASSED : test '" & TEST & "' finished without errors";
        else
            report "TEST_FAILED : " & integer'image(errors) & " error(s)" severity error;
        end if;

        std.env.stop;
        wait;
    end process;

end architecture sim;
