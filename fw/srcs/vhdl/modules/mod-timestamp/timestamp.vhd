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
-- Title      : Timestamp generator
-- Project    :
-------------------------------------------------------------------------------
-- File       : timestamp.vhd
-- Author     : Javier Contreras 52425N
-- Division   : CSAID/RTPS/DIS
-- Created    : 2025-07-31
-- Last update: 2025-07-31
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Timestamp generator with freeze. The freeze signal locks the
-- timestamp_frozen out signal while the real timestamp keeps counting
-------------------------------------------------------------------------------
-- Copyright (c) 2025 Fermi Forward Discovery Group, LLC
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2025-07-31  1.0      javierc     Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timestamp_generator is
  generic(
    c_BITS_TIMESTAMP : integer := 30
    );
  port (
    clk              : in  std_logic;
    enable           : in  std_logic;
    reset            : in  std_logic;
    freeze           : in  std_logic;
    timestamp        : out std_logic_vector(c_BITS_TIMESTAMP-1 downto 0);
    timestamp_frozen : out std_logic_vector(c_BITS_TIMESTAMP-1 downto 0)
    );

end entity timestamp_generator;

architecture rtl of timestamp_generator is

  signal sig_Timestamp : std_logic_vector(c_BITS_TIMESTAMP-1 downto 0);

begin  -- architecture rtl

  -- <Generate timestamp and test data for ethernet>
  p_GenerateTimestamp : process(clk, reset) is
    variable counter : natural := 0;
  begin
    if rising_edge(clk) then
      if reset = '1' then
        counter          := 0;
        timestamp_frozen <= (others => '0');
      else
        if enable = '1' then
          counter       := counter + 1;
          sig_Timestamp <= std_logic_vector(to_unsigned(counter, c_BITS_TIMESTAMP));
          if freeze = '1' then
            timestamp_frozen <= sig_Timestamp;
          end if;
        end if;
      end if;
    end if;
  end process p_GenerateTimestamp;

  timestamp <= sig_Timestamp;

end architecture rtl;
