#!/bin/bash
# =============================================================================
# run_verilator_uvm.sh    RaveNoC_TB  (UVM version)
export UVM_HOME="/foss/designs/AVM_XPU_Digital/antmicro-uvm/src"

usage() { echo "Usage: $(basename $0) TESTNAME [-h(elp)]"; }

OPT_TESTNAME="undefined"
while [ $# -gt 0 ]; do
  opt=${1/#--/-}
  case "$opt" in
    -h*)    usage; exit 0 ;;
    -*)     usage; echo "Unknown option: $1"; exit 1 ;;
    *test*) OPT_TESTNAME=$1 ;;
  esac
  shift
done

if [ "$OPT_TESTNAME" = "undefined" ]; then
  usage >&2; echo "Error: test name required (e.g. axi_like_test)"; exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TB_DIR="$SCRIPT_DIR/../tb"
NOC_ROOT="$SCRIPT_DIR/../../RaveNoC"
NOC_SRC="$NOC_ROOT/src"
AXI_PKG="$NOC_ROOT/bus_arch_sv_pkg"

[ -z "$UVM_HOME" ] && echo "ERROR: UVM_HOME not set" && exit 1
[ ! -f "$UVM_HOME/uvm_pkg.sv" ] && echo "ERROR: $UVM_HOME/uvm_pkg.sv not found" && exit 1
[ ! -f "$AXI_PKG/amba_axi_pkg.sv" ] && echo "ERROR: amba_axi_pkg.sv not found" && exit 1

rm -rf "$SCRIPT_DIR/obj_dir_uvm"
rm -rf "$SCRIPT_DIR/obj_dir_uvm"
echo "Verilator : $(verilator --version 2>&1 | grep -oP '\d+\.\d+' | head -1)"
echo "UVM_HOME  : $UVM_HOME"
echo "TB        : $TB_DIR"
echo "NOC RTL   : $NOC_SRC"
echo "Test      : $OPT_TESTNAME"
echo ""
echo "NOTE: Running UVM test with Antmicro UVM fork."
echo "      Antmicro UVM fork is compatible with Verilator 5.042."
echo ""

WARN="-Wno-DECLFILENAME -Wno-CONSTRAINTIGN -Wno-MISINDENT \
      -Wno-VARHIDDEN -Wno-WIDTHTRUNC -Wno-CASTCONST \
      -Wno-WIDTHEXPAND -Wno-UNDRIVEN -Wno-UNUSEDSIGNAL \
      -Wno-UNUSEDPARAM -Wno-ZERODLY -Wno-SYMRSVDWORD \
      -Wno-CASEINCOMPLETE -Wno-SIDEEFFECT -Wno-fatal \
      -Wno-REALCVT -Wno-SPLITVAR -Wno-INITIALDLY \
      -Wno-SYNCASYNCNET -Wno-PINMISSING -Wno-PINCONNECTEMPTY \
      -Wno-ENUMVALUE -Wno-UNOPTFLAT"


echo "=================================="
echo "Compiling with UVM..."
echo "=================================="

verilator \
  -sv -O1 -j "$(nproc)" \
  --binary --build --cc \
  --trace-fst \
  \
  --timescale 1ns/1ps \
  --top-module tb_top \
  --Mdir "$SCRIPT_DIR/obj_dir_uvm""" \
  --error-limit 20 \
  \
  --timing \
  --converge-limit 100000 \
  --x-initial-edge \
  --x-assign 0 \
  -fno-merge-const-pool \
  -fno-merge-const-pool \
  --x-initial-edge \
  --x-assign 0 \
  -fno-merge-const-pool \
  -fno-merge-const-pool \
  -Wall \
  -CFLAGS -DVL_DEBUG=1 \
  $WARN \
  +define+UVM_REPORT_DISABLE_FILE_LINE \
  +define+UVM_NO_DPI \
  +define+UVM_VERILATOR \
  +define+COMMON_CELLS_ASSERTS_OFF \
  +incdir+"$UVM_HOME" \
  +incdir+"$TB_DIR" \
  +incdir+"$NOC_SRC/include" \
  +incdir+"$AXI_PKG" \
  "$UVM_HOME/uvm_pkg.sv" \
  "$AXI_PKG/amba_axi_pkg.sv" \
  "$NOC_SRC/include/ravenoc_pkg.sv" \
  "$TB_DIR/axi_like_if.sv" \
  "$NOC_SRC/router/router_if.sv" \
  "$NOC_SRC/router/fifo.sv" \
  "$SCRIPT_DIR/../rtl_patched/vc_buffer.sv" \
  "$NOC_SRC/router/rr_arbiter.sv" \
  "$SCRIPT_DIR/../rtl_patched/input_datapath.sv" \
  "$NOC_SRC/router/input_module.sv" \
  "$NOC_SRC/router/input_router.sv" \
  "$SCRIPT_DIR/../rtl_patched/output_module.sv" \
  "$SCRIPT_DIR/../rtl_patched/router_ravenoc.sv" \
  "$NOC_SRC/ni/async_gp_fifo.sv" \
  "$NOC_SRC/ni/pkt_proc.sv" \
  "$NOC_SRC/ni/cdc_pkt.sv" \
  "$SCRIPT_DIR/../rtl_patched/axi_csr.sv" \
  "$SCRIPT_DIR/../rtl_patched/axi_slave_if.sv" \
  "$SCRIPT_DIR/../rtl_patched/router_wrapper.sv" \
  "$NOC_SRC/ravenoc.sv" \
  "$NOC_SRC/ravenoc_wrapper.sv" \
  "$TB_DIR/tb_pkg.sv" \
  ""$TB_DIR/tb_top_uvm.sv"" \
  2>&1 | tail -5

RC=$?
if [ $RC -ne 0 ]; then
  echo "== COMPILE FAILED =="
  exit $RC
fi

echo "=================================="
echo "Running: $OPT_TESTNAME"
echo "Running axi_like_test with Antmicro UVM"
echo "=================================="

"$SCRIPT_DIR/obj_dir_uvm/Vtb_top" +UVM_TESTNAME="$OPT_TESTNAME" "$@"

RC=$?
if [ $RC -ne 0 ]; then
  echo ""
  echo "== FAILED as expected =="
  echo "Root cause: Standard Accellera UVM is not compatible with"
  rm -rf "$SCRIPT_DIR/obj_dir_uvm"
rm -rf "$SCRIPT_DIR/obj_dir_uvm"
  echo "Fix: Use Antmicro patched UVM fork."
else
  echo "== PASSED =="
fi
