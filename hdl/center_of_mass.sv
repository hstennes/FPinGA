`default_nettype none
module center_of_mass (
                         input wire clk_in,
                         input wire rst_in,
                         input wire [10:0] x_in,
                         input wire [9:0]  y_in,
                         input wire valid_in,
                         input wire tabulate_in,
                         output logic [10:0] x_out,
                         output logic [9:0] y_out,
                         output logic valid_out);
	logic [31:0] sum_x;
    logic [31:0] sum_y;
    logic [31:0] total;
    logic [11:0] result_x;
    logic [11:0] result_y;
    logic x_done;
    logic y_done;

    logic divider_valid_in;
    logic div_x_valid_out;
    logic div_y_valid_out;

    divider x_div(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .dividend_in(sum_x),
        .divisor_in(total),
        .data_valid_in(divider_valid_in),
        .quotient_out(result_x),
        .data_valid_out(div_x_valid_out)
    );

    divider y_div(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .dividend_in(sum_y),
        .divisor_in(total),
        .data_valid_in(divider_valid_in),
        .quotient_out(result_y),
        .data_valid_out(div_y_valid_out)
    );
    
    enum {RECORDING, DIVIDING} state;

    always_ff @(posedge clk_in) begin
        if(rst_in) begin
            sum_x <= 0;
            sum_y <= 0;
            total <= 0;
            x_done <= 0;
            y_done <= 0;
            divider_valid_in <= 0;
        end
        case(state)
            RECORDING: begin
                valid_out <= 0;
                if(valid_in) begin
                    total += 1;
                    sum_x += x_in;
                    sum_y += y_in;
                end
                if(tabulate_in) begin
                    if(total > 0) begin
                        state <= DIVIDING;
                        divider_valid_in <= 1;
                    end
                end
            end
            DIVIDING: begin
                divider_valid_in <= 0;
                if(div_x_valid_out) begin
                    x_out <= result_x;
                    x_done <= 1;
                end
                if(div_y_valid_out) begin
                    y_out <= result_y;
                    y_done <= 1;
                end
                if(x_done == 1 && y_done == 1) begin
                    valid_out <= 1;
                    sum_x <= 0;
                    sum_y <= 0;
                    total <= 0;
                    x_done <= 0;
                    y_done <= 0;
                    state <= RECORDING;
                end
            end
        endcase
    end
endmodule

`default_nettype wire
