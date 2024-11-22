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
  output logic [24:0] pixel_axis_tdata;
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

  logic [SIZE-1:0] float_hcount_result;
  logic float_hcount_valid;

  logic [SIZE-1:0] float_vcount_result;
  logic float_vcount_valid;

  logic px_ready;
  
  logic py_ready;

  fixed_to_float float_hcount(
    .s_axis_a_tdata(hcount_axis_tdata),
    .s_axis_a_tready(hcount_axis_tready),
    .s_axis_a_tvalid(hcount_axis_tvalid),
    .m_axis_result_tdata(float_hcount_result),
    .m_axis_result_tready(px_ready),
    .m_axis_result_tvalid(float_hcount_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  fixed_to_float float_vcount(
    .s_axis_a_tdata(vcount_axis_tdata),
    .s_axis_a_tready(vcount_axis_tready),
    .s_axis_a_tvalid(vcount_axis_tvalid),
    .m_axis_result_tdata(float_vcount_result),
    .m_axis_result_tready(py_ready),
    .m_axis_result_tvalid(float_vcount_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_fused_mul_add px(
    .s_axis_a_tdata(float_hcount_result),
    .s_axis_a_tready(px_ready),
    .s_axis_a_tvalid(float_hcount_valid),
    .s_axis_b_tdata(PX_MUL),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(1),
    .s_axis_c_tdata(PX_ADD),
    .s_axis_c_tready(),
    .s_axis_c_tvalid(1),
    .m_axis_result_tdata(ray_axis_tdata[2]),
    .m_axis_result_tready(ray_axis_tready),
    .m_axis_result_tvalid(ray_axis_tvalid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_fused_mul_add py(
    .s_axis_a_tdata(float_vcount_result),
    .s_axis_a_tready(py_ready),
    .s_axis_a_tvalid(float_vcount_valid),
    .s_axis_b_tdata(PY_MUL),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(1),
    .s_axis_c_tdata(PY_ADD),
    .s_axis_c_tready(),
    .s_axis_c_tvalid(1),
    .m_axis_result_tdata(ray_axis_tdata[1]),
    .m_axis_result_tready(ray_axis_tready),
    .m_axis_result_tvalid(),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  assign ray_axis_tdata[0] = PZ;

endmodule
`default_nettype wire