-------------------------------------------------------------------------------
-- Title      : Delay control for DDR data
-- Project    :
-------------------------------------------------------------------------------
-- File       : delay.vhd
-- Author     :   <javierc@correlator6.fnal.gov>
-- Company    :
-- Created    : 2025-06-30
-- Last update: 2025-06-30
-- Platform   :
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2025
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2025-06-30  1.0      javierc	Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity delay is

  port (
    adc_data_in     : in std_logic_vector(3 downto 0);
    adc_data_out     : out std_logic_vector(3 downto 0);
    delay_clk : in std_logic);

end entity delay;


architecture rtl of delay is


  signal CNTVALUEOUT : std_logic_vector(4 downto 0);
  signal DATAOUT     : std_logic;
  signal C           : std_logic;
  signal CE          : std_logic;
  signal CINVCTRL    : std_logic;
  signal CNTVALUEIN  : std_logic_vector(4 downto 0);
  signal DATAIN      : std_logic;
  signal IDATAIN     : std_logic;
  signal INC         : std_logic;
  signal LD          : std_logic;
  signal LDPIPEEN    : std_logic;
  signal REGRST      : std_logic;

  signal RDY    : std_logic;
  signal REFCLK : std_logic;
  signal RST    : std_logic;
 
  begin

  gen_delay : for ii in 0 to 3 generate
  IDELAYE2_ii: IDELAYE2
    generic map (
      CINVCTRL_SEL          => "FALSE",
      DELAY_SRC             => "IDATAIN",
      HIGH_PERFORMANCE_MODE => "TRUE",
      IDELAY_TYPE           => "FIXED",
      IDELAY_VALUE          => 31,
      IS_C_INVERTED         => '0',
      REFCLK_FREQUENCY      => 200.0,
      PIPE_SEL              => "FALSE",
      SIGNAL_PATTERN        => "DATA")
    port map (
      CNTVALUEOUT => open,
      DATAOUT     => adc_data_out(ii),
      C           => delay_clk,
      CE          => '1',
      CINVCTRL    => '0',
      CNTVALUEIN  => "00000",
      IDATAIN      => adc_data_in(ii),
      DATAIN     => '0',
      INC         => '1',
      LD          => '0',
      LDPIPEEN    => '0',
      REGRST      => '0');

  IDELAYCTRL_ii: IDELAYCTRL
    port map (
      RDY    => open,
      REFCLK => delay_clk,
      RST    => '0');


  end generate gen_delay;

end architecture rtl;
