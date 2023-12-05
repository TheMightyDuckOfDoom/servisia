// Copyright 2023 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module servisia_tb #(
  parameter time    CLK_PERIOD = 10,
  parameter time    CLK_HALF = CLK_PERIOD / 2,
  parameter integer SIM_CYCLES = 100000,
  parameter         program_file = "programs/hello.binary"
) ();

  logic clk, rst_n;
  logic gpio;

  initial begin
    integer file;

    // Reset
    clk = 1'b0;
    rst_n = 1'b0;

    #CLK_HALF
    clk = 1'b1;
    #CLK_HALF
    clk = 1'b0;
    rst_n = 1'b1;

    // Load program
    $display("Loading program");
    `ifdef POST_SYNTHESIS
      $readmemh(program_file, i_dut.i_sram_rw__i_sram.i_sram_model.mem);
    `endif
    `ifdef POST_LAYOUT
      $readmemh(program_file, i_dut.i_sram_rw__i_sram.i_sram_model.mem);
    `endif
    `ifndef POST_SYNTHESIS
    `ifndef POST_LAYOUT
      $readmemh(program_file, i_dut.i_sram_rw.i_sram.i_sram_model.mem);
      for(int i = 0; i < 20; i++) begin
        $display("mem[%d] = %h", i, i_dut.i_sram_rw.i_sram.i_sram_model.mem[i]);
      end
      $display("Reference");
      for(int i = 0; i < 20; i++) begin
        $display("mem[%d] = %h", i, i_generic_ram.mem[i]);
      end
    `endif
    `endif

    // Running clock
    forever #CLK_PERIOD clk = ~clk;
  end
  
  `ifndef POST_SYNTHESIS
  `ifndef POST_LAYOUT
    // Reference memory
    wire [7:0] sram_rdata_ref;
    subservient_generic_ram #(
        .depth   ( 1 << 14      ),
        .memfile ( program_file )
    ) i_generic_ram (
        .i_clk   ( i_dut.clk_i      ),
        .i_rst   ( i_dut.rst_ni     ),
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

  // Instantiate DUT
  servisia i_dut (
    .clk_i  ( clk   ),
    .rst_ni ( rst_n ),
    .gpio_o ( gpio  )
  );

  always @(gpio) begin
    $display();
    $display("GPIO change! gpio=%b", gpio);
    $display();
  end

  initial begin
    int cycle;
    cycle = 0;

    `ifndef POST_LAYOUT
      $display("Starting post synthesis simulation");
      $dumpfile("dump_post.vcd");
    `endif
    `ifndef POST_SYNTHESIS
      $display("Starting layout simulation");
      $dumpfile("dump_layout.vcd");
    `endif
    `ifndef POST_SYNTHESIS
    `ifndef POST_LAYOUT
      $display("Starting simulation");
      $dumpfile("dump.vcd");
    `endif
    `endif
    $dumpvars();

    // Wait for reset to be released
    @(posedge rst_n);

    $display("Reset released");

    repeat (SIM_CYCLES) begin 
      @(posedge clk);
      //$display("cycle: %d, clk=%b, rst_n=%b gpio=%b", cycle, clk, rst_n, gpio);
      //$display("cycle: %d, cs_n=%b, we_n=%b, oe_n=%b, addr=%d, data=%d", cycle, i_dut.i_sram_rw.i_sram.CS_N, i_dut.i_sram_rw.i_sram.WE_N, i_dut.i_sram_rw.i_sram.OE_N, i_dut.i_sram_rw.i_sram.A, i_dut.i_sram_rw.i_sram.IO);
      @(negedge clk);
      //$display("cycle: %d, clk=%b, rst_n=%b gpio=%b", cycle, clk, rst_n, gpio);
      //$display("cs_n=%b, we_n=%b, oe_n=%b, addr=%d, data=%d", i_dut.i_sram_rw.i_sram.CS_N, i_dut.i_sram_rw.i_sram.WE_N, i_dut.i_sram_rw.i_sram.OE_N, i_dut.i_sram_rw.i_sram.A, i_dut.i_sram_rw.i_sram.IO);
      cycle++;
    end

    `ifdef POST_SYNTHESIS
      $display("Post Synthesis Simulation finished!");
    `endif
    `ifdef POST_LAYOUT
      $display("Layout Simulation finished!");
    `endif
    `ifndef POST_SYNTHESIS
    `ifndef POST_LAYOUT
      $display("Simulation finished!");
    `endif
    `endif
    // Stop simulation
    $finish;
  end

endmodule : servisia_tb
