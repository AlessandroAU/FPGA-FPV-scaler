----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 10/03/2017 12:43:00 AM
-- Design Name:
-- Module Name: fifo_writer_5150 - Behavioral
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

-- Copyright (C) 2017  rrk

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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fifo_writer_5150 is

         PORT (

          clk_pixel_27 : in STD_LOGIC;
          video601 : in std_logic_vector (7 downto 0);

          AVID: in STD_LOGIC;
--        VSYNC: in STD_LOGIC;

--        FID: in STD_LOGIC;
          VBLK: in std_logic;

          fifo_data : out std_logic_vector (15 downto 0);
          fifo_wren : out std_logic :='0'

);

end fifo_writer_5150;


architecture Behavioral of fifo_writer_5150 is

signal chroma_delayed : std_logic_vector (7 downto 0);
signal yc_interleave: std_logic;
signal vblk_dly: std_logic;


begin

vblank_lock_to_first_avid: process (avid)

begin

     if rising_edge (avid) then
        vblk_dly <= vblk;
     end if;

end process;



fifo_writer_sequencer:  process (clk_pixel_27)
begin
   if rising_edge (clk_pixel_27) then




        fifo_wren <= yc_interleave;

         chroma_delayed <= video601 ;
         fifo_data <= chroma_delayed & video601;

      if (avid = '0') or (vblk_dly= '1' ) then
         yc_interleave <= '0';
    --   fifo_wren <= '0';

      else
         yc_interleave <= not yc_interleave;

  --     fifo_data <= chroma_delayed & video601;
      end if;
   end if;
end process;


end Behavioral;
