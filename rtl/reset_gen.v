// Copyright 2023 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module reset_gen #(
    parameter integer RESET_CYCLES = 2
) (
    input  wire clk_i,
    output wire rst_no
);
    // Internal reset signal from POR
    wire internal_rst_n;

    // Registered reset signal
    reg [RESET_CYCLES-1:0] rst_n_q;

    // Power On Reset
    POR_DS9809PRSS3 i_por (
        .RESET_N( internal_rst_n )
    );

    // Synchronize reset signal
    always @(posedge clk_i or negedge internal_rst_n) begin
        if (!internal_rst_n) begin
            // Reset all registers to 0 -> Also asserts rst_ni
            rst_n_q <= {RESET_CYCLES{1'b0}};
        end else begin
            // Shift POR signal into rst_n_q
            rst_n_q <= {rst_n_q[RESET_CYCLES-2:0], 1'b1};
        end
    end

    // Output reset signal
    assign rst_no = rst_n_q[RESET_CYCLES-1];

endmodule : reset_gen
