/*
 * Wolfsfeld BIOS
 * Copyright (c) 2025 Lone Dynamics Corporation. All rights reserved.
 *
 */

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>

#define SSD1306_I2C_ADDR 0x3c
#define SSD1306_WIDTH 128
#define SSD1306_HEIGHT 32
#define SSD1306_PAGES (SSD1306_HEIGHT / 8)

#define reg_uart0_data (*(volatile uint8_t*)0xf0000000)
#define reg_uart0_dlbl (*(volatile uint8_t*)0xf0000000)
#define reg_uart0_dlbh (*(volatile uint8_t*)0xf0000004)
#define reg_uart0_ier (*(volatile uint8_t*)0xf0000004)
#define reg_uart0_fcr (*(volatile uint8_t*)0xf0000008)
#define reg_uart0_iir (*(volatile uint8_t*)0xf0000008)
#define reg_uart0_lcr (*(volatile uint8_t*)0xf000000c)
#define reg_uart0_mcr (*(volatile uint8_t*)0xf0000010)
#define reg_uart0_lsr (*(volatile uint8_t*)0xf0000014)
#define reg_uart0_msr (*(volatile uint8_t*)0xf0000018)

#define reg_led (*(volatile uint8_t*)0xe0000000)
#define reg_leds (*(volatile uint8_t*)0xe0000004)

#define reg_disp (*(volatile uint32_t*)0xc0000000)

#define reg_rtc (*(volatile uint32_t*)0xd0000000)
#define reg_power (*(volatile uint32_t*)0xb0000000)

#define MEM_BIOS			0x00000000
#define MEM_BIOS_SIZE	(8 * 1024)

#define MEM_VRAM			0x20000000
#define MEM_VRAM_SIZE	512

#define MEM_FLASH			0x80000000
#define MEM_FLASH_SIZE	(1024 * 1024 * 4)

#define MEM_FLASH_OS		0x80040000
#define MEM_FLASH_OS_SIZE	(1024 * 128)

#define MEM_MAIN			0x40000000
#define MEM_MAIN_SIZE	(1024 * 128)

#include "font8x8_basic.h"

#define FRAMEBUFFER_WIDTH 128
#define FRAMEBUFFER_HEIGHT 32
#define FRAMEBUFFER_ADDRESS 0x20000000

// Treat framebuffer as pointer to 32-bit words
volatile uint32_t* framebuffer = (uint32_t*)0x20000000;

// Set or clear a single pixel at (x,y)
void set_pixel(uint8_t x, uint8_t y, uint8_t value) {
    if (x >= SSD1306_WIDTH || y >= SSD1306_HEIGHT) return;

    uint8_t page = y / 8;
    uint8_t bit_pos = y % 8;

    // Calculate word index: each word covers 4 bytes (columns)
    uint16_t word_index = page * (SSD1306_WIDTH / 4) + (x / 4);
    uint8_t byte_in_word = x % 4;  // which byte inside the 32-bit word

    uint32_t orig = framebuffer[word_index];
    uint8_t byte_val = (orig >> (byte_in_word * 8)) & 0xFF;

    if (value) {
        byte_val |= (1 << bit_pos);
    } else {
        byte_val &= ~(1 << bit_pos);
    }

    // Clear the original byte and set the new value
    uint32_t mask = 0xFF << (byte_in_word * 8);
    uint32_t new_val = (orig & ~mask) | ((uint32_t)byte_val << (byte_in_word * 8));

    framebuffer[word_index] = new_val;
}

// Draw character c at (x,y) top-left corner
void draw_char(char c, uint8_t x, uint8_t y) {
    if (x > SSD1306_WIDTH - 8 || y > SSD1306_HEIGHT - 8) return;

    // For each pixel in 8x8 character block
    for (uint8_t row = 0; row < 8; row++) {
        uint8_t row_data = font8x8_basic[(uint8_t)c][row];
        for (uint8_t col = 0; col < 8; col++) {
            uint8_t pixel_on = (row_data >> col) & 1;
            set_pixel(x + col, y + row, pixel_on);
        }
    }
}

// Draw a string at (x, y), no line wrapping
void draw_string(const char* str, uint8_t x, uint8_t y) {
    while (*str && x <= FRAMEBUFFER_WIDTH - 8) {
        draw_char(*str++, x, y);
        x += 8;
    }
}

// Optional: clear framebuffer (set all pixels to 0)
void clear_framebuffer() {
    for (int i = 0; i < (FRAMEBUFFER_WIDTH * FRAMEBUFFER_HEIGHT) / 32; i++) {
        framebuffer[i] = 0;
    }
}

// ---

uint16_t curs_x = 0;
uint16_t curs_y = 0;

uint32_t addr_ptr;
uint32_t mem_total;

// --------------------------------------------------------

uint32_t xfer_recv(uint32_t addr);
uint32_t crc32b(char *data, uint32_t len);
void putchar_vga(const char c);
char scantoascii(uint8_t scancode);
char hidtoascii(uint8_t code);

void print_hex(uint32_t v, int digits);
void memtest(uint32_t addr_ptr, uint32_t mem_total);
void memcpy(uint32_t dest, uint32_t src, uint32_t n);

int vid_cols;
int vid_rows;
int vid_hres;
int vid_vres;

// --------------------------------------------------------


int putchar(int c)
{
	while ((reg_uart0_lsr & 0x20) == 0);
	if (c == '\n')
		putchar('\r');

	reg_uart0_data = (char)c;

	return c;
}

void print(const char *p)
{
	while (*p)
		putchar(*(p++));
}

int getchar()
{
	int uart_dr = ((reg_uart0_lsr & 0x01) == 1);

	if (!uart_dr) {
		return EOF;
	} else {
		return reg_uart0_data;
	}
}

void getchars(char *buf, int len) {
	int c;
	for (int i = 0; i < len; i++) {
		while ((c = getchar()) == EOF);
		buf[i] = (char)c;
	};
}

uint32_t xfer_recv(uint32_t addr_ptr)
{

	uint32_t addr = addr_ptr;
	uint32_t bytes = 0;
	uint32_t crc_ours;
	uint32_t crc_theirs;

	char buf_data[252];
	char buf_crc[4];

	int cmd;
	int datasize;

	print("xfer addr 0x");
	print_hex(addr, 8);
	print("\n");

	while (1) {

		while ((cmd = getchar()) == EOF);
		buf_data[0] = (uint8_t)cmd;

		if ((char)cmd == 'L') {
			while ((datasize = getchar()) == EOF);
			buf_data[1] = (uint8_t)datasize;
			getchars(&buf_data[2], datasize);
			getchars(buf_crc, 4);
			crc_ours = crc32b(buf_data, datasize + 2);
			crc_theirs = buf_crc[0] | (buf_crc[1] << 8) |
				(buf_crc[2] << 16) | (buf_crc[3] << 24);
			if (crc_ours == crc_theirs) {
				for (int i = 0; i < datasize; i++) {
					(*(volatile uint8_t *)(addr + i)) = buf_data[2 + i];
				}
				addr += datasize;
				bytes += datasize;
				putchar('A');
			} else {
				putchar('N');
			}
		}

		if ((char)cmd == 'D') {
			break;
		}

	}

	return bytes;

}

uint32_t crc32b(char *data, uint32_t len) {

	uint32_t byte, crc, mask;

	crc = 0xffffffff;
	for (int i = 0; i < len; i++) {
		byte = data[i];
		crc = crc ^ byte;
		for (int j = 7; j >= 0; j--) {
			mask = -(crc & 1);
			crc = (crc >> 1) ^ (0xedb88320 & mask);
		}
	}
	return ~crc;
}

void cmd_echo() {
	int c;

	while (1) {
		if ((c = getchar()) != EOF) {
			if ((char)c == '0') return;
			putchar(c);
		}
	}

}

void cmd_info() {

	uint8_t tmp;
	uint32_t tmp32;

	print("led: 0x");
	tmp = reg_led;
	print_hex(tmp, 2);
	print("\n");
/*
	print("rtc: 0x");
	tmp32 = reg_rtc;
	print_hex(tmp32, 8);
	print("\n");
*/

}

void cmd_dump_bytes() {

	uint32_t addr = addr_ptr;
	uint8_t tmp;

	for (int i = 0; i < 16; i++) {
		print_hex(addr, 8);
		print(" ");
		for (int x = 0; x < 16; x++) {
			tmp = (*(volatile uint8_t *)addr);
			print_hex(tmp, 2);
			print(" ");
			addr += 1;
		}
		print("\n");
	}

}

void cmd_dump_words() {

	uint32_t addr = addr_ptr;
	uint32_t tmp;

	for (int i = 0; i < 16; i++) {
		print_hex(addr, 8);
		print(" ");
		for (int x = 0; x < 4; x++) {
			tmp = (*(volatile uint32_t *)addr);
			print_hex(tmp, 8);
			print(" ");
			addr += 4;
		}
		print("\n");
	}

}

void cmd_memzero()
{
	print("zeroing ... ");
   volatile uint32_t *addr = (uint32_t *)addr_ptr;
	for (int i = 0; i < (mem_total / sizeof(int)); i++) {
		(*(volatile uint32_t *)(addr + i)) = 0x00000000;
	}
	print("done.\n");
}

void cmd_memhigh(int q)
{
	print("zeroing ... ");
   volatile uint32_t *addr = (uint32_t *)addr_ptr;
	for (int i = 0; i < (mem_total / sizeof(int)); i++) {
		if (q)
			(*(volatile uint32_t *)(addr + i)) = 0x12345678;
		else
			(*(volatile uint32_t *)(addr + i)) = 0xffffffff;
	}
	print("done.\n");
}

void memcpy(uint32_t dest, uint32_t src, uint32_t n) {
   volatile uint32_t *from = (uint32_t *)src;
   volatile uint32_t *to = (uint32_t *)dest;
	for (int i = 0; i < (n / sizeof(uint32_t)); i++) {
		(*(volatile uint32_t *)(to + i)) = *(from + i);
	}
}

//
// --------------------------------------------------------

void cmd_help() {
/*
	print("\n [0] toggle address\n");
	print(" [D] dump memory as bytes\n");
	print(" [W] dump memory as words\n");
	print(" [9] reset memory page\n");
	print(" [ ] next memory page\n");
	print(" [I] system info\n");
	print(" [M] test memory\n");
	print(" [Z] zero memory\n");
	print(" [F] fill memory with pattern\n");
	print(" [X] receive to memory (xfer)\n");
	print(" [1] led on\n");
	print(" [2] led off\n");
	print(" [B] boot to 0x40000000\n");
	print(" [E] echo mode (exit with 0)\n");
	print(" [H] help\n\n");
*/
}

void cmd_toggle_addr_ptr(void) {

	if (addr_ptr == MEM_BIOS) {
		addr_ptr = MEM_VRAM;
		mem_total = MEM_VRAM_SIZE;
	} else if (addr_ptr == MEM_VRAM) {
		addr_ptr = MEM_MAIN;
		mem_total = MEM_MAIN_SIZE;
	} else if (addr_ptr == MEM_MAIN) {
		addr_ptr = MEM_FLASH;
		mem_total = MEM_FLASH_SIZE;
	} else if (addr_ptr == MEM_FLASH) {
		addr_ptr = MEM_FLASH_OS;
		mem_total = MEM_FLASH_OS_SIZE;
	} else if (addr_ptr == MEM_FLASH_OS) {
		addr_ptr = MEM_BIOS;
		mem_total = MEM_BIOS_SIZE;
	}

}

void cmd_xfer() {
	uint32_t b = xfer_recv(addr_ptr);
	print("xfer received ");
	print_hex(b, 8);
	print(" bytes at ");
	print_hex(addr_ptr, 8);
	print("\n");
}

void uart_init() {

	// 24_000_000 / 13 = ~1846153 = 16 x 115200
	//uint16_t baud_rate_divisor = 13;	// clock / divisor = 16 x baud rate

	// 16_000_000 / 1 = 1600000 = 16 x 1000000
	uint16_t baud_rate_divisor = 1;	// clock / divisor = 16 x baud rate

	// set LCR
	reg_uart0_lcr = (uint8_t)0b10000011;	// access divisor latch; 8n1

	// set divisor latch
	reg_uart0_dlbh = (uint8_t)((baud_rate_divisor >> 8) & 0xff);
	reg_uart0_dlbl = (uint8_t)(baud_rate_divisor & 0xff);

	reg_uart0_lcr = (uint8_t)0b00000011;	// disable divisor latch

	reg_uart0_fcr = (uint8_t)0b00000111;	// enable fifos; trigger 1 byte
	reg_uart0_ier = (uint8_t)0b00000000;	// disable all interrupts
	//reg_uart0_ier = (uint8_t)0b00001111;	// enable all interrupts

}

void delay() {
	volatile static int x, y;
	for (int i = 0; i < 5000; i++) {
		x += y;
	}
}

// --

void disp_sda_high() { reg_disp |= 0x01; }
void disp_sda_low() { reg_disp &= ~(1 << 0); }
void disp_scl_high() { reg_disp |= 0x02; }
void disp_scl_low() { reg_disp &= ~(1 << 1); }

#define disp_delay()

//void disp_delay() {
//	__asm__ volatile ("nop");
//}

void disp_start() {
	disp_sda_high(); disp_scl_high(); disp_delay();
	disp_sda_low();  disp_delay();
	disp_scl_low();  disp_delay();
}

void disp_stop() {
	disp_sda_low();  disp_scl_high(); disp_delay();
	disp_sda_high(); disp_delay();
}

void disp_write_byte(uint8_t byte) {
	for (int i = 0; i < 8; i++) {
		(byte & 0x80) ? disp_sda_high() : disp_sda_low();
		disp_scl_high(); disp_delay();
		disp_scl_low();  disp_delay();
		byte <<= 1;
	}
    // Skip ACK: just release SDA and toggle SCL
	disp_sda_high(); disp_scl_high(); disp_delay();
	disp_scl_low();  disp_delay();
}

void disp_cmd(uint8_t cmd) {
	disp_start();
	disp_write_byte(SSD1306_I2C_ADDR << 1); // write mode
	disp_write_byte(0x00); // Control byte for command
	disp_write_byte(cmd);
	disp_stop();
}

// Send framebuffer (128x32 = 512 bytes)
void disp_send_buffer() {

	for (uint8_t page = 0; page < 4; page++) {
		disp_cmd(0xB0 + page);       // Page address
		disp_cmd(0x00);              // Lower column address
		disp_cmd(0x10);              // Higher column address

		disp_stop();
		disp_start();
		disp_write_byte(SSD1306_I2C_ADDR << 1);
		disp_write_byte(0x40); // Control byte for data

		uint8_t *vram_ptr = (uint8_t *)MEM_VRAM + (page * 128);

		for (uint8_t col = 0; col < 128; col += 4) {
			uint32_t word = *(volatile uint32_t *)(vram_ptr + col);
			disp_write_byte(word & 0xFF);
			disp_write_byte((word >> 8) & 0xFF);
			disp_write_byte((word >> 16) & 0xFF);
			disp_write_byte((word >> 24) & 0xFF);
		}

		disp_stop();

	}

}

void disp_init() {
    disp_cmd(0xAE); // Display OFF
    disp_cmd(0xD5); disp_cmd(0x80); // Clock
    disp_cmd(0xA8); disp_cmd(0x1F); // Multiplex 32
    disp_cmd(0xD3); disp_cmd(0x00); // Display offset
    disp_cmd(0x40); // Start line
    disp_cmd(0x8D); disp_cmd(0x14); // Charge pump
    disp_cmd(0x20); disp_cmd(0x02); // Memory mode
    disp_cmd(0xA1); // Segment remap
    disp_cmd(0xC8); // COM scan direction
    disp_cmd(0xDA); disp_cmd(0x02); // COM pins
    disp_cmd(0x81); disp_cmd(0xCF); // Contrast
    disp_cmd(0xD9); disp_cmd(0xF1); // Precharge
    disp_cmd(0xDB); disp_cmd(0x40); // VCOM detect
    disp_cmd(0xA4); // Entire display ON
    disp_cmd(0xA6); // Normal display
    disp_cmd(0x2e); // Disable scroll
    disp_cmd(0xAF); // Display ON
}

void draw_font() {

	uint8_t *vram_ptr = (uint8_t *)MEM_VRAM;

	for (int y = 0; y < 8; y++) {
		*(volatile uint8_t *)(vram_ptr + y * 8) = font8x8_basic[65][y];
	}

}

// --

void main() {

	int cmd;

	reg_led = 0x00;

/*
	while (1) {

		reg_led = 0xff;
		for (volatile int i = 0; i < 10000; i++);
		reg_led = 0x00;
		for (volatile int i = 0; i < 10000; i++);

	}
*/

	addr_ptr = MEM_MAIN;
	mem_total = MEM_MAIN_SIZE;

	uart_init();

	print("WF\n");

	print("disp_init\n");
	disp_init();

	draw_string("WOLFSFELD", 0, 0);
	draw_string("ABCDEFGHIJKLMNOP", 0, (1*8));
	draw_string("0123456789012345", 0, (2*8));
	draw_string("ABCDEFGHIJKLMNOP", 0, (3*8));
	disp_send_buffer();

//	cmd_info();
//	cmd_help();

	while (1) {

		print("@");
		print_hex(addr_ptr, 8);
		print("> ");

		while ((cmd = getchar()) == EOF) continue;

		print("\n");

		switch (cmd) {
			case 'h':
			case 'H':
				cmd_help();
				break;
			case '0':
				cmd_toggle_addr_ptr();
				break;
			case '1':
				reg_led = 0x01;
				break;
			case '2':
				reg_led = 0x00;
				break;
			case '9':
				addr_ptr = 0x40000000;
				break;
			case ' ':
				addr_ptr += 256;
				break;
			case 'x':
			case 'X':
				cmd_xfer();
				break;
			case 'i':
			case 'I':
				cmd_info();
				break;
			case 'd':
			case 'D':
				cmd_dump_bytes();
				break;
			case 'o':
			case 'O':
				disp_send_buffer();
				break;
			case 'w':
			case 'W':
				cmd_dump_words();
				break;
			case 'm':
			case 'M':
				memtest(addr_ptr, mem_total);
				break;
			case 'b':
			case 'B':
				print("booting ... ");
				return;
				break;
			case 'e':
			case 'E':
				cmd_echo();
				break;
			case 'z':
			case 'Z':
				cmd_memzero();
				break;
			case 'f':
				cmd_memhigh(1);
				break;
			case 'F':
				cmd_memhigh(0);
				break;
			case 'y':
			case 'Y':
				reg_power = 0xff;
				break;
			case 'q':
			case 'Q':
				draw_string("WOLFSFELD", 0, 0);
				draw_string("ABCDEFGHIJKLMNOP", 0, (1*8));
				draw_string("0123456789012345", 0, (2*8));
				draw_string("ABCDEFGHIJKLMNOP", 0, (3*8));
				break;
			default:
				continue;
		}

	}

}
