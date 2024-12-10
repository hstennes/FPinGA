`timescale 1ns / 1ps
`default_nettype none

module vec_unit #(parameter SIZE) (
  input wire [2:0][SIZE-1:0] s_axis_a_tdata,
  output logic s_axis_a_tready,
  input wire s_axis_a_tvalid,
  output logic [2:0][SIZE-1:0] m_axis_result_tdata,
  input wire m_axis_result_tready,
  output logic m_axis_result_tvalid,
  input wire aclk,
  input wire aresetn);

  //TOTAL LATENCY: 91

  localparam PIPE_LATENCY = 62;

  logic [SIZE-1:0] norm_result;
  logic norm_valid;

  logic [2:0][SIZE-1:0] pipe_vec_result;
  logic pipe_vec_valid;

  logic div1_num_ready;
  logic div1_den_ready;

  logic div2_num_ready;
  logic div2_den_ready;

  logic div3_num_ready;
  logic div3_den_ready;


  vec_norm #(.SIZE(SIZE)) norm (
    .s_axis_a_tdata(s_axis_a_tdata),
    .s_axis_a_tready(s_axis_a_tready),
    .s_axis_a_tvalid(s_axis_a_tvalid),
    .m_axis_result_tdata(norm_result),
    .m_axis_result_tvalid(norm_valid),
    .m_axis_result_tready(div1_den_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  axi_pipe #(.LATENCY(PIPE_LATENCY), .SIZE(SIZE*3)) pipe_vec(
    .s_axis_a_tdata(s_axis_a_tdata),
    .s_axis_a_tready(),
    .s_axis_a_tvalid(s_axis_a_tvalid),
    .m_axis_result_tdata(pipe_vec_result),
    .m_axis_result_tvalid(pipe_vec_valid),
    .m_axis_result_tready(div1_num_ready),
    .aclk(aclk),
    .aresetn(aresetn)
  );
  
  float_div div1(
    .s_axis_a_tdata(pipe_vec_result[0]),
    .s_axis_a_tready(div1_num_ready),
    .s_axis_a_tvalid(pipe_vec_valid),
    .s_axis_b_tdata(norm_result), //* 2
    .s_axis_b_tready(div1_den_ready),
    .s_axis_b_tvalid(norm_valid),
    .m_axis_result_tdata(m_axis_result_tdata[0]),
    .m_axis_result_tvalid(m_axis_result_tvalid),
    .m_axis_result_tready(m_axis_result_tready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_div div2(
    .s_axis_a_tdata(pipe_vec_result[1]),
    .s_axis_a_tready(div2_num_ready),
    .s_axis_a_tvalid(pipe_vec_valid),
    .s_axis_b_tdata(norm_result), //* 2
    .s_axis_b_tready(div2_den_ready),
    .s_axis_b_tvalid(norm_valid),
    .m_axis_result_tdata(m_axis_result_tdata[1]),
    .m_axis_result_tvalid(),
    .m_axis_result_tready(m_axis_result_tready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

  float_div div3(
    .s_axis_a_tdata(pipe_vec_result[2]),
    .s_axis_a_tready(div3_num_ready),
    .s_axis_a_tvalid(pipe_vec_valid),
    .s_axis_b_tdata(norm_result), //* 2
    .s_axis_b_tready(div3_den_ready),
    .s_axis_b_tvalid(norm_valid),
    .m_axis_result_tdata(m_axis_result_tdata[2]),
    .m_axis_result_tvalid(),
    .m_axis_result_tready(m_axis_result_tready),
    .aclk(aclk),
    .aresetn(aresetn)
  );

endmodule
`default_nettype wire