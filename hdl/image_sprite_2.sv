`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */

module image_sprite_2 #(
  parameter WIDTH=256, HEIGHT=256) (
  input wire pixel_clk_in,
  input wire rst_in,
  input wire [10:0] x_in, hcount_in,
  input wire [9:0]  y_in, vcount_in,
  input wire pop_in,
  output logic [7:0] red_out,
  output logic [7:0] green_out,
  output logic [7:0] blue_out
  );

  // calculate rom address
  logic [$clog2(WIDTH*HEIGHT)-1:0] image_addr;
  assign image_addr = (hcount_in - x_in) + ((vcount_in - y_in) * WIDTH);

  logic [7:0] color_index;
  logic [23:0] color;

  logic [10:0] hcount_pipe [4-1:0];
  always_ff @(posedge pixel_clk_in)begin
    hcount_pipe[0] <= hcount_in;
    for (int i=1; i<4; i = i+1)begin
      hcount_pipe[i] <= hcount_pipe[i-1];
    end
  end

  logic [9:0] vcount_pipe [4-1:0];
  always_ff @(posedge pixel_clk_in)begin
    vcount_pipe[0] <= vcount_in;
    for (int i=1; i<4; i = i+1)begin
      vcount_pipe[i] <= vcount_pipe[i-1];
    end
  end

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(8),                       // Specify RAM data width
    .RAM_DEPTH(WIDTH*HEIGHT*2),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(image2.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) image_rom (
    .addra((vcount_in - y_in) * WIDTH + (hcount_in - x_in) + (pop_in ? 0 : (WIDTH * HEIGHT))),     // Address bus, width determined from RAM_DEPTH
    .dina(0),       // RAM input data, width determined from RAM_WIDTH
    .clka(pixel_clk_in),       // Clock
    .wea(0),         // Write enable
    .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1),   // Output register enable
    .douta(color_index)      // RAM output data, width determined from RAM_WIDTH
  );

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(24),                       // Specify RAM data width
    .RAM_DEPTH(256),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(palette2.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) palette_rom (
    .addra(color_index),     // Address bus, width determined from RAM_DEPTH
    .dina(0),       // RAM input data, width determined from RAM_WIDTH
    .clka(pixel_clk_in),       // Clock
    .wea(0),         // Write enable
    .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1),   // Output register enable
    .douta(color)      // RAM output data, width determined from RAM_WIDTH
  );

  logic in_sprite;
  assign in_sprite = ((hcount_pipe[3] >= x_in && hcount_pipe[3] < (x_in + WIDTH)) &&
                      (vcount_pipe[3] >= y_in && vcount_pipe[3] < (y_in + HEIGHT)));

  // Modify the module below to use your BRAMs!
  assign red_out =    in_sprite ? color[23:16] : 0;
  assign green_out =  in_sprite ? color[15:8] : 0;
  assign blue_out =   in_sprite ? color[7:0] : 0;
endmodule

`default_nettype none