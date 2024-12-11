`timescale 1ns / 1ps
`default_nettype none

module collision_adv (
    input wire clk_in,
    input wire rst_in,
    input wire valid_in,
    input wire [10:0] ball_x,
    input wire [9:0] ball_y,
    input wire [9:0][10:0] pins_x,
    input wire [9:0][9:0] pins_y,
    input wire [15:0] ball_vx_in,
    input wire [15:0] ball_vy_in,
    output logic [9:0][15:0] pins_vx_out,
    output logic [9:0][15:0] pins_vy_out,
    output logic [9:0] pins_hit,
    output logic done
);
    localparam CALC_DIST_BALL = 2'b00;
    localparam CALC_COLL_BALL = 2'b01;
    localparam CALC_DIST_PIN = 2'b10;
    localparam CALC_COLL_PIN = 2'b11;

    parameter BALL_MASS = 2;
    parameter PIN_MASS = 1;
    parameter BALL_RADIUS = 25;
    parameter PIN_RADIUS = 5;
    parameter SCREEN_HEIGHT = 768;
    parameter SCREEN_WIDTH = 1024;
    parameter TIMER_RST = 1500000;

    logic [19:0] dist_ball_pin [9:0];
    logic [19:0] dist_pin [9:0][9:0];
    logic state;
    logic [31:0] timer;
    logic [9:0][15:0] pins_vx_in;
    logic [9:0][15:0] pins_vy_in;

    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            pins_hit <= 10'b0;
            pins_vx_out <= '0;
            pins_vy_out <= '0;
            pins_vx_in <= 0;
            pins_vy_in <= 0;
            done <= 0;
            state <= CALC_DIST_BALL;
            
        end else if (timer == 0) begin
            timer <= timer + 1;
            if (valid_in) begin
                if (state == CALC_DIST_BALL) begin
                    done <= 0;

                    for (int i = 0; i < 10; i++) begin
                        dist_ball_pin[i] <= (ball_x - pins_x[i]) * (ball_x - pins_x[i]) +
                                            (ball_y - pins_y[i]) * (ball_y - pins_y[i]);
                    end
                    state <= CALC_COLL_BALL;

                end else if (state == CALC_COLL_BALL) begin 
                    for (int i = 0; i < 10; i++) begin
                        if (dist_ball_pin[i] <= (BALL_RADIUS + PIN_RADIUS) * (BALL_RADIUS + PIN_RADIUS)) begin
                            logic [15:0] rel_vx = ball_vx_in - pins_vx_in[i];
                            logic [15:0] rel_vy = ball_vy_in - pins_vy_in[i];

                            logic [10:0] dx = ball_x - pins_x[i];
                            logic [9:0] dy = ball_y - pins_y[i];

                            logic [19:0] approx_mag = dx * dx + dy * dy;

                            logic [15:0] dot_product = (rel_vx * dx + rel_vy * dy) / approx_mag;

                            pins_vx_out[i] <= pins_vx_in[i] + (2 * BALL_MASS * dot_product * dx) / (BALL_MASS + PIN_MASS);
                            pins_vy_out[i] <= pins_vy_in[i] + (2 * BALL_MASS * dot_product * dy) / (BALL_MASS + PIN_MASS);
                            pins_hit[i] <= 1;
                        end
                    end
                    state <= CALC_DIST_PIN;

                end else if (state == CALC_DIST_PIN) begin
                    for (int i = 0; i < 10; i++) begin
                        for (int j = i+1; j < 10; j++) begin
                            dist_pin[i][j] <= (pins_x[j] - pins_x[i]) * (pins_x[j] - pins_x[i]) +
                                              (pins_y[j] - pins_y[i]) * (pins_y[j] - pins_y[i]);
                        end
                    end
                    state <= CALC_COLL_PIN;

                end else if (state == CALC_COLL_PIN) begin
                    for (int i = 0; i < 10; i++) begin
                        for (int j = i+1; j < 10; j++) begin
                            if ((dist_pin[i][j] <= (PIN_RADIUS + PIN_RADIUS) * (PIN_RADIUS + PIN_RADIUS)) && (i != j)) begin
                                logic [15:0] rel_vx = pins_vx_in[j] - pins_vx_in[i];
                                logic [15:0] rel_vy = pins_vy_in[j] - pins_vy_in[i];

                                logic [10:0] dx = pins_x[j] - pins_x[i];
                                logic [9:0] dy = pins_y[j] - pins_y[i];

                                logic [19:0] approx_mag = dx * dx + dy * dy;

                                logic [15:0] dot_product = (rel_vx * dx + rel_vy * dy) / approx_mag;

                                pins_vx_out[i] <= pins_vx_in[i] + dot_product * dx;
                                pins_vy_out[i] <= pins_vy_in[i] + dot_product * dy;
                                pins_vx_out[j] <= pins_vx_in[j] - dot_product * dx;
                                pins_vy_out[j] <= pins_vy_in[j] - dot_product * dy;

                                pins_hit[i] <= 1;
                                pins_hit[j] <= 1;
                            end
                        end
                    end
                    state <= CALC_DIST_BALL;
                end

                done <= 1;
            end
        end else if (timer == TIMER_RST) begin
            timer <= 0;
            done <= 0;
        end else begin 
            timer <= timer + 1;
            done <= 0;
        end
    end
endmodule
