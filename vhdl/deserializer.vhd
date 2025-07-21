-------------------------------------------------------------------------------
-- Title : ADS9813 Deserializer
-- Project :
-------------------------------------------------------------------------------
-- File : deserializer.vhd
-- Author : <javierc@correlator6.fnal.gov>
-- Company :
-- Created : 2025-07-09
-- Last update: 2025-07-09
-- Platform :
-- Standard : VHDL'08
-------------------------------------------------------------------------------
-- Description: Deserialize data from ADC
-------------------------------------------------------------------------------
-- Copyright (c) 2025
-------------------------------------------------------------------------------
-- Revisions :
-- Date Version Author Description
-- 2025-07-09 1.0 javierc Created
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.qps_pkg.all;

entity deserializer is

  port (
    DCLK  : in  std_logic;
    FCLK  : in  std_logic;
    DIN_A : in  std_logic;
    DIN_B : in  std_logic;
    DIN_C : in  std_logic;
    DIN_D : in  std_logic;
    DRDY  : out std_logic;
    DOUT  : out t_DESERIALIZER_OUTPUT);

end entity deserializer;


architecture rtl of deserializer is

  signal pos_DIN_A, neg_DIN_A   : std_logic;
  signal pos_DIN_B, neg_DIN_B   : std_logic;
  signal pos_DIN_C, neg_DIN_C   : std_logic;
  signal pos_DIN_D, neg_DIN_D   : std_logic;
  signal pos_FCLK, neg_FCLK     : std_logic;
  signal word_in_ab, word_in_cd : std_logic_vector(3 downto 0);

  subtype t_array is array(natural range <>) of std_logic_vector(3 downto 0);
  signal data_reg_ab, data_reg_cd : t_array(0 to 23);

  signal fclk_mask    : std_logic;  -- To capture FCLK rising edge independent of pos/neg
  signal fclk_reg     : std_logic_vector(1 downto 0);  -- To detect rising edge
  signal data_counter : unsigned(5 downto 0);  -- To properly sort channels

begin  -- architecture rtl

  iddr_fclk : IDDR
    port map(
      D  => FCLK,
      C  => DCLK,
      Q1 => pos_FCLK,
      Q2 => neg_FCLK,
      CE => '1',
      R  => '0',
      S  => '0'
      );

  iddr_a : IDDR
    port map(
      D  => DIN_A,
      C  => DCLK,
      Q1 => pos_DIN_A,
      Q2 => neg_DIN_A,
      CE => '1',
      R  => '0',
      S  => '0'
      );

  iddr_b : IDDR
    port map(
      D  => DIN_B,
      C  => DCLK,
      Q1 => pos_DIN_B,
      Q2 => neg_DIN_B,
      CE => '1',
      R  => '0',
      S  => '0'
      );

  iddr_c : IDDR
    port map(
      D  => DIN_C,
      C  => DCLK,
      Q1 => pos_DIN_C,
      Q2 => neg_DIN_C,
      CE => '1',
      R  => '0',
      S  => '0'
      );

  iddr_d : IDDR
    port map(
      D  => DIN_D,
      C  => DCLK,
      Q1 => pos_DIN_D,
      Q2 => neg_DIN_D,
      CE => '1',
      R  => '0',
      S  => '0'
      );

  p_shift_reg : process (DCLK) is
  begin
    if rising_edge(DCLK) then
      data_reg_ab(data_counter) <= word_in_ab;
      data_reg_cd(data_counter) <= word_in_cd;

      fclk_reg(1) <= fclk_reg(0);
      fclk_reg(0) <= fclk_mask;
    end if;
  end process p_shift_reg;

  p_counter : process(DCLK) is
  begin
    if rising_edge(DCLK) then
      if (fclk_reg = "01") then         -- Rising edge of fclk
        data_counter <= 0;
      else
        data_counter <= data_counter + 1;
      end if;
    end if;
  end process p_counter;


-- Combinational assignments
  word_in_ab(3) <= pos_DIN_B;
  word_in_ab(2) <= pos_DIN_A;
  word_in_ab(1) <= neg_DIN_B;
  word_in_ab(0) <= neg_DIN_A;

  word_in_cd(3) <= pos_DIN_D;
  word_in_cd(2) <= pos_DIN_C;
  word_in_cd(1) <= neg_DIN_D;
  word_in_cd(0) <= neg_DIN_C;

  fclk_mask <= pos_FCLK or neg_FCLK;

  DOUT.ch1 <= data_reg_ab(12) & data_reg_


end architecture rtl;
