// Copyright 2023 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module servisia_tb #(
  parameter time    CLK_PERIOD = 10,
  parameter time    CLK_HALF = CLK_PERIOD / 2,
  parameter integer SIM_CYCLES = 100000,
  parameter         program_file = "programs/hello.binary",
  parameter MEM_ADDR_WIDTH = 21
) ();

  logic clk;
  logic [7:0] gpio;

  initial begin
    integer file;
    clk = 1'b0;

    // Load program
    $display("Loading program");
    `ifdef TARGET_SIM_SYNTH
      $readmemh(program_file, i_dut.i_servisia_mem__i_flash.i_sram_model.mem);
    `endif
    `ifdef TARGET_SIM_LAYOUT
      $readmemh(program_file, i_dut.i_servisia_mem__i_flash.i_sram_model.mem);
    `endif
    `ifndef TARGET_SIM_SYNTH
    `ifndef TARGET_SIM_LAYOUT
      $readmemh(program_file, i_dut.i_servisia_mem.i_flash.i_sram_model.mem);
      for(int i = 0; i < 20; i++) begin
        $display("mem[%d] = %h", i, i_dut.i_servisia_mem.i_flash.i_sram_model.mem[i]);
      end
      wait(i_generic_ram.mem[0] != 0);
      $display("Reference");
      for(int i = 0; i < 20; i++) begin
        $display("mem[%d] = %h", i, i_generic_ram.mem[i]);
      end
    `endif
    `endif

    // Running clock
    forever #CLK_PERIOD clk = ~clk;
  end
  
  `ifndef TARGET_SIM_SYNTH
  `ifndef TARGET_SIM_LAYOUT
    // Reference memory
    wire [7:0] sram_rdata_ref;
    subservient_generic_ram #(
        .depth   ( 1 << MEM_ADDR_WIDTH ),
        .memfile ( program_file )
    ) i_generic_ram (
        .i_clk   ( i_dut.clk_i      ),
        .i_rst   ( i_dut.rst_n      ),
        .i_waddr ( i_dut.sram_waddr ),
        .i_wdata ( i_dut.sram_wdata ),
        .i_wen   ( i_dut.sram_wen   ),
        .i_raddr ( i_dut.sram_raddr ),
        .o_rdata ( sram_rdata_ref   ),
        .i_ren   ( i_dut.sram_ren   )
    );

    always @(posedge i_dut.clk_i) begin
        if(sram_rdata_ref != i_dut.sram_rdata) begin
            $error("SRAM mismatch! ref=%h, dut=%h", sram_rdata_ref, i_dut.sram_rdata);
        end
    end
  `endif
  `endif

  // Apply Power
  // Default / Unconnected is 0
  `ifdef TARGET_SIM_LAYOUT
    assign i_dut.VDD = 1'b1;
    assign i_dut.GND = 1'b1;
  `endif

  // Instantiate DUT
  servisia i_dut (
    .clk_i  ( clk   ),
    .gpio_o ( gpio  )
  );

  // Monitor GPIO
  always @(gpio) begin
    $display();
    $display("GPIO change! gpio=%d %c", gpio, gpio);
    $display();
  end

  // Testbench
  initial begin
    int cycle;
    cycle = 0;

    `ifndef TARGET_SIM_LAYOUT
      $display("Starting post synthesis simulation");
      $dumpfile("dump_post.vcd");
    `endif
    `ifndef TARGET_SIM_SYNTH
      $display("Starting layout simulation");
      $dumpfile("dump_layout.vcd");
    `endif
    `ifndef TARGET_SIM_SYNTH
    `ifndef TARGET_SIM_LAYOUT
      $display("Starting simulation");
      $dumpfile("dump.vcd");
    `endif
    `endif
    $dumpvars();

    repeat (SIM_CYCLES) begin 
      @(posedge clk);
      //$display("cycle: %d, clk=%b, rst_n=%b gpio=%b", cycle, clk, rst_n, gpio);
      //$display("cycle: %d, cs_n=%b, we_n=%b, oe_n=%b, addr=%d, data=%d", cycle, i_dut.i_sram_rw.i_sram.CS_N, i_dut.i_sram_rw.i_sram.WE_N, i_dut.i_sram_rw.i_sram.OE_N, i_dut.i_sram_rw.i_sram.A, i_dut.i_sram_rw.i_sram.IO);
      @(negedge clk);
      //$display("cycle: %d, clk=%b, rst_n=%b gpio=%b", cycle, clk, rst_n, gpio);
      //$display("cs_n=%b, we_n=%b, oe_n=%b, addr=%d, data=%d", i_dut.i_sram_rw.i_sram.CS_N, i_dut.i_sram_rw.i_sram.WE_N, i_dut.i_sram_rw.i_sram.OE_N, i_dut.i_sram_rw.i_sram.A, i_dut.i_sram_rw.i_sram.IO);
      cycle++;
    end

    `ifdef TARGET_SIM_SYNTH
      $display("Post Synthesis Simulation finished!");
    `endif
    `ifdef TARGET_SIM_LAYOUT
      $display("Layout Simulation finished!");
    `endif
    `ifndef TARGET_SIM_SYNTH
    `ifndef TARGET_SIM_LAYOUT
      $display("Simulation finished!");
    `endif
    `endif
    // Stop simulation
    $finish;
  end

endmodule : servisia_tb
