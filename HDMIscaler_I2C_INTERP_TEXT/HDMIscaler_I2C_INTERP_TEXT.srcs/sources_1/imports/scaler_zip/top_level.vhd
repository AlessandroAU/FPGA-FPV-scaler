----------------------------------------------------------------------------------
-- Low latency CVBS to HDMI FPGA converter engine
--
-- I2C, YCC to RGB and HDMI output modules (c) Mike Field <hamster@snap.net.nz>
--
-- Module Name: top level

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
use IEEE.NUMERIC_STD.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

entity top_level is
    Port (
        clk50    : in STD_LOGIC;
        clk27_5150 : in std_logic;

        video5150 : in std_logic_vector (7 downto 0);

         AVID5150: in STD_LOGIC;
         VSYNC5150: in STD_LOGIC;
         FID5150: in STD_LOGIC;
         VBLK5150: in std_logic;

         SDA5150: inout STD_LOGIC;
         SCL5150 : inout STD_LOGIC;
         reset5150 : out std_logic;
        mode_a : in std_logic;
        mode_b : in std_logic;

        hdmi_tx_clk_p : out std_logic;
        hdmi_tx_clk_n : out std_logic;
        hdmi_tx_p     : out std_logic_vector(2 downto 0);
        hdmi_tx_n     : out std_logic_vector(2 downto 0)
);
end top_level;

architecture Behavioral of top_level is
    signal clk_pixel_x1  : std_logic;
    signal clk_pixel_x5  : std_logic;
    signal clk_pixel_27  : std_logic;
    signal clk_pixel_13_5  : std_logic;
    signal crystal27 : std_logic;
    signal clk74_17 : std_logic;
    signal clk74_25 : std_logic;
    signal clk270M : std_logic;
    signal blank : std_logic := '0';
    signal hsync : std_logic := '0';
    signal vsync : std_logic := '0';
    signal x_pos : std_logic_vector(11 downto 0);
    signal y_pos : STD_LOGIC_VECTOR(11 downto 0);
    signal fsync : std_logic_vector (1 downto 0);
    signal redframe : std_logic_vector (11 downto 0);
    signal redframe1 : std_logic_vector (11 downto 0);
    signal greenframe : std_logic_vector (11 downto 0);
    signal greenframe1 : std_logic_vector (11 downto 0);
    signal blueframe : std_logic_vector (11 downto 0);
    signal blueframe1 : std_logic_vector (11 downto 0);
    signal vg27_data : std_logic_vector (7 downto 0);
    signal fifo_wren : std_logic;
    signal fifo_rden : std_logic;

    signal fifo_data_out : std_logic_vector (15 downto 0);
    signal fifo_data_in : std_logic_vector (15 downto 0);

    signal sdtv_blank : std_logic;
    signal hdtv_hsync : std_logic;
    signal sdtv_vsync : std_logic;
    signal sdtv_hsync : std_logic;
    signal sdtv_hblk : std_logic;
    signal sdtv_vblk : std_logic;
    signal hdtv_vsync : std_logic;
    signal hdtv_blank : std_logic;
    signal hdtv_vsync_rgb : std_logic;
    signal hdtv_blank_rgb : std_logic;
    signal hdtv_hsync_rgb : std_logic;


    signal fid  : std_logic;
    signal sdtv_avid : std_logic;
    signal reset5150_0 : std_logic;
    signal reset_i2c : std_logic;
    signal reset_i2c_ActiveLow : std_logic;
    signal notfid : std_logic;
    signal y : std_logic_vector (7 downto 0);
    signal cr : std_logic_vector (7 downto 0);
    signal cb : std_logic_vector (7 downto 0);
    signal fourfourfour_U     : std_logic_vector(11 downto 0);
    signal fourfourfour_V     : std_logic_vector(11 downto 0);
    signal fourfourfour_W     : std_logic_vector(11 downto 0);

    signal psclk: std_logic;
    signal psen: std_logic;
    signal psdone: std_logic;
    signal psincdec: std_logic;
    signal locked_mmcme: std_logic;
    signal ps_request: std_logic;
    signal inc_dec: std_logic;
    
    ---------------------------i2c signals----------------------------
    signal I2C_ena : STD_LOGIC;
    signal I2C_addr : STD_LOGIC_VECTOR (6 downto 0);
    signal I2C_rw : STD_LOGIC;
    signal I2C_data_wr : STD_LOGIC_VECTOR (7 downto 0);
    signal I2C_data_rd : STD_LOGIC_VECTOR (7 downto 0);
    signal I2C_ack_error : STD_LOGIC;
    signal I2C_busy : STD_LOGIC;
    ------------------------------------------------------------------
    
    signal TVP5150_statusREG1 : STD_LOGIC_VECTOR (7 downto 0);
    signal blockPPLtuning : STD_LOGIC;
    
    ----------------------------------Text Rendering Engine-----------------------------
    signal TextEngineRedIn, TextEngineGreenIn, TextEngineBlueIn : std_logic_vector (11 downto 0);
    signal TextEngineRedOut, TextEngineGreenOut, TextEngineBlueOut : std_logic_vector (7 downto 0);
    signal TextEngine_XPOSin, TextEngine_YPOSin : std_logic_vector (11 downto 0); 
    signal FIFO_XPOS, FIFO_YPOS : std_logic_vector (11 downto 0); 
    signal TextEngineHSYNCCout, TextEngineVSYNCCout, TextEngineBLANKout : std_logic;
    signal TextEngine_HSYNCin, TextEngine_VSYNCin, TextEngine_BLANKin : std_logic;
	signal DisplayText : string(1 to 11) := "12345678910";
    
    
   component clk_wiz_0 is

 -- 1.001 multiply

    port (
            clk_out1 : out std_logic;

             reset : in std_logic;
             locked : out std_logic;
             clk_in1 : in std_logic
     );
  end component;

   component clk_wiz_1 is

  -- 27/270M multiply

     port (
             clk_out1 : out std_logic;

              reset : in std_logic;
              locked : out std_logic;
              clk_in1 : in std_logic
      );
   end component;

   component clk_wiz_2 is

   -- 50M -> 27M test

      port (
              clk_out1 : out std_logic;
              clk_out2 : out std_logic;
               reset : in std_logic;
               locked : out std_logic;
               clk_in1 : in std_logic
       );
    end component;

 component gen_pal_74_25 is

 --  multiply 27M from 5150 to 74.25 HD720P dotclock in PAL mode

    port (
            clk_out1 : out std_logic;

             reset : in std_logic;
             locked : out std_logic;
             clk_in1 : in std_logic
     );
  end component;

  component ps_control  is



        port (psclk : in STD_LOGIC;
             psen : out STD_LOGIC;
             psdone : in STD_LOGIC;
             locked : in STD_LOGIC;
             psincdec : out STD_LOGIC;
             inc_dec : in STD_LOGIC;
             ps_request : in STD_LOGIC

         );
      end component;






   component fifo_generator_0 IS
      PORT (
        wr_clk : IN STD_LOGIC;
        rd_clk : IN STD_LOGIC;
        din : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        wr_en : IN STD_LOGIC;
        rd_en : IN STD_LOGIC;
        dout : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        full : OUT STD_LOGIC;
        empty : OUT STD_LOGIC;
        valid : OUT STD_LOGIC
      );
    END component;



 component fifo_writer_5150 IS
                      PORT (

                      clk_pixel_27 : in STD_LOGIC;
                      video601 : in std_logic_vector (7 downto 0);

                      AVID: in STD_LOGIC;
--                    VSYNC: in STD_LOGIC;
--                    FID: in STD_LOGIC;
                      VBLK: in std_logic;

                      fifo_data : out std_logic_vector (15 downto 0);
                      fifo_wren : out std_logic


                          );
    END component;


    component fifo_reader IS
          PORT (

          clk : in STD_LOGIC;
          pal_ntsc : in std_logic; -- PAL=1 NTSC=0
          fifo_data : in std_logic_vector (15 downto 0);
          fifo_rden : out std_logic;
          blank : buffer STD_LOGIC ;
          hsync : out STD_LOGIC ;
          vsync_in : in STD_LOGIC ;
          vsync_stop : in std_logic;
          vsync : out STD_LOGIC ;
          fid : in std_logic;
          Y_out : out std_logic_vector (7 downto 0);
          Cr_out : out std_logic_vector (7 downto 0);
          Cb_out : out std_logic_vector (7 downto 0);
          x_pos : out STD_LOGIC_VECTOR(11 downto 0);
          y_pos : out STD_LOGIC_VECTOR(11 downto 0);
          ps_request: out std_logic;
          inc_dec: out std_logic

          );
        END component;

 component conversion_to_RGB is
               port ( clk            : in std_Logic;
                      input_is_YCbCr : in std_Logic;
                      input_is_sRGB  : in std_Logic;
                      ------------------------
                      in_blank       : in std_logic;
                      in_hsync       : in std_logic;
                      in_vsync       : in std_logic;
                      in_U           : in std_logic_vector(11 downto 0);
                      in_V           : in std_logic_vector(11 downto 0);
                      in_W           : in std_logic_vector(11 downto 0);
                      ------------------------
                      out_blank      : out std_logic;
                      out_hsync      : out std_logic;
                      out_vsync      : out std_logic;
                      out_R          : out std_logic_vector(11 downto 0);
                      out_G          : out std_logic_vector(11 downto 0);
                      out_B          : out std_logic_vector(11 downto 0)
                 );
  end component;

    component vga_output is
        Port ( clk : in STD_LOGIC;
               hsync_in : in STD_LOGIC;
               vsync_in : in STD_LOGIC;
               blank_in : in STD_LOGIC;
               count     : in STD_LOGIC_VECTOR(7 downto 0);
               vga_hsync : out std_logic;
               vga_vsync : out std_logic;
               vga_red   : out std_logic_vector(7 downto 0);
               vga_green : out std_logic_vector(7 downto 0);
               vga_blue  : out std_logic_vector(7 downto 0);
               vga_blank : out std_logic;
               x_pos : in STD_LOGIC_VECTOR(11 downto 0);
               y_pos : in STD_LOGIC_VECTOR(11 downto 0)
               );
    end component;



    signal vga_hsync     : std_logic;
    signal vga_vsync     : std_logic;
    signal vga_red       : std_logic_vector(7 downto 0);
    signal vga_green     : std_logic_vector(7 downto 0);
    signal vga_blue      : std_logic_vector(7 downto 0);
    signal vga_blank     : std_logic;
    signal reset         : std_logic;


component hdmi_io is
    port (

        pixel_clk : in std_logic;
        pixel_clk_x5 : in std_logic;
        reset  : in std_logic;
        -------------
        -- HDMI out
        -------------

        hdmi_tx_clk_n : out   std_logic;
        hdmi_tx_clk_p : out   std_logic;

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
end component;

--component i2c_sender

--port (
--           clk    : in    STD_LOGIC;
--           resend : in    STD_LOGIC;
--           sioc   : out   STD_LOGIC;
--           siod   : inout STD_LOGIC
--);
--end component;

component i2c_master
  GENERIC(
    input_clk : INTEGER := 50_000_000; --input clock speed from user logic in Hz
    bus_clk   : INTEGER := 400_000);   --speed the i2c bus (scl) will run at in Hz
  PORT(
    clk       : IN     STD_LOGIC;                    --system clock
    reset_n   : IN     STD_LOGIC;                    --active low reset
    ena       : IN     STD_LOGIC;                    --latch in command
    addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
    rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
    data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
    busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
    data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
    ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
    sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
    scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
 end component;
 
 
 component I2C_UserController
    Port ( 
           clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           ena : out STD_LOGIC;
           addr : out STD_LOGIC_VECTOR (6 downto 0);
           rw : out STD_LOGIC;
           data_wr : out STD_LOGIC_VECTOR (7 downto 0);
           data_rd : in STD_LOGIC_VECTOR (7 downto 0);
           ack_error : in STD_LOGIC;
           busy : in STD_LOGIC;
           statusREG1 : out STD_LOGIC_VECTOR (7 downto 0)
           );
end component;



component reset_control

port (
           clk50 : in    STD_LOGIC;
           lock1 : in    STD_LOGIC;
           lock2 : in   STD_LOGIC;
           lock3 : in   STD_LOGIC;
           done : in std_logic;
           reset_out : out std_logic;
           reset_i2c : out std_logic
);
end component;



    signal locked        : std_logic;
    signal locked27        : std_logic;

    signal clkfb         : std_logic;

begin
    reset <= reset_i2c;
 --   reset <= not locked;
    reset5150 <= not reset5150_0;
    clk_pixel_27 <= clk27_5150;
    notfid <= not fid5150;

reset_controller : reset_control

    port map (
              clk50  => clk50,
              reset_out => reset5150_0,
              reset_i2c => reset_i2c,
              lock1  => locked,
              lock2  => '1',
              lock3  => '1',
              done => '1'

    );

-- i2c : i2c_sender

--    port map (
--               clk    =>  clk50,
----               resend => '0',
--              resend  => reset_i2c,
--               sioc    => scl5150,
--               siod   => sda5150
--    );
reset_i2c_ActiveLow <= not reset_i2c;

 i2c_master1 : i2c_master

    port map (
               clk    =>  clk50,
               reset_n  => reset_i2c_ActiveLow,
               ena => I2C_ena,
               addr => I2C_addr,
               rw => I2C_rw,
               data_wr => I2C_data_wr,
               data_rd => I2C_data_rd,
               ack_error => I2C_ack_error,
               busy => I2C_busy,                             
               scl    => scl5150,
               sda   => sda5150
    );
    
    
  I2C_UserController1 : I2C_UserController
        port map(
                clk => clk50,
                reset => reset_i2c,
                ena => I2C_ena,
                addr => I2C_addr,
                rw => I2C_rw,
                data_wr => I2C_data_wr,
                data_rd => I2C_data_rd,
                ack_error => I2C_ack_error,
                busy => I2C_busy,
                statusREG1 => TVP5150_statusREG1
            );



--    ---------------------------i2c signals----------------------------
--    signal I2C_addr : STD_LOGIC_VECTOR (6 downto 0);
--    signal I2C_rw : STD_LOGIC;
--    signal I2C_data_wr : STD_LOGIC_VECTOR (7 downto 0);
--    signal I2C_data_rd : STD_LOGIC_VECTOR (7 downto 0);
--    signal I2C_ack_error : STD_LOGIC;
--    signal I2C_busy : STD_LOGIC;
--    ------------------------------------------------------------------
    



    
    mult1001 : clk_wiz_0 -- genetate 74.17M NTSC 720p dotclock from 270M

    port map (
             clk_out1 => clk74_17,

              reset => '0',
              locked => open,
              clk_in1 => clk270M
      );


-- genetate 74.25M PAL 720p dotclock from 27M





    gen_PAL : gen_pal_74_25

    port map (
             clk_out1 => clk74_25,

              reset => '0',
              locked => open,
              clk_in1 => crystal27
      );
    -- genetate 270M clock from 27M

          mult270 : clk_wiz_1

          port map (
                   clk_out1 => clk270M,

                    reset => '0',
                    locked => open,
                    clk_in1 => crystal27
            );

      -- generate 27M clock from 50M

                    GEN27 : clk_wiz_2

                    port map (
                             clk_out1 => crystal27,

                             clk_out2 =>  clk_pixel_13_5,
                              reset => '0',
                              locked => locked,
                              clk_in1 => clk50
                      );



--- main HDMI sync generator
-- fclk to fclk x 5 multiply
-- we are using phase shift trick to adjust clock about +- 500ppm
-- for timebase corrector "flywhell" digital PLL

 MMCME2_BASE_inst : mmcme2_ADV
   generic map (
      BANDWIDTH => "OPTIMIZED",  -- Jitter programming (OPTIMIZED, HIGH, LOW)
      DIVCLK_DIVIDE   => 1,        -- Master division value (1-106)
      CLKFBOUT_MULT_F => 15.0,    -- Multiply value for all CLKOUT (2.000-64.000).
      CLKFBOUT_PHASE => 0.0,     -- Phase offset in degrees of CLKFB (-360.000-360.000).
      CLKIN1_PERIOD => 13.468,      -- Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
      CLKIN2_PERIOD => 13.468,
      -- CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
      CLKOUT0_DIVIDE_F   => 10.0,   -- Divide amount for CLKOUT0 (1.000-128.000).
      CLKOUT1_DIVIDE   => 15,
      CLKOUT2_DIVIDE   => 3,
      CLKOUT3_DIVIDE   => 3,
      CLKOUT4_DIVIDE   => 1,
      CLKOUT5_DIVIDE   => 1,
      clkout6_divide   => 1,
      -- CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99).
      CLKOUT0_DUTY_CYCLE => 0.5,
      CLKOUT1_DUTY_CYCLE => 0.5,
      CLKOUT2_DUTY_CYCLE => 0.5,
      CLKOUT3_DUTY_CYCLE => 0.5,
      CLKOUT4_DUTY_CYCLE => 0.5,
      CLKOUT5_DUTY_CYCLE => 0.5,
      CLKOUT6_DUTY_CYCLE => 0.5,
      -- CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
      CLKOUT0_PHASE => 0.0,
      CLKOUT1_PHASE => 0.0,
      CLKOUT2_PHASE => 0.0,
      CLKOUT3_PHASE => 0.0,
      CLKOUT4_PHASE => 0.0,
      CLKOUT5_PHASE => 0.0,
      clkout6_phase => 0.0,

      COMPENSATION => "ZHOLD",       -- ZHOLD, BUF_IN, EXTERNAL, INTERNAL
      REF_JITTER1 => 0.0,        -- Reference input jitter in UI (0.000-0.999).
      REF_JITTER2 => 0.0,        -- Reference input jitter in UI (0.000-0.999).
      STARTUP_WAIT => FALSE,      -- Delays DONE until MMCM is locked (FALSE, TRUE)
      SS_EN => "FALSE",              -- Enables spread spectrum (FALSE, TRUE)
      SS_MODE => "CENTER_HIGH",      -- CENTER_HIGH, CENTER_LOW, DOWN_HIGH, DOWN_LOW
      SS_MOD_PERIOD => 10000,        -- Spread spectrum modulation period (ns) (VALUES)
            -- USE_FINE_PS: Fine phase shift enable (TRUE/FALSE)
            CLKFBOUT_USE_FINE_PS => FALSE,
            CLKOUT0_USE_FINE_PS => FALSE,
            CLKOUT1_USE_FINE_PS => TRUE,
            CLKOUT2_USE_FINE_PS => TRUE,
            CLKOUT3_USE_FINE_PS => FALSE,
            CLKOUT4_USE_FINE_PS => FALSE,
            CLKOUT5_USE_FINE_PS => FALSE,
            CLKOUT6_USE_FINE_PS => FALSE


   )
   port map (
      -- Clock Outputs: 1-bit (each) output: User configurable clock outputs
      CLKOUT0   => open,     -- 1-bit output: CLKOUT0

      CLKOUT1   => clk_pixel_x1, -- 1-bit output: CLKOUT1

      CLKOUT2   => clk_pixel_x5, -- 1-bit output: CLKOUT2

      CLKOUT3   => psclk,         -- 1-bit output: CLKOUT3

      CLKOUT4   => open,         -- 1-bit output: CLKOUT4
      CLKOUT5   => open,         -- 1-bit output: CLKOUT5

      -- Feedback Clocks: 1-bit (each) output: Clock feedback ports
      CLKFBOUT  => clkfb,  -- 1-bit output: Feedback clock
  --    CLKFBOUTB => open,   -- 1-bit output: Inverted CLKFBOUT
      -- Status Ports: 1-bit (each) output: MMCM status ports
      LOCKED    => locked_mmcme,   -- 1-bit output: LOCK
      -- Clock Inputs: 1-bit (each) input: Clock input
      CLKIN1    => clk74_25, -- 1-bit input: Clock
      CLKIN2    => clk74_17, -- 1-bit input: Clock
      --CLKINSEL  => mode_b,
      --CLKINSEL  => '1',
      CLKINSEL => TVP5150_statusREG1(5),
      -- Control Ports: 1-bit (each) input: MMCM control ports
      PWRDWN    => '0',    -- 1-bit input: Power-down
      RST       => reset5150_0,    -- 1-bit input: Reset
      -- Feedback Clocks: 1-bit (each) input: Clock feedback ports
      CLKFBIN   => clkfb,   -- 1-bit input: Feedback clock
      DADDR => b"0000000",
      DI => x"0000",
      DWE => '0',
      DEN => '0',
      DCLK => '0',
      PSCLK => PSCLK,               -- 1-bit input: Phase shift clock
      PSEN => blockPPLtuning,                 -- 1-bit input: Phase shift enable
      PSINCDEC => PSINCDEC,         -- 1-bit input: Phase shift increment/decrement
      PSDONE => PSDONE


   );

blockPPLtuning <= PSEN xor TVP5150_statusREG1(4);


pscontroller : ps_control

 -- MMCM phase shift commander module for DPLL

    port map (
              psclk => psclk,
               psen => psen,
               psdone =>psdone,
               locked =>locked_mmcme,
               psincdec => psincdec,
               inc_dec => inc_dec,
               ps_request => ps_request

      );





fifo64K: fifo_generator_0 port map (

 -- timebase corrector "rubber band" FIFO


        wr_clk => clk_pixel_27,
        rd_clk => clk_pixel_x1,
        din  => fifo_data_in,
        wr_en => fifo_wren,
        rd_en => fifo_rden,
        dout => fifo_data_out,
        full => open,
        empty => open,
        valid => open
      );

fifo_writer_5150_0: fifo_writer_5150 port map (

 -- takes BT.656 data from TVP5150, muxes it 16bits
 -- we need 16 bits width because FIFO needs to readout (at pixel clock)
 -- slightly ahead of actual HDTV display pixel run.

         clk_pixel_27 => clk_pixel_27,
         video601 => video5150,

         AVID => avid5150,
--       VSYNC => vsync5150,
--       FID => fid5150,
         VBLK => vblk5150,

         fifo_data => fifo_data_in,
         fifo_wren => fifo_wren


         );



fifo_reader0: fifo_reader port map (


               clk => clk_pixel_x1,
               --pal_ntsc => mode_b, -- PAL=1 NTSC=0
               --pal_ntsc => '1',
               pal_ntsc => TVP5150_statusREG1(5),
               fifo_data => fifo_data_out,
               fifo_rden => fifo_rden,
               blank => hdtv_blank,
               hsync => hdtv_hsync,
               vsync_in => vsync5150,
               vsync => hdtv_vsync,
               --vsync_stop => mode_a,
               vsync_stop => '1',
               fid => fid5150,
               Y_out => Y,
               Cr_out => Cr,
               Cb_out => Cb,
               x_pos => TextEngine_XPOSin,
               y_pos => TextEngine_YPOSin,
               ps_request => ps_request,
               inc_dec => inc_dec
               );

-- padding 8-bit YCrCb 4:4:4 to 12bits for Mike's YCC-RGB converter

  fourfourfour_U  <= cb &"0000";
  fourfourfour_V  <= y & "0000";
  fourfourfour_W  <= cr & "0000";


  i_conversion_to_RGB: conversion_to_RGB
      port map (
             clk              => clk_pixel_x1,
             ------------------------
             input_is_YCbCr   => '1',
             input_is_sRGB    => '0',
             in_blank         => hdtv_blank,
             in_hsync         => hdtv_hsync,
             in_vsync         => hdtv_vsync,
             in_U             => fourfourfour_U,
             in_V             => fourfourfour_V,
             in_W             => fourfourfour_W,
             ------------------------
--             out_blank        => hdtv_blank_rgb,
--             out_hsync        => hdtv_hsync_rgb,
--             out_vsync        => hdtv_vsync_rgb,
--             out_R            => redframe,
--             out_G            => greenframe,
--             out_B            => blueframe
             out_blank        => TextEngine_BLANKin,
             out_hsync        => TextEngine_HSYNCin,
             out_vsync        => TextEngine_VSYNCin,
             
             out_R            => TextEngineRedIn,
             out_G            => TextEngineGreenIn,
             out_B            => TextEngineBlueIn
             --out_xpos         => TextEngine_XPOSin,
             --out_ypos         => TextEngine_YPOSin,
      );
      
with TVP5150_statusREG1(5 downto 4) select
    DisplayText <=
    "PAL        " when "10",
    "NTSC       " when "00",
    "SIGNAL LOSS" when "11",
    "SIGNAL LOSS" when "01";     

    textElement1: entity work.Pixel_On_Text
        generic map (
        	textLength => 11,
        	TextScale => 4
        )
        port map(
        	clk => clk_pixel_x1,--conversion_to_RGB_clkout,
        	--clk_out => TextEngine_clkout,
        	displayText => DisplayText,
        	position => (15, 650), -- text position (top left)
        	horzCoord => to_integer(unsigned(TextEngine_XPOSin)),
        	vertCoord => to_integer(unsigned(TextEngine_YPOSin)),
        	
        	RedIn => TextEngineRedIn, GreenIn => TextEngineGreenIn, BlueIn => TextEngineBlueIn,
            RedOut => redframe, GreenOut => greenframe, BlueOut => blueframe,
            
            

            VSYNC_IN => TextEngine_VSYNCin,
            HSYNC_IN => TextEngine_HSYNCin,
		    BLANK_IN => TextEngine_BLANKin,
		    
            VSYNC_OUT => hdtv_vsync_rgb,
            HSYNC_OUT => hdtv_hsync_rgb,
            BLANK_OUT => hdtv_blank_rgb 
        	
        );

-- vsync_visualizer : process (clk_pixel_x1)

-- -- DPLL diagnostics here
-- -- draw a small rectangle in right lower edge of frame on SDTV VSYNC time
-- -- green if right timing, red if pshift=1 (late VSYNC), blue if psift=0 (early VSYNC)

-- begin
-- if ((x_pos = x"4ed") or (x_pos=x"4ee") or (x_pos=x"4ef")) and (vsync5150='1') then

--    if ps_request= '0' then
--        greenframe1 <= x"fff";
--    else
--        greenframe1 <=greenframe;
--    end if;

--    if (ps_request = '1') and (inc_dec='0') then
--        blueframe1 <= x"fff";
--    else
--        blueframe1 <= blueframe;
--    end if;

--    if (ps_request = '1') and (inc_dec='1') then
--        redframe1 <= x"fff";
--    else
--        redframe1 <=redframe;
--     end if;

--   else
--     greenframe1 <= greenframe;
--     blueframe1 <= blueframe;
--     redframe1 <=redframe;

-- end if;
-- end process;





 i_hdmi_io: hdmi_io port map (
        pixel_clk     => clk_pixel_x1,
        pixel_clk_x5  => clk_pixel_x5,
        reset         => reset,
        out_hsync     => hdtv_hsync_rgb,
        out_vsync     => hdtv_vsync_rgb,
        out_red       => redframe(11 downto 4),
        out_green     => greenframe(11 downto 4),
        out_blue      => blueframe(11 downto 4),
        out_blank     => hdtv_blank_rgb,

        hdmi_tx_clk_p => hdmi_tx_clk_p,
        hdmi_tx_clk_n => hdmi_tx_clk_n,
        hdmi_tx_p     => hdmi_tx_p,
        hdmi_tx_n     => hdmi_tx_n
    );



end Behavioral;
