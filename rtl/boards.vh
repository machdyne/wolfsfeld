// UNIVERSAL CONFIG
// ----------------

`define DEBUG

// BOARD CONFIG
// ------------

`ifdef BOARD_WOLFSFELD

`define FPGA_ICE40
`define MEM_SPRAM
`define MEM_FLASH
`define MEM_VRAM
`define RTC
`define POWER
`define I2C
`define DISP_OLED
`define UART0
//`define VIDEO

`endif
