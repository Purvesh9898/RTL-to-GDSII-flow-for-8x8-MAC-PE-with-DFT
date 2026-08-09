`timescale 1ns/1ps

module tb_pe;

    localparam int DATA_WIDTH = 8;
    localparam int ACC_WIDTH  = 20;
    localparam int CLK_PERIOD = 10;

    logic                   clk;
    logic                   rst_n;
    logic                   en;
    logic                   clear_acc;
    logic [DATA_WIDTH-1:0]  a;
    logic [DATA_WIDTH-1:0]  b;
    logic [ACC_WIDTH-1:0]   out;
    logic [19:0]             scan_pattern;
    logic                   scan_en;
    logic                   scan_in;
    logic                   scan_out;
    int errors;
    int test_num;

    pe #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .clear_acc(clear_acc),
        .a(a),
        .b(b),
        .out(out),
        .scan_en(scan_en),
        .scan_in(scan_in),
        .scan_out(scan_out)
    );

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        $dumpfile("tb_pe.vcd");
        $dumpvars(0, tb_pe);
    end

    task automatic check_out(input logic [ACC_WIDTH-1:0] expected);
        test_num++;
        assert (out === expected) begin
            $display("[PASS] Test %0d @ time %0t: out=%0d as expected",
                      test_num, $time, out);
        end else begin
            $error("[FAIL] Test %0d @ time %0t: out=%0d expected=%0d",
                    test_num, $time, out, expected);
            errors++;
        end
    endtask

    task automatic check_bit(input logic actual, input logic expected, input string label);
        test_num++;
        assert (actual === expected) begin
            $display("[PASS] Test %0d @ time %0t: %s=%b as expected",
                      test_num, $time, label, actual);
        end else begin
            $error("[FAIL] Test %0d @ time %0t: %s=%b expected=%b",
                    test_num, $time, label, actual, expected);
            errors++;
        end
    endtask

    initial begin
        errors    = 0;
        test_num  = 0;
        rst_n     = 0;
        en        = 0;
        clear_acc = 0;
        scan_en   = 0;
        scan_in   = 0;
        a = 0; b = 0;

        // --- Functional tests (unchanged from before) ---
        @(negedge clk);
        check_out(20'd0);

        @(negedge clk);
        rst_n = 1;

        a = 8'd3; b = 8'd4; en = 1;
        @(negedge clk);
        check_out(20'd12);

        a = 8'd5; b = 8'd2;
        @(negedge clk);
        check_out(20'd22);

        en = 0;
        a = 8'd9; b = 8'd9;
        @(negedge clk);
        check_out(20'd22);

        en = 1;
        @(negedge clk);
        check_out(20'd103);

        clear_acc = 1;
        @(negedge clk);
        check_out(20'd0);
        clear_acc = 0;

        // --- NEW: Scan chain test ---
        // Reset to a known state first
        rst_n = 0;
        @(negedge clk);
        rst_n = 1;
        en = 0;

scan_pattern = 20'b10101100111100001101;
        scan_en = 1;
        for (int i = 19; i >= 0; i--) begin
            scan_in = scan_pattern[i];
            @(negedge clk);
        end
        scan_en = 0;

        check_out(scan_pattern);
   
        // --- NEW: Confirm functional mode still works after a scan test ---
        // (this is a REAL DFT concern: does exiting scan mode cleanly
        // restore normal function, or does state leak/corrupt?)
        clear_acc = 1;
        @(negedge clk);
        check_out(20'd0);
        clear_acc = 0;

        a = 8'd6; b = 8'd7; en = 1;
        @(negedge clk);
        check_out(20'd42);

        // --- Summary ---
        @(negedge clk);
        if (errors == 0)
            $display("\n=== ALL %0d TESTS PASSED ===\n", test_num);
        else
            $display("\n=== %0d OF %0d TESTS FAILED ===\n", errors, test_num);

        $finish;
    end

endmodule
