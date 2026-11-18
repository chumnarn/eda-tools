--=============================================================================
-- cmd_fsm.vhd  --  Command Decoder + Response FSM  (VHDL version)
-------------------------------------------------------------------------------
-- VHDL counterpart of rtl/cmd_fsm.v, used by the VHDL appendix of the lab
-- guide "Using Code Coverage in QuestaSim".
--
-- The structure is deliberately identical to the Verilog version so that the
-- same coverage numbers can be expected from both languages:
--   s  Statement, b Branch, c Condition, e Expression, t Toggle, f FSM
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cmd_fsm is
    port (
        clk     : in  std_logic;
        rst_n   : in  std_logic;
        en      : in  std_logic;
        cmd     : in  std_logic_vector(3 downto 0);
        a       : in  std_logic_vector(3 downto 0);
        b       : in  std_logic_vector(3 downto 0);
        result  : out std_logic_vector(3 downto 0);
        zero    : out std_logic;
        parity  : out std_logic;
        done    : out std_logic;
        state_o : out std_logic_vector(1 downto 0)
    );
end entity cmd_fsm;

architecture rtl of cmd_fsm is

    type state_t is (ST_IDLE, ST_EXEC, ST_WAIT, ST_DONE);
    signal state, next_state : state_t;

    signal res_i    : std_logic_vector(3 downto 0);
    signal zero_i   : std_logic;
    signal parity_i : std_logic;

    function state_to_sl (s : state_t) return std_logic_vector is
    begin
        case s is
            when ST_IDLE => return "00";
            when ST_EXEC => return "01";
            when ST_WAIT => return "10";
            when ST_DONE => return "11";
        end case;
    end function;

begin

    -----------------------------------------------------------------------
    -- Next-state logic (combinational)  -> FSM transition coverage
    -----------------------------------------------------------------------
    process (state, en, a, b) is
        variable ns : state_t;
    begin
        ns := state;
        case state is
            when ST_IDLE => if en = '1' then ns := ST_EXEC; end if;
            when ST_EXEC => if en = '0' then ns := ST_WAIT; end if;
            when ST_WAIT => if a = b    then ns := ST_DONE; end if;
            when ST_DONE => if en = '0' then ns := ST_IDLE; end if;
        end case;
        next_state <= ns;
    end process;

    -----------------------------------------------------------------------
    -- State register
    -----------------------------------------------------------------------
    process (clk, rst_n) is
    begin
        if rst_n = '0' then
            state <= ST_IDLE;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    state_o <= state_to_sl(state);
    done    <= '1' when state = ST_DONE else '0';

    -----------------------------------------------------------------------
    -- Command decoder : statement / branch / expression coverage
    -----------------------------------------------------------------------
    process (en, cmd, a, b) is
    begin
        res_i <= (others => '0');
        if en = '1' then
            case cmd is
                when "0001" => res_i <= std_logic_vector(unsigned(a) + unsigned(b));
                when "0010" => res_i <= std_logic_vector(unsigned(a) - unsigned(b));
                when "0011" => res_i <= a xor b;
                when "0100" => res_i <= a(1 downto 0) & b(1 downto 0);
                when others => res_i <= (others => '0');
            end case;
        end if;
    end process;

    result <= res_i;

    -----------------------------------------------------------------------
    -- Compare logic : condition coverage
    -----------------------------------------------------------------------
    process (en, a, b) is
    begin
        zero_i <= '0';
        if (en = '1') and (unsigned(a) > unsigned(b)) then
            zero_i <= '1';
        elsif (en = '1') and (a = b) then
            zero_i <= '1';
        else
            zero_i <= '0';
        end if;
    end process;

    zero <= zero_i;

    -----------------------------------------------------------------------
    -- Parity logic : expression coverage
    -----------------------------------------------------------------------
    process (a, b) is
    begin
        parity_i <= (a(0) xor b(0)) and (a(1) or b(1));
    end process;

    parity <= parity_i;

end architecture rtl;
