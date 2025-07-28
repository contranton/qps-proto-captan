-------------------------------------------------------------------------------
-- Title      : Testbench for design "sequencer"
-- Project    :
-------------------------------------------------------------------------------
-- File       : sequencer_tb.vhd
-- Author     :   <javierc@correlator6.fnal.gov>
-- Company    :
-- Created    : 2025-07-23
-- Last update: 2025-07-23
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2025
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2025-07-23  1.0      javierc	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.qps_pkg.all;
-------------------------------------------------------------------------------

entity sequencer_tb is

end entity sequencer_tb;

-------------------------------------------------------------------------------

architecture sim of sequencer_tb is

  -- component generics
  constant NUM_CHANNELS : natural := 8;

  -- component ports
  signal clk               : std_logic := '1';
  signal valid_in          : std_logic := '0';
  signal input_bus         : t_ADC_BUS(0 to NUM_CHANNELS-1);
  signal ready_in          : std_logic := '0';
  signal valid_out         : std_logic := '0';
  signal output_data       : t_ADC_WORD;
  signal sequencer_channel : std_logic_vector(c_LOG2_CHANNELS-1 downto 0);

begin  -- architecture sim

  -- component instantiation
  DUT: entity work.sequencer
    generic map (
      NUM_CHANNELS => NUM_CHANNELS)
    port map (
      clk               => clk,
      valid_in          => valid_in,
      input_bus         => input_bus,
      ready_in          => ready_in,
      valid_out         => valid_out,
      output_data       => output_data,
      sequencer_channel => sequencer_channel);

  -- clock generation
  Clk <= not Clk after 10 ns;

  -- waveform generation
  WaveGen_Proc: process
    variable i : integer := 0;
  begin
    -- insert signal assignments here

    wait until rising_edge(clk);
    input_bus(0) <= x"123456";
    input_bus(1) <= x"123456";
    input_bus(2) <= x"123456";
    input_bus(3) <= x"123456";
    input_bus(4) <= x"789ABC";
    input_bus(5) <= x"789ABC";
    input_bus(6) <= x"789ABC";
    input_bus(7) <= x"789ABC";
    valid_in <= '1';

    wait until rising_edge(clk);
    valid_in <= '0';

    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    ready_in <= '1';

    for i in 0 to 100 loop
      wait until rising_edge(clk);
    end loop;

  end process WaveGen_Proc;



end architecture sim;
