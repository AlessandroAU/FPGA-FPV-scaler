----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz<
-- 
-- Module Name: hdmi_io - Behavioral
--
-- Description: Wrapper for input and output components of HDMI data stream
--
------------------------------------------------------------------------------------
-- The MIT License (MIT)
-- 
-- Copyright (c) 2015 Michael Alan Field
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
------------------------------------------------------------------------------------
----- Want to say thanks? ----------------------------------------------------------
------------------------------------------------------------------------------------
--
-- This design has taken many hours - with the industry metric of 30 lines
-- per day, it is equivalent to about 6 months of work. I'm more than happy
-- to share it if you can make use of it. It is released under the MIT license,
-- so you are not under any onus to say thanks, but....
-- 
-- If you what to say thanks for this design how about trying PayPal?
--  Educational use - Enough for a beer
--  Hobbyist use    - Enough for a pizza
--  Research use    - Enough to take the family out to dinner
--  Commercial use  - A weeks pay for an engineer (I wish!)
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity hdmi_io is
    port (
    --  clk100        : in STD_LOGIC;
        pixel_clk : in std_logic;
        pixel_clk_x5 : in std_logic;
        reset  : in std_logic;
        -------------
        -- HDMI out
        -------------
  --      hdmi_tx_cec   : inout std_logic;
        hdmi_tx_clk_n : out   std_logic;
        hdmi_tx_clk_p : out   std_logic;
  --      hdmi_tx_hpd   : in    std_logic;
  --      hdmi_tx_rscl  : out  std_logic;
  --      hdmi_tx_rsda  : inout std_logic;
        hdmi_tx_p     : out   std_logic_vector(2 downto 0);
        hdmi_tx_n     : out   std_logic_vector(2 downto 0);
        

        -------------------------------

        
        -----------------------------------
        -- VGA data to be converted to HDMI
        -----------------------------------
        out_blank : in  std_logic;
        out_hsync : in  std_logic;
        out_vsync : in  std_logic;
        out_red   : in  std_logic_vector(7 downto 0);
        out_green : in  std_logic_vector(7 downto 0);
        out_blue  : in  std_logic_vector(7 downto 0)
       -------------------------------------
 
        

    );
end entity;

architecture Behavioral of hdmi_io is
 --   component edid_rom is
 --   port ( clk      : in    std_logic;
 --          sclk_raw : in    std_logic;
 --          sdat_raw : inout std_logic;
 --          edid_debug : out std_logic_vector(2 downto 0));
 --   end component;


    
   -- signal rgb_blank : std_logic;
   -- signal rgb_hsync : std_logic;
   -- signal rgb_vsync : std_logic;
   -- signal rgb_R     : std_logic_vector(11 downto 0);
   -- signal rgb_G     : std_logic_vector(11 downto 0);  -- G or Y
   -- signal rgb_B     : std_logic_vector(11 downto 0);   -- R or Cr

    component DVID_output is
    Port ( 
        pixel_clk       : in std_logic;  -- Driven by BUFG
        pixel_io_clk_x1 : in std_logic;  -- Driven by BUFIO
        pixel_io_clk_x5 : in std_logic;  -- Driven by BUFIO
         reset     : in std_logic;
        -- VGA Signals
        vga_blank       : in  std_logic;
        vga_hsync       : in  std_logic;
        vga_vsync       : in  std_logic;
        vga_red         : in  std_logic_vector(7 downto 0);
        vga_blue        : in  std_logic_vector(7 downto 0);
        vga_green       : in  std_logic_vector(7 downto 0);
        data_valid      : in  std_logic;
        
        --- HDMI out
        tmds_out_clk    : out   std_logic;
        tmds_out_ch0    : out   std_logic;
        tmds_out_ch1    : out   std_logic;
        tmds_out_ch2    : out   std_logic
    );
    end component;
   
    -- Clocks for the pixel clock domain
    signal pixel_clk_i     : std_logic;
    signal pixel_io_clk_x1 : std_logic;
    signal pixel_io_clk_x5 : std_logic;



    signal tmds_out_clk : std_logic;
    signal tmds_out_ch0 : std_logic;
    signal tmds_out_ch1 : std_logic;
    signal tmds_out_ch2 : std_logic;

    signal detect_sr : std_logic_vector(7 downto 0) := (others => '0');
begin
 --   pixel_clk <= pixel_clk_i;



------------------------------------------------
-- Outputting video data
-----------------------------------------------
i_DVID_output: DVID_output port map ( 
        pixel_clk       => pixel_clk,
        pixel_io_clk_x1 => pixel_clk,
        pixel_io_clk_x5 => pixel_clk_x5,
        reset => reset, 
        data_valid      => '1',
        -- VGA Signals
        vga_blank     => out_blank,
        vga_hsync     => out_hsync,
        vga_vsync     => out_vsync,
        vga_red       => out_red,
        vga_blue      => out_blue,
        vga_green     => out_green,
        
        --- HDMI out
        tmds_out_clk  => tmds_out_clk,
        tmds_out_ch0  => tmds_out_ch0,
        tmds_out_ch1  => tmds_out_ch1,
        tmds_out_ch2  => tmds_out_ch2
    );

    -----------------------------
    -- Other HDMI control signals
    -----------------------------
--    hdmi_tx_rsda  <= 'Z';
--    hdmi_tx_cec   <= 'Z';
--    hdmi_tx_rscl  <= '1';

    -----------------
    -- Output buffers
    -----------------
out_clk_buf: OBUFDS generic map ( IOSTANDARD => "TMDS_33",  SLEW => "FAST")
    port map ( O  => hdmi_tx_clk_p, OB => hdmi_tx_clk_n, I => tmds_out_clk);
    
out_tx0_buf: OBUFDS generic map ( IOSTANDARD => "TMDS_33",  SLEW => "FAST")
    port map ( O  => hdmi_tx_p(0), OB => hdmi_tx_n(0), I  => tmds_out_ch0);

out_tx1_buf: OBUFDS generic map ( IOSTANDARD => "TMDS_33",  SLEW => "FAST")
    port map ( O  => hdmi_tx_p(1), OB => hdmi_tx_n(1), I  => tmds_out_ch1);

out_tx2_buf: OBUFDS generic map ( IOSTANDARD => "TMDS_33",  SLEW => "FAST")
    port map ( O  => hdmi_tx_p(2), OB => hdmi_tx_n(2), I  => tmds_out_ch2);

end Behavioral;