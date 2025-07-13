/*
 * Wolfsfeld SOC
 * Copyright (c) 2025 Lone Dynamics Corporation. All rights reserved.
 *
 */

extern char _start, _end;

#include <stdio.h>
#include <stdbool.h>
#include "kruntime.h"
#include "kernel.h"
#include "uart.h"

// --

void sh(void);
uint32_t *z_kernel_entry(uint32_t mode, uint32_t *args, uint32_t val);

// --

void delay() {
   volatile static int x, y;
   for (int i = 0; i < 500; i++) {
      x += y;
   }
}

int main(void) {

	uint8_t leds = 0;

	// set the kernel register so the irq handler knows who to call
	reg_kernel = (uint32_t)(uintptr_t)z_kernel_entry;

	while (1) {
		reg_leds = leds++;
		reg_led = 0xff;
//		k_uart_putc('A');
		delay();
		reg_led = 0x00;
		delay();
	}

	printf("Wolfsfeld OS\n");


	// the kernel shell is process zero
	sh();

}

// this is called by the BIOS interrupt handler
// it uses the interrupt stack
uint32_t *z_kernel_entry(uint32_t mode, uint32_t *regs, uint32_t irqs) {

   if ((irqs & (1 << Z_IRQ_UART)) != 0) {
      z_uart_irq();
   }

	return regs;

}
