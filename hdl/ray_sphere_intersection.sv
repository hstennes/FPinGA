`timescale 1ns / 1ps
`default_nettype none

module ray_sphere_intersection #(parameter SIZE=64) (
  input wire [2:0][SIZE-1:0] sphere_loc,
  input wire sphere_loc_valid,
  input wire [5:0][SIZE-1:0] ray_axis_tdata,
  output logic ray_axis_tready,
  input wire ray_axis_tvalid,
  output logic [SIZE-1:0] t_axis_tdata,
  input wire t_axis_tready,
  output logic t_axis_tvalid,
  input wire aclk,
  input wire aresetn);

  //TOTAL LATENCY: 139

  localparam PIPE_D_LATENCY = 9;
  localparam PIPE_A_LATENCY = 18;
  localparam PIPE_B_LATENCY = 9;

  logic [2:0][SIZE-1:0] oc_result;
  logic oc_valid;

  logic ocd_oc_ready;
  logic ocd_d_ready;
  logic [SIZE-1:0] ocd_result;
  logic ocd_valid;

  logic ococ_ready;
  logic [SIZE-1:0] ococ_result;
  logic ococ_valid;

  logic [2:0][SIZE-1:0] pipe_d_result;
  logic pipe_d_valid;

  logic pipe_b_ready;
  logic [SIZE-1:0] pipe_b_result;
  logic pipe_b_valid;

  logic ococmr2_ococ_ready;
  logic ococmr2_r2_ready;
  logic [SIZE-1:0] ococmr2_result;
  logic ococmr2_valid;

  logic quad_a_ready;
  logic quad_b_ready;
  logic quad_c_ready;
  logic [SIZE-1:0] quad_result;
  logic quad_valid;

  logic [2:0][SIZE-1:0] neg_valid_sphere_loc;

  vec_add oc(
    .s_axis_a_tdata(ray_axis_tdata[2:0]),
    .s_axis_a_tready(ray_axis_tready),
    .s_axis_a_tvalid(ray_axis_tvalid),
    .s_axis_b_tdata(neg_valid_sphere_loc),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(1),
    .m_axis_result_tdata(oc_result),
    .m_axis_result_tready(ocd_oc_ready),
    .m_axis_result_tvalid(oc_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_D_LATENCY), .SIZE(SIZE*3)) pipe_d(
    .s_axis_a_tdata(ray_axis_tdata[5:3]),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(ray_axis_tvalid),
    .m_axis_result_tdata(pipe_d_result),
    .m_axis_result_tvalid(pipe_d_valid),
    .m_axis_result_tready(ocd_d_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  vec_dot ocd(
    .s_axis_a_tdata(oc_result),
    .s_axis_a_tready(ocd_oc_ready),
    .s_axis_a_tvalid(oc_valid),
    .s_axis_b_tdata(pipe_d_result),
    .s_axis_b_tready(ocd_d_ready),
    .s_axis_b_tvalid(pipe_d_valid),
    .m_axis_result_tdata(ocd_result),
    .m_axis_result_tready(pipe_b_ready),
    .m_axis_result_tvalid(ocd_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  vec_dot ococ(
    .s_axis_a_tdata(oc_result),
    .s_axis_a_tready(ococ_ready),
    .s_axis_a_tvalid(oc_valid),
    .s_axis_b_tdata(oc_result),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(oc_valid),
    .m_axis_result_tdata(ococ_result),
    .m_axis_result_tready(ococmr2_ococ_ready),
    .m_axis_result_tvalid(ococ_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_add ococmr2(
    .s_axis_a_tdata(ococ_result),
    .s_axis_a_tready(ococmr2_ococ_ready),
    .s_axis_a_tvalid(ococ_valid),
    .s_axis_b_tdata(64'b1011111111110000000000000000000000000000000000000000000000000000),
    .s_axis_b_tready(),
    .s_axis_b_tvalid(1),
    .m_axis_result_tdata(ococmr2_result),
    .m_axis_result_tready(quad_c_ready),
    .m_axis_result_tvalid(ococmr2_valid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  logic [10:0] calc_b_temp;
  assign calc_b_temp = ocd_result[62:52] + 1;

  axi_pipe #(.LATENCY(PIPE_B_LATENCY)) pipe_b(
    .s_axis_a_tdata({ocd_result[63], calc_b_temp, ocd_result[51:0]}),
    .s_axis_a_tready(pipe_b_ready),
    .s_axis_a_tvalid(ocd_valid),
    .m_axis_result_tdata(pipe_b_result),
    .m_axis_result_tvalid(pipe_b_valid),
    .m_axis_result_tready(quad_b_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  quadratic quad(
    .s_axis_a_tdata(64'b0011111111110000000000000000000000000000000000000000000000000000),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(1),
    .s_axis_b_tdata(pipe_b_result),
    .s_axis_b_tready(quad_b_ready),
    .s_axis_b_tvalid(pipe_b_valid),
    .s_axis_c_tdata(ococmr2_result),
    .s_axis_c_tready(quad_c_ready),
    .s_axis_c_tvalid(ococmr2_valid),
    .m_axis_result_tdata(t_axis_tdata),
    .m_axis_result_tready(t_axis_tready),
    .m_axis_result_tvalid(t_axis_tvalid),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  always_ff @(posedge aclk) begin
    if(sphere_loc_valid) begin
      neg_valid_sphere_loc <= {{~sphere_loc[2][63], sphere_loc[2][62:0]}, {~sphere_loc[1][63], sphere_loc[1][62:0]}, {~sphere_loc[0][63], sphere_loc[0][62:0]}};
    end
  end

endmodule
`default_nettype wire