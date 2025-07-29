-------------------------------------------------------------------------------
-- Title : Main module
-- Project :
-------------------------------------------------------------------------------
-- File : main.vhd
-- Author : <javierc@correlator6.fnal.gov>
-- Company :
-- Created : 2025-05-22
-- Last update: 2025-07-29
-- Platform :
-- Standard : VHDL'08
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2025
-------------------------------------------------------------------------------
-- Revisions :
-- Date Version Author Description
-- 2025-05-22 1.0 javierc Created
-------------------------------------------------------------------------------

use work.qps_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.Vcomponents.all;

library xpm;
use xpm.vcomponents.all;

entity main is
  generic (
    constant c_NUM_ADC_CHANNELS : natural := 8;
    constant c_DEBUG_ENABLE : std_logic := '1'
    );
  port (
    adc_frame_clk : in    std_logic;
    adc_data_clk  : in    std_logic;
    adc_spi_ctrl  : inout t_ADC_CTRL;
    adc_data      : in    t_ADC_RAW_DATA(3 downto 0);

    adc_pwdn_n  : out std_logic;
    adc_reset_n : out std_logic;

    adc_sample_clk : out std_logic;

    USER_CLK1 : in  std_logic;
    user_led  : out std_logic;

    -- Ryan's GEL
    phy_rx    : in  t_GEL_PHY_RX;
    phy_tx    : out t_GEL_PHY_TX;
    PHY_RESET : out std_logic

    );
end entity main;

architecture rtl of main is

  type t_phase_shift_if is record
    enable : std_logic;
    clk    : std_logic;
    incdec : std_logic;
    done   : std_logic;
  end record t_phase_shift_if;

  signal phase_shift_if : t_phase_shift_if;
  signal phase_shift_if_done_sync : std_logic;

  signal clk      : std_logic;
  signal reset    : std_logic := '0';
  signal resetn    : std_logic := '1';
  signal mb_reset : std_logic := '0';

  signal reset_sync_adc    : std_logic := '0';

  signal phy_tx_dbg : t_GEL_PHY_TX;

  signal phy_reset_sig      : std_logic := '1';
  signal phy_reset_sig_sync : std_logic := '1';
  signal phy_resetn_sig     : std_logic := '1';

  -- Ethernet Interface
  signal reset_in   : std_logic;
  signal reset_out  : std_logic;
  signal rx_addr    : std_logic_vector (31 downto 0);
  signal rx_data    : std_logic_vector (63 downto 0);
  signal rx_wren    : std_logic;
  signal tx_data    : std_logic_vector (63 downto 0);
  signal b_data     : std_logic_vector (63 downto 0);
  signal b_data_we  : std_logic;
  signal b_enable   : std_logic;
  signal MASTER_CLK : std_logic;
  signal FAST_CLK   : std_logic;
  signal PHY_CLK   : std_logic;

  signal adc_sample_clk_4mhz       : std_logic := '0';
  signal adc_sample_clk_16mhz_prebuf    : std_logic := '0';
  signal adc_sample_clk_8mhz    : std_logic := '0';
  signal adc_sample_clk_16mhz : std_logic := '0';
  signal phy_txclk_prebuf         : std_logic := '0';

  constant c_MSB : natural := c_ADC_BITS*c_NUM_ADC_CHANNELS;

  signal m_axis_adc_tvalid : std_logic;
  signal m_axis_adc_tdata  : std_logic_vector(c_MSB-1 downto 0);

  -- Data clock shifted to align with data lanes
  signal adc_data_clk_shift : std_logic;

  -- Synchronized data/frame clocks for ILA
  signal adc_data_clk_sync, adc_frame_clk_sync           : std_logic := '0';
  signal adc_data_clk_fast_sync, adc_frame_clk_fast_sync : std_logic := '0';

  signal adc_data_fast_sync : std_logic_vector(3 downto 0);

  signal fast_sync_bus_in, fast_sync_bus_out : std_logic_vector(5 downto 0);

  signal adc_output_streams    : t_ADC_BUS(0 to c_NUM_ADC_CHANNELS-1);
  signal fifo_output_streams   : t_ADC_BUS(0 to c_NUM_ADC_CHANNELS-1);
  signal packet                : t_PACKET;
  signal packetized_data       : std_logic_vector(63 downto 0);
  signal packetized_data_valid : std_logic;
  signal packetized_data_ready : std_logic;

  signal ethernet_payload       : std_logic_vector(63 downto 0);
  signal ethernet_payload_valid : std_logic;

  signal burst_data : std_logic_vector(c_MSB-1 downto 0);

  signal ti_adc_output               : std_logic_vector(c_MSB-1 downto 0);
  signal adc_data_ready              : std_logic;
  signal adc_data_ready_single_clock : std_logic;

  -- Selects whether ADC or test data go to ethernet interface
  signal eth_data_gen_enable    : std_logic := '0';
  signal flip_ddr_polarity      : std_logic := '1';
  signal flip_ddr_polarity_sync : std_logic := '1';
  signal data_lanes             : std_logic_vector(1 downto 0);

  signal adc_data_clk_buf4cdc : std_logic := '0';

  -- Mux signals to ethernet
  signal sequencer_out   : std_logic_vector(c_ADC_BITS-1 downto 0) := (others => '0');
  signal sequencer_valid : std_logic                     := '0';

  signal test_data_out : std_logic_vector(c_ADC_BITS-1 downto 0) := (others => '0');

  -- VIO output for phase shifter
  signal phase_shift_backward_vio   : std_logic := '0';
  signal phase_shift_forward_vio    : std_logic := '0';
  signal clk_wiz_phase_shift_reset  : std_logic := '0';
  signal clk_wiz_phase_shift_locked : std_logic := '0';
  signal sample_rate_select : std_logic := '0';

  -- ORd together phase_shift buttons
  signal phase_shift_backward_button : std_logic := '0';
  signal phase_shift_forward_button  : std_logic := '0';

  signal sequencer_channel : std_logic_vector(c_LOG2_CHANNELS-1 downto 0);

  -- MB GPIO
  signal mb_gpio_raw : std_logic_vector (31 downto 0);

  type t_mb_gpio is record
    phase_shift_forward_button  : std_logic;
    phase_shift_backward_button : std_logic;
  end record t_mb_gpio;

  signal mb_gpio : t_mb_gpio;

  signal timestamp : std_logic_vector(c_BITS_TIMESTAMP - 1 downto 0);

  signal eth_data : std_logic_vector(c_ADC_BITS-1 downto 0) := (others => '0');

begin

  dclk_cdc_buf : BUFG
    port map(
      I => adc_data_clk_shift,
      O => adc_data_clk_buf4cdc
      );

  sync_master2adc_reset: xpm_cdc_single
    generic map(
      SRC_INPUT_REG => 0,
      DEST_SYNC_FF => 2
    )
    port map(
      src_clk => MASTER_CLK,
      src_in => reset,
      dest_out => reset_sync_adc,
      dest_clk => adc_data_clk_shift
    );


  sync_master2adc_phase_shift_if_done: xpm_cdc_single
    generic map(
      SRC_INPUT_REG => 0,
      DEST_SYNC_FF => 2
    )
    port map(
      src_clk => MASTER_CLK,
      src_in => phase_shift_if.done,
      dest_out => phase_shift_if_done_sync,
      dest_clk => adc_data_clk_shift
    );

  sync_vio2adc_flip_ddr_polarity : xpm_cdc_single
    generic map(
      SRC_INPUT_REG => 0,
      DEST_SYNC_FF => 2
    )
    port map(
      src_clk => MASTER_CLK,
      src_in => flip_ddr_polarity,
      dest_out => flip_ddr_polarity_sync,
      dest_clk => adc_data_clk_shift
    );

  sync_vio2phy_phy_reset: xpm_cdc_single
    generic map(
      SRC_INPUT_REG => 0,
      DEST_SYNC_FF => 2
    )
    port map(
      src_clk => MASTER_CLK,
      src_in => phy_reset_sig,
      dest_out => phy_reset_sig_sync,
      dest_clk => PHY_CLK
    );

  sync_data_clk : xpm_cdc_single
    generic map(
      SRC_INPUT_REG => 0,
      DEST_SYNC_FF  => 2
      )
    port map(
      src_clk  => '0',
      src_in   => adc_data_clk_buf4cdc,
      dest_out => adc_data_clk_sync,
      dest_clk => MASTER_CLK
      );

  sync_frame_clk : xpm_cdc_single
    generic map(
      SRC_INPUT_REG => 0,
      DEST_SYNC_FF  => 2
      )
    port map(
      src_clk  => '0',
      src_in   => adc_frame_clk,
      dest_out => adc_frame_clk_sync,
      dest_clk => MASTER_CLK
      );

  wiz_adc_clk : entity work.clk_wiz_usrclk2adc
    port map(
      clk_in_100  => USER_CLK1,
      clk_out_200 => FAST_CLK,
      clk_out_150 => MASTER_CLK,
      clk_out_16  => adc_sample_clk_16mhz_prebuf
      );

  wiz_phy_clk : entity work.clk_wiz_phy2adc
    port map(
      clk_in_125 => phy_rx.PHY_RXCLK,
      clk_out_125 => PHY_CLK
  );

  OBUF_ADC_SMPCLK : OBUF
    port map (
      I => adc_sample_clk_16mhz_prebuf,
      O => adc_sample_clk_16mhz
      );

  -- Divide to 8MHz
  div_smpclk_first : process (adc_sample_clk_16mhz)
  begin
    if rising_edge(adc_sample_clk_16mhz) then
      adc_sample_clk_8mhz <= not adc_sample_clk_8mhz;
    end if;
  end process div_smpclk_first;

  -- Divide to 4MHz
  div_smpclk_second : process (adc_sample_clk_8mhz)
  begin
    if rising_edge(adc_sample_clk_8mhz) then
      adc_sample_clk_4mhz <= not adc_sample_clk_4mhz;
    end if;
  end process div_smpclk_second;


  phy_txclk_buf : OBUF
    port map(
      I => phy_txclk_prebuf,
      O => phy_tx.PHY_TXCLK
      );


  bd : entity work.design_1_wrapper
    port map(
      bd_clk           => MASTER_CLK,
      bd_reset         => mb_reset,
      SPI_0_io0_io     => adc_spi_ctrl.SDO,
      SPI_0_io1_io     => adc_spi_ctrl.SDI,
      SPI_0_sck_io     => adc_spi_ctrl.SCLK,
      SPI_0_ss_io      => adc_spi_ctrl.CSn,
      gpio_rtl_0_tri_o => mb_gpio_raw
      );

  mb_gpio.phase_shift_forward_button  <= mb_gpio_raw(0);
  mb_gpio.phase_shift_backward_button <= mb_gpio_raw(1);


  phase_shift_backward_button <= phase_shift_backward_vio or mb_gpio.phase_shift_backward_button;
  phase_shift_forward_button  <= phase_shift_forward_vio or mb_gpio.phase_shift_forward_button;
  phase_shift_ctrl : entity work.phase_shift_ctrl
    port map(
      clk             => MASTER_CLK,
      forward_button  => phase_shift_forward_button,
      backward_button => phase_shift_backward_button,
      enable          => phase_shift_if.enable,
      incdec          => phase_shift_if.incdec,
      done            => phase_shift_if.done
      );

  phase_shift : entity work.clk_wiz_phase_shift
    port map(
      psen          => phase_shift_if.enable,
      psclk         => MASTER_CLK,
      psdone        => phase_shift_if.done,
      psincdec      => phase_shift_if.incdec,
      clk_in_48     => adc_data_clk,
      clk_out_shift => adc_data_clk_shift,
      reset         => clk_wiz_phase_shift_reset,
      locked        => clk_wiz_phase_shift_locked
      );

  -- TODO: make the signals
  autoalign_ctrl_1: entity work.autoalign_ctrl
    port map (
      clk                  => clk,
      reset                => reset,
      start                => start,
      autoalign_trigger    => autoalign_trigger,
      autoalign_done       => autoalign_done,
      autoalign_error      => autoalign_error,
      gpio_set_test_data   => gpio_set_test_data,
      gpio_unset_test_data => gpio_unset_test_data,
      error_out            => error_out);

  adc_autoalign_1: entity work.adc_autoalign
    generic map (
      c_TEST_PATTERN => c_TEST_PATTERN)
    port map (
      clk                         => clk,
      reset                       => reset,
      deserializer_raw_data       => deserializer_raw_data,
      deserializer_raw_data_valid => deserializer_raw_data_valid,
      trigger                     => trigger,
      n_delays                    => n_delays,
      autoalign_done              => autoalign_done,
      phase_shift_button_forward  => phase_shift_button_forward,
      phase_shift_button_backward => phase_shift_button_backward,
      phase_shift_done            => phase_shift_done);


  ti_deserializer : entity work.deser_cmos
    port map(
      CMOS_DIN_A        => adc_data(0),
      CMOS_DIN_B        => adc_data(1),
      CMOS_DIN_C        => adc_data(2),
      CMOS_DIN_D        => adc_data(3),
      DCLK              => adc_data_clk_shift,
      FCLK              => adc_frame_clk,
      data_rate         => '0',         -- 0: DDR, 1: SDR
      data_lanes        => "10",        -- 4 lanes
      flip_ddr_polarity => flip_ddr_polarity_sync,
      RST               => reset_sync_adc or phase_shift_if_done_sync,
      DRDY              => adc_data_ready,
      DOUT              => ti_adc_output
      );

  pulse_shorten_adc_data_ready : entity work.pulse_shorten
    port map(
      clk      => adc_data_clk_shift,
      src_in   => adc_data_ready,
      dest_out => adc_data_ready_single_clock
      );

  fifo_adc2master : entity work.fifo_0
    port map (
      s_axis_aresetn => resetn,
      s_axis_aclk    => adc_data_clk_shift,
      s_axis_tvalid  => adc_data_ready_single_clock,
      s_axis_tready  => open,
      s_axis_tdata   => ti_adc_output,
      m_axis_aclk    => MASTER_CLK,
      m_axis_tvalid  => m_axis_adc_tvalid,
      m_axis_tready  => '1',
      m_axis_tdata   => m_axis_adc_tdata);


--  ti_serializer_bin_outputs : for ii in 0 to c_NUM_ADC_CHANNELS - 1 generate
--    constant msb        : natural := c_ADC_BITS*(c_NUM_ADC_CHANNELS - ii);
--    constant lsb        : natural := c_ADC_BITS*(c_NUM_ADC_CHANNELS - ii - 1);
--    signal deser_output : std_logic_vector(c_ADC_BITS-1 downto 0);
--  begin
--    deser_output           <= ti_adc_output(msb - 1 downto lsb);
--    adc_output_streams(ii) <= deser_output;
--  end generate;

  fifo_bin_outputs : for ii in 0 to c_NUM_ADC_CHANNELS - 1 generate
    constant msb : natural := c_ADC_BITS*(c_NUM_ADC_CHANNELS - ii);
    constant lsb : natural := c_ADC_BITS*(c_NUM_ADC_CHANNELS - ii - 1);
  begin
    fifo_output_streams(ii) <= m_axis_adc_tdata(msb - 1 downto lsb);
  end generate;

  sequencer : entity work.sequencer
    generic map(
      NUM_CHANNELS => c_NUM_ADC_CHANNELS
      )
    port map (
      clk               => MASTER_CLK,
      valid_in          => m_axis_adc_tvalid,
      ready_in          => packetized_data_ready,
      input_bus         => fifo_output_streams,
      valid_out         => sequencer_valid,
      output_data       => sequencer_out,
      sequencer_channel => sequencer_channel
      );

  p_Packetize : process (all) is
  begin
    if eth_data_gen_enable = '1' then
      eth_data <= test_data_out; -- test data
    else
      eth_data <= sequencer_out; -- serialized adc data
    end if;
    packet.timestamp <= timestamp;
    packet.channel <= sequencer_channel;
    packet.data <= eth_data;
    packetized_data <= packet.timestamp & packet.channel & packet.data;
    packetized_data_valid <= sequencer_valid;
  end process p_Packetize;

  fifo_master2phy : entity work.fifo_1
    port map (
      s_axis_aresetn => resetn,
      s_axis_aclk    => MASTER_CLK,
      s_axis_tvalid  => packetized_data_valid,
      s_axis_tready  => packetized_data_ready,
      s_axis_tdata   => packetized_data,
      m_axis_aclk    => PHY_CLK,
      m_axis_tvalid  => ethernet_payload_valid,
      m_axis_tready  => '1',
      m_axis_tdata   => ethernet_payload);

  ethernet_interface_1 : entity work.ethernet_interface
    port map (
      reset_in   => phy_reset_sig_sync,
      reset_out  => reset_out,
      rx_addr    => rx_addr,
      rx_data    => rx_data,
      rx_wren    => rx_wren,
      tx_data    => tx_data,
      b_data     => ethernet_payload,
      b_data_we  => ethernet_payload_valid,
      b_enable   => b_enable,
      MASTER_CLK => PHY_CLK,
      PHY_RXD    => phy_rx.PHY_RXD,
      PHY_RX_DV  => phy_rx.PHY_RXCTL_RXDV,
      PHY_RX_ER  => '0',
      TX_CLK     => phy_txclk_prebuf,
      PHY_TXD    => phy_tx_dbg.PHY_TXD,
      PHY_TX_EN  => phy_tx_dbg.PHY_TXCTL_TXEN,
      PHY_TX_ER  => phy_tx_dbg.PHY_TXER);

  p_GenerateTimestamp : process(MASTER_CLK) is
    variable counter : natural := 0;
  begin
    if rising_edge(MASTER_CLK) then
      counter := counter + 1;
      timestamp <= std_logic_vector(to_unsigned(counter, c_BITS_TIMESTAMP));
    end if;
  end process p_GenerateTimestamp;

  gen_test_data : process(MASTER_CLK) is
  begin
    if rising_edge(MASTER_CLK) then
      test_data_out <= std_logic_vector(unsigned(test_data_out) + 1);
    end if;
  end process gen_test_data;

  -- Assignments
  reset_in            <= reset;
  resetn              <= not reset;
  adc_spi_ctrl.SPI_EN <= '1';
  phy_tx              <= phy_tx_dbg;
  phy_resetn_sig      <= not (reset_out);

  -- Mux sample clock
  -- 8Mhz if sample_rate_select=1, else 4MHz
  with sample_rate_select select
    adc_sample_clk <= adc_sample_clk_8mhz when '1',
                      adc_sample_clk_4mhz when '0',
                      '0' when others;

  adc_pwdn_n  <= '1';
  adc_reset_n <= '1';


  phy_reset_buf : OBUF
    port map(
      I => phy_resetn_sig,
      O => PHY_RESET
      );

--------------------------------------
--------------------------------------
--------------------------------------
--------------------------------------
---  ____  _____ ____  _   _  ____ ---
--- |  _ \| ____| __ )| | | |/ ___|---
--- | | | |  _| |  _ \| | | | |  _ ---
--- | |_| | |___| |_) | |_| | |_| |---
--- |____/|_____|____/ \___/ \____|---
--------------------------------------
--------------------------------------
--------------------------------------
--------------------------------------

debug_gen : if c_DEBUG_ENABLE = '1' generate
  fast_sync_bus_in(5)          <= adc_data_clk_shift;
  fast_sync_bus_in(4)          <= adc_frame_clk;
  fast_sync_bus_in(3 downto 0) <= std_logic_vector(adc_data);
  adc_data_clk_fast_sync       <= fast_sync_bus_out(5);
  adc_frame_clk_fast_sync      <= fast_sync_bus_out(4);
  adc_data_fast_sync           <= fast_sync_bus_out(3 downto 0);
  sync_fast_clk : xpm_cdc_array_single
    generic map(
      SRC_INPUT_REG => 0,
      DEST_SYNC_FF  => 2,
      WIDTH         => 6
      )
    port map (
      src_clk  => '0',
      src_in   => fast_sync_bus_in,
      dest_clk => FAST_CLK,
      dest_out => fast_sync_bus_out
      );



  ila_1_inst_0 : entity work.ila_1
    port map
    (
      clk       => PHY_CLK,
      probe0(0) => '0',
      probe1    => ethernet_payload,
      probe2(0) => ethernet_payload_valid,
      probe3(0) => phy_resetn_sig,
      probe4    => std_logic_vector(rx_addr),
      probe5    => std_logic_vector(rx_data),
      probe6(0) => rx_wren,
      probe7    => std_logic_vector(tx_data)
      );

  --ila_2_inst_0 : entity work.ila_2
  --  port map(
  --    clk       => FAST_CLK,
  --    probe0    => adc_data_fast_sync,
  --    probe1(0) => adc_data_clk_fast_sync,
  --    probe2(0) => adc_frame_clk_fast_sync
  --    );

  ila_0_inst_0 : entity work.ila_0
    port map(
      clk        => MASTER_CLK,
      probe0     => std_logic_vector(fifo_output_streams(0)),
      probe1     => std_logic_vector(fifo_output_streams(1)),
      probe2     => std_logic_vector(fifo_output_streams(2)),
      probe3     => std_logic_vector(fifo_output_streams(3)),
      probe4     => std_logic_vector(fifo_output_streams(4)),
      probe5     => std_logic_vector(fifo_output_streams(5)),
      probe6     => std_logic_vector(fifo_output_streams(6)),
      probe7     => std_logic_vector(fifo_output_streams(7)),
      probe8     => "0000",
      probe9(0)  => m_axis_adc_tvalid,
      probe10(0) => adc_data_clk_sync,
      probe11(0) => adc_frame_clk_sync,
      probe12    => m_axis_adc_tdata
      );

--  ila_0_inst_1 : entity work.ila_0
--    port map(
--      clk        => adc_data_clk_shift,
--      probe0     => std_logic_vector(adc_output_streams(0)),
--      probe1     => std_logic_vector(adc_output_streams(1)),
--      probe2     => std_logic_vector(adc_output_streams(2)),
--      probe3     => std_logic_vector(adc_output_streams(3)),
--      probe4     => std_logic_vector(adc_output_streams(4)),
--      probe5     => std_logic_vector(adc_output_streams(5)),
--      probe6     => std_logic_vector(adc_output_streams(6)),
--      probe7     => std_logic_vector(adc_output_streams(7)),
--      probe8     => std_logic_vector(adc_data),
--      probe9(0)  => adc_data_ready_single_clock,
--      probe10(0) => '0',
--      probe11(0) => '0', --adc_frame_clk,
--      probe12    => ti_adc_output
--      );

  ila_3_inst_0 : entity work.ila_3
    port map(
      clk       => MASTER_CLK,
      probe0(0) => m_axis_adc_tvalid,
      probe1(0) => packetized_data_ready,
      probe2    => flatten_array(fifo_output_streams),
      probe3(0) => sequencer_valid,
      probe4    => sequencer_out,
      probe5    => sequencer_channel
      );

  vio_dbg : entity work.vio_0
    port map(
      clk           => MASTER_CLK,
      probe_in0(0)  => '0',
      probe_in1(0)  => '0',
      probe_in2(0)  => '0', --adc_frame_clk,
      probe_in3(0)  => '0', --adc_data_clk,
      probe_in4(0)  => '0', --adc_data_ready,
      probe_in5(0)  => '0',
      probe_out0(0) => eth_data_gen_enable,
      probe_out1(0) => reset,
      probe_out2(0) => flip_ddr_polarity,
      probe_out3(0) => sample_rate_select,
      probe_out4(0) => phase_shift_forward_vio,
      probe_out5(0) => phase_shift_backward_vio,
      probe_out6(0) => clk_wiz_phase_shift_reset,
      probe_out7(0) => phy_reset_sig
      );

  end generate debug_gen;


end architecture rtl;
