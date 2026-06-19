// Processing element: signed 8-bit MAC with passthrough.
module pe (
    input  wire               clk,
    input  wire               rst,
    input  wire signed [7:0]   a_in,
    input  wire signed [7:0]   b_in,
    input  wire               valid_in,
    output reg  signed [7:0]   a_out,
    output reg  signed [7:0]   b_out,
    output reg  signed [31:0]  acc,
    output reg                valid_out
);

    always @(posedge clk) begin
        if (rst) begin
            acc       <= 32'sd0;
            a_out     <= 8'sd0;
            b_out     <= 8'sd0;
            valid_out <= 1'b0;
        end else begin
            acc       <= acc + (a_in * b_in);
            a_out     <= a_in;
            b_out     <= b_in;
            valid_out <= valid_in;
        end
    end

endmodule
