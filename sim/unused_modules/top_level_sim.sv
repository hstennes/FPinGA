`timescale 1ns / 1ps
`default_nettype none

module top_level_sim
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

   localparam SIZE = 32;

  // Clock and Reset Signals
  logic          sys_rst_pixel;

  logic          clk_camera;
  logic          clk_pixel;
  logic          clk_5x;
  logic          clk_xc;

  logic          clk_100_passthrough;

  // clocking wizards to generate the clock speeds we need for our different domains
  // clk_camera: 200MHz, fast enough to comfortably sample the cameera's PCLK (50MHz)
  // cw_hdmi_clk_wiz wizard_hdmi
  //   (.sysclk(clk_100_passthrough),
  //    .clk_pixel(clk_pixel),
  //    .clk_tmds(clk_5x),
  //    .reset(0));

  // cw_fast_clk_wiz wizard_migcam
  //   (.clk_in1(CLK100MHZ),
  //    .clk_camera(clk_camera),
  //    .clk_xc(clk_xc),
  //    .clk_100(clk_100_passthrough),
  //    .reset(0));

  assign clk_pixel = CLK100MHZ;

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
  logic [3:0]          red,green,blue;

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

  // START OF SIMULATION STUFF

  logic light_on;
  logic [15:0] ball_vx;
  logic [15:0] ball_vy;
  logic [15:0] ball_vx_fin;
  logic [15:0] ball_vy_fin;
  logic cam_valid;
  logic [10:0] ball_x;
  logic [9:0] ball_y;
  logic check_coll;
  logic [9:0][10:0] pins_x;
  logic [9:0][9:0] pins_y;
  logic [9:0][15:0] pins_vx_coll;
  logic [9:0][15:0] pins_vy_coll;
  logic [9:0][15:0] pins_vx_pins;
  logic [9:0][15:0] pins_vy_pins;
  logic [9:0] pins_hit;
  logic update_pins;
  logic end_roll;
  logic [19:0][5:0] score_p1;
  logic [19:0][5:0] score_p2;
  logic player_no;
  logic roll_no;
  logic [3:0] round_no;
  logic [10:0] x_com, x_com_calc; //long term x_com and output from module, resp
  logic [9:0] y_com, y_com_calc; //long term y_com and output from module, resp
  logic new_com; //used to know when to update x_com and y_com ...
  logic ball_vy_neg;

  camera_input ci (
    .clk_in(clk_pixel),
    .rst_in(~sys_rst_pixel),
    .new_com(new_com),
    .light_on(light_on),
    .x_com(x_com),
    .y_com(y_com)
  );

  camera cam(
    .clk_in(clk_pixel),
    .rst_in(~sys_rst_pixel),
    .valid_in(new_com),
    .light_in(light_on),
    .x_in(x_com),
    .y_in(y_com),
    .vx_out(ball_vx),
    .vy_out(ball_vy),
    .is_vy_neg(ball_vy_neg),
    .valid_out(cam_valid)
  );

  ball ball(
    .clk_in(clk_pixel),
    .rst_in(~sys_rst_pixel),
    .valid_in(cam_valid),
    .initial_speed_x(ball_vx),
    .initial_speed_y(ball_vy),
    .is_vy_neg(ball_vy_neg),
    .ball_x(ball_x),
    .ball_y(ball_y),
    .speed_x(ball_vx_fin),
    .speed_y(ball_vy_fin),
    .check_collision(check_coll),
    .done(end_roll)
  );

  collision coll(
    .clk_in(clk_pixel),                     
    .rst_in(~sys_rst_pixel),
    .valid_in(check_coll), 
    .ball_x(ball_x),          
    .ball_y(ball_y),     
    .pins_x(pins_x),       
    .pins_y(pins_y),        
    .pins_vx_in(pins_vx_pins),       
    .pins_vy_in(pins_vy_pins),        
    .ball_vx_in(ball_vx_fin),       
    .ball_vy_in(ball_vy_fin), 
    .pins_vx_out(pins_vx_coll), 
    .pins_vy_out(pins_vy_coll), 
    .pins_hit(pins_hit),
    .done(update_pins)               
  );

  pins pins(
    .clk_in(clk_pixel),
    .rst_in(~sys_rst_pixel),
    .valid_in(update_pins),
    .pins_vx_in(pins_vx_coll),
    .pins_vy_in(pins_vy_coll),
    .pins_hit_in(pins_hit),
    .pins_x(pins_x),
    .pins_y(pins_y),
    .pins_vx_out(pins_vx_pins),
    .pins_vy_out(pins_vy_pins)
  );

  logic [SIZE-1:0] float_ball_x;
  logic float_ball_x_valid;

  logic [SIZE-1:0] float_ball_y;
  logic float_ball_y_valid;

  fixed_to_float convert_ball_x(
    .s_axis_a_tdata(ball_x),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(1'b1),
    .m_axis_result_tdata(float_ball_x),
    .m_axis_result_tready(1'b1),
    .m_axis_result_tvalid(float_ball_x_valid),
    .aclk(clk_pixel),
    .aresetn(sys_rst_pixel)
  );

  fixed_to_float convert_ball_y(
    .s_axis_a_tdata(ball_y),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(1'b1),
    .m_axis_result_tdata(float_ball_y),
    .m_axis_result_tready(1'b1),
    .m_axis_result_tvalid(float_ball_y_valid),
    .aclk(clk_pixel),
    .aresetn(sys_rst_pixel)
  );

  logic [9:0][SIZE-1:0] float_pin_x;
  logic [9:0][SIZE-1:0] float_pin_y;

  genvar i;
  generate
    for(i = 0; i < 10; i = i + 1) begin
      fixed_to_float convert_pin_x (
        .s_axis_a_tdata(pins_x[i]),
        .s_axis_a_tready(),
        .s_axis_a_tvalid(1'b1),
        .m_axis_result_tdata(float_pin_x[i]),
        .m_axis_result_tready(1'b1),
        .m_axis_result_tvalid(),
        .aclk(clk_pixel),
        .aresetn(sys_rst_pixel)
      );

      fixed_to_float convert_pin_y (
        .s_axis_a_tdata(pins_y[i]),
        .s_axis_a_tready(),
        .s_axis_a_tvalid(1'b1),
        .m_axis_result_tdata(float_pin_y[i]),
        .m_axis_result_tready(1'b1),
        .m_axis_result_tvalid(),
        .aclk(clk_pixel),
        .aresetn(sys_rst_pixel)
      );
    end
  endgenerate

  logic [2:0][SIZE-1:0] pin_axis;

  pin_rotate #(.SIZE(SIZE)) calc_pin_rotate(
    .pin_axis(pin_axis),
    .pin_axis_valid(),
    .pin_axis_ready(1'b1),
    .aclk(clk_pixel),
    .aresetn(sys_rst_pixel)
  );

  // END OF SIMULATION STUFF

  logic [10:0] renderer_hcount_in;
  logic [9:0] renderer_vcount_in;
  logic [10:0] renderer_hcount_out;
  logic [9:0] renderer_vcount_out;
  logic renderer_ready;
  logic pixel_valid;

  localparam [10:0] START_X = 390;
  localparam [9:0] START_Y = 390;
  localparam [10:0] END_X = 634;
  localparam [9:0] END_Y = 765;
  localparam [9:0] REGION_DIVIDE = 530;

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

  logic [23:0] renderer_pixel_out;
  logic [1:0] select_objs;
  assign select_objs = renderer_vcount_in < REGION_DIVIDE ? 2'b11 : 2'b10;

  logic [1919:0] cylinder_data;
  assign cylinder_data = {96'h000000003f80000000000000, float_pin_x[0], 32'h00000000, float_pin_y[0], 96'h000000003f80000000000000, float_pin_x[1], 32'h00000000, float_pin_y[1], 96'h000000003f80000000000000, float_pin_x[2], 32'h00000000, float_pin_y[2], 96'h000000003f80000000000000, float_pin_x[3], 32'h00000000, float_pin_y[3], 96'h000000003f80000000000000, float_pin_x[4], 32'h00000000, float_pin_y[4], 96'h000000003f80000000000000, float_pin_x[5], 32'h00000000, float_pin_y[5], 96'h000000003f80000000000000, float_pin_x[6], 32'h00000000, float_pin_y[6], 96'h000000003f80000000000000, float_pin_x[7], 32'h00000000, float_pin_y[7], 96'h000000003f80000000000000, float_pin_x[8], 32'h00000000, float_pin_y[8], 96'h000000003f80000000000000, float_pin_x[9], 32'h00000000, float_pin_y[9]};

  full_renderer full_render (
    .hcount_axis_tdata(renderer_hcount_in),
    .hcount_axis_tvalid(1'b1),
    .hcount_axis_tready(renderer_ready),
    .vcount_axis_tdata(renderer_vcount_in),
    .vcount_axis_tvalid(1'b1),
    .vcount_axis_tready(),
    .select_objs(select_objs),
    // .sphere(192'h0000000000000000000000004310000041f0000043d20000),
    .sphere({96'h0, float_ball_x, 32'h41f00000, float_ball_y}),
    .cylinders(cylinder_data),
    // .cylinders(1920'h3f80000000000000000000000000000000000000000000003f8000000000000042c000000000000000000000000000003f80000000000000434000000000000000000000000000003f80000000000000439000000000000000000000000000003f80000000000000424000000000000042700000000000003f80000000000000431000000000000042700000000000003f80000000000000437000000000000042700000000000003f8000000000000042c000000000000042f00000000000003f80000000000000434000000000000042f00000000000003f80000000000000431000000000000043340000),
    // .cylinders({pin_axis, 1824'h000000000000000000000000000000003f8000000000000042c000000000000000000000000000003f80000000000000434000000000000000000000000000003f80000000000000439000000000000000000000000000003f80000000000000424000000000000042700000000000003f80000000000000431000000000000042700000000000003f80000000000000437000000000000042700000000000003f8000000000000042c000000000000042f00000000000003f80000000000000434000000000000042f00000000000003f80000000000000431000000000000043340000}),
    // .cylinders({1728'h3f80000000000000000000000000000000000000000000003f8000000000000042c000000000000000000000000000003f80000000000000434000000000000000000000000000003f80000000000000439000000000000000000000000000003f80000000000000424000000000000042700000000000003f80000000000000431000000000000042700000000000003f80000000000000437000000000000042700000000000003f8000000000000042c000000000000042f00000000000003f80000000000000434000000000000042f00000, pin_axis, 96'h431000000000000043340000}),
    .pixel_axis_tdata(renderer_pixel_out),
    .pixel_axis_tvalid(pixel_valid),
    .pixel_axis_tready(1'b1),
    .aclk(clk_pixel),
    .hcount_out(renderer_hcount_out),
    .vcount_out(renderer_vcount_out),
    .aresetn(sys_rst_pixel)
  );

  logic in_cylinder_region;
  assign in_cylinder_region = renderer_vcount_out < REGION_DIVIDE;
  logic in_3d_region;
  assign in_3d_region = hcount_vga >= START_X && hcount_vga < END_X && vcount_vga >= START_Y && vcount_vga < END_Y;
  logic [16:0] ram_addrb;
  assign ram_addrb = (hcount_vga - START_X) + (vcount_vga - START_Y) * (END_X - START_X);
  logic [16:0] ram_addra;
  assign ram_addra = (renderer_hcount_out - START_X - (in_cylinder_region ? 2 : 0)) + (renderer_vcount_out - START_Y) * (END_X - START_X);

  xilinx_true_dual_port_read_first_2_clock_ram #(
      .RAM_WIDTH(12),                       // Specify RAM data width
      .RAM_DEPTH(91500),                     // Specify RAM depth (number of entries)
      .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
      .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) renderer_buffer (
      .addra(ram_addra),   // Port A address bus, width determined from RAM_DEPTH
      .addrb(in_3d_region ? ram_addrb : 1'b0),   // Port B address bus, width determined from RAM_DEPTH
      .dina({renderer_pixel_out[23:20], renderer_pixel_out[15:12], renderer_pixel_out[7:4]}),     // Port A RAM input data, width determined from RAM_WIDTH
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

  assign VGA_R = pipe_in_3d_region && pipe_active_draw_vga ? red : 4'h0; // Full red in active region
  assign VGA_G = pipe_in_3d_region && pipe_active_draw_vga ? green : 4'h0; // No green
  assign VGA_B = pipe_in_3d_region && pipe_active_draw_vga ? blue : 4'h0; // No green

endmodule // top_level

`default_nettype wire