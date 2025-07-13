
/*
 *  PicoSoC - A simple example SoC using PicoRV32
 *
 *  Copyright (C) 2017  Claire Xenia Wolf <claire@yosyshq.com>
 *  Copyright (c) 2025  Lone Dynamics Corporation <info@lonedynamics.com>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

module spram_wb #(
	// We current always use the whole SPRAM (128 kB)
	parameter integer WORDS = 32768
) (
	input wb_clk_i,
	input wb_rst_i,
	input [29:0] wb_adr_i,
	input [31:0] wb_dat_i,
	output [31:0] wb_dat_o,
	input wb_we_i,
	input [3:0] wb_sel_i,
	input wb_stb_i,
	output wb_ack_o,
	input wb_cyc_i,
);

	wire cs_0, cs_1;
	wire [31:0] rdata_0, rdata_1;

	assign cs_0 = !wb_adr_i[14];
	assign cs_1 = wb_adr_i[14];
	assign wb_dat_o = wb_adr_i[14] ? rdata_1 : rdata_0;
	assign wb_ack_o = wb_cyc_i && wb_stb_i;

	SB_SPRAM256KA ram00 (
		.ADDRESS(wb_adr_i[13:0]),
		.DATAIN(wb_dat_i[15:0]),
		.MASKWREN({wb_sel_i[1], wb_sel_i[1], wb_sel_i[0], wb_sel_i[0]}),
		.WREN(wb_we_i),
		.CHIPSELECT(cs_0),
		.CLOCK(wb_clk_i),
		.STANDBY(1'b0),
		.SLEEP(1'b0),
		.POWEROFF(1'b1),
		.DATAOUT(rdata_0[15:0])
	);

	SB_SPRAM256KA ram01 (
		.ADDRESS(wb_adr_i[13:0]),
		.DATAIN(wb_dat_i[31:16]),
		.MASKWREN({wb_sel_i[3], wb_sel_i[3], wb_sel_i[2], wb_sel_i[2]}),
		.WREN(wb_we_i),
		.CHIPSELECT(cs_0),
		.CLOCK(wb_clk_i),
		.STANDBY(1'b0),
		.SLEEP(1'b0),
		.POWEROFF(1'b1),
		.DATAOUT(rdata_0[31:16])
	);

	SB_SPRAM256KA ram10 (
		.ADDRESS(wb_adr_i[13:0]),
		.DATAIN(wb_dat_i[15:0]),
		.MASKWREN({wb_sel_i[1], wb_sel_i[1], wb_sel_i[0], wb_sel_i[0]}),
		.WREN(wb_we_i),
		.CHIPSELECT(cs_1),
		.CLOCK(wb_clk_i),
		.STANDBY(1'b0),
		.SLEEP(1'b0),
		.POWEROFF(1'b1),
		.DATAOUT(rdata_1[15:0])
	);

	SB_SPRAM256KA ram11 (
		.ADDRESS(wb_adr_i[13:0]),
		.DATAIN(wb_dat_i[31:16]),
		.MASKWREN({wb_sel_i[3], wb_sel_i[3], wb_sel_i[2], wb_sel_i[2]}),
		.WREN(wb_we_i),
		.CHIPSELECT(cs_1),
		.CLOCK(wb_clk_i),
		.STANDBY(1'b0),
		.SLEEP(1'b0),
		.POWEROFF(1'b1),
		.DATAOUT(rdata_1[31:16])
	);

endmodule
