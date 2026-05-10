# CLOCK
set_property -dict { PACKAGE_PIN N11    IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -period 20.000 -name sys_clk [get_ports clk] ;# 50 MHz


# RESET BUTTON
set_property -dict { PACKAGE_PIN L5    IOSTANDARD LVCMOS33 } [get_ports { rst_btn }];#LSB


# NEXT / MODE ADVANCE BUTTON
set_property -dict { PACKAGE_PIN M6    IOSTANDARD LVCMOS33 } [get_ports { next_btn }];#MSB


# PARTY BUTTONS [4:0]
set_property -dict {PACKAGE_PIN K13 IOSTANDARD LVCMOS33 PULLDOWN true} [get_ports {btn_dmk}]; #Button-top
set_property -dict {PACKAGE_PIN L14 IOSTANDARD LVCMOS33 PULLDOWN true} [get_ports {btn_admk}]; #Button-bottom
set_property -dict {PACKAGE_PIN M12 IOSTANDARD LVCMOS33 PULLDOWN true} [get_ports {btn_tvk}]; #Button-left
set_property -dict {PACKAGE_PIN L13 IOSTANDARD LVCMOS33 PULLDOWN true} [get_ports {btn_ntk}]; #Button-right
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33 PULLDOWN true} [get_ports {btn_other}]; #Button-center


#7 segment display
set_property -dict { PACKAGE_PIN F2    IOSTANDARD LVCMOS33 } [get_ports {seg_an[0]}]; #LSB
set_property -dict { PACKAGE_PIN E1    IOSTANDARD LVCMOS33 } [get_ports {seg_an[1]}];
set_property -dict { PACKAGE_PIN G5    IOSTANDARD LVCMOS33 } [get_ports {seg_an[2]}];
set_property -dict { PACKAGE_PIN G4    IOSTANDARD LVCMOS33 } [get_ports {seg_an[3]}]; #MSB
 
set_property -dict { PACKAGE_PIN G2    IOSTANDARD LVCMOS33 } [get_ports {seg_cat[0]}];#A
set_property -dict { PACKAGE_PIN G1    IOSTANDARD LVCMOS33 } [get_ports {seg_cat[1]}];#B
set_property -dict { PACKAGE_PIN H5    IOSTANDARD LVCMOS33 } [get_ports {seg_cat[2]}];#C
set_property -dict { PACKAGE_PIN H4    IOSTANDARD LVCMOS33 } [get_ports {seg_cat[3]}];#D
set_property -dict { PACKAGE_PIN J5    IOSTANDARD LVCMOS33 } [get_ports {seg_cat[4]}];#E
set_property -dict { PACKAGE_PIN J4    IOSTANDARD LVCMOS33 } [get_ports {seg_cat[5]}];#F
set_property -dict { PACKAGE_PIN H2    IOSTANDARD LVCMOS33 } [get_ports {seg_cat[6]}];#G
set_property -dict { PACKAGE_PIN H1    IOSTANDARD LVCMOS33 } [get_ports {seg_cat[7]}];#DP


# VGA OUTPUTS (12-bit VGA)
set_property -dict { PACKAGE_PIN F14 IOSTANDARD LVCMOS33 } [get_ports {hsync}];
set_property -dict { PACKAGE_PIN H16 IOSTANDARD LVCMOS33 } [get_ports {vsync}];
set_property -dict { PACKAGE_PIN D15 IOSTANDARD LVCMOS33 } [get_ports {vga_r[0]}];
set_property -dict { PACKAGE_PIN F12 IOSTANDARD LVCMOS33 } [get_ports {vga_r[1]}];
set_property -dict { PACKAGE_PIN F13 IOSTANDARD LVCMOS33 } [get_ports {vga_r[2]}];
set_property -dict { PACKAGE_PIN E16 IOSTANDARD LVCMOS33 } [get_ports {vga_r[3]}];
set_property -dict { PACKAGE_PIN D16 IOSTANDARD LVCMOS33 } [get_ports {vga_g[0]}];
set_property -dict { PACKAGE_PIN F15 IOSTANDARD LVCMOS33 } [get_ports {vga_g[1]}];
set_property -dict { PACKAGE_PIN E15 IOSTANDARD LVCMOS33 } [get_ports {vga_g[2]}];
set_property -dict { PACKAGE_PIN H11 IOSTANDARD LVCMOS33 } [get_ports {vga_g[3]}];
set_property -dict { PACKAGE_PIN G12 IOSTANDARD LVCMOS33 } [get_ports {vga_b[0]}];
set_property -dict { PACKAGE_PIN H12 IOSTANDARD LVCMOS33 } [get_ports {vga_b[1]}];
set_property -dict { PACKAGE_PIN H13 IOSTANDARD LVCMOS33 } [get_ports {vga_b[2]}];
set_property -dict { PACKAGE_PIN G14 IOSTANDARD LVCMOS33 } [get_ports {vga_b[3]}];


# LEDs (OPTIONAL WINNER / STATUS DISPLAY)
set_property -dict { PACKAGE_PIN J3    IOSTANDARD LVCMOS33 } [get_ports { led[0] }];#LSB
set_property -dict { PACKAGE_PIN H3    IOSTANDARD LVCMOS33 } [get_ports { led[1] }];
set_property -dict { PACKAGE_PIN J1    IOSTANDARD LVCMOS33 } [get_ports { led[2] }];
set_property -dict { PACKAGE_PIN K1    IOSTANDARD LVCMOS33 } [get_ports { led[3] }];
set_property -dict { PACKAGE_PIN L3    IOSTANDARD LVCMOS33 } [get_ports { led[4] }];
set_property -dict { PACKAGE_PIN L2    IOSTANDARD LVCMOS33 } [get_ports { led[5] }];
set_property -dict { PACKAGE_PIN K3    IOSTANDARD LVCMOS33 } [get_ports { led[6] }];
set_property -dict { PACKAGE_PIN K2    IOSTANDARD LVCMOS33 } [get_ports { led[7] }];
set_property -dict { PACKAGE_PIN K5    IOSTANDARD LVCMOS33 } [get_ports { led[8] }];
set_property -dict { PACKAGE_PIN P6    IOSTANDARD LVCMOS33 } [get_ports { led[9] }];
set_property -dict { PACKAGE_PIN R7    IOSTANDARD LVCMOS33 } [get_ports { led[10] }];
set_property -dict { PACKAGE_PIN R6    IOSTANDARD LVCMOS33 } [get_ports { led[11] }];
set_property -dict { PACKAGE_PIN T5    IOSTANDARD LVCMOS33 } [get_ports { led[12] }];
set_property -dict { PACKAGE_PIN R5    IOSTANDARD LVCMOS33 } [get_ports { led[13] }];
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { led[14] }];
set_property -dict { PACKAGE_PIN T9    IOSTANDARD LVCMOS33 } [get_ports { led[15] }];#MSB


# UART TX (OPTIONAL)
set_property -dict { PACKAGE_PIN C4 IOSTANDARD LVCMOS33 } [get_ports {uart_tx_out}];
