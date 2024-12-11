module collision (
    input wire rst_sim,
    input wire clk_in,
    input wire rst_in,
    input wire valid_in,
    input wire [10:0] ball_x,
    input wire [9:0] ball_y,
    input wire [9:0][10:0] pins_x,
    input wire [9:0][9:0] pins_y,
    // input wire [9:0][15:0] pins_vx_in,
    // input wire [9:0][15:0] pins_vy_in,
    input wire [15:0] ball_vx_in,
    input wire [15:0] ball_vy_in,
    output logic [9:0][15:0] pins_vx_out,
    output logic [9:0][15:0] pins_vy_out,
    output logic [9:0] pins_hit,
    output logic done
);
    localparam CALC_DIST_BALL = 2'b0;
    localparam CALC_COLL_BALL = 2'b01;
    localparam CALC_DIST_PIN = 2'b10;
    localparam CALC_COLL_PIN = 2'b11;
    parameter BALL_MASS = 2;
    parameter PIN_MASS = 1;
    parameter BALL_RADIUS = 39;
    parameter PIN_RADIUS = 21;
    parameter SCREEN_HEIGHT = 768;
    parameter SCREEN_WIDTH = 1024;
    parameter TIMER_RST = 1500000;

    // Intermediate variables
    logic [19:0] dist_ball_pin [9:0];
    logic [19:0] dist_pin [9:0][9:0];
    logic state;
    logic [31:0] timer;
    logic [9:0][15:0] pins_vx_in;
    logic [9:0][15:0] pins_vy_in;
    // logic [19:0] dist_pin;

    always @(posedge clk_in) begin
        if (rst_in || rst_sim) begin
            pins_hit <= 10'b0;
            pins_vx_out <= '0;
            pins_vy_out <= '0;
            pins_vx_in <= 0;
            pins_vy_in <= 0;
            done <= 0;
            state <= CALC_DIST_BALL;
        
        end else if(timer == 0) begin
            timer = timer + 1;        
        if (valid_in) begin
            if(state == CALC_DIST_BALL) begin
                done <= 0;
                for (int i = 0; i < 10; i++) begin
                    dist_ball_pin[i] <= (ball_x - pins_x[i]) * (ball_x - pins_x[i]) +
                                        (ball_y - pins_y[i]) * (ball_y - pins_y[i]);
                end
                state <= CALC_COLL_BALL;

            end else if (state == CALC_COLL_BALL) begin 
                for (int i = 0; i < 10; i++) begin
                    if (dist_ball_pin[i] <= (BALL_RADIUS + PIN_RADIUS) * (BALL_RADIUS + PIN_RADIUS)) begin
                        pins_vx_out[i] <= (2 * BALL_MASS * ball_vx_in) / (BALL_MASS + PIN_MASS) - 
                                        (pins_vx_in[i] * (BALL_MASS - PIN_MASS)) / (BALL_MASS + PIN_MASS);
                        pins_vy_out[i] <= (2 * BALL_MASS * ball_vy_in) / (BALL_MASS + PIN_MASS) - 
                                        (pins_vy_in[i] * (BALL_MASS - PIN_MASS)) / (BALL_MASS + PIN_MASS);
                        pins_hit[i] <= 1;
                    end
                end
                state <= CALC_DIST_PIN;

            end else if (state == CALC_DIST_PIN) begin
                for (int i = 0; i < 10; i++) begin
                    for (int j = i + 1; j < 10; j++) begin
                        dist_pin[i][j] <= (pins_x[i] - pins_x[j]) * (pins_x[i] - pins_x[j]) +
                                    (pins_y[j] - pins_y[i]) * (pins_y[j] - pins_y[i]);
                    end
                end
                state <= CALC_COLL_PIN;

            end else if (state == CALC_COLL_PIN) begin
                for (int i = 0; i < 10; i++) begin
                    for (int j = i + 1; j < 10; j++) begin
                        if ((dist_pin[i][j] <= (PIN_RADIUS + PIN_RADIUS) * (PIN_RADIUS + PIN_RADIUS)) && (i!=j) && (pins_x[i] < SCREEN_WIDTH) && (pins_y[i] < SCREEN_HEIGHT)) begin
                            pins_vx_out[i] <= pins_vx_in[j];
                            pins_vx_out[j] <= pins_vx_in[i];
                            pins_vy_out[i] <= pins_vy_in[j];
                            pins_vy_out[j] <= pins_vy_in[i];
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
            timer <= timer +1;
            done <= 0;
        end
    end
endmodule



// `timescale 1ns / 1ps
// `default_nettype none

// //USE BRAMS OR PIPELINE STORE IN REGISTERS

// module collision (
//     input wire clk_in,                     
//     input wire rst_in,
//     input wire valid_in, 
//     input wire [10:0] ball_x,          
//     input wire [9:0] ball_y,     
//     input wire [9:0] [10:0] pins_x,       
//     input wire [9:0] [9:0] pins_y,        
//     input wire [9:0] [15:0] pins_vx_in,       
//     input wire [9:0] [15:0] pins_vy_in,        
//     input wire [15:0] ball_vx_in,       
//     input wire [15:0] ball_vy_in, 
//     output logic [9:0] [15:0] pins_vx_out, 
//     output logic [9:0] [15:0] pins_vy_out, 
//     output logic [9:0] pins_hit_out,
//     output logic done               
// );


//     parameter BALL_MASS = 7200;
//     parameter PIN_MASS = 1000;  
//     parameter BALL_RADIUS = 5;  
//     parameter PIN_RADIUS = 5;

//     // Intermediate variables
//     logic [9:0] [15:0] dist_ball_pin;
//     logic [8:0] [15:0] dist_pin9_pin; 
//     logic [7:0] [15:0] dist_pin8_pin; 
//     logic [6:0] [15:0] dist_pin7_pin; 
//     logic [5:0] [15:0] dist_pin6_pin; 
//     logic [4:0] [15:0] dist_pin5_pin; 
//     logic [3:0] [15:0] dist_pin4_pin; 
//     logic [2:0] [15:0] dist_pin3_pin; 
//     logic [1:0] [15:0] dist_pin2_pin; 
//     logic [15:0] dist_pin1_pin;
//     logic [9:0] [15:0] coll_ball_pin;
//     logic [8:0] [15:0] coll_pin9_pin; 
//     logic [7:0] [15:0] coll_pin8_pin; 
//     logic [6:0] [15:0] coll_pin7_pin; 
//     logic [5:0] [15:0] coll_pin6_pin; 
//     logic [4:0] [15:0] coll_pin5_pin; 
//     logic [3:0] [15:0] coll_pin4_pin; 
//     logic [2:0] [15:0] coll_pin3_pin; 
//     logic [1:0] [15:0] coll_pin2_pin; 
//     logic [15:0] coll_pin1_pin; 
//     logic [9:0] pins_hit;
   
//     always @(posedge clk_in) begin
//         if (rst_in) begin
//             pins_hit <= 10'b1;
//             pins_hit_out <= 0;
//             coll_ball_pin <= 0;
//             coll_pin9_pin <= 0;
//             coll_pin8_pin <= 0;
//             coll_pin7_pin <= 0;
//             coll_pin6_pin <= 0;
//             coll_pin5_pin <= 0;
//             coll_pin4_pin <= 0;
//             coll_pin3_pin <= 0;
//             coll_pin2_pin <= 0;
//             coll_pin1_pin <= 0;
//             dist_ball_pin <= 160'b1;
//             dist_pin9_pin <= 144'b1;
//             dist_pin8_pin <= 138'b1;
//             dist_pin7_pin <= 122'b1;
//             dist_pin6_pin <= 106'b1;
//             dist_pin5_pin <= 90'b1;
//             dist_pin4_pin <= 74'b1;
//             dist_pin3_pin <= 58'b1;
//             dist_pin2_pin <= 42'b1;
//             dist_pin1_pin <= 26'b1;
//         end

//         if (valid_in) begin
//             for (int i=0; i<10; i=i+1) begin
//                 dist_ball_pin[i] <= (ball_x - pins_x[i]) * (ball_x - pins_x[i]) + (ball_y - pins_y[i]) * (ball_y - pins_y[i]);
//                 coll_ball_pin[i] <= (dist_ball_pin[i] <= (BALL_RADIUS + PIN_RADIUS));
//                 if (coll_ball_pin[i]) begin
//                     pins_vx_out[i] <= (2*BALL_MASS*ball_vx_in)/(BALL_MASS+PIN_MASS) - pins_vx_in[i]*(BALL_MASS-PIN_MASS)/(BALL_MASS+PIN_MASS);
//                     pins_vy_out[i] <= (2*BALL_MASS*ball_vy_in)/(BALL_MASS+PIN_MASS) - pins_vy_in[i]*(BALL_MASS-PIN_MASS)/(BALL_MASS+PIN_MASS);
//                     pins_hit_out[i] <= 1;
//                 end
//             end
//             for (int i=0; i<9; i=i+1) begin
//                 dist_pin9_pin[i] <= (pins_x[9] - pins_x[i]) * (pins_x[9] - pins_x[i]) + (pins_y[9] - pins_y[i]) * (pins_y[9] - pins_y[i]);
//                 coll_pin9_pin[i] <= (dist_pin9_pin[i] <= (PIN_RADIUS + PIN_RADIUS));
//                 if (coll_pin9_pin[i]) begin
//                     pins_vx_out[i] <= pins_vx_in[9];
//                     pins_vy_out[i] <= pins_vy_in[9];
//                     pins_vx_out[9] <= pins_vx_in[i];
//                     pins_vy_out[9] <= pins_vy_in[i];
//                     pins_hit_out[i] <= 1;
//                     pins_hit_out[9] <= 1;
//                 end
//             end
            
//             for (int i=0; i<8; i=i+1) begin
//                 dist_pin8_pin[i] = (pins_x[8] - pins_x[i]) * (pins_x[8] - pins_x[i]) + (pins_y[8] - pins_y[i]) * (pins_y[8] - pins_y[i]);
//                 coll_pin8_pin[i] = (dist_pin8_pin[i] <= (PIN_RADIUS + PIN_RADIUS));
//                 if (coll_pin8_pin[i]) begin
//                     pins_vx_out[i] <= pins_vx_in[8];
//                     pins_vy_out[i] <= pins_vy_in[8];
//                     pins_vx_out[8] <= pins_vx_in[i];
//                     pins_vy_out[8] <= pins_vy_in[i];
//                     pins_hit_out[i] <= 1;
//                     pins_hit_out[8] <= 1;
//                 end
//             end

//             for (int i=0; i<7; i=i+1) begin
//                 dist_pin7_pin[i] = (pins_x[7] - pins_x[i]) * (pins_x[7] - pins_x[i]) + (pins_y[7] - pins_y[i]) * (pins_y[7] - pins_y[i]);
//                 coll_pin7_pin[i] = (dist_pin7_pin[i] <= (PIN_RADIUS + PIN_RADIUS));
//                 if (coll_pin7_pin[i]) begin
//                     pins_vx_out[i] <= pins_vx_in[7];
//                     pins_vy_out[i] <= pins_vy_in[7];
//                     pins_vx_out[7] <= pins_vx_in[i];
//                     pins_vy_out[7] <= pins_vy_in[i];
//                     pins_hit_out[i] <= 1;
//                     pins_hit_out[7] <= 1;
//                 end
//             end
            
//             for (int i=0; i<6; i=i+1) begin
//                 dist_pin6_pin[i] = (pins_x[6] - pins_x[i]) * (pins_x[6] - pins_x[i]) + (pins_y[6] - pins_y[i]) * (pins_y[6] - pins_y[i]);
//                 coll_pin6_pin[i] = (dist_pin6_pin[i] <= (PIN_RADIUS + PIN_RADIUS));
//                 if (coll_pin6_pin[i]) begin
//                     pins_vx_out[i] <= pins_vx_in[6];
//                     pins_vy_out[i] <= pins_vy_in[6];
//                     pins_vx_out[6] <= pins_vx_in[i];
//                     pins_vy_out[6] <= pins_vy_in[i];
//                     pins_hit_out[i] <= 1;
//                     pins_hit_out[6] <= 1;
//                 end
//             end
            
//             for (int i=0; i<5; i=i+1) begin
//                 dist_pin5_pin[i] = (pins_x[5] - pins_x[i]) * (pins_x[5] - pins_x[i]) + (pins_y[5] - pins_y[i]) * (pins_y[5] - pins_y[i]);
//                 coll_pin5_pin[i] = (dist_pin5_pin[i] <= (PIN_RADIUS + PIN_RADIUS));
//                 if (coll_pin5_pin[i]) begin
//                     pins_vx_out[i] <= pins_vx_in[5];
//                     pins_vy_out[i] <= pins_vy_in[5];
//                     pins_vx_out[5] <= pins_vx_in[i];
//                     pins_vy_out[5] <= pins_vy_in[i];
//                     pins_hit_out[i] <= 1;
//                     pins_hit_out[5] <= 1;
//                 end
//             end

//             for (int i=0; i<4; i=i+1) begin
//                 dist_pin4_pin[i] = (pins_x[4] - pins_x[i]) * (pins_x[4] - pins_x[i]) + (pins_y[4] - pins_y[i]) * (pins_y[4] - pins_y[i]);
//                 coll_pin4_pin[i] = (dist_pin4_pin[i] <= (PIN_RADIUS + PIN_RADIUS));
//                 if (coll_pin4_pin[i]) begin
//                     pins_vx_out[i] <= pins_vx_in[4];
//                     pins_vy_out[i] <= pins_vy_in[4];
//                     pins_vx_out[4] <= pins_vx_in[i];
//                     pins_vy_out[4] <= pins_vy_in[i];
//                     pins_hit_out[i] <= 1;
//                     pins_hit_out[4] <= 1;
//                 end
//             end

//             for (int i=0; i<3; i=i+1) begin
//                 dist_pin3_pin[i] = (pins_x[3] - pins_x[i]) * (pins_x[3] - pins_x[i]) + (pins_y[3] - pins_y[i]) * (pins_y[3] - pins_y[i]);
//                 coll_pin3_pin[i] = (dist_pin3_pin[i] <= (PIN_RADIUS + PIN_RADIUS));
//                 if (coll_pin3_pin[i]) begin
//                     pins_vx_out[i] <= pins_vx_in[3];
//                     pins_vy_out[i] <= pins_vy_in[3];
//                     pins_vx_out[3] <= pins_vx_in[i];
//                     pins_vy_out[3] <= pins_vy_in[i];
//                     pins_hit_out[i] <= 1;
//                     pins_hit_out[3] <= 1;
//                 end
//             end

//             for (int i=0; i<2; i=i+1) begin
//                 dist_pin2_pin[i] = (pins_x[2] - pins_x[i]) * (pins_x[2] - pins_x[i]) + (pins_y[2] - pins_y[i]) * (pins_y[2] - pins_y[i]);
//                 coll_pin2_pin[i] = (dist_pin2_pin[i] <= (PIN_RADIUS + PIN_RADIUS));
//                 if (coll_pin2_pin[i]) begin
//                     pins_vx_out[i] <= pins_vx_in[2];
//                     pins_vy_out[i] <= pins_vy_in[2];
//                     pins_vx_out[2] <= pins_vx_in[i];
//                     pins_vy_out[2] <= pins_vy_in[i];
//                     pins_hit_out[i] <= 1;
//                     pins_hit_out[2] <= 1;
//                 end
//             end
            
//             dist_pin1_pin = (pins_x[1] - pins_x[0]) * (pins_x[1] - pins_x[0]) + (pins_y[1] - pins_y[0]) * (pins_y[1] - pins_y[0]);
//             coll_pin1_pin = (dist_pin1_pin <= (PIN_RADIUS + PIN_RADIUS));
//             if (coll_pin1_pin) begin
//                 pins_vx_out[0] <= pins_vx_in[1];
//                 pins_vy_out[0] <= pins_vy_in[1];
//                 pins_vx_out[1] <= pins_vx_in[0];
//                 pins_vy_out[1] <= pins_vy_in[0];
//                 pins_hit_out[0] <= 1;
//                 pins_hit_out[1] <= 1;
//             end
//         end
//     end
// endmodule