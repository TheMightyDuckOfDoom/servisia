// Copyright 2023 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module servisia (
    // Clock and Reset
    input wire  clk_i,
    input wire  rst_ni,

    // GPIOs
    output wire [num_gpios-1:0] gpio_o
);
    parameter aw = 14;
    parameter num_gpios = 1;
    parameter memsize = 1 << aw;

    wire sram_wen, sram_ren;
    wire [aw-1:0] sram_raddr, sram_waddr;
    wire [7:0] sram_wdata, sram_rdata;

    sram_rw i_sram_rw (
        .clk_i   ( clk_i      ),
        .rst_ni  ( rst_ni     ),
        .addr_i  ( sram_wen ? sram_waddr : sram_raddr ),
        .wdata_i ( sram_wdata ),
        .write_i ( sram_wen   ),
        .rdata_o ( sram_rdata ),
        .read_i  ( sram_ren   )
    );

    subservient #(
        .memsize  ( memsize ),
        .WITH_CSR ( 0       )
    ) i_soc (
        // Clock & reset
        .i_clk ( clk_i   ),
        .i_rst ( !rst_ni ),

        //SRAM interface
        .o_sram_waddr ( sram_waddr ),
        .o_sram_wdata ( sram_wdata ),
        .o_sram_wen   ( sram_wen   ),
        .o_sram_raddr ( sram_raddr ),
        .i_sram_rdata ( sram_rdata ),
        .o_sram_ren   ( sram_ren   ),

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
        .o_gpio ( gpio_o )
    );
endmodule