`timescale 1ns/1ps

// ============================================
// PE Module
// ============================================
module pe(clk, rst_n, clear_acc, a_in, b_in, valid_in,
          a_out, b_out, acc, valid_out);
  input  wire              clk;
  input  wire              rst_n;
  input  wire              clear_acc;
  input  wire signed [7:0] a_in;
  input  wire signed [7:0] b_in;
  input  wire              valid_in;
  output reg  signed [7:0] a_out;
  output reg  signed [7:0] b_out;
  output reg  signed [31:0] acc;
  output reg               valid_out;

  wire signed [15:0] product;
  assign product = a_in * b_in;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      a_out     <= 8'sd0;
      b_out     <= 8'sd0;
      acc       <= 32'sd0;
      valid_out <= 1'b0;
    end else begin
      a_out     <= a_in;
      b_out     <= b_in;
      valid_out <= valid_in;

      if (clear_acc) begin
        acc <= 32'sd0;
      end else if (valid_in) begin
        acc <= acc + {{16{product[15]}}, product};
      end
    end
  end
endmodule

// ============================================
// Systolic Array Core (16x16 PEs)
// ============================================
module systolic_array_core(clk, rst_n, clear_acc,
                           a_col_in,
                           b_row_in,
                           valid_in,
                           result,
                           valid_out);
  input  wire                clk;
  input  wire                rst_n;
  input  wire                clear_acc;
  input  wire [16*8-1:0]     a_col_in;
  input  wire [16*8-1:0]     b_row_in;
  input  wire                valid_in;
  output wire [16*16*32-1:0] result;
  output wire                valid_out;

  wire [16*17*8-1:0] a_pipe;
  wire [17*16*8-1:0] b_pipe;
  wire [16*17-1:0]   valid_pipe;

  genvar r;
  genvar c;

  generate
    for (r = 0; r < 16; r = r + 1) begin : input_rows
      assign a_pipe[(r*17)*8 +: 8] = a_col_in[r*8 +: 8];
      assign valid_pipe[r*17] = valid_in;
    end
    for (c = 0; c < 16; c = c + 1) begin : input_cols
      assign b_pipe[c*8 +: 8] = b_row_in[c*8 +: 8];
    end
  endgenerate

  generate
    for (r = 0; r < 16; r = r + 1) begin : pe_rows
      for (c = 0; c < 16; c = c + 1) begin : pe_cols
        pe u_pe (
          .clk(clk),
          .rst_n(rst_n),
          .clear_acc(clear_acc),
          .a_in(a_pipe[(r*17 + c)*8 +: 8]),
          .b_in(b_pipe[(r*16 + c)*8 +: 8]),
          .valid_in(valid_pipe[r*17 + c]),
          .a_out(a_pipe[(r*17 + c + 1)*8 +: 8]),
          .b_out(b_pipe[((r + 1)*16 + c)*8 +: 8]),
          .acc(result[(r*16 + c)*32 +: 32]),
          .valid_out(valid_pipe[r*17 + c + 1])
        );
      end
    end
  endgenerate

  assign valid_out = valid_pipe[15*17 + 16];
endmodule

// ============================================
// Testbench
// ============================================
module tb_systolic_16x16;
  localparam N = 16;
  localparam FEED_CYCLES = (N + N + N - 2);

  reg clk;
  reg rst_n;
  reg clear_acc;
  reg valid_in;
  reg [N*8-1:0] a_col_in;
  reg [N*8-1:0] b_row_in;
  wire [N*N*32-1:0] result;
  wire valid_out;

  reg signed [7:0] A [0:N-1][0:N-1];
  reg signed [7:0] B [0:N-1][0:N-1];
  reg signed [31:0] expected [0:N-1][0:N-1];

  // These arrays model the physical input skew registers that normally sit in
  // front of a systolic array. At logical feed cycle t, unskewed A[i][t]
  // enters row i's delay line and unskewed B[t][j] enters column j's delay
  // line. Row i is read from tap i, so A row i is delayed by i cycles. Column j
  // is read from tap j, so B column j is delayed by j cycles.
  //
  // The resulting array boundary wavefront is:
  //   Cycle 0:  A[0][0], B[0][0]
  //   Cycle 1:  A[0][1], A[1][0], B[0][1], B[1][0]
  //   Cycle 2:  A[0][2], A[1][1], A[2][0], B[0][2], B[1][1], B[2][0]
  //   ...
  //   Cycle 15: all 16 entries of the first full diagonal are present.
  reg signed [7:0] a_shift [0:N-1][0:N-1];
  reg signed [7:0] b_shift [0:N-1][0:N-1];

  integer i;
  integer j;
  integer k;
  integer t;
  integer cycles;
  integer total_cycles;
  integer all_passed;
  integer timeout;
  integer test_passed;
  integer failures;
  reg signed [31:0] got;
  reg signed [31:0] sum;
  reg signed [7:0] src_a;
  reg signed [7:0] src_b;

  systolic_array_core dut (
    .clk(clk),
    .rst_n(rst_n),
    .clear_acc(clear_acc),
    .a_col_in(a_col_in),
    .b_row_in(b_row_in),
    .valid_in(valid_in),
    .result(result),
    .valid_out(valid_out)
  );

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  task zero_inputs;
    begin
      a_col_in = {N*8{1'b0}};
      b_row_in = {N*8{1'b0}};
      valid_in = 1'b0;
    end
  endtask

  task reset_skew_registers;
    begin
      for (i = 0; i < N; i = i + 1) begin
        for (j = 0; j < N; j = j + 1) begin
          a_shift[i][j] = 8'sd0;
          b_shift[i][j] = 8'sd0;
        end
      end
    end
  endtask

  task clear_accumulators;
    begin
      @(negedge clk);
      clear_acc = 1'b1;
      zero_inputs();
      @(posedge clk);
      #1;
      @(negedge clk);
      clear_acc = 1'b0;
    end
  endtask

  task compute_expected;
    begin
      for (i = 0; i < N; i = i + 1) begin
        for (j = 0; j < N; j = j + 1) begin
          sum = 32'sd0;
          for (k = 0; k < N; k = k + 1) begin
            sum = sum + (A[i][k] * B[k][j]);
          end
          expected[i][j] = sum;
        end
      end
    end
  endtask

  task drive_skewed_cycle;
    input integer cycle_idx;
    begin
      // Shift each A row delay chain. For row i, tap i is driven into the left
      // edge of systolic row i. That makes A[i][k] enter at cycle i+k.
      for (i = 0; i < N; i = i + 1) begin
        if (cycle_idx < N) begin
          src_a = A[i][cycle_idx];
        end else begin
          src_a = 8'sd0;
        end
        for (k = N-1; k > 0; k = k - 1) begin
          a_shift[i][k] = a_shift[i][k-1];
        end
        a_shift[i][0] = src_a;
        a_col_in[i*8 +: 8] = a_shift[i][i];
      end

      // Shift each B column delay chain. For column j, tap j is driven into the
      // top edge of systolic column j. That makes B[k][j] enter at cycle j+k.
      for (j = 0; j < N; j = j + 1) begin
        if (cycle_idx < N) begin
          src_b = B[cycle_idx][j];
        end else begin
          src_b = 8'sd0;
        end
        for (k = N-1; k > 0; k = k - 1) begin
          b_shift[j][k] = b_shift[j][k-1];
        end
        b_shift[j][0] = src_b;
        b_row_in[j*8 +: 8] = b_shift[j][j];
      end

      valid_in = 1'b1;
    end
  endtask

  task run_feed;
    begin
      cycles = 0;
      timeout = 0;
      reset_skew_registers();

      for (t = 0; t < FEED_CYCLES; t = t + 1) begin
        if (cycles >= 5000) begin
          timeout = 1;
          t = FEED_CYCLES;
        end else begin
          @(negedge clk);
          drive_skewed_cycle(t);
          @(posedge clk);
          #1;
          cycles = cycles + 1;
        end
      end

      @(negedge clk);
      zero_inputs();
      repeat (4) @(posedge clk);
    end
  endtask

  task compare_results;
    input integer test_number;
    begin
      test_passed = 1;
      failures = 0;
      if (timeout) begin
        $display("TIMEOUT");
        test_passed = 0;
      end else begin
        for (i = 0; i < N; i = i + 1) begin
          for (j = 0; j < N; j = j + 1) begin
            got = result[(i*N + j)*32 +: 32];
            if (got !== expected[i][j]) begin
              test_passed = 0;
              failures = failures + 1;
              if (failures <= 16) begin
                $display("FAIL: Test %0d C[%0d][%0d] expected %0d received %0d",
                         test_number, i, j, expected[i][j], got);
              end
            end
          end
        end
        if (failures > 16) begin
          $display("FAIL: Test %0d had %0d total mismatches", test_number, failures);
        end
      end

      $display("Cycles: %0d", cycles);
      if (test_passed) begin
        $display("PASS");
      end else begin
        $display("FAIL");
        all_passed = 0;
      end
      total_cycles = total_cycles + cycles;
    end
  endtask

  task test_identity;
    begin
      for (i = 0; i < N; i = i + 1) begin
        for (j = 0; j < N; j = j + 1) begin
          A[i][j] = (i == j) ? 8'sd1 : 8'sd0;
          // Assigned into signed INT8 storage. Values above 127 wrap exactly
          // like real INT8 hardware data, so the expected matrix is the signed
          // INT8 interpretation of this pattern.
          B[i][j] = i*N + j + 1;
        end
      end
      compute_expected();
      clear_accumulators();
      run_feed();
      compare_results(1);
    end
  endtask

  task test_known_values;
    begin
      for (i = 0; i < N; i = i + 1) begin
        for (j = 0; j < N; j = j + 1) begin
          A[i][j] = i + 1;
          B[i][j] = j + 1;
          expected[i][j] = (i + 1) * (j + 1) * N;
        end
      end
      clear_accumulators();
      run_feed();
      compare_results(2);
    end
  endtask

  task test_pseudo_random;
    begin
      for (i = 0; i < N; i = i + 1) begin
        for (j = 0; j < N; j = j + 1) begin
          A[i][j] = (i*3 + j*2 + 1) % 127;
          B[i][j] = (i*2 + j*5 + 3) % 127;
        end
      end
      compute_expected();
      clear_accumulators();
      run_feed();
      compare_results(3);
    end
  endtask

  initial begin
    $dumpfile("systolic_16x16.vcd");
    $dumpvars(0, tb_systolic_16x16);

    rst_n = 1'b0;
    clear_acc = 1'b0;
    total_cycles = 0;
    all_passed = 1;
    zero_inputs();
    reset_skew_registers();

    $display("=== Foundry Systolic Array Testbench ===");
    $display("=== 16x16 INT8 Matrix Multiply ===");
    $display("");

    repeat (5) @(posedge clk);
    rst_n = 1'b1;
    repeat (2) @(posedge clk);

    $display("--- Test 1: Identity Matrix ---");
    test_identity();
    $display("");

    $display("--- Test 2: Known Values (A[i][j]=i+1, B[i][j]=j+1) ---");
    test_known_values();
    $display("");

    $display("--- Test 3: Pseudo-random Values ---");
    test_pseudo_random();
    $display("");

    if (all_passed) begin
      $display("=== ALL TESTS PASSED ===");
    end else begin
      $display("=== TESTS FAILED ===");
    end
    $display("Total cycles across all tests: %0d", total_cycles);
    $display("VCD written to systolic_16x16.vcd");
    $finish;
  end
endmodule
