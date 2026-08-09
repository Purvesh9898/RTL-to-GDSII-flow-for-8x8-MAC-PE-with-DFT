module pe #(
    parameter integer DATA_WIDTH = 8,
    parameter integer ACC_WIDTH  = 20
)(
    input  clk,
    input  rst_n,
    input  en,
    input  clear_acc,
    input  [DATA_WIDTH-1:0]  a,
    input  [DATA_WIDTH-1:0]  b,
    output [ACC_WIDTH-1:0]   out,

    // ---- DFT: scan chain ports ----
    input  scan_en,   // 1 = test/shift mode, 0 = normal functional mode
    input  scan_in,   // serial data in, shifted into acc[0] each cycle
    output scan_out   // serial data out, taken from acc[ACC_WIDTH-1]
);

    reg [ACC_WIDTH-1:0] acc;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc <= {ACC_WIDTH{1'b0}};
        end
        else if (scan_en) begin
            // Shift mode: acc becomes a shift register.
            // Each bit takes its neighbor's old value; bit 0 takes scan_in.
            acc <= {acc[ACC_WIDTH-2:0], scan_in};
        end
        else if (clear_acc) begin
            acc <= {ACC_WIDTH{1'b0}};
        end
        else if (en) begin
            acc <= acc + (a * b);
        end
    end

    assign out      = acc;
    assign scan_out = acc[ACC_WIDTH-1];

endmodule
