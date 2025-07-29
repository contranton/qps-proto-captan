-------------------------------------------------------------------------------
--
--        _-    -_
--       |  |  |  |            Fermi National Accelerator Laboratory
--       |  |  |  |
--       |  |  |  |        Operated by Fermi Forward Discovery Group, LLC
--       |  |  |  |        for the Department of Energy under contract
--       /  |  |   \                    89243024CSC000002
--      /   /   \   \
--     /   /     \   \
--     ----       ----
-------------------------------------------------------------------------------
-- Title      : Definitions for QPS demo project
-- Project    : QPS (Quench Prediction System) Prototype for APS-TD
-------------------------------------------------------------------------------
-- File       : main.vhd
-- Author     :   <javierc@correlator6.fnal.gov>
-- Division   : CSAID/RTPS/DIS
-- Created    : 2025-05-22
-- Last update: 2025-07-29
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: This package defines types for a simple DAQ system based on
-- otsdaq for CMS.
-------------------------------------------------------------------------------
-- Copyright (c) 2025 Fermi Forward Discovery Group, LLC
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2025-05-22  1.0      javierc   Created
-------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package qps_pkg is

  constant c_ADC_BITS : natural := 24;
  constant c_NUM_ADC_CHANNELS : natural := 8;
  constant c_MSB : natural := c_ADC_BITS*c_NUM_ADC_CHANNELS;

  constant c_LOG2_CHANNELS : natural := integer(ceil(log2(real(c_NUM_ADC_CHANNELS))));
  constant c_BITS_TIMESTAMP : natural := 64 - c_ADC_BITS - c_LOG2_CHANNELS;

  subtype t_ADC_WORD is std_logic_vector(c_ADC_BITS - 1 downto 0);

  type t_DESERIALIZER_OUTPUT is record
    ch1 : t_ADC_WORD;
    ch2 : t_ADC_WORD;
    ch3 : t_ADC_WORD;
    ch4 : t_ADC_WORD;
    ch5 : t_ADC_WORD;
    ch6 : t_ADC_WORD;
    ch7 : t_ADC_WORD;
    ch8 : t_ADC_WORD;
  end record t_DESERIALIZER_OUTPUT;

  type t_ADC_CTRL is record
    SPI_EN : std_logic;
    CSn    : std_logic_vector(0 downto 0);
    SCLK   : std_logic;
    SDI    : std_logic;
    SDO    : std_logic;
  end record t_ADC_CTRL;

  type t_ADC_RAW_DATA is array(natural range<>) of std_logic;

  type t_ADC_BUS is array(natural range <>) of t_ADC_WORD;

  type t_PACKET is record
    timestamp : std_logic_vector(c_BITS_TIMESTAMP-1 downto 0);
    channel : std_logic_vector(c_LOG2_CHANNELS-1 downto 0);
    data : std_logic_vector(c_ADC_BITS-1 downto 0);
  end record t_PACKET;

  type t_MB_GPIO is record
    PhaseShiftForwardButton  : std_logic;
    PhaseShiftBackwardButton : std_logic;
  end record t_MB_GPIO;

  type t_PHASE_SHIFT_IF is record
    enable : std_logic;
    clk    : std_logic;
    incdec : std_logic;
    done   : std_logic;
  end record t_PHASE_SHIFT_IF;

  type t_ETHERNET_INTERFACE is record
    gel_reset_in  : std_logic;
    gel_reset_out : std_logic;
    rx_addr       : std_logic_vector (31 downto 0);
    rx_data       : std_logic_vector (63 downto 0);
    rx_wren       : std_logic;
    tx_data       : std_logic_vector (63 downto 0);
    b_data        : std_logic_vector (63 downto 0);
    b_data_we     : std_logic;
    b_enable      : std_logic;
  end record t_ETHERNET_INTERFACE;

  type t_GEL_PHY_RX is record
    PHY_RXCLK      : std_logic;
    PHY_RXD        : std_logic_vector (7 downto 0);
    PHY_RXCTL_RXDV : std_logic;
  --PHY_RXER : std_logic;
  end record t_GEL_PHY_RX;

  type t_GEL_PHY_TX is record
    PHY_TXCLK      : std_logic;
    PHY_TXD        : std_logic_vector (7 downto 0);
    PHY_TXCTL_TXEN : std_logic;
    PHY_TXER       : std_logic;
  end record t_GEL_PHY_TX;

  --function fix_deserializer_bits( x : std_logic_vector(23 downto 0) )
    --return std_logic_vector(23 downto 0);

  function flatten_array(input : t_ADC_BUS) return std_logic_vector;

end package qps_pkg;

package body qps_pkg is

  function flatten_array(input : t_ADC_BUS) return std_logic_vector is
    variable result : std_logic_vector(input'length * input(0)'length - 1 downto 0);
    constant word_width : integer := input(0)'length;
begin
    for i in input'range loop
        result((i+1)*word_width - 1 downto i*word_width) := input(i);
    end loop;
    return result;
  end function;

  --function fix_deserializer_bits(
    --x : std_logic_vector(23 downto 0)
    --) return std_logic_vector(23 downto 0) is
    --signal y : std_logic_vector(23 downto 0);
  --begin
    --y(23 downto 20) <= x(23 - 4 to 23);
    --y(19 downto 16) <= x(23 - 4 to 23);
    --y(15 downto 12) <= x(23 - 4 to 23);
    --y(11 downto 8) <= x(23 - 4 to 23);
    --y(7 downto 4) <= x(23 - 4 to 23);
    --y(3 downto 0) <= x(23 - 4 to 23);
    --return y;

end package body qps_pkg;
