// tb_wb_pair: unit bench for wb_pair.
//
// DUT          rtl/ctrl/wb_pair/wb_pair.sv, AW = 10
// Reference    two plain arrays of 1,024 x 64 bits in the bench, one per half. Writes go to
//              half ~active; every read of half active is checked exactly RD_LAT cycles later.
// Assertions   rdata is not X, RD_LAT cycles after reading an address written in the active
//              half. The bench only flips active when no read is in flight.
// Must hit     addresses 0 and 1,023 in both halves; a write and a read in the same cycle; a
//              flip of active followed at once by a read.
// Done when    every task below passes and synthesized alone wb_pair shows 4 RAMB36E1.
// Spec         docs/verification.md, section 6.5. docs/architecture.md, section 6.5.
//
// Each test in the plan is a task below; the initial block runs them in order.
// Bench rules: docs/verification.md, section 2.

module tb_wb_pair;
  import tb_pkg::*;

  localparam int AW     = 10;
  localparam int RD_LAT = 2;

  logic          clk = 1'b0;
  logic          rst;
  logic          we;
  logic [AW-1:0] waddr;
  logic [63:0]   wdata;
  logic          active;
  logic [AW-1:0] raddr;
  logic [63:0]   rdata;

  always #5 clk = ~clk;

  wb_pair #(.AW(AW)) dut (.*);

  initial begin
    $display("SKIP: not implemented"); $finish;
    void'(get_seed());
    test_fill_flip_read();
    test_write_idle_while_reading();
    test_read_latency();
    test_both_halves();
    test_reset_midway();
    test_random();
    finish_pass();
  end

  // 1. Fill the idle half, flip active, read every word in order; fails on any mismatch at RD_LAT.
  task automatic test_fill_flip_read();
  endtask

  // 2. Read the active half while writing a different pattern to the idle half; fails if any read returns the new pattern.
  task automatic test_write_idle_while_reading();
  endtask

  // 3. A new raddr every cycle; fails unless each word arrives exactly RD_LAT cycles after its address.
  task automatic test_read_latency();
  endtask

  // 4. Distinct patterns into both halves across two flips, then read both back; fails on any mismatch.
  task automatic test_both_halves();
  endtask

  // Rule 5. rst during writes, then a clean fill and read; fails unless the clean data reads back exactly.
  task automatic test_reset_midway();
  endtask

  // Random. 50,000 cycles: random idle-half writes, random raddr every cycle, random safe flips; fails on any mismatch.
  task automatic test_random();
  endtask

endmodule
