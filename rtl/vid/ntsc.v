/*
 * Wolfsfeld SOC
 * Copyright (c) 2025 Lone Dynamics Corporation. All rights reserved.
 *
 * NTSC composite video output.
 *
 */

module vid_ntsc (
    input  wire        clk32mhz,
    input  wire        pix,
    output reg  [11:0] adr,  // To framebuffer
    output reg  [3:0]  dac
);
    // Divide 32MHz by 5 to get 6.4MHz pixel tick
    reg [2:0] clkdiv = 0;
    wire pixel_tick = (clkdiv == 4);

    always @(posedge clk32mhz)
        clkdiv <= pixel_tick ? 0 : clkdiv + 1;

    // Full horizontal and vertical timing counters
    reg [8:0] hcount_full = 0; // 0..405
    reg [8:0] vcount_full = 0; // 0..261

    // Visible pixel counters
    reg [7:0] hcount_vis = 0;  // 0..255 (256 pixels)
    reg [5:0] vcount_vis = 0;  // 0..63  (64 lines)

    wire visible_area = (hcount_vis < 128); // 128 pixels wide
    wire visible_line = (vcount_vis < 32);  // 32 lines high

    always @(posedge clk32mhz) begin
        if (pixel_tick) begin
            // Increment full horizontal counter
            if (hcount_full == 405)
                hcount_full <= 0;
            else
                hcount_full <= hcount_full + 1;

            // Increment vertical counter at end of line
            if (hcount_full == 405) begin
                if (vcount_full == 261)
                    vcount_full <= 0;
                else
                    vcount_full <= vcount_full + 1;
            end

            // Visible horizontal counter logic
            if (hcount_full == 50)
                hcount_vis <= 0;
            else if (hcount_full > 50 && hcount_full < 306)
                hcount_vis <= hcount_vis + 1;
            else
                hcount_vis <= hcount_vis;

            // Visible vertical counter logic
            if (vcount_full == 20 && hcount_full == 405)
                vcount_vis <= 0;
            else if (vcount_full >= 20 && vcount_full < 84 && hcount_full == 405)
                vcount_vis <= vcount_vis + 1;
            else
                vcount_vis <= vcount_vis;

            // Pixel address calculation: pixel doubling by shifting right by 1
            // 7 bits X (128 pixels), 5 bits Y (32 lines)
            adr <= {hcount_vis[7:1], vcount_vis[5:1]};

            // DAC output generation
            if (hcount_full < 40)
                dac <= 4'b0000;  // Sync level
            else if (visible_area && visible_line)
                dac <= pix ? 4'b1111 : 4'b0100;  // White or Black
            else
                dac <= 4'b0100;  // Blank level
        end
    end
endmodule

