# RaveNoC Design Verification Testbench

**Simulator:** Verilator 5.042 | **OS:** Ubuntu 24.04.3 LTS | **UVM:** Antmicro fork (uvm-1.2-current-patches)

## Quick Start

```bash
# Phase 0: C++ bringup (PASS)
cd sim && ./run_verilator.sh axi_like_test

# Phase 1: UVM single loopback (PASS)
cd sim && timeout 300 ./run_verilator_uvm.sh axi_like_test

# Phase 2: All-to-all sweep 12/12 (PASS)
cd sim && ./run_sweep.sh

# Phase 3: Multi-VC test 3/3 (PASS)
cd sim && timeout 300 ./run_verilator_uvm.sh axi_like_test

# Waveform
DISPLAY=:12 gtkwave sim/sim_uvm.fst sim/wave_uvm.gtkw
```

## Project Status

| Phase | Task | Status |
|-------|------|--------|
| Phase 0 | C++ bringup loopback | PASS |
| Phase 1 | UVM single loopback r0->r3 | PASS=1 |
| Phase 2 | All-to-all sweep 12 pairs | PASS=12/12 |
| Phase 3a | Multi-VC test VC0/VC1/VC2 | PASS=3/3 |
| Phase 3b | Parallel arbitration test | Pending |

## DUT � RaveNoC 2x2 Mesh NoC

| Parameter | Value |
|-----------|-------|
| Topology | 2x2 mesh |
| Routing | XY algorithm |
| Virtual channels | 3 (VC0/VC1/VC2) |
| Flit data width | 32 bits |
| bypass_cdc | 1 (single clock) |

### Router Index Map
[0][0]=0  [0][1]=1
[1][0]=2  [1][1]=3
Index = y + x*NoCCfgSzCols

### Head Flit Format
[31]=x_dest [30]=y_dest [29:22]=pkt_sz=1 [21:0]=payload

### VC Address Map
VC0: wr=0x1000  rd=0x2000
VC1: wr=0x1008  rd=0x2008
VC2: wr=0x1010  rd=0x2010

## Sweep Results (Phase 2)

| Pair | Flit | Path | Result |
|------|------|------|--------|
| r0->r1 | 0x40400002 | East | PASS |
| r0->r2 | 0x80400003 | South | PASS |
| r0->r3 | 0xC0400004 | East+South | PASS |
| r1->r0 | 0x00400005 | West | PASS |
| r1->r2 | 0x80400007 | South+West | PASS |
| r1->r3 | 0xC0400008 | South | PASS |
| r2->r0 | 0x00400009 | North | PASS |
| r2->r1 | 0x4040000A | East+North | PASS |
| r2->r3 | 0xC040000C | East | PASS |
| r3->r0 | 0x0040000D | North+West | PASS |
| r3->r1 | 0x4040000E | North | PASS |
| r3->r2 | 0x8040000F | West | PASS |

## Key Technical Findings

1. **Head flit is wdata** - first word to 0x1000 IS the routing header
2. **wvalid +1 cycle hold** - normal_txn_resp must latch at posedge
3. **Verilator ico bug #5116** - always_ff breaks combinational loop
4. **Blocking = in BFM** - NBA causes awsize/awburst to arrive as 0
5. **RaveNoC NI pre-asserts rvalid** - rready gated until test ready
6. **always_ff +1 cycle** - rdata sampled after extra posedge clk
7. **One binary per sweep pair** - run_sweep.sh uses sed+recompile

## File Structure
tb/
axi_like_if.sv          - virtual interface
axi_like_seq_item.sv    - UVM transaction
axi_like_master_bfm.sv  - shared BFM (TX + RX)
axi_like_agent.sv       - UVM agent
axi_like_env.sv         - UVM environment
axi_like_test.sv        - UVM test
axi_scoreboard.sv       - PASS/FAIL checker
tb_pkg.sv               - package
tb_top.sv               - C++ bringup top
tb_top_uvm.sv           - UVM top (always_ff workaround)
sim/
run_verilator.sh        - C++ bringup
run_verilator_uvm.sh    - UVM single pair
run_sweep.sh            - all-to-all sweep
sim_main.cpp            - C++ AXI driver
wave_uvm.gtkw           - GTKWave layout
rtl/ravenoc/              - DUT submodule
rtl_patched/              - patched RTL files

## Branches

| Branch | Content |
|--------|---------|
| main | C++ bringup PASS |
| uvm-bringup | UVM Phase 1+2+3 PASS |
