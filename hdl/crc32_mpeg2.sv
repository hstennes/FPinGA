
module crc32_mpeg2(
            input wire clk_in,
            input wire rst_in,
            input wire data_valid_in,
            input wire data_in,
            output logic [31:0] data_out);

  localparam POLYNOMIAL = 32'b00000100110000010001110110110111;

  always_ff @(posedge clk_in) begin
    if(rst_in) begin
      data_out <= 32'hFFFF_FFFF;
    end
    else if(data_valid_in) begin
      data_out[0] <= data_in ^ data_out[31];
      for(integer i = 1; i < 32; i = i + 1) begin
        data_out[i] <= data_out[i - 1] ^ (POLYNOMIAL[i] & (data_in ^ data_out[31]));
      end
    end
  end

endmodule
