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
    generic ( N : integer);
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
           funct : in  std_logic_vector (4 downto 0);
           flags_current : in std_logic_vector(3 downto 0);
           output : out std_logic_vector (31 downto 0);
           flags_next : out std_logic_vector (3 downto 0);
           flags_update : out std_logic_vector (1 downto 0));
  end component alu;

  signal instruction_fetched : std_logic_vector (31 downto 0) := (others=>'0');
  
  signal pc_current, pc_next, pc_shifted, pc_plus4 : std_logic_vector (31 downto 0) := (others=>'0');
  signal cond_branch : std_logic;
  
  
  signal reg_read_addr_1, reg_read_addr_2, reg_write_addr : std_logic_vector (3 downto 0) := (others=>'0');
  signal reg_read_data_1, reg_read_data_2, reg_write_data, reg_write_data_pre : std_logic_vector (31 downto 0) := (others=>'0');
  signal reg_write_enable : std_logic := '1';    
  
  signal mem_output  : std_logic_vector (31 downto 0) := (others=>'0');
  signal mem_write_data : std_logic_vector (31 downto 0) := (others=>'0');
  signal mem_write_enable : std_logic := '1';
    
  signal flags_current, flags_next : std_logic_vector (3  downto 0) := (others=>'0');
  signal flags_update : std_logic_vector (1 downto 0) := (others=>'0');
  
  signal alu_function : std_logic_vector (4 downto 0) := (others=>'0');
  signal alu_input_1, alu_input_2, alu_output, alu_output_shifted : std_logic_vector (31 downto 0) := (others=>'0');
  
  signal instr_ok, instr_0, instr_1, instr_2, instr_3, instr_4, instr_5, instr_6, instr_7, instr_8, instr_9 : std_logic;
  signal instr_10, instr_11, instr_12, instr_13, instr_14, instr_15, instr_16, instr_17, instr_18, instr_19 : std_logic;
  
  signal stack_finished : std_logic := '0';
  signal stack_started : std_logic := '0';
  signal listofreg : std_logic_vector (8 downto 0) := (others=>'0');
  signal increasedpointer : std_logic_vector (3 downto 0);
begin
--USELESS
  instr <= instruction_fetched;
--END

  pc_shifted <= "00" & pc_current(31 downto 2);
  alu_output_shifted <= "00" & alu_output(31 downto 2);
  
  memory_block : memory_no_clk 
  generic map (
    N => 29
  )
  port map (
    clk     => clk ,
    write_en=> mem_write_enable ,
    addr_1  => pc_shifted ,
    addr_2  => alu_output_shifted ,
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
  pc_plus4 <= std_logic_vector( unsigned(pc_current) + 4 );
  pc_next <= "00000000000000000000000000000000" when rst = '1' else --reset
             "00000000000000000000000000001000" when instr_17 = '1' else --SWI int
             pc_current when instr_14 = '1' and stack_finished = '0' else
             reg_read_data_2 when instr_5 = '1' and instruction_fetched(9 downto 8) = "11" else
             alu_output when (instr_16 = '1' and cond_branch = '1') or instr_18 = '1' else
             
             
             pc_plus4;
             
  cond_branch <= '1' when (instruction_fetched(11 downto 8) = "0000" and flags_current(2) = '1') or
                          (instruction_fetched(11 downto 8) = "0001" and flags_current(2) = '0') or
                          (instruction_fetched(11 downto 8) = "0010" and flags_current(1) = '1') or
                          (instruction_fetched(11 downto 8) = "0011" and flags_current(1) = '0') or
                          (instruction_fetched(11 downto 8) = "0100" and flags_current(3) = '1') or
                          (instruction_fetched(11 downto 8) = "0101" and flags_current(3) = '0') or
                          (instruction_fetched(11 downto 8) = "0110" and flags_current(0) = '1') or
                          (instruction_fetched(11 downto 8) = "0111" and flags_current(0) = '0') or
                          (instruction_fetched(11 downto 8) = "1000" and flags_current(1) = '1' and flags_current(2) = '0') or
                          (instruction_fetched(11 downto 8) = "1001" and (flags_current(1) = '0' or flags_current(2) = '1')) or
                          (instruction_fetched(11 downto 8) = "1010" and flags_current(3) = flags_current(0)) or
                          (instruction_fetched(11 downto 8) = "1011" and flags_current(3) /= flags_current(0)) or
                          (instruction_fetched(11 downto 8) = "1100" and flags_current(2) = '0' and flags_current(3) = flags_current(0)) or
                          (instruction_fetched(11 downto 8) = "1101" and flags_current(2) = '1' and flags_current(3) /= flags_current(0))
                 else '0';


--Flags updating block
--flag_current(3) == N , flag_current(2) == Z , flag_current(1) == C , flag_current(0) == V
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
  
  --Multiple push/pop
  process(clk)
  begin
    if rising_edge(clk) then 
      if instr_14 = '1' then
        if stack_started = '0' then
          listofreg <= instruction_fetched(8 downto 0);
          stack_started <= '1';
        else
          if listofreg(8) = '1' then
            listofreg(8) <= '0';
            if listofreg(7) = '0' and listofreg(6) = '0' and listofreg(5) = '0' and listofreg(4) = '0' and listofreg(3) = '0' and listofreg(2) = '0' and listofreg(1) = '0' and listofreg(0) = '0' then
              stack_finished <= '1';
            end if;
          elsif listofreg(7) = '1' then
            listofreg(7) <= '0';
            if listofreg(6) = '0' and listofreg(5) = '0' and listofreg(4) = '0' and listofreg(3) = '0' and listofreg(2) = '0' and listofreg(1) = '0' and listofreg(0) = '0' then
              stack_finished <= '1';
            end if;
          elsif listofreg(6) = '1' then
            listofreg(6) <= '0';
            if listofreg(5) = '0' and listofreg(4) = '0' and listofreg(3) = '0' and listofreg(2) = '0' and listofreg(1) = '0' and listofreg(0) = '0' then
              stack_finished <= '1';
            end if;
          elsif listofreg(5) = '1' then
            listofreg(5) <= '0';
            if listofreg(4) = '0' and listofreg(3) = '0' and listofreg(2) = '0' and listofreg(1) = '0' and listofreg(0) = '0' then
              stack_finished <= '1';
            end if;
          elsif listofreg(4) = '1' then
            listofreg(4) <= '0';
            if listofreg(3) = '0' and listofreg(2) = '0' and listofreg(1) = '0' and listofreg(0) = '0' then
              stack_finished <= '1';
            end if;
          elsif listofreg(3) = '1' then
            listofreg(3) <= '0';
            if listofreg(2) = '0' and listofreg(1) = '0' and listofreg(0) = '0' then
              stack_finished <= '1';
            end if;
          elsif listofreg(2) = '1' then
            listofreg(2) <= '0';
            if listofreg(1) = '0' and listofreg(0) = '0' then
              stack_finished <= '1';
            end if;
          elsif listofreg(1) = '1' then
            listofreg(1) <= '0';
            if listofreg(0) = '0' then
              stack_finished <= '1';
            end if;
          else
            listofreg(0) <= '0';
            stack_finished <= '1';
          end if;
            
        end if;
        
      else
        stack_started <= '0';
        stack_finished <= '0';
      end if;
    end if;
  end process;
  
  increasedpointer <= "1111" when listofreg(8) = '1' and instruction_fetched(11) = '0' else
                      "1110" when listofreg(8) = '1' and instruction_fetched(11) = '1' else
                      "0111" when listofreg(7) = '1' else
                      "0110" when listofreg(6) = '1' else
                      "0101" when listofreg(5) = '1' else
                      "0100" when listofreg(4) = '1' else
                      "0011" when listofreg(3) = '1' else
                      "0010" when listofreg(2) = '1' else
                      "0001" when listofreg(1) = '1' else
                      "0000";
  
--Register address decoding  
  reg_read_addr_1 <= '0' & instruction_fetched(5 downto 3) when instr_1 = '1' or instr_2 = '1' or instr_7 = '1' else
                     '0' & instruction_fetched(10 downto 8) when instr_3 = '1' else
                     '0' & instruction_fetched(2 downto 0) when instr_4 = '1' or instr_9 = '1' or instr_10 = '1' else
                     instruction_fetched(7) & instruction_fetched(2 downto 0) when instr_5 = '1' else --high reg
                     "1101" when instr_11 = '1' or (instr_12 = '1' and instruction_fetched(11) ='1') or instr_13 = '1' or instr_14 = '1' else --SP
                     "1111" when instr_16 = '1' or instr_18 = '1' else --PC
                     (others=>'0');
                                 
  reg_read_addr_2 <= '0' & instruction_fetched(8 downto 6) when (instr_2 ='1' and instruction_fetched(10) ='0') or instr_7 = '1' else
                     '0' & instruction_fetched(5 downto 3) when instr_4 ='1' or instr_9 = '1' or instr_10 = '1' else
                     instruction_fetched(6 downto 3) when instr_5 = '1' else --high reg
                     increasedpointer when instr_14 = '1' and instruction_fetched(11) = '0' else
                     (others=>'0');

--ALU input
  alu_input_1 <= pc_plus4 when instr_6 = '1' or (instr_12 = '1' and instruction_fetched(11) ='0') else
                 "000000000000000000000000000" & instruction_fetched(10 downto 6) when (instr_9 = '1' and instruction_fetched(12) ='1') else
                 "0000000000000000000000000" & instruction_fetched(10 downto 6) & "00" when (instr_9 = '1' and instruction_fetched(12) ='0') else
                 "00000000000000000000000000" & instruction_fetched(10 downto 6) & "0" when instr_10 = '1' else
                 reg_read_data_1;
                 
  alu_input_2 <= "000000000000000000000000000" & instruction_fetched(10 downto 6) when instr_1 = '1' else
                 "00000000000000000000000000000" & instruction_fetched(8 downto 6) when (instr_2 = '1' and instruction_fetched(10) ='1')  else
                 X"000000" & instruction_fetched(7 downto 0) when instr_3 = '1' else
                 "0000000000000000000000" & instruction_fetched(7 downto 0) & "00" when instr_6 = '1' or instr_11 = '1' or instr_12 = '1' else
                 (31 downto 9 => instruction_fetched(7)) & instruction_fetched(6 downto 0) & "00" when instr_13 = '1' else
                 "00000000000000000000000" & instruction_fetched(7 downto 0) & '0' when instr_16 = '1' else
                 (31 downto 12 => instruction_fetched(10)) & instruction_fetched(10 downto 0) & '0' when instr_18 = '1' else
                 (31 downto 3 => '0') & "100" when instr_14 = '1' else --SP +- 4
                 reg_read_data_2;

--FIX OP CODE
--0000 AND,0001 EOR,0010 LSL,0011 LSR,0100 ASR,0101 ADC,0110 SBC,0111 ROR,
--1000 TST,1001 NEG,1010 CMP,1011 CMN,1100 ORR,1101 MUL,1110 BIC,1111 MVN
  alu_function <= "0" & instruction_fetched(9 downto 6) when instr_4 = '1' else 
                  "00010" when (instr_1 = '1' and instruction_fetched(12 downto 11) = "00") else --LSL
                  "00011" when (instr_1 = '1' and instruction_fetched(12 downto 11) = "01") else --LSR
                  "00100" when (instr_1 = '1' and instruction_fetched(12 downto 11) = "10") else --ASR
                  "10000" when (instr_3 = '1' and instruction_fetched(12 downto 11) = "00") or (instr_5 = '1' and instruction_fetched(12 downto 11) = "10") else --MOV
                  "01010" when (instr_3 = '1' and instruction_fetched(12 downto 11) = "01") or (instr_5 = '1' and instruction_fetched(12 downto 11) = "01") else --CMP
                  "10001" when (instr_2 = '1' and instruction_fetched(9) = '0') or (instr_3 = '1' and instruction_fetched(12 downto 11) = "10") or (instr_13 = '1' and instruction_fetched(7) ='0') or (instr_5 = '1' and instruction_fetched(12 downto 11) = "00") or instr_6 = '1' or instr_7 = '1' or instr_9 = '1' or instr_10 = '1' or instr_11 = '1' or instr_12 = '1' or instr_16 = '1' or instr_18 = '1' or (instr_14 = '1' and instruction_fetched(11) = '1') else --ADD
                  "10010" when (instr_2 = '1' and instruction_fetched(9) = '1') or (instr_3 = '1' and instruction_fetched(12 downto 11) = "11") or (instr_13 = '1' and instruction_fetched(7) ='1') or (instr_14 = '1' and instruction_fetched(11) = '0') else --SUB
                  (others=>'1');


--Memory write port
  mem_write_enable <= '1' when (instr_9 = '1' and instruction_fetched(11) = '0') or (instr_10 = '1' and instruction_fetched(11) = '0') or (instr_11 = '1' and instruction_fetched(11) = '0') or (instr_14 = '1' and instruction_fetched(11) = '0' and stack_started = '1') else
                      '0';
                           
  mem_write_data <= X"000000" & reg_read_data_1(7 downto 0) when (instr_9 = '1' and instruction_fetched(12) = '1')  else
                    X"0000" & reg_read_data_1(15 downto 0) when instr_10 = '1' else
                    reg_read_data_2 when instr_14 = '1' and instruction_fetched(11) = '0' else
                    reg_read_data_1;
                           
--Register write port    
  reg_write_enable <= '0' when (instr_9 = '1' and instruction_fetched(11) = '0') or (instr_5 = '1' and instruction_fetched(9 downto 8) = "11") or (instr_10 = '1' and instruction_fetched(11) = '0') or (instr_11 = '1' and instruction_fetched(11) = '0') or instr_16 = '1' or instr_18 = '1' or instr_0 = '1' or (instr_14 = '1' and instruction_fetched(11) = '0' and stack_started = '0') else
                      '1';
                      
  reg_write_addr <= '0' & instruction_fetched(2 downto 0) when instr_1 = '1' or instr_2 = '1' or instr_4 = '1' or instr_7 = '1' or instr_9 = '1' or instr_10 = '1' else
                    '0' & instruction_fetched(10 downto 8) when instr_3 = '1' or instr_6 = '1' or instr_11 = '1' or instr_12 = '1' else
                    instruction_fetched(7) & instruction_fetched(2 downto 0) when instr_5 = '1' else
                    "1101" when instr_13 = '1' or (instr_14 = '1' and instruction_fetched(11) = '0' and stack_started = '1') else
                    "1110" when instr_17 = '1' else
                    (others=>'0');
                                  
  reg_write_data_pre <= mem_output when instr_6 = '1' or instr_7 = '1' or instr_9 = '1' or instr_10 = '1' or instr_11 = '1' else
                        pc_plus4 when instr_17 = '1' else
                        alu_output;
                 
  reg_write_data <= X"000000" & reg_write_data_pre(7 downto 0) when (instr_7 = '1' and instruction_fetched(10) = '1') or (instr_9 = '1' and instruction_fetched(12) = '1') else
                    X"0000" & reg_write_data_pre(15 downto 0) when instr_10 = '1' else
                    reg_write_data_pre;

--Instruction basic decoding into 19 groups, depending on the format of instructions
  instr_ok <= '1' when instruction_fetched(31 downto 16) = (31 downto 16 => '0') else '0';
  instr_0  <= '1' when instruction_fetched(31 downto 0) = (31 downto 0 => '0') else '0'; --nop
  instr_1  <= '1' when instr_ok = '1' and instruction_fetched(15 downto 13) = "000" and instruction_fetched(12 downto 11) /= "11" else '0';
  instr_2  <= '1' when instr_ok = '1' and instruction_fetched(15 downto 13) = "000" and instruction_fetched(12 downto 11) = "11" else '0';
  instr_3  <= '1' when instr_ok = '1' and instruction_fetched(15 downto 13) = "001" else '0';
  instr_4  <= '1' when instr_ok = '1' and instruction_fetched(15 downto 10) = "010000" else '0';
  instr_5  <= '1' when instr_ok = '1' and instruction_fetched(15 downto 10) = "010001" else '0';
  instr_6  <= '1' when instr_ok = '1' and instruction_fetched(15 downto 11) = "01001" else '0';  
  instr_7  <= '1' when instr_ok = '1' and instruction_fetched(15 downto 12) = "0101" and instruction_fetched(9) = '0' else '0';  --only implemented LDR, STR not working
  instr_8  <= '1' when instr_ok = '1' and instruction_fetched(15 downto 12) = "0101" and instruction_fetched(9) = '1' else '0';  --not implemented
  instr_9  <= '1' when instr_ok = '1' and instruction_fetched(15 downto 13) = "011" else '0';  
  instr_10 <= '1' when instr_ok = '1' and instruction_fetched(15 downto 12) = "1000" else '0';
  instr_11 <= '1' when instr_ok = '1' and instruction_fetched(15 downto 12) = "1001" else '0';
  instr_12 <= '1' when instr_ok = '1' and instruction_fetched(15 downto 12) = "1010" else '0'; 
  instr_13 <= '1' when instr_ok = '1' and instruction_fetched(15 downto 8 ) = "10110000" else '0'; --only implemented +offset, ignoring sign
  instr_14 <= '1' when instr_ok = '1' and instruction_fetched(15 downto 12) = "1011" and instruction_fetched(10 downto 9) = "10"  else '0'; --multiple push implemented, multiple pop not
  instr_15 <= '1' when instr_ok = '1' and instruction_fetched(15 downto 12) = "1100" else '0';   --TODO
  instr_16 <= '1' when instr_ok = '1' and instruction_fetched(15 downto 12) = "1101" and instruction_fetched(11 downto 8) /= "1111" else '0';
  instr_17 <= '1' when instr_ok = '1' and instruction_fetched(15 downto 8 ) = "11011111" else '0';   --CPSR->SPSR not implemented, only thumb mode enable
  instr_18 <= '1' when instr_ok = '1' and instruction_fetched(15 downto 11) = "11100" else '0'; 
  instr_19 <= '1' when instr_ok = '1' and instruction_fetched(15 downto 12) = "1111" else '0'; --TODO

end Behavioral;