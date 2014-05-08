library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity mcu is
  port ( clk : in  std_logic;
         rst : in  std_logic;
         instr : out std_logic_vector(31 downto 0));
end mcu;

architecture Behavioral of mcu is

  component memory_no_clk is
    port ( clk     : in  std_logic;
           write_en: in  std_logic;
           addr_1  : in  std_logic_vector (31 downto 0);
           addr_2  : in  std_logic_vector (31 downto 0);  
           data_w2 : in  std_logic_vector (31 downto 0);
           data_r1 : out std_logic_vector (31 downto 0);
           data_r2 : out std_logic_vector (31 downto 0));
  end component memory_no_clk;
  
  component regfile_no_clk is
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
  end component regfile_no_clk;
  
  component alu is
    port ( input_1 : in  std_logic_vector (31 downto 0);
           input_2 : in  std_logic_vector (31 downto 0);
           funct : in  std_logic_vector (4  downto 0);
           flags_current : in std_logic_vector(3 downto 0);
           output : out std_logic_vector (31 downto 0);
           flags_next : out std_logic_vector (3  downto 0);
           flags_update : out std_logic_vector (1  downto 0));
  end component alu;

  signal instruction_fetched : std_logic_vector (31  downto 0) := (others=>'0');
  
  signal pc_current, pc_next, pc_shifted : std_logic_vector (31  downto 0) := (others=>'0');
  
  signal reg_read_addr_1, reg_read_addr_2, reg_write_addr : std_logic_vector (3  downto 0) := (others=>'0');
  signal reg_read_data_1, reg_read_data_2, reg_write_data, reg_write_data_pre : std_logic_vector (31  downto 0) := (others=>'0');
  signal reg_write_enable : std_logic := '1';    
  
  signal mem_output  : std_logic_vector (31  downto 0) := (others=>'0');
  signal mem_write_data : std_logic_vector (31  downto 0) := (others=>'0');
  signal mem_write_enable : std_logic := '1';
    
  signal flags_current, flags_next : std_logic_vector (3  downto 0) := (others=>'0');
  signal flags_update : std_logic_vector (1  downto 0) := (others=>'0');
  
  signal alu_function : std_logic_vector (4  downto 0) := (others=>'0');
  signal alu_input_1, alu_input_2, alu_output : std_logic_vector (31  downto 0) := (others=>'0');
  
  signal instr_1, instr_2, instr_3, instr_4, instr_5, instr_6, instr_7, instr_8, instr_9 : std_logic;
  signal instr_10, instr_11, instr_12, instr_13, instr_14, instr_15, instr_16, instr_17, instr_18, instr_19 : std_logic;
  
begin
--USELESS
  instr <= instruction_fetched;
--END

  pc_shifted <= "00" & pc_current(31 downto 2);
  
  memory_block : memory_no_clk port map (
    clk     => clk ,
    write_en=> mem_write_enable ,
    addr_1  => pc_shifted ,
    addr_2  => alu_output ,
    data_w2 => mem_write_data ,
    data_r1 => instruction_fetched ,
    data_r2 => mem_output
  );
  
  register_block : regfile_no_clk port map (
    clk     => clk ,
    write_en=> reg_write_enable ,
    addr_r1 => reg_read_addr_1 ,
    addr_r2 => reg_read_addr_2 ,
    addr_w1 => reg_write_addr ,
    data_w1 => reg_write_data ,
    pc_next => pc_next ,
    data_r1 => reg_read_data_1 ,
    data_r2 => reg_read_data_2 ,
    data_pc => pc_current
  );
  
  alu_block : alu port map (
    input_1 => alu_input_1 ,
    input_2 => alu_input_2 ,
    funct => alu_function ,
    flags_current => flags_current ,
    output => alu_output ,
    flags_next => flags_next ,
    flags_update => flags_update
  );

--PC updating block  
  pc_next <= reg_write_data when (instr_5 = '1' and instruction_fetched(9 downto 8) = "11") or instr_18 = '1' else
             (others=>'0') when rst = '1' else
             std_logic_vector( unsigned(pc_current) + 4 + unsigned(instruction_fetched(10 downto 0) & '0') ) when instr_18 = '1' else
             std_logic_vector( unsigned(pc_current) + 4 );


--Flags updating block
  process(clk)
  begin
    if rising_edge(clk) then 
      case flags_update is --Update mode for flags 0:none 1:NZ 2:NZC 3:NZCV
        when "01" => flags_current <= flags_next(3 downto 2) & flags_current(1 downto 0);
        when "10" => flags_current <= flags_next(3 downto 1) & flags_current(0);
        when "11" => flags_current <= flags_next;
        when others => flags_current <= flags_current;
      end case;
    end if;
  end process;
  
--Register address decoding  
  reg_read_addr_1 <= '0' & instruction_fetched(5 downto 3) when instr_1 = '1' or instr_2 = '1' or instr_7 = '1' else
                     '0' & instruction_fetched(10 downto 8) when instr_3 = '1' else
                     '0' & instruction_fetched(2 downto 0) when instr_4 = '1' or instr_9 = '1' or instr_10 = '1' else
                     instruction_fetched(7) & instruction_fetched(2 downto 0) when instr_5 = '1' else
                     "1101" when instr_11 = '1' or (instr_12 = '1' and instruction_fetched(11) ='1') or instr_13 = '1' else
                     (others=>'0');
                                 
  reg_read_addr_2 <= '0' & instruction_fetched(8 downto 6) when (instr_2 ='1' and instruction_fetched(10) ='0') or instr_7 = '1' else
                     '0' & instruction_fetched(5 downto 3) when instr_4 ='1' or instr_9 = '1' or instr_10 = '1' else
                     instruction_fetched(6 downto 3) when instr_5 = '1' else
                     (others=>'0');

--ALU input
  alu_input_1 <= std_logic_vector( unsigned(pc_current) + 4 ) when instr_6 = '1' or (instr_12 = '1' and instruction_fetched(11) ='0') else
                 "000000000000000000000000000" & instruction_fetched(10 downto 6) when (instr_9 = '1' and instruction_fetched(12) ='1') else
                 "0000000000000000000000000" & instruction_fetched(10 downto 6) & "00" when (instr_9 = '1' and instruction_fetched(12) ='0') else
                 "00000000000000000000000000" & instruction_fetched(10 downto 6) & "0" when instr_10 = '1' else
                 reg_read_data_1;
                 
  alu_input_2 <= "000000000000000000000000000" & instruction_fetched(10 downto 6) when instr_1 = '1' else
                 "00000000000000000000000000000" & instruction_fetched(8 downto 6) when (instr_2 = '1' and instruction_fetched(10) ='1')  else
                 X"000000" & instruction_fetched(7 downto 0) when instr_3 = '1' else
                 "0000000000000000000000" & instruction_fetched(7 downto 0) & "00" when instr_6 = '1' or instr_11 = '1' or instr_12 = '1' else
                 "00000000000000000000000" & instruction_fetched(6 downto 0) & "00" when instr_13 = '1' else
                 reg_read_data_2;

--FIX OP CODE
--0000 AND,0001 EOR,0010 LSL,0011 LSR,0100 ASR,0101 ADC,0110 SBC,0111 ROR,
--1000 TST,1001 NEG,1010 CMP,1011 CMN,1100 ORR,1101 MUL,1110 BIC,1111 MVN
  alu_function <= "000" & instruction_fetched(12 downto 11) when instr_1 = '1' else 
                  "0000" & instruction_fetched(9) when instr_2 = '1' else
                  "000" & instruction_fetched(12 downto 11) when instr_3 = '1' else
                  "0" & instruction_fetched(9 downto 6) when instr_4 = '1' else
                  "000" & instruction_fetched(9 downto 8) when (instr_5= '1' and instruction_fetched(9 downto 8) /= "11") else
                  "00000" when (instr_5= '1' and instruction_fetched(9 downto 8) = "11") else --PASS from alu the 2nd operand
                  "00000" when instr_6 = '1' or instr_7 = '1' or instr_9 = '1' or instr_10 = '1' or instr_11 = '1' or instr_12 = '1' or (instr_13 = '1' and instruction_fetched(7) ='0') else --ADD
                  "00000" when (instr_13 = '1' and instruction_fetched(7) ='1') else --SUB
                  (others=>'0');


--Memory write port
  mem_write_enable <= '1' when (instr_9 = '1' and instruction_fetched(11) = '0') or (instr_10 = '1' and instruction_fetched(11) = '0') or (instr_11 = '1' and instruction_fetched(11) = '0') else
                      '0';
                           
  mem_write_data <= X"000000" & reg_read_data_1(7 downto 0) when (instr_9 = '1' and instruction_fetched(12) = '1')  else
                 X"0000" & reg_read_data_1(15 downto 0) when instr_10 = '1' else
                 reg_read_data_1;
                           
--Register write port    
  reg_write_enable <= '0' when (instr_9 = '1' and instruction_fetched(11) = '0') or (instr_10 = '1' and instruction_fetched(11) = '0') or (instr_11 = '1' and instruction_fetched(11) = '0') else
                      '1';
                      
  reg_write_addr <= '0' & instruction_fetched(2 downto 0) when instr_1 = '1' or instr_2 = '1' or instr_4 = '1' or instr_7 = '1' or instr_9 = '1'or instr_10 = '1' else
                    '0' & instruction_fetched(10 downto 8) when instr_3 = '1' or instr_6 = '1' or instr_11 = '1' or instr_12 = '1' else
                    instruction_fetched(7) & instruction_fetched(2 downto 0) when instr_5 = '1' else
                    "1101" when instr_13 = '1' else
                    (others=>'0');
                                  
  reg_write_data_pre <= mem_output when instr_6 = '1' or instr_7 = '1' or instr_9 = '1' or instr_10 = '1' or instr_11 = '1' else
                        alu_output;
                 
  reg_write_data <= X"000000" & reg_write_data_pre(7 downto 0) when (instr_7 = '1' and instruction_fetched(10) = '1') or (instr_9 = '1' and instruction_fetched(12) = '1') else
                    X"0000" & reg_write_data_pre(15 downto 0) when instr_10 = '1' else
                    reg_write_data_pre;

--Instruction basic decoding into 19 groups, depending on the format of instructions
  instr_1  <= '1' when instruction_fetched(15 downto 13)="000" and instruction_fetched(12 downto 11)/="11" else '0';
  instr_2  <= '1' when instruction_fetched(15 downto 13)="000" and instruction_fetched(12 downto 11)="11" else '0';
  instr_3  <= '1' when instruction_fetched(15 downto 13)="001" else '0';
  instr_4  <= '1' when instruction_fetched(15 downto 10)="010000" else '0';
  instr_5  <= '1' when instruction_fetched(15 downto 10)="010001" else '0';
  instr_6  <= '1' when instruction_fetched(15 downto 11)="01001" else '0';  
  instr_7  <= '1' when instruction_fetched(15 downto 12)="0101" and instruction_fetched(9)='0' else '0';  --STR not working
  instr_8  <= '1' when instruction_fetched(15 downto 12)="0101" and instruction_fetched(9)='1' else '0';  --NOT implemented
  instr_9  <= '1' when instruction_fetched(15 downto 13)="011" else '0';  
  instr_10 <= '1' when instruction_fetched(15 downto 12)="1000" else '0';
  instr_11 <= '1' when instruction_fetched(15 downto 12)="1001" else '0';
  instr_12 <= '1' when instruction_fetched(15 downto 12)="1010" else '0'; 
  instr_13 <= '1' when instruction_fetched(15 downto 8 )="10110000" else '0'; --CHECK Sign
  instr_14 <= '1' when instruction_fetched(15 downto 12)="1011" and instruction_fetched(10 downto 9)="10"  else '0'; --TODO
  instr_15 <= '1' when instruction_fetched(15 downto 12)="1100" else '0';   --TODO
  instr_16 <= '1' when instruction_fetched(15 downto 12)="1101" else '0';   --TODO
  instr_17 <= '1' when instruction_fetched(15 downto 8 )="11011111" and instruction_fetched(9)='0' else '0';   --TODO
  instr_18 <= '1' when instruction_fetched(15 downto 11)="11100" and instruction_fetched(9)='1' else '0'; 
  instr_19 <= '1' when instruction_fetched(15 downto 12)="1111" else '0'; --TODO

end Behavioral;

