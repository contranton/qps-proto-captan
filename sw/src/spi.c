#include "spi.h"

static XSpi SpiInstance;
static t_spi_word _message;

u8 ReadBuffer[BUFFER_SIZE];
u8 WriteBuffer[BUFFER_SIZE];

XSpi *spi_get_instance(void) { return &SpiInstance; }

/**
 * Configure and Initialize SPI device
 * */
int spi_init(XSpi *inst) {
  XSpi_Config *ConfigPtr;
  int status;

  xil_printf("_message Addr: %p\r\n", &_message);
  xil_printf("WriteBuffer Addr: %p\r\n", WriteBuffer);
  xil_printf("ReadBuffer Addr: %p\r\n", ReadBuffer);

  ConfigPtr = XSpi_LookupConfig(XPAR_AXI_QUAD_SPI_0_BASEADDR);
  if (ConfigPtr == NULL)
    return XST_DEVICE_NOT_FOUND;

  status = XSpi_CfgInitialize(inst, ConfigPtr, ConfigPtr->BaseAddress);
  if (status != XST_SUCCESS)
    return XST_FAILURE;

  status = XSpi_SelfTest(inst);
  if (status != XST_SUCCESS)
    return XST_FAILURE;

  status = XSpi_SetOptions(inst, XSP_MASTER_OPTION | XSP_MANUAL_SSELECT_OPTION);
  if (status != XST_SUCCESS)
    return XST_FAILURE;

  XSpi_Start(inst);
  XSpi_IntrGlobalDisable(inst); // Polled mode

  XSpi_SetSlaveSelect(inst, 0x1);

  return XST_SUCCESS;
}

/**
 * Writes bytes and returns pointer to readback
 * */
t_spi_word *spi_write(XSpi *inst) {
  int i;
  static u16 buffer_index = 0;
  t_spi_word *return_ptr;
  if (buffer_index + TRANSACTION_SIZE > BUFFER_SIZE)
    buffer_index = 0;

  // TODO: Debug this assignment
  for (i = 0; i < TRANSACTION_SIZE; i++) {
    //    xil_printf("%p\t%p\t%p\r\n", &WriteBuffer[buffer_index + i],
    //    &_message[i],
    //               _message[i]);
    WriteBuffer[buffer_index + i] = _message[i];
  }

  //  xil_printf("\r\nBuffer_index: %i\r\n", buffer_index);
  //  xil_printf("Write start: %p\r\n", &WriteBuffer[buffer_index]);
  //  xil_printf("Read start: %p\r\n\n", &ReadBuffer[buffer_index]);
  XSpi_Transfer(inst, &WriteBuffer[buffer_index], &ReadBuffer[buffer_index],
                TRANSACTION_SIZE);

  return_ptr = (t_spi_word *)(&ReadBuffer[buffer_index]);
  buffer_index += TRANSACTION_SIZE;

  return return_ptr;
}

void spi_print_word(t_spi_word *word) {
  xil_printf("Reading at: %p\r\n", word);
  for (int i = 0; i < TRANSACTION_SIZE; i++)
    xil_printf("%p ", *word[i]);
  xil_printf("\r\n");
}
t_spi_word *spi_set_message(t_spi_word word) {
  for (int i = 0; i < TRANSACTION_SIZE; i++)
    _message[i] = word[i];

  //  xil_printf("\r\n-----------------------\r\n");
  //  xil_printf("Message set to:\r\n");
  //  for (int i = 0; i < TRANSACTION_SIZE; i++)
  //    xil_printf("%p ", _message[i]);
  //  xil_printf("\r\n");
  return &_message;
}
