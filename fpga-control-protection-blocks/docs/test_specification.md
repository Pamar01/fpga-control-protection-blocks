# Test Specification

Simulator: Icarus Verilog (`make test`). All testbenches are self-checking and end with the line
`ALL TESTS PASSED` when every check succeeds.

## TS-1 PWM generator (`tb/pwm_deadtime_tb.v`)
| ID | Requirement | Method | Pass criterion |
|----|-------------|--------|----------------|
| TS-1.1 | FS-1.1 | Check every clock cycle of every configuration | No cycle with both outputs high |
| TS-1.2 | FS-1.2, FS-1.3 | Sweep duty 0..period+2 for dead = 0..3 and period = 16 and 10; count high cycles over 10 periods after settling | Counts equal 10 x expected per-period value |
| TS-1.3 | FS-1.4 | Included in the sweep (duty = 0, duty >= period) | Counts as specified |
| TS-1.4 | FS-1.5 | Set `en = 0` for 40 cycles | Both outputs low |

## TS-2 Overcurrent protection (`tb/overcurrent_protection_tb.v`)
| ID | Requirement | Method | Pass criterion |
|----|-------------|--------|----------------|
| TS-2.1 | FS-2.1 | 50 samples below threshold; then 3 consecutive samples above (delay = 3) | No trip below threshold; trip on 3rd sample |
| TS-2.2 | FS-2.2 | Two samples above, one below, delay = 3 | No trip |
| TS-2.3 | FS-2.3 | Current returns to normal after a trip | Trip stays set |
| TS-2.4 | FS-2.3 | Pulse `clear_trip` | Trip clears |
| TS-2.5 | FS-2.6 | 5 invalid samples between valid ones | Counter unchanged |
| TS-2.6 | FS-2.5 | delay = 0 and delay = 1 | Trip on first sample above threshold |
| TS-2.7 | reset | Assert `rst_n` low while tripped | Trip clears immediately |
| TS-2.8 | all | 5000 randomised cycles against a behavioural model, fixed seed | `trip` and `alarm` match every cycle |

## Results log (fill in after running `make test`)
| Date | Tool / version | PWM result | Overcurrent result | Notes |
|------|----------------|------------|--------------------|-------|
|      |                |            |                    |       |
