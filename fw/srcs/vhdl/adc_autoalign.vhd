-------------------------------------------------------------------------------
-- Title : ADC Autoalign
-- Project : QPS (Quench Prediction System) Prototype for APS-TD
-------------------------------------------------------------------------------
-- File : adc_autoalign.vhd
-- Author : Javier Contreras 52425N
-- Division : CSAID/RTPS/DIS
-- Created : 2025-07-11
-- Last update: 2025-07-14
-- Platform :
-- Standard : VHDL'08
-------------------------------------------------------------------------------
-- Description: Shifts data_clk until test pattern reads correctly. This routine
-- shifts the data_clock using clocking wizard's phase shift interface. It
-- stores the number of delays until first alignment (edge=FIRST), and continues
-- delaying until it's disaligned once again (edge=SECOND). Finally, it sets a
-- value in the middle of the two "edges" to guarantee stability.
-------------------------------------------------------------------------------
-- Copyright (c) 2025 FermiForward Discovery Group, LLC
-------------------------------------------------------------------------------
-- Revisions :
-- Date Version Author Description
-- 2025-07-11 1.0 javierc Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adc_autoalign is

  generic (
    c_TEST_PATTERN : std_logic_vector(191 downto 0) := x"123456123456123456123456789ABC789ABC789ABC789ABC"
    );
  port (
    clk                         : in  std_logic;
    reset                       : in  std_logic;
    deserializer_raw_data       : in  std_logic_vector(191 downto 0);
    deserializer_raw_data_valid : in  std_logic;
    trigger                     : in  std_logic;
    n_delays                    : out signed(15 downto 0);
    autoalign_done              : out std_logic;
    phase_shift_button_forward  : out std_logic;
    phase_shift_button_backward : out std_logic;
    phase_shift_done            : in  std_logic);

end entity adc_autoalign;

architecture rtl of adc_autoalign is

  -- TODO: Manage spi command for test data
  -- TODO: Resets
  -- TODO: autoalign_success (needs a fail condition -- timeout?)

  type t_state is (IDLE, READ_DATA, MATCH_PATTERN, SHIFT_CLOCK, WAIT_SHIFT_DONE, ALGO_DONE);
  type t_direction is (BACKWARD, FORWARD);
  type t_edge_state is (NONE, FIRST, SECOND, EDGE_DONE);
  type t_startup_case is (STARTUP_UNMATCHED, STARTUP_MATCHED);

  signal state, state_next               : t_state        := IDLE;
  signal direction, direction_next       : t_direction    := BACKWARD;
  signal edge, edge_next                 : t_edge_state   := NONE;
  signal startup_case, startup_case_next : t_startup_case := STARTUP_UNMATCHED;

  -- Current number of delay steps
  signal n_delays_current, n_delays_current_next : signed(15 downto 0) := to_signed(0, 16);

  -- Counters that store how many delays until rising/falling edge of stable regime
  signal n_delays_until_first_edge      : signed(15 downto 0) := to_signed(0, 16);
  signal n_delays_until_first_edge_next : signed(15 downto 0) := to_signed(0, 16);
  signal n_delays_center                : signed(15 downto 0) := to_signed(0, 16);
  signal n_delays_center_next           : signed(15 downto 0) := to_signed(0, 16);

begin  -- architecture rtl

  p_regs : process(clk) is
  ------------------------------
  -- Synchronous process for register write and resets
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state                     <= IDLE;
        direction                 <= BACKWARD;
        edge                      <= NONE;
        startup_case              <= STARTUP_UNMATCHED;
        n_delays_current          <= to_signed(0, 16);
        n_delays_until_first_edge <= to_signed(0, 16);
        n_delays_center           <= to_signed(0, 16);
      else
        state        <= state_next;
        direction    <= direction_next;
        edge         <= edge_next;
        startup_case <= startup_case_next;
      end if;
    end if;
  end process p_regs;
  ------------------------------

  p_fsm : process(all) is
  ------------------------------
  -- Handles matching the test pattern and updating the found edge and direction
  --
  -- There's two possible startup cases: STARTUP_MATCHED and STARTUP_UNMATCHED.
  -- The easiest of these is STARTUP_UNMATCHED: the test pattern doesn't match
  -- on startup, and all we do is shift backwards to find both edges. Then, we
  -- change direction once to find the midpoint. And even if we start up in the
  -- "left side" of the valid window, we'll eventually wrap around and reach
  -- the right.
  --
  -- However, with STARTUP_MATCHED we could potentially be close to the edge of
  -- the window and be prone to instability, so we ignore all matches until we
  -- first find a falling edge. Then, we proceed as with START_UNMATCHED but
  -- with directions reversed.
  --
  -- = = = = = = = = = = = = = = = = = = = =
  -- START_UNMATCHED:
  --    (match)            ___________   <-- Shift direction
  --                      |           |
  -- (no_match) __________|           |___|_______
  --                     /           /   /
  --                SECOND       FIRST   |
  --                                     |
  --                                     | Starting delay
  --
  -- = = = = = = = = = = = = = = = = = = = =
  -- START_MATCHED:
  --                            <-- Initial shift direction
  --    (match)            ___|_______
  --                      |   |       |
  -- (no_match) __________|  /        |__________
  --                     /  |        /
  --                 FIRST  |      SECOND
  --                        |
  --                        | Starting delay
  --
  --                      --> Second shift direction
  --    (match)            ___|_______
  --                      |   |       |
  -- (no_match) __________|  /        |__________
  --                     /  |        /
  --                 FIRST  |      SECOND
  --                        |
  --                        | Starting delay
  --
  begin

    -- Defaults for combinational outputs
    autoalign_done              <= '0';
    phase_shift_button_forward  <= '0';
    phase_shift_button_backward <= '0';

    if state = SHIFT_CLOCK then
      if direction = BACKWARD then
        n_delays_current_next <= n_delays_current + 1;
        phase_shift_button_backward <= '1';
        state_next <= WAIT_SHIFT_DONE;
      else
        n_delays_current_next <= n_delays_current - 1;
        phase_shift_button_forward <= '1';
        state_next <= WAIT_SHIFT_DONE;
      end if;
    end if; -- SHIFT_CLOCK

    if state = WAIT_SHIFT_DONE then
      if phase_shift_done = '1' then
        state_next <= READ_DATA;
      end if;
    end if; -- WAIT_SHIFT_DONE

    if state = READ_DATA and deserializer_raw_data_valid = '1' then
      state_next <= SHIFT_CLOCK;

      if deserializer_raw_data = c_TEST_PATTERN then  -- match found

        -- Detect startup case
        if EDGE = NONE and n_delays_current = 0 then
          startup_case_next <= STARTUP_MATCHED;
        end if;

        if edge = NONE and startup_case = STARTUP_UNMATCHED then
          edge_next <= FIRST;
          direction_next <= BACKWARD;
          n_delays_until_first_edge_next <= n_delays_current;
        end if;
        if edge = NONE and startup_case = STARTUP_MATCHED then
          edge_next <= NONE;
          direction_next <= BACKWARD;
        end if;
        if edge = FIRST and startup_case = STARTUP_UNMATCHED then
          edge_next <= FIRST;
          direction_next <= BACKWARD;
        end if;
        if edge = FIRST and startup_case = STARTUP_MATCHED then
          edge_next <= FIRST;
          direction_next <= FORWARD;
        end if;
        if edge = SECOND and n_delays_current = n_delays_center then
          edge_next <= EDGE_DONE;
          state_next <= ALGO_DONE;
        end if;

      else                              -- no match found

        if edge = NONE and startup_case = STARTUP_UNMATCHED then
          edge_next <= NONE;
          direction_next <= BACKWARD;
        end if;
        if edge = NONE and startup_case = STARTUP_MATCHED then
          edge_next <= FIRST;
          direction_next <= FORWARD;
          n_delays_until_first_edge_next <= n_delays_current;
        end if;
        if edge = FIRST and startup_case = STARTUP_MATCHED then
          edge_next <= SECOND;
          direction_next <= BACKWARD;
          n_delays_center_next <= (n_delays_current - n_delays_until_first_edge) / 2;
        end if;
        if edge = FIRST and startup_case = STARTUP_UNMATCHED then
          edge_next <= SECOND;
          direction_next <= FORWARD;
          n_delays_center_next <= (n_delays_current - n_delays_until_first_edge) / 2;
        end if;
      end if;
    end if; -- READ_DATA

    if state = ALGO_DONE then
      autoalign_done <= '1';
      state_next <= IDLE;
    end if; -- ALGO_DONE

    if state = IDLE then
      if trigger = '1' then
        state_next <= READ_DATA;
      end if;
    end if; -- IDLE

  end process p_fsm;
------------------------------

end architecture rtl;
