`default_nettype none
module evt_counter
  ( input wire          clk_in,
    input wire          rst_in,
    input wire          evt_in,
    input wire [31:0] period_in,
    output logic[31:0]  count_out
  );
 
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      count_out <= 16'b0;
    end else begin
      if (evt_in) begin
        count_out <= count_out + 1 == period_in ? 0 : count_out + 1;
      end
    end
  end
endmodule
`default_nettype wire