// axi_like_if.sv
// AXI-like interface matching ravenoc_wrapper.sv flat port names exactly.
// Types resolved to plain logic to avoid amba_axi_pkg dependency in TB.
//   axi_addr_t  = logic [31:0]
//   axi_size_t  = logic [2:0]
//   axi_burst_t = logic [1:0]
//   axi_resp_t  = logic [1:0]

interface axi_like_if (input logic clk, input logic rst_n);

  // -- Write Address channel ----------------------------------------------
  logic        awid;
  logic [31:0] awaddr;
  logic [7:0]  awlen;
  logic [2:0]  awsize;
  logic [1:0]  awburst;
  logic        awlock;
  logic [3:0]  awcache;
  logic [2:0]  awprot;
  logic [3:0]  awqos;
  logic [3:0]  awregion;
  logic [1:0]  awuser;
  logic        awvalid = 0;
  logic        awready;   // driven by DUT

  // -- Write Data channel -------------------------------------------------
  logic [31:0] wdata;
  logic [3:0]  wstrb;
  logic        wlast;
  logic [1:0]  wuser;
  logic        wvalid = 0;
  logic        wready;    // driven by DUT

  // -- Write Response channel ---------------------------------------------
  logic        bid;       // driven by DUT
  logic [1:0]  bresp;     // driven by DUT
  logic [1:0]  buser;     // driven by DUT
  logic        bvalid;    // driven by DUT
  logic        bready = 1;

  // -- Read Address channel -----------------------------------------------
  logic        arid;
  logic [31:0] araddr;
  logic [7:0]  arlen;
  logic [2:0]  arsize;
  logic [1:0]  arburst;
  logic        arlock;
  logic [3:0]  arcache;
  logic [2:0]  arprot;
  logic [3:0]  arqos;
  logic [3:0]  arregion;
  logic [1:0]  aruser;
  logic        arvalid = 0;
  logic        arready;   // driven by DUT

  // -- Read Data channel --------------------------------------------------
  logic        rid;       // driven by DUT
  logic [31:0] rdata;     // driven by DUT
  logic [1:0]  rresp;     // driven by DUT
  logic        rlast;     // driven by DUT
  logic [1:0]  ruser;     // driven by DUT
  logic        rvalid;    // driven by DUT
  logic        rready = 0;

  // -- Master modport (BFM drives requests, accepts responses) -----------
  modport master (
    input  clk, rst_n,
    output awid, awaddr, awlen, awsize, awburst, awlock,
           awcache, awprot, awqos, awregion, awuser, awvalid,
           wdata, wstrb, wlast, wuser, wvalid,
           bready,
           arid, araddr, arlen, arsize, arburst, arlock,
           arcache, arprot, arqos, arregion, aruser, arvalid,
           rready,
    input  awready, wready,
           bid, bresp, buser, bvalid,
           arready,
           rid, rdata, rresp, rlast, ruser, rvalid
  );

  // -- Slave modport (monitor / responder on noc_out_* side) -------------
  modport slave (
    input  clk, rst_n,
    input  awid, awaddr, awlen, awsize, awburst, awlock,
           awcache, awprot, awqos, awregion, awuser, awvalid,
           wdata, wstrb, wlast, wuser, wvalid,
           bready,
           arid, araddr, arlen, arsize, arburst, arlock,
           arcache, arprot, arqos, arregion, aruser, arvalid,
           rready,
    output awready, wready,
           bid, bresp, buser, bvalid,
           arready,
           rid, rdata, rresp, rlast, ruser, rvalid
  );

endinterface
