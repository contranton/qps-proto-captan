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
-- Title      : Autoalign controler
-- Project    : QPS (Quench Prediction System) Prototype for APS-TD
-------------------------------------------------------------------------------
-- File       : autoalign_ctrl.vhd
-- Author     :   <javierc@correlator6.fnal.gov>
-- Division   : CSAID/RTPS/DIS
-- Created    : 2025-07-28
-- Last update: 2025-07-29
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Manages high-level states for adc_autoalign and integrates with
-- GPIO and SPI functionality
-------------------------------------------------------------------------------
-- Copyright (c) 2025 Fermi Forward Discovery Group, LLC
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2025-07-28  1.0      javierc   Created
-------------------------------------------------------------------------------

use work.autoalign_pkg.all;

entity autoalign_ctrl is

  port (
    clk                : in  std_logic;
    reset              : in  std_logic;
    start              : in  std_logic;
    autoalign_trigger  : out std_logic;
    autoalign_done     : in  std_logic;
    autoalign_error    : in  std_logic;
    gpio_set_test_data : out std_logic;
    error_out          : out std_logic
    );
end entity autoalign_ctrl;

architecture rtl of autoalign_ctrl is


  signal status : t_autoalign_status := st_STANDBY;

begin  -- architecture rtl

  -- purpose: Handle status of autoalign core
  -- type   : sequential
  -- inputs : clk, reset
  -- outputs:
  p_Run : process (clk) is
  begin  -- process p_Run
    if rising_edge(clk) then            -- rising clock edge
      if reset = '0' then               -- synchronous reset (active low)
        status <= st_STANDBY;
      else
        case status is
          when st_STANDBY =>
            if start then
              status             <= st_RUNNING;
              autoalign_trigger  <= '1';
              gpio_set_test_data <= '1';
            end if;
          when st_RUNNING =>
            if autoalign_done then
              status             <= st_DONE;
              gpio_set_test_data <= '0';
              gpio_set_test_data <= '0';
            end if;
            if autoalign_error then
              status <= st_ERROR;
            end if;
          when st_DONE =>
            if start then
              status            <= st_RUNNING;
              autoalign_trigger <= '1';
            end if;
          when st_ERROR =>
            error_out <= '1';
          when others => null;
        end case;
      end if;
    end if;
  end process p_Run;

end architecture rtl;
