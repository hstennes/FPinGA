`timescale 1ns / 1ps
`default_nettype none

module renderer #(parameter SIZE=32) (
  input wire [10:0] hcount_axis_tdata,
  input wire hcount_axis_tvalid,
  output logic hcount_axis_tready,
  input wire [9:0] vcount_axis_tdata,
  input wire vcount_axis_tvalid,
  output logic vcount_axis_tready,
  input wire [5:0][SIZE-1:0] sphere,
  input wire [9:0][5:0][SIZE-1:0] cylinders,
  output logic [23:0] pixel_axis_tdata,
  output logic pixel_axis_tvalid,
  input logic pixel_axis_tready,
  input wire aclk,
  input wire aresetn
  );

  localparam [3*SIZE-1:0] CAMERA_LOC = 192'h000000000000000000000000000000004014000000000000;

  localparam PIPE_RAY_LATENCY = 168;

  logic [2:0][SIZE-1:0] ray_data;
  logic ray_valid;

  logic ray_intersect_ready;
  logic [SIZE-1:0] t_result;
  logic t_valid;

  logic pipe_ray_ready;
  logic [5:0][SIZE-1:0] pipe_ray_result;
  logic pipe_ray_valid;

  logic hit_point_t_ready;
  logic hit_point_ray_ready;
  logic [2:0][SIZE-1:0] hit_point_result;
  logic [2:0][SIZE-1:0] normal_result;
  logic hit_point_valid;
  logic normal_valid;

  logic lambert_hit_point_ready;
  logic lambert_normal_ready;

  ray_from_pixel #(.SIZE(SIZE)) rfp(
    .hcount_axis_tdata(hcount_axis_tdata),
    .hcount_axis_tvalid(hcount_axis_tvalid),
    .hcount_axis_tready(hcount_axis_tready),
    .vcount_axis_tdata(vcount_axis_tdata),
    .vcount_axis_tvalid(vcount_axis_tvalid),
    .vcount_axis_tready(vcount_axis_tready),
    .ray_axis_tdata(ray_data),
    .ray_axis_tvalid(ray_valid),
    .ray_axis_tready(ray_intersect_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_RAY_LATENCY), .SIZE(SIZE*6)) pipe_ray (
    .s_axis_a_tdata({ray_data, CAMERA_LOC}),
    .s_axis_a_tready(pipe_ray_ready),
    .s_axis_a_tvalid(ray_valid),
    .m_axis_result_tdata(pipe_ray_result),
    .m_axis_result_tvalid(pipe_ray_valid),
    .m_axis_result_tready(hit_point_ray_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  ray_intersect #(.SIZE(SIZE)) intersectisakeywordapparently(
    .obj_axis_tdata(sphere),
    .obj_axis_tvalid(1'b1),
    .obj_axis_tready(),
    .obj_axis_is_cylinder(1'b0),
    .ray_axis_tdata({ray_data, CAMERA_LOC}),
    .ray_axis_tvalid(ray_valid),
    .ray_axis_tready(ray_intersect_ready),
    .t_axis_tdata(t_result),
    .t_axis_tvalid(t_valid),
    .t_axis_tready(hit_point_t_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  hit_point #(.SIZE(SIZE)) hp (
    .obj_axis_tdata(sphere),
    .obj_axis_is_cylinder(1'b0),
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
    .hit_point_axis_tready(lambert_hit_point_ready),
    .normal_axis_tdata(normal_result),
    .normal_axis_tvalid(normal_valid),
    .normal_axis_tready(lambert_normal_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  lambert #(.SIZE(SIZE)) lam (
    .hit_point_axis_tdata(hit_point_result),
    .hit_point_axis_tvalid(hit_point_valid),
    .hit_point_axis_tready(lambert_hit_point_ready),
    .normal_axis_tdata(normal_result),
    .normal_axis_tvalid(normal_valid),
    .normal_axis_tready(lambert_normal_ready),
    .is_cylinder(1'b0),
    .pixel_axis_tdata(pixel_axis_tdata),
    .pixel_axis_tvalid(pixel_axis_tvalid),
    .pixel_axis_tready(pixel_axis_tready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

endmodule
`default_nettype wire