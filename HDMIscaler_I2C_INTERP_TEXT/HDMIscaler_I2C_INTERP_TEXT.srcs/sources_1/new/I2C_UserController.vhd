----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/22/2019 07:25:43 PM
-- Design Name: 
-- Module Name: I2C_UserController - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity I2C_UserController is
    Port ( 
           clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           ena : out STD_LOGIC;
           addr : out STD_LOGIC_VECTOR (6 downto 0);
           rw : out STD_LOGIC;
           data_wr : out STD_LOGIC_VECTOR (7 downto 0);
           data_rd : in STD_LOGIC_VECTOR (7 downto 0);
           ack_error : in STD_LOGIC;
           busy : in STD_LOGIC := '0';           
           statusREG1 : out STD_LOGIC_VECTOR (7 downto 0)
           );
           
end I2C_UserController;

architecture Behavioral of I2C_UserController is

        signal I2C_sendDelayCounter : INTEGER;
        --signal I2C_sendDelay : STD_LOGIC_VECTOR(23 downto 0) := x"30000";
        signal busy_prev : STD_LOGIC := '0';
        constant I2C_SlaveAddr : STD_LOGIC_VECTOR(6 downto 0) := "1011101";
        signal I2C_Stage : INTEGER;
        
        constant PAL_NTSC_REG : STD_LOGIC_VECTOR (7 downto 0) := x"88";
        
        signal beginSendDelay : std_logic := '0';
                
        type InitAddrsVals is ARRAY(0 TO 3) OF std_logic_vector(7 DOWNTO 0);    
   
       
        constant InitAddr : InitAddrsVals := (x"ff", x"03", x"0F", x"0D");  -- first values of 0xff to have some meaningless data as it seems to get corrupted 
        constant InitVals : InitAddrsVals := (x"ff", x"AF", x"02", x"40");
        signal Addr_or_Val: STD_LOGIC := '0'; --are we currently sending the address or the value?
        signal InitDone: STD_LOGIC := '0'; --are we currently sending the address or the value?
        signal Curr_I2C_Addr: INTEGER := 0; --counter to keep track of current address we are up too
        signal sendStage : INTEGER := 0;
        signal Prev_sendStage : INTEGER := 1;
        
        signal WaitforNotBusy : STD_LOGIC := '0';
        signal DataIN : STD_LOGIC_VECTOR (7 downto 0);
        
        
        --signal 

begin

process (clk)
    begin
    if rising_edge(clk) and reset = '0' then
    
--    if (reset = '1') then
--        Curr_I2C_Addr <= 0;
--        beginSendDelay <= '0';
--        I2C_sendDelayCounter <= 0;
--        sendStage <= 0;
--    else
    
         busy_prev <= busy;
         if(busy_prev = '0' and busy = '1') THEN --i2c busy just went high, so we latached in our cmd.
            sendStage <= sendStage + 1;
           end if; 

            if (InitDone = '0') then
                case sendStage is  -- this is the init cas
                
                    when 0 =>
                    
                        ena <= '1';
                        addr <= I2C_SlaveAddr;
                        rw <= '0'; --0 is a write
                        data_wr <= InitAddr(Curr_I2C_Addr);
    
                    when 1 =>
                         
                        addr <= I2C_SlaveAddr;
                        rw <= '0'; --1 is a write
                        data_wr <= InitVals(Curr_I2C_Addr);
                        
                    when 2 =>
                    
                        ena <= '0';
                        
                        if (busy = '0') then
                        
                            if I2C_sendDelayCounter < 10000 then
                                I2C_sendDelayCounter <= I2C_sendDelayCounter + 1;
                            else
                                I2C_sendDelayCounter <= 0;
                                sendStage <= 0;
                                
                                Curr_I2C_Addr <= Curr_I2C_Addr + 1;
                                
                                if (Curr_I2C_Addr = 3) then
                                    InitDone <= '1';
                                end if;
                            
                        end if;
                            
                        end if;
                        
                    when others => null;     
                end case; 
              else
              
              case sendStage is --- "steady state" case, ie do this all the time in this case we read status reg 1 every 0.2secs. 
              
                  when 0 =>
                    ena <= '1';
                    rw <= '0';
                    data_wr <= x"88";
                    addr <= I2C_SlaveAddr;
                                     
                  when 1 =>
                  
                      ena <= '0';
                      
                    if(busy = '0') then
                       if I2C_sendDelayCounter < 5000 then
                           I2C_sendDelayCounter <= I2C_sendDelayCounter + 1;
                       else
                            sendStage <= sendStage +1;   
                       end if;    
                    end if;
                    
                  when 2 =>
                      
                    ena <= '1';   
                    rw <= '1';
                    data_wr <= x"88";    
                              
                  when 3 =>                  
                    
                    ena <= '0';
                    if(busy = '0') then
                        statusREG1 <= data_rd;
                    
                        if I2C_sendDelayCounter < 10000000 then
                            I2C_sendDelayCounter <= I2C_sendDelayCounter + 1;
                        else
                            I2C_sendDelayCounter <= 0;
                            sendStage <= 0;
                            
                        end if;
                        
                    end if;
                    
                  when others => null;
              end case;
                
              end if;
  end if;  

end process;


end Behavioral;
