-------------------------------------------------------------------------------
-- Title      : Simulation mockup of ADS9813 ADC
-- Project    :
-------------------------------------------------------------------------------
-- File       : ads9813_mockup.vhd
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

library std;
  use std.textio.all;

library work;
  use work.sim_pkg.t_frequency_mhz;
  use work.ads9813_pkg.all;
  use work.qps_pkg.all;

entity ads9813_mockup is

  generic (
    c_FREQUENCY_SAMPLE_CLOCK : t_frequency_mhz := 4.0;
    c_DATA_LANES : integer           := 4;
    c_DATA_RATE  : t_ADS9813_DATA_RATE := 2);

  port (
    reset_n      : in std_logic;
    pwdn_n       : in std_logic;
    sample_clock : in std_logic;
    spi_ctrl     : in t_ADC_CTRL;
    data_clock   : out std_logic;
    frame_clock  : out std_logic;
    d0           : out std_logic;
    d1           : out std_logic;
    d2           : out std_logic;
    d3           : out std_logic);

end entity ads9813_mockup;

architecture sim of ads9813_mockup is

    signal s_data_clock   : std_logic := '0';
    signal s_frame_clock  : std_logic := '0';
    signal s_d0           : std_logic := '0';
    signal s_d1           : std_logic := '0';
    signal s_d2           : std_logic := '0';
    signal s_d3           : std_logic := '0';

    constant c_PERIOD_SAMPLE_CLOCK : time := (1000.0 / c_FREQUENCY_SAMPLE_CLOCK) * 1ns;
    constant c_PERIOD_FRAME_CLOCK : time := (c_PERIOD_SAMPLE_CLOCK * 4);
    constant c_PERIOD_DATA_CLOCK : time := (c_PERIOD_FRAME_CLOCK) * (real(c_DATA_RATE * c_DATA_LANES) / (24.0 * 8.0));

begin  -- architecture sim

  data_clock <= s_data_clock;
  frame_clock <= s_frame_clock;
  d0 <= s_d0;
  d1 <= s_d1;
  d2 <= s_d2;
  d3 <= s_d3;

  p_GenerateFrameClock : process is
    begin
      wait until rising_edge(s_data_clock);
      s_frame_clock <= '1';
      wait for 3 * (c_PERIOD_DATA_CLOCK);
      wait until falling_edge(s_data_clock);
      s_frame_clock <= '0';
      wait for (c_PERIOD_FRAME_CLOCK - 3*c_PERIOD_DATA_CLOCK);
  end process p_GenerateFrameClock;

  p_GenerateDataClock : process is
    begin
      s_data_clock <= not s_data_clock;
      wait for (c_PERIOD_DATA_CLOCK / 2);
  end process p_GenerateDataClock;

  p_ReadData : process is
      file input_file : text open read_mode is "/data/javierc/800_SIM_DATA/qps_prototype/adc_data.txt";
      variable line_buf : line;
      variable value_str : string(1 to 10);
      variable value_int : integer;
      variable value_unsigned : unsigned(7 downto 0);
    begin
      while not endfile(input_file) loop
        readline(input_file, line_buf);
        read(line_buf, value_int);
        value_unsigned := to_unsigned(value_int, 8);

        s_d0 <= value_unsigned(0);
        s_d1 <= value_unsigned(1);
        s_d2 <= value_unsigned(2);
        s_d3 <= value_unsigned(3);
        wait until rising_edge(s_data_clock);

        s_d0 <= value_unsigned(4);
        s_d1 <= value_unsigned(5);
        s_d2 <= value_unsigned(6);
        s_d3 <= value_unsigned(7);
        wait until falling_edge(s_data_clock);
      end loop;
    assert false report "Simulation completed" severity failure;
  end process p_ReadData;

end architecture sim;
