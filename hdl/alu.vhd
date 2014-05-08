library ieee;
  use ieee.std_logic_1164.all;


entity alu is
  port ( input_1 : in  std_logic_vector (31 downto 0);
         input_2 : in  std_logic_vector (31 downto 0);
         funct : in  std_logic_vector (4  downto 0);
         flags_current : in std_logic_vector(3 downto 0);
         output : out std_logic_vector (31 downto 0);
         flags_next : out std_logic_vector (3  downto 0);
         flags_update : out std_logic_vector (1  downto 0)); -- 0:none 1:NZ 2:NZC 3:NZCV
end alu;

architecture Behavioral of alu is

begin

output<=input_1;

end Behavioral;

