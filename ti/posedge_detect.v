// Copyright (c) 2024, Texas Instruments Incorporated
// All rights reserved. See manifest file for licensing info.

module posedge_detect (
    input rst,
    input sig,
    input clk,
    output pe
);

    reg sig_dly1;
    reg sig_dly2;
    reg sig_dly3;

    always @ (posedge clk) begin
        if (rst == 1) begin
            sig_dly1 <= 0;
            sig_dly2 <= 0;
            sig_dly3 <= 0;
        end
        else begin
            sig_dly1 <= sig;
            sig_dly2 <= sig_dly1;
            sig_dly3 <= sig_dly2;
        end
    end

    assign pe = sig_dly2 & ~sig_dly3;

endmodule
