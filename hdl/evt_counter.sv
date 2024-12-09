`default_nettype none

module evt_counter (input wire clk_in,
                    input wire rst_in,
                    input wire evt_in,
                    input wire max_val,
                    output logic [26:0] count_out);
    
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            count_out <= 0;
        end else if (evt_in) begin
            if (count_out >= 115199) begin
                count_out <= 0;
            end else begin
                count_out <= count_out + 1;
            end
        end
    end
endmodule