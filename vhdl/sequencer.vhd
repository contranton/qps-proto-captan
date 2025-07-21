-------------------------------------------------------------------------------
-- Title : Sequencer for parallel-serial muxing
-- Project :
-------------------------------------------------------------------------------
-- File : sequencer.vhd
-- Author : <javierc@correlator6.fnal.gov>
-- Company :
-- Created : 2025-05-23
-- Last update: 2025-07-21
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
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.qps_pkg.all;

entity sequencer is
  generic(
    NUM_CHANNELS : natural := 4
    );
  port(
    clk         : in  std_logic;
    valid_in    : in  std_logic;
    input_bus   : in  t_ADC_BUS(0 to NUM_CHANNELS-1);
    ready_in    : in std_logic;
    valid_out   : out std_logic;
    output_data : out t_ADC_WORD;
    sequencer_channel: out std_logic_vector(c_LOG2_CHANNELS-1 downto 0)
    );
end entity sequencer;


architecture rtl of sequencer is
  signal counter : integer := 0;
begin  -- architecture rtl

  do_sequencer : process(clk) is
  begin
    if rising_edge(clk) then
      if (valid_in = '1' and ready_in = '1') then
        valid_out   <= '1';
        output_data <= input_bus(counter);
        if counter < NUM_CHANNELS then
          counter <= counter + 1;
        else
          counter <= 0;
        end if;
      else
        valid_out   <= '0';
        output_data <= (others => '0');
      end if;
    end if;
  end process do_sequencer;

  sequencer_channel <= std_logic_vector(to_unsigned(counter, c_LOG2_CHANNELS));

end architecture rtl;
