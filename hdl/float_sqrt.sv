`timescale 1ns / 1ps
`default_nettype none

module float_sqrt #(parameter SIZE=64) (
  input wire [SIZE-1:0] s_axis_a_tdata,
  output logic s_axis_a_tready,
  input wire s_axis_a_tvalid,
  input wire [SIZE-1:0] s_axis_b_tdata,
  output logic s_axis_b_tready,
  input wire s_axis_b_tvalid,
  output logic [SIZE-1:0] m_axis_result_tdata,
  input wire m_axis_result_tready,
  output logic m_axis_result_tvalid,
  input wire aclk,
  input wire aresetn);

  localparam ARTIFICIAL_LATENCY = 29;
  logic [SIZE-1:0] a_pipe [ARTIFICIAL_LATENCY-1:0];
  logic [SIZE-1:0] b_pipe [ARTIFICIAL_LATENCY-1:0];
  logic valid_pipe [ARTIFICIAL_LATENCY-1:0];
  logic can_advance;

  always_comb begin
    m_axis_result_tvalid = valid_pipe[ARTIFICIAL_LATENCY-1];
    m_axis_result_tdata = $realtobits($sqrt($bitstoreal(a_pipe[ARTIFICIAL_LATENCY-1])));
    //to convert float 64 to float 32, most significant bit of exponent stays, take the bottom however many bits
    can_advance = m_axis_result_tready || !m_axis_result_tvalid;
    s_axis_a_tready = can_advance;
    s_axis_b_tready = can_advance;
  end

  always_ff @(posedge aclk) begin
    if(aresetn) begin
      for(int i = 0; i < ARTIFICIAL_LATENCY; i++) begin
        valid_pipe[i] <= 0;
      end
    end
    if(can_advance) begin
      a_pipe[0] <= s_axis_a_tdata;
      b_pipe[0] <= s_axis_b_tdata;
      valid_pipe[0] <= s_axis_a_tvalid;
      for(int i = 1; i < ARTIFICIAL_LATENCY; i++) begin
        a_pipe[i] <= a_pipe[i-1];
        b_pipe[i] <= b_pipe[i-1];
        valid_pipe[i] <= valid_pipe[i-1];
      end
    end
  end

endmodule
`default_nettype wire