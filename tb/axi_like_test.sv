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
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi_like_env::type_id::create("env",this);
  endfunction
  task run_phase(uvm_phase phase);
    axi_write_seq wr_seq;
    axi_read_seq  rd_seq;
    phase.raise_objection(this);
    `uvm_info("TEST","objection raised",UVM_NONE)
    #1;

    // Write head flit to TX router [0][0]
    wr_seq       = axi_write_seq::type_id::create("wr_seq");
    wr_seq.addr  = 32'h0000_1000;
    wr_seq.wdata = 32'hC040_0001;
    wr_seq.start(env.master_agent.sequencer);
    `uvm_info("TEST",$sformatf("Write done at %0t bresp=%0d",$time,
              env.master_agent.driver.vif.bresp),UVM_NONE)

    // Option A: start read IMMEDIATELY � no wait
    // AR will be in flight before packet arrives at router [1][1]
    // rready=0 until do_read enables it, so NI cannot drain buffer
    rd_seq      = axi_read_seq::type_id::create("rd_seq");
    rd_seq.addr = 32'h0000_2000;
    // Wait 500 cycles for NoC traversal
    #5000;
    // Wait 500 cycles for NoC traversal
    #5000;
    rd_seq.start(env.rx_agent.sequencer);
    `uvm_info("TEST",$sformatf("Read done rdata=0x%08h at %0t",
              rd_seq.rdata,$time),UVM_NONE)

    env.scoreboard.check_rdata(32'hC040_0001, rd_seq.rdata, "VC0_loopback");
    phase.drop_objection(this);
  endtask
endclass
