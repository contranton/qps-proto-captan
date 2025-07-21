-------------------------------------------------------------------------------
-- Title      : Testbench for design "ethernet_interface"
-- Project    :
-------------------------------------------------------------------------------
-- File       : ethernet_interface_tb.vhd
-- Author     :   <javierc@correlator6.fnal.gov>
-- Company    :
-- Created    : 2025-06-11
-- Last update: 2025-06-17
-- Platform   :
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2025
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2025-06-11  1.0      javierc	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

-------------------------------------------------------------------------------

entity ethernet_interface_tb is

end entity ethernet_interface_tb;

-------------------------------------------------------------------------------

architecture sim of ethernet_interface_tb is

  shared variable seed1 : positive := 10;
  shared variable seed2 : positive := 10;

  impure function rand_slv(len : integer) return std_logic_vector is
    variable r : real;
    variable slv : std_logic_vector(len - 1 downto 0);
  begin
    for i in slv'range loop
      uniform(seed1, seed2, r);
      if r > 0.5 then
        slv(i) := '1';
      else
        slv(i) := '0';
      end if;
    end loop;
    return slv;
  end function;

  -- component ports
  signal reset_in   : std_logic := '0';
  signal reset_out  : std_logic := '0';
  signal rx_addr    : std_logic_vector (31 downto 0) := (others => '0');
  signal rx_data    : std_logic_vector (63 downto 0) := (others => '0');
  signal rx_wren    : std_logic := '0';
  signal tx_data    : std_logic_vector (63 downto 0) := (others => '0');
  signal b_data     : std_logic_vector (63 downto 0) := (others => '0');
  signal b_data_we  : std_logic := '0';
  signal b_enable   : std_logic := '0';
  signal MASTER_CLK : std_logic := '0';
  signal PHY_RXD    : std_logic_vector (7 downto 0) := (others => '0');
  signal PHY_RX_DV  : std_logic := '0';
  signal PHY_RX_ER  : std_logic := '0';
  signal TX_CLK     : std_logic := '0';
  signal PHY_TXD    : std_logic_vector (7 downto 0) := (others => '0');
  signal PHY_TX_EN  : std_logic := '0';
  signal PHY_TX_ER  : std_logic := '0';

begin  -- architecture sim

  -- component instantiation
  DUT: entity work.ethernet_interface
    port map (
      reset_in   => reset_in,
      reset_out  => reset_out,
      rx_addr    => rx_addr,
      rx_data    => rx_data,
      rx_wren    => rx_wren,
      tx_data    => tx_data,
      b_data     => b_data,
      b_data_we  => b_data_we,
      b_enable   => b_enable,
      MASTER_CLK => MASTER_CLK,
      PHY_RXD    => PHY_RXD,
      PHY_RX_DV  => PHY_RX_DV,
      PHY_RX_ER  => PHY_RX_ER,
      TX_CLK     => TX_CLK,
      PHY_TXD    => PHY_TXD,
      PHY_TX_EN  => PHY_TX_EN,
      PHY_TX_ER  => PHY_TX_ER);

  -- clock generation
  MASTER_CLK <= not MASTER_CLK after 10 ns;

  -- waveform generation
  WaveGen_Proc: process
  begin
    -- insert signal assignments here
    wait until reset_out = '0';
    wait for 2 us;


    wait until rising_edge(MASTER_CLK);

    reset_in <= '0';

    PHY_RX_DV <= '1';
    -- PHY_RX_ER <= '1';

    b_data <= x"DEADBEEFDEADBEEF";
    b_data_we <= '1';

    wait for 1 us;
    wait until rising_edge(MASTER_CLK);
    b_data_we <= '0';

    wait for 1 us;
    wait until rising_edge(MASTER_CLK);

    tx_data <= x"1234ABCD9876FEDC";

    wait for 1 us;
    wait until rising_edge(MASTER_CLK);

  end process WaveGen_Proc;


  data_gen : process is
    variable the_random : real;
    variable SEED : positive := 10;
  begin
      wait until rising_edge(MASTER_CLK);
      PHY_RXD <= rand_slv(PHY_RXD'length);
  end process data_gen;


end architecture sim;

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
