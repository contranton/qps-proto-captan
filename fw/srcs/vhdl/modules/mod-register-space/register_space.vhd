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
-- Title      : Register space
-- Project    :
-------------------------------------------------------------------------------
-- File       : register_space.vhd
-- Author     : Javier Contreras 52425N
-- Division   : CSAID/RTPS/DIS
-- Created    : 2025-07-31
-- Last update: 2025-07-31
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Register space for ethernet interface interactions
-------------------------------------------------------------------------------
-- Copyright (c) 2025 Fermi Forward Discovery Group, LLC
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2025-07-31  1.0      javierc   Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.register_space_pkg.all;

entity register_space is
  port (
    clk         : in    std_logic;
    if_RegSpace : inout t_CONFIG_REGISTER_INTERFACE
    );
end entity register_space;

architecture rtl of register_space is

  signal sig_RegisterSpace : t_arr_REGISTER_SPACE :=
    (
      reg_VoltageScale      => x"00000001",
      reg_Decimation        => x"00000000",
      reg_PhaseShiftDegrees => x"00000000",
      reg_AutoalignEnable   => x"00000000"
      );

begin  -- architecture rtl

  p_Decode : process (clk) is
    variable v_Address : natural;
    variable v_Reg     : t_enum_CONFIG_REGISTERS;
    variable v_RegMode : t_enum_REGISTER_MODE;

    variable v_ReadData : t_REGISTER := (others => '0');
  begin
    if rising_edge(clk) then
      v_Address := if_RegSpace.ReadAddress;

      -- Handle invalid addresses
      if v_Address >= c_NUM_CONFIG_REGISTERS then
        if_RegSpace.ReadData  <= (others => '0');
        if_RegSpace.AddrError <= '1';
      else
        -- Dereference register from enum
        v_Reg     := t_enum_CONFIG_REGISTERS'val(v_Address);
        v_RegMode := c_data_REGISTER_MODES(v_Reg);

        if if_RegSpace.WriteEnable = '0' then
          -- Read data
          with v_RegMode select
            v_ReadData := sig_RegisterSpace(v_Reg) when en_READ_ONLY,
                           sig_RegisterSpace(v_Reg) when en_READ_WRITE,
                           (others => '0')          when others;
        else
          -- Write Data
          if v_RegMode = en_READ_WRITE or v_RegMode = en_WRITE_ONLY then
            sig_RegisterSpace(v_Reg) <= if_RegSpace.WriteData;
          end if;
        end if;  -- write enable?
      end if;  -- valid address?

      -- Write read data back to interface
      -- TODO: Get the 63 from somewhere else
      if_RegSpace.ReadData(63 downto c_BITS_CONFIG_REGISTER) <= (others => '0');
      if_RegSpace.ReadData(c_BITS_CONFIG_REGISTER-1 downto 0) <= v_ReadData;

    end if;  -- rising_edge(clk)
  end process p_Decode;


end architecture rtl;
