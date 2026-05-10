class axi_write_seq extends uvm_sequence #(axi_like_seq_item);
  `uvm_object_utils(axi_write_seq)
  rand logic [31:0] addr;
  rand logic [31:0] wdata;
  function new(string name="axi_write_seq"); super.new(name); endfunction
  task body();
    axi_like_seq_item item = axi_like_seq_item::type_id::create("item");
    item.dir=axi_like_seq_item::AXI_WRITE; item.addr=addr; item.len=0;
    item.data=new[1]; item.data[0]=wdata;
    start_item(item); finish_item(item);
  endtask
endclass

class axi_read_seq extends uvm_sequence #(axi_like_seq_item);
  `uvm_object_utils(axi_read_seq)
  rand logic [31:0] addr;
  logic [31:0] rdata;
  function new(string name="axi_read_seq"); super.new(name); endfunction
  task body();
    axi_like_seq_item item = axi_like_seq_item::type_id::create("item");
    item.dir=axi_like_seq_item::AXI_READ; item.addr=addr; item.len=0;
    item.rdata=new[1]; start_item(item); finish_item(item);
    rdata=item.rdata[0];
  endtask
endclass

class axi_like_test extends uvm_test;
  `uvm_component_utils(axi_like_test)
  axi_like_env env;

  // VC address map
  // VC0: wr=0x1000 rd=0x2000
  // VC1: wr=0x1008 rd=0x2008
  // VC2: wr=0x1010 rd=0x2010
  localparam logic [31:0] WR_ADDR [3] = '{
    32'h0000_1000,   // VC0
    32'h0000_1008,   // VC1
    32'h0000_1010    // VC2
  };
  localparam logic [31:0] RD_ADDR [3] = '{
    32'h0000_2000,   // VC0
    32'h0000_2008,   // VC1
    32'h0000_2010    // VC2
  };

  function automatic logic [31:0] make_flit(
    input int dst,
    input logic [21:0] payload
  );
    return {dst[1], dst[0], 8'd1, payload};
  endfunction

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi_like_env::type_id::create("env", this);
  endfunction

  // Run one write+read on a specific VC
  task run_vc_txn(
    input int src,
    input int dst,
    input int vc,
    input logic [21:0] payload
  );
    axi_write_seq wr_seq;
    axi_read_seq  rd_seq;
    logic [31:0]  flit;
    string        tag;

    flit = make_flit(dst, payload);
    tag  = $sformatf("r%0d->r%0d VC%0d", src, dst, vc);

    `uvm_info("TEST", $sformatf(
      "=== %s wr_addr=0x%08h rd_addr=0x%08h flit=0x%08h ===",
      tag, WR_ADDR[vc], RD_ADDR[vc], flit), UVM_NONE)

    // Write to VC-specific TX buffer
    wr_seq       = axi_write_seq::type_id::create("wr_seq");
    wr_seq.addr  = WR_ADDR[vc];
    wr_seq.wdata = flit;
    wr_seq.start(env.master_agent.sequencer);
    `uvm_info("TEST", $sformatf("%s WRITE done bresp=%0d",
              tag, env.master_agent.driver.vif.bresp), UVM_NONE)

    // Wait for NoC traversal
    #50000;

    // Read from VC-specific RX buffer
    rd_seq      = axi_read_seq::type_id::create("rd_seq");
    rd_seq.addr = RD_ADDR[vc];
    rd_seq.start(env.rx_agent.sequencer);

    env.scoreboard.check_rdata(flit, rd_seq.rdata, tag);
    `uvm_info("TEST", $sformatf("%s READ rdata=0x%08h",
              tag, rd_seq.rdata), UVM_NONE)

    #10000; // gap between transactions
  endtask

  task run_phase(uvm_phase phase);
    int src, dst;
    phase.raise_objection(this);

    if (1) src = 0; // sweep
    if (1) dst = 3; // sweep

    `uvm_info("TEST","=== MULTI-ADDRESS VC TEST START ===", UVM_NONE)

    // Test all 3 VCs sequentially
    run_vc_txn(src, dst, 0, 22'd1);  // VC0: addr 0x1000/0x2000
    run_vc_txn(src, dst, 1, 22'd2);  // VC1: addr 0x1008/0x2008
    run_vc_txn(src, dst, 2, 22'd3);  // VC2: addr 0x1010/0x2010

    `uvm_info("TEST","=== MULTI-ADDRESS VC TEST DONE ===", UVM_NONE)
    phase.drop_objection(this);
  endtask
endclass
