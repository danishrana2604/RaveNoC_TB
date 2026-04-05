// debug_signals.sv
// Thin module  port-connects internal DUT signals so they appear in
// the FST waveform without needing a hierarchical path in GTKWave.
// Instantiate inside tb_top if needed; currently a stub.

module debug_signals (
  input logic clk,
  input logic rst_n,
  // Add signals here as you identify useful internal DUT nets
  // e.g. input logic [1:0] tx_fsm_state,
  //      input logic       vc0_full
);
  // nothing  signals are visible via port connection in waveform
endmodule
