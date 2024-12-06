`timescale 1ns / 1ps
`default_nettype none

module top_level
  (
   input wire          clk_100mhz,
   output logic [15:0] led,
   // camera bus
   input wire [7:0]    camera_d, // 8 parallel data wires
   output logic        cam_xclk, // XC driving camera
   input wire          cam_hsync, // camera hsync wire
   input wire          cam_vsync, // camera vsync wire
   input wire          cam_pclk, // camera pixel clock
   inout wire          i2c_scl, // i2c inout clock
   inout wire          i2c_sda, // i2c inout data
   input wire [15:0]   sw,
   input wire [3:0]    btn,
   output logic [2:0]  rgb0,
   output logic [2:0]  rgb1,
   // seven segment
   output logic [3:0]  ss0_an,//anode control for upper four digits of seven-seg display
   output logic [3:0]  ss1_an,//anode control for lower four digits of seven-seg display
   output logic [6:0]  ss0_c, //cathode controls for the segments of upper four digits
   output logic [6:0]  ss1_c, //cathod controls for the segments of lower four digits
   // hdmi port
   output logic [2:0]  hdmi_tx_p, //hdmi output signals (positives) (blue, green, red)
   output logic [2:0]  hdmi_tx_n, //hdmi output signals (negatives) (blue, green, red)
   output logic        hdmi_clk_p, hdmi_clk_n //differential hdmi clock
   );

  // shut up those RGBs
  assign rgb0 = 0;
  assign rgb1 = 0;

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
    (.clk_in1(clk_100mhz),
     .clk_camera(clk_camera),
     .clk_xc(clk_xc),
     .clk_100(clk_100_passthrough),
     .reset(0));

  // assign camera's xclk to pmod port: drive the operating clock of the camera!
  // this port also is specifically set to high drive by the XDC file.
  assign cam_xclk = clk_xc;

  assign sys_rst_camera = btn[0]; //use for resetting camera side of logic
  assign sys_rst_pixel = btn[0]; //use for resetting hdmi/draw side of logic


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

  // ** Handling input from the camera **

  // synchronizers to prevent metastability
  logic [7:0]    camera_d_buf [1:0];
  logic          cam_hsync_buf [1:0];
  logic          cam_vsync_buf [1:0];
  logic          cam_pclk_buf [1:0];

  always_ff @(posedge clk_camera) begin
     camera_d_buf <= {camera_d, camera_d_buf[1]};
     cam_pclk_buf <= {cam_pclk, cam_pclk_buf[1]};
     cam_hsync_buf <= {cam_hsync, cam_hsync_buf[1]};
     cam_vsync_buf <= {cam_vsync, cam_vsync_buf[1]};
  end

  logic [10:0] camera_hcount;
  logic [9:0]  camera_vcount;
  logic [15:0] camera_pixel;
  logic        camera_valid;

  // your pixel_reconstruct module, from the exercise!
  // hook it up to buffered inputs.
  pixel_reconstruct
    (.clk_in(clk_camera),
     .rst_in(sys_rst_camera),
     .camera_pclk_in(cam_pclk_buf[0]),
     .camera_hs_in(cam_hsync_buf[0]),
     .camera_vs_in(cam_vsync_buf[0]),
     .camera_data_in(camera_d_buf[0]),
     .pixel_valid_out(camera_valid),
     .pixel_hcount_out(camera_hcount),
     .pixel_vcount_out(camera_vcount),
     .pixel_data_out(camera_pixel));


  //two-port BRAM used to hold image from camera.
  //The camera is producing video at 720p and 30fps, but we can't store all of that
  //we're going to down-sample by a factor of 4 in both dimensions
  //so we have 320 by 180.  this is kinda a bummer, but we'll fix it
  //in future weeks by using off-chip DRAM.
  //even with the down-sample, because our camera is producing data at 30fps
  //and  our display is running at 720p at 60 fps, there's no hope to have the
  //production and consumption of information be synchronized in this system.
  //even if we could line it up once, the clocks of both systems will drift over time
  //so to avoid this sync issue, we use a conflict-resolution device...the frame buffer
  //instead we use a frame buffer as a go-between. The camera sends pixels in at
  //its own rate, and we pull them out for display at the 720p rate/requirement
  //this avoids the whole sync issue. It will however result in artifacts when you
  //introduce fast motion in front of the camera. These lines/tears in the image
  //are the result of unsynced frame-rewriting happening while displaying. It won't
  //matter for slow movement
  localparam FB_DEPTH = 320*180;
  localparam FB_SIZE = $clog2(FB_DEPTH);
  logic [FB_SIZE-1:0] addra; //used to specify address to write to in frame buffer

  logic valid_camera_mem; //used to enable writing pixel data to frame buffer
  logic [15:0] camera_mem; //used to pass pixel data into frame buffer

  always_ff @(posedge clk_camera) begin
    if(camera_valid) begin
      addra <= (camera_hcount[10:2]) + camera_vcount[9:2] * 320;
      camera_mem <= camera_pixel;
      valid_camera_mem <= camera_hcount[1:0] == 2'b0 && camera_vcount[1:0] == 2'b0;
    end else begin
      valid_camera_mem <= 0;
    end
  end

  //frame buffer from IP
  blk_mem_gen_0 frame_buffer (
    .addra(addra), //pixels are stored using this math
    .clka(clk_camera),
    .wea(valid_camera_mem),
    .dina(camera_mem),
    .ena(1'b1),
    .douta(), //never read from this side
    .addrb(addrb),//transformed lookup pixel
    .dinb(16'b0),
    .clkb(clk_pixel),
    .web(1'b0),
    .enb(1'b1),
    .doutb(frame_buff_raw)
  );
  logic [15:0] frame_buff_raw; //data out of frame buffer (565)
  logic [FB_SIZE-1:0] addrb; //used to lookup address in memory for reading from buffer
  logic good_addrb; //used to indicate within valid frame for scaling


  //TO DO in camera part 1:
  // Scale pixel coordinates from HDMI to the frame buffer to grab the right pixel
  //scaling logic!!! You need to complete!!! We want 1X, 2X, and 4X!
  always_ff @(posedge clk_pixel)begin
    //use structure below to do scaling
    if (btn[1])begin //1X scaling from frame buffer
     addrb <= (319-hcount_hdmi) + 320*vcount_hdmi;
     good_addrb <= (hcount_hdmi<320)&&(vcount_hdmi<180);
    end else if (!sw[0])begin //2X scaling from frame buffer
     addrb <= (319-(hcount_hdmi >> 1)) + 320*(vcount_hdmi >> 1);
     good_addrb <= (hcount_hdmi<640)&&(vcount_hdmi<360);
    end else begin //4X scaling from frame buffer
     addrb <= (319-(hcount_hdmi >> 2)) + 320*(vcount_hdmi >> 2);
     good_addrb <= (hcount_hdmi<1280)&&(vcount_hdmi<720);
    end
  end

  //split fame_buff into 3 8 bit color channels (5:6:5 adjusted accordingly)
  //remapped frame_buffer outputs with 8 bits for r, g, b
  logic [7:0] fb_red, fb_green, fb_blue;
  always_ff @(posedge clk_pixel)begin
    fb_red <= good_addrb?{frame_buff_raw[15:11],3'b0}:8'b0;
    fb_green <= good_addrb?{frame_buff_raw[10:5], 2'b0}:8'b0;
    fb_blue <= good_addrb?{frame_buff_raw[4:0],3'b0}:8'b0;
  end
  // Pixel Processing pre-HDMI output

  // RGB to YCrCb

  //output of rgb to ycrcb conversion (10 bits due to module):
  logic [9:0] y_full, cr_full, cb_full; //ycrcb conversion of full pixel
  //bottom 8 of y, cr, cb conversions:
  logic [7:0] y, cr, cb; //ycrcb conversion of full pixel
  //Convert RGB of full pixel to YCrCb
  //See lecture 07 for YCrCb discussion.
  //Module has a 3 cycle latency
  rgb_to_ycrcb rgbtoycrcb_m(
    .clk_in(clk_pixel),
    .r_in(fb_red),
    .g_in(fb_green),
    .b_in(fb_blue),
    .y_out(y_full),
    .cr_out(cr_full),
    .cb_out(cb_full)
  );

  //channel select module (select which of six color channels to mask):
  logic [2:0] channel_sel;
  logic [7:0] selected_channel; //selected channels
  //selected_channel could contain any of the six color channels depend on selection

  //threshold module (apply masking threshold):
  logic [7:0] lower_threshold;
  logic [7:0] upper_threshold;
  logic mask; //Whether or not thresholded pixel is 1 or 0

  //Center of Mass variables (tally all mask=1 pixels for a frame and calculate their center of mass)
  logic [10:0] x_com, x_com_calc; //long term x_com and output from module, resp
  logic [9:0] y_com, y_com_calc; //long term y_com and output from module, resp
  logic new_com; //used to know when to update x_com and y_com ...

  //take lower 8 of full outputs.
  // treat cr and cb as signed numbers, invert the MSB to get an unsigned equivalent ( [-128,128) maps to [0,256) )
  assign y = y_full[7:0];
  assign cr = {!cr_full[7],cr_full[6:0]};
  assign cb = {!cb_full[7],cb_full[6:0]};

  assign channel_sel = sw[3:1];
  // * 3'b000: green
  // * 3'b001: red
  // * 3'b010: blue
  // * 3'b011: not valid
  // * 3'b100: y (luminance)
  // * 3'b101: Cr (Chroma Red)
  // * 3'b110: Cb (Chroma Blue)
  // * 3'b111: not valid
  //Channel Select: Takes in the full RGB and YCrCb information and
  // chooses one of them to output as an 8 bit value

  logic [23:0] fb_rgb_pipe [8-1:0];
  always_ff @(posedge clk_pixel)begin
    fb_rgb_pipe[0] <= {fb_red, fb_green, fb_blue};
    for (int i=1; i<8; i = i+1)begin
      fb_rgb_pipe[i] <= fb_rgb_pipe[i-1];
    end
  end

  channel_select mcs(
     .sel_in(channel_sel),
     .r_in(fb_rgb_pipe[2][23:16]),    //TODO: needs to use pipelined signal (PS1)
     .g_in(fb_rgb_pipe[2][15:8]),  //TODO: needs to use pipelined signal (PS1)
     .b_in(fb_rgb_pipe[2][7:0]),   //TODO: needs to use pipelined signal (PS1)
     .y_in(y),
     .cr_in(cr),
     .cb_in(cb),
     .channel_out(selected_channel)
  );

  //threshold values used to determine what value  passes:
  assign lower_threshold = {sw[11:8],4'b0};
  assign upper_threshold = {sw[15:12],4'b0};

  //Thresholder: Takes in the full selected channedl and
  //based on upper and lower bounds provides a binary mask bit
  // * 1 if selected channel is within the bounds (inclusive)
  // * 0 if selected channel is not within the bounds
  threshold mt(
     .clk_in(clk_pixel),
     .rst_in(sys_rst_pixel),
     .pixel_in(selected_channel),
     .lower_bound_in(lower_threshold),
     .upper_bound_in(upper_threshold),
     .mask_out(mask) //single bit if pixel within mask.
  );


  logic [6:0] ss_c;
  //modified version of seven segment display for showing
  // thresholds and selected channel
  // special customized version
  lab05_ssc mssc(.clk_in(clk_pixel),
                 .rst_in(sys_rst_pixel),
                 .lt_in(lower_threshold),
                 .ut_in(upper_threshold),
                 .channel_sel_in(channel_sel),
                 .cat_out(ss_c),
                 .an_out({ss0_an, ss1_an})
  );
  assign ss0_c = ss_c; //control upper four digit's cathodes!
  assign ss1_c = ss_c; //same as above but for lower four digits!

  logic [10:0] hcount_pipe [8-1:0];
  always_ff @(posedge clk_pixel)begin
    hcount_pipe[0] <= hcount_hdmi;
    for (int i=1; i<8; i = i+1)begin
      hcount_pipe[i] <= hcount_pipe[i-1];
    end
  end

  logic [9:0] vcount_pipe [8-1:0];
  always_ff @(posedge clk_pixel)begin
    vcount_pipe[0] <= vcount_hdmi;
    for (int i=1; i<8; i = i+1)begin
      vcount_pipe[i] <= vcount_pipe[i-1];
    end
  end

  //Center of Mass Calculation: (you need to do)
  //using x_com_calc and y_com_calc values
  //Center of Mass:
  center_of_mass com_m(
    .clk_in(clk_pixel),
    .rst_in(sys_rst_pixel),
    .x_in(hcount_pipe[7]),  //TODO: needs to use pipelined signal! (PS3)
    .y_in(vcount_pipe[7]), //TODO: needs to use pipelined signal! (PS3)
    .valid_in(mask), //aka threshold
    .tabulate_in((nf_hdmi)),
    .x_out(x_com_calc),
    .y_out(y_com_calc),
    .valid_out(new_com)
  );
  //grab logic for above
  //update center of mass x_com, y_com based on new_com signal
  always_ff @(posedge clk_pixel)begin
    if (sys_rst_pixel)begin
      x_com <= 0;
      y_com <= 0;
    end if(new_com)begin
      x_com <= x_com_calc;
      y_com <= y_com_calc;
    end
  end

  //image_sprite output:
  logic [7:0] img_red, img_green, img_blue;

  // TODO: image sprite using hdmi hcount/vcount, x_com y_com to draw image or nothing
  //bring in an instance of your popcat image sprite! remember the correct mem files too!
  image_sprite_2 #(
    .WIDTH(256),
    .HEIGHT(256))
    com_sprite_m (
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst_pixel),
    .pop_in(0),
    .hcount_in(hcount_hdmi),   //TODO: needs to use pipelined signal (PS1) No piplined signal according to diagram?
    .vcount_in(vcount_hdmi),   //TODO: needs to use pipelined signal (PS1) No piplined signal according to diagram?
    .x_in(x_com-128),
    .y_in(y_com-128),
    .red_out(img_red),
    .green_out(img_green),
    .blue_out(img_blue));

  //crosshair output:
  logic [7:0] ch_red, ch_green, ch_blue;

  //Create Crosshair patter on center of mass:
  //0 cycle latency
  //TODO: Should be using output of (PS3) No pipelined signal according to diagram
  always_comb begin
    ch_red   = ((vcount_hdmi==y_com) || (hcount_hdmi==x_com))?8'hFF:8'h00;
    ch_green = ((vcount_hdmi==y_com) || (hcount_hdmi==x_com))?8'hFF:8'h00;
    ch_blue  = ((vcount_hdmi==y_com) || (hcount_hdmi==x_com))?8'hFF:8'h00;
  end


  // HDMI video signal generator
   video_sig_gen vsg
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


  // Video Mux: select from the different display modes based on switch values
  //used with switches for display selections
  logic [1:0] display_choice;
  logic [1:0] target_choice;

  assign display_choice = sw[5:4];
  assign target_choice =  sw[7:6];

  //choose what to display from the camera:
  // * 'b00:  normal camera out
  // * 'b01:  selected channel image in grayscale
  // * 'b10:  masked pixel (all on if 1, all off if 0)
  // * 'b11:  chroma channel with mask overtop as magenta
  //
  //then choose what to use with center of mass:
  // * 'b00: nothing
  // * 'b01: crosshair
  // * 'b10: sprite on top
  // * 'b11: nothing

  logic [7:0] y_pipe;
  always_ff @(posedge clk_pixel)begin
    y_pipe <= y;
  end

  logic [7:0] selected_channel_pipe;
  always_ff @(posedge clk_pixel) begin
    selected_channel_pipe <= selected_channel;
  end

  logic [23:0] ch_pipe [8-1:0];
  always_ff @(posedge clk_pixel)begin
    ch_pipe[0] <= {ch_red, ch_green, ch_blue};
    for (int i=1; i<8; i = i+1)begin
      ch_pipe[i] <= ch_pipe[i-1];
    end
  end

  logic [23:0] img_pipe [4-1:0];
  always_ff @(posedge clk_pixel)begin
    img_pipe[0] <= {img_red, img_green, img_blue};
    for (int i=1; i<4; i = i+1)begin
      img_pipe[i] <= img_pipe[i-1];
    end
  end

  // video_mux mvm(
  //   .bg_in(display_choice), //choose background
  //   .target_in(target_choice), //choose target
  //   .camera_pixel_in(fb_rgb_pipe[3]), //TODO: needs (PS2)
  //   .camera_y_in(y_pipe), //luminance TODO: needs (PS6)
  //   .channel_in(selected_channel_pipe), //current channel being drawn TODO: needs (PS5)
  //   .thresholded_pixel_in(mask), //one bit mask signal TODO: needs (PS4) //pipe length 0 from diagram
  //   .crosshair_in(ch_pipe[7]), //TODO: needs (PS8)
  //   .com_sprite_pixel_in(img_pipe[3]), //TODO: needs (PS9) maybe?
  //   .pixel_out({red,green,blue}) //output to tmds
  // );

   // HDMI Output: just like before!

  //  renderer render (
  //   .hcount_axis_tdata(hcount_hdmi),
  //   .hcount_axis_tvalid(1'b1),
  //   .hcount_axis_tready(),
  //   .vcount_axis_tdata(vcount_hdmi),
  //   .vcount_axis_tvalid(1'b1),
  //   .vcount_axis_tready(),
  //   .sphere(192'h00000000000000000000000000000000c0a00000c0a00000),
  //   .cylinders(),
  //   .pixel_axis_tdata({red,green,blue}),
  //   .pixel_axis_tvalid(),
  //   .pixel_axis_tready(1'b1),
  //   .aclk(clk_pixel),
  //   .hcount_out(),
  //   .vcount_out(),
  //   .aresetn(sys_rst_pixel)
  // );

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
    .rst_in(sys_rst_pixel)
  );

  // logic [7:0] r_red;
  // logic [7:0] r_green;
  // logic [7:0] r_blue;

  logic [24:0] renderer_pixel_out;

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

  logic [24:0] ram_pixel_out;

  logic in_3d_region;
  assign in_3d_region = hcount_hdmi >= START_X && hcount_hdmi < END_X && vcount_hdmi >= START_Y && vcount_hdmi < END_Y;
  logic [13:0] ram_addrb;
  assign ram_addrb = (hcount_hdmi - START_X) + (vcount_hdmi - START_Y) * (END_X - START_X);

  xilinx_true_dual_port_read_first_2_clock_ram #(
      .RAM_WIDTH(24),                       // Specify RAM data width
      .RAM_DEPTH(13000),                     // Specify RAM depth (number of entries)
      .RAM_PERFORMANCE("LOW_LATENCY"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
      .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) renderer_buffer (
      .addra((renderer_hcount_out - START_X) + (renderer_vcount_out - START_Y) * (END_X - START_X)),   // Port A address bus, width determined from RAM_DEPTH
      .addrb(ram_addrb),   // Port B address bus, width determined from RAM_DEPTH
      .dina(renderer_pixel_out),     // Port A RAM input data, width determined from RAM_WIDTH
      .dinb(1'b0),     // Port B RAM input data, width determined from RAM_WIDTH
      .clka(clk_pixel),     // Port A clock
      .clkb(clk_pixel),     // Port B clock
      .wea(pixel_valid),       // Port A write enable
      .web(1'b0),       // Port B write enable
      .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
      .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
      .rsta(sys_rst_pixel),     // Port A output reset (does not affect memory contents)
      .rstb(sys_rst_pixel),     // Port B output reset (does not affect memory contents)
      .regcea(1'b0), // Port A output register enable
      .regceb(1'b1), // Port B output register enable
      // .douta(douta),   // Port A RAM output data, width determined from RAM_WIDTH
      .doutb({red,green,blue})    // Port B RAM output data, width determined from RAM_WIDTH
  );

  logic pipe_hsync_hdmi;
  logic pipe_vsync_hdmi;
  logic pipe_active_draw_hdmi;

  axi_pipe #(.LATENCY(1), .SIZE(1)) pipe_hsync (
    .s_axis_a_tdata(hsync_hdmi),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(1'b1),
    .m_axis_result_tdata(pipe_hsync_hdmi),
    .m_axis_result_tvalid(),
    .m_axis_result_tready(1'b1),
    .aclk(clk_pixel),
    .aresetn(sys_rst_pixel)
  );

  axi_pipe #(.LATENCY(1), .SIZE(1)) pipe_vsync (
    .s_axis_a_tdata(vsync_hdmi),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(1'b1),
    .m_axis_result_tdata(pipe_vsync_hdmi),
    .m_axis_result_tvalid(),
    .m_axis_result_tready(1'b1),
    .aclk(clk_pixel),
    .aresetn(sys_rst_pixel)
  );

  axi_pipe #(.LATENCY(1), .SIZE(1)) pipe_active_draw (
    .s_axis_a_tdata(active_draw_hdmi),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(1'b1),
    .m_axis_result_tdata(pipe_active_draw_hdmi),
    .m_axis_result_tvalid(),
    .m_axis_result_tready(1'b1),
    .aclk(clk_pixel),
    .aresetn(sys_rst_pixel)
  );

   // HDMI Output: just like before!

   logic [9:0] tmds_10b [0:2]; //output of each TMDS encoder!
   logic       tmds_signal [2:0]; //output of each TMDS serializer!

   //three tmds_encoders (blue, green, red)
   //note green should have no control signal like red
   //the blue channel DOES carry the two sync signals:
   //  * control_in[0] = horizontal sync signal
   //  * control_in[1] = vertical sync signal

   tmds_encoder tmds_red(
       .clk_in(clk_pixel),
       .rst_in(sys_rst_pixel),
       .data_in(red),
       .control_in(2'b0),
       .ve_in(pipe_active_draw_hdmi),
       .tmds_out(tmds_10b[2]));

   tmds_encoder tmds_green(
         .clk_in(clk_pixel),
         .rst_in(sys_rst_pixel),
         .data_in(green),
         .control_in(2'b0),
         .ve_in(pipe_active_draw_hdmi),
         .tmds_out(tmds_10b[1]));

   tmds_encoder tmds_blue(
        .clk_in(clk_pixel),
        .rst_in(sys_rst_pixel),
        .data_in(blue),
        .control_in({pipe_vsync_hdmi,pipe_hsync_hdmi}),
        .ve_in(pipe_active_draw_hdmi),
        .tmds_out(tmds_10b[0]));


   //three tmds_serializers (blue, green, red):
   //MISSING: two more serializers for the green and blue tmds signals.
   tmds_serializer red_ser(
         .clk_pixel_in(clk_pixel),
         .clk_5x_in(clk_5x),
         .rst_in(sys_rst_pixel),
         .tmds_in(tmds_10b[2]),
         .tmds_out(tmds_signal[2]));
   tmds_serializer green_ser(
         .clk_pixel_in(clk_pixel),
         .clk_5x_in(clk_5x),
         .rst_in(sys_rst_pixel),
         .tmds_in(tmds_10b[1]),
         .tmds_out(tmds_signal[1]));
   tmds_serializer blue_ser(
         .clk_pixel_in(clk_pixel),
         .clk_5x_in(clk_5x),
         .rst_in(sys_rst_pixel),
         .tmds_in(tmds_10b[0]),
         .tmds_out(tmds_signal[0]));

   //output buffers generating differential signals:
   //three for the r,g,b signals and one that is at the pixel clock rate
   //the HDMI receivers use recover logic coupled with the control signals asserted
   //during blanking and sync periods to synchronize their faster bit clocks off
   //of the slower pixel clock (so they can recover a clock of about 742.5 MHz from
   //the slower 74.25 MHz clock)
   OBUFDS OBUFDS_blue (.I(tmds_signal[0]), .O(hdmi_tx_p[0]), .OB(hdmi_tx_n[0]));
   OBUFDS OBUFDS_green(.I(tmds_signal[1]), .O(hdmi_tx_p[1]), .OB(hdmi_tx_n[1]));
   OBUFDS OBUFDS_red  (.I(tmds_signal[2]), .O(hdmi_tx_p[2]), .OB(hdmi_tx_n[2]));
   OBUFDS OBUFDS_clock(.I(clk_pixel), .O(hdmi_clk_p), .OB(hdmi_clk_n));


   // Nothing To Touch Down Here:
   // register writes to the camera

   // The OV5640 has an I2C bus connected to the board, which is used
   // for setting all the hardware settings (gain, white balance,
   // compression, image quality, etc) needed to start the camera up.
   // We've taken care of setting these all these values for you:
   // "rom.mem" holds a sequence of bytes to be sent over I2C to get
   // the camera up and running, and we've written a design that sends
   // them just after a reset completes.

   // If the camera is not giving data, press your reset button.

   logic  busy, bus_active;
   logic  cr_init_valid, cr_init_ready;

   logic  recent_reset;
   always_ff @(posedge clk_camera) begin
      if (sys_rst_camera) begin
         recent_reset <= 1'b1;
         cr_init_valid <= 1'b0;
      end
      else if (recent_reset) begin
         cr_init_valid <= 1'b1;
         recent_reset <= 1'b0;
      end else if (cr_init_valid && cr_init_ready) begin
         cr_init_valid <= 1'b0;
      end
   end

   logic [23:0] bram_dout;
   logic [7:0]  bram_addr;

   // ROM holding pre-built camera settings to send
   xilinx_single_port_ram_read_first
     #(
       .RAM_WIDTH(24),
       .RAM_DEPTH(256),
       .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
       .INIT_FILE("rom.mem")
       ) registers
       (
        .addra(bram_addr),     // Address bus, width determined from RAM_DEPTH
        .dina(24'b0),          // RAM input data, width determined from RAM_WIDTH
        .clka(clk_camera),     // Clock
        .wea(1'b0),            // Write enable
        .ena(1'b1),            // RAM Enable, for additional power savings, disable port when not in use
        .rsta(sys_rst_camera), // Output reset (does not affect memory contents)
        .regcea(1'b1),         // Output register enable
        .douta(bram_dout)      // RAM output data, width determined from RAM_WIDTH
        );

   logic [23:0] registers_dout;
   logic [7:0]  registers_addr;
   assign registers_dout = bram_dout;
   assign bram_addr = registers_addr;

   logic       con_scl_i, con_scl_o, con_scl_t;
   logic       con_sda_i, con_sda_o, con_sda_t;

   // NOTE these also have pullup specified in the xdc file!
   // access our inouts properly as tri-state pins
   IOBUF IOBUF_scl (.I(con_scl_o), .IO(i2c_scl), .O(con_scl_i), .T(con_scl_t) );
   IOBUF IOBUF_sda (.I(con_sda_o), .IO(i2c_sda), .O(con_sda_i), .T(con_sda_t) );

   // provided module to send data BRAM -> I2C
   camera_registers crw
     (.clk_in(clk_camera),
      .rst_in(sys_rst_camera),
      .init_valid(cr_init_valid),
      .init_ready(cr_init_ready),
      .scl_i(con_scl_i),
      .scl_o(con_scl_o),
      .scl_t(con_scl_t),
      .sda_i(con_sda_i),
      .sda_o(con_sda_o),
      .sda_t(con_sda_t),
      .bram_dout(registers_dout),
      .bram_addr(registers_addr));

   // a handful of debug signals for writing to registers
   assign led[0] = crw.bus_active;
   assign led[1] = cr_init_valid;
   assign led[2] = cr_init_ready;
   assign led[15:3] = 0;

endmodule // top_level


`default_nettype wire

