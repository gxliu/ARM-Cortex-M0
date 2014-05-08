library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  
entity regfile_no_clk is
  port ( clk     : in  std_logic;
         write_en: in  std_logic;
         addr_r1 : in  std_logic_vector (3  downto 0);
         addr_r2 : in  std_logic_vector (3  downto 0);
         addr_w1 : in  std_logic_vector (3  downto 0);
         data_w1 : in  std_logic_vector (31 downto 0);
         pc_next : in  std_logic_vector (31 downto 0);
         data_r1 : out std_logic_vector (31 downto 0);
         data_r2 : out std_logic_vector (31 downto 0);
         data_pc : out std_logic_vector (31 downto 0));
end regfile_no_clk;

architecture Behavioral of regfile_no_clk is
  type type_reg_file is array(15 downto 0) of std_logic_vector(31 downto 0) ;
  signal reg_file : type_reg_file := (others => (others => '0'));
begin

write_port : process(clk)
begin
  if rising_edge(clk) then 
    if write_en = '1' then
      reg_file(conv_integer(addr_w1)) <= data_w1;
    end if;
    reg_file(15) <= pc_next;
  end if;
  
end process;

data_r1 <= reg_file(conv_integer(addr_r1));
data_r2 <= reg_file(conv_integer(addr_r2));
data_pc <= reg_file(15);

end Behavioral;

