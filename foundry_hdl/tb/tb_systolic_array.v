`timescale 1ns/1ps

module tb_systolic_array;
    localparam N = 16;
    localparam K = 16;
    localparam CLK_PERIOD_NS = 10;
    localparam FLUSH_CYCLES = 2*N + K + 4;

    reg clk;
    reg rst;
    reg signed [N*8-1:0] a_row;
    reg signed [N*8-1:0] b_col;
    reg valid_in;

    wire signed [N*N*32-1:0] result;
    wire valid_out;

    reg signed [7:0]  A [0:N-1][0:N-1];
    reg signed [7:0]  B [0:N-1][0:N-1];
    reg signed [31:0] Cexp [0:N-1][0:N-1];

    integer i, j, k;
    integer fd;
    integer errors;
    integer cycle;
    integer start_cycle;
    integer last_valid_out_cycle;
    integer latency_cycles;
    real macs_per_cycle;
    time start_time;
    time last_valid_out_time;
    reg start_seen;

    systolic_array dut (
        .clk(clk),
        .rst(rst),
        .a_row(a_row),
        .b_col(b_col),
        .valid_in(valid_in),
        .result(result),
        .valid_out(valid_out)
    );

    always #(CLK_PERIOD_NS/2) clk = ~clk;

    always @(posedge clk) begin
        if (rst) begin
            cycle <= 0;
            start_seen <= 1'b0;
            start_cycle <= 0;
            last_valid_out_cycle <= 0;
            start_time <= 0;
            last_valid_out_time <= 0;
        end else begin
            cycle <= cycle + 1;
            if (valid_in && !start_seen) begin
                start_seen <= 1'b1;
                start_cycle <= cycle;
                start_time <= $time;
            end
            if (valid_out) begin
                last_valid_out_cycle <= cycle;
                last_valid_out_time <= $time;
            end
        end
    end

    task init_matrices;
    begin
        A[0][0] = 8'sd85;
        A[0][1] = -8'sd123;
        A[0][2] = 8'sd24;
        A[0][3] = 8'sd60;
        A[0][4] = -8'sd29;
        A[0][5] = 8'sd10;
        A[0][6] = 8'sd95;
        A[0][7] = -8'sd46;
        A[0][8] = 8'sd63;
        A[0][9] = -8'sd65;
        A[0][10] = 8'sd93;
        A[0][11] = 8'sd5;
        A[0][12] = -8'sd39;
        A[0][13] = -8'sd33;
        A[0][14] = 8'sd53;
        A[0][15] = -8'sd82;
        A[1][0] = 8'sd83;
        A[1][1] = -8'sd43;
        A[1][2] = -8'sd53;
        A[1][3] = -8'sd23;
        A[1][4] = -8'sd89;
        A[1][5] = -8'sd31;
        A[1][6] = 8'sd46;
        A[1][7] = 8'sd36;
        A[1][8] = -8'sd116;
        A[1][9] = 8'sd106;
        A[1][10] = 8'sd45;
        A[1][11] = -8'sd115;
        A[1][12] = 8'sd84;
        A[1][13] = -8'sd127;
        A[1][14] = -8'sd125;
        A[1][15] = -8'sd45;
        A[2][0] = -8'sd37;
        A[2][1] = 8'sd18;
        A[2][2] = -8'sd78;
        A[2][3] = 8'sd84;
        A[2][4] = -8'sd74;
        A[2][5] = -8'sd35;
        A[2][6] = 8'sd64;
        A[2][7] = -8'sd9;
        A[2][8] = 8'sd40;
        A[2][9] = -8'sd108;
        A[2][10] = -8'sd10;
        A[2][11] = -8'sd67;
        A[2][12] = 8'sd127;
        A[2][13] = -8'sd18;
        A[2][14] = -8'sd33;
        A[2][15] = 8'sd3;
        A[3][0] = 8'sd94;
        A[3][1] = -8'sd62;
        A[3][2] = -8'sd107;
        A[3][3] = -8'sd44;
        A[3][4] = 8'sd26;
        A[3][5] = -8'sd124;
        A[3][6] = -8'sd52;
        A[3][7] = -8'sd11;
        A[3][8] = 8'sd51;
        A[3][9] = 8'sd47;
        A[3][10] = -8'sd48;
        A[3][11] = 8'sd69;
        A[3][12] = 8'sd37;
        A[3][13] = -8'sd122;
        A[3][14] = -8'sd103;
        A[3][15] = -8'sd97;
        A[4][0] = 8'sd99;
        A[4][1] = -8'sd88;
        A[4][2] = 8'sd70;
        A[4][3] = -8'sd37;
        A[4][4] = -8'sd123;
        A[4][5] = 8'sd60;
        A[4][6] = -8'sd18;
        A[4][7] = -8'sd66;
        A[4][8] = 8'sd118;
        A[4][9] = -8'sd97;
        A[4][10] = -8'sd121;
        A[4][11] = 8'sd123;
        A[4][12] = 8'sd38;
        A[4][13] = 8'sd87;
        A[4][14] = -8'sd25;
        A[4][15] = 8'sd58;
        A[5][0] = -8'sd67;
        A[5][1] = -8'sd52;
        A[5][2] = -8'sd88;
        A[5][3] = 8'sd125;
        A[5][4] = -8'sd44;
        A[5][5] = 8'sd43;
        A[5][6] = -8'sd10;
        A[5][7] = -8'sd24;
        A[5][8] = -8'sd45;
        A[5][9] = -8'sd45;
        A[5][10] = 8'sd19;
        A[5][11] = -8'sd52;
        A[5][12] = -8'sd82;
        A[5][13] = -8'sd127;
        A[5][14] = -8'sd53;
        A[5][15] = -8'sd127;
        A[6][0] = 8'sd125;
        A[6][1] = -8'sd34;
        A[6][2] = -8'sd79;
        A[6][3] = 8'sd7;
        A[6][4] = 8'sd79;
        A[6][5] = -8'sd95;
        A[6][6] = 8'sd107;
        A[6][7] = 8'sd85;
        A[6][8] = -8'sd35;
        A[6][9] = -8'sd4;
        A[6][10] = -8'sd34;
        A[6][11] = -8'sd115;
        A[6][12] = 8'sd62;
        A[6][13] = 8'sd41;
        A[6][14] = -8'sd38;
        A[6][15] = 8'sd74;
        A[7][0] = -8'sd37;
        A[7][1] = -8'sd37;
        A[7][2] = -8'sd1;
        A[7][3] = 8'sd83;
        A[7][4] = 8'sd85;
        A[7][5] = 8'sd38;
        A[7][6] = -8'sd67;
        A[7][7] = -8'sd94;
        A[7][8] = 8'sd107;
        A[7][9] = -8'sd29;
        A[7][10] = -8'sd25;
        A[7][11] = -8'sd59;
        A[7][12] = -8'sd9;
        A[7][13] = 8'sd41;
        A[7][14] = 8'sd21;
        A[7][15] = -8'sd64;
        A[8][0] = -8'sd98;
        A[8][1] = 8'sd5;
        A[8][2] = 8'sd90;
        A[8][3] = -8'sd106;
        A[8][4] = 8'sd58;
        A[8][5] = -8'sd73;
        A[8][6] = -8'sd94;
        A[8][7] = -8'sd49;
        A[8][8] = 8'sd62;
        A[8][9] = -8'sd110;
        A[8][10] = 8'sd12;
        A[8][11] = 8'sd99;
        A[8][12] = 8'sd60;
        A[8][13] = 8'sd77;
        A[8][14] = 8'sd29;
        A[8][15] = 8'sd101;
        A[9][0] = 8'sd7;
        A[9][1] = 8'sd31;
        A[9][2] = 8'sd124;
        A[9][3] = 8'sd117;
        A[9][4] = -8'sd103;
        A[9][5] = 8'sd7;
        A[9][6] = 8'sd100;
        A[9][7] = -8'sd113;
        A[9][8] = -8'sd16;
        A[9][9] = 8'sd48;
        A[9][10] = -8'sd59;
        A[9][11] = -8'sd127;
        A[9][12] = -8'sd86;
        A[9][13] = -8'sd113;
        A[9][14] = -8'sd72;
        A[9][15] = -8'sd32;
        A[10][0] = 8'sd75;
        A[10][1] = 8'sd123;
        A[10][2] = -8'sd35;
        A[10][3] = 8'sd11;
        A[10][4] = 8'sd50;
        A[10][5] = -8'sd22;
        A[10][6] = 8'sd25;
        A[10][7] = 8'sd33;
        A[10][8] = 8'sd70;
        A[10][9] = -8'sd90;
        A[10][10] = 8'sd26;
        A[10][11] = 8'sd60;
        A[10][12] = -8'sd108;
        A[10][13] = 8'sd86;
        A[10][14] = -8'sd31;
        A[10][15] = -8'sd46;
        A[11][0] = -8'sd87;
        A[11][1] = -8'sd55;
        A[11][2] = 8'sd28;
        A[11][3] = -8'sd10;
        A[11][4] = 8'sd42;
        A[11][5] = 8'sd89;
        A[11][6] = -8'sd26;
        A[11][7] = -8'sd121;
        A[11][8] = -8'sd52;
        A[11][9] = -8'sd70;
        A[11][10] = -8'sd112;
        A[11][11] = 8'sd46;
        A[11][12] = 8'sd72;
        A[11][13] = 8'sd35;
        A[11][14] = -8'sd108;
        A[11][15] = -8'sd5;
        A[12][0] = -8'sd77;
        A[12][1] = 8'sd120;
        A[12][2] = -8'sd52;
        A[12][3] = -8'sd23;
        A[12][4] = 8'sd4;
        A[12][5] = 8'sd55;
        A[12][6] = -8'sd47;
        A[12][7] = 8'sd17;
        A[12][8] = -8'sd109;
        A[12][9] = -8'sd82;
        A[12][10] = -8'sd80;
        A[12][11] = -8'sd22;
        A[12][12] = 8'sd81;
        A[12][13] = -8'sd121;
        A[12][14] = -8'sd51;
        A[12][15] = 8'sd38;
        A[13][0] = -8'sd45;
        A[13][1] = 8'sd106;
        A[13][2] = 8'sd84;
        A[13][3] = 8'sd97;
        A[13][4] = -8'sd116;
        A[13][5] = 8'sd62;
        A[13][6] = -8'sd114;
        A[13][7] = 8'sd70;
        A[13][8] = 8'sd53;
        A[13][9] = -8'sd120;
        A[13][10] = 8'sd35;
        A[13][11] = 8'sd112;
        A[13][12] = 8'sd96;
        A[13][13] = -8'sd105;
        A[13][14] = 8'sd35;
        A[13][15] = 8'sd32;
        A[14][0] = 8'sd71;
        A[14][1] = 8'sd24;
        A[14][2] = -8'sd64;
        A[14][3] = 8'sd66;
        A[14][4] = -8'sd99;
        A[14][5] = -8'sd72;
        A[14][6] = 8'sd120;
        A[14][7] = -8'sd68;
        A[14][8] = -8'sd79;
        A[14][9] = -8'sd39;
        A[14][10] = -8'sd111;
        A[14][11] = -8'sd102;
        A[14][12] = 8'sd30;
        A[14][13] = -8'sd18;
        A[14][14] = -8'sd79;
        A[14][15] = 8'sd107;
        A[15][0] = 8'sd127;
        A[15][1] = 8'sd112;
        A[15][2] = -8'sd98;
        A[15][3] = 8'sd88;
        A[15][4] = -8'sd16;
        A[15][5] = -8'sd15;
        A[15][6] = 8'sd40;
        A[15][7] = -8'sd45;
        A[15][8] = 8'sd68;
        A[15][9] = -8'sd5;
        A[15][10] = 8'sd113;
        A[15][11] = -8'sd36;
        A[15][12] = -8'sd22;
        A[15][13] = -8'sd19;
        A[15][14] = -8'sd47;
        A[15][15] = 8'sd105;

        B[0][0] = -8'sd121;
        B[0][1] = -8'sd29;
        B[0][2] = -8'sd91;
        B[0][3] = -8'sd93;
        B[0][4] = -8'sd66;
        B[0][5] = -8'sd80;
        B[0][6] = 8'sd7;
        B[0][7] = -8'sd8;
        B[0][8] = -8'sd19;
        B[0][9] = 8'sd14;
        B[0][10] = -8'sd13;
        B[0][11] = 8'sd126;
        B[0][12] = 8'sd61;
        B[0][13] = 8'sd100;
        B[0][14] = 8'sd78;
        B[0][15] = -8'sd1;
        B[1][0] = 8'sd102;
        B[1][1] = -8'sd73;
        B[1][2] = -8'sd113;
        B[1][3] = 8'sd60;
        B[1][4] = -8'sd6;
        B[1][5] = 8'sd76;
        B[1][6] = 8'sd124;
        B[1][7] = -8'sd86;
        B[1][8] = 8'sd87;
        B[1][9] = 8'sd110;
        B[1][10] = -8'sd72;
        B[1][11] = 8'sd39;
        B[1][12] = -8'sd1;
        B[1][13] = 8'sd99;
        B[1][14] = 8'sd27;
        B[1][15] = 8'sd89;
        B[2][0] = -8'sd65;
        B[2][1] = -8'sd41;
        B[2][2] = -8'sd17;
        B[2][3] = 8'sd69;
        B[2][4] = 8'sd6;
        B[2][5] = -8'sd38;
        B[2][6] = -8'sd126;
        B[2][7] = 8'sd13;
        B[2][8] = -8'sd116;
        B[2][9] = 8'sd117;
        B[2][10] = 8'sd42;
        B[2][11] = -8'sd25;
        B[2][12] = 8'sd26;
        B[2][13] = -8'sd114;
        B[2][14] = 8'sd75;
        B[2][15] = 8'sd59;
        B[3][0] = -8'sd18;
        B[3][1] = 8'sd0;
        B[3][2] = -8'sd11;
        B[3][3] = -8'sd81;
        B[3][4] = -8'sd24;
        B[3][5] = 8'sd0;
        B[3][6] = -8'sd126;
        B[3][7] = -8'sd120;
        B[3][8] = -8'sd51;
        B[3][9] = -8'sd60;
        B[3][10] = 8'sd40;
        B[3][11] = -8'sd19;
        B[3][12] = -8'sd63;
        B[3][13] = 8'sd28;
        B[3][14] = 8'sd18;
        B[3][15] = -8'sd114;
        B[4][0] = -8'sd21;
        B[4][1] = 8'sd91;
        B[4][2] = 8'sd73;
        B[4][3] = 8'sd77;
        B[4][4] = 8'sd97;
        B[4][5] = 8'sd15;
        B[4][6] = 8'sd16;
        B[4][7] = -8'sd91;
        B[4][8] = 8'sd116;
        B[4][9] = 8'sd119;
        B[4][10] = -8'sd47;
        B[4][11] = 8'sd88;
        B[4][12] = -8'sd104;
        B[4][13] = -8'sd78;
        B[4][14] = -8'sd67;
        B[4][15] = 8'sd8;
        B[5][0] = 8'sd33;
        B[5][1] = 8'sd83;
        B[5][2] = 8'sd72;
        B[5][3] = 8'sd116;
        B[5][4] = -8'sd81;
        B[5][5] = 8'sd71;
        B[5][6] = -8'sd66;
        B[5][7] = 8'sd92;
        B[5][8] = -8'sd11;
        B[5][9] = -8'sd125;
        B[5][10] = 8'sd106;
        B[5][11] = -8'sd49;
        B[5][12] = -8'sd121;
        B[5][13] = 8'sd54;
        B[5][14] = -8'sd47;
        B[5][15] = 8'sd10;
        B[6][0] = -8'sd55;
        B[6][1] = 8'sd70;
        B[6][2] = -8'sd46;
        B[6][3] = 8'sd31;
        B[6][4] = 8'sd37;
        B[6][5] = 8'sd33;
        B[6][6] = 8'sd92;
        B[6][7] = -8'sd108;
        B[6][8] = 8'sd53;
        B[6][9] = -8'sd3;
        B[6][10] = 8'sd106;
        B[6][11] = -8'sd115;
        B[6][12] = 8'sd49;
        B[6][13] = 8'sd72;
        B[6][14] = 8'sd126;
        B[6][15] = -8'sd58;
        B[7][0] = 8'sd63;
        B[7][1] = 8'sd24;
        B[7][2] = -8'sd61;
        B[7][3] = 8'sd127;
        B[7][4] = 8'sd103;
        B[7][5] = -8'sd123;
        B[7][6] = 8'sd110;
        B[7][7] = 8'sd60;
        B[7][8] = -8'sd10;
        B[7][9] = 8'sd81;
        B[7][10] = 8'sd113;
        B[7][11] = -8'sd13;
        B[7][12] = 8'sd46;
        B[7][13] = 8'sd123;
        B[7][14] = 8'sd23;
        B[7][15] = -8'sd11;
        B[8][0] = 8'sd84;
        B[8][1] = 8'sd35;
        B[8][2] = -8'sd79;
        B[8][3] = -8'sd52;
        B[8][4] = -8'sd33;
        B[8][5] = -8'sd105;
        B[8][6] = -8'sd66;
        B[8][7] = 8'sd70;
        B[8][8] = -8'sd64;
        B[8][9] = 8'sd61;
        B[8][10] = -8'sd96;
        B[8][11] = -8'sd26;
        B[8][12] = -8'sd18;
        B[8][13] = -8'sd128;
        B[8][14] = -8'sd80;
        B[8][15] = 8'sd44;
        B[9][0] = 8'sd5;
        B[9][1] = -8'sd1;
        B[9][2] = 8'sd13;
        B[9][3] = 8'sd30;
        B[9][4] = 8'sd49;
        B[9][5] = 8'sd33;
        B[9][6] = 8'sd72;
        B[9][7] = -8'sd118;
        B[9][8] = -8'sd67;
        B[9][9] = 8'sd96;
        B[9][10] = 8'sd97;
        B[9][11] = 8'sd33;
        B[9][12] = -8'sd8;
        B[9][13] = 8'sd2;
        B[9][14] = -8'sd78;
        B[9][15] = -8'sd41;
        B[10][0] = 8'sd20;
        B[10][1] = -8'sd97;
        B[10][2] = -8'sd63;
        B[10][3] = -8'sd56;
        B[10][4] = -8'sd28;
        B[10][5] = 8'sd9;
        B[10][6] = -8'sd20;
        B[10][7] = 8'sd2;
        B[10][8] = 8'sd55;
        B[10][9] = -8'sd104;
        B[10][10] = -8'sd88;
        B[10][11] = -8'sd56;
        B[10][12] = -8'sd9;
        B[10][13] = -8'sd106;
        B[10][14] = -8'sd57;
        B[10][15] = -8'sd118;
        B[11][0] = -8'sd110;
        B[11][1] = -8'sd55;
        B[11][2] = 8'sd65;
        B[11][3] = 8'sd89;
        B[11][4] = 8'sd87;
        B[11][5] = -8'sd116;
        B[11][6] = -8'sd40;
        B[11][7] = -8'sd49;
        B[11][8] = -8'sd55;
        B[11][9] = 8'sd123;
        B[11][10] = -8'sd75;
        B[11][11] = 8'sd54;
        B[11][12] = -8'sd90;
        B[11][13] = -8'sd49;
        B[11][14] = -8'sd117;
        B[11][15] = -8'sd92;
        B[12][0] = 8'sd53;
        B[12][1] = -8'sd61;
        B[12][2] = 8'sd56;
        B[12][3] = 8'sd47;
        B[12][4] = -8'sd20;
        B[12][5] = 8'sd22;
        B[12][6] = -8'sd28;
        B[12][7] = 8'sd41;
        B[12][8] = 8'sd79;
        B[12][9] = -8'sd92;
        B[12][10] = 8'sd41;
        B[12][11] = -8'sd45;
        B[12][12] = 8'sd0;
        B[12][13] = 8'sd113;
        B[12][14] = -8'sd42;
        B[12][15] = -8'sd61;
        B[13][0] = 8'sd68;
        B[13][1] = -8'sd116;
        B[13][2] = 8'sd99;
        B[13][3] = -8'sd53;
        B[13][4] = 8'sd3;
        B[13][5] = -8'sd59;
        B[13][6] = -8'sd49;
        B[13][7] = 8'sd1;
        B[13][8] = 8'sd2;
        B[13][9] = 8'sd20;
        B[13][10] = -8'sd127;
        B[13][11] = 8'sd60;
        B[13][12] = 8'sd77;
        B[13][13] = -8'sd25;
        B[13][14] = 8'sd64;
        B[13][15] = -8'sd77;
        B[14][0] = -8'sd73;
        B[14][1] = -8'sd42;
        B[14][2] = 8'sd109;
        B[14][3] = -8'sd34;
        B[14][4] = -8'sd90;
        B[14][5] = -8'sd73;
        B[14][6] = -8'sd73;
        B[14][7] = 8'sd83;
        B[14][8] = -8'sd51;
        B[14][9] = -8'sd105;
        B[14][10] = 8'sd101;
        B[14][11] = -8'sd67;
        B[14][12] = 8'sd78;
        B[14][13] = 8'sd4;
        B[14][14] = 8'sd18;
        B[14][15] = -8'sd61;
        B[15][0] = -8'sd13;
        B[15][1] = -8'sd38;
        B[15][2] = -8'sd78;
        B[15][3] = 8'sd90;
        B[15][4] = -8'sd53;
        B[15][5] = 8'sd14;
        B[15][6] = -8'sd4;
        B[15][7] = -8'sd67;
        B[15][8] = 8'sd32;
        B[15][9] = 8'sd74;
        B[15][10] = 8'sd6;
        B[15][11] = -8'sd19;
        B[15][12] = 8'sd63;
        B[15][13] = 8'sd71;
        B[15][14] = 8'sd30;
        B[15][15] = -8'sd126;
    end
    endtask

    task compute_expected;
    begin
        for (i = 0; i < N; i = i + 1) begin
            for (j = 0; j < N; j = j + 1) begin
                Cexp[i][j] = 32'sd0;
            end
        end
        for (i = 0; i < N; i = i + 1) begin
            for (j = 0; j < N; j = j + 1) begin
                for (k = 0; k < K; k = k + 1) begin
                    Cexp[i][j] = Cexp[i][j] + $signed(A[i][k]) * $signed(B[k][j]);
                end
            end
        end
    end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        valid_in = 1'b0;
        a_row = {N*8{1'b0}};
        b_col = {N*8{1'b0}};

        init_matrices();
        compute_expected();

        $dumpfile("result.vcd");
        $dumpvars(0, tb_systolic_array);

        repeat (2) @(posedge clk);
        rst = 1'b0;

        for (k = 0; k < K; k = k + 1) begin
            @(negedge clk);
            for (i = 0; i < N; i = i + 1) begin
                a_row[i*8 +: 8] = A[i][k];
            end
            for (j = 0; j < N; j = j + 1) begin
                b_col[j*8 +: 8] = B[k][j];
            end
            valid_in = 1'b1;
        end

        @(negedge clk);
        valid_in = 1'b0;
        a_row = {N*8{1'b0}};
        b_col = {N*8{1'b0}};

        for (i = 0; i < FLUSH_CYCLES; i = i + 1) begin
            @(posedge clk);
        end

        fd = $fopen("result.txt", "w");
        for (i = 0; i < N; i = i + 1) begin
            for (j = 0; j < N; j = j + 1) begin
                $fdisplay(fd, "%0d", $signed(result[(i*N + j)*32 +: 32]));
            end
        end
        $fclose(fd);

        errors = 0;
        for (i = 0; i < N; i = i + 1) begin
            for (j = 0; j < N; j = j + 1) begin
                if ($signed(result[(i*N + j)*32 +: 32]) !== Cexp[i][j]) begin
                    if (errors == 0) begin
                        $display("Systolic array FAIL at [%0d][%0d]: got %0d expected %0d",
                                 i, j, $signed(result[(i*N + j)*32 +: 32]), Cexp[i][j]);
                    end
                    errors = errors + 1;
                end
            end
        end
        if (errors == 0) begin
            $display("Systolic array PASS - all elements match");
        end else begin
            $display("Systolic array FAIL - mismatches: %0d", errors);
        end

        latency_cycles = last_valid_out_cycle - start_cycle + 1;
        if (latency_cycles <= 0) latency_cycles = 1;
        macs_per_cycle = (N*N*K*1.0) / latency_cycles;

        fd = $fopen("bench.txt", "w");
        $fdisplay(fd, "N=%0d", N);
        $fdisplay(fd, "K=%0d", K);
        $fdisplay(fd, "cycles_total=%0d", cycle);
        $fdisplay(fd, "first_valid_in_cycle=%0d", start_cycle);
        $fdisplay(fd, "last_valid_out_cycle=%0d", last_valid_out_cycle);
        $fdisplay(fd, "latency_cycles=%0d", latency_cycles);
        $fdisplay(fd, "time_first_valid_ns=%0t", start_time);
        $fdisplay(fd, "time_last_valid_ns=%0t", last_valid_out_time);
        $fdisplay(fd, "time_window_ns=%0t", (last_valid_out_time - start_time));
        $fdisplay(fd, "total_macs=%0d", (N*N*K));
        $fdisplay(fd, "macs_per_cycle=%0f", macs_per_cycle);
        $fdisplay(fd, "clock_period_ns=%0d", CLK_PERIOD_NS);
        $fclose(fd);

        $finish;
    end
endmodule
