-------------------------------------------------------------------------------
-- Title : Phase Shift interface control
-- Project :
-------------------------------------------------------------------------------
-- File : phase_shift_if.vhd
-- Author : <javierc@correlator6.fnal.gov>
-- Company :
-- Created : 2025-07-02
-- Last update: 2025-07-02
-- Platform :
-- Standard : VHDL'08
-------------------------------------------------------------------------------
-- Description: Push-button interface for clocking wizard. A pulse (rising edge
-- until falling edge) generates at most one phase shift increment.
-------------------------------------------------------------------------------
-- Copyright (c) 2025
-------------------------------------------------------------------------------
-- Revisions :
-- Date Version Author Description
-- 2025-07-02 1.0 javierc Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity phase_shift_ctrl is
  port (
    clk             : in  std_logic;
    forward_button  : in  std_logic;
    backward_button : in  std_logic;
    enable          : out std_logic;
    incdec          : out std_logic;
    done            : in  std_logic
    );

end entity phase_shift_ctrl;

architecture rtl of phase_shift_ctrl is


  type t_state is (PRESSED, RELEASED, SHIFT_DONE);
  signal state : t_state := RELEASED;

  signal button : std_logic;

begin  -- architecture rtl

  button <= forward_button or backward_button;

  p1 : process (clk) is
  begin
    if rising_edge(clk) then
      if (state = RELEASED) then
        enable <= '0';
        if (button = '1') then
          state  <= PRESSED;
          enable <= '1';
        end if;
      end if;
      if (state = PRESSED) then
        enable <= '0';
        if (done = '1') then
          state <= SHIFT_DONE;
        end if;
      end if;
      if (state = SHIFT_DONE) then
        if (button = '0') then
          state <= RELEASED;
        end if;
      end if;
    end if;
  end process p1;

  incdec <= '1' when forward_button = '1' else '0';

end architecture rtl;
