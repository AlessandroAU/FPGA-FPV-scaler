-----------------------------------------------------------------------------
-- Scaler main guts are here.
--
-- 720p timing generator
-- read fifo, demux 4:2:2, deinterlace/interpolate Y, interpolate X,

-- timing generator code based on Mike Field work

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
-----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--use IEEE.math_real.ALL;

entity fifo_reader is



    Port ( clk : in STD_LOGIC;
           pal_ntsc : in std_logic; -- PAL=1 NTSC=0
           fifo_data : in std_logic_vector (15 downto 0);
           fifo_rden : out std_logic :='1' ;
           blank : buffer STD_LOGIC;
           hsync : out STD_LOGIC;
           vsync_in : in STD_LOGIC;
           vsync_stop : in std_logic; -- hard sync on VSYNC or use DPLL
           vsync : out STD_LOGIC;
           fid : in std_logic;
           Y_out : out std_logic_vector (7 downto 0);
           Cr_out : out std_logic_vector (7 downto 0);
           Cb_out : out std_logic_vector (7 downto 0);
           x_pos : out STD_LOGIC_VECTOR(11 downto 0);
           y_pos : out STD_LOGIC_VECTOR(11 downto 0);
           ps_request: out std_logic:= '0'; -- DPLL adjust command
           inc_dec: out std_logic:='0' -- DPLL direction
           );

end fifo_reader;

architecture Behavioral of fifo_reader is

constant vsync_delay: integer := 40;
type line_buffer_720 is array (722 downto 1) of STD_LOGIC_VECTOR (23 downto 0);
signal deinterlacer_buffer : line_buffer_720 := (others => (others =>'0'));


-- PAL/NTSC deinterlacer buffer write position
--signal fill_position_720 : integer := 1;  -- range 1 to 720

signal vsync_dly1: std_logic :='0';
signal vsync_dly2: std_logic :='0';
signal vsync_dly3: std_logic :='0';
signal vsync_delay_timer : unsigned(11 downto 0) := (others => '0');
signal Y_dly: std_logic_vector (7 downto 0) :=(others =>'0');
signal C_dly1: std_logic_vector (7 downto 0) :=(others =>'0');
signal C_dly2: std_logic_vector (7 downto 0) :=(others =>'0');

signal x : unsigned(11 downto 0) := (others => '0');
signal y : unsigned(11 downto 0) := (others => '0');
signal xs : std_logic_vector(11 downto 0) := (others => '0');
    -- PAL/NTSC deinterlacer buffer readout position
signal x_720 : unsigned(10 downto 0) := "00000000001";  -- range 1 to 720
signal fill_position_720 : unsigned  (11 downto 0) := X"001";
signal filling_enabled : std_logic := '0';
signal filling_request : std_logic := '0';
--signal fifo_rden : std_logic :='0';


-------------------------Variables for Pixel Interpolation--------------------
signal PixelA : std_logic_vector(10 downto 0);
signal PixelB : std_logic_vector(10 downto 0);

signal CoeffsA : std_logic_vector(10 downto 0);
signal CoeffsB : std_logic_vector(10 downto 0);

signal Y1_raw : unsigned(7 downto 0);
signal Y2_raw : unsigned(7 downto 0);
signal Y1_shifted : unsigned(17 downto 0); 
signal Y2_shifted : unsigned(17 downto 0);
signal Y_result : std_logic_vector (7 downto 0);

signal Cr1_raw : unsigned(7 downto 0);
signal Cr2_raw : unsigned(7 downto 0);
signal Cr1_shifted : unsigned(17 downto 0); 
signal Cr2_shifted : unsigned(17 downto 0);
signal Cr_result : std_logic_vector (7 downto 0);

signal Cb1_raw : unsigned(7 downto 0);
signal Cb2_raw : unsigned(7 downto 0);
signal Cb1_shifted : unsigned(17 downto 0); 
signal Cb2_shifted : unsigned(17 downto 0);
signal Cb_result : std_logic_vector (7 downto 0);

signal ActiveVideoLine : std_logic;
signal NewFrame : std_logic := '0';

----------------------------memory  for storing previous lines---------

type line_buffer_1280 is array (1280 downto 1) of STD_LOGIC_VECTOR (7 downto 0);

signal Y_out_prev : line_buffer_1280 := (others => (others =>'0')); --first line buffer
signal Cr_out_prev : line_buffer_1280 := (others => (others =>'0'));
signal Cb_out_prev : line_buffer_1280 := (others => (others =>'0'));

signal Y_out_prev2 : line_buffer_1280 := (others => (others =>'0'));  --second line buffer
signal Cr_out_prev2 : line_buffer_1280 := (others => (others =>'0'));
signal Cb_out_prev2 : line_buffer_1280 := (others => (others =>'0'));

signal Y_out_prev3 : line_buffer_1280 := (others => (others =>'0'));  --third line buffer
signal Cr_out_prev3 : line_buffer_1280 := (others => (others =>'0'));
signal Cb_out_prev3 : line_buffer_1280 := (others => (others =>'0'));

signal YinterpCounter : integer := 0;






component INTProm_PixelsA is
	port(
		clk: in std_logic;
		addr: in integer;
		DataOut_PixelA: out std_logic_vector(10 downto 0)
	);
end component;

component INTProm_PixelsB is
	port(
		clk: in std_logic;
		addr: in integer;
		DataOut_PixelB: out std_logic_vector(10 downto 0)
	);
end component;


component INTProm_CoeffsA is
	port(
		clk: in std_logic;
		addr: in integer;
		DataOut_CoeffsA: out std_logic_vector(10 downto 0)
	);
end component;

component INTProm_CoeffsB is
	port(
		clk: in std_logic;
		addr: in integer;
		DataOut_CoeffsB: out std_logic_vector(10 downto 0)
	);
end component;



begin

	RomPixelA: INTProm_PixelsA
	port map(
		clk => clk,
		addr => to_integer(unsigned(x)),
		DataOut_PixelA => PixelA
	);
	
    RomPixelB: INTProm_PixelsB
	port map(
		clk => clk,
		addr => to_integer(unsigned(x)),
		DataOut_PixelB => PixelB
	);
	
	RomCoeffsA : INTProm_CoeffsA 
	port map(
		clk => clk,
		addr => to_integer(unsigned(x)),
		DataOut_CoeffsA => CoeffsA
	);
	
	RomCoeffsB : INTProm_CoeffsB 
	port map(
		clk => clk,
		addr => to_integer(unsigned(x)),
		DataOut_CoeffsB => CoeffsB
	);


	


v_synchronizer: process (clk) is

-- forced VSYNC to timing generator OR digital PLL detecor based on which 720p line input VSYNC will hit

begin
-- deglitcher for signal from foreighn clock domain

        if rising_edge(clk) then

        if x=1650-1   then

                    vsync_delay_timer <= (vsync_delay_timer + 1); -- count end of lines, hope it will not overrun if vsyncs are here
                    -- when it will reach vsync_delay we will fire vsync at main HDTV raster generator
                    -- when it will reach filling_start: we will fire line buffer filling
             end if;



         vsync_dly1 <= vsync_in;
         vsync_dly2 <= vsync_dly1;
         vsync_dly3 <= vsync_dly2;

        if vsync_dly2 ='1' and vsync_dly3='0' then -- find synchronous edge of vsync

               vsync_delay_timer <= x"000"; -- then fire vsync delay timer

           -- DO our cool DPLL :)

           -- if PAL / NTSC derived VSYNC hits HDTV line 710, fine, do nothing.
           -- earlier/later - will command to bump HDTV MMCM frequency up/down

               if (y < 710) and (y > 355) then
                    ps_request <= '1';
                    inc_dec <='0';

               elsif (y > 710) or (y < 356)  then
                     ps_request <= '1';
                     inc_dec <='1';

               else
                     ps_request <= '0';
                     inc_dec <='0';
               end if;

          end if;

        end if ;




end process;

-- fifo_rden <= filling_enabled;

--newFieldDetect : process (clk) is
--begin
--    if vsync_in = '1' then
--        NewFrame <= '1';
--    end if;
--end process;


buffer_reader_X_scaler: process(clk) is

-- we are reading YCrCb from line buffer to HDTV output using 1280/720 linear interpolation

begin

        if rising_edge(clk) then
        
            if (x = 1280) then
                 YinterpCounter <= YinterpCounter +1;
            end if;
            
--            if y > 720 then --we finished drawing the current frame
--                NewFrame <= '1';
--            end if;

            if blank ='1' then

                Cb_out <= x"80"; -- do blanking
                Cr_out <= x"80";
                Y_out <= x"10";
                
            else
            
                ActiveVideoLine <= '0';
                            
                 if  pal_ntsc ='0' then --- logic for NTSC sdeinterlacer-scaler   --I copied this here just to detect when there is an active video line happening
                        if fid = '0' then -- first NTSC frame is EVEN
                                if  (y < 27) then null; --repeat prefilled buffer on first 2 lines
                            elsif ((y-26) rem 3)=1 then -- (! adjust!!!)
    
                                ActiveVideoLine <= '1';
    
                             end if;
    
                         else  -- do odd NTSC frame
                            if (((y-28) rem 3) =1) or (y=26) or (y=27) then -- (! adjust!!!)
                            
                                    ActiveVideoLine <= '1';
                                    
                            end if;
                        end if; -- ntsc fid 0/1
                  end if;

            

                if  pal_ntsc ='0' then
                
                    Y1_raw <= unsigned(deinterlacer_buffer(to_integer(unsigned(PixelA)))(23 downto 16)); -- raw value of pixel A from the buffer
                    Y2_raw <= unsigned(deinterlacer_buffer(to_integer(unsigned(PixelB)))(23 downto 16)); -- value of pixel B
                    
                    Y_result <= std_logic_vector(resize(shift_right(((unsigned(CoeffsA) * shift_left(resize(unsigned(Y1_raw), 18),10)) + (unsigned(CoeffsB) * shift_left(resize(unsigned(Y2_raw), 18),10))),20),8));
                    
                    
                    Cr1_raw <= unsigned(deinterlacer_buffer(to_integer(unsigned(PixelA)))(15 downto 8)); -- raw value of pixel A from the buffer
                    Cr2_raw <= unsigned(deinterlacer_buffer(to_integer(unsigned(PixelB)))(15 downto 8)); -- value of pixel B
                    
                    Cr_result <= std_logic_vector(resize(shift_right(((unsigned(CoeffsA) * shift_left(resize(unsigned(Cr1_raw), 18),10)) + (unsigned(CoeffsB) * shift_left(resize(unsigned(Cr2_raw), 18),10))),20),8));
                    
    
                    Cb1_raw <= unsigned(deinterlacer_buffer(to_integer(unsigned(PixelA)))(7 downto 0)); -- raw value of pixel A from the buffer
                    Cb2_raw <= unsigned(deinterlacer_buffer(to_integer(unsigned(PixelB)))(7 downto 0)); -- value of pixel B
                    
                    Cb_result <= std_logic_vector(resize(shift_right(((unsigned(CoeffsA) * shift_left(resize(unsigned(Cb1_raw), 18),10)) + (unsigned(CoeffsB) * shift_left(resize(unsigned(Cb2_raw), 18),10))),20),8)); --multiply and times buy the coeffs
                    
                   
            
                    --Y1_raw <= unsigned(deinterlacer_buffer(to_integer(unsigned(PixelA)))(23 downto 16)); -- raw value of pixel A from the buffer
                    --Y2_raw <= unsigned(deinterlacer_buffer(to_integer(unsigned(PixelB)))(23 downto 16)); -- value of pixel B
                    
                    --Y_result <= std_logic_vector(resize(shift_right(((unsigned(CoeffsA) * shift_left(resize(unsigned(unsigned(deinterlacer_buffer(to_integer(unsigned(PixelA)))(23 downto 16))), 18),10)) + (unsigned(CoeffsB) * shift_left(resize(unsigned(unsigned(deinterlacer_buffer(to_integer(unsigned(PixelB)))(23 downto 16))), 18),10))),20),8));
                    
                    
                    --Cr1_raw <= unsigned(deinterlacer_buffer(to_integer(unsigned(PixelA)))(15 downto 8)); -- raw value of pixel A from the buffer
                    --Cr2_raw <= unsigned(deinterlacer_buffer(to_integer(unsigned(PixelB)))(15 downto 8)); -- value of pixel B
                    
                    --Cr_result <= std_logic_vector(resize(shift_right(((unsigned(CoeffsA) * shift_left(resize(unsigned(unsigned(deinterlacer_buffer(to_integer(unsigned(PixelA)))(15 downto 8))), 18),10)) + (unsigned(CoeffsB) * shift_left(resize(unsigned(unsigned(deinterlacer_buffer(to_integer(unsigned(PixelB)))(15 downto 8))), 18),10))),20),8));
                    
    
                    --Cb1_raw <= unsigned(deinterlacer_buffer(to_integer(unsigned(PixelA)))(7 downto 0)); -- raw value of pixel A from the buffer
                    --Cb2_raw <= unsigned(deinterlacer_buffer(to_integer(unsigned(PixelB)))(7 downto 0)); -- value of pixel B
                    
                    --Cb_result <= std_logic_vector(resize(shift_right(((unsigned(CoeffsA) * shift_left(resize(unsigned(unsigned(deinterlacer_buffer(to_integer(unsigned(PixelA)))(7 downto 0))), 18),10)) + (unsigned(CoeffsB) * shift_left(resize(unsigned(unsigned(deinterlacer_buffer(to_integer(unsigned(PixelB)))(7 downto 0))), 18),10))),20),8)); --multiply and times buy the coeffs
                    
                   
                if (ActiveVideoLine = '1') then
                    
                    YinterpCounter <= 0;
                    
                    
                    
                        Y_out_prev2(to_integer(x)) <= Y_out_prev(to_integer(x));
                        Y_out_prev(to_integer(x)) <= Y_result; 
                        
                        Cr_out_prev2(to_integer(x)) <= Cr_out_prev(to_integer(x));
                        Cr_out_prev(to_integer(x)) <= Cr_result; 
                        
                        Cb_out_prev2(to_integer(x)) <= Cb_out_prev(to_integer(x));
                        Cb_out_prev(to_integer(x)) <= Cb_result; 
                        
                 end if;
                    
--                 if (NewFrame = '1') then  --- fix the glitch with the first line actually being the line from the previous field
                    
--                        Y_out_prev2(to_integer(x)) <= Y_result;
--                        Y_out_prev(to_integer(x)) <= Y_result; 
                        
--                        Cr_out_prev2(to_integer(x)) <= Cr_result;
--                        Cr_out_prev(to_integer(x)) <= Cr_result; 
                        
--                        Cb_out_prev2(to_integer(x)) <= Cb_result;
--                        Cb_out_prev(to_integer(x)) <= Cb_result;    
                                             
--                        NewFrame <= '0';                    
               
--                  end if;
                
                
                    case YinterpCounter is   ---- here is where we do the vertical interpolarion, we loose 2 lines of latency but oh well, that is only 1.4 ms so who cares!
                    
                    when 0 =>
                    
                          Y_out <= Y_out_prev2(to_integer(x));
                          Cr_out <= Cr_out_prev2(to_integer(x));
                          Cb_out <= Cb_out_prev2(to_integer(x));
--                          Y_out <= std_logic_vector(resize(shift_right((("01010101011" * shift_left(resize(unsigned(Y_out_prev2(to_integer(x))), 18),10)) + ("00101010101" * shift_left(resize(unsigned(Y_out_prev(to_integer(x))), 18),10))),20),8));
--                          Cr_out <= std_logic_vector(resize(shift_right((("01010101011" * shift_left(resize(unsigned(Cr_out_prev2(to_integer(x))), 18),10)) + ("00101010101" * shift_left(resize(unsigned(Cr_out_prev(to_integer(x))), 18),10))),20),8));
--                          Cb_out <= std_logic_vector(resize(shift_right((("01010101011" * shift_left(resize(unsigned(Cb_out_prev2(to_integer(x))), 18),10)) + ("00101010101" * shift_left(resize(unsigned(Cb_out_prev(to_integer(x))), 18),10))),20),8));

                        --Y2_raw <= unsigned(Y_out_prev(to_integer(x)));   -- 1/3 = 00101010101, --- 2/3 01010101011
                        
                    when 1 =>    
                    
                          Y_out <= std_logic_vector(resize(shift_right((("01010101011" * shift_left(resize(unsigned(Y_out_prev2(to_integer(x))), 18),10)) + ("00101010101" * shift_left(resize(unsigned(Y_out_prev(to_integer(x))), 18),10))),20),8));
                          Cr_out <= std_logic_vector(resize(shift_right((("01010101011" * shift_left(resize(unsigned(Cr_out_prev2(to_integer(x))), 18),10)) + ("00101010101" * shift_left(resize(unsigned(Cr_out_prev(to_integer(x))), 18),10))),20),8));
                          Cb_out <= std_logic_vector(resize(shift_right((("01010101011" * shift_left(resize(unsigned(Cb_out_prev2(to_integer(x))), 18),10)) + ("00101010101" * shift_left(resize(unsigned(Cb_out_prev(to_integer(x))), 18),10))),20),8));
                        
                    when 2 =>    
                      
                          Y_out <= std_logic_vector(resize(shift_right((("00101010101" * shift_left(resize(unsigned(Y_out_prev2(to_integer(x))), 18),10)) + ("01010101011" * shift_left(resize(unsigned(Y_out_prev(to_integer(x))), 18),10))),20),8));
                          Cr_out <= std_logic_vector(resize(shift_right((("00101010101" * shift_left(resize(unsigned(Cr_out_prev2(to_integer(x))), 18),10)) + ("01010101011" * shift_left(resize(unsigned(Cr_out_prev(to_integer(x))), 18),10))),20),8));
                          Cb_out <= std_logic_vector(resize(shift_right((("00101010101" * shift_left(resize(unsigned(Cb_out_prev2(to_integer(x))), 18),10)) + ("01010101011" * shift_left(resize(unsigned(Cb_out_prev(to_integer(x))), 18),10))),20),8));
                          
--                          Y_out_prev2(to_integer(x)) <= Y_out_prev(to_integer(x));
--                          Cr_out_prev2(to_integer(x)) <= Cr_out_prev(to_integer(x));
--                          Cb_out_prev2(to_integer(x)) <= Cb_out_prev(to_integer(x));
                        
                    when others => null;
                    
                    end case;
                    
                
                    --Cb_out <= x"10"; -- do blanking
                    --Cr_out <= x"80";
                    
               else -- if pal_ntsc = 1, we do not do interpolation on a pal signal !!
               
                      Cb_out <= deinterlacer_buffer(to_integer (x_720))(7 downto 0);
                      Cr_out <= deinterlacer_buffer(to_integer (x_720))(15 downto 8);
                      Y_out <= deinterlacer_buffer(to_integer (x_720))(23 downto 16);
                            
               end if;               

            end if; --blank =1 
            

                
        end if; --rising edge clk

end process;

Y_scaler_controller : process (clk)

-- BOB deinterlacer and Y interpolation logic here
-- requests (or not) SDTV deinterlacer buffer fill from FIFO
-- when fill not requested, SDTV buffer just repeats on HDTV out,
-- multiplying the same SDTV line
-- buffer filling is done faster than HDTV output, so display readout will not overrun it
--
-- depends on HDTV line number and deinterlacing/line multiplying logic here
-- BOB deinterlacer does line tripling for NTSC
-- or linedoubling and linetripling for PAL


-- filler process will get 720 pixels and then stop itself untill kicked for the next time

begin

  if rising_edge(clk) then
    if (x = 1430) then -- sync filler controller to ~~about HDTV hsync time

          if (y=25) or (y > 745)  then
                -- do buffer prefill for first line.
                -- also flush fifo by dummy reads after frame ends just in case...

                filling_request <= '1';
   --             fifo_rden <='1';

          elsif (y >= 26) and (y < 720 + 26) then

             -- rules for active parts of HDTV frame

                if  pal_ntsc ='0' then --- logic for NTSC sdeinterlacer-scaler

                    if fid = '0' then -- first NTSC frame is EVEN

                        if  (y < 27) then null; --repeat prefilled buffer on first 2 lines

                        elsif ((y-26) rem 3)=1 then -- (! adjust!!!)

                            -- request next SDTV line and repeat 3 times


                            filling_request <= '1';
                            --ActiveVideoLine <= '1';

                         end if;

                     else  -- do odd NTSC frame
                 --       if y < 29 then null; --repeat prefilled buffer on first 4 lines
                        if (((y-28) rem 3) =1) or (y=26) or (y=27) then -- (! adjust!!!)

                        -- request next SDTV line and repeat 3 times

                            filling_request <= '1';
                           -- ActiveVideoLine <= '1';

                        end if;

                    end if; -- ntsc fid 0/1


                else -- logic for PAL deinterlacer-scaler
                     if fid = '0' then

                            if (((y-26) rem 5)=1) or (((y-26) rem 5)=4) then -- (! adjust!!!)

                           -- request next SDTV line and repeat 2 or 3 times

                              filling_request <= '1';

                            end if;

                     else

                            if (y=26) or (y=27) then null; --repeat prefilled buffer on first 3 lines

                            elsif (((y-27) rem 5)=1) or (((y-27) rem 5)=4) then -- (! adjust!!!)

                                             -- request next SDTV line and repeat 3 times

                            filling_request <= '1';
                            end if;
                      end if;   -- pal fid 0/1

                end if; --pal/ntsc

          end if; -- active frame

        else filling_request <='0';
    end if;  -- x=1430




  end if; -- clk

  end process;

Buffer_filler : process (clk)

-- quickly fill deinterlacer buffer from FIFO

 begin

  if rising_edge(clk) then

    if filling_request = '1' then

        filling_enabled <= '1';
        fifo_rden <= '1';
        fill_position_720 <= x"000";

    end if;



            if filling_enabled = '1' then

              Y_dly <= fifo_data (7 downto 0);
              C_dly1 <= fifo_data (15 downto 8);
              C_dly2 <= C_dly1;

              -- do demux YCrCb 422 to 444

              if fill_position_720 > 0 then -- position 0 is a pre-read, 1-720 are real indexes
                if fill_position_720(0 downto 0) = 0 then

                    deinterlacer_buffer (to_integer (fill_position_720)) <= (Y_dly & C_dly1 & C_dly2); --odd pixel
                else
                    deinterlacer_buffer (to_integer (fill_position_720)) <= (Y_dly & (fifo_data(15 downto 8)) & C_dly1); --even pixel
                end if;
               end if;

            fill_position_720 <= fill_position_720 + 1;

            if fill_position_720 = 719 then

                -- auto stop filler process & reset pointer after we got 720 pixels from FIFO

                fill_position_720 <= x"000";
                filling_enabled <= '0';
                fifo_rden <='0';

            end if;
           end if;




  end if; -- clk

end process;



HDTV_raster_generator : process(clk)

-- HDTV 720p50 / 720p60 timing generator is here
-- x range 0 to 1650-1 for 720p60 or 1980-1 for 720p50
-- y range 1 to 750 (+ 5 dummy lines in case no input vsync arrived!)

begin
        if rising_edge(clk) then
            if x = 1280-1 then
                blank <= '1';
            elsif ((x = (1650-1) and (pal_ntsc='0')) or (x=(1980-1) and (pal_ntsc='1'))) and (y < 720 and y >= 25 ) then
                blank <= '0';
            end if;

            if ((x = 1390) and (pal_ntsc='0')) or ((x=1720) and (pal_ntsc='1')) then
                hsync <= '1';
            elsif (( x = 1430) and (pal_ntsc='0')) or ((x=1760) and (pal_ntsc='1'))then
                hsync <= '0';
            end if;

                x_pos <= std_logic_vector (x);
                y_pos <= std_logic_vector (y);

              if (x = (1650-1) and pal_ntsc='0') or (x=(1980-1) and pal_ntsc='1') then
      --      if x = 1650-1 then
                x <= (others => '0');
                --x_720 <= x"001" ; -- also reset deinterlacer buffer readout counter
                x_720 <= "00000000001";

                if y = 1 then
                        vsync  <= '1';
                     elsif y = 5 then
                        vsync  <= '0';
                end if;

                 if (((y = 755) or (vsync_delay_timer = vsync_delay)) and vsync_stop = '0') or ((y >= 750) and (vsync_stop='1')) then
   -- reset y at max 755 or when real vsync arrived (when hard sync enabled) or at line 750 when DPLL works

                    y <=   X"001";
                    vsync <= '1';
                else
                    y <= y +1;
                end if;
            else
                x <= x + 1;
                
                            case (std_logic_vector (x (3 downto 0))) is
                                  --    when "0000" => null ;
                                      when "0001" =>  x_720 <= x_720+1 ;
                                  --    when "0010" => null ;
                                      when "0011" =>  x_720 <= x_720+1;
                                  --    when "0100" => null;
                                      when "0101" =>  x_720 <= x_720+1;
                                  --    when "0110" =>  null;
                                      when "0111" =>  x_720 <= x_720+1;
                                      when "1000" =>  x_720 <= x_720+1;
                                  --   when "1001" => null;
                                      when "1010" => x_720 <= x_720+1;
                                  --    when "1011" => null;
                                      when "1100" => x_720 <= x_720+1;
                                  --    when "1101" => null;
                                      when "1110" => x_720 <= x_720+1;
                                      when "1111" => x_720 <= x_720+1;
                                      when others => null;

                                   end case;

                   end if;

        end if;


end process;

end behavioral;
