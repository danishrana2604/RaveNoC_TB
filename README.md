# RaveNoC Design Verification Testbench

**Simulator:** Verilator 5.042 | **OS:** Ubuntu 24.04.3 LTS | **UVM:** Antmicro fork (uvm-1.2-current-patches)

## Quick Start
```bash
# Phase 0: C++ bringup (PASS)
cd sim && ./run_verilator.sh axi_like_test

# Phase 1: UVM run (write PASS, read PASS)
cd sim && ./run_verilator_uvm.sh axi_like_test

```

## DUT
RaveNoC 2×2 mesh NoC · XY routing · 3 VCs · FLIT_DATA_WIDTH=32
| Port | Router | Signal |
|------|--------|--------|
| TX | [0][0] | noc_in_* (axi_sel_in=0) |
| RX | [1][1] | noc_out_* (axi_sel_out=3) |

## Head Flit Format (write to 0x1000)
[31:30] = dest x,y  (1,1 for router [1][1])
[29:22] = pkt_size  (1 for single flit)
[21:0]  = payload
Example: 0xC0400001

## Project Status
| Phase | Task | Status |
|-------|------|--------|
| Phase 0 | C++ bringup  write + read loopback |  PASS |
| Phase 1 | UVM write path (AW+W+B) |  PASS |
| Phase 1 | UVM read path (AR+R scoreboard) | PASS |
| Phase 2 | Some test cases  |  Pending |

## Key Technical Findings
1. **wvalid must be held 1 extra cycle** after wready  `normal_txn_resp` needs a full posedge
2. **AW+W must be driven simultaneously**  wready is combinatorially gated on the AW FIFO
3. **Verilator ico bug #5116**  virtual interface members create infinite combinational triggers with UVM; workaround: `always_ff` registered intermediates in `tb_top_uvm.sv`
4. **RaveNoC NI pre-asserts rvalid** without waiting for arvalid  rready must be gated until test is ready to read

## File Structure
tb/
axi_like_if.sv          � AXI-like virtual interface
axi_like_seq_item.sv    � UVM transaction (write/read)
axi_like_master_bfm.sv  � shared driver (TX + RX agents)
axi_like_agent.sv       � UVM agent (sequencer + driver)
axi_like_env.sv         � UVM environment
axi_like_test.sv        � UVM test (VC0 loopback)
axi_scoreboard.sv       � PASS/FAIL checker
tb_pkg.sv               � package including all classes
tb_top.sv               � C++ bringup top (flat ports)
tb_top_uvm.sv           � UVM top (always_ff workaround)
sim/
run_verilator.sh        � C++ bringup script
run_verilator_uvm.sh    � UVM script (Antmicro fork)
