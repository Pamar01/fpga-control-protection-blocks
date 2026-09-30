`timescale 1ns/1ps
// Self-checking testbench for pwm_deadtime.v
// For many (period, duty, dead) combinations it checks:
//   1. pwm_hi and pwm_lo are NEVER high in the same clock cycle (no shoot-through)
//   2. the number of high cycles per period matches the specification
//   3. both outputs are 0 while disabled
module pwm_deadtime_tb;

    reg         clk;
    reg         rst_n;
    reg         en;
    reg  [15:0] period;
    reg  [15:0] duty;
    reg  [7:0]  dead;
    wire        pwm_hi, pwm_lo;

    integer errors;
    integer configs;
    integer overlap_errors;

    pwm_deadtime dut (
        .clk(clk), .rst_n(rst_n), .en(en),
        .period(period), .duty(duty), .dead(dead),
        .pwm_hi(pwm_hi), .pwm_lo(pwm_lo)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // run one configuration and compare per-period high-cycle counts
    task run_config;
        input integer p;
        input integer d;
        input integer dt;
        integer n;
        integer hi_total, lo_total;
        integer exp_hi, exp_lo;
        begin
            @(negedge clk);
            rst_n  = 1'b0;
            en     = 1'b0;
            period = p;
            duty   = d;
            dead   = dt;
            @(negedge clk);
            @(negedge clk);
            rst_n  = 1'b1;
            en     = 1'b1;

            // let the output reach steady state
            repeat (3 * p) @(negedge clk);

            hi_total = 0;
            lo_total = 0;
            for (n = 0; n < 10 * p; n = n + 1) begin
                @(negedge clk);
                if (pwm_hi === 1'b1 && pwm_lo === 1'b1) begin
                    overlap_errors = overlap_errors + 1;
                    errors = errors + 1;
                    $display("FAIL: shoot-through (both outputs high) p=%0d d=%0d dead=%0d", p, d, dt);
                end
                if (pwm_hi === 1'b1) hi_total = hi_total + 1;
                if (pwm_lo === 1'b1) lo_total = lo_total + 1;
            end

            // expected number of high cycles per period
            if (d == 0) begin
                exp_hi = 0;
                exp_lo = p;
            end else if (d >= p) begin
                exp_hi = p;
                exp_lo = 0;
            end else begin
                exp_hi = (d > dt)       ? (d - dt)       : 0;
                exp_lo = ((p - d) > dt) ? (p - d - dt)   : 0;
            end

            configs = configs + 1;
            if (hi_total !== 10 * exp_hi || lo_total !== 10 * exp_lo) begin
                errors = errors + 1;
                $display("FAIL: p=%0d d=%0d dead=%0d | hi/period got %0d exp %0d | lo/period got %0d exp %0d",
                         p, d, dt, hi_total / 10, exp_hi, lo_total / 10, exp_lo);
            end
        end
    endtask

    integer pi, di, ti;
    integer plist [0:1];
    integer n;

    initial begin
        $dumpfile("pwm_deadtime_tb.vcd");
        $dumpvars(0, pwm_deadtime_tb);

        errors = 0; configs = 0; overlap_errors = 0;
        rst_n = 1'b0; en = 1'b0; period = 16'd16; duty = 16'd8; dead = 8'd2;
        plist[0] = 16;
        plist[1] = 10;

        // ---- sweep duty from 0 to period+2 for several dead times -----------
        for (pi = 0; pi < 2; pi = pi + 1) begin
            for (ti = 0; ti < 4; ti = ti + 1) begin
                for (di = 0; di <= plist[pi] + 2; di = di + 1) begin
                    run_config(plist[pi], di, ti);
                end
            end
            $display("Sweep done for period=%0d", plist[pi]);
        end

        // ---- disabled state: both outputs must stay low --------------------
        @(negedge clk);
        en = 1'b0;
        for (n = 0; n < 40; n = n + 1) begin
            @(negedge clk);
            if (pwm_hi !== 1'b0 || pwm_lo !== 1'b0) begin
                errors = errors + 1;
                $display("FAIL: outputs not low while disabled");
            end
        end
        $display("Disabled-state check done");

        if (errors == 0)
            $display("ALL TESTS PASSED (%0d configurations, 0 shoot-through cycles)", configs);
        else
            $display("TESTS FAILED: %0d errors (%0d shoot-through)", errors, overlap_errors);
        $finish;
    end

endmodule
