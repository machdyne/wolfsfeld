/*
 * Zucker GPU
 * Copyright (c) 2021 Lone Dynamics Corporation. All rights reserved.
 *
 * 32-bit dual-port VRAM for 128x32x1bpp framebuffer
 *
 */

module vram_wb #()
(
   input wb_clk_i,
   input wb_rst_i,
   input [14:0] wb_adr_i,
   input [31:0] wb_dat_i,
   output reg [31:0] wb_dat_o,
   input wb_we_i,
   input [3:0] wb_sel_i,
   input wb_stb_i,
   output wb_ack_o,
   input wb_cyc_i,

	input [11:0] gb_adr_i,
	output reg gb_pix_o,
);

	reg [31:0] vram [0:127];	// 128 x 32 / 32

	wire wb_active = wb_cyc_i && wb_stb_i;

	wire wb_ack_o = ack;
	reg ack;

	always @(posedge wb_clk_i) begin

		ack <= 0;

		if (wb_active) begin
			if (wb_we_i) begin
				if (wb_sel_i[0]) vram[wb_adr_i][7:0] <= wb_dat_i[7:0];
				if (wb_sel_i[1]) vram[wb_adr_i][15:8] <= wb_dat_i[15:8];
				if (wb_sel_i[2]) vram[wb_adr_i][23:16] <= wb_dat_i[23:16];
				if (wb_sel_i[3]) vram[wb_adr_i][31:24] <= wb_dat_i[31:24];
			end
			wb_dat_o <= vram[wb_adr_i];
			ack <= 1;
		end
	end

	wire [6:0] x = gb_adr_i[11:5];
	wire [4:0] y = gb_adr_i[4:0];
	reg [31:0] word;

	always @(posedge wb_clk_i) begin
		gb_pix_o <= word[y];
		word <= vram[x];
	end

endmodule
