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
-- Title      : Utilities package
-- Project    :
-------------------------------------------------------------------------------
-- File       : utils_pkg.vhd
-- Author     : Javier Contreras 52425N
-- Division   : CSAID/RTPS/DIS
-- Created    : 2025-07-31
-- Last update: 2025-07-31
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Functions, type casts, etc
-------------------------------------------------------------------------------
-- Copyright (c) 2025 Fermi Forward Discovery Group, LLC
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2025-07-31  1.0      javierc	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.math_real.all;

package utils_pkg is

  function f_Clog2 (val : natural) return natural;

end package utils_pkg;

package body utils_pkg is

  function f_Clog2 (val : natural) return natural is
    begin
      return integer(ceil(log2(real(val))));
    end function;

end package body utils_pkg;
