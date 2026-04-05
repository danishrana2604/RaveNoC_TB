// tb_pkg.sv
// Single compilation unit for all TB classes.
// Include order matters: base types first, then components that use them.

package tb_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "axi_like_seq_item.sv"
  `include "axi_like_master_bfm.sv"
  `include "axi_like_slave_bfm.sv"
  `include "axi_like_agent.sv"
  `include "axi_scoreboard.sv"
  `include "axi_like_env.sv"
  `include "axi_like_test.sv"
endpackage
