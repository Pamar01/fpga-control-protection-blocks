# FPGA Control and Protection Building Blocks (Verilog)

Two small, synthesizable Verilog blocks of the kind used in power-converter control and
protection FPGAs (for example in HVDC converter controllers), each with a functional
specification, a test specification, a self-checking testbench and automated simulation in CI.

| Block | File | Summary |
|-------|------|---------|
| PWM with dead-time | `rtl/pwm_deadtime.v` | Complementary high/low-side gate commands with programmable period, duty and dead time; no shoot-through |
| Overcurrent protection | `rtl/overcurrent_protection.v` | Definite-time overcurrent element with consecutive-sample delay and latched trip |

## Documentation
- `docs/functional_specification.md`: ports and numbered requirements
- `docs/test_specification.md`: test cases traced to requirements, plus a results log

## Verification
- **PWM:** sweeps period, duty (including the 0 and 100% edge cases) and dead time; checks
  there is never a cycle with both outputs high and that per-period on-times match the spec.
- **Overcurrent:** directed tests (spike ignored, delay, latch, clear, invalid samples, reset)
  plus 5000 randomised cycles compared with a behavioural model.

## Run
Install [Icarus Verilog](https://steveicarus.github.io/iverilog/) (`sudo apt-get install iverilog`,
`brew install icarus-verilog`, or the Windows installer), then:

```bash
make test        # both testbenches
make test-pwm
make test-oc
make clean
```
Waveforms are written as `.vcd` files in `build/` (open with GTKWave).

## Synthesis note
The RTL uses only synthesizable Verilog-2001 constructs. Import the files into Intel Quartus
Prime, Xilinx Vivado or Microchip Libero SoC to check synthesis and timing for a target device.

## Layout
```
rtl/   design files
tb/    self-checking testbenches
docs/  functional and test specifications
.github/workflows/ci.yml   runs `make test` on every push
```
