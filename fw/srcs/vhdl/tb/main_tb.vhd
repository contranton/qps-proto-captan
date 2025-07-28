-------------------------------------------------------------------------------
-- Title      : Testbench for design "main"
-- Project    :
-------------------------------------------------------------------------------
-- File       : main_tb.vhd
-- Author     :   <javierc@correlator6.fnal.gov>
-- Company    :
-- Created    : 2025-07-11
-- Last update: 2025-07-15
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


use work.qps_pkg.all;

-------------------------------------------------------------------------------

entity main_tb is

  generic (
    c_USER_CLK_FREQ_MHZ : real := 100.0
    );

end entity main_tb;

-------------------------------------------------------------------------------

architecture sim of main_tb is

  signal clk   : std_logic := '0';
  signal reset : std_logic := '1';

  -- component ports
  signal adc_frame_clk  : std_logic;
  signal adc_data_clk   : std_logic;
  signal adc_spi_ctrl   : t_ADC_CTRL;
  signal adc_data       : t_ADC_RAW_DATA(3 downto 0);
  signal adc_pwdn_n     : std_logic;
  signal adc_reset_n    : std_logic;
  signal adc_sample_clk : std_logic;
  signal USER_CLK1      : std_logic := '0';
  signal user_led       : std_logic;
  signal phy_rx         : t_GEL_PHY_RX;
  signal phy_tx         : t_GEL_PHY_TX;
  signal PHY_RESET      : std_logic;

  -- signals for autoalign
  signal deserializer_raw_data       : std_logic_vector(191 downto 0) := (others => '0');
  signal deserializer_raw_data_valid : std_logic := '0';
  signal trigger                     : std_logic := '0';
  signal n_delays                    : signed(15 downto 0) := (others => '0');
  signal autoalign_done              : std_logic := '0';
  signal phase_shift_button_forward  : std_logic := '0';
  signal phase_shift_button_backward : std_logic := '0';
  signal phase_shift_done            : std_logic := '0';

  -- signals for deserializer


begin  -- architecture sim

  -- component instantiation
    DUT: entity work.main
      generic map(
        c_NUM_ADC_CHANNELS => 8
      )
      port map (
        adc_frame_clk  => adc_frame_clk,
        adc_data_clk   => adc_data_clk,
        adc_spi_ctrl   => adc_spi_ctrl,
        adc_data       => adc_data,
        adc_pwdn_n     => adc_pwdn_n,
        adc_reset_n    => adc_reset_n,
        adc_sample_clk => adc_sample_clk,
        USER_CLK1      => USER_CLK1,
        user_led       => user_led,
        phy_rx         => phy_rx,
        phy_tx         => phy_tx,
        PHY_RESET      => PHY_RESET);

  ADC: entity work.ads9813_mockup
    generic map(
      c_FREQUENCY_SAMPLE_CLOCK => 4.0,
      c_DATA_LANES => 4,
      c_DATA_RATE => 2
    )
    port map(
      spi_ctrl     => adc_spi_ctrl,
      reset_n      => adc_reset_n,
      pwdn_n       => adc_pwdn_n,
      sample_clock => adc_sample_clk,
      data_clock   => adc_data_clk,
      frame_clock  => adc_frame_clk,
      d0           => adc_data(0),
      d1           => adc_data(1),
      d2           => adc_data(2),
      d3           => adc_data(3)
    );

  ti_deserializer : entity work.deser_cmos
    port map(
      CMOS_DIN_A        => adc_data(0),
      CMOS_DIN_B        => adc_data(1),
      CMOS_DIN_C        => adc_data(2),
      CMOS_DIN_D        => adc_data(3),
      DCLK              => adc_data_clk,
      FCLK              => adc_frame_clk,
      data_rate         => '0',         -- 0: DDR, 1: SDR
      data_lanes        => "10",        -- 4 lanes
      flip_ddr_polarity => '0',
      RST               => reset,
      DRDY              => deserializer_raw_data_valid,
      DOUT              => deserializer_raw_data
      );

  adc_autoalign_1: entity work.adc_autoalign
    port map (
      clk                         => adc_data_clk,
      reset                       => reset,
      deserializer_raw_data       => deserializer_raw_data,
      deserializer_raw_data_valid => deserializer_raw_data_valid,
      trigger                     => trigger,
      n_delays                    => n_delays,
      autoalign_done              => autoalign_done,
      phase_shift_button_forward  => phase_shift_button_forward,
      phase_shift_button_backward => phase_shift_button_backward,
      phase_shift_done            => phase_shift_done);

  -- clock generation
  gen_clocks : process is
  begin
    USER_CLK1 <= not USER_CLK1;
    wait for (1000.0 / c_USER_CLK_FREQ_MHZ) * 1 ns;
  end process gen_clocks;


  p_stop : process is
    begin
      wait until autoalign_done = '1';
  end process p_stop;

end architecture sim;

