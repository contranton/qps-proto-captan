// Copyright (c) 2022-2024, Texas Instruments Incorporated
// All rights reserved. See manifest file for licensing info.

module spi_master (
    input logic spi_clk,            // free running spi FSM clock
    input logic SPI_EN,             // make it logic HIGH to enable the FSM
    input logic tx_trn,             // TX TRIGGER: 0 to 1 transition indicates write SPI data to DUT
    input logic rx_trn,             // RX TRIGGER: 0 to 1 transition indicates read SPI data from DUT
    input logic [7:0] addr,         // DUT's register address
    input logic [15:0] wr_data,     // DUT's register write data
    input logic SPI_MISO,           // DUT's SDO
    input logic rst,                // active high reset
    output logic SPI_CS_Z,          // DUT's CSz
    output logic SPI_MOSI,          // DUT's SDI
    output logic SPI_SCLK,          // DUT's SCLK
    output logic SPI_BUSY,          // FSM busy indicator
    output logic SPI_READ_DONE,     // FSM read done indicator
    output logic [23:0] read_data   // Deserialzed SPI_MISO
);

    logic [4:0] tx_count;
    logic counter_en;
    logic read_mode_en;
    logic spi_clk_out;
    logic cs_z;
    logic [23:0] tx_buff;
    logic [23:0] tx_buff1;
    logic [23:0] rx_buff;
    logic tx_out;
    logic read_done_flag;
    logic trn;
    logic fsm_start;
    logic [2:0] fsm_start_count;
    logic [23:0] temp;
    logic busy;
    logic read_done;
    logic st_trn;
    logic tx_trn_pulse;
    logic rx_trn_pulse;
    logic tx_trn_delay;
    logic rx_trn_delay;

    // tx_pulse generator
    always @(posedge spi_clk or posedge rst) begin
        if (rst) tx_trn_delay <= 1'b0;
        else tx_trn_delay <= tx_trn;
    end

    assign tx_trn_pulse = tx_trn & (~tx_trn_delay);

    // rx_pulse generator
    always @(posedge spi_clk or posedge rst) begin
        if (rst) rx_trn_delay <= 1'b0;
        else rx_trn_delay <= rx_trn;
    end

    assign rx_trn_pulse = rx_trn & (~rx_trn_delay);
    assign trn = (tx_trn_pulse | rx_trn_pulse) & (!busy);
    assign tx_buff = {addr,wr_data};

    always @(posedge spi_clk or posedge rst or posedge trn) begin
        if (rst) fsm_start_count <=  3'd0;
        else if (trn) fsm_start_count <=  3'd4;
        else if (fsm_start_count == 3'd0) fsm_start_count <= 3'd2;
        else fsm_start_count <=  (fsm_start_count - 3'd1);
    end

    assign fsm_start = (fsm_start_count == 3'd3) ? 1'b1 : 1'b0;
    assign counter_en = (fsm_start);

    always @(negedge spi_clk or posedge rst) begin
        if (rst) tx_count <=  5'd0;
        else if (counter_en) tx_count <=  5'd24;
        else if (tx_count == 5'd0) tx_count <=  5'd24;
        else tx_count <=  tx_count - 5'd1;
    end

    enum logic [2:0] {
        ST_IDLE = 3'd0,
        ST_TRN = 3'd1,
        ST_READ_DONE = 3'd2
    } curr_state, next_state;

    always@(negedge spi_clk or posedge rst) begin
        if (rst == 1'b1) curr_state <= ST_IDLE;
        else if (SPI_EN == 1'b1) curr_state <= next_state;
        else curr_state <= ST_IDLE;
    end

    always_comb begin
        case (curr_state)
            ST_IDLE: begin
                cs_z = 1'b1;
                busy = 1'b0;
                read_done_flag = 1'b0;
                tx_out = 1'b0;
                if (counter_en == 1'b1) begin
                    next_state = ST_TRN;
                end
                else begin next_state = ST_IDLE; end
            end

            ST_TRN: begin
                cs_z = 1'b0;
                read_done_flag = 1'b0;
                busy = 1'b1;
                tx_out = tx_buff[(tx_count - 5'd1)];
                if (tx_count == 5'd1) next_state = ST_READ_DONE;
                else next_state = ST_TRN;
            end

            ST_READ_DONE: begin
                cs_z = 1'b0;
                tx_out = 1'b0;
                busy = 1'b1;
                if ((tx_count == 5'd0) && (read_mode_en == 1'b1)) begin
                    read_done_flag = 1'b1;
                    next_state = ST_READ_DONE;
                end
                else begin
                    read_done_flag = 1'b0;
                    next_state = ST_IDLE;
                end
            end

            default: begin
                cs_z = 1'b1;
                busy = 1'b0;
                read_done_flag = 1'b0;
                tx_out = 1'b0;
                next_state = ST_IDLE;
            end
        endcase
    end

    assign st_trn = (curr_state == ST_TRN) ? 1'b1 : 1'b0;
    assign spi_clk_out = (st_trn) ? spi_clk : 1'b0;

    // RX Shift reg
    always @(posedge SPI_SCLK or posedge rst) begin
        if (rst) temp <=  24'h000000;
        else if (read_mode_en) temp <= {temp[22:0],SPI_MISO};
        else temp <=  24'h000000;
    end

    assign rx_buff = temp;

    // Read mode en logic
    always @(posedge rx_trn_pulse or negedge read_done_flag or posedge rst) begin
        if (rx_trn_pulse) read_mode_en <=  1'b1;
        else if (rst) read_mode_en  <= 1'b0;
        else if (!read_done_flag) read_mode_en <=  1'b0;
        else read_mode_en <=  1'b0;
    end

    // read done logic
    always @(posedge read_done_flag or posedge counter_en or posedge rst) begin
        if (rst) read_done <= 1'b0;
        else if (counter_en) read_done <= 1'b0;
        else if (read_done_flag) read_done <= 1'b1;
        else read_done <= 1'b0;
    end

    assign read_data = rx_buff;
    assign SPI_MOSI = (!cs_z) ? (tx_out) : 1'b1; // Hi Z
    assign SPI_SCLK = spi_clk_out;
    assign SPI_CS_Z = cs_z;
    assign SPI_BUSY = busy;
    assign SPI_READ_DONE = read_done;

endmodule
