// Deliberate violations are enabled only by plusarg; normal regression passes.
module tb_axis_negative;
  logic clk = 0, rst = 1, enable = 1;
  logic [63:0] tdata = 0;
  logic tvalid = 0, tready = 0, tlast = 0;
  string violation;
  always #5 clk = ~clk;
  axis_check #(.NAME("deliberate")) dut(.*);
  initial begin
    if (!$value$plusargs("violation=%s",violation)) begin
      $display("PASS"); $finish;
    end
    repeat (2) @(negedge clk);
    rst = 0; tvalid = 1;
    @(negedge clk);
    if (violation == "valid") tvalid = 0;
    else if (violation == "data") tdata = 1;
    else if (violation == "last") tlast = 1;
    else $fatal(1,"unknown violation");
    @(negedge clk);
    $fatal(1,"checker failed to reject violation");
  end
endmodule
