// Parameterized source checks: hex truncation, 100% gap, rate and sink stall duration.
module tb_source_edges #(parameter int W = 64);
  import tb_pkg::*;
  logic clk = 0, rst = 1;
  logic [W-1:0] tdata;
  logic tvalid, tready, tlast;
  logic [W-1:0] data;
  logic last;
  int fd, cycle = 0, previous_transfer = -1;
  bit rate_check = 0;
  string path;
  always #5 clk = ~clk;
  axis_src #(.W(W)) src(.*);
  axis_sink #(.W(W)) sink(.*);
  axis_check #(.W(W)) checker_i(.enable(1'b1),.*);
  always @(posedge clk) begin
    cycle++;
    if (!rst && rate_check && tvalid && tready) begin
      if (previous_transfer >= 0 && cycle != previous_transfer+1)
        $fatal(1,"source inserted a bubble at gap 0");
      previous_transfer = cycle;
      cover_hit("back_to_back");
    end
  end
  initial begin
    #100000;
    $fatal(1,"source edge watchdog");
  end
  initial begin
    void'(get_seed());
    cover_declare("back_to_back");
    cover_declare("gap100");
    cover_declare("hex_truncation");
    cover_declare("stall_duration");
    cover_declare("reset_pending");
    repeat (3) @(negedge clk);
    rst = 0;
    repeat (3) @(negedge clk);
    src.set_gap_pct(100);
    src.push('1,0);
    repeat (20) @(negedge clk);
    check("gap100 valid",vec_t'(tvalid),0);
    check("gap100 count",vec_t'(sink.num_words()),0);
    cover_hit("gap100");
    src.clear();
    path = $sformatf("build/source_edges_%0d.hex",W);
    fd = $fopen(path,"w");
    if (fd == 0) $fatal(1,"cannot create fixture");
    $fdisplay(fd,"%070h",280'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    $fwrite(fd,"0"); // Final line without newline.
    $fclose(fd);
    src.load_hex(path);
    src.push('1,1);
    src.set_gap_pct(0);
    rate_check = 1;
    src.wait_empty();
    rate_check = 0;
    sink.wait_words(3);
    for (int i=0;i<3;i++) begin
      sink.get(i,data,last);
      check("hex low W",vec_t'(data),i == 1 ? vec_t'(0) : vec_t'({W{1'b1}}));
      check("last boundaries",vec_t'(last),vec_t'(i != 0));
    end
    cover_hit("hex_truncation");
    @(negedge clk);
    sink.stall(5);
    // tready is registered: the next five rising edges schedule it low.
    repeat (5) begin
      @(negedge clk);
      check("stall low",vec_t'(tready),0);
    end
    @(negedge clk);
    check("stall released",vec_t'(tready),1);
    cover_hit("stall_duration");
    sink.set_ready_pct(0);
    repeat (3) @(negedge clk);
    sink.clear();
    src.push('0,0);
    src.push('1,1);
    repeat (3) @(negedge clk);
    rst = 1;
    repeat (2) @(negedge clk);
    check("reset offer",vec_t'(tvalid),0);
    rst = 0;
    sink.set_ready_pct(100);
    src.wait_empty();
    sink.wait_words(1);
    check("pending count",vec_t'(sink.num_words()),1);
    sink.get(0,data,last);
    check("pending data",vec_t'(data),vec_t'({W{1'b1}}));
    check("pending last",vec_t'(last),1);
    cover_hit("reset_pending");
    finish_pass();
  end
endmodule
