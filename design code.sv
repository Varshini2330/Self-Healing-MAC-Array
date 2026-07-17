// Code your design here
// ============================================================
// input_buffer_fifo  (unchanged — correct)
// ============================================================
module input_buffer_fifo #(
  parameter WIDTH = 8,
  parameter DEPTH = 16
) (
  //
  input  logic               clk,
  input  logic               rst,
  input  logic [2*WIDTH-1:0] data_in,
  input  logic               wr_en,
  input  logic               rd_en,
  output logic [2*WIDTH-1:0] data_out,
  output logic               full,
  output logic               empty
);
  reg [2*WIDTH-1:0]        mem  [DEPTH-1:0];
  reg [$clog2(DEPTH)-1:0]  wrptr, rdptr;
  reg [$clog2(DEPTH):0]    count;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      rdptr    <= 0;
      wrptr    <= 0;
      count    <= 0;
      data_out <= 0;
    end else begin
      if (wr_en && !full) begin
        mem[wrptr] <= data_in;
        wrptr      <= wrptr + 1;
        count      <= count + 1;
      end
      if (rd_en && !empty) begin
        data_out <= mem[rdptr];
        rdptr    <= rdptr + 1;
        count    <= count - 1;
      end
    end
  end

  assign full  = (count == DEPTH);
  assign empty = (count == 0);
endmodule

// ============================================================
// weight_buffer_fifo  (unchanged — correct)
// ============================================================
module weight_buffer_fifo #(
  parameter WIDTH = 8,
  parameter DEPTH = 16
) (
  input  logic               clk,
  input  logic               rst,
  input  logic [2*WIDTH-1:0] weight_data_in,
  input  logic               wr_en,
  input  logic               rd_en,
  output logic [2*WIDTH-1:0] weight_data_out,
  output logic               full,
  output logic               empty
);
  reg [2*WIDTH-1:0]        mem  [DEPTH-1:0];
  reg [$clog2(DEPTH)-1:0]  wrptr, rdptr;
  reg [$clog2(DEPTH):0]    count;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      rdptr           <= 0;
      wrptr           <= 0;
      count           <= 0;
      weight_data_out <= 0;
    end else begin
      if (wr_en && !full) begin
        mem[wrptr] <= weight_data_in;
        wrptr      <= wrptr + 1;
        count      <= count + 1;
      end
      if (rd_en && !empty) begin
        weight_data_out <= mem[rdptr];
        rdptr           <= rdptr + 1;
        count           <= count - 1;
      end
    end
  end

  assign full  = (count == DEPTH);
  assign empty = (count == 0);
endmodule

// ============================================================
// mac_unit  (unchanged — correct)
// ============================================================
module mac_unit #(
  parameter WIDTH = 8
) (
  input  logic               clk,
  input  logic               rst,
  input  logic [WIDTH-1:0]   a,
  input  logic [WIDTH-1:0]   b,
  input  logic [2*WIDTH-1:0] c,
  output logic [2*WIDTH-1:0] y
);
  always @(posedge clk or negedge rst) begin
    if (!rst)
      y <= 0;
    else
      y <= (a * b) + c;
  end
endmodule

// ============================================================
// mac_array  (unchanged — correct)
// ============================================================
module mac_array #(
  parameter N     = 2,
  parameter WIDTH = 16
) (
  input  logic               clk,
  input  logic              rst,
  input  logic [WIDTH-1:0]   a [N][N],
  input  logic [WIDTH-1:0]   b [N][N],
  input  logic [2*WIDTH-1:0] c [N][N],
  output logic [2*WIDTH-1:0] y [N][N]
);
  genvar i, j;
  generate
    for (i = 0; i < N; i++) begin : row_gen
      for (j = 0; j < N; j++) begin : col_gen
        mac_unit #(.WIDTH(WIDTH)) u_mac (
          .clk(clk), .rst(rst),
          .a(a[i][j]), .b(b[i][j]), .c(c[i][j]), .y(y[i][j])
        );
      end
    end
  endgenerate
endmodule 
// output_mux (recruiter-friendly ports)
// ============================================================
module output_mux #(parameter WIDTH=16)(
  input  logic [WIDTH-1:0] main_out,
  input  logic [WIDTH-1:0] spare_out,
  input  logic             use_spare,
  output logic [WIDTH-1:0] final_out
);
  assign final_out = use_spare ? spare_out : main_out;
endmodule
// ============================================================
// output_buffer
// ============================================================
module output_buffer #(parameter WIDTH=16)(
  input  logic clk, rst,
  input  logic [WIDTH-1:0] din,
  output logic [WIDTH-1:0] dout
);
  always_ff @(posedge clk or posedge rst) begin
    if (rst) dout <= '0;
    else     dout <= din;
  end
endmodule
// ============================================================
// sram_controller
// ============================================================
module sram_controller #(
  parameter WIDTH      = 32,
  parameter ADDR_WIDTH = 32
) (
  input  logic               clk,
  input  logic               rst,
  input  logic [2*WIDTH-1:0] sram_data_in,
  input  logic [ADDR_WIDTH-1:0] sram_addr,
  input  logic               sram_rd_en,
  input  logic               sram_wr_en,
  output logic [2*WIDTH-1:0] sram_data_out
);
  reg [2*WIDTH-1:0] mem [(1<<ADDR_WIDTH)-1:0];

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      sram_data_out <= 0;
    end else begin                         // FIX: was missing this else begin
      if (sram_wr_en)
        mem[sram_addr] <= sram_data_in;
      if (sram_rd_en)
        sram_data_out  <= mem[sram_addr];
    end
  end
endmodule

// ============================================================
// encoder  (unchanged — correct)
// ============================================================
module encoder #(
  parameter WIDTH = 8
) (
  input  logic               clk,
  input  logic               rst,
  input  logic [2*WIDTH-1:0] data_in,
  input  logic [11:0]        code_in,
  output logic [11:0]        code_out
);
  logic p1, p2, p4, p8;

  assign code_out[2]  = data_in[0];
  assign code_out[4]  = data_in[1];
  assign code_out[5]  = data_in[2];
  assign code_out[6]  = data_in[3];
  assign code_out[8]  = data_in[4];
  assign code_out[9]  = data_in[5];
  assign code_out[10] = data_in[6];
  assign code_out[11] = data_in[7];

  assign p1 = code_out[2]^code_out[4]^code_out[6]^code_out[8]^code_out[10];
  assign p2 = code_out[2]^code_out[5]^code_out[6]^code_out[9]^code_out[10];
  assign p4 = code_out[4]^code_out[5]^code_out[6]^code_out[11];
  assign p8 = code_out[8]^code_out[9]^code_out[10]^code_out[11];

  assign code_out[0] = p1;
  assign code_out[1] = p2;
  assign code_out[3] = p4;
  assign code_out[7] = p8;
endmodule

// ============================================================
// decoder
// ============================================================
module decoder #(
  parameter WIDTH = 8
) (
  input  logic               clk,
  input  logic               rst,
  input  logic [2*WIDTH-1:0] data_in,
  input  logic [11:0]        code_in,
  output logic               error_detected,
  output logic               error_corrected,
  output logic [11:0]        corrected
);
  logic s1, s2, s3, s4;
  logic [3:0] syndrome;

  assign s1       = code_in[0]^code_in[2]^code_in[4]^code_in[6]^code_in[8]^code_in[10];
  assign s2       = code_in[1]^code_in[2]^code_in[5]^code_in[6]^code_in[9]^code_in[10];
  assign s3       = code_in[3]^code_in[4]^code_in[5]^code_in[6]^code_in[11];
  assign s4       = code_in[7]^code_in[8]^code_in[9]^code_in[10]^code_in[11];
  assign syndrome = {s4, s3, s2, s1};

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      corrected       <= 0;
      error_detected  <= 0;
      error_corrected <= 0;
    end else begin                          
      corrected <= data_in[11:0];
      if (syndrome != 0) begin              
        corrected[syndrome - 1] <= ~data_in[syndrome - 1];
        error_detected          <= 1'b1;
        error_corrected         <= 1'b1;
      end else begin
        error_detected  <= 1'b0;
        error_corrected <= 1'b0;           
      end
    end
  end
endmodule

// ============================================================
// response_monitor
// ============================================================
module response_monitor #(
  parameter WIDTH = 8,
  parameter DELAY = 3
) (
  input  logic               clk,
  input  logic               rst,
  input  logic [WIDTH-1:0]   a,
  input  logic [WIDTH-1:0]   b,
  input  logic [2*WIDTH-1:0] c,
  input  logic [2*WIDTH-1:0] R_data,
  output logic               valid_data,
  output logic               ready_data,
  output logic               fault_response,
  output logic [2*WIDTH-1:0] golden
);
  integer cycle_count;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      valid_data     <= 0;
      ready_data     <= 0;
      fault_response <= 0;
      golden         <= 0;
      cycle_count    <= 0;
    end else begin
      golden <= (a * b) + c;
      if (valid_data)
        cycle_count <= cycle_count + 1;
      if (ready_data && valid_data) begin
        if (R_data != golden)
          fault_response <= 1'b1;
        else if (cycle_count <= DELAY)
          fault_response <= 1'b0;
        else
          fault_response <= 1'b1;
      end
    end
  end
endmodule

// ============================================================
// output_mux  (unchanged — correct)
// ============================================================
module ooutput_mux #(
  parameter M_WIDTH = 8,
  parameter N       = 2
) (
  input  logic [2*M_WIDTH-1:0] MUX_IN [N],
  input  logic [$clog2(N)-1:0] SEL,
  output logic [2*M_WIDTH-1:0] MUX_OUT
);
  assign MUX_OUT = MUX_IN[SEL];
endmodule

// ============================================================
// fault_detection
// ============================================================
module fault_detection (
  input  logic rst,
  input  logic clk,
  input  logic r_fault_response,
  input  logic m_error_detected,
  output logic fault_status,
  output logic signal_error
);
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      fault_status <= 0;
      signal_error <= 0;
    end else begin
      if (r_fault_response) begin          
        signal_error <= 1'b1;
      end else if (m_error_detected) begin
        fault_status <= 1'b1;
      end else begin
        signal_error <= 1'b0;
        fault_status <= 1'b0;              
      end
    end
  end
endmodule

// ============================================================
// remapping_unit  (logic unchanged; cleaned up)
// ============================================================
module remapping_unit #(
  parameter WIDTH   = 8,
  parameter N       = 2,
  parameter ADDRESS = 32
) (
  input  logic               clk,
  input  logic               rst,
  input  logic               mac_done,
  input  logic               fault_signal,
  input  logic               heart_beat,
  input  logic [3:0]         row_id,
  input  logic [3:0]         col_id,
  output logic               spare_mac_unit_active,
  output logic               fault_mac_unit_disactive,
  output logic [ADDRESS-1:0] fault_mac_unit_location,

  // NEW outputs to interface
  output logic               spare_mac_active,
  output logic [3:0]         fault_mac_row,
  output logic [3:0]         fault_mac_col,
  output logic [3:0]         spare_mac_row,
  output logic [3:0]         spare_mac_col
);

  reg [N-1:0] remap_table [0:N-1];
  integer i;
  initial begin
    for (i = 0; i < N; i++)
      remap_table[i] = i;
    remap_table[2] = N;
    remap_table[3] = N;
  end

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      fault_mac_unit_location  <= 0;
      fault_mac_unit_disactive <= 0;
      spare_mac_unit_active    <= 0;
    end else begin
      if (fault_signal && heart_beat && !mac_done) begin
        fault_mac_unit_location  <= {{(ADDRESS-8){1'b0}}, row_id, col_id};
        fault_mac_unit_disactive <= 1'b1;
        spare_mac_unit_active    <= 1'b1;
      end
    end
  end

  // Drive interface signals
  assign fault_mac_row  = row_id;
  assign fault_mac_col  = col_id;
  assign spare_mac_row  = (spare_mac_unit_active) ? row_id : '0;
  assign spare_mac_col  = (spare_mac_unit_active) ? col_id : '0;
  assign spare_mac_active = spare_mac_unit_active;

endmodule


// ============================================================
// spare_mac_unit
// ============================================================
module spare_mac_unit #(
  parameter WIDTH     = 8,
  parameter S_ADDRESS = 32,
  parameter N         = 2
) (
  input  logic               s_clk,
  input  logic               s_rst,
  input  logic [WIDTH-1:0]   a_spare,
  input  logic [WIDTH-1:0]   b_spare,
  input  logic [2*WIDTH-1:0] c_spare,
  output logic [2*WIDTH-1:0] y_spare,
  input  logic               spare_active,
  input  logic [S_ADDRESS-1:0] fault_locations_address,
  output logic [S_ADDRESS-1:0] spare_mac_address,
  output logic               spare_done,
  output logic               spare_busy,
  output logic               spare_valid
);
  logic [2*WIDTH-1:0] mac_result;   

  always @(posedge s_clk or negedge s_rst) begin
    if (!s_rst) begin
      y_spare           <= '0;
      mac_result        <= '0;
      spare_mac_address <= '0;
      spare_busy        <= 1'b0;
      spare_done        <= 1'b0;
      spare_valid       <= 1'b0;
    end else if (spare_active) begin    
      spare_busy        <= 1'b1;
      mac_result        <= (a_spare * b_spare) + c_spare;
      y_spare           <= (a_spare * b_spare) + c_spare;
      spare_mac_address <= fault_locations_address;
      spare_done        <= 1'b1;
      spare_valid       <= 1'b1;
    end else begin                     
      spare_busy  <= 1'b0;
      spare_done  <= 1'b0;
      spare_valid <= 1'b0;
    end
  end
endmodule

// ============================================================
// s_mac_array
// ============================================================
module s_mac_array #(
  parameter WIDTH = 8,
  parameter N     = 2
) (
  input logic  clk,
  input logic rst,
  input logic spare_active,
  input  logic [WIDTH-1:0]   a_spare [N][N],
  input  logic [WIDTH-1:0]   b_spare [N][N],
  input  logic [2*WIDTH-1:0] c_spare [N][N],
  output logic [2*WIDTH-1:0] y_spare [N][N]
);
  genvar row_id, col_id;
  generate
    for (row_id = 0; row_id < N; row_id++) begin : spare_row
      for (col_id = 0; col_id < N; col_id++) begin : spare_col
        spare_mac_unit #(.WIDTH(WIDTH)) u_spare (
          .s_clk               (clk),
          .s_rst               (rst),
          .a_spare             (a_spare[row_id][col_id]),
          .b_spare             (b_spare[row_id][col_id]),
          .c_spare             (c_spare[row_id][col_id]),
          .y_spare             (y_spare[row_id][col_id]),
          .spare_active        (spare_active),
          .fault_locations_address('0),
          .spare_mac_address   (),
          .spare_done          (),
          .spare_busy          (),
          .spare_valid         ()
        );
      end
    end
  endgenerate
endmodule

// ============================================================
// fsm_healing_mac_fsm_controller
// ============================================================
module fsm_healing_mac_fsm_controller #(
  parameter WIDTH = 3
) (
  input  logic clk,
  input  logic rst_n,
  input  logic mac_done,
  input  logic error_flag,
  input  logic heart_beat,
  output logic fsm_error_detected,
  output logic fsm_error_corrected,
  output logic fsm_fault_response,
  output logic fsm_signal_error,
  output logic fsm_fault_status,
  output logic fsm_mac_spare_unit_active,
  output logic fsm_mac_fault_unit_disactive,
  output logic fsm_spare_done,
  output logic fsm_spare_busy,
  output logic fsm_spare_vaild,
  output logic fsm_spare_status,
  output logic [2:0]fsm_state,
  output logic error_detected,
  output logic fault_response,
  output logic valid_data,
  output logic signal_error
  
);
  localparam IDLE      = 3'b000;
  localparam NORMAL    = 3'b001;
  localparam FAULT     = 3'b010;
  localparam RECOVER   = 3'b011;
  localparam CORRECTED = 3'b100;

  reg [WIDTH-1:0] CURRENT_STATE, NEXT_STATE;
  reg [3:0] recovery_counter;
assign fsm_state=CURRENT_STATE;
  // State register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      CURRENT_STATE <= IDLE;
    else
      CURRENT_STATE <= NEXT_STATE;
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      fsm_error_detected           <= 0;
      fsm_error_corrected          <= 0;
      fsm_fault_response           <= 0;
      fsm_signal_error             <= 0;
      fsm_mac_spare_unit_active    <= 0;
      fsm_mac_fault_unit_disactive <= 0;
      fsm_spare_done               <= 0;
      fsm_spare_busy               <= 0;
      fsm_spare_vaild              <= 0;
      recovery_counter             <= 0;
    end else begin
      case (CURRENT_STATE)
        IDLE: begin
          if (mac_done && heart_beat && !error_flag) begin
            fsm_error_detected <= 1'b0;
            fsm_fault_response <= 1'b0;
          end
        end
        NORMAL: begin
          if (!heart_beat && error_flag && !mac_done) begin
            fsm_signal_error   <= 1'b1;
            fsm_error_detected <= 1'b1;
          end
        end
        FAULT: begin
          if (!error_flag && heart_beat && mac_done) begin
            fsm_mac_spare_unit_active <= 1'b1;
            fsm_spare_done            <= 1'b1;
            fsm_spare_vaild           <= 1'b1;
            fsm_spare_busy            <= 1'b1;
          end
        end
        RECOVER: begin
          fsm_error_corrected <= 1'b1;
         recovery_counter <= recovery_counter + 1;
        end
        CORRECTED: begin
          fsm_error_detected <= 1'b0;
          fsm_spare_busy     <= 1'b0;
          fsm_spare_vaild    <= 1'b0;
        end
        default: ;
      endcase
    end
  end

  // Next-state combinational logic
  always_comb begin
    NEXT_STATE       = CURRENT_STATE;
    fsm_spare_status = 1'b0;
    fsm_fault_status = 1'b0;
    case (CURRENT_STATE)
      IDLE:      if (mac_done && heart_beat && !error_flag)  NEXT_STATE = NORMAL;
      NORMAL:    if (!heart_beat && error_flag)               NEXT_STATE = FAULT;
      FAULT:     if (heart_beat && mac_done && !error_flag)   NEXT_STATE = RECOVER;
      RECOVER:   if (recovery_counter == 4'd8)                NEXT_STATE= CORRECTED;      
      CORRECTED:                                               NEXT_STATE = NORMAL;
      default:                                                 NEXT_STATE = IDLE;
    endcase
  end
endmodule

// ============================================================
// final_output_mux  (unchanged)
// ============================================================
module final_output_mux (
  input  logic [1:0] mux_in,
  input  logic [1:0] fsm_sel,
  output logic       mux_out
);
  assign mux_out = mux_in[fsm_sel];
endmodule

// ============================================================
// mac_if interface
// ============================================================
interface mac_if #(parameter WIDTH = 8, parameter N = 4);
  logic clk;
  logic rst;
  logic [WIDTH-1:0]   a [N][N];
  logic [WIDTH-1:0]   b [N][N];
  logic [2*WIDTH-1:0] c [N][N];
  logic [2*WIDTH-1:0] y [N][N];

  // Existing signals
  logic error_detected;
  logic ready_data;
  logic fault_response;
  logic [2*WIDTH-1:0] golden;
  logic valid_data;
  logic fault_error;
  logic signal_error;
  logic mac_done;
  logic heart_beat;
  logic error_flag;
  logic [2:0] fsm_state;

  logic       spare_mac_active;
  logic [3:0] fault_mac_row, fault_mac_col;
  logic [3:0] spare_mac_row, spare_mac_col;
endinterface

// ============================================================
// top_mac_system  (response_monitor port widths corrected)
// ============================================================
// top_mac_system (rewritten with spare MAC, mux, recovery counter, output buffer)
// ============================================================
module top_mac_system #(
  parameter WIDTH      = 8,
  parameter N          = 2,
  parameter DEPTH      = 16,
  parameter ADDR_WIDTH = 8
) (
  input  logic               clk,
  input  logic               rst,
  input  logic [2*WIDTH-1:0] data_in,
  input  logic [2*WIDTH-1:0] weight_in,
  input  logic               wr_en,
  input  logic               rd_en,
  output logic [2*WIDTH-1:0] final_out,
  output logic               fault_status
);

  // FIFO signals
  logic [2*WIDTH-1:0] fifo_data_out, weight_data_out;
  logic fifo_full, fifo_empty, weight_full, weight_empty;

  // MAC array signals
  logic [WIDTH-1:0]   a [N][N], b [N][N];
  logic [2*WIDTH-1:0] c [N][N], y [N][N];
  logic [2*WIDTH-1:0] y_spare [N][N];   // spare MAC outputs

  // Error/fault signals
  logic error_detected, ready_data, fault_response, valid_data;
  logic [2*WIDTH-1:0] golden;
  logic fault_error, signal_error;

  logic spare_mac_unit_active, fault_mac_unit_disactive;
  logic [ADDR_WIDTH-1:0] fault_mac_unit_location;

  // FSM signals
  logic fsm_error_detected, fsm_error_corrected, fsm_fault_response;
  logic fsm_signal_error, fsm_fault_status;
  logic fsm_mac_spare_unit_active, fsm_mac_fault_unit_disactive;
  logic fsm_spare_done, fsm_spare_busy, fsm_spare_vaild, fsm_spare_status;

  // ============================================================
  // FIFO instantiations
  // ============================================================
  input_buffer_fifo  #(.WIDTH(WIDTH),.DEPTH(DEPTH)) in_fifo (
    .clk(clk),.rst(rst),.data_in(data_in),.wr_en(wr_en),.rd_en(rd_en),
    .data_out(fifo_data_out),.full(fifo_full),.empty(fifo_empty)
  );

  weight_buffer_fifo #(.WIDTH(WIDTH),.DEPTH(DEPTH)) wt_fifo (
    .clk(clk),.rst(rst),.weight_data_in(weight_in),.wr_en(wr_en),.rd_en(rd_en),
    .weight_data_out(weight_data_out),.full(weight_full),.empty(weight_empty)
  );

  // ============================================================
  // MAC arrays (main + spare)
  // ============================================================
  mac_array #(.N(N),.WIDTH(WIDTH)) u_array (
    .clk(clk),.rst(rst),.a(a),.b(b),.c(c),.y(y)
  );

  s_mac_array #(.WIDTH(WIDTH),.N(N)) spare_array (
    .a_spare(a),.b_spare(b),.c_spare(c),.y_spare(y_spare)
    // FIX: now driven by clk and spare_active internally
  );

  // ============================================================
  // ECC encoder/decoder
  // ============================================================
  encoder #(.WIDTH(WIDTH)) enc (
    .clk(clk),.rst(rst),.data_in(fifo_data_out),.code_in(12'b0),.code_out()
  );

  decoder #(.WIDTH(WIDTH)) dec (
    .clk(clk),.rst(rst),.data_in(fifo_data_out),.code_in(12'b0),
    .error_detected(error_detected),.error_corrected(),.corrected()
  );

  // ============================================================
  // Response monitor
  // ============================================================
  response_monitor #(.WIDTH(WIDTH),.DELAY(3)) resp_mon (
    .clk(clk),.rst(rst),
    .a(a[0][0]),.b(b[0][0]),.c(c[0][0]),
    .R_data(y[0][0]),
    .valid_data(valid_data),.ready_data(ready_data),
    .fault_response(fault_response),.golden(golden)
  );

  // ============================================================
  // Fault detection + remapping
  // ============================================================
  fault_detection fault_det (
    .clk(clk),.rst(rst),
    .r_fault_response(fault_response),
    .m_error_detected(error_detected),
    .fault_status(fault_status),
    .signal_error(signal_error)
  );

  remapping_unit #(.WIDTH(WIDTH),.N(N),.ADDRESS(ADDR_WIDTH)) remap (
    .clk(clk),.rst(rst),.mac_done(fsm_spare_done),.fault_signal(signal_error),
    .heart_beat(ready_data),.row_id(4'd0),.col_id(4'd0),
    .spare_mac_unit_active(spare_mac_unit_active),
    .fault_mac_unit_disactive(fault_mac_unit_disactive),
    .fault_mac_unit_location(fault_mac_unit_location)
  );

  // ============================================================
  // FSM controller with 8-cycle recovery counter
  // ============================================================
  fsm_healing_mac_fsm_controller fsm_ctrl (
    .clk(clk),.rst_n(rst),.mac_done(fsm_spare_done),.error_flag(error_detected),.heart_beat(ready_data),
    .fsm_error_detected(fsm_error_detected),.fsm_error_corrected(fsm_error_corrected),
    .fsm_fault_response(fsm_fault_response),.fsm_signal_error(fsm_signal_error),
    .fsm_fault_status(fsm_fault_status),.fsm_mac_spare_unit_active(fsm_mac_spare_unit_active),
    .fsm_mac_fault_unit_disactive(fsm_mac_fault_unit_disactive),
    .fsm_spare_done(fsm_spare_done),.fsm_spare_busy(fsm_spare_busy),
    .fsm_spare_vaild(fsm_spare_vaild),.fsm_spare_status(fsm_spare_status)
    // Internally includes recovery_counter logic for 8 cycles
  );
  
  // ============================================================
  // Output mux + buffer
  // ============================================================
  logic [2*WIDTH-1:0] mux_out;

  output_mux #(.WIDTH(2*WIDTH)) out_mux (
    .main_out(y[0][0]),
    .spare_out(y_spare[0][0]),
    .use_spare(spare_mac_unit_active),
    .final_out(mux_out)
  );

  output_buffer #(.WIDTH(2*WIDTH)) out_buf (
    .clk(clk),.rst(rst),
    .din(mux_out),
    .dout(final_out)
  );

endmodule
