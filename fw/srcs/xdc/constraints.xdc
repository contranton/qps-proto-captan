# SampleClock is 8MHz
# FrameClock is SampleClock/4 = 2.00MHz
# create_clock -period 500.000 -name ADC_FRAMECLK [get_ports adc_frame_clk]
# DataClock is FrameClock * 24 (Config = SDR + 4 lanes) =  60MHz
# Assume SDR with faster clock for higher design flexibility (live SDR/DDR switching).
# Commented out since clk_wiz_phase_shift overrides
#create_clock -period 16.667 -name ADC_DATACLK [get_ports adc_data_clk]

#set_clock_groups -asynchronous -group [get_clocks -of_objects [get_nets {MASTER_CLK adc_data_clk}]]
#set_clock_groups -asynchronous -group [get_clocks -of_objects [get_nets {MASTER_CLK adc_frame_clk}]]

create_generated_clock \
    -name adc_sample_clk_8mhz \
    -source [get_pins pll_MainClocks/clk_out_16] \
    [get_pins adc_sample_clk_8mhz_reg/Q] \
    -divide_by 2

create_generated_clock \
    -name adc_sample_clk_4mhz \
    -source [get_pins adc_sample_clk_8mhz_reg/Q] \
    [get_pins adc_sample_clk_4mhz_reg/Q] \
    -divide_by 2

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets adc_data_clk_IBUF]

#set_input_delay -clock ADC_DATACLK 30 [get_ports adc_data[*]]

#set_property IODELAY_GROUP DATA_0 [get_cells delay_inst/gen_delay[0].*]
#set_property IODELAY_GROUP DATA_1 [get_cells delay_inst/gen_delay[1].*]
#set_property IODELAY_GROUP DATA_2 [get_cells delay_inst/gen_delay[2].*]
#set_property IODELAY_GROUP DATA_3 [get_cells delay_inst/gen_delay[3].*]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets pll_PhaseShift/inst/clk_in_48_clk_wiz_phase_shift]
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets pll_PhyClock/inst/clk_in_125_clk_wiz_phy2adc]

# User LED
set_property PACKAGE_PIN J3 [get_ports user_led]
set_property IOSTANDARD LVCMOS25 [get_ports user_led]

set_property PACKAGE_PIN AA30 [get_ports USER_CLK1]
set_property IOSTANDARD LVCMOS33 [get_ports USER_CLK1]

# EVM connected in SW slot
set_property PACKAGE_PIN AB10 [get_ports adc_pwdn_n]
set_property IOSTANDARD LVCMOS18 [get_ports adc_pwdn_n]

set_property PACKAGE_PIN Y8 [get_ports adc_reset_n]
set_property IOSTANDARD LVCMOS18 [get_ports adc_reset_n]

set_property PACKAGE_PIN AA10 [get_ports adc_sample_clk]
set_property IOSTANDARD LVCMOS18 [get_ports adc_sample_clk]

set_property PACKAGE_PIN V9 [get_ports adc_frame_clk]
set_property IOSTANDARD LVCMOS18 [get_ports adc_frame_clk]

set_property PACKAGE_PIN W6 [get_ports adc_data_clk]
set_property IOSTANDARD LVCMOS18 [get_ports adc_data_clk]

set_property PACKAGE_PIN AK3 [get_ports {adc_spi_ctrl[SDI]}]
set_property IOSTANDARD LVCMOS18 [get_ports {adc_spi_ctrl[SDI]}]

set_property PACKAGE_PIN AM2 [get_ports {adc_spi_ctrl[SDO]}]
set_property IOSTANDARD LVCMOS18 [get_ports {adc_spi_ctrl[SDO]}]

set_property PACKAGE_PIN AL2 [get_ports {adc_spi_ctrl[SPI_EN]}]
set_property IOSTANDARD LVCMOS18 [get_ports {adc_spi_ctrl[SPI_EN]}]

set_property PACKAGE_PIN AN3 [get_ports {adc_spi_ctrl[CSn][0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {adc_spi_ctrl[CSn][0]}]


set_property PACKAGE_PIN AN1 [get_ports {adc_spi_ctrl[SCLK]}]
set_property IOSTANDARD LVCMOS18 [get_ports {adc_spi_ctrl[SCLK]}]

set_property PACKAGE_PIN W10 [get_ports {adc_data[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {adc_data[0]}]

set_property PACKAGE_PIN W5 [get_ports {adc_data[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {adc_data[1]}]

set_property PACKAGE_PIN R10 [get_ports {adc_data[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {adc_data[2]}]

set_property PACKAGE_PIN AA3 [get_ports {adc_data[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {adc_data[3]}]

# ------------------------------
# GEL

#set_property PACKAGE_PIN AA30 [get_ports USER_CLOCK]
#set_property IOSTANDARD LVCMOS25 [get_ports USER_CLOCK]

#RGMII uses the CTL line
#set_property PACKAGE_PIN AA32 [get_ports {phy_rx[PHY_RXER]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {phy_rx[PHY_RXER]}]

set_property PACKAGE_PIN Y30 [get_ports {phy_rx[PHY_RXCLK]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_rx[PHY_RXCLK]}]

set_property PACKAGE_PIN V31 [get_ports {phy_rx[PHY_RXCTL_RXDV]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_rx[PHY_RXCTL_RXDV]}]


set_property PACKAGE_PIN V24 [get_ports {phy_rx[PHY_RXD][0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_rx[PHY_RXD][0]}]

set_property PACKAGE_PIN W25 [get_ports {phy_rx[PHY_RXD][1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_rx[PHY_RXD][1]}]

set_property PACKAGE_PIN W24 [get_ports {phy_rx[PHY_RXD][2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_rx[PHY_RXD][2]}]

set_property PACKAGE_PIN Y28 [get_ports {phy_rx[PHY_RXD][3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_rx[PHY_RXD][3]}]

set_property PACKAGE_PIN Y25 [get_ports {phy_rx[PHY_RXD][4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_rx[PHY_RXD][4]}]

set_property PACKAGE_PIN AA25 [get_ports {phy_rx[PHY_RXD][5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_rx[PHY_RXD][5]}]

set_property PACKAGE_PIN AA24 [get_ports {phy_rx[PHY_RXD][6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_rx[PHY_RXD][6]}]

set_property PACKAGE_PIN AB25 [get_ports {phy_rx[PHY_RXD][7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_rx[PHY_RXD][7]}]


set_property PACKAGE_PIN Y31 [get_ports {phy_tx[PHY_TXCLK]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_tx[PHY_TXCLK]}]

#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {phy_tx[PHY_TXC_GTXCLK]}]

set_property PACKAGE_PIN V32 [get_ports {phy_tx[PHY_TXCTL_TXEN]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_tx[PHY_TXCTL_TXEN]}]


set_property PACKAGE_PIN V33 [get_ports {phy_tx[PHY_TXER]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_tx[PHY_TXER]}]


set_property PACKAGE_PIN W28 [get_ports {phy_tx[PHY_TXD][0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_tx[PHY_TXD][0]}]

set_property PACKAGE_PIN W26 [get_ports {phy_tx[PHY_TXD][1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_tx[PHY_TXD][1]}]

set_property PACKAGE_PIN Y32 [get_ports {phy_tx[PHY_TXD][2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_tx[PHY_TXD][2]}]

set_property PACKAGE_PIN AA28 [get_ports {phy_tx[PHY_TXD][3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_tx[PHY_TXD][3]}]

set_property PACKAGE_PIN AA27 [get_ports {phy_tx[PHY_TXD][4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_tx[PHY_TXD][4]}]

set_property PACKAGE_PIN AB27 [get_ports {phy_tx[PHY_TXD][5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_tx[PHY_TXD][5]}]

set_property PACKAGE_PIN AB26 [get_ports {phy_tx[PHY_TXD][6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_tx[PHY_TXD][6]}]

set_property PACKAGE_PIN AC31 [get_ports {phy_tx[PHY_TXD][7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_tx[PHY_TXD][7]}]

set_property PACKAGE_PIN Y33 [get_ports PHY_RESET]
set_property IOSTANDARD LVCMOS33 [get_ports PHY_RESET]


