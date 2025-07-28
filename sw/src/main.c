#include "adc_hw.h"
#include "spi.h"
#include "xgpio_l.h"
#include "xil_printf.h"
#include "xparameters.h"

#define DO_TEST_PATTERN_RAMP 0
#define DO_TEST_PATTERN_FIXED 0

//#define DO_PHASE_SHIFT
#define PHASE_SHIFT_BACKWARDS 1
#define PHASE_SHIFT 15.0 /* Deg */

// Calculations for Phase shifter
#define VCO_FREQ 1008 /* MHz */
#define CLK_FREQ 24   /* MHz */

#define FREQ_RATIO (VCO_FREQ / CLK_FREQ)
#define ANGL_RATIO (PHASE_SHIFT / 360.0)
#define PHASE_SHIFT_STEPS ((int)(56.0 * FREQ_RATIO * ANGL_RATIO))

#define GPIO_ADDR 0x40000000

void forward_button(void) {
  XGpio_WriteReg((GPIO_ADDR), 0x0, 0x1);
  XGpio_WriteReg((GPIO_ADDR), 0x0, 0x0);
}

void backward_button(void) {
  XGpio_WriteReg((GPIO_ADDR), 0x0, 0x2);
  XGpio_WriteReg((GPIO_ADDR), 0x0, 0x0);
}

/*
#define EMBEDDED_CLI_IMPL
#include "../lib/embedded_cli.h"

#define CLI_BUFFER_SIZE 512
#define CLI_RX_BUFFER_SIZE 16
#define CLI_CMD_BUFFER_SIZE 32
#define CLI_HISTORY_SIZE 32
#define CLI_BINDING_COUNT 16

EmbeddedCli *cli;

CLI_UINT cliBuffer[BYTES_TO_CLI_UINTS(CLI_BUFFER_SIZE)];

void init_cli(void);
*/

int spi_program_adc(XSpi *inst);

int main(void) {
  int status = XST_SUCCESS;
  xil_printf("Hello World!\r\n");

  // init_cli();

  int busy_loop_counter = 0;

  XSpi *spi_inst = spi_get_instance();
  xil_printf("SPI Driver Address: %p\r\n", spi_inst);

  status = spi_init(spi_inst);
  if (status != XST_SUCCESS) {
    xil_printf("spi_program_adc failed with status %i \r\n", status);
    return XST_FAILURE;
  }

  // Program ADC via SPI
  status = spi_program_adc(spi_inst);
  if (status != XST_SUCCESS) {
    xil_printf("spi_program_adc failed with status %i \r\n", status);
    return XST_FAILURE;
  }

#ifdef DO_PHASE_SHIFT
  // COnfigure Phase Shifter
  xil_printf("Will phase shift %s %i steps (%0.1f deg)\r\n",
		  	  PHASE_SHIFT_BACKWARDS == 1 ? "forward" : "backward",
             PHASE_SHIFT_STEPS, PHASE_SHIFT);
  for (int i = 0; i < PHASE_SHIFT_STEPS; i++) {
    if (PHASE_SHIFT_BACKWARDS)
      backward_button();
    else
      forward_button();
  }
#endif

  return status;
}

void doPhaseShiftForward(void) { xil_printf("Shifting phase forward\r\n"); }

/*
void init_cli(void) {
  EmbeddedCliConfig *config = embeddedCliDefaultConfig();
  config->cliBuffer = cliBuffer;
  config->cliBufferSize = CLI_BUFFER_SIZE;
  config->rxBufferSize = CLI_RX_BUFFER_SIZE;
  config->cmdBufferSize = CLI_CMD_BUFFER_SIZE;
  config->historyBufferSize = CLI_HISTORY_SIZE;
  config->maxBindingCount = CLI_BINDING_COUNT;

  cli = embeddedCliNew(config);

  if (cli == NULL) {
    xil_printf("Failed to create EmbeddedCLI\r\n");
    return;
  }

  embeddedCliAddBinding(cli, {"forward-phase-shift",
                              "Shift phase forward 1/32 of VCO period", false,
                              nullptr, doPhaseShiftForward});
}
*/

/**
 * Program ADC registers for:
 *  - 4 lanes
 *  - SDR operation
 *  */
int spi_program_adc(XSpi *inst) {
  xil_printf("In spi_program_adc\r\n");
  t_spi_word *message;
  t_spi_word *response;

  /*
  SPI_WRITE({0xDE, 0xAD, 0xBE})

  SPI_WRITE({0xEF, 0x98, 0x76})
  */

  // Reset
  SPI_WRITE(SPI_COMMAND_B0_RESET);
  SPI_WRITE(SPI_COMMAND_B0_RESET_CLEAR);

  // Initialization (cf. SBASAQ6A 6.4.3)
  SPI_WRITE(SPI_COMMAND_INIT_1);
  SPI_WRITE(SPI_COMMAND_SEL_B2);
  SPI_WRITE(SPI_COMMAND_B2_INIT_2);
  SPI_WRITE(SPI_COMMAND_B2_INIT_3);

  // Configure data interface
  SPI_WRITE(SPI_COMMAND_SEL_B1);
  SPI_WRITE(SPI_COMMAND_B1_DOUBLE_DATA_RATE);

  // Configure voltage ranges
  SPI_WRITE(SPI_COMMAND_B1_CH1_TO_CH4_RANGE_7V0);
  SPI_WRITE(SPI_COMMAND_B1_CH5_TO_CH8_RANGE_7V0);

  // Enable digital ramp test pattern
  if (DO_TEST_PATTERN_RAMP) {
    SPI_WRITE(SPI_COMMAND_B1_TEST_PATTERN_RAMP_CH1_4);
    SPI_WRITE(SPI_COMMAND_B1_TEST_PATTERN_RAMP_CH5_8);
  }

  // Enable fixed test pattern
  if (DO_TEST_PATTERN_FIXED) {
    SPI_WRITE(SPI_COMMAND_B1_TEST_PATTERN_EN_CH1_4);
    SPI_WRITE(SPI_COMMAND_B1_TEST_PATTERN_EN_CH5_8);
    SPI_WRITE(SPI_COMMAND_B1_TEST_PATTERN_1OF4);
    SPI_WRITE(SPI_COMMAND_B1_TEST_PATTERN_2OF4);
    SPI_WRITE(SPI_COMMAND_B1_TEST_PATTERN_3OF4);
    SPI_WRITE(SPI_COMMAND_B1_TEST_PATTERN_4OF4);
  }

  return XST_SUCCESS;
}
