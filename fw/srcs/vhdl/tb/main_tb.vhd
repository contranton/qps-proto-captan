-------------------------------------------------------------------------------
-- Title      : Testbench for design "main"
-- Project    :
-------------------------------------------------------------------------------
-- File       : main_tb.vhd
-- Author     :   <javierc@correlator6.fnal.gov>
-- Company    :
-- Created    : 2025-07-11
-- Last update: 2025-08-06
-- Platform   :
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2025
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2025-07-11  1.0      javierc	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


use work.sim_pkg.all;
use work.qps_pkg.all;
use work.ads9813_pkg.all;

-------------------------------------------------------------------------------

entity main_tb is

  generic (
    c_USER_CLK_FREQ_MHZ : real := 100.0
    );

end entity main_tb;

-------------------------------------------------------------------------------

architecture sim of main_tb is

  constant c_FREQUENCY_SAMPLE_CLOCK : t_frequency_mhz     := 4.0;
  constant c_DATA_LANES             : integer             := 4;
  constant c_DATA_RATE              : t_ADS9813_DATA_RATE := 2;

  signal USER_CLK1        : std_logic;
  signal user_led         : std_logic;
  signal clk_ADC_FRAME    : std_logic;
  signal clk_ADC_DATA     : std_logic;
  signal adc_data         : t_ADC_RAW_DATA(3 downto 0);
  signal adc_pwdn_n       : std_logic;
  signal adc_reset_n      : std_logic;
  signal adc_spi_ctrl     : t_ADC_CTRL;
  signal clk_ADC_SAMPLING : std_logic;
  signal phy_rx           : t_GEL_PHY_RX;
  signal phy_tx           : t_GEL_PHY_TX;
  signal PHY_RESET        : std_logic;

  signal reset_n      : std_logic;
  signal pwdn_n       : std_logic;
  signal sample_clock : std_logic;
  signal spi_ctrl     : t_ADC_CTRL;
  signal data_clock   : std_logic;
  signal frame_clock  : std_logic;
  signal d0           : std_logic;
  signal d1           : std_logic;
  signal d2           : std_logic;
  signal d3           : std_logic;

  begin

  main_i: entity work.main
    port map (
      USER_CLK1        => USER_CLK1,
      user_led         => user_led,
      clk_ADC_FRAME    => clk_ADC_FRAME,
      clk_ADC_DATA     => clk_ADC_DATA,
      adc_data         => adc_data,
      adc_pwdn_n       => adc_pwdn_n,
      adc_reset_n      => adc_reset_n,
      adc_spi_ctrl     => adc_spi_ctrl,
      clk_ADC_SAMPLING => clk_ADC_SAMPLING,
      phy_rx           => phy_rx,
      phy_tx           => phy_tx,
      PHY_RESET        => PHY_RESET);

  ads9813_mockup_1: entity work.ads9813_mockup
    generic map (
      c_FREQUENCY_SAMPLE_CLOCK => c_FREQUENCY_SAMPLE_CLOCK,
      c_DATA_LANES             => c_DATA_LANES,
      c_DATA_RATE              => c_DATA_RATE)
    port map (
      reset_n      => reset_n,
      pwdn_n       => pwdn_n,
      sample_clock => clk_ADC_SAMPLING,
      spi_ctrl     => adc_spi_ctrl,
      data_clock   => clk_ADC_DATA,
      frame_clock  => clk_ADC_FRAME,
      d0           => adc_data(0),
      d1           => adc_data(1),
      d2           => adc_data(2),
      d3           => adc_data(3)
      );

  -- clock generation
  gen_clocks : process is
  begin
    USER_CLK1 <= not USER_CLK1;
    wait for (1000.0 / c_USER_CLK_FREQ_MHZ) * 1 ns;
  end process gen_clocks;


  p_stop : process is
    alias done is << signal .main_tb.main_i.if_AutoalignControl.done : std_logic>>;
    begin
      wait until done = '1';
  end process p_stop;

end architecture sim;

