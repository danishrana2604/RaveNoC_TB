module tb_top;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import ravenoc_pkg::*;
  import amba_axi_pkg::*;
  import tb_pkg::*;

  logic clk = 0;
  logic [1:0] axi_sel_in  = 2'd3;
  logic [1:0] axi_sel_out = 2'd2;
  logic rst_n = 0;
  initial forever #5 clk = ~clk;
  initial begin
    tx_if.awvalid = 0; tx_if.wvalid = 0; tx_if.arvalid = 0;
    // Pulse rst to generate posedge arst for async reset
    rst_n = 1; #2; rst_n = 0;
    rx_if.awvalid = 0; rx_if.wvalid = 0; rx_if.arvalid = 0;
    tx_if.bready = 1; rx_if.bready = 1;
    tx_if.rready = 0; rx_if.rready = 0;
    #10000; rst_n = 1;
  end

  axi_like_if tx_if(.clk(clk), .rst_n(rst_n));
  axi_like_if rx_if(.clk(clk), .rst_n(rst_n));

  // Initialize rx_if inputs to 0 to prevent spurious reads
  initial begin
    rx_if.arvalid = 0; rx_if.araddr = 0; rx_if.arlen = 0;
    rx_if.arsize = 3'b010; rx_if.arburst = 2'b01;
    rx_if.arid = 0; rx_if.rready = 0;
    rx_if.awvalid = 0; rx_if.awaddr = 0; rx_if.awlen = 0;
    rx_if.awsize = 3'b010; rx_if.awburst = 2'b01;
    rx_if.awid = 0;
    rx_if.wvalid = 0; rx_if.wdata = 0; rx_if.wstrb = 4'hF;
    rx_if.wlast = 0; rx_if.bready = 1;
  end

  // Intermediate wires for DUT outputs � breaks virtual interface ico loop
  logic        tx_awready_w, tx_wready_w, tx_bvalid_w, tx_arready_w;
  logic        tx_bid_w, tx_rvalid_w, tx_rlast_w, tx_rid_w;
  logic [1:0]  tx_bresp_w, tx_buser_w, tx_rresp_w, tx_ruser_w;
  logic [31:0] tx_rdata_w;

  logic        rx_awready_w, rx_wready_w, rx_bvalid_w, rx_arready_w;
  logic        rx_bid_w, rx_rvalid_w, rx_rlast_w, rx_rid_w;
  logic [1:0]  rx_bresp_w, rx_buser_w, rx_rresp_w, rx_ruser_w;
  logic [31:0] rx_rdata_w;
  logic rx_ar_gate = 0;
  logic rx_rready_ctrl;
  logic rx_arvalid_ctrl = 0;
  logic rx_rready_ctrl2 = 0;
  logic [15:0] rx_gate_cnt = 0;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_ar_gate <= 0;
      rx_gate_cnt <= 0;
      rx_rready_ctrl <= 0;
    end else begin
      rx_rready_ctrl <= rx_if.rready;
      rx_arvalid_ctrl <= rx_if.arvalid;
      rx_rready_ctrl2 <= rx_if.rready;
      if (rx_gate_cnt < 16'hFFFF) rx_gate_cnt <= rx_gate_cnt + 1;
      if (rx_gate_cnt > 16'h0100) rx_ar_gate <= 1;
    end
  end

  always_ff @(posedge clk) begin
    tx_if.awready <= tx_awready_w;
    tx_if.wready  <= tx_wready_w;
    tx_if.bvalid  <= tx_bvalid_w;
    tx_if.bresp   <= tx_bresp_w;
    tx_if.buser   <= tx_buser_w;
    tx_if.bid     <= tx_bid_w;
    tx_if.arready <= tx_arready_w;
    tx_if.rvalid  <= tx_rvalid_w;
    tx_if.rdata   <= tx_rdata_w;
    tx_if.rresp   <= tx_rresp_w;
    tx_if.rlast   <= tx_rlast_w;
    tx_if.ruser   <= tx_ruser_w;
    tx_if.rid     <= tx_rid_w;
    rx_if.awready <= rx_awready_w;
    rx_if.wready  <= rx_wready_w;
    rx_if.bvalid  <= rx_bvalid_w;
    rx_if.bresp   <= rx_bresp_w;
    rx_if.buser   <= rx_buser_w;
    rx_if.bid     <= rx_bid_w;
    rx_if.arready <= rx_arready_w;
    rx_if.rvalid  <= rx_rvalid_w;
    rx_if.rdata   <= rx_rdata_w;
    rx_if.rresp   <= rx_rresp_w;
    rx_if.rlast   <= rx_rlast_w;
    rx_if.ruser   <= rx_ruser_w;
    rx_if.rid     <= rx_rid_w;
  end

  ravenoc_wrapper #(.DEBUG(0)) dut (
    .clk_axi(clk), .clk_noc(clk),
    .arst_axi(~rst_n), .arst_noc(~rst_n),
    .bypass_cdc(1'b1),
    .act_in(1'b1),  .axi_sel_in(axi_sel_in),
    .act_out(1'b1), .axi_sel_out(axi_sel_out),
    .noc_in_awid(tx_if.awid),       .noc_in_awaddr(tx_if.awaddr),
    .noc_in_awlen(tx_if.awlen),     .noc_in_awsize(tx_if.awsize),
    .noc_in_awburst(tx_if.awburst), .noc_in_awlock(tx_if.awlock),
    .noc_in_awcache(tx_if.awcache), .noc_in_awprot(tx_if.awprot),
    .noc_in_awqos(tx_if.awqos),     .noc_in_awregion(tx_if.awregion),
    .noc_in_awuser(tx_if.awuser),   .noc_in_awvalid(tx_if.awvalid),
    .noc_in_awready(tx_awready_w),
    .noc_in_wdata(tx_if.wdata),     .noc_in_wstrb(tx_if.wstrb),
    .noc_in_wlast(tx_if.wlast),     .noc_in_wuser(tx_if.wuser),
    .noc_in_wvalid(tx_if.wvalid),   .noc_in_wready(tx_wready_w),
    .noc_in_bready(tx_if.bready),   .noc_in_bid(tx_bid_w),
    .noc_in_bresp(tx_bresp_w),      .noc_in_buser(tx_buser_w),
    .noc_in_bvalid(tx_bvalid_w),
    .noc_in_arid(tx_if.arid),       .noc_in_araddr(tx_if.araddr),
    .noc_in_arlen(tx_if.arlen),     .noc_in_arsize(tx_if.arsize),
    .noc_in_arburst(tx_if.arburst), .noc_in_arlock(tx_if.arlock),
    .noc_in_arcache(tx_if.arcache), .noc_in_arprot(tx_if.arprot),
    .noc_in_arqos(tx_if.arqos),     .noc_in_arregion(tx_if.arregion),
    .noc_in_aruser(tx_if.aruser),   .noc_in_arvalid(tx_if.arvalid),
    .noc_in_arready(tx_arready_w),  .noc_in_rready(tx_if.rready),
    .noc_in_rid(tx_rid_w),          .noc_in_rdata(tx_rdata_w),
    .noc_in_rresp(tx_rresp_w),      .noc_in_rlast(tx_rlast_w),
    .noc_in_ruser(tx_ruser_w),      .noc_in_rvalid(tx_rvalid_w),
    .noc_out_awid(rx_if.awid),      .noc_out_awaddr(rx_if.awaddr),
    .noc_out_awlen(rx_if.awlen),    .noc_out_awsize(rx_if.awsize),
    .noc_out_awburst(rx_if.awburst),.noc_out_awlock(rx_if.awlock),
    .noc_out_awcache(rx_if.awcache),.noc_out_awprot(rx_if.awprot),
    .noc_out_awqos(rx_if.awqos),    .noc_out_awregion(rx_if.awregion),
    .noc_out_awuser(rx_if.awuser),  .noc_out_awvalid(rx_if.awvalid),
    .noc_out_awready(rx_awready_w),
    .noc_out_wdata(rx_if.wdata),    .noc_out_wstrb(rx_if.wstrb),
    .noc_out_wlast(rx_if.wlast),    .noc_out_wuser(rx_if.wuser),
    .noc_out_wvalid(rx_if.wvalid),  .noc_out_wready(rx_wready_w),
    .noc_out_bready(rx_if.bready),  .noc_out_bid(rx_bid_w),
    .noc_out_bresp(rx_bresp_w),     .noc_out_buser(rx_buser_w),
    .noc_out_bvalid(rx_bvalid_w),
    .noc_out_arid(rx_if.arid),      .noc_out_araddr(rx_if.araddr),
    .noc_out_arlen(rx_if.arlen),    .noc_out_arsize(rx_if.arsize),
    .noc_out_arburst(rx_if.arburst),.noc_out_arlock(rx_if.arlock),
    .noc_out_arcache(rx_if.arcache),.noc_out_arprot(rx_if.arprot),
    .noc_out_arqos(rx_if.arqos),    .noc_out_arregion(rx_if.arregion),
    .noc_out_aruser(rx_if.aruser),  .noc_out_arvalid(rx_if.arvalid),
    .noc_out_arready(rx_arready_w), .noc_out_rready(rx_rready_ctrl2),
    .noc_out_rid(rx_rid_w),         .noc_out_rdata(rx_rdata_w),
    .noc_out_rresp(rx_rresp_w),     .noc_out_rlast(rx_rlast_w),
    .noc_out_ruser(rx_ruser_w),     .noc_out_rvalid(rx_rvalid_w)
  );

  initial begin
    uvm_config_db#(virtual axi_like_if)::set(null,"uvm_test_top.env.master_agent.*","tx_vif",tx_if);
    uvm_config_db#(virtual axi_like_if)::set(null,"uvm_test_top.env.rx_agent.*","tx_vif",rx_if);
    uvm_config_db#(virtual axi_like_if)::set(null,"uvm_test_top","rx_vif",rx_if);
    $dumpfile("sim_uvm.fst");
    $dumpvars(0, tb_top);
    run_test();
  end
endmodule
