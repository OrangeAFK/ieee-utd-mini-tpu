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

  int unsigned cover_counts[string];
  bit seeded = 0;
  int unsigned seed_value = 1;

  function automatic int unsigned get_seed();
    int unsigned seed_arg;
    if (!seeded) begin
      if ($value$plusargs("seed=%d", seed_value)) begin end
      seed_arg = seed_value;
      void'($urandom(seed_arg));
      $display("seed = %0d", seed_value);
      seeded = 1;
    end
    return seed_value;
  endfunction

  function automatic void check(input string tag, input vec_t got, input vec_t exp);
    if (got !== exp)
      $fatal(1, "%s: got %h expected %h", tag, got, exp);
  endfunction

  function automatic void check_known(input string tag, input vec_t val, input int width);
    if (width < 1 || width > VW) $fatal(1, "%s: invalid width %0d", tag, width);
    for (int i = 0; i < width; i++)
      if ($isunknown(val[i])) $fatal(1, "%s: X/Z at bit %0d", tag, i);
  endfunction

  task automatic load_hex(input string path, output vec_t vals[$]);
    int fd, line_no, scanned;
    string line, token, extra;
    vec_t value;
    vals.delete();
    fd = $fopen(path, "r");
    if (fd == 0) $fatal(1, "load_hex: cannot open %s", path);
    line_no = 0;
    while ($fgets(line, fd) != 0) begin
      line_no++;
      scanned = $sscanf(line, "%s %s", token, extra);
      if (scanned < 1) continue;
      if (scanned != 1 || token.len() > VW/4) begin
        $fclose(fd);
        $fatal(1, "load_hex: invalid line %s:%0d", path, line_no);
      end
      for (int i = 0; i < token.len(); i++) begin
        if (!((token[i] >= "0" && token[i] <= "9") ||
              (token[i] >= "a" && token[i] <= "f") ||
              (token[i] >= "A" && token[i] <= "F"))) begin
          $fclose(fd);
          $fatal(1, "load_hex: invalid hex %s:%0d", path, line_no);
        end
      end
      value = '0;
      if ($sscanf(token, "%h", value) != 1) $fatal(1, "load_hex: parse %s", path);
      vals.push_back(value);
    end
    $fclose(fd);
    if (vals.size() == 0) $fatal(1, "load_hex: empty file %s", path);
  endtask

  function automatic void cover_declare(input string name);
    if (cover_counts.exists(name) != 0) $fatal(1, "duplicate cover: %s", name);
    cover_counts[name] = 0;
  endfunction

  function automatic void cover_hit(input string name);
    if (cover_counts.exists(name) == 0) $fatal(1, "undeclared cover: %s", name);
    cover_counts[name]++;
  endfunction

  task automatic finish_pass();
    bit missed;
    missed = 0;
    foreach (cover_counts[name]) begin
      $display("cover %s = %0d", name, cover_counts[name]);
      if (cover_counts[name] == 0) missed = 1;
    end
    if (missed) $fatal(1, "required coverage missing");
    $display("PASS");
    $finish;
  endtask

endpackage
