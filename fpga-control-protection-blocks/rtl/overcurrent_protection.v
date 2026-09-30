// -----------------------------------------------------------------------------
// Overcurrent protection element (definite-time)
//
// A digitised current magnitude is compared with a threshold. If the current is
// above the threshold for `delay` CONSECUTIVE valid samples, `trip` is asserted
// and LATCHED until `clear_trip` is pulsed (a trip stays set even if the current
// returns to normal, as in real protection relays).
//
//  alarm : combinational flag, high while current > threshold
//  trip  : latched trip output
//  delay = 0 behaves like delay = 1 (trip on the first sample above threshold)
//  If a trip condition and clear_trip occur in the same clock, the trip wins.
//  Samples are only evaluated when sample_valid = 1; otherwise state is held.
// -----------------------------------------------------------------------------
module overcurrent_protection (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        sample_valid,
    input  wire [11:0] current,
    input  wire [11:0] threshold,
    input  wire [7:0]  delay,
    input  wire        clear_trip,
    output wire        alarm,
    output reg         trip
);

    reg [7:0] over_cnt;

    assign alarm = (current > threshold);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            over_cnt <= 8'd0;
            trip     <= 1'b0;
        end else begin
            if (clear_trip)
                trip <= 1'b0;

            if (sample_valid) begin
                if (current > threshold) begin
                    if ((over_cnt + 1) >= delay)
                        trip <= 1'b1;
                    if (over_cnt != 8'hFF)
                        over_cnt <= over_cnt + 8'd1;
                end else begin
                    over_cnt <= 8'd0;
                end
            end
        end
    end

endmodule
