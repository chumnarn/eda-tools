-- probe : what does ieee.math_real.uniform really return ?
-- NOTE : "variable s1, s2 : positive := 777;" would give BOTH variables
--        the value 777 -- the seeds have to be declared separately.
library ieee;
use ieee.math_real.all;

entity probe_uniform is
end entity probe_uniform;

architecture sim of probe_uniform is
begin
  process
    variable s1 : positive := 777;
    variable s2 : positive := 888;
    variable t1 : positive := 12345;
    variable t2 : positive := 67890;
    variable u  : real;
  begin
    report "seed (777,888) -- raw values of uniform :" severity note;
    for i in 1 to 8 loop
      uniform(s1, s2, u);
      report "  call " & integer'image(i) &
             " : u = " & real'image(u) &
             "   integer(u*16.0) = " & integer'image(integer(u * 16.0)) &
             "   integer(u*256.0) = " & integer'image(integer(u * 256.0)) severity note;
    end loop;

    report "seed (12345,67890) -- raw values of uniform :" severity note;
    for i in 1 to 8 loop
      uniform(t1, t2, u);
      report "  call " & integer'image(i) &
             " : u = " & real'image(u) &
             "   integer(u*16.0) = " & integer'image(integer(u * 16.0)) &
             "   integer(u*256.0) = " & integer'image(integer(u * 256.0)) severity note;
    end loop;

    std.env.finish;
    wait;
  end process;
end architecture sim;
