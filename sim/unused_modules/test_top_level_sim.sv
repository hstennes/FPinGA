`timescale 1ns / 1ps
`default_nettype none

module top_level
  (
   input wire          clk_100mhz,
   output logic [15:0] led,
   input wire [15:0]   sw,
   input wire [3:0]    btn,
   output logic [2:0]  rgb0,
   output logic [2:0]  rgb1,
   // seven segment
   output logic [3:0]  ss0_an,//anode control for upper four digits of seven-seg display
   output logic [3:0]  ss1_an,//anode control for lower four digits of seven-seg display
   output logic [6:0]  ss0_c, //cathode controls for the segments of upper four digits

   output logic [3:0] vga_r,
   output logic [3:0] vga_g,
   output logic [3:0] vga_b,
   output logic vga_hs,
   output logic vga_vs
   );

  // shut up those RGBs
  assign rgb0 = 0;
  assign rgb1 = 0;

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
    (.clk_in1(clk_100mhz),
     .clk_camera(clk_camera),
     .clk_xc(clk_xc),
     .clk_100(clk_100_passthrough),
     .reset(0));

  // assign camera's xclk to pmod port: drive the operating clock of the camera!
  // this port also is specifically set to high drive by the XDC file.

  assign sys_rst_pixel = btn[0]; //use for resetting hdmi/draw side of logic


  // video signal generator signals
  logic          hsync_vga;
  logic          vsync_vga;
  logic [10:0]  hcount_vga;
  logic [9:0]    vcount_vga;
  logic          active_draw_vga;
  logic          new_frame_vga;
  logic [5:0]    frame_count_vga;
  logic          nf_vga;
  // rgb output values
  logic [3:0]          red,green,blue;

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
    .rst_in(sys_rst_pixel),
    .new_com(new_com),
    .light_on(light_on),
    .x_com(x_com),
    .y_com(y_com)
  );

  camera cam(
    .clk_in(clk_pixel),
    .rst_in(sys_rst_pixel),
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
    .rst_in(sys_rst_pixel),
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
    .rst_in(sys_rst_pixel),
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
    .rst_in(sys_rst_pixel),
    .valid_in(update_pins),
    .pins_vx_in(pins_vx_coll),
    .pins_vy_in(pins_vy_coll),
    .pins_hit_in(pins_hit),
    .pins_x(pins_x),
    .pins_y(pins_y),
    .pins_vx_out(pins_vx_pins),
    .pins_vy_out(pins_vy_pins)
  );

  // VGA video signal generator
   video_sig_gen vsg
     (
      .pixel_clk_in(clk_pixel),
      .rst_in(sys_rst_pixel),
      .hcount_out(hcount_vga),
      .vcount_out(vcount_vga),
      .vs_out(vga_vs),
      .hs_out(vga_hs),
      .nf_out(nf_vga),
      .ad_out(active_draw_vga),
      .fc_out(frame_count_vga)
      );

  assign vga_r = active_draw_vga && (hcount_vga >= ball_x && hcount_vga < ball_x + 16) && 
                 (vcount_vga >= ball_y && vcount_vga < ball_y + 16) ? 4'hF : 4'h0;
  assign vga_g = active_draw_vga && check_coll && (hcount_vga > 0 && hcount_vga <10)&& 
                 (pins_hit[0] && ((hcount_vga >= pins_x[0] && hcount_vga < pins_x[0] + 10) && 
                 (vcount_vga >= pins_y[0] && vcount_vga < pins_y[0] + 10))) ||
                 
                 (pins_hit[1] && ((hcount_vga >= pins_x[1] && hcount_vga < pins_x[1] + 10) && 
                 (vcount_vga >= pins_y[1] && vcount_vga < pins_y[1] + 10))) ||

                 (pins_hit[2] && ((hcount_vga >= pins_x[2] && hcount_vga < pins_x[2] + 10) && 
                 (vcount_vga >= pins_y[2] && vcount_vga < pins_y[2] + 10))) ||

                 (pins_hit[3] && ((hcount_vga >= pins_x[3] && hcount_vga < pins_x[3] + 10) && 
                 (vcount_vga >= pins_y[3] && vcount_vga < pins_y[3] + 10))) ||

                 (pins_hit[4] && ((hcount_vga >= pins_x[4] && hcount_vga < pins_x[4] + 10) && 
                 (vcount_vga >= pins_y[4] && vcount_vga < pins_y[4] + 10))) ||

                 (pins_hit[5] && ((hcount_vga >= pins_x[5] && hcount_vga < pins_x[5] + 10) && 
                 (vcount_vga >= pins_y[5] && vcount_vga < pins_y[5] + 10))) ||

                 (pins_hit[6] && ((hcount_vga >= pins_x[6] && hcount_vga < pins_x[6] + 10) && 
                 (vcount_vga >= pins_y[6] && vcount_vga < pins_y[6] + 10))) ||

                 (pins_hit[7] && ((hcount_vga >= pins_x[7] && hcount_vga < pins_x[7] + 10) && 
                 (vcount_vga >= pins_y[7] && vcount_vga < pins_y[7] + 10))) ||

                 (pins_hit[8] && ((hcount_vga >= pins_x[8] && hcount_vga < pins_x[8] + 10) && 
                 (vcount_vga >= pins_y[8] && vcount_vga < pins_y[8] + 10))) ||

                 (pins_hit[9] && ((hcount_vga >= pins_x[9] && hcount_vga < pins_x[9] + 10) && 
                 (vcount_vga >= pins_y[9] && vcount_vga < pins_y[9] + 10)))
                  ? 4'hF : 4'h0;

  assign vga_b = active_draw_vga && 
                 (!pins_hit[0] && ((hcount_vga >= pins_x[0] && hcount_vga < pins_x[0] + 10) && 
                 (vcount_vga >= pins_y[0] && vcount_vga < pins_y[0] + 10))) ||
                 
                 (!pins_hit[1] && ((hcount_vga >= pins_x[1] && hcount_vga < pins_x[1] + 10) && 
                 (vcount_vga >= pins_y[1] && vcount_vga < pins_y[1] + 10))) ||

                 (!pins_hit[2] && ((hcount_vga >= pins_x[2] && hcount_vga < pins_x[2] + 10) && 
                 (vcount_vga >= pins_y[2] && vcount_vga < pins_y[2] + 10))) ||

                 (!pins_hit[3] && ((hcount_vga >= pins_x[3] && hcount_vga < pins_x[3] + 10) && 
                 (vcount_vga >= pins_y[3] && vcount_vga < pins_y[3] + 10))) ||

                 (!pins_hit[4] && ((hcount_vga >= pins_x[4] && hcount_vga < pins_x[4] + 10) && 
                 (vcount_vga >= pins_y[4] && vcount_vga < pins_y[4] + 10))) ||

                 (!pins_hit[5] && ((hcount_vga >= pins_x[5] && hcount_vga < pins_x[5] + 10) && 
                 (vcount_vga >= pins_y[5] && vcount_vga < pins_y[5] + 10))) ||

                 (!pins_hit[6] && ((hcount_vga >= pins_x[6] && hcount_vga < pins_x[6] + 10) && 
                 (vcount_vga >= pins_y[6] && vcount_vga < pins_y[6] + 10))) ||

                 (!pins_hit[7] && ((hcount_vga >= pins_x[7] && hcount_vga < pins_x[7] + 10) && 
                 (vcount_vga >= pins_y[7] && vcount_vga < pins_y[7] + 10))) ||

                 (!pins_hit[8] && ((hcount_vga >= pins_x[8] && hcount_vga < pins_x[8] + 10) && 
                 (vcount_vga >= pins_y[8] && vcount_vga < pins_y[8] + 10))) ||

                 (!pins_hit[9] && ((hcount_vga >= pins_x[9] && hcount_vga < pins_x[9] + 10) && 
                 (vcount_vga >= pins_y[9] && vcount_vga < pins_y[9] + 10)))
                  ? 4'hF : 4'h0;

   
endmodule // top_level


`default_nettype wire

