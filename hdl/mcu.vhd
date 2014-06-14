library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.std_logic_unsigned.all;
  use work.define.all;
  
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
           funct : in  std_logic_vector (4 downto 0);
           flags : in std_logic_vector(3 downto 0);
           output : out std_logic_vector (31 downto 0);
           flags_next : out std_logic_vector (3 downto 0);
           flags_update : out std_logic_vector (1 downto 0));
  end component alu;

  signal instruction_fetched : std_logic_vector (31 downto 0) := (others=>'0');
  
  signal pc_current, pc_next, pc_shifted, pc_plus_4 : std_logic_vector (31 downto 0) := (others=>'0');
  signal cond_branch : std_logic;
  
  
  signal reg_read_addr_1, reg_read_addr_2, reg_write_addr : std_logic_vector (3 downto 0) := (others=>'0');
  signal reg_read_data_1, reg_read_data_2, reg_write_data, reg_write_data_pre : std_logic_vector (31 downto 0) := (others=>'0');
  signal reg_write_enable : std_logic := '1';    
  
  signal mem_output  : std_logic_vector (31 downto 0) := (others=>'0');
  signal mem_write_data : std_logic_vector (31 downto 0) := (others=>'0');
  signal mem_write_enable : std_logic := '1';
    
  signal flags, flags_next : std_logic_vector (3  downto 0) := (others=>'0');
  signal flags_update : std_logic_vector (1 downto 0) := (others=>'0');
  
  signal alu_function : std_logic_vector (4 downto 0) := (others=>'0');
  signal alu_input_1, alu_input_2, alu_output, alu_output_shifted : std_logic_vector (31 downto 0) := (others=>'0');
  
  signal instr_ok, instr_0, instr_1, instr_2, instr_3, instr_4, instr_5, instr_6, instr_7, instr_8, instr_9 : std_logic;
  signal instr_10, instr_11, instr_12, instr_13, instr_14, instr_15, instr_16, instr_17, instr_18, instr_19 : std_logic;
  
  signal stack_finished : std_logic := '0';
  signal stack_started : std_logic := '0';
  signal listofreg : std_logic_vector (8 downto 0) := (others=>'0');
  signal increasedpointer : std_logic_vector (3 downto 0);
  
  signal instr_cat : std_logic_vector (4 downto 0);
  
  signal address, address_pc_lr : std_logic_vector (3 downto 0);
  
  signal reglist, next_reglist, address_encoded : std_logic_vector (7 downto 0);
  
  
  type state_type is (s_wait,s_push_pop,s_finish,s3);  --type of state machine.
  signal state_current, state_next : state_type;  
  
begin
--USELESS
  instr <= instruction_fetched;
--END

  pc_shifted <= "00" & pc_current(31 downto 2);
  alu_output_shifted <= "00" & alu_output(31 downto 2);
  
  memory_block : memory_no_clk port map (
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
    flags => flags ,
    output => alu_output ,
    flags_next => flags_next ,
    flags_update => flags_update
  );

--PC updating block  
  pc_plus_4 <= std_logic_vector( unsigned(pc_current) + 4 );
  pc_next <= "00000000000000000000000000000000" when rst = '1' else --reset
             "00000000000000000000000000001000" when instr_17 = '1' else --SWI int
             pc_current when instr_cat = INSTR_PUSH_POP and state_current /= s_finish else
             reg_read_data_2 when instr_5 = '1' and instruction_fetched(9 downto 8) = "11" else
             alu_output when (instr_16 = '1' and cond_branch = '1') or instr_18 = '1' else
             
             
             pc_plus_4;
             
  cond_branch <= '1' when (instruction_fetched(11 downto 8) = "0000" and flags(2) = '1') or
                          (instruction_fetched(11 downto 8) = "0001" and flags(2) = '0') or
                          (instruction_fetched(11 downto 8) = "0010" and flags(1) = '1') or
                          (instruction_fetched(11 downto 8) = "0011" and flags(1) = '0') or
                          (instruction_fetched(11 downto 8) = "0100" and flags(3) = '1') or
                          (instruction_fetched(11 downto 8) = "0101" and flags(3) = '0') or
                          (instruction_fetched(11 downto 8) = "0110" and flags(0) = '1') or
                          (instruction_fetched(11 downto 8) = "0111" and flags(0) = '0') or
                          (instruction_fetched(11 downto 8) = "1000" and flags(1) = '1' and flags(2) = '0') or
                          (instruction_fetched(11 downto 8) = "1001" and (flags(1) = '0' or flags(2) = '1')) or
                          (instruction_fetched(11 downto 8) = "1010" and flags(3) = flags(0)) or
                          (instruction_fetched(11 downto 8) = "1011" and flags(3) /= flags(0)) or
                          (instruction_fetched(11 downto 8) = "1100" and flags(2) = '0' and flags(3) = flags(0)) or
                          (instruction_fetched(11 downto 8) = "1101" and flags(2) = '1' and flags(3) /= flags(0))
                 else '0';

--Flags updating block
--flag_current(3) == N , flag_current(2) == Z , flag_current(1) == C , flag_current(0) == V
  process(clk, rst)
  begin
    if rst = '1' then
      flags <= "0000";
    elsif rising_edge(clk) then 
      case flags_update is --Update mode for flags 0:none 1:NZ 2:NZC 3:NZCV
        when "01" => flags(3 downto 2) <= flags_next(3 downto 2);
        when "10" => flags(3 downto 1) <= flags_next(3 downto 1);
        when "11" => flags <= flags_next;
        when others => flags <= flags;
      end case;
    end if;
  end process;
  
  --Multiple push/pop
  process(clk, rst)
  begin
    if rst = '1' then
      listofreg <= (others => '0');
    elsif rising_edge(clk) then 
      case state_current is
      
        when s_wait =>
          listofreg <= instruction_fetched(8 downto 0);
          if instr_cat = INSTR_PUSH_POP then
            state_next <= s_push_pop ;
          end if;
          
        when s_push_pop =>
          listofreg <= listofreg_next;
          if listofreg_next = (7 downto 0 => '0') then
            state_next <= s_finish;
          end if;
          
        when s_finish =>
          state_next <= s_wait;
      end case;
    end if;
  end process;

  address_pc_lr <= "1111" when instruction_fetched(11) = '0' else "1110";
  
  address_encoded <= listofreg and std_logic_vector(unsigned(not(listofreg)) + 1);
  listofreg_next <= listofreg and not(address_encoded);
  
  with address_encoded select
    address <= "0000" when "00000001",
               "0001" when "00000010",
               "0011" when "00000100",
               "0100" when "00001000",
               "0101" when "00010000",
               "0110" when "00100000",
               "0111" when "01000000",
               address_pc_lr when "10000000",
               "0000" when OTHERS;
  
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
  alu_input_1 <= pc_plus_4 when instr_6 = '1' or (instr_12 = '1' and instruction_fetched(11) ='0') else
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
                        pc_plus_4 when instr_17 = '1' else
                        alu_output;
             
--  with instr_cat select
--    reg_write_data_pre <= mem_output when  ,
--                          mem_output when  ,
--                          mem_output when  ,
--                          mem_output when  ,
--                          mem_output when  ,
--                          mem_output when  ,
--                          
              
--  reg_write_data <= X"000000" & reg_write_data_pre(7 downto 0) when (instr_7 = '1' and instruction_fetched(10) = '1') or (instr_9 = '1' and instruction_fetched(12) = '1') else
--                    X"0000" & reg_write_data_pre(15 downto 0) when instr_10 = '1' else
--                    reg_write_data_pre;


  with instr_cat select
    reg_write_data <= X"000000" & reg_write_data_pre(7 downto 0) when "00000001", --instr_7 = '1' and instruction_fetched(10) = '1'
                      X"000000" & reg_write_data_pre(7 downto 0) when "00000001", --instr_9 = '1' and instruction_fetched(12) = '1'
                      X"0000" & reg_write_data_pre(15 downto 0) when INSTR_LDR_STR_HALF,
                      reg_write_data_pre when OTHERS;
--Instruction basic decoding into 19 groups, depending on the format of instructions
--  instr_ok <= '1' when instruction_fetched(31 downto 16) = (31 downto 16 => '0') else '0';
--  instr_0  <= '1' when 
--  instr_1  <= '1' when instr_ok = '1' and instruction_fetched(15 downto 13) = "000" and instruction_fetched(12 downto 11) /= "11" else '0';
--  instr_2  <= '1' when instr_ok = '1' and instruction_fetched(15 downto 13) = "000" and instruction_fetched(12 downto 11) = "11" else '0';
--  instr_3  <= '1' when instr_ok = '1' and instruction_fetched(15 downto 13) = "001" else '0';
--  instr_4  <= '1' when instr_ok = '1' and instruction_fetched(15 downto 10) = "010000" else '0';
--  instr_5  <= '1' when instr_ok = '1' and instruction_fetched(15 downto 10) = "010001" else '0';
--  instr_6  <= '1' when instr_ok = '1' and instruction_fetched(15 downto 11) = "01001" else '0';  
--  instr_7  <= '1' when instr_ok = '1' and instruction_fetched(15 downto 12) = "0101" and instruction_fetched(9) = '0' else '0';  --only implemented LDR, STR not working
--  instr_8  <= '1' when instr_ok = '1' and instruction_fetched(15 downto 12) = "0101" and instruction_fetched(9) = '1' else '0';  --not implemented
--  instr_9  <= '1' when instr_ok = '1' and  else '0';  
--  instr_10 <= '1' when instr_ok = '1' and else '0';
--  instr_11 <= '1' when instr_ok = '1' and else '0';
--  instr_12 <= '1' when instr_ok = '1' and else '0'; 
--  instr_13 <= '1' when instr_ok = '1' and else '0'; 
--  instr_14 <= '1' when instr_ok = '1' and  else '0'; 
--  instr_15 <= '1' when instr_ok = '1' and  else '0'; 
--  instr_16 <= '1' when instr_ok = '1' and else '0';
--  instr_17 <= '1' when instr_ok = '1' and  else '0'; 
--  instr_18 <= '1' when instr_ok = '1' and lse '0'; 
--  instr_19 <= '1' when instr_ok = '1' and  else '0';

  instr_cat <= INSTR_NOP when instruction_fetched(31 downto 0) = (31 downto 0 => '0') else --nop
               INSTR_MOVE_SHIFTED when instruction_fetched(15 downto 13) = "000" and instruction_fetched(12 downto 11) /= "11" else
               INSTR_ADD_SUB when instruction_fetched(15 downto 13) = "000" and instruction_fetched(12 downto 11) = "11" else
               INSTR_MVN_CMP_ADD_SUB when instruction_fetched(15 downto 13) = "001" else
               INSTR_ALU when instruction_fetched(15 downto 10) = "010000" else
               INSTR_HI_REG_BRANCH  when instruction_fetched(15 downto 10) = "010001" else
               INSTR_PC_REL_LOAD when instruction_fetched(15 downto 11) = "01001" else
               INSTR_LDR_STR_REG_OFF when instruction_fetched(15 downto 12) = "0101" and instruction_fetched(9) = '0' else --only implemented LDR, STR not working
               INSTR_LDR_STR_SIGNED_HALF when instruction_fetched(15 downto 12) = "0101" and instruction_fetched(9) = '1' else --not implemented
               INSTR_LDR_STR_IMME_OFF when instruction_fetched(15 downto 13) = "011" else
               INSTR_LDR_STR_HALF when instruction_fetched(15 downto 12) = "1000" else
               INSTR_LDR_STR_SP_OFF when instruction_fetched(15 downto 12) = "1001" else
               INSTR_LOAD_ADDRESS when instruction_fetched(15 downto 12) = "1010" else
               INSTR_OFFSET_SP when instruction_fetched(15 downto 8 ) = "10110000" else --only implemented +offset, ignoring sign
               INSTR_PUSH_POP when instruction_fetched(15 downto 12) = "1011" and instruction_fetched(10 downto 9) = "10" else --multiple push implemented, multiple pop not
               INSTR_MULTIPLE_LDR_STR when instruction_fetched(15 downto 12) = "1100" else  --TODO
               INSTR_BRANCH when instruction_fetched(15 downto 12) = "1101" and instruction_fetched(11 downto 8) /= "1111" else
               INSTR_SWI when instruction_fetched(15 downto 8 ) = "11011111" else  --CPSR->SPSR not implemented, only thumb mode enable
               INSTR_JUMP when instruction_fetched(15 downto 11) = "11100" else
               INSTR_BRANCH_LINK when instruction_fetched(15 downto 12) = "1111" else --TODO
               INSTR_ILLEGAL_OPCODE; --invalid command
               
end Behavioral;