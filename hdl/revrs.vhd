library ieee;
use ieee.std_logic_1164.all;

entity revrs is
  port ( input : in  std_logic_vector (31 downto 0);
         mode  : in  std_logic_vector (1 downto 0); -- 0:REV 1:REV16 2:REVSH
         outpt : out std_logic_vector (31 downto 0));
end revrs;

architecture Behavioral of revrs is

begin
  outpt(0 ) <= input(31) when mode = "00" else input(15);
  outpt(1 ) <= input(30) when mode = "00" else input(14);
  outpt(2 ) <= input(29) when mode = "00" else input(13);             
  outpt(3 ) <= input(28) when mode = "00" else input(12);
  outpt(4 ) <= input(27) when mode = "00" else input(11);             
  outpt(5 ) <= input(26) when mode = "00" else input(10);             
  outpt(6 ) <= input(25) when mode = "00" else input(9 );             
  outpt(7 ) <= input(24) when mode = "00" else input(8 );
  outpt(8 ) <= input(23) when mode = "00" else input(7 );  
  outpt(9 ) <= input(22) when mode = "00" else input(6 );  
  outpt(10) <= input(21) when mode = "00" else input(5 );  
  outpt(11) <= input(20) when mode = "00" else input(4 );  
  outpt(12) <= input(19) when mode = "00" else input(3 );  
  outpt(13) <= input(18) when mode = "00" else input(2 );  
  outpt(14) <= input(17) when mode = "00" else input(1 );  
  outpt(15) <= input(16) when mode = "00" else input(0 );                 
  outpt(16) <= input(15) when mode = "00" else input(31) when mode = "01" else input(0 ); 
  outpt(17) <= input(14) when mode = "00" else input(30) when mode = "01" else input(0 ); 
  outpt(18) <= input(13) when mode = "00" else input(29) when mode = "01" else input(0 ); 
  outpt(19) <= input(12) when mode = "00" else input(28) when mode = "01" else input(0 ); 
  outpt(20) <= input(11) when mode = "00" else input(27) when mode = "01" else input(0 ); 
  outpt(21) <= input(10) when mode = "00" else input(26) when mode = "01" else input(0 ); 
  outpt(22) <= input(9 ) when mode = "00" else input(25) when mode = "01" else input(0 ); 
  outpt(23) <= input(8 ) when mode = "00" else input(24) when mode = "01" else input(0 ); 
  outpt(24) <= input(7 ) when mode = "00" else input(23) when mode = "01" else input(0 ); 
  outpt(25) <= input(6 ) when mode = "00" else input(22) when mode = "01" else input(0 ); 
  outpt(26) <= input(5 ) when mode = "00" else input(21) when mode = "01" else input(0 ); 
  outpt(27) <= input(4 ) when mode = "00" else input(20) when mode = "01" else input(0 ); 
  outpt(28) <= input(3 ) when mode = "00" else input(19) when mode = "01" else input(0 ); 
  outpt(29) <= input(2 ) when mode = "00" else input(18) when mode = "01" else input(0 ); 
  outpt(30) <= input(1 ) when mode = "00" else input(17) when mode = "01" else input(0 );              
  outpt(31) <= input(0 ) when mode = "00" else input(16) when mode = "01" else input(0 );
end Behavioral;

