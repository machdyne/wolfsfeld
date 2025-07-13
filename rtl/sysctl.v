/*
 * Wolfsfeld SOC
 * Copyright (c) 2025 Lone Dynamics Corporation. All rights reserved.
 *
 * System Controller (top)
 *
 */

`include "boards.vh"

module sysctl #()
(

	input K1, K2, K3, K4,
	output L1, L2, L3, L4,
	output LED_R, LED_G, LED_B,

`ifdef DISP_OLED
	inout DISP_SDA,
	inout DISP_SCL,
`endif

`ifdef MEM_FLASH
`ifdef MEM_FLASH_PMOD
	output PMOD_A1,
	output PMOD_A2,
	input PMOD_A3,
	output PMOD_A4,
`else
	output CSPI_SS,
	output CSPI_SCK,
	output CSPI_MOSI,
	input CSPI_MISO,
`endif
`endif

`ifdef VIDEO
	output DAC_D3, DAC_D2, DAC_D1, DAC_D0,
`endif

`ifdef UART0
	input GPIOX,
	output GPIOY
`endif

);

	// BOARD LEDS

	assign LED_R = !cpu_trap;
	assign LED_G = !(power_mode == 0);

	// KEYBOARD LEDS

	assign L1 = ~K1;
	assign L2 = ~K2;
	assign L3 = ~K3;
	assign L4 = ~K4;

	// POWER MANAGEMENT

	wire power_mode;

	// CLOCKS
	wire sys_clk;
	wire clk48mhz;
	wire clk32mhz;
	wire clk10khz;

	wire hfosc_en = (power_mode == 0);

	SB_HFOSC hfosc_i (
		.CLKHFPU(hfosc_en),
		.CLKHFEN(hfosc_en),
		.CLKHF(clk48mhz)
	);

	SB_LFOSC lfosc_i (
		.CLKLFPU(1'b1),
		.CLKLFEN(1'b1),
		.CLKLF(clk10khz)
	);

	wire pll_locked;

	vid_pll #() vid_pll_i
	(
		.clock_in(clk48mhz),
		.clock_out(clk32mhz),
		.locked(pll_locked)
	);

	reg clk16mhz = 0;

	always @(posedge clk32mhz) begin
		clk16mhz <= ~clk16mhz;
	end

	SB_GB clk_buf (
		.USER_SIGNAL_TO_GLOBAL_BUFFER(clk16mhz),
		.GLOBAL_BUFFER_OUTPUT(sys_clk)
	);

	// RESET

	reg [11:0] resetn_counter = 0;
	wire sys_rstn = &resetn_counter;

	always @(posedge sys_clk) begin
		if (!pll_locked)
			resetn_counter <= 0;
		else if (!sys_rstn)
			resetn_counter <= resetn_counter + 1;
	end

	// INTERRUPTS

	reg irq_timer;

	always @* begin
		cpu_irq = 0;
		cpu_irq[3] = wbs_rtc_int;
		cpu_irq[4] = wbs_uart0_int;
	end

	// VIDEO

`ifdef VIDEO
	wire [11:0] gb_adr;
	wire gb_pix;

	vid_ntsc #() vid_ntsc_i
	(
		.clk32mhz(clk32mhz),
		.pix(gb_pix),
		.adr(gb_adr),
		.dac({DAC_D3, DAC_D2, DAC_D1, DAC_D0})
	);
`endif

	// WISHBONE BUS

	wire wbm_clk = sys_clk;
	wire wbm_rst = !sys_rstn;

	wire [27:0] wbm_adr_sel = (wbm_adr & 32'h0fff_ffff);
	wire [25:0] wbm_adr_sel_word = wbm_adr_sel[27:2];

	wire [31:0] wbs_bram_dat_o;
	wire [31:0] wbs_vram_dat_o;
	wire [31:0] wbs_spram_dat_o;
	wire [31:0] wbs_flash_dat_o;
	wire [31:0] wbs_debug_dat_o;
	wire [31:0] wbs_i2c_dat_o;
	wire [31:0] wbs_rtc_dat_o;
	wire [31:0] wbs_power_dat_o;
	wire [31:0] wbs_uart0_dat_o;

	wire cs_bram = (wbm_adr < 8192);

`ifdef MEM_VRAM
	wire cs_vram = ((wbm_adr & 32'hf000_0000) == 32'h2000_0000);
`endif
`ifdef MEM_SPRAM
	wire cs_spram = ((wbm_adr & 32'hf000_0000) == 32'h4000_0000);
`endif
`ifdef MEM_FLASH
	wire cs_flash = ((wbm_adr & 32'hf000_0000) == 32'h8000_0000);
`endif
`ifdef DEBUG
	wire cs_debug = ((wbm_adr & 32'hf000_0000) == 32'he000_0000);
`endif
`ifdef I2C
	wire cs_i2c = ((wbm_adr & 32'hf000_0000) == 32'hc000_0000);
`endif
`ifdef RTC
	wire cs_rtc = ((wbm_adr & 32'hf000_0000) == 32'hd000_0000);
`endif
`ifdef POWER
	wire cs_power = ((wbm_adr & 32'hf000_0000) == 32'hb000_0000);
`endif
`ifdef UART0
	wire cs_uart0 = ((wbm_adr & 32'hf000_0000) == 32'hf000_0000);
`endif

	assign wbm_dat_i =
		cs_bram ? wbs_bram_dat_o :
`ifdef MEM_VRAM
		cs_vram ? wbs_vram_dat_o :
`endif
`ifdef MEM_SPRAM
		cs_spram ? wbs_spram_dat_o :
`endif
`ifdef MEM_FLASH
		cs_flash ? wbs_flash_dat_o :
`endif
`ifdef DEBUG
		cs_debug ? wbs_debug_dat_o :
`endif
`ifdef I2C
		cs_i2c ? wbs_i2c_dat_o :
`endif
`ifdef RTC
		cs_rtc ? wbs_rtc_dat_o :
`endif
`ifdef POWER
		cs_power ? wbs_power_dat_o :
`endif
`ifdef UART0
		cs_uart0 ? wbs_uart0_dat_o :
`endif
		32'hzzzz_zzzz;

	wire wbs_bram_ack_o;
	wire wbs_vram_ack_o;
	wire wbs_spram_ack_o;
	wire wbs_flash_ack_o;
	wire wbs_debug_ack_o;
	wire wbs_i2c_ack_o;
	wire wbs_rtc_ack_o;
	wire wbs_power_ack_o;
	wire wbs_uart0_ack_o;

	assign wbm_ack =
		cs_bram ? wbs_bram_ack_o :
`ifdef MEM_VRAM
		cs_vram ? wbs_vram_ack_o :
`endif
`ifdef MEM_SPRAM
		cs_spram ? wbs_spram_ack_o :
`endif
`ifdef MEM_FLASH
		cs_flash ? wbs_flash_ack_o :
`endif
`ifdef DEBUG
		cs_debug ? wbs_debug_ack_o :
`endif
`ifdef I2C
		cs_i2c ? wbs_i2c_ack_o :
`endif
`ifdef RTC
		cs_rtc ? wbs_rtc_ack_o :
`endif
`ifdef POWER
		cs_power ? wbs_power_ack_o :
`endif
`ifdef UART0
		cs_uart0 ? wbs_uart0_ack_o :
`endif
		1'b0;

	// WISHBONE MASTER: CPU

   wire cpu_trap;
   reg [31:0] cpu_irq = 0;

	wire [31:0] wbm_adr;
	wire [31:0] wbm_dat_o;
	wire [31:0] wbm_dat_i;
	wire [3:0] wbm_sel;
	wire wbm_we;
	wire wbm_stb;
	wire wbm_ack;
	wire wbm_cyc;

	localparam BRAM_WORDS = 2048;

	picorv32_wb #(
      .STACKADDR(BRAM_WORDS * 4),      // end of BRAM
      .PROGADDR_RESET(32'h0000_0000),
      .PROGADDR_IRQ(32'h0000_0010),
      .BARREL_SHIFTER(1),
      .COMPRESSED_ISA(0),
      .ENABLE_MUL(0),
      .ENABLE_DIV(0),
      .ENABLE_IRQ(1),
      .ENABLE_IRQ_TIMER(0),
      .ENABLE_IRQ_QREGS(1),
		.LATCHED_IRQ(32'b1111_1111_1111_1111_1111_1111_1110_1111)
	)
	wbm_cpu0_i
	(
		.wb_clk_i(wbm_clk),
		.wb_rst_i(wbm_rst),
		.wbm_adr_o(wbm_adr),
		.wbm_dat_o(wbm_dat_o),
		.wbm_dat_i(wbm_dat_i),
		.wbm_we_o(wbm_we),
		.wbm_sel_o(wbm_sel),
		.wbm_stb_o(wbm_stb),
		.wbm_ack_i(wbm_ack),
		.wbm_cyc_o(wbm_cyc),
		.trap(cpu_trap),
		.irq(cpu_irq)
	);

	// WISHBONE SLAVE: BLOCK RAM (BIOS)

	wire wbm_cyc_bram = cs_bram && wbm_cyc;

	bram_wb #() wbs_bram0_i
	(
      .wb_clk_i(wbm_clk),
      .wb_rst_i(wbm_rst),
      .wb_adr_i(wbm_adr_sel_word),
      .wb_dat_i(wbm_dat_o),
      .wb_dat_o(wbs_bram_dat_o),
      .wb_we_i(wbm_we),
      .wb_sel_i(wbm_sel),
      .wb_stb_i(wbm_stb),
      .wb_ack_o(wbs_bram_ack_o),
      .wb_cyc_i(wbm_cyc_bram),
	);

	// WISHBONE SLAVE: DUAL-PORT VRAM (FRAMEBUFFER)
`ifdef MEM_VRAM
	wire wbm_cyc_vram = cs_vram && wbm_cyc;
	reg [31:0] gb_dat;

	vram_wb #() wbs_vram_i
	(
		.wb_clk_i(wbm_clk),
		.wb_rst_i(wbm_rst),
		.wb_adr_i(wbm_adr_sel_word),
		.wb_dat_i(wbm_dat_o),
		.wb_dat_o(wbs_vram_dat_o),
		.wb_we_i(wbm_we),
		.wb_sel_i(wbm_sel),
		.wb_stb_i(wbm_stb),
		.wb_ack_o(wbs_vram_ack_o),
		.wb_cyc_i(wbm_cyc_vram),
`ifdef VIDEO
		.gb_adr_i(gb_adr),
		.gb_pix_o(gb_pix),
`endif
	);
`endif

	// WISHBONE SLAVE: SPRAM (MAIN MEMORY)
`ifdef MEM_SPRAM
	wire wbm_cyc_spram = cs_spram && wbm_cyc;

	spram_wb #() wb_spram_i
	(
		.wb_clk_i(wbm_clk),
		.wb_rst_i(wbm_rst),
		.wb_adr_i(wbm_adr_sel_word),
		.wb_dat_i(wbm_dat_o),
		.wb_dat_o(wbs_spram_dat_o),
		.wb_we_i(wbm_we),
		.wb_sel_i(wbm_sel),
		.wb_stb_i(wbm_stb),
		.wb_ack_o(wbs_spram_ack_o),
		.wb_cyc_i(wbm_cyc_spram),
	);
`endif

	// WISHBONE SLAVE: SPI MEM_FLASH (MMOD)
`ifdef MEM_FLASH
	wire wbm_cyc_flash = cs_flash && wbm_cyc;

	spiflashro_wb #() wb_spiflashro_i
	(
		.wb_clk_i(wbm_clk),
		.wb_rst_i(wbm_rst),
		.wb_adr_i(wbm_adr_sel),
		.wb_dat_i(wbm_dat_o),
		.wb_dat_o(wbs_flash_dat_o),
		.wb_we_i(wbm_we),
		.wb_sel_i(wbm_sel),
		.wb_stb_i(wbm_stb),
		.wb_ack_o(wbs_flash_ack_o),
		.wb_cyc_i(wbm_cyc_flash),
`ifdef MEM_FLASH_PMOD
		.ss(PMOD_A1),
		.sck(PMOD_A4),
		.mosi(PMOD_A2),
		.miso(PMOD_A3)
`else
		.ss(CSPI_SS),
		.sck(CSPI_SCK),
		.mosi(CSPI_MOSI),
		.miso(CSPI_MISO)
`endif
	);
`endif

	// WISHBONE SLAVE: LED DEBUG INTERFACE
`ifdef DEBUG
	wire wbm_cyc_debug = cs_debug && wbm_cyc;

	debug_wb #() wbs_debug0_i
	(
		.wb_clk_i(wbm_clk),
		.wb_rst_i(wbm_rst),
		.wb_adr_i(wbm_adr_sel_word),
		.wb_dat_i(wbm_dat_o),
		.wb_dat_o(wbs_debug_dat_o),
		.wb_we_i(wbm_we),
		.wb_sel_i(wbm_sel),
		.wb_stb_i(wbm_stb),
		.wb_ack_o(wbs_debug_ack_o),
		.wb_cyc_i(wbm_cyc_debug),
		.led(LED_B),
	);
`endif

	// WISHBONE SLAVE: I2C BIT-BANG INTERFACE
`ifdef I2C
	wire wbm_cyc_i2c = cs_i2c && wbm_cyc;

	i2c_wb #() wbs_i2c0_i
	(
		.wb_clk_i(wbm_clk),
		.wb_rst_i(wbm_rst),
		.wb_adr_i(wbm_adr_sel_word),
		.wb_dat_i(wbm_dat_o),
		.wb_dat_o(wbs_i2c_dat_o),
		.wb_we_i(wbm_we),
		.wb_sel_i(wbm_sel),
		.wb_stb_i(wbm_stb),
		.wb_ack_o(wbs_i2c_ack_o),
		.wb_cyc_i(wbm_cyc_i2c),
		.sda(DISP_SDA),
		.scl(DISP_SCL),
	);
`endif

	// WISHBONE SLAVE: UART0
`ifdef UART0
	reg wbs_uart0_int;
	wire wbm_cyc_uart0 = cs_uart0 && wbm_cyc;
	wire wbm_stb_uart0 = cs_uart0 && wbm_stb;

	uart_top #() wbs_uart0_i
	(
		.wb_clk_i(wbm_clk),
		.wb_rst_i(wbm_rst),
		.wb_adr_i(wbm_adr_sel_word),
		.wb_dat_i(wbm_dat_o),
		.wb_dat_o(wbs_uart0_dat_o),
		.wb_we_i(wbm_we),
		.wb_sel_i(wbm_sel),
		.wb_stb_i(wbm_stb_uart0),
		.wb_ack_o(wbs_uart0_ack_o),
		.wb_cyc_i(wbm_cyc_uart0),
		.stx_pad_o(GPIOY),
		.srx_pad_i(GPIOX),
		.cts_pad_i(1'b1),
		.dsr_pad_i(1'b1),
		.ri_pad_i(1'b1),
		.dcd_pad_i(1'b1),
		.int_o(wbs_uart0_int)
	);
`endif

	// WISHBONE SLAVE: RTC
`ifdef RTC
	reg wbs_rtc_int;
	wire wbm_cyc_rtc = cs_rtc && wbm_cyc;

	rtc_wb #() wbs_rtc0_i
	(
		.wb_clk_i(wbm_clk),
		.wb_rst_i(wbm_rst),
		.wb_adr_i(wbm_adr_sel_word),
		.wb_dat_i(wbm_dat_o),
		.wb_dat_o(wbs_rtc_dat_o),
		.wb_we_i(wbm_we),
		.wb_sel_i(wbm_sel),
		.wb_stb_i(wbm_stb),
		.wb_ack_o(wbs_rtc_ack_o),
		.wb_cyc_i(wbm_cyc_rtc),
		.clk10khz(clk10khz),
		.int_o(wbs_rtc_int)
	);
`endif

	// WISHBONE SLAVE: POWER MANAGEMENT
`ifdef POWER
	wire wbm_cyc_power = cs_power && wbm_cyc;

	wire wake = |{~K1, ~K2, ~K3, ~K4};

	power_wb #() wbs_power0_i
	(
		.wb_clk_i(wbm_clk),
		.wb_rst_i(wbm_rst),
		.wb_adr_i(wbm_adr_sel_word),
		.wb_dat_i(wbm_dat_o),
		.wb_dat_o(wbs_power_dat_o),
		.wb_we_i(wbm_we),
		.wb_sel_i(wbm_sel),
		.wb_stb_i(wbm_stb),
		.wb_ack_o(wbs_power_ack_o),
		.wb_cyc_i(wbm_cyc_power),
		.clk10khz(clk10khz),
		.power_mode(power_mode),
		.wake(wake)
	);
`else
	assign power_mode = 0;
`endif

endmodule
