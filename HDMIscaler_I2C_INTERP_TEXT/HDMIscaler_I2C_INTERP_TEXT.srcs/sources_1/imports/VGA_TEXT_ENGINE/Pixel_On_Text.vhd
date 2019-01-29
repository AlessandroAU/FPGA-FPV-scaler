-- Pixel_On_Text determines if the current pixel is on text
-- param:
--   textlength, use to init the string
-- input: 
--   VGA clock(the clk you used to update VGA)
--   display text
--   top left corner of the text box
--   current X and Y position
-- output:
--   a bit that represent whether is the pixel in text

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

-- note this line.The package is compiled to this directory by default.
-- so don't forget to include this directory. 
library work;
-- this line also is must.This includes the particular package into your program.
use work.commonPak.all;

entity Pixel_On_Text is
	generic(
	   -- needed for init displayText, the default value 11 is just a random number
       constant textLength: integer := 11;
       constant TextScale : integer := 1
	);
	port (
		clk: in std_logic;
		--clk_out: out std_logic;
		displayText: in string (1 to textLength) := (others => NUL);
		-- top left corner of the text
		position: in point_2d := (0, 0);
		-- current pixel postion
		horzCoord: in integer;
		vertCoord: in integer;
		
		--pixel: out std_logic := '0'
		
	    RedOut, GreenOut, BlueOut : out std_logic_vector (11 downto 0);
		RedIn, GreenIn, BlueIn : in std_logic_vector (11 downto 0);
		
		
		
		VSYNC_IN : in std_logic;
        HSYNC_IN : in std_logic;
        BLANK_IN : in std_logic;
    
        VSYNC_OUT : out std_logic;
        HSYNC_OUT : out std_logic;
        BLANK_OUT : out std_logic
	);

end Pixel_On_Text;

architecture Behavioral of Pixel_On_Text is

	signal fontAddress: integer;
	-- A row of bit in a charactor, we check if our current (x,y) is 1 in char row
	signal charBitInRow: std_logic_vector(FONT_WIDTH-1 downto 0) := (others => '0');
	-- char in ASCII code
	signal charCode:integer := 0;
	-- the position(column) of a charactor in the given text
	signal charPosition:integer := 0;
	-- the bit position(column) in a charactor
	signal bitPosition:integer := 0;
	
	signal Red, Green, Blue : std_logic_vector (11 downto 0);
	signal HSYNC, VSYNC, BLANK :std_logic;
	
	signal scaledFontAddr:integer;
	
	signal sig_clk_in_dly1 : std_logic;
    signal sig_clk_in_dly2 : std_logic;
	
	
begin

   -- (horzCoord - position.x): x positionin the top left of the whole text
    charPosition <= (horzCoord - position.x)/(FONT_WIDTH * TextScale) + 1;
    bitPosition <= ((horzCoord - position.x) mod (FONT_WIDTH * TextScale))/TextScale;
    charCode <= character'pos(displayText(charPosition));
    -- charCode*16: first row of the char
    scaledFontAddr <= (vertCoord - position.y)/TextScale;
    fontAddress <= charCode*16+scaledFontAddr;
    
	fontRom: entity work.Font_Rom
	port map(
		clk => clk,
		addr => fontAddress,
		fontRow => charBitInRow
	);
	
--    clk_buffer : process (clk) is
--    begin
--        sig_clk_in_dly1 <= clk;
--        sig_clk_in_dly2 <= sig_clk_in_dly1;
--        clk_out <= sig_clk_in_dly2;
--    end process;
	
	pixelOn: process(clk)
		variable inXRange: boolean := false;
		variable inYRange: boolean := false;
	begin
        if rising_edge(clk) then
        
            Red <= RedIn;
            Green <= GreenIn;
            Blue <= BlueIn;
            HSYNC <= HSYNC_IN;
            VSYNC <= VSYNC_IN;
            BLANK <= BLANK_IN;
            
            -- reset
            inXRange := false;
            inYRange := false;
            --pixel <= '0';
            -- If current pixel is in the horizontal range of text
            if horzCoord >= position.x and horzCoord < position.x + ((FONT_WIDTH * TextScale)* textlength) then
                inXRange := true;
            end if;
            
            -- If current pixel is in the vertical range of text
            if vertCoord >= position.y and vertCoord < position.y + (FONT_HEIGHT * TextScale) then
                inYRange := true;
            end if;                
            
            -- need to check if the pixel is on for text
            if inXRange and inYRange then
                -- FONT_WIDTH-bitPosition: we are reverting the charactor
                if charBitInRow(FONT_WIDTH-bitPosition) = '1' then
                    --pixel <= '1';
                    Green <= "111111111111";
                    --Red <= "000000000000";
                    --BlueOut <= "000000000000";
                end if;					
            end if;
			   RedOut <= Red;
	           GreenOut <= Green;
	           BlueOut <= Blue;
	           VSYNC_OUT <= VSYNC; 
               HSYNC_OUT <= HSYNC;
               BLANK_OUT <= BLANK;

               --clk_out <= clk;
		end if;
	end process;

end Behavioral;