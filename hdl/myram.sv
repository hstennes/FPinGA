`timescale 1ns / 1ps
`default_nettype none

module myram #(parameter SIZE=64) (
  input wire [10:0] data,
  input wire [3:0] write,
  input wire [3:0] read,
  input wire aclk,
  input wire aresetn
  );

  logic [10:0] ram_output;

  xilinx_true_dual_port_read_first_2_clock_ram #(
      .RAM_WIDTH(11),                       // Specify RAM data width
      .RAM_DEPTH(16),                     // Specify RAM depth (number of entries)
      .RAM_PERFORMANCE("LOW_LATENCY"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
      .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) ram (
      .addra(write),   // Port A address bus, width determined from RAM_DEPTH
      .addrb(read),   // Port B address bus, width determined from RAM_DEPTH
      .dina(data),     // Port A RAM input data, width determined from RAM_WIDTH
      .dinb(1'b0),     // Port B RAM input data, width determined from RAM_WIDTH
      .clka(aclk),     // Port A clock
      .clkb(aclk),     // Port B clock
      .wea(1'b1),       // Port A write enable
      .web(1'b0),       // Port B write enable
      .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
      .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
      .rsta(aresetn),     // Port A output reset (does not affect memory contents)
      .rstb(aresetn),     // Port B output reset (does not affect memory contents)
      .regcea(1'b0), // Port A output register enable
      .regceb(1'b1), // Port B output register enable
      // .douta(douta),   // Port A RAM output data, width determined from RAM_WIDTH
      .doutb(ram_output)    // Port B RAM output data, width determined from RAM_WIDTH
  );

endmodule
`default_nettype wire