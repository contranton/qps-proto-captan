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
-- 2025-07-30  1.0      javierc     Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package ads9813_pkg is

  subtype t_ADS9813_DATA_RATE is integer range 1 to 2;

  type t_enum_ADS9813_SPI_FUNCTIONS is (
    en_FUNCTION_NONE,
    en_FUNCTION_INIT,
    en_FUNCTION_ENABLE_TEST,
    en_FUNCTION_DISABLE_TEST,
    en_FUNCTION_SET_VOLT_SCALE,
    en_FUNCTION_SET_TEST_PATTERN
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

  subtype t_TEST_PATTERN is std_logic_vector(23 downto 0);
  constant c_INITIAL_TEST_PATTERN_CH1_4 : t_TEST_PATTERN := x"123456";
  constant c_INITIAL_TEST_PATTERN_CH5_8 : t_TEST_PATTERN := x"789ABC";

  type t_ADC_USER_CONFIG is record
    VoltageScale      : t_enum_ADS9813_VOLT_SCALES;
    TestPatternCh1To4 : t_TEST_PATTERN;
    TestPatternCh5To8 : t_TEST_PATTERN;
  end record t_ADC_USER_CONFIG;

  type t_rec_SPI_TX_WORD is record
    address : std_logic_vector(7 downto 0);
    data    : std_logic_vector(15 downto 0);
  end record;

  constant c_TX_BUFFER_MAX_SIZE : integer := 10;
  type t_arr_SPI_TX_BUFFER is array(natural range 0 to c_TX_BUFFER_MAX_SIZE) of t_rec_SPI_TX_WORD;
  subtype t_POINTER is integer range 0 to c_TX_BUFFER_MAX_SIZE - 1;


  type t_cmd_COMMANDS is (
    cmd_RESET,                          -- Resets ADC's register space
    cmd_RESET_CLEAR,                    -- Clears reset
    cmd_INIT_1,     -- Step 1 of 3 required to initialize ADC
    cmd_SEL_B1,                         -- Selects Register bank 1
    cmd_B1_VOLTSCALE_CH1_4,             -- Set voltage scale for channels 1-4
    cmd_B1_VOLTSCALE_CH5_8,             -- Set voltage scale for channels 5-8
    cmd_SEL_B2,                         -- Selects Register bank 2
    cmd_B2_INIT_2,  -- Step 2 of 3 required to initialize ADC
    cmd_B2_INIT_3,  -- Step 3 of 3 required to initialize ADC
    cmd_B1_TEST_PATTERN_ENABLE_CH1_4,   -- Enable test pattern for channels 1-4
    cmd_B1_TEST_PATTERN_ENABLE_CH5_8,   -- Enable test pattern for channels 5-8
    cmd_B1_TEST_PATTERN_DISABLE_CH1_4,  -- Disable test pattern for channels 1-4
    cmd_B1_TEST_PATTERN_DISABLE_CH5_8,  -- Disable test pattern for channels 5-8
    cmd_B1_TEST_PATTERN_SET_1OF4,  -- Write test pattern 1/4
    cmd_B1_TEST_PATTERN_SET_2OF4,  -- Write test pattern 2/4
    cmd_B1_TEST_PATTERN_SET_3OF4,  -- Write test pattern 3/4
    cmd_B1_TEST_PATTERN_SET_4OF4   -- Write test pattern 4/4
    );

  type t_data_SPI_COMMANDS is array(t_cmd_COMMANDS) of t_rec_SPI_TX_WORD;

  constant c_data_SpiCommands : t_data_SPI_COMMANDS := (
    cmd_RESET                            => (address => x"00", data => x"0001"),
    cmd_RESET_CLEAR                      => (address => x"00", data => x"0000"),
    cmd_INIT_1                           => (address => x"04", data => x"0002"),
    cmd_SEL_B1                           => (address => x"03", data => x"0002"),
    cmd_B1_VOLTSCALE_CH1_4               => (address => x"C2", data => x"FFFF"),
    cmd_B1_VOLTSCALE_CH5_8               => (address => x"C3", data => x"FFFF"),
    cmd_B1_TEST_PATTERN_ENABLE_CH1_4     => (address => x"13", data => x"000A"),
    cmd_B1_TEST_PATTERN_ENABLE_CH5_8     => (address => x"18", data => x"000A"),
    cmd_B1_TEST_PATTERN_DISABLE_CH1_4    => (address => x"13", data => x"0000"),
    cmd_B1_TEST_PATTERN_DISABLE_CH5_8    => (address => x"18", data => x"0000"),
    cmd_B1_TEST_PATTERN_SET_PATTERN_1OF4 => (address => x"14", data => x"FFFF"),
    cmd_B1_TEST_PATTERN_SET_PATTERN_2OF4 => (address => x"15", data => x"FFFF"),
    cmd_B1_TEST_PATTERN_SET_PATTERN_3OF4 => (address => x"19", data => x"FFFF"),
    cmd_B1_TEST_PATTERN_SET_PATTERN_4OF4 => (address => x"1A", data => x"FFFF"),
    cmd_SEL_B2                           => (address => x"03", data => x"0010"),
    cmd_B2_INIT_2                        => (address => x"92", data => x"0002"),
    cmd_B2_INIT_3                        => (address => x"C5", data => x"0604")
    );

end package ads9813_pkg;

package body ads9813_pkg is


end package body ads9813_pkg;
