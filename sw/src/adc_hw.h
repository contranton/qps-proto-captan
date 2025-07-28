#ifndef ADC_HW_H_
#define ADC_HW_H_
// clang-format off

#define SPI_COMMAND_SEL_B1 {0x3, 0x0, 0x02}
#define SPI_COMMAND_SEL_B2 {0x3, 0x0, 0x10}

#define SPI_COMMAND_INIT_1 {0x4, 0x0, 0xB}
#define SPI_COMMAND_B2_INIT_2 {0x92, 0x0, 0x2}
#define SPI_COMMAND_B2_INIT_3 {0xC5, 0x06, 0x04}

// --------------------
// Bank 0 Settings
// --------------------
#define SPI_COMMAND_B0_RESET {0x0, 0x0, 0x1}
#define SPI_COMMAND_B0_RESET_CLEAR {0x0, 0x0, 0x0}
// --------------------
// Bank 1 Settings
// --------------------
// USER BITS SETTINGS
#define UBITS_CH1_4 0b1101
#define UBITS_CH5_8 0b1101
#define SPI_COMMAND_B1_USER_BITS {0x1C, UBITS_CH5_8, UBITS_CH1_4}
// DATA RATE SETTINGS
#define SPI_COMMAND_B1_DOUBLE_DATA_RATE {0xC1, 0x00, 0x00}
#define SPI_COMMAND_B1_SINGLE_DATA_RATE {0xC1, 0x01, 0x00}
// --------------------
// VOLTAGE RANGE SETTINGS.
// These macros are provided for convenience assuming all ADCs equal.
// To customize individual ADCs, the mapping is as follows:
// Address 0xC2 => Channels 4 to 1 (Data is [CH4;CH3;CH2;CH1])
// Address 0xC3 => Channels 8 to 5 (Data is [CH8;CH7;CH6;CH5])
// Each channel has 4 bits, with the mapping:
// 0 -- +-5V
// 1 -- +-3.5V
// 2 -- +-2.5V
// 3 -- +-7V
// 4 -- +-10V
// 5 -- +-12V
#define SPI_COMMAND_B1_CH1_TO_CH4_RANGE_5V0 {0xC2, 0x00, 0x00}
#define SPI_COMMAND_B1_CH1_TO_CH4_RANGE_3V5 {0xC2, 0x11, 0x11}
#define SPI_COMMAND_B1_CH1_TO_CH4_RANGE_2V5 {0xC2, 0x22, 0x22}
#define SPI_COMMAND_B1_CH1_TO_CH4_RANGE_7V0 {0xC2, 0x33, 0x33}
#define SPI_COMMAND_B1_CH1_TO_CH4_RANGE_10V0 {0xC2, 0x44, 0x44}
#define SPI_COMMAND_B1_CH1_TO_CH4_RANGE_12V0 {0xC2, 0x55, 0x55}
#define SPI_COMMAND_B1_CH5_TO_CH8_RANGE_5V0 {0xC3, 0x00, 0x00}
#define SPI_COMMAND_B1_CH5_TO_CH8_RANGE_3V5 {0xC3, 0x11, 0x11}
#define SPI_COMMAND_B1_CH5_TO_CH8_RANGE_2V5 {0xC3, 0x22, 0x22}
#define SPI_COMMAND_B1_CH5_TO_CH8_RANGE_7V0 {0xC3, 0x33, 0x33}
#define SPI_COMMAND_B1_CH5_TO_CH8_RANGE_10V0 {0xC3, 0x44, 0x44}
#define SPI_COMMAND_B1_CH5_TO_CH8_RANGE_12V0 {0xC3, 0x55, 0x55}
// --------------------
// TEST DATA SETTINGS
#define TP_A_1 0x12
#define TP_A_2 0x34
#define TP_A_3 0x56
#define TP_B_1 0x78
#define TP_B_2 0x9A
#define TP_B_3 0xBC
#define SPI_COMMAND_B1_TEST_PATTERN_RAMP_CH1_4 {0x13, 0x00, 0x0A} // Increments by one
#define SPI_COMMAND_B1_TEST_PATTERN_RAMP_CH5_8 {0x18, 0x00, 0x0A} // Increments by one
#define SPI_COMMAND_B1_TEST_PATTERN_EN_CH1_4 {0x13, 0x00, 0x02}
#define SPI_COMMAND_B1_TEST_PATTERN_EN_CH5_8 {0x18, 0x00, 0x02}
#define SPI_COMMAND_B1_TEST_PATTERN_1OF4 {0x14, TP_A_2, TP_A_3}
#define SPI_COMMAND_B1_TEST_PATTERN_2OF4 {0x15, 0x00, TP_A_1}
#define SPI_COMMAND_B1_TEST_PATTERN_3OF4 {0x19, TP_B_2, TP_B_3}
#define SPI_COMMAND_B1_TEST_PATTERN_4OF4 {0x1A, 0x00, TP_B_1}

// clang-format on
#endif // ADC_HW_H_
