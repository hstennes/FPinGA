`timescale 1ns / 1ps
`default_nettype none

module hit_point #(parameter SIZE) (
  input wire [5:0][SIZE-1:0] obj_axis_tdata,
  input wire obj_axis_is_cylinder,
  output logic obj_axis_tready,
  input wire obj_axis_tvalid,
  input wire [SIZE-1:0] t_axis_tdata,
  input wire t_axis_tvalid,
  output logic t_axis_tready,
  input wire [5:0][SIZE-1:0] ray_axis_tdata,
  output logic ray_axis_tready,
  input wire ray_axis_tvalid,
  output logic [2:0][SIZE-1:0] hit_point_axis_tdata,
  output logic hit_point_axis_tvalid,
  input logic hit_point_axis_tready,
  output logic [2:0][SIZE-1:0] normal_axis_tdata,
  output logic normal_axis_tvalid,
  input logic normal_axis_tready,
  input wire aclk,
  input wire aresetn);

  //TOTAL LATENCY: 17

  localparam PIPE_CENTER_LATENCY = 17;
  localparam PIPE_CA_LATENCY = 29;
  localparam PIPE_CA_2_LATENCY = 33;
  localparam PIPE_PRE_NORMAL_LATENCY = 42;
  localparam PIPE_HIT_POINT_LATENCY = 66;

  logic [2:0][SIZE-1:0] hit_point_result;
  logic hit_point_valid;

  logic [2:0][SIZE-1:0] pipe_center_result;
  logic pipe_center_valid;

  logic [2:0][SIZE-1:0] pipe_ca_result;
  logic pipe_ca_valid;

  logic pipe_ca_2_ready;
  logic [2:0][SIZE-1:0] pipe_ca_2_result;
  logic pipe_ca_2_valid;

  logic pre_normal_hp_ready;
  logic pre_normal_center_ready;
  logic [2:0][SIZE-1:0] pre_normal_result;
  logic pre_normal_valid;

  logic dot_pre_normal_ready;
  logic dot_ca_ready;
  logic [SIZE-1:0] dot_result;
  logic dot_valid;

  logic mul_dot_ready;
  logic mul_ca_ready;
  logic [2:0][SIZE-1:0] mul_result;
  logic mul_valid;

  logic pipe_pre_normal_ready;
  logic [2:0][SIZE-1:0] pipe_pre_normal_result;
  logic pipe_pre_normal_valid;

  logic normal_pre_normal_ready;
  logic normal_mul_ready;

  logic pipe_hit_point_ready;

  logic [SIZE*3-1:0] neg_center;
  assign neg_center = {{~obj_axis_tdata[2][SIZE-1], obj_axis_tdata[2][SIZE-2:0]}, {~obj_axis_tdata[1][SIZE-1], obj_axis_tdata[1][SIZE-2:0]}, {~obj_axis_tdata[0][SIZE-1], obj_axis_tdata[0][SIZE-2:0]}};

  vec_fused_mul_add #(.SIZE(SIZE)) hit_point (
    .s_axis_a_tdata(ray_axis_tdata[5:3]),
    .s_axis_a_tready(ray_axis_tready),
    .s_axis_a_tvalid(ray_axis_tvalid),
    .s_axis_b_tdata(t_axis_tdata),
    .s_axis_b_tready(t_axis_tready),
    .s_axis_b_tvalid(t_axis_tvalid),
    .s_axis_c_tdata(ray_axis_tdata[2:0]),
    .s_axis_c_tready(),
    .s_axis_c_tvalid(ray_axis_tvalid),
    .m_axis_result_tdata(hit_point_result),
    .m_axis_result_tready(pre_normal_hp_ready),
    .m_axis_result_tvalid(hit_point_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_CENTER_LATENCY), .SIZE(SIZE*3)) pipe_center(
    .s_axis_a_tdata(neg_center),
    .s_axis_a_tready(obj_axis_tready),
    .s_axis_a_tvalid(obj_axis_tvalid),
    .m_axis_result_tdata(pipe_center_result),
    .m_axis_result_tvalid(pipe_center_valid),
    .m_axis_result_tready(pre_normal_center_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  vec_add #(.SIZE(SIZE)) pre_normal(
    .s_axis_a_tdata(hit_point_result),
    .s_axis_a_tready(pre_normal_hp_ready),
    .s_axis_a_tvalid(hit_point_valid),
    .s_axis_b_tdata(pipe_center_result),
    .s_axis_b_tready(pre_normal_center_ready),
    .s_axis_b_tvalid(pipe_center_valid),
    .m_axis_result_tdata(pre_normal_result),
    .m_axis_result_tready(dot_pre_normal_ready),
    .m_axis_result_tvalid(pre_normal_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_CA_LATENCY), .SIZE(SIZE*3)) pipe_ca (
    .s_axis_a_tdata(obj_axis_tdata[5:3]),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(obj_axis_tvalid),
    .m_axis_result_tdata(pipe_ca_result),
    .m_axis_result_tvalid(pipe_ca_valid),
    .m_axis_result_tready(dot_ca_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  vec_dot #(.SIZE(SIZE)) dot(
    .s_axis_a_tdata(pre_normal_result),
    .s_axis_a_tready(dot_pre_normal_ready),
    .s_axis_a_tvalid(pre_normal_valid),
    .s_axis_b_tdata(pipe_ca_result),
    .s_axis_b_tready(dot_ca_ready),
    .s_axis_b_tvalid(pipe_ca_valid),
    .m_axis_result_tdata(dot_result),
    .m_axis_result_tready(mul_dot_ready),
    .m_axis_result_tvalid(dot_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_CA_2_LATENCY), .SIZE(SIZE*3)) pipe_ca_2 (
    .s_axis_a_tdata(pipe_ca_result),
    .s_axis_a_tready(pipe_ca_2_ready),
    .s_axis_a_tvalid(pipe_ca_valid),
    .m_axis_result_tdata(pipe_ca_2_result),
    .m_axis_result_tvalid(pipe_ca_2_valid),
    .m_axis_result_tready(mul_ca_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  vec_mul #(.SIZE(SIZE)) mul(
    .s_axis_a_tdata(pipe_ca_2_result),
    .s_axis_a_tready(mul_ca_ready),
    .s_axis_a_tvalid(pipe_ca_2_valid),
    .s_axis_b_tdata(dot_result),
    .s_axis_b_tready(mul_dot_ready),
    .s_axis_b_tvalid(dot_valid),
    .m_axis_result_tdata(mul_result),
    .m_axis_result_tready(normal_mul_ready),
    .m_axis_result_tvalid(mul_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_PRE_NORMAL_LATENCY), .SIZE(SIZE*3)) pipe_pre_normal (
    .s_axis_a_tdata(pre_normal_result),
    .s_axis_a_tready(pipe_pre_normal_ready),
    .s_axis_a_tvalid(pre_normal_valid),
    .m_axis_result_tdata(pipe_pre_normal_result),
    .m_axis_result_tvalid(pipe_pre_normal_valid),
    .m_axis_result_tready(normal_pre_normal_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  logic [2:0][SIZE-1:0] neg_mul;
  assign neg_mul = {{~mul_result[2][SIZE-1], mul_result[2][SIZE-2:0]}, {~mul_result[1][SIZE-1], mul_result[1][SIZE-2:0]}, {~mul_result[0][SIZE-1], mul_result[0][SIZE-2:0]}};

  vec_add #(.SIZE(SIZE)) normal(
    .s_axis_a_tdata(pipe_pre_normal_result),
    .s_axis_a_tready(normal_pre_normal_ready),
    .s_axis_a_tvalid(pipe_pre_normal_valid),
    .s_axis_b_tdata(neg_mul),
    .s_axis_b_tready(normal_mul_ready),
    .s_axis_b_tvalid(mul_valid),
    .m_axis_result_tdata(normal_axis_tdata),
    .m_axis_result_tready(normal_axis_tready),
    .m_axis_result_tvalid(normal_axis_tvalid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_HIT_POINT_LATENCY), .SIZE(SIZE*3)) pipe_hit_point (
    .s_axis_a_tdata(hit_point_result),
    .s_axis_a_tready(pipe_hit_point_ready),
    .s_axis_a_tvalid(hit_point_valid),
    .m_axis_result_tdata(hit_point_axis_tdata),
    .m_axis_result_tvalid(hit_point_axis_tvalid),
    .m_axis_result_tready(hit_point_axis_tready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

endmodule
`default_nettype wire