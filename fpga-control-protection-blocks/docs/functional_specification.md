# Functional Specification

Document status: draft 1.0. These blocks are simplified building blocks of the kind used in
power-converter control and protection FPGAs. They are educational designs and are not
certified for use in real protection systems.

## FS-1 PWM generator with dead-time (`rtl/pwm_deadtime.v`)

**Purpose:** drive the high-side and low-side switches of one converter leg from a single duty
command while guaranteeing a minimum gap (dead time) between one switch turning off and the
other turning on.

| Signal | Dir | Width | Description |
|--------|-----|-------|-------------|
| clk | in | 1 | System clock, all logic on rising edge |
| rst_n | in | 1 | Active-low asynchronous reset |
| en | in | 1 | Enable. When 0 both outputs are forced low (safe state) |
| period | in | 16 | PWM period in clock cycles (0 = invalid, outputs low) |
| duty | in | 16 | Clock cycles per period the raw command is high |
| dead | in | 8 | Dead time in clock cycles before each output turns on |
| pwm_hi | out | 1 | High-side gate command |
| pwm_lo | out | 1 | Low-side gate command |

Requirements:
- FS-1.1 `pwm_hi` and `pwm_lo` shall never be high in the same clock cycle.
- FS-1.2 Each output shall turn off immediately when its raw command ends and turn on `dead` clock cycles after its raw command begins.
- FS-1.3 In steady state, `pwm_hi` is high for `max(0, duty - dead)` cycles per period and `pwm_lo` for `max(0, period - duty - dead)` cycles per period (for 0 < duty < period).
- FS-1.4 `duty = 0` gives `pwm_hi = 0` and `pwm_lo = 1`; `duty >= period` gives `pwm_hi = 1` and `pwm_lo = 0`.
- FS-1.5 With `en = 0` or `period = 0` both outputs shall be low.

## FS-2 Overcurrent protection element (`rtl/overcurrent_protection.v`)

**Purpose:** detect a sustained overcurrent on a digitised current measurement and issue a
latched trip, as in a definite-time overcurrent relay function.

| Signal | Dir | Width | Description |
|--------|-----|-------|-------------|
| clk | in | 1 | System clock |
| rst_n | in | 1 | Active-low asynchronous reset (clears the trip latch) |
| sample_valid | in | 1 | Sample strobe. State is held when 0 |
| current | in | 12 | Current magnitude sample (unsigned) |
| threshold | in | 12 | Pick-up threshold |
| delay | in | 8 | Consecutive samples above threshold required to trip |
| clear_trip | in | 1 | Clears the trip latch |
| alarm | out | 1 | Combinational: `current > threshold` |
| trip | out | 1 | Latched trip output |

Requirements:
- FS-2.1 `trip` shall assert when `current > threshold` for `delay` consecutive valid samples.
- FS-2.2 A sample at or below the threshold shall reset the consecutive-sample counter.
- FS-2.3 `trip` shall remain latched until `clear_trip` (or reset); it shall not clear itself when the current falls.
- FS-2.4 If a trip condition and `clear_trip` occur in the same clock, the trip shall win.
- FS-2.5 `delay = 0` shall behave as `delay = 1`.
- FS-2.6 Invalid samples (`sample_valid = 0`) shall not change the counter or the trip state.
