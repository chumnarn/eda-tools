--=====================================================================
-- fsm_timer.vhd  --  FSM ตัวจับเวลาแบบ Moore
--   ใช้สอนเรื่อง : การตรวจสอบผลลัพธ์ของ FSM ที่ต้องเลื่อนเวลาไป 1 ns
--                   หลังขอบขึ้นของนาฬิกา (เอาต์พุตเป็น Moore = ลงทะเบียนแล้ว)
--
--   ST_IDLE -> รอ start
--   ST_RUN  -> นับ 0,1,2,3 (cnt เป็น Moore output)
--   ST_DONE -> done = '1'
--=====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fsm_timer is
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    start : in  std_logic;
    cnt   : out std_logic_vector(1 downto 0);   -- Moore output
    done  : out std_logic                      -- Moore output
  );
end entity fsm_timer;

architecture rtl of fsm_timer is
  type state_t is (ST_IDLE, ST_RUN, ST_DONE);
  signal state : state_t := ST_IDLE;
  signal c     : unsigned(1 downto 0) := (others => '0');
begin

  next_state : process (clk) is
  begin
    if rising_edge(clk) then
      if rst = '1' then
        state <= ST_IDLE;
        c     <= (others => '0');
      else
        case state is
          when ST_IDLE =>
            c <= (others => '0');
            if start = '1' then
              state <= ST_RUN;
            end if;

          when ST_RUN =>
            if c = "11" then
              state <= ST_DONE;
            else
              c <= c + 1;
            end if;

          when ST_DONE =>
            if start = '0' then
              state <= ST_IDLE;
            end if;
        end case;
      end if;
    end if;
  end process next_state;

  -- Moore output : ผลลัพธ์ขึ้นกับ state ปัจจุบันเท่านั้น
  cnt  <= std_logic_vector(c);
  done <= '1' when state = ST_DONE else '0';

end architecture rtl;
