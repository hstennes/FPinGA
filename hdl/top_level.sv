`timescale 1ns / 1ps
`default_nettype none

module top_level
  (
   input wire         CLK100MHZ,
   output logic [3:0] VGA_R,
   output logic [3:0] VGA_G,
   output logic [3:0] VGA_B,
   output logic VGA_HS,
   output logic VGA_VS,
   input wire BTNC
   );


  // Clock and Reset Signals
  logic          sys_rst_camera;
  logic          sys_rst_pixel;

  logic          clk_camera;
  logic          clk_pixel;
  logic          clk_5x;
  logic          clk_xc;

  logic          clk_100_passthrough;

  // clocking wizards to generate the clock speeds we need for our different domains
  // clk_camera: 200MHz, fast enough to comfortably sample the cameera's PCLK (50MHz)
  cw_hdmi_clk_wiz wizard_hdmi
    (.sysclk(clk_100_passthrough),
     .clk_pixel(clk_pixel),
     .clk_tmds(clk_5x),
     .reset(0));

  cw_fast_clk_wiz wizard_migcam
    (.clk_in1(CLK100MHZ),
     .clk_camera(clk_camera),
     .clk_xc(clk_xc),
     .clk_100(clk_100_passthrough),
     .reset(0));

  // assign camera's xclk to pmod port: drive the operating clock of the camera!
  // this port also is specifically set to high drive by the XDC file.

  assign sys_rst_camera = BTNC; //use for resetting camera side of logic
  assign sys_rst_pixel = BTNC; //use for resetting hdmi/draw side of logic


  // video signal generator signals
  logic          hsync_hdmi;
  logic          vsync_hdmi;
  logic [10:0]  hcount_hdmi;
  logic [9:0]    vcount_hdmi;
  logic          active_draw_hdmi;
  logic          new_frame_hdmi;
  logic [5:0]    frame_count_hdmi;
  logic          nf_hdmi;

  // rgb output values
  logic [7:0]          red,green,blue;

  
  // HDMI video signal generator
   vga_sig_gen vsg
     (
      .pixel_clk_in(clk_pixel),
      .rst_in(sys_rst_pixel),
      .hcount_out(hcount_hdmi),
      .vcount_out(vcount_hdmi),
      .vs_out(vsync_hdmi),
      .hs_out(hsync_hdmi),
      .nf_out(nf_hdmi),
      .ad_out(active_draw_hdmi),
      .fc_out(frame_count_hdmi)
      );

   renderer render (
    .hcount_axis_tdata(hcount_hdmi),
    .hcount_axis_tvalid(1'b1),
    .hcount_axis_tready(),
    .vcount_axis_tdata(vcount_hdmi),
    .vcount_axis_tvalid(1'b1),
    .vcount_axis_tready(),
    .sphere(192'h00000000000000000000000000000000c0a00000c0a00000),
    .cylinders(),
    .pixel_axis_tdata({red,green,blue}),
    .pixel_axis_tvalid(),
    .pixel_axis_tready(1'b1),
    .aclk(clk_pixel),
    .hcount_out(),
    .vcount_out(),
    .aresetn(sys_rst_pixel)
  );

  logic pipe_hsync_hdmi;
  logic pipe_vsync_hdmi;
  logic pipe_active_draw_hdmi;

  axi_pipe #(.LATENCY(339), .SIZE(1)) pipe_hsync (
    .s_axis_a_tdata(hsync_hdmi),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(1'b1),
    .m_axis_result_tdata(VGA_HS),
    .m_axis_result_tvalid(),
    .m_axis_result_tready(1'b1),
    .aclk(clk_pixel),
    .aresetn(sys_rst_pixel)
  );

  axi_pipe #(.LATENCY(339), .SIZE(1)) pipe_vsync (
    .s_axis_a_tdata(vsync_hdmi),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(1'b1),
    .m_axis_result_tdata(VGA_VS),
    .m_axis_result_tvalid(),
    .m_axis_result_tready(1'b1),
    .aclk(clk_pixel),
    .aresetn(sys_rst_pixel)
  );

  axi_pipe #(.LATENCY(339), .SIZE(1)) pipe_active_draw (
    .s_axis_a_tdata(active_draw_hdmi),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(1'b1),
    .m_axis_result_tdata(pipe_active_draw_hdmi),
    .m_axis_result_tvalid(),
    .m_axis_result_tready(1'b1),
    .aclk(clk_pixel),
    .aresetn(sys_rst_pixel)
  );

  assign VGA_R = pipe_active_draw_hdmi ? red[7:4] : 4'h0;
  assign VGA_G = pipe_active_draw_hdmi ? green[7:4] : 4'h0;
  assign VGA_B = pipe_active_draw_hdmi ? blue[7:4] : 4'h0;

endmodule // top_level


`default_nettype wire

