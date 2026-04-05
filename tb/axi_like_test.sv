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
    phase.raise_objection(this);
    `uvm_info("TEST","Starting minimal test - no clock waits",UVM_NONE)
    phase.drop_objection(this);
  endtask
endclass
