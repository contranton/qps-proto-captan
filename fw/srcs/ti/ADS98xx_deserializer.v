// Copyright (c) 2022-2024, Texas Instruments Incorporated
// All rights reserved. See manifest file for licensing info.

module deser_cmos (
                   input CMOS_DIN_A, // input serial data D0 (CMOS logic)
                   input CMOS_DIN_B, // input serial data D1 (CMOS logic)
                   input CMOS_DIN_C, // input serial data D2 (CMOS logic)
                   input CMOS_DIN_D, // input serial data D3 (CMOS logic)
                   input DCLK, // input DCLK (CMOS logic)
                   input FCLK, // input FCLK (CMOS logic)
                   input data_rate, // DDR or SDR selection (DDR : data_rate = 0; SDR : data_rate = 1)
                   input [1:0] data_lanes, // no:of lanes; 0 = 1 lane; 1 = 2 lane, 2 = 4 lane
                   input RST,
                   input flip_ddr_polarity,
                   output DRDY, // data ready signal (indicates the final deserialized output)
                   output [191:0] DOUT // deserialized output
                   );

   ila_deser ila_deser_1 (
      .clk    (DCLK),
      .probe0 (pos_DIN_A),
      .probe1 (neg_DIN_A),
      .probe2 (pos_DIN_B),
      .probe3 (neg_DIN_B),
      .probe4 (pos_DIN_C),
      .probe5 (neg_DIN_C),
      .probe6 (pos_DIN_D),
      .probe7 (neg_DIN_D),
      .probe8 (pos_CMOS_FCLK),
      .probe9 (neg_CMOS_FCLK),
      .probe10 (DRDY),
      .probe11 (DOUT),
      .probe12 (FCLK_pos)
      );


   // IDDR  instantiation
    wire pos_DIN_A, neg_DIN_A;
   IDDR #(
     .DDR_CLK_EDGE("OPPOSITE_EDGE")
     ) iDDR_DIN_A (
     .D (CMOS_DIN_A),
     .C (DCLK),
     .Q1 (pos_DIN_A),
     .Q2 (neg_DIN_A),
     .CE (1),
     .R (0),
     .S (0)
     );

   wire pos_DIN_B, neg_DIN_B;
   IDDR #(
     .DDR_CLK_EDGE("OPPOSITE_EDGE")
     ) iDDR_DIN_B (
     .D (CMOS_DIN_B),
     .C (DCLK),
     .Q1 (pos_DIN_B),
     .Q2 (neg_DIN_B),
     .CE (1),
     .R (0),
     .S (0)
     );

   wire pos_DIN_C, neg_DIN_C;
   IDDR #(
     .DDR_CLK_EDGE("OPPOSITE_EDGE")
     ) iDDR_DIN_C (
     .D (CMOS_DIN_C),
     .C (DCLK),
     .Q1 (pos_DIN_C),
     .Q2 (neg_DIN_C),
     .CE (1),
     .R (0),
     .S (0)
     );

   wire pos_DIN_D, neg_DIN_D;
   IDDR #(
     .DDR_CLK_EDGE("OPPOSITE_EDGE")
     ) iDDR_DIN_D (
     .D (CMOS_DIN_D),
     .C (DCLK),
     .Q1 (pos_DIN_D),
     .Q2 (neg_DIN_D),
     .CE (1),
     .R (0),
     .S (0)
     );

   wire pos_CMOS_FCLK, neg_CMOS_FCLK;
   IDDR #(
     .DDR_CLK_EDGE("OPPOSITE_EDGE")
     ) iDDR_FCLK (
     .D (FCLK),
     .C (DCLK),
     .Q1 (pos_CMOS_FCLK),
     .Q2 (neg_CMOS_FCLK),
     .CE (1),
     .R (0),
     .S (0)
     );

   // SDR DESERIALIZER --------------------------------------------------------------------
   reg [191:0] shift_reg_d; // D3
   reg [95:0] shift_reg_b; // D1
   reg [47:0] shift_reg_a, shift_reg_c; // D0 and D2
   wire [191:0] dout_sdr_1lane, dout_sdr_2lane, dout_sdr_4lane;

   // 192 bits are aligned as {ADC A {191:96}, ADC B {95:0}}
   always @(negedge DCLK) begin // latching at the neg edge of DCLK
      shift_reg_d[191:1] <= shift_reg_d[190:0];
      shift_reg_d[0] <= CMOS_DIN_D;

      shift_reg_b[95:1] <= shift_reg_b[94:0];
      shift_reg_b[0] <= CMOS_DIN_B;

      shift_reg_c[47:1] <= shift_reg_c[46:0];
      shift_reg_c[0] <= CMOS_DIN_C;

      shift_reg_a[47:1] <= shift_reg_a[46:0];
      shift_reg_a[0] <= CMOS_DIN_A;
   end

   assign dout_sdr_1lane = shift_reg_d; // D3 has all the data

   genvar i;
   generate

      for (i = 0; i < 96; i = i + 1) begin
         assign dout_sdr_2lane[i] = shift_reg_b[i]; // D3 all bits of ADC A
         assign dout_sdr_2lane[96 + i] = shift_reg_d[i]; // D1 all bits of ADC B
      end

      for (i = 0; i < 48; i = i + 1) begin
         assign dout_sdr_4lane[2*i] = shift_reg_a[i]; // D2 LSB of ADC A
         assign dout_sdr_4lane[2*i + 1] = shift_reg_b[i]; // D3 MSB of ADC A
         assign dout_sdr_4lane[96 + 2*i] = shift_reg_c[i]; // D0 LSB of ADC B
         assign dout_sdr_4lane[97 + 2*i] = shift_reg_d[i]; // D1 MSB of ADC B
      end
   endgenerate

   // DDR DESERIALIZER ----------------------------------------------------------------

   reg [96:0] pos_shift_reg_d, neg_shift_reg_d;
   reg [48:0] pos_shift_reg_b, neg_shift_reg_b;
   reg [24:0] pos_shift_reg_c, neg_shift_reg_c;
   reg [24:0] pos_shift_reg_a, neg_shift_reg_a;
   wire [191:0] dout_ddr_1lane, dout_ddr_1lane_neg, dout_ddr_2lane, dout_ddr_2lane_neg, dout_ddr_4lane, dout_ddr_4lane_neg;

   always @(posedge DCLK) begin
      pos_shift_reg_d[96:1] <= pos_shift_reg_d[95:0];
      pos_shift_reg_d[0] <= pos_DIN_D;
      neg_shift_reg_d[96:1] <= neg_shift_reg_d[95:0];
      neg_shift_reg_d[0] <= neg_DIN_D;

      pos_shift_reg_b[48:1] <= pos_shift_reg_b[47:0];
      pos_shift_reg_b[0] <= pos_DIN_B;
      neg_shift_reg_b[48:1] <= neg_shift_reg_b[47:0];
      neg_shift_reg_b[0] <= neg_DIN_B;

      pos_shift_reg_c[24:1] <= pos_shift_reg_c[23:0];
      pos_shift_reg_c[0] <= pos_DIN_C;
      neg_shift_reg_c[24:1] <= neg_shift_reg_c[23:0];
      neg_shift_reg_c[0] <= neg_DIN_C;

      pos_shift_reg_a[24:1] <= pos_shift_reg_a[23:0];
      pos_shift_reg_a[0] <= pos_DIN_A;
      neg_shift_reg_a[24:1] <= neg_shift_reg_a[23:0];
      neg_shift_reg_a[0] <= neg_DIN_A;
   end


   // 192 bits are aligned as {ADC A {191:96}, ADC B {95:0}}
   generate
      for (i = 0; i < 96; i = i + 1) begin
         assign dout_ddr_1lane[2*i] = pos_shift_reg_d[i];
         assign dout_ddr_1lane[2*i + 1] = neg_shift_reg_d[i];
      end

      for (i = 0; i < 96; i = i + 1) begin
         assign dout_ddr_1lane_neg[2*i] = neg_shift_reg_d[i];
         assign dout_ddr_1lane_neg[2*i + 1] = pos_shift_reg_d[i+1];
      end

      for (i = 0; i < 48; i = i + 1) begin
         assign dout_ddr_2lane[2*i] = pos_shift_reg_b[i];
         assign dout_ddr_2lane[2*i + 1] = neg_shift_reg_b[i];
         assign dout_ddr_2lane[96 + 2*i] = pos_shift_reg_d[i];
         assign dout_ddr_2lane[97 + 2*i] = neg_shift_reg_d[i];
      end

      for (i = 0; i < 48; i = i + 1) begin
         assign dout_ddr_2lane_neg[2*i] = neg_shift_reg_b[i];
         assign dout_ddr_2lane_neg[2*i + 1] = pos_shift_reg_b[i+1];
         assign dout_ddr_2lane_neg[96 + 2*i] = neg_shift_reg_d[i];
         assign dout_ddr_2lane_neg[97 + 2*i] = pos_shift_reg_d[i+1];
      end

      for (i = 0; i < 24; i = i + 1) begin
         assign dout_ddr_4lane[4*i] = pos_shift_reg_a[i];
         assign dout_ddr_4lane[4*i + 1] = pos_shift_reg_b[i];
         assign dout_ddr_4lane[4*i + 2] = neg_shift_reg_a[i];
         assign dout_ddr_4lane[4*i + 3] = neg_shift_reg_b[i];
         assign dout_ddr_4lane[96 + 4*i] = pos_shift_reg_c[i];
         assign dout_ddr_4lane[97 + 4*i] = pos_shift_reg_d[i];
         assign dout_ddr_4lane[98 + 4*i] = neg_shift_reg_c[i];
         assign dout_ddr_4lane[99 + 4*i] = neg_shift_reg_d[i];
      end

      for (i = 0; i < 24; i = i + 1) begin
         assign dout_ddr_4lane_neg[4*i] = neg_shift_reg_a[i];
         assign dout_ddr_4lane_neg[4*i + 1] = neg_shift_reg_b[i];
         assign dout_ddr_4lane_neg[4*i + 2] = pos_shift_reg_a[i];
         assign dout_ddr_4lane_neg[4*i + 3] = pos_shift_reg_b[i];
         assign dout_ddr_4lane_neg[96 + 4*i] = neg_shift_reg_c[i];
         assign dout_ddr_4lane_neg[97 + 4*i] = neg_shift_reg_d[i];
         assign dout_ddr_4lane_neg[98 + 4*i] = pos_shift_reg_c[i];
         assign dout_ddr_4lane_neg[99 + 4*i] = pos_shift_reg_d[i];
      end
   endgenerate

   // DATA OUTPUT MUX -----------------------------------------------------------------------------------------------
   // if DDR (data_rate = 0) then data is interleaved between pos_shift_reg [95:0] and neg_shift_reg [95:0]
   // if SDR (data_rate = 1) then all data is in pos_shift_reg [191:0]

   reg FCLK_pos;

   // final deserialized output selection
   assign DOUT = (data_rate == 0 && data_lanes == 2'b00 && FCLK_pos == 0) ? (dout_ddr_1lane) :
                 (data_rate == 0 && data_lanes == 2'b00 && FCLK_pos == 1) ? (dout_ddr_1lane_neg) :
                 (data_rate == 0 && data_lanes == 2'b01 && FCLK_pos == 0) ? (dout_ddr_2lane) :
                 (data_rate == 0 && data_lanes == 2'b01 && FCLK_pos == 1) ? (dout_ddr_2lane_neg) :
                 (data_rate == 0 && data_lanes == 2'b10 && flip_ddr_polarity == 0) ? (dout_ddr_4lane) :
                 (data_rate == 0 && data_lanes == 2'b10 && flip_ddr_polarity == 1) ? (dout_ddr_4lane_neg) :
                 (data_rate == 1 && data_lanes == 2'b00)?(dout_sdr_1lane) :
                 (data_rate == 1 && data_lanes == 2'b01)?(dout_sdr_2lane) :
                 (data_rate == 1 && data_lanes == 2'b10)?(dout_sdr_4lane) :
                 (192'hBAD00BAD00BAD00BAD00BAD00BAD00BAD00BAD00BAD00BAD);

   // generation of DRDY signal
   // When FCLK_pos = HIGH, mux the dout_ddr_4lane_neg; when FCLK_pos = LOW, mus the dout_ddr_4lane
   reg fclk_ddr_dly1;
   reg fclk_ddr_dly2;
   reg fclk_ddr_dly3;

   always @(negedge DCLK) begin
      fclk_ddr_dly1 <= pos_CMOS_FCLK | neg_CMOS_FCLK;
      fclk_ddr_dly2 <= fclk_ddr_dly1;
      fclk_ddr_dly3 <= fclk_ddr_dly2;
   end

   wire fclk_posedge;
   posedge_detect FCLK_rising_edge (
     .rst (RST),
     .sig (pos_CMOS_FCLK & ~neg_CMOS_FCLK),
     .clk (DCLK),
     .pe (fclk_posedge)
     );

   always @(posedge DCLK) begin
      if (RST == 1) FCLK_pos <= 1'b0;
      else FCLK_pos <= FCLK_pos | fclk_posedge;
   end

   assign DRDY = ((FCLK_pos == 0)&& (data_rate == 0)) ? (fclk_ddr_dly1) :
                 ((FCLK_pos == 1) && (data_rate == 0)) ? (fclk_ddr_dly2) :
                 (data_rate == 1) ? (pos_CMOS_FCLK | neg_CMOS_FCLK) : 1'b0;

endmodule
