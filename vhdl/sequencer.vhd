-------------------------------------------------------------------------------
-- Title : Sequencer for parallel-serial muxing
-- Project :
-------------------------------------------------------------------------------
-- File : sequencer.vhd
-- Author : <javierc@correlator6.fnal.gov>
-- Company :
-- Created : 2025-05-23
-- Last update: 2025-07-23
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
  signal valid_inner : std_logic := '0';
  type t_sequencer_fsm is (WAITING, SENDING);
  signal state : t_sequencer_fsm;

  signal data_reg : t_ADC_BUS(0 to NUM_CHANNELS-1);
begin  -- architecture rtl

  p_Sequencer : process(clk) is
  begin
    if rising_edge(clk) then
      if (state = WAITING) then
        if valid_in = '1' then
          data_reg <= input_bus;
          state <= SENDING;
          counter <= 0;
          valid_out <= '1';
        end if;
      end if;

      if (state = SENDING) then
        if (ready_in = '1') then
          counter <= counter + 1;
          if (counter + 1 >= NUM_CHANNELS) then
            state <= WAITING;
            counter <= 0;
            valid_out <= '0';
          end if;
        end if;
      end if;
    end if;
  end process p_Sequencer;

--  do_sequencer : process(clk) is
--  begin
--    if rising_edge(clk) then
--      if (valid_in = '1' and ready_in = '1') then
--        valid_out   <= '1';
--        output_data <= input_bus(counter);
--        if counter < NUM_CHANNELS then
--          valid_inner <= '1';
--          counter <= counter + 1;
--        else
--          valid_inner <= '0';
--          counter <= 0;
--        end if;
--      else
--        valid_out   <= '0';
--        valid_inner <= '1';
--        output_data <= (others => '0');
--      end if;
--    end if;
--  end process do_sequencer;

  output_data <= data_reg(counter);
  sequencer_channel <= std_logic_vector(to_unsigned(counter, c_LOG2_CHANNELS));

end architecture rtl;
