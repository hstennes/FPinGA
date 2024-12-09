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
   input wire BTNC,
   output logic CA,
   output logic CB,
   output logic CC,
   output logic CD,
   output logic CE,
   output logic CF,
   output logic CG,
   output logic [7:0] AN,
   output logic [0:0] LED
   );

  // Clock and Reset Signals
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

  assign sys_rst_pixel = ~BTNC; //use for resetting hdmi/draw side of logic
  assign LED = BTNC;

  // video signal generator signals
  logic          hsync_vga;
  logic          vsync_vga;
  logic [10:0]   hcount_vga;
  logic [9:0]    vcount_vga;
  logic          active_draw_vga;
  logic          new_frame_vga;
  logic [5:0]    frame_count_vga;
  logic          nf_vga;

  // rgb output values
  logic [7:0]          red,green,blue;

  vga_sig_gen vsg
  (
    .pixel_clk_in(clk_pixel),
    .rst_in(~sys_rst_pixel),
    .hcount_out(hcount_vga),
    .vcount_out(vcount_vga),
    .vs_out(vsync_vga),
    .hs_out(hsync_vga),
    .nf_out(nf_vga),
    .ad_out(active_draw_vga),
    .fc_out(frame_count_vga)
  );

  logic [10:0] renderer_hcount_in;
  logic [9:0] renderer_vcount_in;
  logic [10:0] renderer_hcount_out;
  logic [9:0] renderer_vcount_out;
  logic renderer_ready;
  logic pixel_valid;

  localparam [10:0] START_X = 260;
  localparam [9:0] START_Y = 195;
  localparam [10:0] END_X = 390;
  localparam [9:0] END_Y = 295;

  renderer_sig_gen #(
    .START_X(START_X),
    .START_Y(START_Y),
    .END_X(END_X),
    .END_Y(END_Y)
  ) renderer_sig (
    .ready(renderer_ready),
    .hcount_out(renderer_hcount_in),
    .vcount_out(renderer_vcount_in),
    .aclk(clk_pixel),
    .rst_in(~sys_rst_pixel)
  );

  // logic [7:0] r_red;
  // logic [7:0] r_green;
  // logic [7:0] r_blue;

  logic [23:0] renderer_pixel_out;

  // full_renderer full_render (
  //   .hcount_axis_tdata(renderer_hcount_in),
  //   .hcount_axis_tvalid(1'b1),
  //   .hcount_axis_tready(renderer_ready),
  //   .vcount_axis_tdata(renderer_vcount_in),
  //   .vcount_axis_tvalid(1'b1),
  //   .vcount_axis_tready(),
  //   .sphere(192'h00000000000000000000000000000000c0a00000c0a00000),
  //   .cylinders(1920'h3f80000000000000c0c00000c0a00000c1800000000000003f80000000000000c0000000c0a00000c1800000000000003f8000000000000040000000c0a00000c1800000000000003f8000000000000040c00000c0a00000c1800000000000003f80000000000000c0800000c0a00000c1600000000000003f8000000000000000000000c0a00000c1600000000000003f8000000000000040800000c0a00000c1600000000000003f80000000000000c0000000c0a00000c1400000000000003f8000000000000040000000c0a00000c1400000000000003f8000000000000000000000c0a00000c1200000),
  //   .pixel_axis_tdata(renderer_pixel_out),
  //   .pixel_axis_tvalid(pixel_valid),
  //   .pixel_axis_tready(1'b1),
  //   .aclk(clk_pixel),
  //   .hcount_out(renderer_hcount_out),
  //   .vcount_out(renderer_vcount_out),
  //   .aresetn(sys_rst_pixel)
  // );

  logic [31:0] valid_counter;

  full_renderer full_render (
    .hcount_axis_tdata(renderer_hcount_in),
    .hcount_axis_tvalid(1'b1),
    .hcount_axis_tready(renderer_ready),
    .vcount_axis_tdata(renderer_vcount_in),
    .vcount_axis_tvalid(1'b1),
    .vcount_axis_tready(),
    .sphere(192'h00000000000000000000000000000000c0a00000c0a00000),
    .cylinders(1920'h3f80000000000000c0c00000c0a00000c1800000000000003f80000000000000c0000000c0a00000c1800000000000003f8000000000000040000000c0a00000c1800000000000003f8000000000000040c00000c0a00000c1800000000000003f80000000000000c0800000c0a00000c1600000000000003f8000000000000000000000c0a00000c1600000000000003f8000000000000040800000c0a00000c1600000000000003f80000000000000c0000000c0a00000c1400000000000003f8000000000000040000000c0a00000c1400000000000003f8000000000000000000000c0a00000c1200000),
    .pixel_axis_tdata(renderer_pixel_out),
    .pixel_axis_tvalid(pixel_valid),
    .pixel_axis_tready(1'b1),
    .aclk(clk_pixel),
    .hcount_out(renderer_hcount_out),
    .vcount_out(renderer_vcount_out),
    .aresetn(sys_rst_pixel)
  );

  evt_counter valid_evt_counter (
    .clk_in(clk_pixel),
    .rst_in(~sys_rst_pixel),
    .evt_in(pixel_valid),
    .period_in(32'hFFFFFFFF),
    .count_out(valid_counter)
  );

  logic [6:0] ss_c;

  seven_segment_controller mssc(.clk_in(clk_pixel),
                               .rst_in(~sys_rst_pixel),
                               .val_in(valid_counter),
                               .cat_out(ss_c),
                               .an_out(AN));

  assign CA = ss_c[0];
  assign CB = ss_c[1];
  assign CC = ss_c[2];
  assign CD = ss_c[3];
  assign CE = ss_c[4];
  assign CF = ss_c[5];
  assign CG = ss_c[6];

  logic [24:0] ram_pixel_out;

  logic in_3d_region;
  assign in_3d_region = hcount_vga >= START_X && hcount_vga < END_X && vcount_vga >= START_Y && vcount_vga < END_Y;
  logic [13:0] ram_addrb;
  assign ram_addrb = (hcount_vga - START_X) + (vcount_vga - START_Y) * (END_X - START_X);
  logic [13:0] ram_addra;
  assign ram_addra = (renderer_hcount_out - START_X) + (renderer_vcount_out - START_Y) * (END_X - START_X);

  xilinx_true_dual_port_read_first_2_clock_ram #(
      .RAM_WIDTH(24),                       // Specify RAM data width
      .RAM_DEPTH(13000),                     // Specify RAM depth (number of entries)
      .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
      .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) renderer_buffer (
      .addra(ram_addra),   // Port A address bus, width determined from RAM_DEPTH
      .addrb(in_3d_region ? ram_addrb : 1'b0),   // Port B address bus, width determined from RAM_DEPTH
      .dina(renderer_pixel_out),     // Port A RAM input data, width determined from RAM_WIDTH
      .dinb(1'b0),     // Port B RAM input data, width determined from RAM_WIDTH
      .clka(clk_pixel),     // Port A clock
      .clkb(clk_pixel),     // Port B clock
      .wea(pixel_valid),       // Port A write enable
      .web(1'b0),       // Port B write enable
      .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
      .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
      .rsta(~sys_rst_pixel),     // Port A output reset (does not affect memory contents)
      .rstb(~sys_rst_pixel),     // Port B output reset (does not affect memory contents)
      .regcea(1'b0), // Port A output register enable
      .regceb(1'b1), // Port B output register enable
      // .douta(douta),   // Port A RAM output data, width determined from RAM_WIDTH
      .doutb({red,green,blue})    // Port B RAM output data, width determined from RAM_WIDTH
  );

  logic pipe_hsync_vga;
  logic pipe_vsync_vga;
  logic pipe_active_draw_vga;
  logic pipe_in_3d_region;

  axi_pipe #(.LATENCY(2), .SIZE(1)) pipe_hsync (
    .s_axis_a_tdata(hsync_vga),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(1'b1),
    .m_axis_result_tdata(VGA_HS),
    .m_axis_result_tvalid(),
    .m_axis_result_tready(1'b1),
    .aclk(clk_pixel),
    .aresetn(sys_rst_pixel)
  );

  axi_pipe #(.LATENCY(2), .SIZE(1)) pipe_vsync (
    .s_axis_a_tdata(vsync_vga),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(1'b1),
    .m_axis_result_tdata(VGA_VS),
    .m_axis_result_tvalid(),
    .m_axis_result_tready(1'b1),
    .aclk(clk_pixel),
    .aresetn(sys_rst_pixel)
  );

  axi_pipe #(.LATENCY(2), .SIZE(1)) pipe_active_draw (
    .s_axis_a_tdata(active_draw_vga),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(1'b1),
    .m_axis_result_tdata(pipe_active_draw_vga),
    .m_axis_result_tvalid(),
    .m_axis_result_tready(1'b1),
    .aclk(clk_pixel),
    .aresetn(sys_rst_pixel)
  );

  axi_pipe #(.LATENCY(2), .SIZE(1)) pipe_in_3d (
    .s_axis_a_tdata(in_3d_region),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(1'b1),
    .m_axis_result_tdata(pipe_in_3d_region),
    .m_axis_result_tvalid(),
    .m_axis_result_tready(1'b1),
    .aclk(clk_pixel),
    .aresetn(sys_rst_pixel)
  );

  // assign VGA_R = pipe_active_draw_vga ? renderer_pixel_out[23:20] : 4'h0; // Full red in active region
  // assign VGA_G = pipe_active_draw_vga ? renderer_pixel_out[15:12] : 4'h0; // No green
  // assign VGA_B = pipe_active_draw_vga ? renderer_pixel_out[7:4] : 4'h0; // No green

  assign VGA_R = pipe_active_draw_vga ? red[7:4] : 4'h0; // Full red in active region
  assign VGA_G = pipe_active_draw_vga ? green[7:4] : 4'h0; // No green
  assign VGA_B = pipe_active_draw_vga ? blue[7:4] : 4'h0; // No green

endmodule // top_level

`default_nettype wire









// `timescale 1ns / 1ps
// `default_nettype none

// module top_level
//   (
//    input wire         CLK100MHZ,
//    output logic [3:0] VGA_R,
//    output logic [3:0] VGA_G,
//    output logic [3:0] VGA_B,
//    output logic VGA_HS,
//    output logic VGA_VS,
//    input wire BTNC
//    );


//   // Clock and Reset Signals
//   logic          sys_rst_camera;
//   logic          sys_rst_pixel;

//   logic          clk_camera;
//   logic          clk_pixel;
//   logic          clk_5x;
//   logic          clk_xc;

//   logic          clk_100_passthrough;

//   // clocking wizards to generate the clock speeds we need for our different domains
//   // clk_camera: 200MHz, fast enough to comfortably sample the cameera's PCLK (50MHz)
//   cw_hdmi_clk_wiz wizard_hdmi
//     (.sysclk(clk_100_passthrough),
//      .clk_pixel(clk_pixel),
//      .clk_tmds(clk_5x),
//      .reset(0));

//   cw_fast_clk_wiz wizard_migcam
//     (.clk_in1(CLK100MHZ),
//      .clk_camera(clk_camera),
//      .clk_xc(clk_xc),
//      .clk_100(clk_100_passthrough),
//      .reset(0));

//   // assign camera's xclk to pmod port: drive the operating clock of the camera!
//   // this port also is specifically set to high drive by the XDC file.

//   assign sys_rst_camera = BTNC; //use for resetting camera side of logic
//   assign sys_rst_pixel = BTNC; //use for resetting hdmi/draw side of logic


//   // video signal generator signals
//   logic          hsync_hdmi;
//   logic          vsync_hdmi;
//   logic [10:0]  hcount_hdmi;
//   logic [9:0]    vcount_hdmi;
//   logic          active_draw_hdmi;
//   logic          new_frame_hdmi;
//   logic [5:0]    frame_count_hdmi;
//   logic          nf_hdmi;

//   // rgb output values
//   logic [7:0]          red,green,blue;

  
//   // HDMI video signal generator
//    vga_sig_gen vsg
//      (
//       .pixel_clk_in(clk_pixel),
//       .rst_in(sys_rst_pixel),
//       .hcount_out(hcount_hdmi),
//       .vcount_out(vcount_hdmi),
//       .vs_out(vsync_hdmi),
//       .hs_out(hsync_hdmi),
//       .nf_out(nf_hdmi),
//       .ad_out(active_draw_hdmi),
//       .fc_out(frame_count_hdmi)
//       );

//    renderer render (
//     .hcount_axis_tdata(hcount_hdmi),
//     .hcount_axis_tvalid(1'b1),
//     .hcount_axis_tready(),
//     .vcount_axis_tdata(vcount_hdmi),
//     .vcount_axis_tvalid(1'b1),
//     .vcount_axis_tready(),
//     .sphere(192'h00000000000000000000000000000000c0a00000c0a00000),
//     .cylinders(),
//     .pixel_axis_tdata({red,green,blue}),
//     .pixel_axis_tvalid(),
//     .pixel_axis_tready(1'b1),
//     .aclk(clk_pixel),
//     .hcount_out(),
//     .vcount_out(),
//     .aresetn(sys_rst_pixel)
//   );

//   logic pipe_hsync_hdmi;
//   logic pipe_vsync_hdmi;
//   logic pipe_active_draw_hdmi;

//   axi_pipe #(.LATENCY(339), .SIZE(1)) pipe_hsync (
//     .s_axis_a_tdata(hsync_hdmi),
//     .s_axis_a_tready(),
//     .s_axis_a_tvalid(1'b1),
//     .m_axis_result_tdata(VGA_HS),
//     .m_axis_result_tvalid(),
//     .m_axis_result_tready(1'b1),
//     .aclk(clk_pixel),
//     .aresetn(sys_rst_pixel)
//   );

//   axi_pipe #(.LATENCY(339), .SIZE(1)) pipe_vsync (
//     .s_axis_a_tdata(vsync_hdmi),
//     .s_axis_a_tready(),
//     .s_axis_a_tvalid(1'b1),
//     .m_axis_result_tdata(VGA_VS),
//     .m_axis_result_tvalid(),
//     .m_axis_result_tready(1'b1),
//     .aclk(clk_pixel),
//     .aresetn(sys_rst_pixel)
//   );

//   axi_pipe #(.LATENCY(339), .SIZE(1)) pipe_active_draw (
//     .s_axis_a_tdata(active_draw_hdmi),
//     .s_axis_a_tready(),
//     .s_axis_a_tvalid(1'b1),
//     .m_axis_result_tdata(pipe_active_draw_hdmi),
//     .m_axis_result_tvalid(),
//     .m_axis_result_tready(1'b1),
//     .aclk(clk_pixel),
//     .aresetn(sys_rst_pixel)
//   );

//   assign VGA_R = pipe_active_draw_hdmi ? red[7:4] : 4'h0;
//   assign VGA_G = pipe_active_draw_hdmi ? green[7:4] : 4'h0;
//   assign VGA_B = pipe_active_draw_hdmi ? blue[7:4] : 4'h0;

// endmodule // top_level


// `default_nettype wire

