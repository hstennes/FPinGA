`timescale 1ns / 1ps
`default_nettype none

module score (
    input wire clk_in,                    
    input wire rst_in,
    input wire valid_in,
    input wire [9:0] pin_hit,
    output logic [19:0] [5:0] score_p1,
    output logic [19:0] [5:0] score_p2,
    output logic player,
    output logic chance,
    output logic [3:0] round
);


    always @(posedge clk_in) begin
        if (rst_in) begin
            score_p1 <= 0;
            score_p2 <= 0;
            player <= 0;
            chance <= 0;
            round <= 0;
        end

        else if (valid_in) begin
            if (!player) begin   
                if (!chance) begin             
                    score_p1 <= {score_p1[19:2], 1'b1, 
                                pin_hit[0]+pin_hit[1]+pin_hit[2]+pin_hit[3]+pin_hit[4]+pin_hit[5]+
                                pin_hit[6]+pin_hit[7]+pin_hit[8]+pin_hit[9]};
                    chance <= 1;
                end else begin
                    score_p1 <= {score_p1[19:2], 1'b1, 
                                pin_hit[0]+pin_hit[1]+pin_hit[2]+pin_hit[3]+pin_hit[4]+pin_hit[5]+
                                pin_hit[6]+pin_hit[7]+pin_hit[8]+pin_hit[9]-score_p1[19]};
                    chance <= 0;
                    player <= 1;
                end
            end else begin
                if (!chance) begin             
                    score_p2 <= {score_p2[19:2], 1'b1, 
                                pin_hit[0]+pin_hit[1]+pin_hit[2]+pin_hit[3]+pin_hit[4]+pin_hit[5]+
                                pin_hit[6]+pin_hit[7]+pin_hit[8]+pin_hit[9]};
                    chance <= 1;
                end else begin
                    score_p2 <= {score_p2[19:1], 
                                pin_hit[0]+pin_hit[1]+pin_hit[2]+pin_hit[3]+pin_hit[4]+pin_hit[5]+
                                pin_hit[6]+pin_hit[7]+pin_hit[8]+pin_hit[9]-score_p1[19]};
                    chance <= 0;
                    player <= 1;
                    round <= round + 1;
                end
            end
        end
    end

endmodule