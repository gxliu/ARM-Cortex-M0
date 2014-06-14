----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:32:30 06/13/2014 
-- Design Name: 
-- Module Name:    define - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity define is
end define;

architecture Behavioral of define is

  constant INSTR_NOP : std_logic_vector(4 downto 0) := "00000";
  constant INSTR_MOVE_SHIFTED : std_logic_vector(4 downto 0) := "00001";
  constant INSTR_ADD_SUB : std_logic_vector(4 downto 0) := "00010";
  constant INSTR_MVN_CMP_ADD_SUB : std_logic_vector(4 downto 0) := "00011";
  constant INSTR_ALU : std_logic_vector(4 downto 0) := "00100";
  constant INSTR_HI_REG_BRANCH : std_logic_vector(4 downto 0) := "00101";
  constant INSTR_PC_REL_LOAD : std_logic_vector(4 downto 0) := "00110";
  constant INSTR_LDR_STR_REG_OFF : std_logic_vector(4 downto 0) := "00111";
  constant INSTR_LDR_STR_SIGNED_HALF : std_logic_vector(4 downto 0) := "01000";
  constant INSTR_LDR_STR_IMME_OFF : std_logic_vector(4 downto 0) := "01001";
  constant INSTR_LDR_STR_HALF : std_logic_vector(4 downto 0) := "01010";
  constant INSTR_LDR_STR_SP_OFF : std_logic_vector(4 downto 0) := "01011";
  constant INSTR_LOAD_ADDRESS : std_logic_vector(4 downto 0) := "01100";
  constant INSTR_OFFSET_SP : std_logic_vector(4 downto 0) := "01101";
  constant INSTR_PUSH_POP : std_logic_vector(4 downto 0) := "01110";
  constant INSTR_MULTIPLE_LDR_STR : std_logic_vector(4 downto 0) := "01111";
  constant INSTR_BRANCH : std_logic_vector(4 downto 0) := "10000";
  constant INSTR_SWI : std_logic_vector(4 downto 0) := "10001";
  constant INSTR_JUMP : std_logic_vector(4 downto 0) := "10010";
  constant INSTR_BRANCH_LINK : std_logic_vector(4 downto 0) := "10011";
  constant INSTR_ILLEGAL_OPCODE : std_logic_vector(4 downto 0) := "11111";
  
  constant BRANCH_EQ : std_logic_vector(3 downto 0) := "0000";
  constant BRANCH_NE : std_logic_vector(3 downto 0) := "0001";
  constant BRANCH_CS : std_logic_vector(3 downto 0) := "0010";
  constant BRANCH_CC : std_logic_vector(3 downto 0) := "0011";
  constant BRANCH_MI : std_logic_vector(3 downto 0) := "0100";
  constant BRANCH_PL : std_logic_vector(3 downto 0) := "0101";
  constant BRANCH_VS : std_logic_vector(3 downto 0) := "0110";
  constant BRANCH_VC : std_logic_vector(3 downto 0) := "0111";
  constant BRANCH_HI : std_logic_vector(3 downto 0) := "1000";
  constant BRANCH_LS : std_logic_vector(3 downto 0) := "1001";
  constant BRANCH_GE : std_logic_vector(3 downto 0) := "1010";
  constant BRANCH_LT : std_logic_vector(3 downto 0) := "1011";
  constant BRANCH_GT : std_logic_vector(3 downto 0) := "1100";
  constant BRANCH_LE : std_logic_vector(3 downto 0) := "1101";
  
  
  --flag_current(3) == N , flag_current(2) == Z , flag_current(1) == C , flag_current(0) == V
  constant FLAG_N : integer := 3;
  constant FLAG_Z : integer := 2;
  constant FLAG_C : integer := 1;
  constant FLAG_V : integer := 0;
begin


end Behavioral;

