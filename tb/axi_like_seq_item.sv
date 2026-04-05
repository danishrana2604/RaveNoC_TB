// axi_like_seq_item.sv
// One AXI transaction (write or read, single beat for now).

class axi_like_seq_item extends uvm_sequence_item;
  `uvm_object_utils(axi_like_seq_item)

  // direction
  typedef enum logic { AXI_WRITE = 0, AXI_READ = 1 } axi_dir_e;
  rand axi_dir_e    dir;

  // address channel
  rand logic [31:0] addr;
  rand logic [7:0]  len;     // 0 = 1 beat
  rand logic [2:0]  size;    // 2 = 4-byte word
  rand logic [1:0]  burst;   // 01 = INCR
  logic             id;

  // data (write)
  rand logic [31:0] data [];  // dynamic array, 1 entry per beat
  rand logic [3:0]  strb;

  // response (filled in by BFM)
  logic [1:0]  bresp;
  logic [31:0] rdata [];

  // -- Constraints ------------------------------------------------------
  // Only word-aligned addresses to valid RaveNoC regions
  constraint c_addr_align { addr[1:0] == 2'b00; }
  constraint c_size_word  { size == 3'b010; }      // 4-byte
  constraint c_burst_incr { burst == 2'b01; }
  constraint c_len_basic  { len == 8'h00; }        // single beat to start

  // data array length must match len+1
  constraint c_data_size  { data.size() == (len + 1); }

  function new(string name = "axi_like_seq_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("%s addr=0x%08h len=%0d data[0]=0x%08h bresp=%0b",
      dir.name(), addr, len, (data.size() > 0 ? data[0] : 32'hx), bresp);
  endfunction
endclass
