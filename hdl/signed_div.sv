`timescale 1ns / 1ps
`default_nettype none

module signed_div #(parameter WIDTH = 32) (
    input wire clk_in,
    input wire rst_in,
    input wire [WIDTH-1:0] dividend_in,
    input wire [WIDTH-1:0] divisor_in,
    input wire data_valid_in,
    output logic [WIDTH-1:0] quotient_out,
    output logic [WIDTH-1:0] remainder_out,
    output logic data_valid_out,
    output logic error_out,
    output logic busy_out
);
  localparam RESTING = 0;
  localparam DIVIDING = 1;

  logic [WIDTH-1:0] quotient, dividend, divisor;
  logic state;
  
  // Detecting the sign of dividend and divisor
  logic dividend_negative, divisor_negative;
  logic quotient_negative;

  // Always need to extend for signed calculation
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      quotient <= 0;
      dividend <= 0;
      divisor <= 0;
      remainder_out <= 0;
      busy_out <= 1'b0;
      error_out <= 1'b0;
      state <= RESTING;
      data_valid_out <= 1'b0;
    end else begin
      case (state)
        RESTING: begin
          if (data_valid_in) begin
            state <= DIVIDING;
            quotient <= 0;
            dividend <= dividend_in;
            divisor <= divisor_in;
            busy_out <= 1'b1;
            error_out <= 1'b0;
            
            // Detecting the signs of dividend and divisor
            dividend_negative <= dividend_in[WIDTH-1];
            divisor_negative <= divisor_in[WIDTH-1];
            quotient_negative <= dividend_negative ^ divisor_negative; // Result sign is negative if exactly one of them is negative
          end
          data_valid_out <= 1'b0;
        end

        DIVIDING: begin
          if (dividend == 0) begin
            // Division is complete
            state <= RESTING;  // Finish division
            remainder_out <= dividend;
            quotient_out <= quotient;
            busy_out <= 1'b0;  // Tell outside world I'm done
            error_out <= 1'b0;
            data_valid_out <= 1'b1;  // Output valid data
          end else if (divisor == 0) begin
            // Handle division by zero
            state <= RESTING;
            remainder_out <= 0;
            quotient_out <= 0;
            busy_out <= 1'b0;  // Tell outside world I'm done
            error_out <= 1'b1;  // ERROR
            data_valid_out <= 1'b1;  // Output valid ERROR
          end else if (dividend < divisor) begin
            // If dividend is less than divisor, we complete the division
            state <= RESTING;
            remainder_out <= dividend;
            quotient_out <= quotient;
            busy_out <= 1'b0;
            error_out <= 1'b0;
            data_valid_out <= 1'b1;  // Output valid data
          end else begin
            // Continue dividing
            quotient <= quotient + 1'b1;
            dividend <= dividend - divisor;
          end
        end
      endcase
    end
  end
  
  // Final adjustment: Apply the quotient sign
  always_ff @(posedge clk_in) begin
    if (data_valid_out) begin
      if (quotient_negative) begin
        quotient_out <= -quotient;  // Apply the negative sign
      end else begin
        quotient_out <= quotient;
      end
    end
  end
endmodule

`default_nettype wire