module renderer_sig_gen
#(
  parameter START_X,
  parameter END_X,
  parameter START_Y,
  parameter END_Y)
(
  input wire aclk,
  input wire rst_in,
  input wire ready,
  output logic [10:0] hcount_out,
  output logic [9:0] vcount_out);

  always_ff @(posedge aclk) begin
    if(ready == 1) begin
      if(hcount_out == END_X - 1) begin
        hcount_out <= START_X;
        vcount_out <= vcount_out == END_Y - 1 ? START_Y : vcount_out + 1;
      end else begin
        hcount_out <= hcount_out + 1;
      end
    end
  end
  
endmodule
