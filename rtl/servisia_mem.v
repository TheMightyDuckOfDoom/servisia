// Copyright 2023 Tobias Senti
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

module servisia_mem (
    input wire clk_i,
    input wire rst_ni,

    input wire        read_i,
    input wire        write_i,
    input wire [19:0] addr_i,
    input wire  [7:0] wdata_i,
    
    output reg [7:0] rdata_o
);
    wire [7:0] data_z;

    // Tristate Buffers
    generate;
        genvar i;
        for (i = 0; i < 8; i = i + 1) begin : gen_tristate
            `ifdef CMOS
                ZBUF_74LVC1G125 i_tristate (
                    .A    ( wdata_i[i] ),
                    .Y    ( data_z[i] ),
                    .EN_N ( !write_i   )
                );
            `endif
            `ifdef RELAY
                ZBUF_JY4100F_S_C i_tristate (
                    .A    ( wdata_i[i] ),
                    .Y    ( data_z[i] ),
                    .EN_N ( !write_i   )
                );
            `endif
        end
    endgenerate

    // Instantiate FLASH
    (* keep *) SST39SF040_70_DIP i_flash (
        .CE_N ( clk_i ),
        .WE_N ( read_i | !write_i | addr_i[19]),
        .OE_N ( !read_i           | addr_i[19]),
        .A    ( addr_i[18:0]      ),
        .DQ   ( data_z            )
    );

    // Instantiate SRAM
    (* keep *) AS6C4008_55_DIP i_sram (
        .CS_N ( clk_i ),
        .WE_N ( read_i | !write_i | !addr_i[19]),
        .OE_N ( !read_i           | !addr_i[19]),
        .A    ( addr_i[18:0]      ),
        .DQ   ( data_z            )
    );
    
    // Observability
    //wire write_ff;
    //(* keep *) DFF_74LVC1G175 i_write_ff (
    //    .CLK ( clk_i    ),
    //    .D   ( !write_i ),
    //    .Q   ( write_ff )
    //);

    // Flip Flops
    always @(posedge clk_i) begin
        rdata_o[7:0] <= read_i && rst_ni ? data_z[7:0] : '0;
    end
endmodule
