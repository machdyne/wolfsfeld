/*
 * I2C
 * Copyright (c) 2025 Lone Dynamics Corporation. All rights reserved.
 *
 * I2C write-only bit-bang interface
 *
 */

module i2c_wb #()
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
	inout sda,
	inout scl,
);

	reg ack;
	assign wb_ack_o = ack;

   reg sda_oen; // 0 = drive low, 1 = release (open-drain)
   reg scl_oen;

   assign sda = sda_oen ? 1'bz : 1'b0;
   assign scl = scl_oen ? 1'bz : 1'b0;

	always @(posedge wb_clk_i) begin

		ack <= 0;

      if (wb_rst_i) begin
         sda_oen <= 1;
         scl_oen <= 1;
      end else if (wb_cyc_i && wb_stb_i) begin
			if (wb_we_i) begin
				sda_oen <= wb_dat_i[0];
				scl_oen <= wb_dat_i[1];
			end else begin
				wb_dat_o <= { 30'b0, scl_oen, sda_oen };
			end
			ack <= 1;
		end
	end

endmodule
