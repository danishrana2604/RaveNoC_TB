// axi_scoreboard.sv
// Simple scoreboard: store expected write data, compare against read data.

class axi_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(axi_scoreboard)

  // Analysis ports  connect from master BFM monitor (future)
  uvm_tlm_analysis_fifo #(axi_like_seq_item) wr_fifo;
  uvm_tlm_analysis_fifo #(axi_like_seq_item) rd_fifo;

  int unsigned pass_count = 0;
  int unsigned fail_count = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    wr_fifo = new("wr_fifo", this);
    rd_fifo = new("rd_fifo", this);
  endfunction

  // Call this directly from test for Phase 0 bringup (no analysis port needed yet)
  function void check_rdata(logic [31:0] expected, logic [31:0] got, string tag = "");
    if (expected === got) begin
      pass_count++;
      `uvm_info("SCOREBOARD", $sformatf("PASS %s exp=0x%08h got=0x%08h", tag, expected, got), UVM_LOW)
    end else begin
      fail_count++;
      `uvm_error("SCOREBOARD", $sformatf("FAIL %s exp=0x%08h got=0x%08h", tag, expected, got))
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("SCOREBOARD", $sformatf("Results: PASS=%0d  FAIL=%0d", pass_count, fail_count), UVM_NONE)
    if (fail_count > 0)
      `uvm_error("SCOREBOARD", "TEST FAILED")
    else
      `uvm_info("SCOREBOARD",  "TEST PASSED", UVM_NONE)
  endfunction
endclass
