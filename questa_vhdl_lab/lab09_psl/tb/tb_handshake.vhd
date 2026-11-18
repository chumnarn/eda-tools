--=============================================================================
--  tb_handshake.vhd -- testbench for the handshake DUT
-------------------------------------------------------------------------------
--  ONE testbench, one scenario.  The generic BUGGY selects the DUT variant:
--      vsim work.tb_handshake -gBUGGY=false   -> correct design
--      vsim work.tb_handshake -gBUGGY=true    -> deliberately buggy design
--
--  The testbench only checks a LOOSE latency bound ("the answer has to show
--  up within two cycles").  The exact protocol timing is checked by the
--  embedded PSL property "req_ack" inside the DUT -- that is the point of
--  the lab: PSL checks something the testbench does not.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity tb_handshake is
    generic (
        BUGGY : boolean := false
    );
end entity tb_handshake;

architecture sim of tb_handshake is

    signal clk    : std_logic := '0';
    signal rst_n  : std_logic := '0';
    signal req    : std_logic := '0';
    signal ack    : std_logic;
    signal busy   : std_logic;
    signal cnt    : std_logic_vector(3 downto 0);
    signal clk_stop : boolean := false;

begin

    dut : entity work.handshake
        generic map (
            BUGGY => BUGGY
        )
        port map (
            clk   => clk,
            rst_n => rst_n,
            req   => req,
            ack   => ack,
            busy  => busy,
            cnt   => cnt
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
        variable lat    : natural := 0;
    begin
        rst_n <= '0';
        req   <= '0';

        -- ---- reset ------------------------------------------------------
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        rst_n <= '1';
        wait until falling_edge(clk);
        report "reset released, BUGGY=" & boolean'image(BUGGY);

        -- ---- three transactions ----------------------------------------
        for i in 1 to 3 loop
            -- present the request for exactly one clock cycle
            req <= '1';
            wait until falling_edge(clk);
            req <= '0';

            -- loose functional check : the answer must show up within
            -- two clock cycles
            if ack = '1' then
                lat := 1;
                report "transaction " & integer'image(i) & " : ack on cycle 1";
            else
                wait until falling_edge(clk);
                if ack = '1' then
                    lat := 2;
                    report "transaction " & integer'image(i) & " : ack on cycle 2 (late)";
                else
                    lat := 0;
                    report "ERROR : transaction " & integer'image(i) &
                           " : no ack within 2 cycles" severity error;
                    errors := errors + 1;
                end if;
            end if;

            report "transaction " & integer'image(i) & " : ack latency = " &
                   integer'image(lat) & " cycle(s)";

            -- let the handshake machine go back to idle
            wait until falling_edge(clk);
            wait until falling_edge(clk);
        end loop;

        clk_stop <= true;

        -- ---- verdict ----------------------------------------------------
        if errors = 0 then
            report "TEST_PASSED : 3/3 handshakes answered within the latency bound";
            report "=== handshake testbench finished ===";
        else
            report "TEST_FAILED : " & integer'image(errors) & " error(s)" severity error;
        end if;

        std.env.stop;
        wait;
    end process;

end architecture sim;
