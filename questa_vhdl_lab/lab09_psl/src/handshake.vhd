--=============================================================================
--  handshake.vhd -- Request / Acknowledge handshake DUT with embedded PSL
-------------------------------------------------------------------------------
--  The PSL directives are ordinary VHDL comments that start with "-- psl".
--  ModelSim reads them while compiling and builds the checker into the
--  design.  No extra library and no extra command line option are needed:
--  embedded PSL parsing is ON by default in Questa 2026.1.
--
--  Generic BUGGY selects the deliberately broken variant:
--      false -> correct design.  "ack" is produced in the clock cycle
--               right after "req" was sampled.
--      true  -> buggy design.  "ack" is produced ONE CYCLE TOO LATE.
--               The embedded PSL property "req_ack" detects this.
--               The testbench only checks a loose latency bound, so it
--               stays quiet -- this is exactly what PSL adds.
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity handshake is
    generic (
        BUGGY : boolean := false
    );
    port (
        clk   : in  std_logic;
        rst_n : in  std_logic;
        req   : in  std_logic;
        ack   : out std_logic;
        busy  : out std_logic;
        cnt   : out std_logic_vector(3 downto 0)
    );
end entity handshake;

architecture rtl of handshake is

    type state_t is (ST_IDLE, ST_BUSY);
    signal state : state_t := ST_IDLE;
    signal ack_r : std_logic := '0';
    signal cnt_r : std_logic_vector(3 downto 0) := (others => '0');

    --=====================================================================
    -- Embedded PSL.
    --   * every directive starts with "-- psl"
    --   * the "default clock" directive must come FIRST, otherwise the
    --     property is unclocked and vcom refuses to compile it
    --   * VHDL PSL has no "severity" keyword and no "next[a to b]" range
    --=====================================================================

    -- The clock used by every following property
    -- psl default clock is rising_edge(clk);

    -- ASSUME : the environment presents "req" for exactly one cycle.
    --          This is a constraint on the testbench, not on the DUT.
    -- psl env_req_pulse: assume always (req -> next not req);

    -- ASSERT : the protocol contract of the DUT -- the answer must be
    --          given in the clock cycle right after the request.
    -- psl req_ack: assert always (req -> next ack);

    -- ASSERT : a request and an answer are never seen at the same time
    -- psl no_overlap: assert always (not ((req = '1') and (ack = '1')));

    -- COVER  : the sequence "request then answer" must really happen
    -- psl c_req_ack: cover {req; ack};

begin

    -----------------------------------------------------------------------
    -- Core : a two state handshake engine
    -----------------------------------------------------------------------
    process (clk, rst_n) is
    begin
        if rst_n = '0' then
            state <= ST_IDLE;
            ack_r <= '0';
            cnt_r <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                when ST_IDLE =>
                    if BUGGY then
                        -- BUG : the answer is not registered together with
                        --       the request, it comes one cycle too late
                        ack_r <= '0';
                    else
                        -- CORRECT : ack is high in the cycle after req
                        ack_r <= req;
                    end if;
                    cnt_r <= std_logic_vector(unsigned(cnt_r) + 1);
                    if req = '1' then
                        state <= ST_BUSY;
                    else
                        state <= ST_IDLE;
                    end if;

                when ST_BUSY =>
                    if BUGGY then
                        -- BUG : the answer shows up here, one cycle late
                        ack_r <= '1';
                    else
                        ack_r <= '0';
                    end if;
                    state <= ST_IDLE;
            end case;
        end if;
    end process;

    ack  <= ack_r;
    busy <= '1' when state = ST_BUSY else '0';
    cnt  <= cnt_r;

end architecture rtl;
