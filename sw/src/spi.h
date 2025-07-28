#ifndef SPI_H_
#define SPI_H_

#include "xil_printf.h"
#include "xparameters.h"
#include "xspi.h"
#include "xspi_l.h"

#define BUFFER_SIZE 256
#define TRANSACTION_SIZE 3

typedef u8 t_spi_word[TRANSACTION_SIZE];

int spi_init(XSpi *inst);
t_spi_word *spi_write(XSpi *inst);
XSpi *spi_get_instance(void);
void spi_print_word(t_spi_word *word);
t_spi_word *spi_set_message(t_spi_word word);

#define SPI_WRITE(param)                                                       \
  do {                                                                         \
    spi_set_message((t_spi_word)param);                                        \
    spi_write(inst);                                                           \
  } while (0)

#endif // SPI_H_
