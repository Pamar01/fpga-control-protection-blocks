// -----------------------------------------------------------------------------
// PWM generator with dead-time insertion (complementary outputs)
//
// Used to drive the high-side and low-side switches of one converter leg.
// Dead time prevents both switches conducting at once (shoot-through).
//
//  period : PWM period in clock cycles (must be >= 1)
//  duty   : number of clock cycles per period the "raw" signal is high
//  dead   : dead time in clock cycles inserted before EACH output turns on
//
//  pwm_hi turns off immediately when the raw signal falls and turns on `dead`
//  cycles after it rises. pwm_lo does the opposite. The two outputs are never
//  high in the same clock cycle.
//
//  Special cases:  duty = 0        -> pwm_hi always 0, pwm_lo always 1
//                  duty >= period -> pwm_hi always 1, pwm_lo always 0
//                  en = 0 or period = 0 -> both outputs 0 (safe state)
// -----------------------------------------------------------------------------
module pwm_deadtime (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire [15:0] period,
    input  wire [15:0] duty,
    input  wire [7:0]  dead,
    output wire        pwm_hi,
    output wire        pwm_lo
);

    reg [15:0] cnt;
    reg [7:0]  hi_cnt;
    reg [7:0]  lo_cnt;

    wire active = en && (period != 16'd0);
    wire raw    = (cnt < duty);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt    <= 16'd0;
            hi_cnt <= 8'd0;
            lo_cnt <= 8'd0;
        end else if (!active) begin
            // disabled: hold the counters cleared (outputs are forced low below)
            cnt    <= 16'd0;
            hi_cnt <= 8'd0;
            lo_cnt <= 8'd0;
        end else begin
            if (cnt >= period - 16'd1)
                cnt <= 16'd0;
            else
                cnt <= cnt + 16'd1;

            if (raw) begin
                lo_cnt <= 8'd0;
                if (hi_cnt < dead) hi_cnt <= hi_cnt + 8'd1;
            end else begin
                hi_cnt <= 8'd0;
                if (lo_cnt < dead) lo_cnt <= lo_cnt + 8'd1;
            end
        end
    end

    assign pwm_hi = active &&  raw && (hi_cnt >= dead);
    assign pwm_lo = active && !raw && (lo_cnt >= dead);

endmodule
