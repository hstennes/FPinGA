`timescale 1ns / 1ps
`default_nettype none

module lambert #(parameter SIZE=64) (
  input wire [2:0][SIZE-1:0] hit_point_axis_tdata,
  input wire hit_point_axis_tvalid,
  output logic hit_point_axis_tready,
  input wire [2:0][SIZE-1:0] normal_axis_tdata,
  input wire normal_axis_tvalid,
  output logic normal_axis_tready,
  input wire is_cylinder,
  output logic [23:0] pixel_axis_tdata;
  output logic pixel_axis_tvalid;
  input logic pixel_axis_tready;
  input wire aclk,
  input wire aresetn);

  //TOTAL LATENCY: 17

  localparam [SIZE-1:0] PX_MUL = 64'h3F76C16C16C16C16;
  localparam [SIZE-1:0] PX_ADD = 64'hBFFC71C71C71C71B;
  localparam [SIZE-1:0] PY_MUL = 64'hBF76C16C16C16C16;
  localparam [SIZE-1:0] PY_ADD = 64'h3FEFFFFFFFFFFFFF;
  localparam [SIZE-1:0] PZ = 64'hBFF0000000000000;

  logic [SIZE-1:0] light_dir_result;
  logic light_dir_valid;

  logic [SIZE-1:0] pipe_normal_result;
  logic pipe_normal_valid;

  logic norm_normal_ready;
  logic [SIZE-1:0] norm_normal_result;
  logic norm_normal_valid;

  logic norm_light_dir_ready;
  logic [SIZE-1:0] norm_light_dir_result;
  logic norm_light_dir_valid;

  logic dot_light_dir_ready;
  logic dot_normal_ready;
  logic [SIZE-1:0] dot_result;
  logic dot_valid;

  logic mul_normal_ready;
  logic mul_light_dir_ready;
  logic [SIZE-1:0] mul_result;
  logic mul_valid;

  logic int_num_ready;
  logic int_den_ready;
  logic [SIZE-1:0] int_result;
  logic int_valid;

  logic color_int_ready;
  logic color_paint_ready;
  logic [SIZE-1:0] color_result;
  logic color_valid;

  logic pixel_ready;

  logic [2:0][SIZE-1:0] neg_hit_point;
  assign neg_hit_point = {}

  vec_add light_dir (
    .s_axis_a_tdata(b_sq_result),
    .s_axis_a_tready(disc_b_sq_ready),
    .s_axis_a_tvalid(b_sq_valid),
    .s_axis_b_tdata(scale_ac_result), //* -4
    .s_axis_b_tready(disc_ac_ready),
    .s_axis_b_tvalid(ac_valid),
    .m_axis_result_tdata(disc_result),
    .m_axis_result_tready(sqrt_ready),
    .m_axis_result_tvalid(disc_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_A_LATENCY)) pipe_a(
    .s_axis_a_tdata(s_axis_a_tdata),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(s_axis_a_tvalid),
    .m_axis_result_tdata(pipe_a_result),
    .m_axis_result_tvalid(pipe_a_valid),
    .m_axis_result_tready(div_den_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  vec_norm #(.LATENCY(PIPE_A_LATENCY)) pipe_a(
    .s_axis_a_tdata(s_axis_a_tdata),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(s_axis_a_tvalid),
    .m_axis_result_tdata(pipe_a_result),
    .m_axis_result_tvalid(pipe_a_valid),
    .m_axis_result_tready(div_den_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  vec_norm #(.LATENCY(PIPE_A_LATENCY)) pipe_a(
    .s_axis_a_tdata(s_axis_a_tdata),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(s_axis_a_tvalid),
    .m_axis_result_tdata(pipe_a_result),
    .m_axis_result_tvalid(pipe_a_valid),
    .m_axis_result_tready(div_den_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  vec_dot #(.SIZE(SIZE)) dd(
    .s_axis_a_tdata(ray_axis_tdata[5:3]),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(ray_axis_tvalid),
    .s_axis_b_tdata(ray_axis_tdata[5:3]),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(ray_axis_tvalid),
    .m_axis_result_tdata(dd_result),
    .m_axis_result_tready(pipe_a_ready),
    .m_axis_result_tvalid(dd_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_mul ac(
    .s_axis_a_tdata(s_axis_a_tdata),
    .s_axis_a_tready(s_axis_a_tready),
    .s_axis_a_tvalid(s_axis_a_tvalid),
    .s_axis_b_tdata(s_axis_c_tdata),
    .s_axis_b_tready(s_axis_c_tready),
    .s_axis_b_tvalid(s_axis_c_tvalid),
    .m_axis_result_tdata(ac_result),
    .m_axis_result_tready(disc_ac_ready),
    .m_axis_result_tvalid(ac_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_div div(
    .s_axis_a_tdata(cmp_result),
    .s_axis_a_tready(div_num_ready),
    .s_axis_a_tvalid(cmp_valid),
    .s_axis_b_tdata(scale_pipe_a_result), //* 2
    .s_axis_b_tready(div_den_ready),
    .s_axis_b_tvalid(pipe_a_valid),
    .m_axis_result_tdata(m_axis_result_tdata),
    .m_axis_result_tvalid(m_axis_result_tvalid),
    .m_axis_result_tready(m_axis_result_tready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  vec_mul color(
    .s_axis_a_tdata(cmp_result),
    .s_axis_a_tready(div_num_ready),
    .s_axis_a_tvalid(cmp_valid),
    .s_axis_b_tdata(scale_pipe_a_result), //* 2
    .s_axis_b_tready(div_den_ready),
    .s_axis_b_tvalid(pipe_a_valid),
    .m_axis_result_tdata(m_axis_result_tdata),
    .m_axis_result_tvalid(m_axis_result_tvalid),
    .m_axis_result_tready(m_axis_result_tready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  vec_to_pixel_color div(
    .s_axis_a_tdata(cmp_result),
    .s_axis_a_tready(div_num_ready),
    .s_axis_a_tvalid(cmp_valid),
    .s_axis_b_tdata(scale_pipe_a_result), //* 2
    .s_axis_b_tready(div_den_ready),
    .s_axis_b_tvalid(pipe_a_valid),
    .m_axis_result_tdata(m_axis_result_tdata),
    .m_axis_result_tvalid(m_axis_result_tvalid),
    .m_axis_result_tready(m_axis_result_tready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  assign ray_axis_tdata[0] = PZ;

endmodule
`default_nettype wire