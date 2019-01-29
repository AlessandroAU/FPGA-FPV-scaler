----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 10/05/2017 12:13:44 AM
-- Design Name:
-- Module Name: reset_control - Behavioral
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
-- --Copyright (C) 2017  rrk

--    This program is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.

--    This program is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.

--    You should have received a copy of the GNU General Public License
--   along with this program. If not, see <http://www.gnu.org/licenses/>.
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity reset_control is
    Port ( clk50 : in STD_LOGIC;
           reset_out : out STD_LOGIC :='1' ;
           reset_i2c : out STD_LOGIC :='1' ;
           lock1 : in STD_LOGIC;
           lock2 : in STD_LOGIC;
           lock3 : in STD_LOGIC;
           done : in STD_LOGIC);
end reset_control;

architecture Behavioral of reset_control is

signal reset_counter : unsigned(21 downto 0) := (others => '0');

begin



process (clk50)
begin
   if (clk50'event and clk50 = '1') then
      if (lock1 = '0') or (lock2 = '0') or (lock3 = '0') then
         reset_counter <= (others => '0');
         reset_out <= '1';
         reset_i2c <= '1';
      elsif reset_counter = x"1DFFFF" then
         reset_out <= '0';
         reset_counter <= reset_counter + 1 ;
      elsif reset_counter = x"3FFFFF" then
         reset_i2c <= '0';
      else
         reset_counter <= reset_counter + 1 ;
      end if;
   end if;
end process;


end Behavioral;
