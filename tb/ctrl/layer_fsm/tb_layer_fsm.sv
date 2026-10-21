// tb_layer_fsm: unit bench for layer_fsm.
//
// DUT          rtl/ctrl/layer_fsm/layer_fsm.sv, RD_LAT = 2, FLUSH_LAT and SHIFT_LAT from mxu_pkg
// Neighbours   small models in the bench: nxt_valid rises a random time after each swap (and
//              before the first); can_take_tile toggles at random; last_sent pulses a random
//              time after the final shift burst. res_valid for the checker is shift_en
//              delayed SHIFT_LAT cycles.
// Monitor      records every read address, in_valid, shift burst, bias_sel per shift cycle,
//              rb_discard, rb_last and swap, as an event list.
// Reference    a schedule model: a plain nested loop over nt, mt, k that lists the events a
//              layer of that shape must produce, in order. Bias rule and exit rule from
//              docs/architecture.md, section 6.6.
// Assertions   mxu_check with the FSM as the driver. swap only when nxt_valid is high.
//              Exactly one discarded burst per layer. rb_last only during the final tile's
//              burst. in_valid high exactly K times per tile. Every read address below 8,192.
//              Watchdog: busy falls within a bounded time once the neighbours are ready.
// Must hit     every state and all 12 transitions; HOLD waiting for buffer space; HOLD
//              waiting for the next block; bias from CURRENT, NEXT and zero; the overflow error.
// Done when    every task below passes and the 12 transition cover counters are all nonzero.
// Spec         docs/verification.md, section 6.10. docs/architecture.md, section 6.6.
//
// Each test in the plan is a task below; the initial block runs them in order.
// Bench rules: docs/verification.md, section 2.

module tb_layer_fsm;
  import tb_pkg::*;

  localparam int RD_LAT    = 2;
  localparam int FLUSH_LAT = mxu_pkg::FLUSH_LAT;
  localparam int SHIFT_LAT = mxu_pkg::SHIFT_LAT;

  logic        clk = 1'b0;
  logic        rst;
  logic        start;
  logic [15:0] m_tiles;
  logic [10:0] k;
  logic [15:0] n_tiles;
  logic        nxt_valid;
  logic        can_take_tile;
  logic        last_sent;
  logic [12:0] ub_rd_addr;
  logic [9:0]  wb_rd_addr;
  logic        in_valid;
  logic        shift_en;
  logic [1:0]  bias_sel;
  logic [2:0]  shift_idx;
  logic        swap;
  logic        rb_discard;
  logic        rb_last;
  logic        busy;
  logic        done_set;
  logic        err_set;
  logic [7:0]  fsm_state;
  logic        ev_wait_wb;
  logic        ev_wait_out;
  logic        ev_tile;
  logic        res_valid_model;

  always #5 clk = ~clk;

  layer_fsm #(.RD_LAT(RD_LAT), .FLUSH_LAT(FLUSH_LAT), .SHIFT_LAT(SHIFT_LAT)) dut (.*);

  mxu_check #(.T(8), .FLUSH_LAT(FLUSH_LAT), .SHIFT_LAT(SHIFT_LAT)) u_chk (
    .clk, .rst, .enable(1'b1), .in_valid, .shift_en,
    .res_valid(res_valid_model), .res_row('0)
  );

  initial begin
    $display("SKIP: not implemented"); $finish;
    void'(get_seed());
    test_one_tile();
    test_loop_boundaries();
    test_k_extremes();
    test_late_block();
    test_no_space();
    test_overflow();
    test_two_layers();
    test_reset_midway();
    test_random();
    finish_pass();
  end

  // Helper, not a test. Runs one layer of the given shape with the neighbour models and
  // compares the monitor's event list with the schedule model's.
  task automatic run_layer(input int mt_n, input int k_n, input int nt_n);
  endtask

  // 1. M_T = 1, N_T = 1; fails if the event list differs from the schedule model or done_set does not pulse once.
  task automatic test_one_tile();
  endtask

  // 2. M_T = 3 with N_T = 1, then M_T = 1 with N_T = 3; fails on any event-list mismatch, including bias source at boundaries.
  task automatic test_loop_boundaries();
  endtask

  // 3. K = 1 and K = 1,024; fails on any event-list mismatch or in_valid count != K per tile.
  task automatic test_k_extremes();
  endtask

  // 4. Next block arrives 2,000 cycles late at a boundary; fails unless the FSM waits in HOLD (ev_wait_wb high) and then matches.
  task automatic test_late_block();
  endtask

  // 5. can_take_tile held low 1,000 cycles; fails unless the FSM waits (ev_wait_out high), loses nothing and then matches.
  task automatic test_no_space();
  endtask

  // 6. A shape with M_T * K > 8,192; fails unless err_set pulses.
  task automatic test_overflow();
  endtask

  // 7. Two layers back to back with no reset; fails unless both event lists match.
  task automatic test_two_layers();
  endtask

  // Rule 5. rst in the middle of a layer, then a clean layer; fails unless the FSM is in IDLE after rst and the clean layer matches.
  task automatic test_reset_midway();
  endtask

  // Random. 500 layers, M_T and N_T 1..8, K 1..64, random neighbour delays; fails on any event-list mismatch or assertion.
  task automatic test_random();
  endtask

endmodule
