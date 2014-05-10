library ieee;
  use ieee.std_logic_1164.all;

entity extnd is
  port ( input : in  std_logic_vector (31 downto 0);
         sign  : in  std_logic; -- 1:sign 0:zero extend
         byte  : in  std_logic; -- 1:byte 0:halfword extend
         outpt : out std_logic_vector (31 downto 0));
end extnd;

architecture Behavioral of extnd is

begin
  outpt(7  downto 0 ) <= input(7  downto 0);
  outpt(15 downto 8 ) <= input(15 downto 8)         when byte = '0' else
                         (15 downto 8 => input(7))  when sign = '1' else
                         (15 downto 8 => '0');
  outpt(31 downto 16) <= (31 downto 16 => '0')      when sign = '0' else
                         (31 downto 16 => input(7)) when byte = '1' else
                         (31 downto 16 => input(15));                     

end Behavioral;

