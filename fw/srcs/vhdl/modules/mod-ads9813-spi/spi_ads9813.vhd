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
-- Author     : Javier Contreras 52425N
-- Division   : CSAID/RTPS/DIS
-- Created    : 2025-07-29
-- Last update: 2025-08-05
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Generates SPI transactions for ADC configuration. TX Only
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
use work.qps_pkg.all;

entity SpiController_ADS9813 is

  port (
    clk              : in    std_logic;
    if_Ads9813       : inout t_Ads9813;
    if_AdcUserConfig : in    t_ADC_USER_CONFIG;
    if_Spi           : inout t_SPI_MGT);

end entity SpiController_ADS9813;

architecture rtl of SpiController_ADS9813 is

  signal FunctionAddress : t_enum_ADS9813_SPI_FUNCTIONS;
  signal triggerTx, triggerRx : std_logic;
  signal read_data : std_logic_vector(23 downto 0);

  -- <State Machine>
  type t_fsm_CommunicationState is (st_IDLE, st_TX, st_RX);
  signal fsm_CommunicationState : t_fsm_CommunicationState;
  signal sig_TxDone             : std_logic := '0';
  -- </.>

  -- <Transmission FIFO>
  signal sig_TxBuffer  : t_arr_SPI_TX_BUFFER;
  signal sig_TxPointer : t_POINTER;
  -- </.>

  procedure proc_BufferTx(
    signal arg_Buffer  : in    t_arr_SPI_TX_BUFFER;
    signal arg_Pointer : inout t_POINTER;
    signal arg_Done    : out   std_logic;
    signal arg_Spi     : inout t_SPI_MGT
    ) is
  begin
    arg_Spi.tx_trn <= '0';              -- Default

    if arg_Pointer > 0 and arg_Spi.busy = '0' then
      arg_Spi.addr    <= arg_Buffer(arg_Pointer).address;
      arg_Spi.wr_data <= arg_Buffer(arg_Pointer).data;
      arg_Spi.tx_trn  <= '1';
      arg_Pointer     <= arg_Pointer - 1;
    end if;

    if arg_Pointer = 0 and arg_Spi.busy = '0' then
      arg_Done <= '1';
    end if;

  end procedure proc_BufferTx;

  procedure proc_BufferPush(
    signal arg_Buffer  : inout t_arr_SPI_TX_BUFFER;
    signal arg_Pointer : inout t_POINTER;
    constant arg_Data  : in    t_rec_SPI_TX_WORD
    ) is
  begin
    arg_Pointer             <= arg_Pointer + 1;
    arg_Buffer(arg_Pointer) <= arg_Data;
  end procedure proc_BufferPush;

  procedure proc_BufferReset(
    signal arg_Buffer  : inout t_arr_SPI_TX_BUFFER;
    signal arg_Pointer : out   t_POINTER
    ) is
  begin
    for idx in 0 to arg_Buffer'length - 1 loop
      arg_Buffer(idx) <= (address => x"00", data => x"0000");
    end loop;
    arg_Pointer <= 0;
  end procedure proc_BufferReset;

begin  -- architecture rtl

  triggerRx <= if_Ads9813.triggerRx;
  triggerTx <= if_Ads9813.triggerTx;
  FunctionAddress <= if_Ads9813.FunctionAddress;

  p_fsm_Communication : process(clk) is
  begin
    if rising_edge(clk) then
      case fsm_CommunicationState is
        when st_IDLE =>
          if triggerTx = '1' then
            fsm_CommunicationState <= st_TX;
          end if;
        when st_TX =>
          proc_BufferTx(sig_TxBuffer, sig_TxPointer, sig_TxDone, if_Spi);
          if sig_TxDone = '1' then
            fsm_CommunicationState <= st_IDLE;
            proc_BufferReset(sig_TxBuffer, sig_TxPointer);
          end if;
        when st_RX =>
          -- Not implemented
          null;
        when others =>
          null;
      end case;
    end if;
  end process p_fsm_Communication;

  p_FunctionDecode : process(clk) is

    -- Name shortening aliases
    alias ptr  is sig_TxPointer;
    alias buf  is sig_TxBuffer;
    alias spi  is c_data_SpiCommands;

    variable v_Cmd : t_rec_SPI_TX_WORD;

  begin

    if rising_edge(clk) then
      if triggerTx = '1' and fsm_CommunicationState = st_IDLE then
        case functionAddress is
          when en_FUNCTION_NONE =>
            null;
          when en_FUNCTION_INIT =>
            proc_BufferPush(buf, ptr, spi(cmd_INIT_1));
            proc_BufferPush(buf, ptr, spi(cmd_SEL_B2));
            proc_BufferPush(buf, ptr, spi(cmd_B2_INIT_2));
            proc_BufferPush(buf, ptr, spi(cmd_B2_INIT_3));
          when en_FUNCTION_ENABLE_TEST =>
            proc_BufferPush(buf, ptr, spi(cmd_SEL_B1));
            proc_BufferPush(buf, ptr, spi(cmd_B1_TEST_PATTERN_ENABLE_CH1_4));
            proc_BufferPush(buf, ptr, spi(cmd_B1_TEST_PATTERN_ENABLE_CH5_8));
            proc_BufferPush(buf, ptr, spi(cmd_B1_TEST_PATTERN_SET_1OF4));
            proc_BufferPush(buf, ptr, spi(cmd_B1_TEST_PATTERN_SET_2OF4));
            proc_BufferPush(buf, ptr, spi(cmd_B1_TEST_PATTERN_SET_3OF4));
            proc_BufferPush(buf, ptr, spi(cmd_B1_TEST_PATTERN_SET_4OF4));
          when en_FUNCTION_DISABLE_TEST =>
            proc_BufferPush(buf, ptr, spi(cmd_B1_TEST_PATTERN_DISABLE_CH1_4));
            proc_BufferPush(buf, ptr, spi(cmd_B1_TEST_PATTERN_DISABLE_CH5_8));
          when en_FUNCTION_SET_VOLT_SCALE =>
            v_Cmd := spi(cmd_B1_VOLTSCALE_CH1_4);

            -- Set proper config for desired voltage scale
            with if_AdcUserConfig.VoltageScale select
                v_Cmd.data := x"0000" when en_VOLTSCALE_5V0,
                              x"1111" when en_VOLTSCALE_3V5,
                              x"2222" when en_VOLTSCALE_2V5,
                              x"3333" when en_VOLTSCALE_7V0,
                              x"4444" when en_VOLTSCALE_10V0,
                              x"5555" when en_VOLTSCALE_12V0,
                               (others => 'X') when others;
            proc_BufferPush(buf, ptr, v_Cmd);

            -- Repeat for channels 5-8
            v_Cmd.address := spi(cmd_B1_VOLTSCALE_CH5_8).address;
            proc_BufferPush(buf, ptr, v_Cmd);
            null;
          when en_FUNCTION_SET_TEST_PATTERN =>
            v_Cmd := spi(cmd_B1_TEST_PATTERN_SET_1OF4);
            v_Cmd.data := if_AdcUserConfig.TestPatternCh1To4(15 downto 0);
            proc_BufferPush(buf, ptr, v_Cmd);

            v_Cmd := spi(cmd_B1_TEST_PATTERN_SET_2OF4);
            v_Cmd.data := x"00" & if_AdcUserConfig.TestPatternCh1To4(23 downto 16);
            proc_BufferPush(buf, ptr, v_Cmd);

            v_Cmd := spi(cmd_B1_TEST_PATTERN_SET_3OF4);
            v_Cmd.data := if_AdcUserConfig.TestPatternCh5To8(15 downto 0);
            proc_BufferPush(buf, ptr, v_Cmd);

            v_Cmd := spi(cmd_B1_TEST_PATTERN_SET_4OF4);
            v_Cmd.data := x"00" & if_AdcUserConfig.TestPatternCh5To8(23 downto 16);
            proc_BufferPush(buf, ptr, v_Cmd);
          when others =>
            null;
        end case;

      end if;
    end if;

  end process p_FunctionDecode;

end architecture rtl;
