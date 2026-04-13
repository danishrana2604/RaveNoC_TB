#!/bin/bash
cd /foss/designs/AVM_XPU_Digital/RaveNoC_TB/sim
PASS=0; FAIL=0

for src in 0 1 2 3; do
  for dst in 0 1 2 3; do
    [ "$src" -eq "$dst" ] && continue
    echo "===== r${src}->r${dst} ====="

    # Update sel signals
    sed -i "s/logic \[1:0\] axi_sel_in  = 2'd.;/logic [1:0] axi_sel_in  = 2'd${src};/" \
      ../tb/tb_top_uvm.sv
    sed -i "s/logic \[1:0\] axi_sel_out = 2'd.;/logic [1:0] axi_sel_out = 2'd${dst};/" \
      ../tb/tb_top_uvm.sv

    # Update src/dst in test
    sed -i "54s/.*/    if (1) src = ${src}; \/\/ sweep/" ../tb/axi_like_test.sv
    sed -i "55s/.*/    if (1) dst = ${dst}; \/\/ sweep/" ../tb/axi_like_test.sv

    # Rebuild and run
    rm -rf obj_dir_uvm
    result=$(timeout 150 ./run_verilator_uvm.sh axi_like_test 2>&1 | \
             grep -E "TEST PASSED|TEST FAILED|WRITE done|READ rdata|Results")
    echo "$result"

    if echo "$result" | grep -q "TEST PASSED"; then
      PASS=$((PASS+1)); echo "  --> PASS"
    else
      FAIL=$((FAIL+1)); echo "  --> FAIL"
    fi
    echo ""
  done
done

echo "========================================"
echo "SWEEP COMPLETE: PASS=$PASS / $((PASS+FAIL))"
echo "========================================"
