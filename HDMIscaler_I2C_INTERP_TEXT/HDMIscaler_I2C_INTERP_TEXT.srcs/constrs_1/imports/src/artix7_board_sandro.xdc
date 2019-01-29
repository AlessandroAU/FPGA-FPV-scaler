########################################
#  Constraints
########################################
##Clock Signal
set_property -dict { PACKAGE_PIN N11    IOSTANDARD LVCMOS33 } [get_ports { clk50 }]; # Sch=sysclk
    create_clock -add -name sys_clk_pin -period 20.00 -waveform {0 10} [get_ports clk50];

##HDMI out
set_property -dict { PACKAGE_PIN N4    IOSTANDARD TMDS_33  } [get_ports { hdmi_tx_n[0] }];
set_property -dict { PACKAGE_PIN M5    IOSTANDARD TMDS_33  } [get_ports { hdmi_tx_p[0] }];
set_property -dict { PACKAGE_PIN P3   IOSTANDARD TMDS_33  } [get_ports { hdmi_tx_n[1] }];
set_property -dict { PACKAGE_PIN P4   IOSTANDARD TMDS_33  } [get_ports { hdmi_tx_p[1] }];
set_property -dict { PACKAGE_PIN P1   IOSTANDARD TMDS_33  } [get_ports { hdmi_tx_n[2] }];
set_property -dict { PACKAGE_PIN N1   IOSTANDARD TMDS_33  } [get_ports { hdmi_tx_p[2] }];
set_property -dict { PACKAGE_PIN R1    IOSTANDARD TMDS_33  } [get_ports { hdmi_tx_clk_n }];
set_property -dict { PACKAGE_PIN R2    IOSTANDARD TMDS_33  } [get_ports { hdmi_tx_clk_p }];

#5150 video
set_property -dict { PACKAGE_PIN K2   IOSTANDARD LVCMOS33 } [get_ports { video5150[0] }];
set_property -dict { PACKAGE_PIN K3   IOSTANDARD LVCMOS33 } [get_ports { video5150[1] }];
set_property -dict { PACKAGE_PIN H3   IOSTANDARD LVCMOS33 } [get_ports { video5150[2] }];
set_property -dict { PACKAGE_PIN J3   IOSTANDARD LVCMOS33 } [get_ports { video5150[3] }];
set_property -dict { PACKAGE_PIN H4   IOSTANDARD LVCMOS33 } [get_ports { video5150[4] }];
set_property -dict { PACKAGE_PIN H5  IOSTANDARD LVCMOS33 } [get_ports { video5150[5] }];
set_property -dict { PACKAGE_PIN L2   IOSTANDARD LVCMOS33 } [get_ports { video5150[6] }];
set_property -dict { PACKAGE_PIN L3  IOSTANDARD LVCMOS33 } [get_ports { video5150[7] }];
#5150 sync
set_property -dict { PACKAGE_PIN K1    IOSTANDARD LVCMOS33 } [get_ports { clk27_5150 }];
 create_clock -add -name sys_clk_5150 -period 37.04 -waveform {0 18} [get_ports clk27_5150];

set_property -dict { PACKAGE_PIN N2    IOSTANDARD LVCMOS33 } [get_ports { AVID5150 }];
set_property -dict { PACKAGE_PIN H2   IOSTANDARD LVCMOS33 } [get_ports { VSYNC5150 }];
set_property -dict { PACKAGE_PIN M4   IOSTANDARD LVCMOS33 } [get_ports { FID5150 }];
set_property -dict { PACKAGE_PIN N3   IOSTANDARD LVCMOS33 } [get_ports { VBLK5150 }];
#5150 i2c control
set_property -dict { PACKAGE_PIN G1   IOSTANDARD LVCMOS33 } [get_ports { SDA5150 }];
set_property -dict { PACKAGE_PIN G2   IOSTANDARD LVCMOS33 } [get_ports { SCL5150 }];
set_property -dict { PACKAGE_PIN J1   IOSTANDARD LVCMOS33 } [get_ports { reset5150 }];

#mode switches
set_property -dict { PACKAGE_PIN M1   IOSTANDARD LVCMOS33 } [get_ports { mode_a }];
set_property -dict { PACKAGE_PIN N13   IOSTANDARD LVCMOS33 } [get_ports { mode_b }];

set_property -dict { PACKAGE_PIN C8   IOSTANDARD LVCMOS33 } [get_ports { LED_lock }];

#set_property -dict { PACKAGE_PIN M12   IOSTANDARD LVCMOS33 } [get_ports { LED_1 }];
#set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { LED_2 }];


#[Place 30-876] Port 'clk27_5150'  is assigned to PACKAGE_PIN 'N12'  which can only be used as the N side of a differential clock input.
#Please use the following constraint(s) to pass this DRC check:

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk27_5150_IBUF];

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets AVID5150_IBUF];

#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets VSYNC5150_IBUF];

#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets LED_1_OBUF]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets LED_2_OBUF];
#-----------------------------------------------------------------------------------------------------------------------------------------------------

set_clock_groups -physically_exclusive -group [get_clocks -include_generated_clocks *clk_wiz_0*] -group [get_clocks -include_generated_clocks *gen_pal_74_25*]
set_false_path -through [get_pins -hierarchical *master_serdes/RST]
set_false_path -through [get_pins -hierarchical *slave_serdes/RST]

#set_false_path -through [get_nets TVP5150_statusREG1(5)]TVP5150_statusREG1
#set_false_path -through [get_pins -hierarchical *I2C_UserController1/statusREG1*]
#set_false_path -through [get_pins -hierarchical *TVP5150_statusREG1*]
#set_false_path -through [get_pins -hierarchical *fifo_reader/pal_ntsc*]
#set_false_path -through [get_pins -hierarchical *MMCME2_BASE_inst/CLKINSEL*]
#set_disable_timing [get_pins *I2C_UserController1/statusREG1*]
##set_disable_timing [get_pins *I2C_UserController1/statusREG1*] 
#set_disable_timing [get_pins *MMCME2_BASE_inst/CLKINSEL*]
#set_disable_timing [get_pins *fifo_reader0/pal_ntsc*]
#set_false_path -from [get_pins {I2C_UserController1/statusREG1*[*]/C}] -to [get_pins {fifo_reader0/*]
set_disable_timing [get_pins {I2C_UserController1/statusREG1*[*]/C}]