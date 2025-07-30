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
-- Title      : Package for ADS9813 interaction
-- Project    :
-------------------------------------------------------------------------------
-- File       : ads9813_pkg.vhd
-- Author     :   <javierc@correlator6.fnal.gov>
-- Division   : CSAID/RTPS/DIS
-- Created    : 2025-07-30
-- Last update: <date   >
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Commaands and state management for SPI interface
-------------------------------------------------------------------------------
-- Copyright (c) 2025 Fermi Forward Discovery Group, LLC
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2025-07-30  1.0      javierc	Created
-------------------------------------------------------------------------------

package ads9813_pkg is

  subtype t_ADS9813_DATA_RATE is integer range 1 to 2;

  type t_enum_ADS9813_SPI_FUNCTIONS is (
    en_FUNCTION_NONE,
    en_FUNCTION_INIT,
    en_FUNCTION_SET_TEST,
    en_FUNCTION_UNSET_TEST,
    en_FUNCTION_SET_VOLT_SCALE
    );

  type t_enum_ADS9813_VOLT_SCALES is (
    en_VOLTSCALE_5V0,
    en_VOLTSCALE_3V5,
    en_VOLTSCALE_2V5,
    en_VOLTSCALE_7V0,
    en_VOLTSCALE_9V0,
    en_VOLTSCALE_10V0,
    en_VOLTSCALE_12V0
    );


  type t_arr_SPI_TX_BUFFER is array(positive range<>) of t_rec_SPI_TX_WORD;

  type t_rec_SPI_TX_WORD is record
    address : std_logic_vector(7 downto 0);
    data    : std_logic_vector(15 downto 0);
  end record;

  type t_cmd_COMMANDS is (
    cmd_RESET,
    cmd_RESET_CLEAR,
    cmd_INIT_1,
    cmd_SEL_B1,
    cmd_B1_VOLTSCALE_CH1_4,
    cmd_B1_VOLTSCALE_CH5_8,
    cmd_SEL_B2,
    cmd_B2_INIT_2,
    cmd_B2_INIT_3,
    cmd_B1_TEST_PATTERN_ENABLE_CH1_4,
    cmd_B1_TEST_PATTERN_ENABLE_CH5_8,
    cmd_B1_TEST_PATTERN_SET_PATTERN_1OF4,
    cmd_B1_TEST_PATTERN_SET_PATTERN_2OF4,
    cmd_B1_TEST_PATTERN_SET_PATTERN_3OF4,
    cmd_B1_TEST_PATTERN_SET_PATTERN_4OF4
    );

  type t_data_SPI_COMMANDS is array(t_cmd_COMMANDS) of t_rec_SPI_TX_WORD;

  constant c_data_SpiCommands : t_data_SPI_COMMANDS := (
    cmd_RESET                            => (address => x"00", data => x"0001"),
    cmd_RESET_CLEAR                      => (address => x"00", data => x"0000"),
    cmd_INIT_1                           => (address => x"04", data => x"0002"),
    cmd_SEL_B1                           => (address => x"03", data => x"0002"),
    cmd_B1_VOLTSCALE_CH1_4               => (address => x"XX", data => x"XXXX"),
    cmd_B1_VOLTSCALE_CH5_8               => (address => x"XX", data => x"XXXX"),
    cmd_B1_TEST_PATTERN_ENABLE_CH1_4     => (address => x"XX", data => x"XXXX"),
    cmd_B1_TEST_PATTERN_ENABLE_CH5_8     => (address => x"XX", data => x"XXXX"),
    cmd_B1_TEST_PATTERN_SET_PATTERN_1OF4 => (address => x"XX", data => x"XXXX"),
    cmd_B1_TEST_PATTERN_SET_PATTERN_2OF4 => (address => x"XX", data => x"XXXX"),
    cmd_B1_TEST_PATTERN_SET_PATTERN_3OF4 => (address => x"XX", data => x"XXXX"),
    cmd_B1_TEST_PATTERN_SET_PATTERN_4OF4 => (address => x"XX", data => x"XXXX"),
    cmd_SEL_B2                           => (address => x"03", data => x"0010"),
    cmd_B2_INIT_2                        => (address => x"92", data => x"0002"),
    cmd_B2_INIT_3                        => (address => x"C5", data => x"0604")
    );

end package ads9813_pkg;

package body ads9813_pkg is


end package body ads9813_pkg;
