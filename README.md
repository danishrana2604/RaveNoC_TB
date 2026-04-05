# RaveNoC Design Verification Testbench

Verilator 5.042 | Ubuntu 24.04.3 | Antmicro UVM fork

## Quick Start
```bash
# C++ bringup (Phase 0 � PASS)
cd sim && ./run_verilator.sh axi_like_test

# UVM run (Phase 1 � write works, read in progress)
cd sim && ./run_verilator_uvm.sh axi_like_test
```

## DUT
RaveNoC 2×2 mesh NoC, XY routing, 3 VCs, FLIT_DATA_WIDTH=32.
- TX: router [0][0] via noc_in_* (axi_sel_in=0)
- RX: router [1][1] via noc_out_* (axi_sel_out=3)

## Status
| Phase | Status |
|-------|--------|
| Phase 0: C++ bringup | ? PASS |
| Phase 1: UVM write path | ? PASS |
| Phase 1: UVM read path | ?? In progress |

## Key Finding
Head flit format for noc_in write at 0x1000:
- [31:30] = dest x,y coordinates
- [29:22] = packet size in flits  
- [21:0]  = payload data
