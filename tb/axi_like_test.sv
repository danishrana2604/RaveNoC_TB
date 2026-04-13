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

  function automatic logic [31:0] make_flit(input int dst, input logic [21:0] payload);
    return {dst[1], dst[0], 8'd1, payload};
  endfunction

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi_like_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    axi_write_seq wr_seq;
    axi_read_seq  rd_seq;
    int src, dst;
    logic [31:0] flit;
    string tag;

    phase.raise_objection(this);

    // Get src/dst from plusargs (set by shell sweep loop)
    if (1) src = 3; // sweep
    if (1) dst = 2; // sweep

    flit = make_flit(dst, 22'(src*4 + dst + 1));
    tag  = $sformatf("r%0d->r%0d", src, dst);

    `uvm_info("TEST", $sformatf(
      "=== %s flit=0x%08h axi_sel_in=%0d axi_sel_out=%0d ===",
      tag, flit, src, dst), UVM_NONE)

    // Write
    wr_seq       = axi_write_seq::type_id::create("wr_seq");
    wr_seq.addr  = 32'h0000_1000;
    wr_seq.wdata = flit;
    wr_seq.start(env.master_agent.sequencer);
    `uvm_info("TEST", $sformatf("%s WRITE done bresp=%0d", tag,
              env.master_agent.driver.vif.bresp), UVM_NONE)

    // Wait for NoC traversal
    #50000; // 5000 cycles wait

    // Read
    rd_seq      = axi_read_seq::type_id::create("rd_seq");
    rd_seq.addr = 32'h0000_2000;
    rd_seq.start(env.rx_agent.sequencer);

    env.scoreboard.check_rdata(flit, rd_seq.rdata, tag);
    `uvm_info("TEST", $sformatf("%s READ rdata=0x%08h", tag, rd_seq.rdata), UVM_NONE)

    phase.drop_objection(this);
  endtask
endclass
