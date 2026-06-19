// 16x16 systolic array for matrix multiply.
module systolic_array (
    input  wire                     clk,
    input  wire                     rst,
    input  wire signed [16*8-1:0]   a_row,
    input  wire signed [16*8-1:0]   b_col,
    input  wire                     valid_in,
    output wire signed [16*16*32-1:0] result,
    output wire                     valid_out
);
    localparam N = 16;

    // Internal wires for PE connections.
    wire signed [7:0]  a_wire [0:N-1][0:N-1];
    wire signed [7:0]  b_wire [0:N-1][0:N-1];
    wire signed [7:0]  a_out  [0:N-1][0:N-1];
    wire signed [7:0]  b_out  [0:N-1][0:N-1];
    wire signed [31:0] acc    [0:N-1][0:N-1];
    wire               v_in   [0:N-1][0:N-1];
    wire               v_out  [0:N-1][0:N-1];

    // Input skewing registers: A delayed by row index, B delayed by column index.
    // This creates the diagonal wavefront needed for correct systolic dataflow.
    // Step-by-step skewing:
    // 1) a_row provides one element per row each cycle (A[k][row]).
    // 2) To align A for PE[row][col], we delay the stream by `row` cycles so
    //    that A[k][row] arrives at column 0 at time t = k + row.
    // 3) Similarly, b_col provides one element per column each cycle (B[col][k]).
    // 4) We delay each column stream by `col` cycles so B[col][k] arrives at row 0
    //    at time t = k + col.
    // 5) With both delays, PE[i][j] receives A[k][i] and B[j][k] in the same cycle
    //    (t = k + i + j), enabling correct accumulation.
    reg signed [7:0] a_skew [0:N-1][0:N-1];
    reg signed [7:0] b_skew [0:N-1][0:N-1];
    reg              v_skew [0:N-1][0:N-1];

    integer i, j;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                for (j = 0; j < N; j = j + 1) begin
                    a_skew[i][j] <= 8'sd0;
                    b_skew[i][j] <= 8'sd0;
                    v_skew[i][j] <= 1'b0;
                end
            end
        end else begin
            // Shift A skew registers for each row (delay by row index).
            for (i = 0; i < N; i = i + 1) begin
                a_skew[i][0] <= a_row[i*8 +: 8];
                v_skew[i][0] <= valid_in;
                for (j = 1; j < N; j = j + 1) begin
                    a_skew[i][j] <= a_skew[i][j-1];
                    v_skew[i][j] <= v_skew[i][j-1];
                end
            end
            // Shift B skew registers for each column (delay by column index).
            for (j = 0; j < N; j = j + 1) begin
                b_skew[j][0] <= b_col[j*8 +: 8];
                for (i = 1; i < N; i = i + 1) begin
                    b_skew[j][i] <= b_skew[j][i-1];
                end
            end
        end
    end

    // Connect skewed inputs into the array.
    // Generate-if used (not ternary) to avoid out-of-bounds X warnings when c=0 or r=0.
    generate
        genvar r, c;
        for (r = 0; r < N; r = r + 1) begin : gen_rows
            for (c = 0; c < N; c = c + 1) begin : gen_cols
                if (c == 0) begin : a_first_col
                    // Row-r stream delayed by r cycles enters column 0.
                    assign a_wire[r][c] = a_skew[r][r];
                    assign v_in[r][c]   = v_skew[r][r];
                end else begin : a_other_col
                    // a_out propagates right one column per cycle.
                    assign a_wire[r][c] = a_out[r][c-1];
                    assign v_in[r][c]   = v_out[r][c-1];
                end
                if (r == 0) begin : b_first_row
                    // Col-c stream delayed by c cycles enters row 0.
                    assign b_wire[r][c] = b_skew[c][c];
                end else begin : b_other_row
                    // b_out propagates down one row per cycle.
                    assign b_wire[r][c] = b_out[r-1][c];
                end
                pe u_pe (
                    .clk(clk),
                    .rst(rst),
                    .a_in(a_wire[r][c]),
                    .b_in(b_wire[r][c]),
                    .valid_in(v_in[r][c]),
                    .a_out(a_out[r][c]),
                    .b_out(b_out[r][c]),
                    .acc(acc[r][c]),
                    .valid_out(v_out[r][c])
                );
                assign result[(r*N + c)*32 +: 32] = acc[r][c];
            end
        end
    endgenerate

    // valid_out asserts after full wavefront reaches bottom-right.
    assign valid_out = v_out[N-1][N-1];

endmodule
