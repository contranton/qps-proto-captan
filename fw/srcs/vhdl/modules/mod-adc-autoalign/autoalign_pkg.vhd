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
-- Title      : Autoalign package
-- Project    : QPS (Quench Prediction System) Prototype for APS-TD
-------------------------------------------------------------------------------
-- File       : autoalign_pkg.vhd
-- Author     :   <javierc@correlator6.fnal.gov>
-- Division   : CSAID/RTPS/DIS
-- Created    : 2025-07-29
-- Last update: 2025-08-05
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Type definitions for autoalign module
-------------------------------------------------------------------------------
-- Copyright (c) 2025 Fermi Forward Discovery Group, LLC
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2025-07-29  1.0      javierc	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package autoalign_pkg is

  type t_autoalign_status is (st_STANDBY, st_RUNNING, st_DONE, st_ERROR);
  type t_autoalign_error is (e_NOERR, e_NOMATCH, e_OTHER);

  type t_AutoalignCtrl is record
    trigger : std_logic;
    done    : std_logic;
    status  : t_autoalign_status;
    error   : t_autoalign_error;
  end record t_AutoalignCtrl;

end package autoalign_pkg;
