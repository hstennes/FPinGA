`default_nettype none
module traffic_evt_counter (
    input wire clk_in,
    input wire rst_in,
    input wire write_axis_valid,
    input wire write_axis_ready,
    input wire write_axis_tlast,
    input wire read_request_valid,
    input wire read_request_ready,
    input wire read_axis_valid,
    input wire read_axis_ready,
    output wire [26:0] write_address,
    output wire [26:0] read_request_address,
    output wire [26:0] read_response_address
);

evt_counter write_addr_counter(
    .clk_in(clk_in),
    .rst_in(rst_in || (write_axis_valid && write_axis_ready && write_axis_tlast)),
    .evt_in(write_axis_valid && write_axis_ready),
    .period_in(115200),
    .count_out(write_address)
  );

  evt_counter read_request_addr_counter(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .evt_in(read_request_valid && read_request_ready),
    .period_in(115200),
    .count_out(read_request_address)
  );

  evt_counter read_response_addr_counter(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .evt_in(read_axis_valid && read_axis_ready),
    .period_in(115200),
    .count_out(read_response_address)
  );

endmodule
`default_nettype wire