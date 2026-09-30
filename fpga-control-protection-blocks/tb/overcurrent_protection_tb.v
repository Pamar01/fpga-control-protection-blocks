`timescale 1ns/1ps
// Self-checking testbench for overcurrent_protection.v
// Directed tests (no trip, delay reset, latching, clear, hold on invalid samples)
// followed by randomised stimulus compared cycle-by-cycle with a behavioural model.
module overcurrent_protection_tb;

    reg         clk;
    reg         rst_n;
    reg         sample_valid;
    reg  [11:0] current;
    reg  [11:0] threshold;
    reg  [7:0]  delay;
    reg         clear_trip;
    wire        alarm;
    wire        trip;

    overcurrent_protection dut (
        .clk(clk), .rst_n(rst_n), .sample_valid(sample_valid),
        .current(current), .threshold(threshold), .delay(delay),
        .clear_trip(clear_trip), .alarm(alarm), .trip(trip)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ---- behavioural model -------------------------------------------------
    integer m_cnt;
    reg     m_trip;
    integer errors;
    integer cycles;
    integer seed;
    integer n;
    reg [31:0] r;

    task model_reset;
        begin
            m_cnt  = 0;
            m_trip = 1'b0;
        end
    endtask

    // Drive one clock cycle (called at a falling edge, returns at the next one)
    task cycle;
        input        valid;
        input [11:0] cur;
        input [11:0] thr;
        input [7:0]  dly;
        input        clr;
        reg          over;
        begin
            sample_valid = valid;
            current      = cur;
            threshold    = thr;
            delay        = dly;
            clear_trip   = clr;

            over = (cur > thr);
            if (clr) m_trip = 1'b0;
            if (valid) begin
                if (over) begin
                    if ((m_cnt + 1) >= dly) m_trip = 1'b1;
                    if (m_cnt < 255) m_cnt = m_cnt + 1;
                end else begin
                    m_cnt = 0;
                end
            end

            @(negedge clk);
            cycles = cycles + 1;

            if (trip !== m_trip) begin
                errors = errors + 1;
                $display("FAIL: trip=%b expected=%b (cur=%0d thr=%0d delay=%0d time %0t)",
                         trip, m_trip, cur, thr, dly, $time);
            end
            if (alarm !== over) begin
                errors = errors + 1;
                $display("FAIL: alarm=%b expected=%b (cur=%0d thr=%0d)", alarm, over, cur, thr);
            end
        end
    endtask

    task expect_trip;
        input        value;
        input [255:0] msg;
        begin
            if (trip !== value) begin
                errors = errors + 1;
                $display("FAIL: %0s (trip=%b, expected %b)", msg, trip, value);
            end
        end
    endtask

    integer i;

    initial begin
        $dumpfile("overcurrent_protection_tb.vcd");
        $dumpvars(0, overcurrent_protection_tb);

        errors = 0; cycles = 0; seed = 2026;
        rst_n = 1'b0; sample_valid = 1'b0; current = 12'd0; threshold = 12'd1000;
        delay = 8'd3; clear_trip = 1'b0;
        model_reset;

        @(negedge clk);
        @(negedge clk);
        rst_n = 1'b1;
        @(negedge clk);

        // ---- Test 1: normal current never trips ----------------------------
        for (i = 0; i < 50; i = i + 1) cycle(1, 12'd900, 12'd1000, 8'd3, 1'b0);
        expect_trip(1'b0, "no trip below threshold");
        $display("Test 1 done: normal current");

        // ---- Test 2: short spike shorter than delay is ignored -------------
        cycle(1, 12'd1500, 12'd1000, 8'd3, 1'b0);
        cycle(1, 12'd1500, 12'd1000, 8'd3, 1'b0);
        cycle(1, 12'd500,  12'd1000, 8'd3, 1'b0);
        expect_trip(1'b0, "2-sample spike does not trip (delay=3)");
        $display("Test 2 done: short spike ignored");

        // ---- Test 3: persistent overcurrent trips after delay --------------
        cycle(1, 12'd1500, 12'd1000, 8'd3, 1'b0);
        cycle(1, 12'd1500, 12'd1000, 8'd3, 1'b0);
        expect_trip(1'b0, "not yet tripped after 2 samples");
        cycle(1, 12'd1500, 12'd1000, 8'd3, 1'b0);
        expect_trip(1'b1, "trips on 3rd consecutive sample");
        $display("Test 3 done: trip after delay");

        // ---- Test 4: trip is latched after current returns to normal -------
        for (i = 0; i < 10; i = i + 1) cycle(1, 12'd100, 12'd1000, 8'd3, 1'b0);
        expect_trip(1'b1, "trip stays latched");
        $display("Test 4 done: latching");

        // ---- Test 5: clear_trip resets the latch ---------------------------
        cycle(1, 12'd100, 12'd1000, 8'd3, 1'b1);
        expect_trip(1'b0, "clear_trip resets the trip");
        $display("Test 5 done: clear");

        // ---- Test 6: invalid samples hold state ----------------------------
        cycle(1, 12'd1500, 12'd1000, 8'd3, 1'b0);
        cycle(1, 12'd1500, 12'd1000, 8'd3, 1'b0);
        for (i = 0; i < 5; i = i + 1) cycle(0, 12'd4000, 12'd1000, 8'd3, 1'b0);
        expect_trip(1'b0, "invalid samples do not count");
        cycle(1, 12'd1500, 12'd1000, 8'd3, 1'b0);
        expect_trip(1'b1, "trips after 3rd VALID over-threshold sample");
        cycle(1, 12'd100, 12'd1000, 8'd3, 1'b1);
        $display("Test 6 done: sample_valid handling");

        // ---- Test 7: delay of 0 and 1 trip on the first sample -------------
        cycle(1, 12'd2000, 12'd1000, 8'd0, 1'b0);
        expect_trip(1'b1, "delay=0 trips immediately");
        cycle(1, 12'd100, 12'd1000, 8'd0, 1'b1);
        cycle(1, 12'd2000, 12'd1000, 8'd1, 1'b0);
        expect_trip(1'b1, "delay=1 trips immediately");
        cycle(1, 12'd100, 12'd1000, 8'd1, 1'b1);
        $display("Test 7 done: minimum delay");

        // ---- Test 8: async reset clears the latch --------------------------
        cycle(1, 12'd2000, 12'd1000, 8'd1, 1'b0);
        #1;
        rst_n = 1'b0;
        sample_valid = 1'b0;
        clear_trip   = 1'b0;
        #1;
        expect_trip(1'b0, "async reset clears trip");
        model_reset;
        @(negedge clk);
        rst_n = 1'b1;
        @(negedge clk);
        $display("Test 8 done: asynchronous reset");

        // ---- Test 9: randomised stimulus (fixed seed => repeatable) --------
        for (n = 0; n < 5000; n = n + 1) begin
            r = $random(seed);
            cycle(r[0] | r[1],            // valid most of the time
                  r[15:4],                // random current
                  12'd2048,               // fixed threshold
                  {5'd0, r[18:16]},       // delay 0..7
                  (r[23:20] == 4'd0));    // occasional clear
        end
        $display("Test 9 done: 5000 randomised cycles");

        if (errors == 0)
            $display("ALL TESTS PASSED (%0d cycles)", cycles);
        else
            $display("TESTS FAILED: %0d errors in %0d cycles", errors, cycles);
        $finish;
    end

endmodule
