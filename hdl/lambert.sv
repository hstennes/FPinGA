`timescale 1ns / 1ps
`default_nettype none

module lambert #(parameter SIZE) (
  input wire [2:0][SIZE-1:0] hit_point_axis_tdata,
  input wire hit_point_axis_tvalid,
  output logic hit_point_axis_tready,
  input wire [2:0][SIZE-1:0] normal_axis_tdata,
  input wire normal_axis_tvalid,
  output logic normal_axis_tready,
  input wire is_cylinder,
  output logic [23:0] pixel_axis_tdata,
  output logic pixel_axis_tvalid,
  input wire pixel_axis_tready,
  input wire aclk,
  input wire aresetn);

  //TOTAL LATENCY: 64

  localparam PIPE_NORMAL_LATENCY = 12;
  localparam PIPE_IS_CYLINDER_LATENCY = 45;

  // localparam [3*SIZE-1:0] LIGHT_LOC = 192'h0000000000000000401C000000000000401C000000000000;
  // localparam [3*SIZE-1:0] SPHERE_COLOR = 192'h0000000000000000406FE000000000000000000000000000;
  // localparam [3*SIZE-1:0] CYLINDER_COLOR = 192'h406FE00000000000406FE00000000000406FE00000000000;

  localparam [3*SIZE-1:0] LIGHT_LOC = 96'h0000000042340000428c0000;
  localparam [3*SIZE-1:0] SPHERE_COLOR = 96'h000000004316000000000000;
  localparam [3*SIZE-1:0] CYLINDER_COLOR = 96'h437f0000437f0000437f0000;

  logic [2:0][SIZE-1:0] light_dir_result;
  logic light_dir_valid;

  logic [2:0][SIZE-1:0] pipe_normal_result;
  logic pipe_normal_valid;

  logic dot_light_dir_ready;
  logic dot_normal_ready;
  logic [SIZE-1:0] dot_result;
  logic dot_valid;

  logic pipe_is_cylinder_result;
  logic pipe_is_cylinder_valid;

  logic color_dot_ready;
  logic color_paint_ready;
  logic [2:0][SIZE-1:0] color_result;
  logic color_valid;

  logic pixel_ready;

  logic [2:0][SIZE-1:0] neg_hit_point;
  assign neg_hit_point = {{~hit_point_axis_tdata[2][SIZE-1], hit_point_axis_tdata[2][SIZE-2:0]}, {~hit_point_axis_tdata[1][SIZE-1], hit_point_axis_tdata[1][SIZE-2:0]}, {~hit_point_axis_tdata[0][SIZE-1], hit_point_axis_tdata[0][SIZE-2:0]}};

  vec_add #(.SIZE(SIZE)) light_dir (
    .s_axis_a_tdata(neg_hit_point),
    .s_axis_a_tready(hit_point_axis_tready),
    .s_axis_a_tvalid(hit_point_axis_tvalid),
    .s_axis_b_tdata(LIGHT_LOC), //* -4
    .s_axis_b_tready(),
    .s_axis_b_tvalid(1'b1),
    .m_axis_result_tdata(light_dir_result),
    .m_axis_result_tready(dot_light_dir_ready),
    .m_axis_result_tvalid(light_dir_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_NORMAL_LATENCY), .SIZE(SIZE*3)) pipe_normal(
    .s_axis_a_tdata(normal_axis_tdata),
    .s_axis_a_tready(normal_axis_tready),
    .s_axis_a_tvalid(normal_axis_tvalid),
    .m_axis_result_tdata(pipe_normal_result),
    .m_axis_result_tvalid(pipe_normal_valid),
    .m_axis_result_tready(dot_normal_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  vec_dot #(.SIZE(SIZE)) dot(
    .s_axis_a_tdata(light_dir_result),
    .s_axis_a_tready(dot_light_dir_ready),
    .s_axis_a_tvalid(light_dir_valid),
    .s_axis_b_tdata(pipe_normal_result),
    .s_axis_b_tready(dot_normal_ready),
    .s_axis_b_tvalid(pipe_normal_valid),
    .m_axis_result_tdata(dot_result),
    .m_axis_result_tready(color_dot_ready),
    .m_axis_result_tvalid(dot_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_IS_CYLINDER_LATENCY), .SIZE(1)) pipe_is_cylinder (
    .s_axis_a_tdata(is_cylinder),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(normal_axis_tvalid),
    .m_axis_result_tdata(pipe_is_cylinder_result),
    .m_axis_result_tvalid(pipe_is_cylinder_valid),
    .m_axis_result_tready(color_paint_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  logic [SIZE-1:0] scale_dot_result;

  float_mul_pow2 #(.SIZE(SIZE), .POW(-6)) scale_pipe_a(
    .in_float(dot_result),
    .result(scale_dot_result)
  );

  vec_mul #(.SIZE(SIZE)) color(
    .s_axis_a_tdata(pipe_is_cylinder_result ? CYLINDER_COLOR : SPHERE_COLOR),
    .s_axis_a_tready(color_paint_ready),
    .s_axis_a_tvalid(pipe_is_cylinder_valid),
    .s_axis_b_tdata(scale_dot_result),
    .s_axis_b_tready(color_dot_ready),
    .s_axis_b_tvalid(dot_valid),
    .m_axis_result_tdata(color_result),
    .m_axis_result_tvalid(color_valid),
    .m_axis_result_tready(pixel_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  vec_to_pixel_color #(.SIZE(SIZE)) pixel(
    .s_axis_a_tdata(color_result),
    .s_axis_a_tready(pixel_ready),
    .s_axis_a_tvalid(color_valid),
    .m_axis_result_tdata(pixel_axis_tdata),
    .m_axis_result_tvalid(pixel_axis_tvalid),
    .m_axis_result_tready(pixel_axis_tready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

endmodule
`default_nettype wire