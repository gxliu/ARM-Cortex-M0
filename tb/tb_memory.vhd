library ieee;
  use ieee.std_logic_1164.ALL;
  use ieee.numeric_std.ALL;
 
 
ENTITY tb_memory IS
END tb_memory;
 
ARCHITECTURE behavior OF tb_memory IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT memory_no_clk
    PORT(
         clk : IN  std_logic;
         write_en : IN  std_logic;
         addr_1 : IN  std_logic_vector(31 downto 0);
         addr_2 : IN  std_logic_vector(31 downto 0);
         data_w2 : IN  std_logic_vector(31 downto 0);
         data_r1 : OUT  std_logic_vector(31 downto 0);
         data_r2 : OUT  std_logic_vector(31 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal write_en : std_logic := '0';
   signal addr_1 : std_logic_vector(31 downto 0) := (others => '0');
   signal addr_2 : std_logic_vector(31 downto 0) := (others => '0');
   signal data_w2 : std_logic_vector(31 downto 0) := (others => '0');

 	--Outputs
   signal data_r1 : std_logic_vector(31 downto 0);
   signal data_r2 : std_logic_vector(31 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: memory_no_clk PORT MAP (
          clk => clk,
          write_en => write_en,
          addr_1 => addr_1,
          addr_2 => addr_2,
          data_w2 => data_w2,
          data_r1 => data_r1,
          data_r2 => data_r2
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
 
  addr1_process :process
  begin
    if unsigned(addr_1) = 7 then
      addr_1 <= (others=>'0');
    else
      addr_1 <= std_logic_vector(unsigned(addr_1) + 1);
    end if;
    wait for 2*clk_period;
  end process;


  addr2_process :process
  begin
    if unsigned(addr_2) = 7 then
      addr_2 <= (others=>'0');
    else
      addr_2 <= std_logic_vector(unsigned(addr_2) + 1);
    end if;
    wait for 3*clk_period;
  end process;
  
  write_en_process :process
  begin
    write_en <= '1';
    wait for 2*clk_period;
    write_en <= '0';
    wait for 8*clk_period;
  end process;
  
  data_process :process
  begin
    data_w2 <= std_logic_vector(unsigned(data_w2) + 1);
    wait for clk_period;
  end process;
END;
