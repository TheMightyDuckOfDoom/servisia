/*
 * servisia_gpio.v : Single-bit GPIO for the subservient SoC
 *
 * SPDX-FileCopyrightText: 2021 Olof Kindgren <olof.kindgren@gmail.com>
 * SPDX-License-Identifier: Apache-2.0
 */

// Modified version of subservient_gpio.v by Tobias Senti 2023

module servisia_gpo #(
   parameter integer WIDTH = 1
)(
   // Wishbone interface
   input  wire             wb_clk_i,
   input  wire             wb_rst_i,
   input  wire [WIDTH-1:0] wb_dat_i,
   input  wire             wb_we_i,
   input  wire             wb_stb_i,
   output reg  [WIDTH-1:0] wb_rdt_o,
   output reg              wb_ack_o,
   
   // Outputs
   output reg [WIDTH-1:0] gpio_o
);

   always @(posedge wb_clk_i) begin
      wb_rdt_o <= gpio_o;
      wb_ack_o <= wb_stb_i & !wb_ack_o;
      if (wb_stb_i & wb_we_i)
         gpio_o <= wb_dat_i;

      if (wb_rst_i) begin
         wb_ack_o <= 1'b0;
         gpio_o   <= 'd0;
      end
   end
endmodule
