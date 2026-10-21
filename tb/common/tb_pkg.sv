// tb_pkg: bench utilities shared by every testbench.
// Seed handling, hex loading, compare-and-report, and cover counters, so each bench follows
// the rules in docs/verification.md section 2 the same way.
//
// Ports
//   none. It is a package; it provides:
//   name           kind      signature                                   meaning
//   VW             param     int, 280                                    widest value any bench compares
//   vec_t          type      logic [VW-1:0]                              value type for check and load_hex
//   get_seed       function  int unsigned get_seed()                     seed from +seed=N, else a fixed default
//   check          function  void check(string tag, vec_t got, vec_t exp)    compare, report, fail on mismatch
//   check_known    function  void check_known(string tag, vec_t val, int width)  fail if any of the low width bits is X or Z
//   load_hex       task      load_hex(string path, output vec_t vals[$])  read a .hex file into a queue
//   cover_declare  function  void cover_declare(string name)             register a must-hit counter at 0
//   cover_hit      function  void cover_hit(string name)                 add one to a counter
//   finish_pass    task      finish_pass()                               check covers, print PASS, end
//
// Behaviour
//   1. get_seed: read +seed=N with $value$plusargs. Without it use 1. Print
//      "seed = N" and seed the bench's random numbers with it (void'($urandom(N))), so
//      every run can be replayed.
//   2. check: if got !== exp, print tag, got and exp in hex and call $fatal. Otherwise
//      silent. Compare with !==, so X never matches a known value.
//   3. check_known: if $isunknown on the low width bits of val, print tag and call $fatal.
//   4. load_hex: open path with $fopen, read one hex value per line with $fscanf("%h"),
//      push each onto vals, close. $fatal if the file does not open or holds no lines.
//      Format: one value per line, most significant digit first, no prefix
//      (docs/verification.md, section 5).
//   5. cover_declare / cover_hit: keep an associative array of counters keyed by name.
//      cover_hit on an undeclared name calls $fatal, which catches typos.
//   6. finish_pass: print every counter. If any declared counter is still 0, print its name
//      and call $fatal. Otherwise print "PASS" on its own line and call $finish.
//
// Timing
//   No clocks; plain functions and tasks. Nothing here consumes simulation time.
//
// Resource target
//   simulation only
//
// Done when
//   tb/ctrl/out_fifo/tb_out_fifo.sv passes using it, and Verilator and the Vivado simulator
//   both compile it.
//
// Spec
//   docs/verification.md, sections 2 and 4.

package tb_pkg;

  localparam int VW = 280;
  typedef logic [VW-1:0] vec_t;

  function automatic int unsigned get_seed();
  endfunction

  function automatic void check(input string tag, input vec_t got, input vec_t exp);
  endfunction

  function automatic void check_known(input string tag, input vec_t val, input int width);
  endfunction

  task automatic load_hex(input string path, output vec_t vals[$]);
  endtask

  function automatic void cover_declare(input string name);
  endfunction

  function automatic void cover_hit(input string name);
  endfunction

  task automatic finish_pass();
  endtask

endpackage
