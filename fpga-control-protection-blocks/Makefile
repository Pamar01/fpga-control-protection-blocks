IVERILOG ?= iverilog
VVP      ?= vvp
BUILD    := build

.PHONY: all test test-pwm test-oc clean

all: test

test: test-pwm test-oc

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/pwm_sim: rtl/pwm_deadtime.v tb/pwm_deadtime_tb.v | $(BUILD)
	$(IVERILOG) -Wall -o $@ rtl/pwm_deadtime.v tb/pwm_deadtime_tb.v

$(BUILD)/oc_sim: rtl/overcurrent_protection.v tb/overcurrent_protection_tb.v | $(BUILD)
	$(IVERILOG) -Wall -o $@ rtl/overcurrent_protection.v tb/overcurrent_protection_tb.v

test-pwm: $(BUILD)/pwm_sim
	cd $(BUILD) && $(VVP) pwm_sim > pwm.log; cat pwm.log
	@grep -q "ALL TESTS PASSED" $(BUILD)/pwm.log

test-oc: $(BUILD)/oc_sim
	cd $(BUILD) && $(VVP) oc_sim > oc.log; cat oc.log
	@grep -q "ALL TESTS PASSED" $(BUILD)/oc.log

clean:
	rm -rf $(BUILD)
