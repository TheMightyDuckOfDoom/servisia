// Copyright 2024 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module servisia (
    `ifdef TARGET_FPGA
    // Clock and Reset
    input wire  clk_i,
    input wire  rst_ni,

    // Memory Interface
    output wire [19:0] addr_o,
    output wire        write_o,
    output wire [7:0]  wdata_o,
    output wire        read_o,
    input  wire [7:0]  rdata_i,
    
    // GPIOs
    input  wire [num_gp_inp-1:0] gpio_i,
    output wire [num_gp_out-lcd_ios-1:0] gpio_o
    `endif
);
    parameter integer aw = 20;
    parameter integer lcd_ios = 10;
    parameter integer num_gp_out = 8 + lcd_ios;
    parameter integer num_gp_inp = 8;
    parameter integer num_gpios  = num_gp_out + num_gp_inp;
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

    wire [num_gp_out-1:0] gpio_output;
    wire [num_gpios-1:0] wb_gpio_rdt;

    `ifndef TARGET_FPGA
    // GPIO Pin Headers
    (* keep *) wire [num_gp_inp-1:0] gpio_i;
    (* keep *) wire [num_gp_out-lcd_ios-1:0] gpio_o;

    (* keep *) PINOUT_8 i_gpio_o (
        .TO_HEADER ( gpio_o )
    );

    (* keep *) PININ_8 i_gpio_i (
        .FROM_HEADER ( gpio_i )
    );

    // Internal CLK
    wire internal_clk;

    servisia_clk i_servisia_clk (
        .clk_o ( internal_clk )
    );

    // Input Pin Headers for misc signals
    wire [4:0] inp;

    (* keep *) wire clk_i, rst_ni;
    (* keep *) wire scan_en_i, scan_d_i, scan_d_o;
    (* keep *) PININ_5 i_misc_inp (
        .FROM_HEADER ( inp )
    );

    (* keep *) MUX2_74LVC1G157 i_clk_mux (
        .I0 ( internal_clk ),
        .I1 ( inp[1]       ),
        .S  ( inp[0]       ),
        .Y  ( clk_i        )
    );

    assign rst_ni    = inp[2];
    assign scan_en_i = inp[3];
    assign scan_d_i  = inp[4];

    // Disable external reset by default
    (* keep *) PULLUP_R0603 i_pullup_rst_ni (
        .Y ( rst_ni )
    );

    // Disable external clk by default
    (* keep *) PULLDOWN_R0603 i_pulldown_inp_0 (
        .Y ( inp[0] )
    );

    // Disable scan chain by default
    (* keep *) PULLDOWN_R0603 i_pulldown_scan_en_i (
        .Y ( scan_en_i )
    );

    // Default scan chain data input
    (* keep *) PULLDOWN_R0603 i_pulldown_scan_d_i (
        .Y ( scan_d_i )
    );

    // Default scan chain data output
    (* keep *) PULLDOWN_OUT_R0603 SCANCHAIN_OUT_DEFAULT (
        .Y ( scan_d_o )
    );

    // Output Pin Headers for misc signals
    (* keep *) PINOUT_1 i_misc_out (
        .TO_HEADER ( scan_d_o )
    );
    `endif

    `ifdef TARGET_CMOS
        // Reset generator
        reset_gen i_reset_gen (
            .clk_i  ( clk_i  ),
            .rst_ni ( rst_ni ),
            .rst_no ( rst_n  )
        );
    `else
        assign rst_n = rst_ni;
    `endif
    
    // SRAM interface
    `ifdef TARGET_FPGA
    assign addr_o     = sram_wen ? sram_waddr : sram_raddr;
    assign write_o    = sram_wen;
    assign wdata_o    = sram_wdata;
    assign read_o     = sram_ren;
    assign sram_rdata = rdata_i;
    `else
    servisia_mem i_servisia_mem (
        .clk_i     ( clk_i      ),
        .rst_ni    ( rst_n      ),
        .scan_en_i ( scan_en_i  ),
        .addr_i    ( sram_wen ? sram_waddr : sram_raddr ),
        .wdata_i   ( sram_wdata ),
        .write_i   ( sram_wen   ),
        .rdata_o   ( sram_rdata ),
        .read_i    ( sram_ren   )
    );
    `endif

    // GPIO
    generate if (num_gpios < 32)
        assign wb_core_rdt[31:num_gpios] = 'd0;
    endgenerate
    assign wb_core_rdt[num_gpios-1:0] = wb_gpio_rdt;

    servisia_gpio #(
        .OUT_WIDTH ( num_gp_out ),
        .INP_WIDTH ( num_gp_inp )
    ) gpio (
        .wb_clk_i ( clk_i       ),
        .wb_rst_i ( !rst_n      ),
        .wb_dat_i ( wb_core_dat[num_gpios-1:0] ),
        .wb_we_i  ( wb_core_we  ),
        .wb_stb_i ( wb_core_stb ),
        .wb_rdt_o ( wb_gpio_rdt ),
        .wb_ack_o ( wb_core_ack ),
        .gpio_i   ( gpio_i      ),
        .gpio_o   ( gpio_output )
    );

    assign gpio_o = gpio_output[num_gp_out-lcd_ios-1:0];

    `ifdef TARGET_CMOS
    // Contrast control
    wire lcd_contrast;
    VDIV_TRIMMER_POT i_pot (
        .Y ( lcd_contrast )
    );

    // LCD
    LCD_16x2 i_lcd (
        .Vee( lcd_contrast              ),
        .RS ( gpio_output[num_gp_out-1] ),
        .RW ( 1'b0                      ),
        .EN ( gpio_output[num_gp_out-2] ),
        .DB ( gpio_output[num_gp_out-3:num_gp_out-10] )
    );
    `endif

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
