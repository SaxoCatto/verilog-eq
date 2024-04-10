`timescale 1 ns / 1 ns

module filter (
    input clk,
    input clk_enable,
    input rst,

    input signed [15:0] filter_in,      // signed integer 16 bit. [-32768, 32768 - 1]
    input               write_enable,
    input               write_done,
    input        [ 5:0] write_address,  // unsigned integer 6 bit. [0, 64 - 1]
    input signed [15:0] coeffs_in,      // signed fixed-point 16 bit, 18 frac. [-0.125, 0.125 - 3.814697265625e-06]

    output signed [15:0] filter_out  // signed integer 16 bit. [-32768, 32768 - 1]
);
  // region counter
  wire [5:0] current_count;  // from counter's current_count

  counter counter_inst (
      .clk(clk),
      .clk_enable(clk_enable),
      .rst(rst),

      .current_count(current_count)
  );

  // endregion counter

  // region phase_check
  wire phase_63, phase_0, control_phase_bar; // from phase_check's phase_63, phase_0, control_phase_bar

  phase_check phase_check_inst (
      .clk_enable(clk_enable),

      .current_count(current_count),

      .phase_63(phase_63),
      .phase_0(phase_0),
      .control_phase_bar(control_phase_bar)
  );

  // endregion phase_check

  // region delay_pipeline
  wire signed [15:0] input_mux;

  delay_pipeline delay_pipeline_inst (
      .clk(clk),
      .rst(rst),
      .current_count(current_count),

      .phase_63 (phase_63),
      .filter_in(filter_in),

      .input_mux(input_mux)
  );

  // endregion delay_pipeline

  // region input_register
  wire w_write_enable;
  wire w_write_done;
  wire [5:0] w_write_address;
  wire [15:0] w_coeffs_in; // from input_register's o_write_enable, o_write_done, o_write_address, o_coeffs_in

  input_register input_register_inst (
      .clk(clk),
      .rst(rst),
      .clk_enable(clk_enable),

      .i_write_enable(write_enable),
      .i_write_done(write_done),
      .i_write_address(write_address),
      .i_coeffs_in(coeffs_in),

      .o_write_enable(w_write_enable),
      .o_write_done(w_write_done),
      .o_write_address(w_write_address),
      .o_coeffs_in(w_coeffs_in)
  );

  // endregion input_register

  // region write_done_capture
  wire o_write_done_capture, o_write_done_edge, coeffs_en;  //write_done_capture's o_write_done_capture, o_write_done_edge, coeffs_en
  write_done_capture write_done_capture_inst (
      .clk(clk),
      .rst(rst),
      .clk_enable(clk_enable),

      .i_write_done(w_write_done),
      .i_control_phase_bar(control_phase_bar),
      .phase_63(phase_63),

      .o_write_done_capture(o_write_done_capture),
      .o_write_done_edge(o_write_done_edge),
      .coeffs_en(coeffs_en)
  );

  // endregion write_done_capture

  // region coeffs_control
  wire signed [15:0] product_mux;

  coeffs_control coeffs_control_inst (
      .clk(clk),
      .rst(rst),
      .clk_enable(clk_enable),

      .current_count(current_count),  // current_count from counter

      .coeffs_en(coeffs_en),  // coeffs_en from write_done_capture

      .write_address(w_write_address),  // o_write_address from input_register
      .coeffs_in    (w_coeffs_in),      // o_coeffs_in from input_register
      .write_enable (w_write_enable),   // o_write_enable from input_register

      .product_mux(product_mux)
  );

  // endregion coeffs_control

  // region compute
  compute compute_inst (
      .clk(clk),
      .rst(rst),
      .clk_enable(clk_enable),

      .input_mux(input_mux),

      .product_mux(product_mux),

      .phase_0 (phase_0),
      .phase_63(phase_63),

      .filter_out(filter_out)
  );

  // endregion

endmodule  //filter
