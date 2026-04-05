// axi_like_slave_bfm.sv
// UVM responder  drives noc_out_* (RX side) of ravenoc_wrapper.
// Accepts writes (sends B=OKAY) and reads (sends rdata from a simple memory).

class axi_like_slave_bfm extends uvm_component;
  `uvm_component_utils(axi_like_slave_bfm)

  virtual axi_like_if.slave vif;

  // Simple 256-word memory model (word-addressed)
  logic [31:0] mem [0:255];

  // Configurable response delay in cycles (0 = back-to-back)
  int unsigned resp_delay = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual axi_like_if)::get(this, "", "rx_vif", vif))
      `uvm_fatal("NO_VIF", "axi_like_slave_bfm: rx_vif not found in config_db")
    // zero out memory
    foreach (mem[i]) mem[i] = 32'h0;
  endfunction

  task run_phase(uvm_phase phase);
    // Initialise outputs
    vif.awready <= 0;
    vif.wready  <= 0;
    vif.bvalid  <= 0; vif.bid <= 0; vif.bresp <= 2'b00; vif.buser <= 0;
    vif.arready <= 0;
    vif.rvalid  <= 0; vif.rid <= 0; vif.rdata <= 0;
    vif.rresp   <= 2'b00; vif.rlast <= 0; vif.ruser <= 0;

    @(posedge vif.rst_n);
    @(posedge vif.clk);

    // Run write and read handlers concurrently
    fork
      handle_writes();
      handle_reads();
    join
  endtask

  // -- Write handler -----------------------------------------------------
  task handle_writes();
    logic        id_lat;
    logic [31:0] addr_lat;
    logic [7:0]  len_lat;

    forever begin
      // Accept AW
      vif.awready <= 1;
      @(posedge vif.clk iff vif.awvalid);
      id_lat   = vif.awid;
      addr_lat = vif.awaddr;
      len_lat  = vif.awlen;
      vif.awready <= 0;

      // Accept W beats
      for (int i = 0; i <= len_lat; i++) begin
        vif.wready <= 1;
        @(posedge vif.clk iff vif.wvalid);
        // store to memory (word address = addr[9:2] + beat offset)
        mem[(addr_lat[9:2] + i) & 8'hFF] = vif.wdata;
        vif.wready <= 0;
      end

      // Optional delay before B
      repeat(resp_delay) @(posedge vif.clk);

      // Send B response
      vif.bvalid <= 1;
      vif.bid    <= id_lat;
      vif.bresp  <= 2'b00;  // OKAY
      @(posedge vif.clk iff vif.bready);
      vif.bvalid <= 0;

      `uvm_info("SLAVE_BFM", $sformatf("WRITE accepted addr=0x%08h", addr_lat), UVM_MEDIUM)
    end
  endtask

  // -- Read handler ------------------------------------------------------
  task handle_reads();
    logic        id_lat;
    logic [31:0] addr_lat;
    logic [7:0]  len_lat;

    forever begin
      // Accept AR
      vif.arready <= 1;
      @(posedge vif.clk iff vif.arvalid);
      id_lat   = vif.arid;
      addr_lat = vif.araddr;
      len_lat  = vif.arlen;
      vif.arready <= 0;

      // Optional delay before R
      repeat(resp_delay) @(posedge vif.clk);

      // Send R beats
      for (int i = 0; i <= len_lat; i++) begin
        vif.rvalid <= 1;
        vif.rid    <= id_lat;
        vif.rdata  <= mem[(addr_lat[9:2] + i) & 8'hFF];
        vif.rresp  <= 2'b00;  // OKAY
        vif.rlast  <= (i == len_lat);
        @(posedge vif.clk iff vif.rready);
      end
      vif.rvalid <= 0;
      vif.rlast  <= 0;

      `uvm_info("SLAVE_BFM", $sformatf("READ accepted addr=0x%08h len=%0d", addr_lat, len_lat), UVM_MEDIUM)
    end
  endtask

endclass
