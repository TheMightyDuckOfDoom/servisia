// Copyright 2023 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module servisia (
    // Clock
    input wire  clk_i,

    // GPIOs
    output wire [num_gpios-1:0] gpio_o
);
    parameter integer aw = 14;
    parameter integer num_gpios = 8;
    parameter integer memsize = 1 << aw;

    wire rst_n;

    wire          sram_wen, sram_ren;
    wire [aw-1:0] sram_raddr, sram_waddr;
    wire    [7:0] sram_wdata, sram_rdata;

    wire [31:0]	wb_core_adr;
    wire [31:0]	wb_core_dat;
    wire  [3:0] wb_core_sel;
    wire        wb_core_we;
    wire        wb_core_stb;
    wire [31:0] wb_core_rdt;
    wire        wb_core_ack;

    wire [num_gpios-1:0] wb_gpio_rdt;

    // Reset generator
    reset_gen #(
        .RESET_CYCLES ( 2 )
    ) i_reset_gen (
        .clk_i  ( clk_i ),
        .rst_no ( rst_n )
    );
    
    // SRAM interface
    sram_rw i_sram_rw (
        .clk_i   ( clk_i      ),
        .rst_ni  ( rst_n      ),
        .addr_i  ( sram_wen ? sram_waddr : sram_raddr ),
        .wdata_i ( sram_wdata ),
        .write_i ( sram_wen   ),
        .rdata_o ( sram_rdata ),
        .read_i  ( sram_ren   )
    );

    // GPIO Read Data
    assign wb_core_rdt[31:num_gpios] = 'd0;
    assign wb_core_rdt[num_gpios-1:0] = wb_gpio_rdt;

    servisia_gpo #(
        .WIDTH ( num_gpios )
    ) gpio (
        .wb_clk_i ( clk_i       ),
        .wb_rst_i ( !rst_n      ),
        .wb_dat_i ( wb_core_dat[num_gpios-1:0] ),
        .wb_we_i  ( wb_core_we  ),
        .wb_stb_i ( wb_core_stb ),
        .wb_rdt_o ( wb_gpio_rdt ),
        .wb_ack_o ( wb_core_ack ),
        .gpio_o   ( gpio_o      )
    );

    // Subservient core
    subservient_core #(
        .memsize  ( memsize ),
        .WITH_CSR ( 0       )
    ) i_core (
        .i_clk       ( clk_i  ),
        .i_rst       ( !rst_n ),
        .i_timer_irq ( 1'b0   ),

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

        //Peripheral interface
        .o_wb_adr ( wb_core_adr ),
        .o_wb_dat ( wb_core_dat ),
        .o_wb_sel ( wb_core_sel ),
        .o_wb_we  ( wb_core_we  ),
        .o_wb_stb ( wb_core_stb ),
        .i_wb_rdt ( wb_core_rdt ),
        .i_wb_ack ( wb_core_ack )
    );

endmodule
