-------------------------------------------------------------------------------
-- Title : Packet serializer for burst transactions
-- Project :
-------------------------------------------------------------------------------
-- File : serializer.vhd
-- Author : <javierc@correlator6.fnal.gov>
-- Company :
-- Created : 2025-05-23
-- Last update: 2025-06-09
-- Platform :
-- Standard : VHDL'08
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2025
-------------------------------------------------------------------------------
-- Revisions :
-- Date Version Author Description
-- 2025-05-23 1.0 javierc Created
-------------------------------------------------------------------------------

use work.qps_pkg.all;

library ieee;
use ieee.std_logic_1164.all;

entity serializer is

  generic (
    NUM_CHANNELS : natural := 8
    );
  port (
    packetized_data : in  t_PACKETIZED(NUM_CHANNELS-1 downto 0);
    burst_data      : out std_logic_vector(c_ADC_BITS*NUM_CHANNELS-1 downto 0)
    );

end entity serializer;




architecture rtl of serializer is

begin  -- architecture rtl

  burst_assign: for ii in 0 to NUM_CHANNELS-1 generate
    burst_data((ii+1)*c_ADC_BITS-1 downto ii*c_ADC_BITS) <= std_logic_vector(packetized_data(ii));
  end generate;

end architecture rtl;
