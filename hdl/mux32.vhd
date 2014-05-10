library ieee;
  use ieee.std_logic_1164.all;

entity mux32 is
  port ( in0 : in  std_logic_vector (31 downto 0);
         in1 : in  std_logic_vector (31 downto 0);
         ctl : in  std_logic;
         result : out  std_logic_vector (31 downto 0));
end mux32;

architecture Behavioral of mux32 is

begin
  result <= in0 when ctl = '0' else in1;
end Behavioral;

