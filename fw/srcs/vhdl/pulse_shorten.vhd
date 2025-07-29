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
-- Title      : Pulse shortener
-- Project    :
-------------------------------------------------------------------------------
-- File       : pulse_shorten.vhd
-- Author     :   <javierc@correlator6.fnal.gov>
-- Division   : CSAID/RTPS/DIS
-- Created    : 2025-07-08
-- Last update: 2025-07-29
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Converts a long input pulse to single-clock length
-------------------------------------------------------------------------------
-- Copyright (c) 2025 Fermi Forward Discovery Group, LLC
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2025-07-08  1.0      javierc	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity pulse_shorten is

  port (
    clk      : in  std_logic;
    src_in   : in  std_logic;
    dest_out : out std_logic);

end entity pulse_shorten;

architecture rtl of pulse_shorten is
  signal reg1 : std_logic := '0';
begin  -- architecture rtl

p1: process (clk)  is
begin  -- process p1
  if rising_edge(clk) then
    reg1 <= src_in;
  end if;
end process p1;

dest_out <= src_in and not reg1;

end architecture rtl;
