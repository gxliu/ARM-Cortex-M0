library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  
library std;
  use std.textio.all;

entity memory_no_clk is
  generic ( N : integer := 1);
  port ( clk     : in  std_logic;
         write_en: in  std_logic;
         addr_1  : in  std_logic_vector (31 downto 0);
         addr_2  : in  std_logic_vector (31 downto 0);  
         data_w2 : in  std_logic_vector (31 downto 0);
         data_r1 : out std_logic_vector (31 downto 0);
         data_r2 : out std_logic_vector (31 downto 0));
end memory_no_clk;

architecture Behavioral of memory_no_clk is
   
  type type_mem_file is array(0 to N) of bit_vector(31 downto 0);
  
  impure function load_from_mem (ram_file_name : in string) return type_mem_file is                                                   
    file ram_file      : text is in ram_file_name;                       
    variable line_name : line;                                 
    variable ram_name  : type_mem_file;                                      
  begin                                                        
    for I in type_mem_file'range loop                                  
      readline (ram_file, line_name);                             
      read (line_name, ram_name(I));                                  
    end loop;                                                    
    return ram_name;                                                  
  end function;
  
  signal mem_file : type_mem_file := load_from_mem("push");
  
  signal addr_1_tmp, addr_2_tmp : std_logic_vector (31 downto 0);
begin

write_port : process(clk)
begin
  if rising_edge(clk) then
    if write_en = '1' then
      mem_file(conv_integer(addr_2)) <= to_bitvector(data_w2);
    end if;
  end if;
end process;

addr_1_tmp <= addr_1 when conv_integer(addr_1) < N and conv_integer(addr_1) > 0 else (others=>'0');
addr_2_tmp <= addr_2 when conv_integer(addr_2) < N and conv_integer(addr_2) > 0 else (others=>'0');

data_r1 <= to_stdlogicvector(mem_file(conv_integer(addr_1_tmp))) when conv_integer(addr_1) < N and conv_integer(addr_1) > 0 else (others=>'0');
data_r2 <= to_stdlogicvector(mem_file(conv_integer(addr_2_tmp))) when conv_integer(addr_2) < N and conv_integer(addr_2) > 0 else (others=>'0');

end Behavioral;