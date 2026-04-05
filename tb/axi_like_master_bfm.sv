class axi_like_master_bfm extends uvm_driver #(axi_like_seq_item);
  `uvm_component_utils(axi_like_master_bfm)
  virtual axi_like_if.master vif;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual axi_like_if)::get(this, "", "tx_vif", vif))
      `uvm_fatal("NO_VIF", "axi_like_master_bfm: tx_vif not found in config_db")
  endfunction

  task wait_sig(ref logic sig, input string name, input int timeout=1000);
    int cnt = 0;
    while (!sig) begin
      @(posedge vif.clk);
      if (++cnt > timeout)
        `uvm_fatal("TIMEOUT", $sformatf("%s never asserted after %0d cycles", name, timeout))
    end
  endtask

  task run_phase(uvm_phase phase);
    axi_like_seq_item req;
    vif.awvalid <= 0; vif.awid <= 0; vif.awaddr <= 0;
    vif.awlen <= 0; vif.awsize <= 3'b010; vif.awburst <= 2'b01;
    vif.awlock <= 0; vif.awcache <= 0; vif.awprot <= 0;
    vif.awqos <= 0; vif.awregion <= 0; vif.awuser <= 0;
    vif.wvalid <= 0; vif.wdata <= 0; vif.wstrb <= 4'hF; vif.wlast <= 0;
    vif.bready <= 1;
    vif.arvalid <= 0; vif.arid <= 0; vif.araddr <= 0;
    vif.arlen <= 0; vif.arsize <= 3'b010; vif.arburst <= 2'b01;
    vif.arlock <= 0; vif.arcache <= 0; vif.arprot <= 0;
    vif.arqos <= 0; vif.arregion <= 0; vif.aruser <= 0;
    vif.rready <= 0;
    forever begin
      seq_item_port.get_next_item(req);
      if (req.dir == axi_like_seq_item::AXI_WRITE)
        do_write(req);
      else
        do_read(req);
      seq_item_port.item_done();
    end
  endtask

  task do_write(axi_like_seq_item req);
    @(posedge vif.clk);
    vif.awvalid <= 1; vif.awaddr <= req.addr;
    vif.awid <= req.id; vif.awlen <= req.len;
    vif.awsize <= req.size; vif.awburst <= req.burst;
    vif.wvalid <= 1; vif.wdata <= req.data[0];
    vif.wstrb <= req.strb; vif.wlast <= 1;
    @(posedge vif.clk);
    `uvm_info("WRITE_DBG",$sformatf("t=%0t awready=%0b wready=%0b",$time,vif.awready,vif.wready),UVM_NONE)
    wait_sig(vif.awready, "awready");
    vif.awvalid <= 0;
    wait_sig(vif.wready, "wready");
    @(posedge vif.clk);
    vif.wvalid <= 0; vif.wlast <= 0;
    wait_sig(vif.bvalid, "bvalid");
    req.bresp = vif.bresp;
    `uvm_info("MASTER_BFM", $sformatf("WRITE done: %s", req.convert2string()), UVM_MEDIUM)
  endtask

  task do_read(axi_like_seq_item req);
    vif.rready <= 1;
    @(posedge vif.clk);
    vif.arvalid <= 1; vif.araddr <= req.addr;
    vif.arid <= req.id; vif.arlen <= req.len;
    vif.arsize <= req.size; vif.arburst <= req.burst;
    wait_sig(vif.arready, "arready");
    vif.arvalid <= 0;
    req.rdata = new[req.len + 1];
    for (int i = 0; i <= req.len; i++) begin
      wait_sig(vif.rvalid, "rvalid");
      @(posedge vif.clk);
      req.rdata[i] = vif.rdata;
    end
    vif.rready <= 0;
    `uvm_info("MASTER_BFM", $sformatf("READ done: %s rdata[0]=0x%08h",
      req.convert2string(), req.rdata[0]), UVM_MEDIUM)
  endtask
endclass
