// axi_like_agent.sv
// Wraps the master BFM with a sequencer. One agent per AXI port.

class axi_like_agent extends uvm_agent;
  `uvm_component_utils(axi_like_agent)

  uvm_sequencer #(axi_like_seq_item) sequencer;
  axi_like_master_bfm                driver;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sequencer = uvm_sequencer #(axi_like_seq_item)::type_id::create("sequencer", this);
    driver    = axi_like_master_bfm::type_id::create("driver", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction
endclass
