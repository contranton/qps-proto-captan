-------------------------------------------------------------------------------
-- Title      : Packetizer
-- Project    :
-------------------------------------------------------------------------------
-- File       : packetizer.vhd
-- Author     :   <javierc@correlator6.fnal.gov>
-- Company    :
-- Created    : 2025-05-22
-- Last update: 2025-05-27
-- Platform   :
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2025
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2025-05-22  1.0      javierc	Created
-------------------------------------------------------------------------------

use work.qps_pkg.all;

entity packetizer is
 port (
   adc_streams : in t_ADC_WORD;
   packetized_data : out t_ADC_WORD
   );
end entity packetizer;

architecture rtl of packetizer is

begin  -- architecture rtl

  packetized_data <= adc_streams;

end architecture rtl;
