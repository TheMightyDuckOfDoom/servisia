// Copyright 2023 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module sram_rw (
    input wire clk_i,
    input wire rst_ni,

    input wire        read_i,
    input wire        write_i,
    input wire [13:0] addr_i,
    input wire  [7:0] wdata_i,
    
    output reg [7:0] rdata_o
);
    wire [7:0] data_z;


    generate;
        genvar i;
        for (i = 0; i < 8; i = i + 1) begin : gen_tristate
            ZBUF_74LVC1G125 i_tristate (
                .A    ( wdata_i[i] ),
                .Y    ( data_z[i] ),
                .EN_N ( !write_i   )
            );
        end
    endgenerate

    // Instantiate SRAM
    (* keep *) W24129A_35 i_sram (
        .CS_N ( clk_i             ),
        .WE_N ( read_i | !write_i ),
        .OE_N ( !read_i           ),
        .A    ( addr_i            ),
        .IO   ( data_z            )
    );

    // Flip Flops
    always @(posedge clk_i) begin
        rdata_o[7:0] <= read_i && rst_ni ? data_z[7:0] : '0;
    end
endmodule
