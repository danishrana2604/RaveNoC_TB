# RaveNoC Design Verification Testbench

**Simulator:** Verilator 5.042 | **OS:** Ubuntu 24.04.3 LTS | **UVM:** Antmicro fork (uvm-1.2-current-patches)

## Quick Start

\`\`\`bash
# Phase 0: C++ bringup (PASS)
cd sim && ./run_verilator.sh axi_like_test

# Phase 1: UVM single loopback r0->r3 (PASS)
cd sim && ./run_verilator_uvm.sh axi_like_test

# Phase 2: All-to-all sweep � all 12 src->dst pairs (PASS 12/12)
cd sim && ./run_sweep.sh

# View waveform
DISPLAY=:12 gtkwave sim/sim_uvm.fst sim/wave_uvm.gtkw &
\`\`\`

## DUT � RaveNoC 2×2 Mesh NoC

| Parameter | Value |
|-----------|-------|
| Topology | 2×2 mesh |
| Routing | XY algorithm |
| Virtual channels | 3 (VC0/VC1/VC2) |
| Flit data width | 32 bits |
| bypass_cdc | 1 (single clock domain) |
| Reset | arst = ~rst_n (async active-high) |

### Router Index Map

\`\`\`
Index = y + x * NoCCfgSzCols   (x=row, y=col)

  col0      col1
  [0][0]=0  [0][1]=1   row 0
  [1][0]=2  [1][1]=3   row 1
\`\`\`

### Head Flit Format (write to 0x1000)

\`\`\`
Bit  [31]    = x_dest  (destination row)
Bit  [30]    = y_dest  (destination col)
Bits [29:22] = pkt_size (1 for single flit)
Bits [21:0]  = payload data

Example r0->r3: 0xC0400001
\`\`\`

## Project Status

| Phase | Task | Status |
|-------|------|--------|
| Phase 0 | C++ bringup � write + read loopback | ? PASS |
| Phase 1 | UVM write path (AW+W+B) | ? PASS |
| Phase 1 | UVM read path (AR+R + scoreboard) | ? PASS |
| Phase 2 | All-to-all sweep � 12/12 pairs | ? PASS |
| Phase 3 | Parallel/arbitration test | ? Pending |

## Phase 2 Sweep Results

| Pair | Flit | Routing path | Result |
|------|------|-------------|--------|
| r0?r1 | 0x40400002 | [0][0]?East?[0][1] | ? |
| r0?r2 | 0x80400003 | [0][0]?South?[1][0] | ? |
| r0?r3 | 0xC0400004 | [0][0]?East?[0][1]?South?[1][1] | ? |
| r1?r0 | 0x00400005 | [0][1]?West?[0][0] | ? |
| r1?r2 | 0x80400007 | [0][1]?South?[1][1]?West?[1][0] | ? |
| r1?r3 | 0xC0400008 | [0][1]?South?[1][1] | ? |
| r2?r0 | 0x00400009 | [1][0]?North?[0][0] | ? |
| r2?r1 | 0x4040000A | [1][0]?East?[1][1]?North?[0][1] | ? |
| r2?r3 | 0xC040000C | [1][0]?East?[1][1] | ? |
| r3?r0 | 0x0040000D | [1][1]?North?[0][1]?West?[0][0] | ? |
| r3?r1 | 0x4040000E | [1][1]?North?[0][1] | ? |
| r3?r2 | 0x8040000F | [1][1]?West?[1][0] | ? |

## Key Technical Findings

1. **Head flit is wdata** � first word written to 0x1000 IS the routing header
2. **wvalid +1 cycle hold** � normal_txn_resp must latch at posedge
3. **Verilator ico bug #5116** � always_ff workaround breaks combinational loop
4. **Blocking = in BFM** � NBA causes awsize/awburst to arrive as 0
5. **RaveNoC NI pre-asserts rvalid** � rready must be gated until test ready
6. **always_ff +1 cycle** � rdata sampled after extra @posedge clk
7. **One binary per pair** � run_sweep.sh modifies SV via sed and recompiles

## File Structure

\`\`\`
tb/
  axi_like_if.sv          � virtual interface
  axi_like_seq_item.sv    � UVM transaction
  axi_like_master_bfm.sv  � shared BFM (TX + RX)
  axi_like_agent.sv       � UVM agent
  axi_like_env.sv         � UVM environment
  axi_like_test.sv        � UVM test (single pair per run)
  axi_scoreboard.sv       � PASS/FAIL checker
  tb_pkg.sv               � package
  tb_top.sv               � C++ bringup top
  tb_top_uvm.sv           � UVM top (always_ff workaround)
sim/
  run_verilator.sh        � C++ bringup
  run_verilator_uvm.sh    � UVM single pair
  run_sweep.sh            � all-to-all sweep (Phase 2)
  sim_main.cpp            � C++ AXI driver
  wave_uvm.gtkw           � GTKWave signal layout
\`\`\`

## Branches

| Branch | Content |
|--------|---------|
| main | Stable C++ bringup PASS |
| uvm-bringup | UVM Phase 1 + Phase 2 sweep PASS |
