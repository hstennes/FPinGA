module test_pattern_generator(
  input wire [1:0] sel_in,
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  output logic [7:0] red_out,
  output logic [7:0] green_out,
  output logic [7:0] blue_out
  );
  
  logic [7:0] crosshair;
  logic [10:0] sum;

  always_comb begin

    case (sel_in)
        2'b00: begin
            red_out = 8'h00;
            green_out = 8'hFF;
            blue_out = 8'hFF;
        end
        2'b01: begin
            crosshair = (vcount_in == 360 || hcount_in == 640) ? 8'hFF : 8'h00;
            red_out = crosshair;
            green_out = crosshair;
            blue_out = crosshair;
        end
        2'b10: begin
            red_out = hcount_in[7:0];
            green_out = hcount_in[7:0];
            blue_out = hcount_in[7:0];
        end
        2'b11: begin
            red_out = hcount_in[7:0];
            green_out = vcount_in[7:0];
            sum = hcount_in + vcount_in;
            blue_out = sum[7:0];
        end
    endcase
  end

endmodule