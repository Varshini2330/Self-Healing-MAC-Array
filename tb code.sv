parameter int N     = 2;
parameter int WIDTH = 4;

`include "uvm_macros.svh"
import uvm_pkg::*;

class my_trans extends uvm_sequence_item;
  rand logic [WIDTH-1:0]   a [N*N];
  rand logic [WIDTH-1:0]   b [N*N];
  rand logic [2*WIDTH-1:0] c [N*N];
       logic [2*WIDTH-1:0] y [N*N];

  // Existing flags
  logic error_detected;
  logic ready_data;
  logic fault_response;
  logic valid_data;
  logic signal_error;

  // NEW fields for FSM and remapping
  logic [2:0] fsm_state;
  logic       spare_mac_active;
  logic [3:0] fault_mac_row, fault_mac_col;
  logic [3:0] spare_mac_row, spare_mac_col;

  `uvm_object_utils_begin(my_trans)
    `uvm_field_sarray_int(a, UVM_DEFAULT)
    `uvm_field_sarray_int(b, UVM_DEFAULT)
    `uvm_field_sarray_int(c, UVM_DEFAULT)
    `uvm_field_sarray_int(y, UVM_DEFAULT)
    `uvm_field_int(fsm_state, UVM_DEFAULT)
    `uvm_field_int(spare_mac_active, UVM_DEFAULT)
    `uvm_field_int(fault_mac_row, UVM_DEFAULT)
    `uvm_field_int(fault_mac_col, UVM_DEFAULT)
    `uvm_field_int(spare_mac_row, UVM_DEFAULT)
    `uvm_field_int(spare_mac_col, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name="my_trans");
    super.new(name);
  endfunction
endclass
//--------------------------------------------------------------------
// Sequence
// ---------------------------------------------------------------------
class my_gen extends uvm_sequence #(my_trans);
  `uvm_object_utils(my_gen)
  my_trans tg;

  function new(string name = "my_gen");
    super.new(name);
  endfunction

  virtual task body();
    repeat (10) begin
      tg = my_trans::type_id::create("tg");
      start_item(tg);
      assert(tg.randomize()) else `uvm_fatal("my_gen", "Randomization failed")
      finish_item(tg);
      `uvm_info("my_gen",
                $sformatf("Data sent: a=%p b=%p c=%p", tg.a, tg.b, tg.c),
                UVM_NONE)
    end
  endtask
endclass

// ---------------------------------------------------------------------
// Driver
// ---------------------------------------------------------------------
class my_driver extends uvm_driver #(my_trans);
  `uvm_component_utils(my_driver)
  virtual mac_if #(WIDTH, N) aif;
  my_trans td;

  function new(string name = "my_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task reset_dut();
    aif.rst <= 1'b0;
    foreach (aif.a[i]) foreach (aif.a[i][j]) begin
      aif.a[i][j] <= '0;
      aif.b[i][j] <= '0;
      aif.c[i][j] <= '0;
    end
    repeat (5) @(posedge aif.clk);
    aif.rst <= 1'b1;
    repeat (3) @(posedge aif.clk);
  endtask

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    td = my_trans::type_id::create("td", this);
    if (!uvm_config_db #(virtual mac_if #(WIDTH, N))::get(this, "", "aif", aif))
      `uvm_fatal("my_driver", "Unable to access interface")
  endfunction

  task run_phase(uvm_phase phase);
    reset_dut();

    forever begin
      seq_item_port.get_next_item(td);

      foreach (td.a[k]) begin
        int i = k / N;
        int j = k % N;
        aif.a[i][j] <= td.a[k];
        aif.b[i][j] <= td.b[k];
        aif.c[i][j] <= td.c[k];
      end

      aif.error_detected <= td.error_detected;
      aif.fault_response <= td.fault_response;
      aif.valid_data     <= td.valid_data;
      aif.signal_error   <= td.signal_error;

      repeat (3) @(posedge aif.clk);

      foreach (td.y[k]) begin
        int i = k / N;
        int j = k % N;
        td.y[k] = aif.y[i][j];
      end

      seq_item_port.item_done();

      `uvm_info("my_driver",
                $sformatf("DUT: a=%p b=%p c=%p y=%p", td.a, td.b, td.c, aif.y),
                UVM_NONE)
    end
  endtask
endclass

// ---------------------------------------------------------------------
// Monitor
// ---------------------------------------------------------------------
class my_mon extends uvm_component;
  `uvm_component_utils(my_mon)
  uvm_analysis_port #(my_trans) send;
  virtual mac_if #(WIDTH, N) aif;
  my_trans tm;

  function new(string name = "my_mon", uvm_component parent = null);
    super.new(name, parent);
    send = new("send", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tm = my_trans::type_id::create("tm", this);
    if (!uvm_config_db #(virtual mac_if #(WIDTH, N))::get(this, "", "aif", aif))
      `uvm_fatal("my_mon", "Unable to access interface")
  endfunction

  task run_phase(uvm_phase phase);
    @(posedge aif.rst);

    forever begin
      repeat (3) @(posedge aif.clk);

      foreach (tm.a[k]) begin
        int i = k / N;
        int j = k % N;
        tm.a[k] = aif.a[i][j];
        tm.b[k] = aif.b[i][j];
        tm.c[k] = aif.c[i][j];
        tm.y[k] = aif.y[i][j];
      end

      tm.error_detected = aif.error_detected;
      tm.fault_response = aif.fault_response;
      tm.valid_data     = aif.valid_data;
      tm.signal_error   = aif.signal_error;
      tm.fsm_state       = aif.fsm_state;
      tm.spare_mac_active= aif.spare_mac_active;
      tm.fault_mac_row   = aif.fault_mac_row;
      tm.fault_mac_col   = aif.fault_mac_col;
      tm.spare_mac_row   = aif.spare_mac_row;
      tm.spare_mac_col   = aif.spare_mac_col;


      send.write(tm);
    end
  endtask
endclass
// ---------------------------------------------------------------------
// Scoreboard
// ---------------------------------------------------------------------
class my_score extends uvm_component;
  `uvm_component_utils(my_score)
  uvm_analysis_imp #(my_trans, my_score) rec;
  my_trans ts;

  function new(string name = "my_score", uvm_component parent = null);
    super.new(name, parent);
    rec = new("rec", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ts = my_trans::type_id::create("ts", this);
  endfunction

  function void write(my_trans t);
    logic [2*WIDTH-1:0] expected;

    // Print FSM state for context
    string state_name;
    case (t.fsm_state)
      3'b000: state_name = "IDLE";
      3'b001: state_name = "NORMAL";
      3'b010: state_name = "FAULT";
      3'b011: state_name = "RECOVER";
      3'b100: state_name = "CORRECTED";
      default: state_name = "UNKNOWN";
    endcase
    `uvm_info("FSM",$sformatf("FSM_STATE=%s",state_name),UVM_LOW)

    // Show fault → spare mapping if active
    if (t.spare_mac_active)
      `uvm_info("FLOW",
        $sformatf("FAULT at MAC[%0d][%0d] → remapped to SPARE[%0d][%0d]",
                  t.fault_mac_row, t.fault_mac_col,
                  t.spare_mac_row, t.spare_mac_col), UVM_LOW)

    // Arithmetic check for each MAC element
    foreach (t.a[k]) begin
  int row = k / N;
  int col = k % N;
  expected = (t.a[k] * t.b[k]) + t.c[k];
  if (t.y[k] !== expected)
    `uvm_error("my_score",
      $sformatf("MISMATCH MAC[%0d][%0d]: got=%0d expected=%0d",
                row, col, t.y[k], expected))
  else
    `uvm_info("my_score",
      $sformatf("MATCH MAC[%0d][%0d]: got=%0d expected=%0d",
                row, col, t.y[k], expected), UVM_LOW)
end

    ts = t;
  endfunction
endclass
// ---------------------------------------------------------------------
// Agent
// ---------------------------------------------------------------------
class my_agent extends uvm_component;
  `uvm_component_utils(my_agent)
  my_mon m;
  my_driver d;
  uvm_sequencer #(my_trans) seq;

  function new(string name = "my_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m   = my_mon   ::type_id::create("m", this);
    d   = my_driver::type_id::create("d", this);
    seq = uvm_sequencer#(my_trans)::type_id::create("seq", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    d.seq_item_port.connect(seq.seq_item_export);
  endfunction
endclass

// ---------------------------------------------------------------------
// Environment
// ---------------------------------------------------------------------
class my_env extends uvm_component;
  `uvm_component_utils(my_env)
  my_agent a;
  my_score s;
  virtual mac_if #(WIDTH, N) vif;

  function new(string name = "my_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    a = my_agent::type_id::create("a", this);
    s = my_score::type_id::create("s", this);

    if (!uvm_config_db #(virtual mac_if #(WIDTH, N))::get(this, "", "aif", vif))
      `uvm_fatal("my_env", "Unable to access interface")
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    a.m.send.connect(s.rec);
  endfunction
endclass

// ---------------------------------------------------------------------
// Test
// ---------------------------------------------------------------------
class my_test extends uvm_test;
  `uvm_component_utils(my_test)
  my_env e;
  my_gen g;

  function new(string name="my_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e = my_env::type_id::create("e", this);
    g = my_gen::type_id::create("g");
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    g.start(e.a.seq);

    // FSM testcase
    e.vif.mac_done   <= 1'b0;
    e.vif.error_flag <= 1'b0;
    e.vif.heart_beat <= 1'b0;
    @(posedge e.vif.clk);
    `uvm_info("FSM","FSM_STATE=IDLE",UVM_LOW)
    e.vif.mac_done   <= 1'b1;
    e.vif.error_flag <= 1'b0;
    e.vif.heart_beat <= 1'b1;
    @(posedge e.vif.clk);
    `uvm_info("FSM","FSM_STATE=NORMAL",UVM_LOW)

    e.vif.mac_done   <= 1'b0;
    e.vif.error_flag <= 1'b1;
    e.vif.heart_beat <= 1'b0;
    @(posedge e.vif.clk);
    `uvm_info("FSM"," FSM_STATE=FAULT",UVM_LOW)

    e.vif.mac_done   <= 1'b1;
    e.vif.error_flag <= 1'b0;
    e.vif.heart_beat <= 1'b1;
    @(posedge e.vif.clk);
    `uvm_info("FSM"," FSM_STATE=RECOVER",UVM_LOW)

    e.vif.mac_done   <= 1'b1;
    e.vif.error_flag <= 1'b0;
    e.vif.heart_beat <= 1'b1;
    @(posedge e.vif.clk);
    `uvm_info("FSM","FSM_STATE=CORRECTED",UVM_LOW)

    #200;
    phase.drop_objection(this);
  endtask
endclass

// ---------------------------------------------------------------------
// Top testbench
// ---------------------------------------------------------------------
module tb;
  logic clk, rst;

  initial clk = 0;
  always #5 clk = ~clk;

  mac_if #(WIDTH, N) aif ();
  assign aif.clk = clk;
  assign aif.rst = rst;

  mac_array #(.N(N), .WIDTH(WIDTH)) dut (
    .a   (aif.a),
    .b   (aif.b),
    .c   (aif.c),
    .y   (aif.y),
    .clk (aif.clk),
    .rst (aif.rst)
  );
  fsm_healing_mac_fsm_controller fsm_dut(
    .clk(clk),
    .rst_n(rst_n),
    .mac_done(aif.mac_done),
    .error_flag(aif.error_flag),
    .heart_beat(aif.heart_beat),
    .fsm_state(aif.fsm_state),
    .error_detected(aif.error_detected),
    .fault_response(aif.fault_response),
    .valid_data(aif.valid_data),
    .signal_error(aif.signal_error)
  );

  initial begin
    rst = 1'b0;
    repeat (5) @(posedge clk);
    rst = 1'b1;
  end

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb);
    uvm_config_db #(virtual mac_if #(WIDTH, N))::set(null, "*", "aif", aif);
    run_test("my_test");
  end
endmodule
