`timescale 1ns/1ps

module tb_pe;

    localparam int DATA_WIDTH = 8;
    localparam int ACC_WIDTH  = 20;
    localparam int CLK_PERIOD = 10; // 100MHz test clock

    logic                   clk;
    logic                   rst_n;
    logic                   en;
    logic                   clear_acc;
    logic [DATA_WIDTH-1:0]  a;
    logic [DATA_WIDTH-1:0]  b;
    logic [ACC_WIDTH-1:0]   out;

    int errors;
    int test_num;

    // DUT instantiation
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
        .out(out)
    );

    // Clock generation
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Waveform dump
    initial begin
        $dumpfile("tb_pe.vcd");
        $dumpvars(0, tb_pe);
    end

    // Self-checking task using an immediate assertion
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

    initial begin
        errors    = 0;
        test_num  = 0;
        rst_n     = 0;
        en        = 0;
        clear_acc = 0;
        a = 0; b = 0;

        // --- Test 1: Reset behavior ---
        @(negedge clk);
        check_out(20'd0);

        // Release reset
        @(negedge clk);
        rst_n = 1;

        // --- Test 2: First MAC: 3 * 4 = 12 ---
        a = 8'd3; b = 8'd4; en = 1;
        @(negedge clk);
        check_out(20'd12);

        // --- Test 3: Accumulate: 12 + (5*2=10) = 22 ---
        a = 8'd5; b = 8'd2;
        @(negedge clk);
        check_out(20'd22);

        // --- Test 4: en=0, hold value ---
        en = 0;
        a = 8'd9; b = 8'd9;
        @(negedge clk);
        check_out(20'd22);

        // --- Test 5: re-enable: 22 + (9*9=81) = 103 ---
        en = 1;
        @(negedge clk);
        check_out(20'd103);

        // --- Test 6: clear_acc synchronously resets to 0 ---
        clear_acc = 1;
        @(negedge clk);
        check_out(20'd0);
        clear_acc = 0;

        // --- Test 7: Max operand values: 255 * 255 = 65025 ---
        a = 8'd255; b = 8'd255;
        @(negedge clk);
        check_out(20'd65025);

        // --- Test 8: Asynchronous reset mid-operation ---
        rst_n = 0;
        #1;
        check_out(20'd0);
        rst_n = 1;

        // --- Summary ---
        @(negedge clk);
        if (errors == 0)
            $display("\n=== ALL %0d TESTS PASSED ===\n", test_num);
        else
            $display("\n=== %0d OF %0d TESTS FAILED ===\n", errors, test_num);

        $finish;
    end

endmodule
