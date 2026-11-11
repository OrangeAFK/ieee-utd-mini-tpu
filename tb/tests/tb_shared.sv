// Shared utility and stream regression. Run with +negative=<case> for expected failures.
module tb_shared;
  import tb_pkg::*;
  logic clk = 0, rst = 1;
  logic [63:0] tdata;
  logic tvalid, tready, tlast;
  string negative;
  vec_t values[$];
  logic [63:0] data;
  logic last;
  int fd;
  always #5 clk = ~clk;
  axis_src src(.*);
  axis_sink sink(.*);
  axis_check #(.NAME("loopback")) checker_i(.enable(1'b1), .*);
  initial begin
    #2000000;
    $fatal(1, "tb_shared watchdog");
  end
  initial begin
    void'(get_seed());
    if ($value$plusargs("negative=%s", negative)) begin
      if (negative == "compare") check("intentional", 1, 2);
      else if (negative == "cover_typo") cover_hit("typo");
      else if (negative == "cover_duplicate") begin
        cover_declare("duplicate"); cover_declare("duplicate");
      end
      else if (negative == "gap_range") src.set_gap_pct(101);
      else if (negative == "ready_range") sink.set_ready_pct(-1);
      else if (negative == "sink_index") sink.get(0,data,last);
      else if (negative == "zero_width") check_known("invalid",0,0);
      else if (negative == "cover_miss") begin cover_declare("miss"); finish_pass(); end
      else if (negative == "width") check_known("invalid", 0, 281);
      else if (negative == "missing") load_hex("build/no-such-file.hex", values);
      else if (negative == "empty" || negative == "malformed" ||
               negative == "extra_token" || negative == "overwide") begin
        fd = $fopen("build/shared_negative.hex", "w");
        if (negative == "malformed") $fdisplay(fd, "12xx");
        if (negative == "extra_token") $fdisplay(fd,"12 34");
        if (negative == "overwide") $fdisplay(fd,"1%070h",280'(0));
        $fclose(fd);
        load_hex("build/shared_negative.hex", values);
      end else $fatal(1, "unknown negative case");
      $fatal(1, "expected rejection did not occur");
    end
    cover_declare("gap0");
    cover_declare("gap30");
    cover_declare("gap90");
    cover_declare("reset");
    cover_declare("clear_stalled");
    check("equal", 280'h123, 280'h123);
    check_known("known", 280'h123, VW);
    check("seed_cached", vec_t'(get_seed()), vec_t'(get_seed()));
    fd = $fopen("build/shared_input.hex", "w");
    $fdisplay(fd, "0123456789abcdef");
    $fdisplay(fd, "fedcba9876543210");
    $fclose(fd);
    load_hex("build/shared_input.hex", values);
    check("hex_count", vec_t'(values.size()), 2);
    check("hex_first", values[0], 280'h0123456789abcdef);
    check("hex_last", values[1], 280'hfedcba9876543210);
    repeat (3) @(negedge clk);
    rst = 0;
    src.load_hex("build/shared_input.hex");
    src.wait_empty();
    sink.wait_words(2);
    for (int i = 0; i < 2; i++) begin
      sink.get(i, data, last);
      check("file_data", vec_t'(data), values[i]);
      check("file_last", vec_t'(last), vec_t'(i == 1));
    end
    for (int profile = 0; profile < 3; profile++) begin
      @(negedge clk);
      sink.clear();
      src.set_gap_pct(profile == 0 ? 0 : (profile == 1 ? 30 : 90));
      sink.set_ready_pct(profile == 0 ? 100 : 35);
      for (int i = 0; i < 1000; i++) src.push(64'(i), i == 999);
      src.wait_empty();
      sink.wait_words(1000);
      for (int i = 0; i < 1000; i++) begin
        sink.get(i, data, last);
        check("stream_order", vec_t'(data), vec_t'(i));
        check("stream_last", vec_t'(last), vec_t'(i == 999));
      end
      check("first_last", vec_t'(sink.last_index()), 999);
      case (profile)
        0: cover_hit("gap0");
        1: cover_hit("gap30");
        2: cover_hit("gap90");
      endcase
    end
    // Clear may discard queued words, but must not withdraw a stalled offer.
    @(negedge clk);
    sink.clear();
    sink.set_ready_pct(0);
    src.set_gap_pct(0);
    repeat (3) @(negedge clk);
    src.push(64'h55, 1);
    src.push(64'h66, 0);
    repeat (3) @(negedge clk);
    check("offered", vec_t'(tvalid), 1);
    src.clear();
    repeat (3) @(negedge clk);
    check("held_after_clear", vec_t'(tdata), 280'h55);
    sink.set_ready_pct(100);
    src.wait_empty();
    sink.wait_words(1);
    check("clear_count", vec_t'(sink.num_words()), 1);
    cover_hit("clear_stalled");
    // Reset discards the active offer and retains words still in the source queue.
    @(negedge clk);
    sink.clear();
    sink.set_ready_pct(0);
    repeat (3) @(negedge clk);
    src.push(64'h77, 0);
    src.push(64'h88, 1);
    repeat (3) @(negedge clk);
    rst = 1;
    repeat (2) @(negedge clk);
    check("reset_valid", vec_t'(tvalid), 0);
    rst = 0;
    sink.set_ready_pct(100);
    src.wait_empty();
    sink.wait_words(1);
    sink.get(0, data, last);
    check("reset_pending", vec_t'(data), 280'h88);
    check("reset_last", vec_t'(last), 1);
    cover_hit("reset");
    finish_pass();
  end
endmodule
