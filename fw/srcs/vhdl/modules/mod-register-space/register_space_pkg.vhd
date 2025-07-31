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
-- Title      : Register space package
-- Project    :
-------------------------------------------------------------------------------
-- File       : register_space_pkg.vhd
-- Author     : Javier Contreras 52425N
-- Division   : CSAID/RTPS/DIS
-- Created    : 2025-07-31
-- Last update: 2025-07-31
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Generic package to handle custom register spaces with
-- configurable R/W modes.
--
-- To use this in your own system, create a new package that redefines
-- t_enum_CONFIG_REGISTERS and c_data_REGISTER_MODES
-------------------------------------------------------------------------------
-- Copyright (c) 2025 Fermi Forward Discovery Group, LLC
------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2025-07-31  1.0      javierc     Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.utils_pkg.f_Clog2;

package register_space_pkg is

  type t_enum_CONFIG_REGISTERS is (
    reg_VoltageScale,
    reg_Decimation,
    reg_PhaseShiftDegrees,
    reg_AutoalignEnable
    );

  -- <Configuration Register Space>
  constant c_BITS_CONFIG_REGISTER : natural := 32;
  subtype t_REGISTER is std_logic_vector(c_BITS_CONFIG_REGISTER-1 downto 0);
  type t_arr_REGISTER_SPACE is array (t_enum_CONFIG_REGISTERS) of t_REGISTER;

  type t_enum_REGISTER_MODE is (en_READ_ONLY, en_WRITE_ONLY, en_READ_WRITE);
  type t_data_REGISTER_MODES is array(t_enum_CONFIG_REGISTERS) of t_enum_REGISTER_MODE;

  constant c_NUM_CONFIG_REGISTERS : natural
    := t_enum_CONFIG_REGISTERS'pos(t_enum_CONFIG_REGISTERS'right) + 1;

  constant c_REGISTER_ADDRESS_MSB : natural := f_Clog2(c_NUM_CONFIG_REGISTERS);

  type t_CONFIG_REGISTER_INTERFACE is record
    -- TODO: Make sure a 'natural' works fine here
    ReadAddress : natural range 0 to c_NUM_CONFIG_REGISTERS-1;
    ReadData    : std_logic_vector(63 downto 0);
    WriteEnable : std_logic;
    WriteData   : std_logic_vector(63 downto 0);
    AddrError   : std_logic;
  end record t_CONFIG_REGISTER_INTERFACE;

  constant c_data_REGISTER_MODES : t_data_REGISTER_MODES := (
    reg_VoltageScale      => en_READ_WRITE,
    reg_Decimation        => en_READ_WRITE,
    reg_PhaseShiftDegrees => en_READ_ONLY,
    reg_AutoalignEnable   => en_READ_WRITE
    );


end package register_space_pkg;
