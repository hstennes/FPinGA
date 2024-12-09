`timescale 1ns / 1ps
`default_nettype none

module check_objects #(parameter SIZE=64) (
  input wire [2:0][SIZE-1:0] ray_axis_tdata,
  input wire [1:0] select_objs,
  input wire [10:0] hcount_axis_tdata,
  input wire [9:0] vcount_axis_tdata,
  input wire ray_axis_tvalid,
  output logic ray_axis_tready,
  input wire [5:0][SIZE-1:0] sphere,
  input wire [9:0][5:0][SIZE-1:0] cylinders,
  output logic [2:0][SIZE-1:0] hit_point_axis_tdata,
  output logic hit_point_axis_tvalid,
  input wire hit_point_axis_tready,
  output logic [2:0][SIZE-1:0] normal_axis_tdata,
  output logic normal_axis_tvalid,
  input wire normal_axis_tready,
  output logic hit_cylinder,
  output logic hit_sphere,
  output logic [10:0] hcount_out,
  output logic [9:0] vcount_out,
  input wire aclk,
  input wire aresetn
  );

  /*
  When passing a ray, also pass in which objects should be checked.
  Options - just sphere, just cylinders, both. select[1] for sphere, select[0] for cylinders
  Cylinder indices 0 - 9, sphere index 10
  */

  localparam RAY_INTERSECT_LATENCY = 168;
  localparam HP_LATENCY = 83;
  localparam MIN_LATENCY = 12;

  // localparam [SIZE-1:0] FLOAT_MAX = 64'h7FEFFFFFFFFFFFFF;
  localparam [SIZE-1:0] FLOAT_MAX = 32'h7f7fffff;

  // localparam [16*SIZE-1:0] RESET_T_REG = 1024'h7FEFFFFFFFFFFFFF7FEFFFFFFFFFFFFF7FEFFFFFFFFFFFFF7FEFFFFFFFFFFFFF7FEFFFFFFFFFFFFE7FEFFFFFFFFFFFFF7FEFFFFFFFFFFFFF7FEFFFFFFFFFFFFF7FEFFFFFFFFFFFFF7FEFFFFFFFFFFFFF7FEFFFFFFFFFFFFF7FEFFFFFFFFFFFFF7FEFFFFFFFFFFFFF7FEFFFFFFFFFFFFF7FEFFFFFFFFFFFFF7FEFFFFFFFFFFFFF;
  localparam [16*SIZE-1:0] RESET_T_REG = 512'h7f7fffff7f7fffff7f7fffff7f7fffff7f7fffff7f7fffff7f7fffff7f7fffff7f7fffff7f7fffff7f7fffff7f7fffff7f7fffff7f7fffff7f7fffff7f7fffff;

  // localparam [3*SIZE-1:0] CAMERA_LOC = 192'h000000000000000000000000000000004014000000000000;
  localparam [3*SIZE-1:0] CAMERA_LOC = 96'h000000000000000040a00000;

  logic ray_intersect_ready;
  logic [SIZE-1:0] t_result;
  logic undef_result;
  logic t_valid;

  logic pipe_ray_ready;
  logic [5:0][SIZE-1:0] pipe_ray_result;
  logic pipe_ray_valid;

  logic [10:0] pipe_hcount1_result;
  logic pipe_hcount1_valid;

  logic [9:0] pipe_vcount1_result;
  logic pipe_vcount1_valid;

  logic pipe_hcount2_ready;
  logic [10:0] pipe_hcount2_result;
  logic pipe_hcount2_valid;

  logic pipe_vcount2_ready;
  logic [9:0] pipe_vcount2_result;
  logic pipe_vcount2_valid;

  logic [3:0] pipe_obj_idx1_result;
  logic pipe_obj_idx1_valid;

  logic pipe_obj_idx2_ready;
  logic [3:0] pipe_obj_idx2_result;
  logic pipe_obj_idx2_valid;

  logic pipe_obj_idx3_ready;
  logic [3:0] pipe_obj_idx3_result;
  logic pipe_obj_idx3_valid;

  logic pipe_t_ready;
  logic [SIZE-1:0] pipe_t_result;
  logic pipe_t_valid;

  logic pipe_hit_normal_ready;
  logic [5:0][SIZE-1:0] pipe_hit_normal_result;
  logic pipe_hit_normal_valid;

  logic hit_point_t_ready;
  logic hit_point_ray_ready;
  logic [2:0][SIZE-1:0] hit_point_result;
  logic [2:0][SIZE-1:0] normal_result;
  logic hit_point_valid;
  logic normal_valid;
  logic invalid_cylinder_hit;

  logic t_argmin_ready;
  logic [3:0] t_argmin_result;
  logic t_argmin_valid;

  //batch input system
  logic [3:0] count_reg;
  logic [3:0] count_end_reg;
  logic [3:0][SIZE-1:0] ray_reg;
  logic [10:0] hcount_reg;
  logic [9:0] vcount_reg;
  logic resting;

  logic [3:0] current_count;
  logic [3:0] current_count_end;
  logic [2:0][SIZE-1:0] current_ray;
  logic [10:0] current_hcount;
  logic [9:0] current_vcount;

  assign current_count = resting ? (select_objs[0] ? 0 : 10) : count_reg; 
  assign current_count_end = resting ? (select_objs[1] ? 10 : 9) : count_end_reg; 
  assign current_ray = resting ? ray_axis_tdata : ray_reg;
  assign current_hcount = resting ? hcount_axis_tdata : hcount_reg;
  assign current_vcount = resting ? vcount_axis_tdata : vcount_reg;

  always_ff @(posedge aclk) begin
    if(~aresetn) begin
      count_reg <= 0;
      count_end_reg <= 0;
      ray_reg <= 0;
      hcount_reg <= 0;
      vcount_reg <= 0;
      resting <= 1;
    end else if(ray_intersect_ready) begin
      if(current_count == current_count_end) begin
        resting <= 1;
      end else if(resting == 1) begin
        if(ray_axis_tvalid == 1) begin
          count_reg <= current_count + 1;
          count_end_reg <= current_count_end;
          ray_reg <= current_ray;
          hcount_reg <= current_hcount;
          vcount_reg <= current_vcount;
          resting <= 0; //if length 1 job, would have gone into first if
        end
      end else begin
          count_reg <= current_count + 1;
      end
    end
  end

  assign ray_axis_tready = resting && ray_intersect_ready;

  logic valid_pipeline_input;
  assign valid_pipeline_input = resting == 0 || (resting == 1 && ray_axis_tvalid == 1);

  logic [5:0][SIZE-1:0] intersect_input;
  assign intersect_input = current_count == 10 ? sphere : cylinders[current_count];

  ray_intersect #(.SIZE(SIZE)) r_intersect(
    .obj_axis_tdata(intersect_input),
    .obj_axis_tvalid(1'b1),
    .obj_axis_tready(),
    .obj_axis_is_cylinder(~(current_count == 10)),
    .ray_axis_tdata({current_ray, CAMERA_LOC}),
    .ray_axis_tvalid(valid_pipeline_input),
    .ray_axis_tready(ray_intersect_ready),
    .t_axis_tdata(t_result),
    .undef_axis_tdata(undef_result),
    .t_axis_tvalid(t_valid),
    .t_axis_tready(hit_point_t_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(RAY_INTERSECT_LATENCY), .SIZE(SIZE*6)) pipe_ray (
    .s_axis_a_tdata({current_ray, CAMERA_LOC}),
    .s_axis_a_tready(pipe_ray_ready),
    .s_axis_a_tvalid(valid_pipeline_input),
    .m_axis_result_tdata(pipe_ray_result),
    .m_axis_result_tvalid(pipe_ray_valid),
    .m_axis_result_tready(hit_point_ray_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  logic pipe_hcount1_input_valid;
  assign pipe_hcount1_input_valid = valid_pipeline_input && (current_count == current_count_end);

  axi_pipe #(.LATENCY(RAY_INTERSECT_LATENCY + HP_LATENCY), .SIZE(11)) pipe_hcount1 (
    .s_axis_a_tdata(current_hcount),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(pipe_hcount1_input_valid), //hcount and vcount aligned with last item in the batch
    .m_axis_result_tdata(pipe_hcount1_result),
    .m_axis_result_tvalid(pipe_hcount1_valid),
    .m_axis_result_tready(pipe_hcount2_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(RAY_INTERSECT_LATENCY + HP_LATENCY), .SIZE(10)) pipe_vcount1 (
    .s_axis_a_tdata(current_vcount),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(valid_pipeline_input && current_count == current_count_end), //hcount and vcount aligned with last item in the batch
    .m_axis_result_tdata(pipe_vcount1_result),
    .m_axis_result_tvalid(pipe_vcount1_valid),
    .m_axis_result_tready(pipe_vcount2_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(RAY_INTERSECT_LATENCY), .SIZE(4)) pipe_obj_idx1 (
    .s_axis_a_tdata(current_count),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(valid_pipeline_input),
    .m_axis_result_tdata(pipe_obj_idx1_result),
    .m_axis_result_tvalid(pipe_obj_idx1_valid),
    .m_axis_result_tready(pipe_obj_idx2_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  ); 

  axi_pipe #(.LATENCY(HP_LATENCY), .SIZE(4)) pipe_obj_idx2 (
    .s_axis_a_tdata(pipe_obj_idx1_result),
    .s_axis_a_tready(pipe_obj_idx2_ready),
    .s_axis_a_tvalid(pipe_obj_idx1_valid),
    .m_axis_result_tdata(pipe_obj_idx2_result),
    .m_axis_result_tvalid(pipe_obj_idx2_valid),
    .m_axis_result_tready(pipe_obj_idx3_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  ); 

  axi_pipe #(.LATENCY(HP_LATENCY), .SIZE(SIZE)) pipe_t (
    .s_axis_a_tdata(undef_result ? FLOAT_MAX : t_result),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(t_valid),
    .m_axis_result_tdata(pipe_t_result),
    .m_axis_result_tvalid(pipe_t_valid),
    .m_axis_result_tready(t_argmin_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  ); 

  logic [5:0][SIZE-1:0] hp_obj_input;
  assign hp_obj_input = pipe_obj_idx1_result == 10 ? sphere : cylinders[pipe_obj_idx1_result];

  logic obj_axis_is_cylinder;
  assign obj_axis_is_cylinder = ~(pipe_obj_idx1_result == 10);

  hit_point #(.SIZE(SIZE)) hp (
    .obj_axis_tdata(hp_obj_input),
    .obj_axis_is_cylinder(obj_axis_is_cylinder),
    .obj_axis_tready(),
    .obj_axis_tvalid(1'b1),
    .t_axis_tdata(t_result),
    .t_axis_tvalid(t_valid),
    .t_axis_tready(hit_point_t_ready),
    .ray_axis_tdata(pipe_ray_result),
    .ray_axis_tvalid(pipe_ray_valid),
    .ray_axis_tready(hit_point_ray_ready),
    .hit_point_axis_tdata(hit_point_result),
    .hit_point_axis_tvalid(hit_point_valid),
    .hit_point_axis_tready(pipe_hit_normal_ready),
    .normal_axis_tdata(normal_result),
    .normal_axis_tvalid(normal_valid),
    .normal_axis_tready(pipe_hit_normal_ready),
    .invalid_cylinder_hit(invalid_cylinder_hit),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(MIN_LATENCY + 1), .SIZE(11)) pipe_hcount2 (
    .s_axis_a_tdata(pipe_hcount1_result),
    .s_axis_a_tready(pipe_hcount2_ready),
    .s_axis_a_tvalid(pipe_hcount1_valid),
    .m_axis_result_tdata(hcount_out),
    .m_axis_result_tvalid(pipe_hcount2_valid),
    .m_axis_result_tready(normal_axis_tready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(MIN_LATENCY + 1), .SIZE(10)) pipe_vcount2 (
    .s_axis_a_tdata(pipe_vcount1_result),
    .s_axis_a_tready(pipe_vcount2_ready),
    .s_axis_a_tvalid(pipe_vcount1_valid),
    .m_axis_result_tdata(vcount_out),
    .m_axis_result_tvalid(pipe_vcount2_valid),
    .m_axis_result_tready(normal_axis_tready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(MIN_LATENCY), .SIZE(4)) pipe_obj_idx3 (
    .s_axis_a_tdata(pipe_obj_idx2_result),
    .s_axis_a_tready(pipe_obj_idx3_ready),
    .s_axis_a_tvalid(pipe_obj_idx2_valid),
    .m_axis_result_tdata(pipe_obj_idx3_result),
    .m_axis_result_tvalid(pipe_obj_idx3_valid),
    .m_axis_result_tready(normal_axis_tready),
    .aclk(aclk),
    .aresetn(aresetn)
  ); 

  axi_pipe #(.LATENCY(MIN_LATENCY), .SIZE(6*SIZE)) pipe_hit_normal (
    .s_axis_a_tdata({normal_result, hit_point_result}),
    .s_axis_a_tready(pipe_hit_normal_ready),
    .s_axis_a_tvalid(normal_valid),
    .m_axis_result_tdata(pipe_hit_normal_result),
    .m_axis_result_tvalid(pipe_hit_normal_valid),
    .m_axis_result_tready(normal_axis_tready),
    .aclk(aclk),
    .aresetn(aresetn)
  ); 

  logic [15:0][SIZE-1:0] t_reg;
  logic delayed_pipe_hcount1_valid;

  always_ff @(posedge aclk) begin
    delayed_pipe_hcount1_valid <= pipe_hcount1_valid;
    if(~aresetn || delayed_pipe_hcount1_valid) begin
      t_reg <= RESET_T_REG;
    end
    if(pipe_obj_idx2_valid) begin
      t_reg[pipe_obj_idx2_result] <= invalid_cylinder_hit ? FLOAT_MAX : pipe_t_result;
    end
  end

  float_multi_argmin #(.SIZE(SIZE)) t_argmin (
    .s_axis_a_tdata(t_reg),
    .s_axis_a_tready(t_argmin_ready),
    .s_axis_a_tvalid(delayed_pipe_hcount1_valid),
    .m_axis_result_tdata(t_argmin_result),
    .m_axis_result_tvalid(t_argmin_valid),
    .m_axis_result_tready(1'b1),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  logic [15:0][5:0][SIZE-1:0] hp_reg;

  always_ff @(posedge aclk) begin
    if(pipe_obj_idx3_valid) begin
      hp_reg[pipe_obj_idx3_valid] <= pipe_hit_normal_result;
    end
  end

  logic [5:0][SIZE-1:0] selected_hp;

  xilinx_true_dual_port_read_first_2_clock_ram #(
      .RAM_WIDTH(6*SIZE),                       // Specify RAM data width
      .RAM_DEPTH(16),                     // Specify RAM depth (number of entries)
      .RAM_PERFORMANCE("LOW_LATENCY"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
      .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) ram (
      .addra(pipe_obj_idx3_result),   // Port A address bus, width determined from RAM_DEPTH
      .addrb(t_argmin_result),   // Port B address bus, width determined from RAM_DEPTH
      .dina(pipe_hit_normal_result),     // Port A RAM input data, width determined from RAM_WIDTH
      .dinb(1'b0),     // Port B RAM input data, width determined from RAM_WIDTH
      .clka(aclk),     // Port A clock
      .clkb(aclk),     // Port B clock
      .wea(pipe_obj_idx3_valid),       // Port A write enable
      .web(1'b0),       // Port B write enable
      .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
      .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
      .rsta(~aresetn),     // Port A output reset (does not affect memory contents)
      .rstb(~aresetn),     // Port B output reset (does not affect memory contents)
      .regcea(1'b0), // Port A output register enable
      .regceb(1'b1), // Port B output register enable
      // .douta(douta),   // Port A RAM output data, width determined from RAM_WIDTH
      .doutb(selected_hp)    // Port B RAM output data, width determined from RAM_WIDTH
  );

  logic [SIZE-1:0] delayed_t_argmin;

  always_ff @(posedge aclk) begin
    normal_axis_tvalid <= t_argmin_valid;
    hit_point_axis_tvalid <= t_argmin_valid;
    delayed_t_argmin <= t_argmin_result;
  end

  assign hit_point_axis_tdata = selected_hp[2:0];
  assign normal_axis_tdata = selected_hp[5:3];
  assign hit_cylinder = delayed_t_argmin < 10;
  assign hit_sphere = delayed_t_argmin == 10;

endmodule
`default_nettype wire