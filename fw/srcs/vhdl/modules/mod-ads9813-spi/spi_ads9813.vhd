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
-- Title      : SPI controller for ADS9813 ADC
-- Project    :
-------------------------------------------------------------------------------
-- File       : spi_ads9813.vhd
-- Author     :   <javierc@correlator6.fnal.gov>
-- Division   : CSAID/RTPS/DIS
-- Created    : 2025-07-29
-- Last update: 2025-07-30
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Generates SPI transactions for ADC configuration
-------------------------------------------------------------------------------
-- Copyright (c) 2025 Fermi Forward Discovery Group, LLC
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2025-07-29  1.0      javierc     Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ads9813_pkg.all;

entity SpiController_ADS9813 is

  port (
    clk             : in  std_logic;
    FunctionAddress : in  t_enum_ADS9813_SPI_FUNCTIONS;
    trigger         : in  std_logic;
    if_Spi          : inout t_SPI_MGT);

end entity SpiController_ADS9813;

architecture rtl of SpiController_ADS9813 is

  -- <State Machine>
  type t_fsm_CommunicationState is (st_IDLE, st_TX, st_WAIT, st_RX);
  signal fsm_CommunicationState : t_fsm_CommunicationState;
  -- </.>

  -- <Transmission FIFO>
  signal sig_TxBuffer : t_arr_SPI_TX_BUFFER(0 to 9);
  signal sig_TxPointer : unsigned(5 downto 0);
  -- </.>

  procedure proc_InitAdc (
    signal if_Spi : inout t_SPI_MGT;
    signal clk    : in    std_logic);

begin  -- architecture rtl

  p_fsm_Communication: process(clk) is
  begin
    if rising_edge(clk) then
      case fsm_CommunicationState is
        when st_IDLE =>
          null;
        when st_TX =>
          fsm_CommunicationState <= st_WAIT;
        when st_WAIT =>
          null;
        when st_RX =>
          null;
        when others =>
          null;
      end case;
    end if;
  end process p_fsm_Communication;

  p_CommunicationWait : process (clk) is
    begin
      if rising_edge(clk) then
        -- if not if_Spi.busy
      end if;
    end process p_CommunicationWait;

  p_FunctionDecode : process(clk) is
  begin

    if rising_edge(clk) then
      if trigger then
        case functionAddress is
          when en_FUNCTION_NONE =>
            null;
          when en_FUNCTION_INIT =>
            sig_TxBuffer(0) <= c_data_SpiCommands(cmd_INIT_1);
            sig_TxBuffer(1) <= c_data_SpiCommands(cmd_SEL_B2);
            sig_TxBuffer(2) <= c_data_SpiCommands(cmd_B2_INIT_2);
            sig_TxBuffer(3) <= c_data_SpiCommands(cmd_B2_INIT_3);
            null;
          when en_FUNCTION_SET_TEST =>
            null;
          when en_FUNCTION_UNSET_TEST =>
            null;
          when en_FUNCTION_SET_VOLT_SCALE =>
            null;
          when others =>
            null;
        end case;

      end if;
    end if;

  end process p_FunctionDecode;

end architecture rtl;

-- <------------------------------------------------------------>
-- __        __         _                                   _ _
-- \ \      / /__  _ __| | __   ___  _ __    _ __ ___   ___| | |
--  \ \ /\ / / _ \| '__| |/ /  / _ \| '_ \  | '_ ` _ \ / _ \ | |
--   \ V  V / (_) | |  |   <  | (_) | | | | | | | | | |  __/_|_|
--    \_/\_/ \___/|_|  |_|\_\  \___/|_| |_| |_| |_| |_|\___(_|_)
--
-- <------------------------------------------------------------>
