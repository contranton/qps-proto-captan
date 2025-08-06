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
-- Last update: 2025-08-06
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Type definitions for autoalign module
-------------------------------------------------------------------------------
-- Copyright (c) 2025 Fermi Forward Discovery Group, LLC
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2025-07-29  1.0      javierc   Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package autoalign_pkg is

  type t_autoalign_status is (st_STANDBY, st_RUNNING, st_DONE, st_ERROR);
  type t_autoalign_error is (e_NOERR, e_NOMATCH, e_OTHER);

  type t_AUTOALIGN_CTRL_IF is record
    trigger  : std_logic;
    --n_delays : signed(15 downto 0);
    n_delays : integer;
    start    : std_logic;
    done     : std_logic;
    error    : t_autoalign_error;
  end record t_AUTOALIGN_CTRL_IF;

  type t_PHASE_SHIFT_IF is record
    enable : std_logic;
    incdec : std_logic;
    done   : std_logic;
  end record t_PHASE_SHIFT_IF;

  type t_PHASE_SHIFT_CTRL_IF is record
    button_forward  : std_logic;
    button_backward : std_logic;
    done : std_logic;
  end record t_PHASE_SHIFT_CTRL_IF;

  procedure proc_PhaseShiftCtrl_Merge(
    signal master_1 : inout t_PHASE_SHIFT_CTRL_IF;
    signal master_2 : inout t_PHASE_SHIFT_CTRL_IF;
    signal slave : inout t_PHASE_SHIFT_CTRL_IF);

end package autoalign_pkg;

package body autoalign_pkg is

  procedure proc_PhaseShiftCtrl_Merge(
    signal master_1 : inout t_PHASE_SHIFT_CTRL_IF;
    signal master_2 : inout t_PHASE_SHIFT_CTRL_IF;
    signal slave : inout t_PHASE_SHIFT_CTRL_IF)
  is
  begin

    slave.button_forward <= master_1.button_forward or
                            master_2.button_forward;
    slave.button_backward <= master_1.button_backward or
                            master_2.button_backward;

    master_1.done <= slave.done;
    master_2.done <= slave.done;

  end procedure proc_PhaseShiftCtrl_Merge;



end package body autoalign_pkg;
