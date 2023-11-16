// Copyright 2023 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module servisia (
    // Clock and Reset
    input wire  clk_i,
    input wire  rst_ni,

    // GPIOs
    output wire [num_gpios-1:0] q_o,

    // SRAM interface
    output wire [aw-1:0] sram_waddr_o,
    output wire [7:0]    sram_wdata_o,
    output wire          sram_wen_o,

    output wire [aw-1:0] sram_raddr_o,
    input wire [7:0]     sram_rdata_i,
    output wire          sram_ren_o
);
    parameter memsize = 65536;
    parameter aw = $clog2(memsize);
    parameter num_gpios = 1;

    subservient #(
        .memsize  ( memsize ),
        .WITH_CSR ( 0       )
    ) i_soc (
        // Clock & reset
        .i_clk ( clk_i   ),
        .i_rst ( !rst_ni ),

        //SRAM interface
        .o_sram_waddr ( sram_waddr_o ),
        .o_sram_wdata ( sram_wdata_o ),
        .o_sram_wen   ( sram_wen_o   ),
        .o_sram_raddr ( sram_raddr_o ),
        .i_sram_rdata ( sram_rdata_i ),
        .o_sram_ren   ( sram_ren_o   ),

        //Debug interface
        .i_debug_mode (  1'b0 ),
        .i_wb_dbg_adr ( 32'd0 ),
        .i_wb_dbg_dat ( 32'd0 ),
        .i_wb_dbg_sel (  4'd0 ),
        .i_wb_dbg_we  (  1'd0 ),
        .i_wb_dbg_stb (  1'd0 ),
        .o_wb_dbg_rdt (       ),
        .o_wb_dbg_ack (       ),

        // External I/O
        .o_gpio ( q_o )
    );
endmodule