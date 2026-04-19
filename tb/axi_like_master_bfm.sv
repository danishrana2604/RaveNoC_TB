class axi_like_master_bfm extends uvm_driver #(axi_like_seq_item);
  `uvm_component_utils(axi_like_master_bfm)
  virtual axi_like_if.master vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_like_if)::get(this,"","tx_vif",vif))
      `uvm_fatal("NO_VIF","axi_like_master_bfm: tx_vif not found")
  endfunction

  task run_phase(uvm_phase phase);
    axi_like_seq_item req;
    vif.awvalid = 0; vif.awid = 0; vif.awaddr = 0;
    vif.awlen   = 0; vif.awsize = 3'b010; vif.awburst = 2'b01;
    vif.awlock  = 0; vif.awcache = 0; vif.awprot = 0;
    vif.awqos   = 0; vif.awregion = 0; vif.awuser = 0;
    vif.wvalid  = 0; vif.wdata = 0; vif.wstrb = 4'hF; vif.wlast = 0;
    vif.bready  = 1;
    vif.arvalid = 0; vif.arid = 0; vif.araddr = 0;
    vif.arlen   = 0; vif.arsize = 3'b010; vif.arburst = 2'b01;
    vif.arlock  = 0; vif.arcache = 0; vif.arprot = 0;
    vif.arqos   = 0; vif.arregion = 0; vif.aruser = 0;
    vif.rready  = 0;
    @(posedge vif.rst_n);
    `uvm_info("BFM","Reset released, BFM ready",UVM_NONE)
    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info("BFM",$sformatf("Got item dir=%s",req.dir.name()),UVM_NONE)
      if (req.dir == axi_like_seq_item::AXI_WRITE)
        do_write(req);
      else
        do_read(req);
      seq_item_port.item_done();
    end
  endtask

  task do_write(axi_like_seq_item req);
    // Wait rising edge then drive with BLOCKING assignments
    @(posedge vif.clk);
    vif.awvalid = 1;
    `uvm_info("BFM",$sformatf("t=%0t awvalid HIGH addr=0x%08h wdata=0x%08h",$time,req.addr,req.data[0]),UVM_NONE)
    vif.awaddr  = req.addr;
    vif.awid    = req.id;
    vif.awlen   = req.len;
    vif.awsize  = req.size;
    vif.awburst = req.burst;
    vif.wvalid  = 1;
    vif.wdata   = req.data[0];
    $display("[BFM] t=%0t wvalid driven HIGH wdata=0x%08h wlast=%0b", $time, vif.wdata, vif.wlast);
    vif.wstrb   = req.strb;
    vif.wlast   = 1;
    `uvm_info("WRITE_DBG",$sformatf(
      "t=%0t driving: awvalid=1 awaddr=0x%08h awsize=%0d awburst=%0d wdata=0x%08h",
      $time, vif.awaddr, vif.awsize, vif.awburst, vif.wdata), UVM_NONE)

    // Wait AW handshake
    @(posedge vif.clk iff vif.awready);
    `uvm_info("WRITE_DBG",$sformatf(
      "t=%0t AW accepted: awsize=%0d awburst=%0d",
      $time, vif.awsize, vif.awburst), UVM_NONE)
    vif.awvalid = 0;
    $display("[BFM] t=%0t awvalid driven LOW (AW handshake done)", $time);

    // Wait W handshake � hold wvalid ONE extra cycle after wready
    @(posedge vif.clk iff vif.wready);
    `uvm_info("WRITE_DBG",$sformatf("t=%0t W accepted, holding +1 cycle",$time),UVM_NONE)
    @(posedge vif.clk);
    vif.wvalid = 0;
    $display("[BFM] t=%0t wvalid driven LOW (+1 cycle hold done)", $time);
    vif.wlast  = 0;

    // Wait B response
    @(posedge vif.clk iff vif.bvalid);
    req.bresp = vif.bresp;
    `uvm_info("MASTER_BFM",$sformatf(
      "WRITE done: addr=0x%08h data=0x%08h bresp=%0d",
      req.addr, req.data[0], req.bresp), UVM_MEDIUM)
  endtask

  task do_read(axi_like_seq_item req);
    vif.rready = 1;
    @(posedge vif.clk);
    vif.arvalid = 1;
    `uvm_info("BFM",$sformatf("t=%0t arvalid HIGH addr=0x%08h",$time,req.addr),UVM_NONE)
    vif.araddr  = req.addr;
    vif.arid    = req.id;
    vif.arlen   = req.len;
    vif.arsize  = req.size;
    vif.arburst = req.burst;
    `uvm_info("READ_DBG",$sformatf("t=%0t driving AR addr=0x%08h",$time,req.addr),UVM_NONE)

    @(posedge vif.clk iff vif.arready);
    vif.arvalid = 0;
    $display("[BFM] t=%0t arvalid driven LOW (AR handshake done)", $time);
    `uvm_info("READ_DBG",$sformatf("t=%0t AR accepted",$time),UVM_NONE)

    req.rdata = new[req.len + 1];
    for (int i = 0; i <= req.len; i++) begin
      @(posedge vif.clk iff vif.rvalid);
      @(posedge vif.clk); // extra cycle for always_ff rdata delay
      req.rdata[i] = vif.rdata;
      `uvm_info("READ_DBG",$sformatf("t=%0t rdata[%0d]=0x%08h rlast=%0b",
                $time, i, vif.rdata, vif.rlast), UVM_NONE)
    end
    vif.rready = 0;
    `uvm_info("MASTER_BFM",$sformatf(
      "READ done: addr=0x%08h rdata[0]=0x%08h",
      req.addr, req.rdata[0]), UVM_MEDIUM)
  endtask

endclass
