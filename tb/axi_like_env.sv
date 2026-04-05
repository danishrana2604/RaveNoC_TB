class axi_like_env extends uvm_env;
  `uvm_component_utils(axi_like_env)
  axi_like_agent     master_agent;   // drives noc_in_* (TX router [0][0])
  axi_like_agent     rx_agent;       // drives noc_out_* (RX router [1][1])
  axi_scoreboard     scoreboard;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    master_agent = axi_like_agent::type_id::create("master_agent", this);
    rx_agent     = axi_like_agent::type_id::create("rx_agent",     this);
    scoreboard   = axi_scoreboard::type_id::create("scoreboard",   this);
  endfunction
endclass
