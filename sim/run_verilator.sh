#!/bin/bash
# =============================================================================
# run_verilator.sh    RaveNoC_TB
# Verilator 5.042  |  Ubuntu 24.04.3 LTS
# Usage:  ./run_verilator.sh TESTNAME [-w] [-b] [-h]
# =============================================================================


usage() { echo "Usage: $(basename $0) TESTNAME [-w(aveform)] [-b(ugpoint)] [-h(elp)]"; }

OPT_TESTNAME="undefined"
OPT_WAVE=0
OPT_BUGPOINT=0

while [ $# -gt 0 ]; do
  opt=${1/#--/-}
  case "$opt" in
    -w*)    OPT_WAVE=1 ;;
    -b*)    OPT_BUGPOINT=1 ;;
    -h*)    usage; exit 0 ;;
    -*)     usage; echo "Unknown option: $1"; exit 1 ;;
    *test*) OPT_TESTNAME=$1 ;;
  esac
  shift
done

if [ "$OPT_TESTNAME" = "undefined" ]; then
  usage >&2; echo "Error: test name required"; exit 1
fi

# -- Paths ------------------------------------------------------------------
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TB_DIR="$SCRIPT_DIR/../tb"
NOC_ROOT="$SCRIPT_DIR/../rtl/ravenoc"   # adjust if your folder is named differently
NOC_SRC="$NOC_ROOT/src"
AXI_PKG="$NOC_ROOT/bus_arch_sv_pkg"

# -- Checks -----------------------------------------------------------------
[ ! -f "$AXI_PKG/amba_axi_pkg.sv" ] && {
  echo "ERROR: $AXI_PKG/amba_axi_pkg.sv not found."
  echo "       Run: cd $NOC_ROOT && git submodule update --init"
  exit 1
}

# Check Verilator version
VER=$(verilator --version 2>&1 | grep -oP '\d+\.\d+' | head -1)
echo "Verilator : $VER"
echo "TB        : $TB_DIR"
echo "NOC RTL   : $NOC_SRC"
echo "Test      : $OPT_TESTNAME"

# -- Flags ------------------------------------------------------------------
if [ $OPT_BUGPOINT -eq 1 ]; then
  VL_MODE="-E -P --cc"; VL_POST="> sv-bugpoint-input.sv"
else
  VL_MODE="--cc --build --exe"; VL_POST=""
fi

WAVE_FLAG=""
[ $OPT_WAVE -eq 1 ] && WAVE_FLAG="--trace-fst" && echo "Waveform  : sim.fst (GTKWave)"

# -- Warnings suppressed (UVM class lib + RaveNoC) -------------------------
WARN="-Wno-DECLFILENAME -Wno-CONSTRAINTIGN -Wno-MISINDENT \
      -Wno-VARHIDDEN -Wno-WIDTHTRUNC -Wno-CASTCONST \
      -Wno-WIDTHEXPAND -Wno-UNDRIVEN -Wno-UNUSEDSIGNAL \
      -Wno-UNUSEDPARAM -Wno-ZERODLY -Wno-SYMRSVDWORD \
      -Wno-CASEINCOMPLETE -Wno-SIDEEFFECT -Wno-fatal \
      -Wno-REALCVT -Wno-SPLITVAR \
      -Wno-INITIALDLY \
      -Wno-SYNCASYNCNET \
      -Wno-PINMISSING \
      -Wno-PINCONNECTEMPTY \
      -Wno-ENUMVALUE \
      -Wno-ENUMVALUE"

# -- Required TB files check ------------------------------------------------
for f in axi_like_if.sv tb_pkg.sv tb_top.sv debug_signals.sv; do
  [ ! -f "$TB_DIR/$f" ] && echo "ERROR: missing $TB_DIR/$f" && exit 1
done

echo "=================================="
echo "Compiling..."
echo "=================================="

# FILE ORDER (critical for Verilator):
#   1. UVM package
#   2. amba_axi_pkg  (defines axi_addr_t / axi_resp_t etc.)
#   3. ravenoc_pkg   (includes defines/structs/fnc)
#   4. AXI-like interface
#   5. RaveNoC RTL bottom-up
#   6. TB package (includes all UVM classes)
#   7. TB top
#   8. C++ harness

verilator \
  -sv \
  -O1 \
  -j "$(nproc)" \
  $VL_MODE \
  $WAVE_FLAG \
  \
  --timescale 1ns/1ps \
  --trace-fst \
  --Mdir "$SCRIPT_DIR/obj_dir" \
  --error-limit 20 \
  --top-module tb_top \
  -Wall \
  -Wno-UNOPTFLAT \
  $WARN \
  +define+COMMON_CELLS_ASSERTS_OFF \
  +incdir+"$TB_DIR" \
  +incdir+"$NOC_SRC/include" \
  +incdir+"$AXI_PKG" \
  "$AXI_PKG/amba_axi_pkg.sv" \
  "$NOC_SRC/include/ravenoc_pkg.sv" \
  "$NOC_SRC/router/router_if.sv" \
  "$NOC_SRC/router/fifo.sv" \
  "$NOC_SRC/router/vc_buffer.sv" \
  "$NOC_SRC/router/rr_arbiter.sv" \
  "$NOC_SRC/router/input_datapath.sv" \
  "$NOC_SRC/router/input_module.sv" \
  "$NOC_SRC/router/input_router.sv" \
  "$NOC_SRC/router/output_module.sv" \
  "$NOC_SRC/router/router_ravenoc.sv" \
  "$NOC_SRC/ni/async_gp_fifo.sv" \
  "$NOC_SRC/ni/pkt_proc.sv" \
  "$NOC_SRC/ni/cdc_pkt.sv" \
  "$NOC_SRC/ni/axi_csr.sv" \
  "$NOC_SRC/ni/axi_slave_if.sv" \
  "$NOC_SRC/ni/router_wrapper.sv" \
  "$NOC_SRC/ravenoc.sv" \
  "$NOC_SRC/ravenoc_wrapper.sv" \
  "$TB_DIR/tb_top.sv" \
  "$SCRIPT_DIR/sim_main.cpp" \
   \
  $VL_POST

RC=$?
[ $RC -ne 0 ] && echo "== COMPILE FAILED ==" && exit $RC
[ $OPT_BUGPOINT -eq 1 ] && echo "Bugpoint: sv-bugpoint-input.sv" && exit 0

echo "=================================="
echo "Running: $OPT_TESTNAME"
echo "=================================="

cd "$SCRIPT_DIR"
./obj_dir/Vtb_top

RC=$?
if [ $RC -eq 0 ]; then
  echo "== PASSED =="
  [ $OPT_WAVE -eq 1 ] && echo "Waveform: $SCRIPT_DIR/sim.fst"
else
  echo "== FAILED (exit $RC) =="
  exit $RC
fi
