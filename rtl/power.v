/*
 * Wolfsfeld SOC
 * Copyright (c) 2025 Lone Dynamics Corporation. All rights reserved.
 *
 * Power management module.
 *
 */

module power_wb #()
(
    input wb_clk_i,
    input wb_rst_i,
    input [31:0] wb_adr_i,
    input [31:0] wb_dat_i,
    output [31:0] wb_dat_o,
    input wb_we_i,
    input [3:0] wb_sel_i,
    input wb_stb_i,
    output wb_ack_o,
    input wb_cyc_i,
    input clk10khz,
    output reg power_mode = 0,
    input wake
);

    localparam [0:0]
        POWER_ACTIVE   = 1'b0,
        POWER_SUSPEND  = 1'b1;

    assign wb_dat_o = {31'b0, power_mode};  // Read back power mode
    assign wb_ack_o = wb_cyc_i && wb_stb_i;

    // Clock domain crossing: wb_clk_i to clk10khz
    reg power_trigger_suspend = 0;
    reg [2:0] suspend_sync = 0;
    
    // Generate reset for 10kHz domain
    reg [2:0] rst_sync_10k = 0;
    wire rst_10khz = !rst_sync_10k[2];
    
    always @(posedge clk10khz) begin
        rst_sync_10k <= {rst_sync_10k[1:0], !wb_rst_i};
    end

    // Trigger suspend in wb_clk domain
    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            power_trigger_suspend <= 0;
        end else if (wb_cyc_i && wb_stb_i && wb_we_i && wb_dat_i[0]) begin
            power_trigger_suspend <= 1;
        end else if (suspend_sync[2]) begin
            power_trigger_suspend <= 0;  // Clear when seen by 10kHz domain
        end
    end

    // Synchronize to 10kHz domain and handle power management
	always @(posedge clk10khz) begin

		// Synchronize suspend trigger
		suspend_sync <= {suspend_sync[1:0], power_trigger_suspend};
        
		if (wake) begin
			power_mode <= POWER_ACTIVE;
			suspend_sync <= 0;  // Clear sync when waking
		end else if (suspend_sync[2] && !suspend_sync[1]) begin  // Rising edge
			power_mode <= POWER_SUSPEND;
		end

	end

endmodule
