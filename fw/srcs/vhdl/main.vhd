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
-- Title      : ADS9813 Prototype DSP system
-- Project    : QPS (Quench Prediction System) Prototype for APS-TD
-------------------------------------------------------------------------------
-- File       : main.vhd
-- Author     : Javier Contreras 52425N
-- Division   : CSAID/RTPS/DIS
-- Created    : 2025-05-22
-- Last update: 2025-08-06
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Configures ADS9813 ADC and transmits incoming data (+ timestamp)
-- to GEL ethernet interface
-------------------------------------------------------------------------------
-- Copyright (c) 2025 Fermi Forward Discovery Group, LLC
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2025-07-22  1.0      javierc   Created
-------------------------------------------------------------------------------

use work.qps_pkg.all;
use work.ads9813_pkg.all;
use work.register_space_pkg.all;
use work.autoalign_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.Vcomponents.all;

library xpm;
use xpm.vcomponents.all;

entity main is
  generic (
    constant c_DEBUG_ENABLE       : std_logic := '1';
    constant c_USE_MICROBLAZE_SPI : std_logic := '0'
    );
  port (
    USER_CLK1 : in  std_logic;
    user_led  : out std_logic;

    -- ADC data interface
    clk_ADC_FRAME : in  std_logic;
    clk_ADC_DATA  : in  std_logic;
    adc_data      : in  t_ADC_RAW_DATA(3 downto 0);
    adc_pwdn_n    : out std_logic;
    adc_reset_n   : out std_logic;

    -- ADC control interface
    adc_spi_ctrl : inout t_ADC_CTRL;

    -- Outgoing sample clock
    clk_ADC_SAMPLING : out std_logic;

    -- GEL Ethernet interface
    phy_rx    : in  t_GEL_PHY_RX;
    phy_tx    : out t_GEL_PHY_TX;
    PHY_RESET : out std_logic
    );
end entity main;

architecture rtl of main is

  -- <Clocks>
  signal clk_MAIN        : std_logic;
  signal clk_FAST        : std_logic;
  signal clk_PHY         : std_logic;
  signal clk_ADC_DATA_SHIFTED : std_logic;  -- Data clock shifted to align with data lanes
  -- </.>

  -- <Resets>
  signal reset          : std_logic := '0';
  signal resetn         : std_logic := '1';
  signal mb_reset       : std_logic := '0';
  signal reset_sync_adc : std_logic := '0';
  signal phy_resetn_sig : std_logic := '1';
  -- </.>

  -- <Outgoing clocks>
  signal clk_ADC_SAMPLING_4MHZ         : std_logic := '0';
  signal clk_ADC_SAMPLING_16MHZ_prebuf : std_logic := '0';
  signal clk_ADC_SAMPLING_8MHZ         : std_logic := '0';
  signal clk_ADC_SAMPLING_16MHZ        : std_logic := '0';
  signal clk_PHY_TX_prebuf            : std_logic := '0';
  -- </.>


--  __  __           _       _
-- |  \/  | ___   __| |_   _| | ___  ___
-- | |\/| |/ _ \ / _` | | | | |/ _ \/ __|
-- | |  | | (_) | (_| | |_| | |  __/\__ \
-- |_|  |_|\___/ \__,_|\__,_|_|\___||___/
--

  -- <PLL phase shift Interface>
  signal if_PhaseShiftControl    : t_PHASE_SHIFT_CTRL_IF;
  signal if_PhaseShift           : t_PHASE_SHIFT_IF;
  signal if_PhaseShift_done_sync : std_logic;
  -- </.>

  -- <Ethernet Interface>
  signal if_Ethernet : t_ETHERNET_INTERFACE;
  -- </.>

  -- <Microblaze gpio outputs>
  signal if_MbGpioRaw : std_logic_vector (31 downto 0);
  signal if_MbGpio    : t_MB_GPIO;
  -- </.>

  -- <ADC autoaligner>
  signal if_AutoalignControl : t_AUTOALIGN_CTRL_IF;

  -- <SPI interfaces>
  signal if_AdcSpiCtrl_Microblaze : t_ADC_CTRL;
  signal if_AdcSpiCtrl_Hdl        : t_ADC_CTRL;
  signal if_SpiHdlManager         : t_SPI_MGT;
  -- </.>

  -- <ADS9813 configuration interface>
  signal if_Ads9813: t_Ads9813;

  signal if_AdcUserConfig : t_ADC_USER_CONFIG :=
    (
      VoltageScale      => en_VOLTSCALE_5V0,
      TestPatternCh1To4 => c_INITIAL_TEST_PATTERN_CH1_4,
      TestPatternCh5To8 => c_INITIAL_TEST_PATTERN_CH5_8
      );

  -- <Register space interface>
  signal if_RegSpace : t_CONFIG_REGISTER_INTERFACE;
  -- </.>

--  __  __       _             _       _           __ _
-- |  \/  | __ _(_)_ __     __| | __ _| |_ __ _   / _| | _____      __
-- | |\/| |/ _` | | '_ \   / _` |/ _` | __/ _` | | |_| |/ _ \ \ /\ / /
-- | |  | | (_| | | | | | | (_| | (_| | || (_| | |  _| | (_) \ V  V /
-- |_|  |_|\__,_|_|_| |_|  \__,_|\__,_|\__\__,_| |_| |_|\___/ \_/\_/
--

  -- <AXIS : Deserializer -- CDC FIFO>
  --  CDC crossing from ADC clock domain to PHY clock domain
  signal sig_axis_AdcData_AdcClk_tdata        : std_logic_vector(c_MSB-1 downto 0);
  signal sig_axis_AdcData_AdcClk_tready       : std_logic := '1';
  signal sig_axis_AdcData_AdcClk_tvalid       : std_logic;
  signal sig_axis_AdcData_AdcClk_tvalid_pulse : std_logic;
  -- </.>

  -- <AXIS : CDC FIFO -- Sequencer>
  -- FIFO output fed into sequencer
  signal sig_axis_AdcData_MasterClk_tvalid : std_logic := '0';
  signal sig_axis_AdcData_MasterClk_tready : std_logic := '1';
  signal sig_axis_AdcData_MasterClk_tdata  : std_logic_vector(c_MSB-1 downto 0);
  -- </.>

  -- <Raw Sequencer Output>
  signal sig_SequencerOut     : std_logic_vector(c_ADC_BITS-1 downto 0) := (others => '0');
  signal sig_SequencerValid   : std_logic                               := '0';
  signal sig_SequencerChannel : std_logic_vector(c_LOG2_CHANNELS-1 downto 0);
  -- </.>

  -- <AXIS : Sequencer -- Packetizer>
  -- Packed output of sequencer to which timestamp is added
  signal sig_axis_PacketizedData_MasterClk_tdata  : std_logic_vector(63 downto 0);
  signal sig_axis_PacketizedData_MasterClk_tvalid : std_logic;
  signal sig_axis_PacketizedData_MasterClk_tready : std_logic := '1';
  -- </.>

  -- Data timestamp. At 150MHz clk_MAIN, 1 LSB = 6.66ns
  -- With c_BITS_TIMESTAMP = 37, this amounts to 916s \approx 15 min.
  signal sig_Timestamp       : std_logic_vector(c_BITS_TIMESTAMP - 1 downto 0);
  signal sig_TimestampFrozen : std_logic_vector(c_BITS_TIMESTAMP - 1 downto 0);

  -- Mux signals to ethernet
  signal sig_PacketData : std_logic_vector(c_ADC_BITS-1 downto 0) := (others => '0');

  -- <AXIS : Packetizer -- Ethernet>
  -- CDC crossing from MAIN clock domain to PHY clock domain
  signal sig_axis_EthernetPayload_PhyClk_tdata  : std_logic_vector(63 downto 0);
  signal sig_axis_EthernetPayload_PhyClk_tvalid : std_logic;
  signal sig_axis_EthernetPayload_PhyClk_tready : std_logic := '1';
  -- </.>


--   ____            _             _
--  / ___|___  _ __ | |_ _ __ ___ | |
-- | |   / _ \| '_ \| __| '__/ _ \| |
-- | |__| (_) | | | | |_| | | (_) | |
--  \____\___/|_| |_|\__|_|  \___/|_|
--

  -- Selects whether ADC or test data go to ethernet interface
  signal ctrl_EthDataGenEnable : std_logic := '0';

  -- Sets whether DDR data starts on rising edge or negative edge
  signal ctrl_FlipDdrPolarity : std_logic := '1';

  -- Pulsed interface for PLL phase shift
  signal ctrl_PhaseShiftBackwardButton : std_logic := '0';
  signal ctrl_PhaseShiftForwardButton  : std_logic := '0';

  -- Selector for sample clock mux (4MHz/8MHz)
  signal ctrl_SampleRateSelect : std_logic := '0';

  -- Enables timestamp counter
  signal ctrl_TimestampEnable : std_logic := '1';

  -- Starts autoalignment algorithm
  signal ctrl_AutoalignTrigger : std_logic := '0';

--  ____  _        _
-- / ___|| |_ __ _| |_ _   _ ___
-- \___ \| __/ _` | __| | | / __|
--  ___) | || (_| | |_| |_| \__ \
-- |____/ \__\__,_|\__|\__,_|___/
--

  signal stat_QpsStatus : t_QpsStatus := (
    AdcHasBeenInitialized => '0',
    AdcDataIsAligned => '0'
  );

--  ____       _
-- |  _ \  ___| |__  _   _  __ _
-- | | | |/ _ \ '_ \| | | |/ _` |
-- | |_| |  __/ |_) | |_| | (_| |
-- |____/ \___|_.__/ \__,_|\__, |
--                         |___/

  -- Synchronized data/frame clocks for ILA
  signal clk_ADC_DATA_sync       : std_logic := '0';
  signal clk_ADC_FRAME_sync      : std_logic := '0';
  signal clk_ADC_DATA_fast_sync  : std_logic := '0';
  signal clk_ADC_FRAME_fast_sync : std_logic := '0';
  signal adc_data_fast_sync      : std_logic_vector(3 downto 0);
  signal fast_sync_bus_in        : std_logic_vector(5 downto 0);
  signal fast_sync_bus_out       : std_logic_vector(5 downto 0);
  signal clk_ADC_DATA_buf4cdc    : std_logic := '0';

  -- VIO signals
  signal vio_out_PhaseShiftBackwardButton : std_logic := '0';
  signal vio_out_PhaseShiftForwardButton  : std_logic := '0';
  signal vio_out_ClkWizPhaseShiftReset    : std_logic := '0';
  signal vio_in_ClkWizPhaseShiftLocked    : std_logic := '0';
  signal vio_out_SampleRateSelect         : std_logic := '0';
  signal vio_out_Reset                    : std_logic := '0';
  signal vio_out_FlipDdrPolarity          : std_logic := '1';
  signal vio_out_FlipDdrPolarity_sync     : std_logic := '1';
  signal vio_out_PhyResetSig              : std_logic := '1';
  signal vio_out_PhyResetSig_sync         : std_logic := '1';
  signal vio_out_EthDataGenEnable         : std_logic := '0';

  -- Sequencer data Input
  -- Splits large std_logic_vector into per_channel ADC words
  signal sig_AdcDataPerChannel : t_ADC_BUS(0 to c_NUM_ADC_CHANNELS-1);


  -- Test data generator for ethernet interface
  -- Most useful when ADC wasn't yet working. Now deprecated.
  signal ctrl_TestDataEnable : std_logic                               := '0';
  signal sig_TestData        : std_logic_vector(c_ADC_BITS-1 downto 0) := (others => '0');

begin

  -- Assignments
  resetn         <= not reset;
  phy_resetn_sig <= not If_Ethernet.gel_reset_out;

  adc_spi_ctrl.SPI_EN <= '1';
  adc_pwdn_n          <= '1';
  adc_reset_n         <= '1';

  -- TODO: Modularize this pattern and add a wait condition
  p_PowerOnInitialize : process(clk_MAIN) is
    begin
      if rising_edge(clk_MAIN) then
       if stat_QpsStatus.AdcHasBeenInitialized = '0' then
         if_Ads9813.FunctionAddress <= en_FUNCTION_INIT;
         if_Ads9813.triggerTx <= '1';
        end if;
      end if;
    end process p_PowerOnInitialize;

  -- <Generate Clocks> --
  pll_MainClocks : entity work.clk_wiz_usrclk2adc
    -- Clocking wizard for main clocks derived from 100MHz crystal
    port map(
      clk_in_100  => USER_CLK1,
      clk_out_200 => clk_FAST,
      clk_out_150 => clk_MAIN,
      clk_out_16  => clk_ADC_SAMPLING_16MHZ_prebuf
      );

  pll_PhyClock : entity work.clk_wiz_phy2adc
    -- Clocking wizard for clk_PHY generation
    port map(
      clk_in_125  => phy_rx.PHY_RXCLK,
      clk_out_125 => clk_PHY
      );

  p_DivideSampleClock16To8 : process (clk_ADC_SAMPLING_16MHZ)
  -- Divide to 8MHz
  begin
    if rising_edge(clk_ADC_SAMPLING_16MHZ) then
      clk_ADC_SAMPLING_8MHZ <= not clk_ADC_SAMPLING_8MHZ;
    end if;
  end process p_DivideSampleClock16To8;

  p_DivideSampleClock8To4 : process (clk_ADC_SAMPLING_8MHZ)
  -- Divide to 4MHz
  begin
    if rising_edge(clk_ADC_SAMPLING_8MHZ) then
      clk_ADC_SAMPLING_4MHZ <= not clk_ADC_SAMPLING_4MHZ;
    end if;
  end process p_DivideSampleClock8To4;

  -- Mux sample clock
  with ctrl_SampleRateSelect select
    clk_ADC_SAMPLING <= clk_ADC_SAMPLING_8MHZ when '1',
                      clk_ADC_SAMPLING_4MHZ when '0',
                      '0'                 when others;
  -- </.> --


  -- <SPI module for ADC configuration>
  gen_Spi : if c_USE_MICROBLAZE_SPI = '0' generate
    adc_spi_ctrl <= if_AdcSpiCtrl_Hdl;

    mod_HdlSpi : entity work.spi_master
      port map(
        spi_clk       => clk_MAIN,
        SPI_EN        => if_AdcSpiCtrl_Hdl.SPI_EN,
        SPI_CS_Z      => if_AdcSpiCtrl_Hdl.CSn,
        SPI_MOSI      => if_AdcSpiCtrl_Hdl.SDO,
        SPI_MISO      => if_AdcSpiCtrl_Hdl.SDI,
        SPI_SCLK      => if_AdcSpiCtrl_Hdl.SCLK,
        tx_trn        => if_SpiHdlManager.tx_trn,
        rx_trn        => if_SpiHdlManager.rx_trn,
        addr          => if_SpiHdlManager.addr,
        wr_data       => if_SpiHdlManager.wr_data,
        rst           => if_SpiHdlManager.reset,
        SPI_BUSY      => if_SpiHdlManager.busy,
        SPI_READ_DONE => if_SpiHdlManager.read_done,
        read_data     => if_SpiHdlManager.read_data
        );

    mod_Ads9813Aspi : entity work.SpiController_ADS9813
      port map (
        clk              => clk_MAIN,
        if_Ads9813       => if_Ads9813,
        if_AdcUserConfig => if_AdcUserConfig,
        if_Spi           => if_SpiHdlManager);

  else generate
    adc_spi_ctrl <= if_AdcSpiCtrl_Microblaze;

    bd_MicroblazeSpi : entity work.design_1_wrapper
      port map(
        bd_clk           => clk_MAIN,
        bd_reset         => mb_reset,
        SPI_0_io0_io     => if_AdcSpiCtrl_Microblaze.SDO,
        SPI_0_io1_io     => if_AdcSpiCtrl_Microblaze.SDI,
        SPI_0_sck_io     => if_AdcSpiCtrl_Microblaze.SCLK,
        SPI_0_ss_io      => if_AdcSpiCtrl_Microblaze.CSn,
        gpio_rtl_0_tri_o => if_MbGpioRaw
        );

    if_MbGpio.PhaseShiftForwardButton  <= if_MbGpioRaw(0);
    if_MbGpio.PhaseShiftBackwardButton <= if_MbGpioRaw(1);

  end generate gen_Spi;
  -- </.>

  -- <Phase shift control for ADC DCLK>
  mod_PhaseShiftControl : entity work.phase_shift_ctrl
    -- Handles phase_shift buttons
    port map(
      clk             => clk_MAIN,
      forward_button  => ctrl_PhaseShiftForwardButton,
      backward_button => ctrl_PhaseShiftBackwardButton,
      enable          => if_PhaseShift.enable,
      incdec          => if_PhaseShift.incdec,
      done            => if_PhaseShift.done
      );

  pll_PhaseShift : entity work.clk_wiz_phase_shift
    -- Clocking wizard exclusively to phase_shift clk_ADC_DATA
    port map(
      psclk         => clk_MAIN,
      psen          => if_PhaseShift.enable,
      psdone        => if_PhaseShift.done,
      psincdec      => if_PhaseShift.incdec,
      clk_in_48     => clk_ADC_DATA,
      clk_out_shift => clk_ADC_DATA_SHIFTED,
      reset         => vio_out_ClkWizPhaseShiftReset,
      locked        => vio_in_ClkWizPhaseShiftLocked
      );
  if_PhaseShiftControl.done <= if_PhaseShift.done;
  -- </.>

  -- <ADC Autoaligners>
  p_SendSpiDisableTestPattern: process(clk_MAIN) is
    begin
      if rising_edge(clk_MAIN) then
        if stat_QpsStatus.AdcDataIsAligned = '0' then
          if if_AutoalignControl.done = '1' then
            stat_QpsStatus.AdcDataIsAligned <= '1';
            if_Ads9813.FunctionAddress <= en_FUNCTION_DISABLE_TEST;
            if_Ads9813.triggerTx <= '1';
          end if;
        end if;
      end if;
  end process p_SendSpiDisableTestPattern;

  mod_Autoalign : entity work.adc_autoalign
    port map (
      clk                         => clk_MAIN,
      reset                       => reset,
      if_AutoAlignCtrl            => if_AutoalignControl,
      if_PhaseShiftCtrl           => if_PhaseShiftControl,
      dut_data                    => sig_axis_AdcData_MasterClk_tdata,
      dut_data_valid              => sig_axis_AdcData_MasterClk_tvalid);
  -- </.>

  -- <ADC DDR Deserializer>
  mod_TiDeserializer : entity work.deser_cmos
    port map(
      CMOS_DIN_A        => adc_data(0),
      CMOS_DIN_B        => adc_data(1),
      CMOS_DIN_C        => adc_data(2),
      CMOS_DIN_D        => adc_data(3),
      DCLK              => clk_ADC_DATA_SHIFTED,
      FCLK              => clk_ADC_FRAME,
      data_rate         => '0',         -- 0: DDR, 1: SDR
      data_lanes        => "10",        -- 4 lanes
      flip_ddr_polarity => ctrl_FlipDdrPolarity,
      RST               => reset_sync_adc or if_PhaseShift_done_sync,
      DRDY              => sig_axis_AdcData_AdcClk_tvalid,
      DOUT              => sig_axis_AdcData_AdcClk_tdata
      );

  mod_PulseShorten_AdcDataValid : entity work.pulse_shorten
    -- Ensures tvalid is single clock pulse to avoid reading wrong data
    port map(
      clk      => clk_ADC_DATA_SHIFTED,
      src_in   => sig_axis_AdcData_AdcClk_tvalid,
      dest_out => sig_axis_AdcData_AdcClk_tvalid_pulse
      );
  -- </.> --

  -- <Clock domain crossing from ADC to MAIN clock domains>
  fifo_Adc2Master_AdcData : entity work.fifo_0
    port map (
      s_axis_aresetn => resetn,
      s_axis_aclk    => clk_ADC_DATA_SHIFTED,
      s_axis_tvalid  => sig_axis_AdcData_AdcClk_tvalid_pulse,
      s_axis_tready  => sig_axis_AdcData_AdcClk_tready,
      s_axis_tdata   => sig_axis_AdcData_AdcClk_tdata,
      m_axis_aclk    => clk_MAIN,
      m_axis_tvalid  => sig_axis_AdcData_MasterClk_tvalid,
      m_axis_tready  => sig_axis_AdcData_MasterClk_tready,
      m_axis_tdata   => sig_axis_AdcData_MasterClk_tdata);
  -- </.>


  -- <Assign channel to ADC data>
  mod_Sequencer : entity work.sequencer
    generic map(
      NUM_CHANNELS => c_NUM_ADC_CHANNELS
      )
    port map (
      clk               => clk_MAIN,
      ready_in          => sig_axis_PacketizedData_MasterClk_tready,
      valid_in          => sig_axis_AdcData_MasterClk_tvalid,
      input_bus         => f_Channelize(sig_axis_AdcData_MasterClk_tdata),
      valid_out         => sig_SequencerValid,
      output_data       => sig_SequencerOut,
      sequencer_channel => sig_SequencerChannel
      );
  -- </.>

  p_GenTestData : process(clk_MAIN) is
  begin
    if rising_edge(clk_MAIN) then
      if ctrl_TestDataEnable then
        sig_TestData <= std_logic_vector(unsigned(sig_TestData) + 1);
      end if;
    end if;
  end process p_GenTestData;
  -- </.>


  -- <Timestamp generator>
  mod_Timestamp : entity work.timestamp_generator
    generic map(
      c_BITS_TIMESTAMP => c_BITS_TIMESTAMP
      )
    port map(
      clk              => clk_MAIN,
      reset            => reset,
      enable           => ctrl_TimestampEnable,
      freeze           => sig_axis_AdcData_MasterClk_tvalid,
      timestamp        => sig_Timestamp,
      timestamp_frozen => sig_TimestampFrozen
      );
  -- </.>

  -- <Mux data to send and add timestamp>
  p_Packetize : process (all) is
  begin
    if ctrl_EthDataGenEnable = '1' then
      sig_PacketData <= sig_TestData;      -- test data
    else
      sig_PacketData <= sig_SequencerOut;  -- serialized adc data
    end if;
    sig_axis_PacketizedData_MasterClk_tdata <=
      sig_TimestampFrozen & sig_SequencerChannel & sig_PacketData;
    sig_axis_PacketizedData_MasterClk_tvalid <= sig_SequencerValid;
  end process p_Packetize;
  -- </.>

  -- <Clock domain crossing from MAIN to PHY clock domain>
  fifo_Main2Phy_PacketizedData : entity work.fifo_1
    port map (
      s_axis_aresetn => resetn,
      s_axis_aclk    => clk_MAIN,
      s_axis_tvalid  => sig_axis_PacketizedData_MasterClk_tvalid,
      s_axis_tready  => sig_axis_PacketizedData_MasterClk_tready,
      s_axis_tdata   => sig_axis_PacketizedData_MasterClk_tdata,
      m_axis_aclk    => clk_PHY,
      m_axis_tvalid  => sig_axis_EthernetPayload_PhyClk_tvalid,
      m_axis_tready  => sig_axis_EthernetPayload_PhyClk_tready,
      m_axis_tdata   => sig_axis_EthernetPayload_PhyClk_tdata);
  -- </.>

  -- <Ethernet interface>
  mod_EthernetInterface : entity work.ethernet_interface
    port map (
      MASTER_CLK => clk_PHY,
      reset_in   => if_Ethernet.gel_reset_in,
      reset_out  => if_Ethernet.gel_reset_out,
      rx_addr    => if_Ethernet.rx_addr,
      rx_data    => if_Ethernet.rx_data,
      rx_wren    => if_Ethernet.rx_wren,
      tx_data    => if_Ethernet.tx_data,
      b_enable   => if_Ethernet.b_enable,
      b_data     => if_Ethernet.b_data,
      b_data_we  => if_Ethernet.b_data_we,
      PHY_RXD    => phy_rx.PHY_RXD,
      PHY_RX_DV  => phy_rx.PHY_RXCTL_RXDV,
      PHY_RX_ER  => '0',
      TX_CLK     => clk_PHY_TX_prebuf,   -- Sent to OBUF before phy_tx.PHY_TXCLK
      PHY_TXD    => phy_tx.PHY_TXD,
      PHY_TX_EN  => phy_tx.PHY_TXCTL_TXEN,
      PHY_TX_ER  => phy_tx.PHY_TXER);

  mod_RegisterSpace : entity work.register_space
    port map(
      clk         => clk_PHY,
      if_RegSpace => if_RegSpace);

  -- TODO: The incoming ots address is 32 bits. SHould I extract only the sub-address I need?
  -- I.e. how to reconstrain the input data without overflowing?
  if_RegSpace.ReadAddress <=
    to_integer(unsigned(if_Ethernet.rx_addr(c_REGISTER_ADDRESS_MSB-1 downto 0)));
  if_RegSpace.WriteData   <= if_Ethernet.rx_data;
  if_RegSpace.WriteEnable <= if_Ethernet.rx_wren;
  if_Ethernet.tx_data     <= if_RegSpace.ReadData;

  if_Ethernet.b_data    <= sig_axis_EthernetPayload_PhyClk_tdata;
  if_Ethernet.b_data_we <= sig_axis_EthernetPayload_PhyClk_tvalid;
  -- </.>


  -- <Synchronizers>
  sync_Main2Adc_Reset : xpm_cdc_single
    generic map(SRC_INPUT_REG => 0, DEST_SYNC_FF => 2)
    port map(
      src_clk  => clk_MAIN,
      src_in   => reset,
      dest_out => reset_sync_adc,
      dest_clk => clk_ADC_DATA_SHIFTED
      );

  sync_Main2Adc_PhaseShiftDone : xpm_cdc_single
    generic map(SRC_INPUT_REG => 0, DEST_SYNC_FF => 2)
    port map(
      src_clk  => clk_MAIN,
      src_in   => if_PhaseShift.done,
      dest_out => if_PhaseShift_done_sync,
      dest_clk => clk_ADC_DATA_SHIFTED
      );

  -- </.>

  -- <Output Buffers>
  obuf_SampleClock : OBUF
    port map (
      I => clk_ADC_SAMPLING_16MHZ_prebuf,
      O => clk_ADC_SAMPLING_16MHZ);

  obuf_PhyReset : OBUF
    port map(
      I => phy_resetn_sig,
      O => PHY_RESET);

  obuf_PhyTxClk : OBUF
    port map(
      I => clk_PHY_TX_prebuf,
      O => phy_tx.PHY_TXCLK);
  -- </.>

---  ____  _____ ____  _   _  ____ ---
--- |  _ \| ____| __ )| | | |/ ___|---
--- | | | |  _| |  _ \| | | | |  _ ---
--- | |_| | |___| |_) | |_| | |_| |---
--- |____/|_____|____/ \___/ \____|---

  gen_Debug : if c_DEBUG_ENABLE = '0' generate

    ctrl_PhaseShiftBackwardButton <= if_MbGpio.PhaseShiftBackwardButton;
    ctrl_PhaseShiftForwardButton  <= if_MbGpio.PhaseShiftForwardButton;
    ctrl_FlipDdrPolarity          <= '1';
    ctrl_EthDataGenEnable         <= '0';
    ctrl_SampleRateSelect         <= '0';
    if_Ethernet.gel_reset_in      <= '0';

  else generate

    fast_sync_bus_in(5)          <= clk_ADC_DATA_SHIFTED;
    fast_sync_bus_in(4)          <= clk_ADC_FRAME;
    fast_sync_bus_in(3 downto 0) <= std_logic_vector(adc_data);
    clk_ADC_DATA_fast_sync       <= fast_sync_bus_out(5);
    clk_ADC_FRAME_fast_sync      <= fast_sync_bus_out(4);
    adc_data_fast_sync           <= fast_sync_bus_out(3 downto 0);

    -- Allow operation from both VIO and MB
    ctrl_EthDataGenEnable         <= vio_out_EthDataGenEnable;
    ctrl_FlipDdrPolarity          <= vio_out_FlipDdrPolarity_sync;
    ctrl_PhaseShiftBackwardButton <= vio_out_PhaseShiftBackwardButton or if_MbGpio.PhaseShiftBackwardButton;
    ctrl_PhaseShiftForwardButton  <= vio_out_PhaseShiftForwardButton or if_MbGpio.PhaseShiftForwardButton;
    ctrl_SampleRateSelect         <= vio_out_SampleRateSelect;
    if_Ethernet.gel_reset_in      <= vio_out_PhyResetSig_sync;

    bufg_DataClockDebug : BUFG
      port map(I => clk_ADC_DATA_SHIFTED, O => clk_ADC_DATA_buf4cdc);

    sync_Async2Fast_FastSyncBus : xpm_cdc_array_single
      generic map(SRC_INPUT_REG => 0, DEST_SYNC_FF => 2, WIDTH => 6)
      port map (
        src_clk  => '0',
        dest_clk => clk_FAST,
        src_in   => fast_sync_bus_in,
        dest_out => fast_sync_bus_out
        );

    sync_Async2Main_DataClockDebug : xpm_cdc_single
      generic map(SRC_INPUT_REG => 0, DEST_SYNC_FF => 2)
      port map(
        src_clk  => '0',
        dest_clk => clk_MAIN,
        src_in   => clk_ADC_DATA_buf4cdc,
        dest_out => clk_ADC_DATA_sync
        );

    sync_Async2Main_FrameClockDebug : xpm_cdc_single
      generic map(SRC_INPUT_REG => 0, DEST_SYNC_FF => 2)
      port map(
        src_clk  => '0',
        dest_clk => clk_MAIN,
        src_in   => clk_ADC_FRAME,
        dest_out => clk_ADC_FRAME_sync
        );

    sync_Main2Adc_VioFlipDdrOPolarity : xpm_cdc_single
      generic map(SRC_INPUT_REG => 0, DEST_SYNC_FF => 2)
      port map(
        src_clk  => clk_MAIN,
        dest_clk => clk_ADC_DATA_SHIFTED,
        src_in   => vio_out_FlipDdrPolarity,
        dest_out => vio_out_FlipDdrPolarity_sync
        );

    sync_Main2Phy_VioPhyReset : xpm_cdc_single
      generic map(SRC_INPUT_REG => 0, DEST_SYNC_FF => 2)
      port map(
        src_clk  => clk_MAIN,
        dest_clk => clk_PHY,
        src_in   => vio_out_PhyResetSig,
        dest_out => vio_out_PhyResetSig_sync
        );

    ila_1_inst_0 : entity work.ila_1
      port map
      (
        clk       => clk_PHY,
        probe0(0) => '0',
        probe1    => sig_axis_EthernetPayload_PhyClk_tdata,
        probe2(0) => sig_axis_EthernetPayload_PhyClk_tvalid,
        probe3(0) => phy_resetn_sig,
        probe4    => std_logic_vector(if_Ethernet.rx_addr),
        probe5    => std_logic_vector(if_Ethernet.rx_data),
        probe6(0) => if_Ethernet.rx_wren,
        probe7    => std_logic_vector(if_Ethernet.tx_data)
        );

    --ila_2_inst_0 : entity work.ila_2
    --  port map(
    --    clk       => clk_FAST,
    --    probe0    => adc_data_fast_sync,
    --    probe1(0) => clk_ADC_DATA_fast_sync,
    --    probe2(0) => clk_ADC_FRAME_fast_sync
    --    );

    sig_AdcDataPerChannel <= f_Channelize(sig_axis_AdcData_MasterClk_tdata);
    ila_0_inst_0 : entity work.ila_0
      port map(
        clk        => clk_MAIN,
        probe0     => std_logic_vector(sig_AdcDataPerChannel(0)),
        probe1     => std_logic_vector(sig_AdcDataPerChannel(1)),
        probe2     => std_logic_vector(sig_AdcDataPerChannel(2)),
        probe3     => std_logic_vector(sig_AdcDataPerChannel(3)),
        probe4     => std_logic_vector(sig_AdcDataPerChannel(4)),
        probe5     => std_logic_vector(sig_AdcDataPerChannel(5)),
        probe6     => std_logic_vector(sig_AdcDataPerChannel(6)),
        probe7     => std_logic_vector(sig_AdcDataPerChannel(7)),
        probe8     => "0000",
        probe9(0)  => sig_axis_AdcData_MasterClk_tvalid,
        probe10(0) => clk_ADC_DATA_sync,
        probe11(0) => clk_ADC_FRAME_sync,
        probe12    => sig_axis_AdcData_MasterClk_tdata
        );

    ila_3_inst_0 : entity work.ila_3
      port map(
        clk       => clk_MAIN,
        probe0(0) => sig_axis_AdcData_MasterClk_tvalid,
        probe1(0) => sig_axis_PacketizedData_MasterClk_tready,
        probe2    => flatten_array(sig_AdcDataPerChannel),
        probe3(0) => sig_SequencerValid,
        probe4    => sig_SequencerOut,
        probe5    => sig_SequencerChannel
        );

    vio_dbg : entity work.vio_0
      port map(
        clk           => clk_MAIN,
        probe_in0(0)  => '0',
        probe_in1(0)  => '0',
        probe_in2(0)  => '0',           --clk_ADC_FRAME,
        probe_in3(0)  => '0',           --clk_ADC_DATA,
        probe_in4(0)  => '0',           --sig_axis_AdcData_AdcClk_tvalid,
        probe_in5(0)  => '0',
        probe_out0(0) => vio_out_EthDataGenEnable,
        probe_out1(0) => vio_out_Reset,
        probe_out2(0) => vio_out_FlipDdrPolarity,
        probe_out3(0) => vio_out_SampleRateSelect,
        probe_out4(0) => vio_out_PhaseShiftForwardButton,
        probe_out5(0) => vio_out_PhaseShiftBackwardButton,
        probe_out6(0) => vio_out_ClkWizPhaseShiftReset,
        probe_out7(0) => vio_out_PhyResetSig
        );
  end generate gen_Debug;


end architecture rtl;
