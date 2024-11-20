`timescale 1ns / 1ps
`default_nettype none

module ray_from_pixel #(parameter SIZE=64) (
  input wire [10:0] hcount_axis_tdata,
  input wire hcount_axis_tvalid,
  output logic hcount_axis_tready,
  input wire [9:0] vcount_axis_tdata,
  input wire vcount_axis_tvalid,
  output logic vcount_axis_tready,
  output logic [2:0][SIZE-1:0] ray_axis_tdata,
  input wire ray_axis_tready,
  output logic ray_axis_tvalid,
  input wire aclk,
  input wire aresetn);

  //TOTAL LATENCY: 17

  localparam [SIZE-1:0] PX_MUL = 64'h3F79999999999999;
  localparam [SIZE-1:0] PX_ADD = 64'hBFFFFFFFFFFFFFFF;
  localparam [SIZE-1:0] PY_MUL = 64'hBF79999999999999;
  localparam [SIZE-1:0] PY_ADD = 64'h3FF0000000000000;
  localparam [SIZE-1:0] PZ = 64'hBFF0000000000000;

  float_fused_mul_add px(
    .s_axis_a_tdata(hcount_axis_tdata),
    .s_axis_a_tready(hcount_axis_tready),
    .s_axis_a_tvalid(hcount_axis_tvalid),
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
    .s_axis_a_tdata(hcount_axis_tdata),
    .s_axis_a_tready(hcount_axis_tready),
    .s_axis_a_tvalid(hcount_axis_tvalid),
    .s_axis_b_tdata(PY_MUL),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(1),
    .s_axis_c_tdata(PY_ADD),
    .s_axis_c_tready(),
    .s_axis_c_tvalid(1),
    .m_axis_result_tdata(ray_axis_tdata[1]),
    .m_axis_result_tready(ray_axis_tready),
    .m_axis_result_tvalid(ray_axis_tvalid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  assign ray_axis_tdata[0] = PZ;

endmodule
`default_nettype wire