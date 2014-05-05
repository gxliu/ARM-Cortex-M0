library ieee;
  use ieee.std_logic_1164.all;

entity badd32 is
  port ( a       : in  std_logic_vector(2 downto 0);  -- Booth multiplier
         b       : in  std_logic_vector(31 downto 0); -- multiplicand
         sum_in  : in  std_logic_vector(31 downto 0); -- sum input
         sum_out : out std_logic_vector(31 downto 0); -- sum output
         prod    : out std_logic_vector(1 downto 0)); -- 2 bits of product
end entity badd32;

architecture Behavioral of badd32 is
  -- Note: Most of the multiply algorithm is performed in here.
  -- multiplier action
  --     a             bb
  -- i+1 i i-1         multiplier,  shift partial result two places each stage
  --  0  0  0   0    pass along
  --  0  0  1   +b   add
  --  0  1  0   +b   add
  --  0  1  1   +2b  shift add
  --  1  0  0   -2b  shift subtract
  --  1  0  1   -b   subtract
  --  1  1  0   -b   subtract
  --  1  1  1   0    pass along
  component add32
  port ( a    : in  std_logic_vector(31 downto 0);
         b    : in  std_logic_vector(31 downto 0);
         cin  : in  std_logic; 
         sum  : out std_logic_vector(31 downto 0);
         cout : out std_logic);
  end component add32;
  component fadd
  port ( a    : in  std_logic;
         b    : in  std_logic;
         cin  : in  std_logic;
         s    : out std_logic;
         cout : out std_logic);
  end component fadd;
  subtype word is std_logic_vector(31 downto 0);
  signal bb        : word;
  signal psum      : word;
  signal b_bar     : word;
  signal two_b     : word;
  signal two_b_bar : word;
  signal cout      : std_logic;
  signal cin       : std_logic;
  signal topbit    : std_logic;
  signal topout    : std_logic;
  signal nc1       : std_logic;
begin
  b_bar <= not b;
  two_b <= b(30 downto 0) & '0';
  two_b_bar <= not two_b;
  bb <= b when a="001" or a="010"           -- 5-input mux
        else two_b when a="011"
        else two_b_bar when a="100"         -- cin=1
        else b_bar when a="101" or a="110"  -- cin=1
        else x"00000000";
  cin <= '1' when a="100" or a="101" or a="110"
         else '0';
  topbit <= b(31) when a="001" or a="010" or a="011"
            else b_bar(31) when a="100" or a="101" or a="110"
            else '0';

  a1: add32 port map(sum_in, bb, cin, psum, cout);
  a2: fadd port map(sum_in(31), topbit, cout, topout, nc1);

  sum_out(29 downto 0) <= psum(31 downto 2);
  sum_out(31) <= topout;
  sum_out(30) <= topout;
  prod <= psum(1 downto 0);
end Behavioral;