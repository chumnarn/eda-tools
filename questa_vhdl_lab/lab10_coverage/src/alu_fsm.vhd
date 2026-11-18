--=============================================================================
--  alu_fsm.vhd -- DUT for the VHDL code coverage lab
-------------------------------------------------------------------------------
--  The design deliberately contains every construct that a code coverage
--  tool is able to measure:
--
--    s  statement   every assignment / every executable line
--    b  branch      if / elsif / else, case / when, loops
--    c  condition   the compound condition in the overflow detector
--    e  expression  the arithmetic and bitwise expressions of the ALU
--    t  toggle      every signal that has to change in both directions
--    f  FSM         the states and the transitions of the control FSM
--
--  The four "lane" accumulators are built with a FOR-GENERATE, so the
--  coverage database contains four separate instance scopes under
--  /tb_alu_fsm/dut/g_lane(*).
--
--  Compile this file WITH coverage, compile the testbench WITHOUT:
--      vcom -2008 src/alu_fsm.vhd +cover=bcesft
--=============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_fsm is
    port (
        clk    : in  std_logic;
        rst_n  : in  std_logic;
        start  : in  std_logic;
        abort  : in  std_logic;
        opcode : in  std_logic_vector(2 downto 0);
        a      : in  std_logic_vector(7 downto 0);
        b      : in  std_logic_vector(7 downto 0);
        dout   : out std_logic_vector(7 downto 0);
        done   : out std_logic;
        state_o: out std_logic_vector(2 downto 0)
    );
end entity alu_fsm;

architecture rtl of alu_fsm is

    constant NLANE : integer := 4;

    type state_t is (ST_IDLE, ST_LOAD, ST_EXEC, ST_WAIT, ST_DONE);
    signal state, next_state : state_t;

    type lane_array is array (0 to NLANE-1) of std_logic_vector(7 downto 0);
    signal lane     : lane_array;
    signal lane_sum : std_logic_vector(7 downto 0);

    signal op_a     : std_logic_vector(7 downto 0) := (others => '0');
    signal op_b     : std_logic_vector(7 downto 0) := (others => '0');
    signal acc_r    : std_logic_vector(7 downto 0) := (others => '0');
    signal ovf      : std_logic := '0';

    function state_to_sl (s : state_t) return std_logic_vector is
    begin
        case s is
            when ST_IDLE => return "000";
            when ST_LOAD => return "001";
            when ST_EXEC => return "010";
            when ST_WAIT => return "011";
            when ST_DONE => return "100";
        end case;
    end function;

begin

    -----------------------------------------------------------------------
    -- FSM : next state logic  ->  FSM coverage (states and transitions)
    -----------------------------------------------------------------------
    next_proc : process (state, start, abort) is
        variable ns : state_t;
    begin
        ns := state;
        case state is
            when ST_IDLE =>
                if start = '1' then
                    ns := ST_LOAD;
                end if;

            when ST_LOAD =>
                ns := ST_EXEC;

            when ST_EXEC =>
                if abort = '1' then
                    ns := ST_IDLE;          -- abort : no result at all
                else
                    ns := ST_WAIT;
                end if;

            when ST_WAIT =>
                ns := ST_DONE;

            when ST_DONE =>
                if start = '0' then
                    ns := ST_IDLE;
                end if;
        end case;
        next_state <= ns;
    end process;

    -----------------------------------------------------------------------
    -- FSM : state register
    -----------------------------------------------------------------------
    state_proc : process (clk, rst_n) is
    begin
        if rst_n = '0' then
            state <= ST_IDLE;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    -----------------------------------------------------------------------
    -- Operand register
    -----------------------------------------------------------------------
    op_proc : process (clk, rst_n) is
    begin
        if rst_n = '0' then
            op_a <= (others => '0');
            op_b <= (others => '0');
        elsif rising_edge(clk) then
            if state = ST_LOAD then
                op_a <= a;
                op_b <= b;
            end if;
        end if;
    end process;

    -----------------------------------------------------------------------
    -- The ALU : CASE branch coverage + expression coverage
    -----------------------------------------------------------------------
    alu_proc : process (opcode, op_a, op_b) is
    begin
        case opcode is
            when "000" => acc_r <= std_logic_vector(unsigned(op_a) + unsigned(op_b));
            when "001" => acc_r <= std_logic_vector(unsigned(op_a) - unsigned(op_b));
            when "010" => acc_r <= op_a and op_b;
            when "011" => acc_r <= op_a xor op_b;
            when others => acc_r <= (others => '0');
        end case;
    end process;

    -----------------------------------------------------------------------
    -- Overflow detector : CONDITION coverage (a compound condition)
    -----------------------------------------------------------------------
    ovf_proc : process (opcode, op_a, op_b) is
    begin
        if (opcode = "000") and (unsigned(op_a) > unsigned(op_b)) then
            ovf <= '1';
        else
            ovf <= '0';
        end if;
    end process;

    -----------------------------------------------------------------------
    -- The four lane accumulators : FOR-GENERATE
    -----------------------------------------------------------------------
    g_lane : for i in 0 to NLANE-1 generate
        lane_proc : process (clk, rst_n) is
        begin
            if rst_n = '0' then
                lane(i) <= (others => '0');
            elsif rising_edge(clk) then
                if state = ST_EXEC then
                    lane(i) <= std_logic_vector(unsigned(lane(i)) + unsigned(op_a));
                elsif state = ST_IDLE then
                    lane(i) <= (others => '0');
                end if;
            end if;
        end process;
    end generate;

    -----------------------------------------------------------------------
    -- Sum of the four lanes : LOOP coverage
    -----------------------------------------------------------------------
    sum_proc : process (lane) is
        variable t : std_logic_vector(7 downto 0);
    begin
        t := (others => '0');
        for i in 0 to NLANE-1 loop
            t := std_logic_vector(unsigned(t) + unsigned(lane(i)));
        end loop;
        lane_sum <= t;
    end process;

    -----------------------------------------------------------------------
    -- Result : CASE + IF + expression coverage
    -----------------------------------------------------------------------
    out_proc : process (state, acc_r, lane_sum, ovf) is
    begin
        case state is
            when ST_DONE =>
                if ovf = '1' then
                    dout <= std_logic_vector(unsigned(acc_r) + unsigned(lane_sum));
                else
                    dout <= acc_r;
                end if;
            when others =>
                dout <= (others => '0');
        end case;
    end process;

    done    <= '1' when state = ST_DONE else '0';
    state_o <= state_to_sl(state);

end architecture rtl;
