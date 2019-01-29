----------------------------------------------------------------------------------
--
-- Engineer: (c) 2017 rrk
--
-- Create Date: 11/01/2017 11:55:44 PM
-- Design Name: scaler
-- Module Name: ps_control - Behavioral
-- Project Name:
-- Target Devices: 7 series MMCM
-- Tool Versions:
-- Description: DIGITAL PLL controller
-- uses MMCM phase shift control trick
-- to gently shift output frequency about +- 500ppm

-- Revision 0.01 - File Created
-- Additional Comments:
--Copyright (C) 2017  rrk

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

--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


--library UNISIM;
--use UNISIM.VComponents.all;

entity ps_control is
    Port ( psclk : in STD_LOGIC;
           psen : out STD_LOGIC;
           psdone : in STD_LOGIC;
           locked : in STD_LOGIC;
           psincdec : out STD_LOGIC;
           inc_dec : in STD_LOGIC;
           ps_request : in STD_LOGIC);
end ps_control;

architecture Behavioral of ps_control is
signal ps_busy: std_logic:='0';
signal inc_dec_dly1: std_logic;

signal ps_request_dly1: std_logic;
signal ps_request_dly2: std_logic;

begin
ps_controller: process (psclk)
    begin
        if rising_edge(psclk)   then



            inc_dec_dly1 <= inc_dec;
            psincdec <= inc_dec_dly1;
            ps_request_dly1 <= ps_request;
            ps_request_dly2 <= ps_request_dly1;



           if ((ps_request_dly2 = '1') and (ps_busy ='0') and (locked='1')) then
            psen <= '1';
            ps_busy <='1';
           else
            psen <='0';
           end if;
           if psdone = '1' then
            ps_busy <= '0';
           end if;


        end if;


    end process;





end Behavioral;
