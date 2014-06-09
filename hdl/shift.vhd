library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

entity shift is
  port ( mode   : in  std_logic_vector (1 downto 0);--0:LSLS 1:LSRS 2:ASRS 3:RORS
         shift  : in  std_logic_vector (4 downto 0);
         input  : in  std_logic_vector (31 downto 0);
         carry  : out std_logic;
         output : out std_logic_vector (31 downto 0));
end shift;

architecture Behavioral of shift is
  signal R1s  : std_logic_vector(31 downto 0);
  signal R2s  : std_logic_vector(31 downto 0);
  signal R4s  : std_logic_vector(31 downto 0);
  signal R8s  : std_logic_vector(31 downto 0);
  signal R16s : std_logic_vector(31 downto 0);
  signal R1   : std_logic_vector(31 downto 0);
  signal R2   : std_logic_vector(31 downto 0);
  signal R4   : std_logic_vector(31 downto 0);
  signal R8   : std_logic_vector(31 downto 0);
  signal R16  : std_logic_vector(31 downto 0);
  signal input1s  : std_logic;
  signal input2s  : std_logic_vector(1 downto 0);
  signal input4s  : std_logic_vector(3 downto 0);
  signal input8s  : std_logic_vector(7 downto 0);
  signal input16s : std_logic_vector(15 downto 0);
  
begin
  carry <= '0' when shift = "0000" else
           input(32 - conv_integer(shift)) when mode = "00" else
           input(conv_integer(shift) - 1);

  input1s <= input(31) when mode = "10" else
             input(0) when mode = "11" else
             '0';
  R1s <= input(30 downto 0) & input1s when mode = "00" else 
          input1s & input(31 downto 1);
  
  input2s <= R1(1 downto 0) when mode = "11" else input1s & input1s;
  R2s <= R1(29 downto 0) & input2s when mode = "00" else 
          input2s & R1(31 downto 2);
  
  input4s <= R2(3 downto 0) when mode = "11" else input2s & input2s;
  R4s <= R2(27 downto 0) & input4s when mode = "00" else 
          input4s & R2(31 downto 4);
  
  input8s <= R4(7 downto 0) when mode = "11" else input4s & input4s;
  R8s <= R4(23 downto 0) & input8s when mode = "00" else 
          input8s & R4(31 downto 8);
  
  input16s <= R8(15 downto 0) when mode = "11" else input8s & input8s;
  R16s <= R8(15 downto 0) & input16s when mode = "00" else 
          input16s & R8(31 downto 16);
  
  R1 <= input when shift(0) = '0' else R1s;
  R2 <= R1 when shift(1) = '0' else R2s;
  R4 <= R2 when shift(2) = '0' else R4s;
  R8 <= R4 when shift(3) = '0' else R8s;
  output <= R8 when shift(4) = '0' else R16s;

end Behavioral;

