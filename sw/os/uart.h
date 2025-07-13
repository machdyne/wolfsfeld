#ifndef Z_UART_H
#define Z_UART_H

void z_uart_init(void);
void z_uart_irq(void);

void k_uart_putc(char c);
int16_t k_uart_getc(void);
bool k_uart_rx_empty(void);
bool k_uart_tx_full(void);

#endif
