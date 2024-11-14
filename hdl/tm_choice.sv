module tm_choice (
  input wire [7:0] data_in,
  output logic [8:0] qm_out
  );

  logic [3:0] sum;
  logic choose;

  always_comb begin
    sum = data_in[0] + data_in[1] + data_in[2] + data_in[3] + data_in[4] + data_in[5] + data_in[6] + data_in[7];
    choose = (sum > 4) || (sum == 4 && data_in[0] == 0);
    qm_out[0] = data_in[0];
    for(integer i = 1; i < 8; i++) begin
      qm_out[i] = (data_in[i] ^ qm_out[i - 1]) ^ choose;
    end
    qm_out[8] = !choose;
  end
 
endmodule