library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


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

  function or_std_logic_vector (vector : in std_logic_vector) return std_logic is  
    variable result : std_logic := '0' ;
  begin                                                        
    for I in vector'range loop                                  
      result := result or vector(I);                                
    end loop;                                                    
    return result;                                                  
  end function;
  
  component shift is
    port ( mode   : in  std_logic_vector (1 downto 0);--0:LSLS 1:LSRS 2:ASRS 3:RORS
           shift  : in  std_logic_vector (4 downto 0);
           input  : in  std_logic_vector (31 downto 0);
           output : out std_logic_vector (31 downto 0));
  end component shift;
  
  component add32 is
    port ( a    : in  std_logic_vector(31 downto 0);
           b    : in  std_logic_vector(31 downto 0);
           cin  : in  std_logic; 
           sum  : out std_logic_vector(31 downto 0);
           cout : out std_logic);
  end component add32;
  
  signal zero, carry_out, overflow : std_logic;
  signal output_mux, output_mul, output_shift, output_add, output_mvn : std_logic_vector(31 downto 0);
  signal carry_mux, carry_shift, carry_in_add, carry_add : std_logic;
  signal shift_mode : std_logic_vector(1 downto 0);
  signal input_add_2 : std_logic_vector(31 downto 0);
begin
--FIX OP CODE
--00000 AND ok
--00001 EOR ok
--00010 LSL ok
--00011 LSR ok
--00100 ASR ok
--00101 ADC ok, V not implemented
--00110 SBC ok, V not implemented
--00111 ROR ok
--01000 TST
--01001 NEG
--01010 CMP ok, V not implemented, same as sub, not implemented not outputting result
--01011 CMN ok, V not implemented, same as add, not implemented not outputting result
--01100 ORR ok
--01101 MUL ok
--01110 BIC ok
--01111 MVN ok
--10000 MOV ok
--10001 ADD ok, V not implemented
--10010 SUB ok, V not implemented

  

  shift_mode <= "00" when funct = "00010" else
                "01" when funct = "00011" else
                "10" when funct = "00100" else
                "11";
                
  shift_block : shift port map (
    mode   => shift_mode ,
    shift  => input_2( 4 downto 0) ,
    input  => input_1 ,
    output => output_shift
  );

  input_add_2 <= input_2 when funct = "00101" or funct = "10001" or funct = "01011" else
                 std_logic_vector(unsigned(not(input_2)) + 1);
                 
  carry_in_add <= flags_current(1) when funct = "00101" or funct = "00110" else
                  '0';
                 
  add_block : add32 port map (
    a    => input_1 ,
    b    => input_add_2 ,
    cin  => carry_in_add ,
    sum  => output_add ,
    cout => carry_add 
  );
  
  
  output_mvn <= not( input_1 );
  
  output_mux <= input_1 and input_2 when funct = "00000" else
                input_1 xor input_2 when funct = "00001" else
                input_1 or input_2 when funct = "01100" else
                input_1 and not(input_2) when funct = "01110" else
                std_logic_vector(signed(input_1) * signed(input_2)) when funct = "01101" else
                output_shift when funct = "00010" or funct = "00011" or funct = "00100" or funct = "00111" else
                output_add when funct = "00101" or funct = "10001" or funct = "00110" or funct = "10010" or funct = "01011" or funct = "01010" else -- wrong "01011" , wrong "01010"
                output_mvn when funct = "01111" else
                input_1 when funct = "10000" else
                (others=> '0');
  output <= output_mux;   

  
  zero <= not ( or_std_logic_vector(output_mux) );


  carry_mux <= carry_shift when funct = "00010" or funct = "00011" or funct = "00100" or funct = "00111" else
               carry_add when funct = "00101" or funct = "10001" or funct = "00110" or funct = "10010" or funct = "01011" or funct = "01010" else
               '0';
               
  overflow <= '1' when funct = "" else
              
              '0';
 
  
  
  flags_next <= output_mux(31) & zero & carry_mux & overflow;
  flags_update <= "01" when funct = "01101" or funct = "00000" or funct = "00001" or funct = "01100" or funct = "01110" or funct = "01000" or funct = "01111" or funct = "10000" or funct = "00010" or funct = "00011" or funct = "00100" or funct = "00111"else
                  "11" when funct = "00101" or funct = "00110" or funct = "01001" or funct = "01010" or funct = "01011" or funct = "10001" or funct = "10010" else
                  "00";
                  
end Behavioral;

