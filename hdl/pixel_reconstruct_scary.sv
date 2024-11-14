`timescale 1ns / 1ps
`default_nettype none

module pixel_reconstruct_scary
	#(
	 parameter HCOUNT_WIDTH = 11,
	 parameter VCOUNT_WIDTH = 10
	 )
	(
	 input wire 										 clk_in,
	 input wire 										 rst_in,
	 input wire 										 camera_pclk_in,
	 input wire 										 camera_hs_in,
	 input wire 										 camera_vs_in,
	 input wire [7:0] 							 camera_data_in,
	 output logic 									 pixel_valid_out,
	 output logic [HCOUNT_WIDTH-1:0] pixel_hcount_out,
	 output logic [VCOUNT_WIDTH-1:0] pixel_vcount_out,
	 output logic [15:0] 						 pixel_data_out
	 );

	 logic pclk_prev;
	 logic last_sampled_hs;
	 logic [7:0] last_sampled_data;
	 logic half_pixel_ready;

	 logic [HCOUNT_WIDTH-1:0] hcount;
	 logic [VCOUNT_WIDTH-1:0] vcount;

	 always_ff@(posedge clk_in) begin
		if (rst_in) begin
			hcount <= 0;
			vcount <= 0;
			pixel_valid_out <= 0;
			pixel_data_out <= 16'b0;
			half_pixel_ready <= 0;
			pclk_prev <= 0;
			last_sampled_data <= 8'b0;
		end else begin
			pclk_prev <= camera_pclk_in;
			last_sampled_hs <= camera_hs_in;

			if(pixel_valid_out) begin
				pixel_valid_out <= 0;
			end

			if(camera_pclk_in && !pclk_prev) begin
				if (!camera_vs_in) begin 
					vcount <= 0;    
					hcount <= 0;
					half_pixel_ready <= 0;
					last_sampled_data <= 0;
				end else if (last_sampled_hs && !camera_hs_in) begin
					hcount <= 0;
					vcount <= vcount + 1;
					half_pixel_ready <= 0;
					last_sampled_data <= 0;
				end			

				if (camera_hs_in && camera_vs_in) begin
					if (!half_pixel_ready) begin
						last_sampled_data <= camera_data_in;
						half_pixel_ready <= 1;
					end else begin
						pixel_data_out <= {last_sampled_data, camera_data_in};
						pixel_valid_out <= 1;
						hcount <= hcount + 1;
						half_pixel_ready <= 0;
					end
				end

				pixel_hcount_out <= hcount;
				pixel_vcount_out <= vcount;
			end
		end
	 end

endmodule

`default_nettype wire
