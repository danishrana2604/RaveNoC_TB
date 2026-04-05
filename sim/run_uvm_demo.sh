#!/bin/bash
# Demo script showing UVM + Verilator 5.042 incompatibility
export UVM_HOME="/foss/designs/AVM_XPU_Digital/uvm-verilator/src"

# Create a minimal UVM tb_top for demo
cat > /tmp/tb_top_uvm_demo.sv << 'SVEOF'
module tb_top;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  logic clk, rst_n;
  initial clk = 0;
  always #5 clk = ~clk;
  initial begin rst_n = 0; #200; rst_n = 1; end

  initial begin
    run_test();
  end
endmodule
SVEOF

rm -rf /tmp/obj_uvm_demo

verilator -sv -O1 -j 16 \
  --binary --build --cc \
  --timing \
  --timescale 1ns/1ps \
  --top-module tb_top \
  --Mdir /tmp/obj_uvm_demo \
  -Wno-fatal -Wno-DECLFILENAME -Wno-CONSTRAINTIGN \
  -Wno-MISINDENT -Wno-VARHIDDEN -Wno-WIDTHTRUNC \
  -Wno-CASTCONST -Wno-WIDTHEXPAND -Wno-UNDRIVEN \
  -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Wno-ZERODLY \
  -Wno-SYMRSVDWORD -Wno-CASEINCOMPLETE -Wno-SIDEEFFECT \
  -Wno-REALCVT -Wno-SPLITVAR -Wno-INITIALDLY \
  +define+UVM_REPORT_DISABLE_FILE_LINE \
  +define+UVM_NO_DPI \
  +define+UVM_VERILATOR \
  +incdir+"$UVM_HOME" \
  "$UVM_HOME/uvm_pkg.sv" \
  /tmp/tb_top_uvm_demo.sv \
  2>&1 | tail -3

echo ""
echo "Running UVM binary - expect timing error below:"
echo "================================================"
/tmp/obj_uvm_demo/Vtb_top +UVM_TESTNAME=axi_like_test 2>&1 | grep -E "Error|UVM|Running|RNTST"
