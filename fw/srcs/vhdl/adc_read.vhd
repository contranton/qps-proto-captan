-------------------------------------------------------------------------------
-- Title : ADC Reader
-- Project :
-------------------------------------------------------------------------------
-- File : adc_read.vhd
-- Author : <javierc@correlator6.fnal.gov>
-- Company :
-- Created : 2025-05-22
-- Last update: 2025-05-27
-- Platform :
-- Standard : VHDL'08
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2025
-------------------------------------------------------------------------------
-- Revisions :
-- Date Version Author Description
-- 2025-05-22 1.0 javierc Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.qps_pkg.all;

entity adc_read is
  port (
    data_clk       : in  std_logic;
    frame_clk      : in  std_logic;
    adc_data       : in  std_logic;
    output_streams : out t_ADC_WORD
    );
end entity adc_read;

architecture rtl of adc_read is
  signal counter : natural := 0;
begin  -- architecture rtl

  proc_read : process(data_clk) is
  begin
    if rising_edge(data_clk) then
      output_streams(counter) <= adc_data;
      counter <= counter + 1;
      if (counter >= t_ADC_WORD'length) then
        counter <= 0;
      end if;
    end if;
  end process proc_read;

  --proc_frame : process(frame_clk) is
  --begin
  --  if rising_edge(frame_clk) then
  --    counter <= 0;
  --  end if;
  --end process proc_frame;

end architecture rtl;
