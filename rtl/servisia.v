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
    output wire          sram_cs_no,
    output wire          sram_wen_no,
    output wire [aw-1:0] sram_addr_o,
    inout  wire [7:0]    sram_data_io
);
    parameter memsize = 65536;
    parameter aw = $clog2(memsize);
    parameter num_gpios = 1;

    wire sram_wen, sram_ren;
    wire [aw-1:0] sram_raddr, sram_waddr;
    wire [7:0] sram_wdata, sram_rdata;

    assign sram_cs_no = !(sram_wen | sram_ren);
    assign sram_addr_o = !sram_wen_no ? sram_waddr : sram_raddr;

    assign sram_wen_no = !sram_wen;
    assign sram_rdata = sram_ren ? sram_data_io : 8'd0;

    generate
        genvar i;
        for(i = 0; i < 8; i = i + 1) begin
            ZBUF_74LVC1G125 i_data_zbuf (
                .A    ( sram_wdata[i]   ),
                .EN_N ( sram_wen_no     ),
                .Y    ( sram_data_io[i] )
            );
        end
    endgenerate

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
        .o_gpio ( q_o )
    );
endmodule