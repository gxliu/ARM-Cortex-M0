library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity shift is
  port ( mode   : in  std_logic_vector (1 downto 0);--0:LSLS 1:LSRS 2:ASRS 3:RORS
         shift  : in  std_logic_vector (4 downto 0);
         input  : in  std_logic_vector (31 downto 0);
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

  component mux32
    port ( in0    : in  std_logic_vector (31 downto 0);
           in1    : in  std_logic_vector (31 downto 0);
           ctl    : in  std_logic;
           result : out std_logic_vector (31 downto 0));
  end component mux_32;
  
begin

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
  
  R1m:  mux32 port map (in0=>input, in1=>R1s,  ctl=>shift(0), result=>R1);
  R2m:  mux32 port map (in0=>R1,    in1=>R2s,  ctl=>shift(1), result=>R2);  
  R4m:  mux32 port map (in0=>R2,    in1=>R4s,  ctl=>shift(2), result=>R4);
  R8m:  mux32 port map (in0=>R4,    in1=>R8s,  ctl=>shift(3), result=>R8);
  R16m: mux32 port map (in0=>R8,    in1=>R16s, ctl=>shift(4), result=>output);

end Behavioral;

