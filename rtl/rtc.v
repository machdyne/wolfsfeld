/*
 * RTC
 * Copyright (c) 2025 Lone Dynamics Corporation. All rights reserved.
 *
 * Real-time clock.
 *
 * The RTC continues running when the device is suspended.
 *
 */

module rtc_wb #()
(
	input wb_clk_i,
	input wb_rst_i,
	input [31:0] wb_adr_i,
	input [31:0] wb_dat_i,
	output reg [31:0] wb_dat_o,
	input wb_we_i,
	input [3:0] wb_sel_i,
	input wb_stb_i,
	output wb_ack_o,
	input wb_cyc_i,
	input clk10khz,
	output int_o,
);

	assign wb_ack_o = ack;

	reg [31:0] uptime;

	reg [7:0] ictr;
	reg [13:0] sctr;
	reg ack;

	reg int;
	assign int_o = int;

	always @(posedge clk10khz) begin

		int <= 0;

      if (wb_rst_i) begin
			ictr <= 0;
			sctr <= 0;
		end else begin
			ictr <= ictr + 1;
			sctr <= sctr + 1;
			if (ictr == 100) begin
				ictr <= 0;
				int <= 1;
			end
			if (sctr == 10000) begin
				sctr <= 0;
				uptime <= uptime + 1;
			end
		end

	end

	always @(posedge wb_clk_i) begin

		ack <= 0;

      if (wb_rst_i) begin
			ack <= 0;
      end else if (wb_cyc_i && wb_stb_i) begin
			ack <= 1;
			if (!wb_we_i) begin
				wb_dat_o <= uptime;
			end
		end

	end

endmodule
