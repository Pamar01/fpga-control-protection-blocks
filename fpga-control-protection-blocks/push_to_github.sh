#!/usr/bin/env bash
# Run inside this folder on your own computer.
# 1) Create an EMPTY repo named "fpga-control-protection-blocks" under Pamar01 on GitHub.
# 2) Run:  bash push_to_github.sh
set -e
git init -b main
git add .
git commit -m "Add PWM dead-time and overcurrent protection FPGA blocks with specs and testbenches"
git remote add origin https://github.com/Pamar01/fpga-control-protection-blocks.git
git push -u origin main
