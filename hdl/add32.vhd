library ieee;
  use ieee.std_logic_1164.all;

entity add32 is
  port ( a    : in  std_logic_vector(31 downto 0);
         b    : in  std_logic_vector(31 downto 0);
         cin  : in  std_logic; 
         sum  : out std_logic_vector(31 downto 0);
         cout : out std_logic);
end entity add32;

architecture Behavioral of add32 is
  component fadd
    port ( a    : in  std_logic;
           b    : in  std_logic;
           cin  : in  std_logic;
           s    : out std_logic;
           cout : out std_logic);
  end component fadd;
  signal c : std_logic_vector(0 to 32);
begin
  c(0) <= cin;
  
  stages : for I in 0 to 31 generate
             adder : fadd port map(a(I), b(I), c(I) , sum(I), c(I+1));
           end generate stages;
           
  cout <= c(32);
end Behavioral;
