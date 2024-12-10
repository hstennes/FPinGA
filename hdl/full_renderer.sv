`timescale 1ns / 1ps
`default_nettype none

module full_renderer #(parameter SIZE=32) (
  input wire [10:0] hcount_axis_tdata,
  input wire hcount_axis_tvalid,
  output logic hcount_axis_tready,
  input wire [9:0] vcount_axis_tdata,
  input wire vcount_axis_tvalid,
  output logic vcount_axis_tready,
  input wire [1:0] select_objs,
  input wire [5:0][SIZE-1:0] sphere,
  input wire [9:0][5:0][SIZE-1:0] cylinders,
  output logic [23:0] pixel_axis_tdata,
  output logic pixel_axis_tvalid,
  input wire pixel_axis_tready,
  input wire aclk,
  output logic [10:0] hcount_out,
  output logic [9:0] vcount_out,
  input wire aresetn
  );

  /*
  When passing a ray, also pass in which objects should be checked.
  Options - just sphere, just cylinders, both
  */

  //TOTAL LATENCY = 339

  // localparam [3*SIZE-1:0] CAMERA_LOC = 192'h000000000000000000000000000000004014000000000000;
  localparam [3*SIZE-1:0] CAMERA_LOC = 96'h431000004316000044160000;

  localparam PIPE_RAY_LATENCY = 168;
  localparam PIPE_HVCOUNT1_LATENCY = 24;
  localparam PIPE_SELECT_OBJS_LATENCY = 24;
  localparam PIPE_UNDEF_LATENCY = 64;
  localparam PIPE_HVCOUNT2_LATENCY = 64;
  localparam PIPE_INVALID_CYLINDER_HIT_LATENCY = 64;
  localparam TOTAL_LATENCY = 339;

  logic [2:0][SIZE-1:0] ray_data;
  logic ray_valid;

  logic pipe_ray_ready;
  logic [5:0][SIZE-1:0] pipe_ray_result;
  logic undef_result;
  logic pipe_ray_valid;

  logic check_objects_ready;
  logic [2:0][SIZE-1:0] check_objects_hit_point_result;
  logic check_objects_hit_point_valid;
  logic [2:0][SIZE-1:0] check_objects_normal_result;
  logic check_objects_normal_valid;
  logic check_objects_hit_cylinder;
  logic check_objects_hit_sphere;
  logic [10:0] check_objects_hcount_out;
  logic [9:0] check_objects_vcount_out;

  logic lambert_hit_point_ready;
  logic lambert_normal_ready;

  logic pipe_undef_ready;
  logic pipe_undef_result;
  logic pipe_undef_valid;

  logic [10:0] pipe_hcount1_result;
  logic pipe_hcount1_valid;

  logic [9:0] pipe_vcount1_result;
  logic pipe_vcount1_valid;

  logic [1:0] pipe_select_objs_result;
  logic pipe_select_objs_valid;

  logic pipe_hcount2_ready;
  logic pipe_vcount2_ready;

  logic pipe_invalid_cylinder_hit_result;
  logic pipe_invalid_cylinder_hit_valid;

  logic [23:0] output_pixel;

  axi_pipe #(.LATENCY(PIPE_HVCOUNT1_LATENCY), .SIZE(11)) pipe_hcount1 (
    .s_axis_a_tdata(hcount_axis_tdata),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(hcount_axis_tvalid),
    .m_axis_result_tdata(pipe_hcount1_result),
    .m_axis_result_tvalid(pipe_hcount1_valid),
    .m_axis_result_tready(check_objects_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_HVCOUNT1_LATENCY), .SIZE(10)) pipe_vcount1 (
    .s_axis_a_tdata(vcount_axis_tdata),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(vcount_axis_tvalid),
    .m_axis_result_tdata(pipe_vcount1_result),
    .m_axis_result_tvalid(pipe_vcount1_valid),
    .m_axis_result_tready(check_objects_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_SELECT_OBJS_LATENCY), .SIZE(2)) pipe_select_objs (
    .s_axis_a_tdata(select_objs),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(vcount_axis_tvalid),
    .m_axis_result_tdata(pipe_select_objs_result),
    .m_axis_result_tvalid(pipe_select_objs_valid),
    .m_axis_result_tready(check_objects_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  ray_from_pixel #(.SIZE(SIZE)) rfp(
    .hcount_axis_tdata(hcount_axis_tdata),
    .hcount_axis_tvalid(hcount_axis_tvalid),
    .hcount_axis_tready(hcount_axis_tready),
    .vcount_axis_tdata(vcount_axis_tdata),
    .vcount_axis_tvalid(vcount_axis_tvalid),
    .vcount_axis_tready(vcount_axis_tready),
    .ray_axis_tdata(ray_data),
    .ray_axis_tvalid(ray_valid),
    .ray_axis_tready(check_objects_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  // input wire [2:0][SIZE-1:0] ray_axis_tdata,
  // input wire [1:0] select_objs,
  // input wire [10:0] hcount_axis_tdata,
  // input wire [9:0] vcount_axis_tdata,
  // input wire ray_axis_tvalid,
  // output logic ray_axis_tready,
  // input wire [5:0][SIZE-1:0] sphere,
  // input wire [9:0][5:0][SIZE-1:0] cylinders,
  // output logic [2:0][SIZE-1:0] hit_point_axis_tdata,
  // output logic hit_point_axis_tvalid,
  // input wire hit_point_axis_tready,
  // output logic [2:0][SIZE-1:0] normal_axis_tdata,
  // output logic normal_axis_tvalid,
  // input wire normal_axis_tready,
  // output logic hit_cylinder,
  // output logic hit_sphere,
  // output logic [10:0] hcount_out,
  // output logic [9:0] vcount_out,
  // input wire aclk,
  // input wire aresetn

  check_objects #(.SIZE(SIZE)) check_objects(
    .ray_axis_tdata(ray_data),
    .select_objs(/*pipe_vcount1_result[0] == 1 ? 2'b01 : 2'b10*/ pipe_select_objs_result),
    .hcount_axis_tdata(pipe_hcount1_result),
    .vcount_axis_tdata(pipe_vcount1_result),
    .ray_axis_tvalid(ray_valid),
    .ray_axis_tready(check_objects_ready),
    .sphere(sphere),
    .cylinders(cylinders),
    .hit_point_axis_tdata(check_objects_hit_point_result),
    .hit_point_axis_tvalid(check_objects_hit_point_valid),
    .hit_point_axis_tready(lambert_hit_point_ready),
    .normal_axis_tdata(check_objects_normal_result),
    .normal_axis_tvalid(check_objects_normal_valid),
    .normal_axis_tready(lambert_normal_ready),
    .hit_cylinder(check_objects_hit_cylinder),
    .hit_sphere(check_objects_hit_sphere),
    .hcount_out(check_objects_hcount_out),
    .vcount_out(check_objects_vcount_out),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_UNDEF_LATENCY), .SIZE(1)) pipe_undef (
    .s_axis_a_tdata(~(check_objects_hit_cylinder || check_objects_hit_sphere)),
    .s_axis_a_tready(pipe_undef_ready),
    .s_axis_a_tvalid(check_objects_hit_point_valid),
    .m_axis_result_tdata(pipe_undef_result),
    .m_axis_result_tvalid(pipe_undef_valid),
    .m_axis_result_tready(pixel_axis_tready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  lambert #(.SIZE(SIZE)) lam (
    .hit_point_axis_tdata(check_objects_hit_point_result),
    .hit_point_axis_tvalid(check_objects_hit_point_valid),
    .hit_point_axis_tready(lambert_hit_point_ready),
    .normal_axis_tdata(check_objects_normal_result),
    .normal_axis_tvalid(check_objects_normal_valid),
    .normal_axis_tready(lambert_normal_ready),
    .is_cylinder(check_objects_hit_cylinder),
    .pixel_axis_tdata(output_pixel),
    .pixel_axis_tvalid(pixel_axis_tvalid),
    .pixel_axis_tready(pixel_axis_tready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_HVCOUNT2_LATENCY), .SIZE(11)) pipe_hcount2 (
    .s_axis_a_tdata(check_objects_hcount_out),
    .s_axis_a_tready(pipe_hcount2_ready),
    .s_axis_a_tvalid(check_objects_hit_point_valid),
    .m_axis_result_tdata(hcount_out),
    .m_axis_result_tvalid(),
    .m_axis_result_tready(pixel_axis_tready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_HVCOUNT2_LATENCY), .SIZE(10)) pipe_vcount2 (
    .s_axis_a_tdata(check_objects_vcount_out),
    .s_axis_a_tready(pipe_vcount2_ready),
    .s_axis_a_tvalid(check_objects_hit_point_valid),
    .m_axis_result_tdata(vcount_out),
    .m_axis_result_tvalid(),
    .m_axis_result_tready(pixel_axis_tready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  assign pixel_axis_tdata = (pipe_undef_result) ? 24'b0 : output_pixel;

endmodule
`default_nettype wire