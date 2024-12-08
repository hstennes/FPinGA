module vga_sig_gen
#(
  parameter ACTIVE_H_PIXELS = 1024,
  parameter H_FRONT_PORCH = 24,
  parameter H_SYNC_WIDTH = 136,
  parameter H_BACK_PORCH = 160,
  parameter ACTIVE_LINES = 768,
  parameter V_FRONT_PORCH = 3,
  parameter V_SYNC_WIDTH = 6,
  parameter V_BACK_PORCH = 29,
  parameter FPS = 60)
(
  input wire pixel_clk_in,
  input wire rst_in,
  output logic [$clog2(ACTIVE_H_PIXELS + H_FRONT_PORCH + H_SYNC_WIDTH + H_BACK_PORCH)-1:0] hcount_out,
  output logic [$clog2(ACTIVE_LINES + V_FRONT_PORCH + V_SYNC_WIDTH + V_BACK_PORCH)-1:0] vcount_out,
  output logic vs_out, //vertical sync out
  output logic hs_out, //horizontal sync out
  output logic ad_out,
  output logic nf_out, //single cycle enable signal
  output logic [5:0] fc_out); //frame

  localparam TOTAL_PIXELS = ACTIVE_H_PIXELS + H_FRONT_PORCH + H_SYNC_WIDTH + H_BACK_PORCH;
  localparam TOTAL_LINES = ACTIVE_LINES + V_FRONT_PORCH + V_SYNC_WIDTH + V_BACK_PORCH;

  counter h_counter(
    .clk_in(pixel_clk_in),
    .rst_in(rst_in),
    .period_in(TOTAL_PIXELS),
    .count_out(hcount_out)
  );

  evt_counter v_counter(
    .clk_in(pixel_clk_in),
    .rst_in(rst_in),
    .evt_in(hcount_out == TOTAL_PIXELS - 1),
    .period_in(TOTAL_LINES),
    .count_out(vcount_out)
  );

  evt_counter frame_counter (
    .clk_in(pixel_clk_in),
    .rst_in(rst_in),
    .evt_in(nf_out),
    .period_in(60),
    .count_out(fc_out)
  );

  always_comb begin
    hs_out = (hcount_out >= ACTIVE_H_PIXELS + H_FRONT_PORCH) && (hcount_out < ACTIVE_H_PIXELS + H_FRONT_PORCH + H_SYNC_WIDTH);
    vs_out = (vcount_out >= ACTIVE_LINES + V_FRONT_PORCH) && (vcount_out < ACTIVE_LINES + V_FRONT_PORCH + V_SYNC_WIDTH);
    ad_out = (hcount_out < ACTIVE_H_PIXELS && vcount_out < ACTIVE_LINES);
    nf_out = (hcount_out == ACTIVE_H_PIXELS && vcount_out == ACTIVE_LINES);
  end
  
endmodule
