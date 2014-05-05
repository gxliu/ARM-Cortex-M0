library ieee;
  use ieee.std_logic_1164.all;

entity fadd is
  port ( a   : in  std_logic;
         b   : in  std_logic;
         cin : in  std_logic;
         s   : out std_logic;
         cout: out std_logic);
end entity fadd;

architecture Behavioral of fadd is
begin
  s <= a xor b xor cin;
  cout <= (a and b) or (a and cin) or (b and cin);
end Behavioral;


