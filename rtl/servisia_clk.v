// Copyright 2024 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module servisia_clk (
    output reg clk_o
);
    wire clk_16mhz32;

    (* keep *) SG615P_16MHZ32 i_oscillator (
        .CLKOUT ( clk_16mhz32 )
    );

    clkdiv i_clkdiv (
        .clk_i ( clk_16mhz32 ),
        .clk_o ( clk_o )
    );

endmodule
