.PHONY: clean prog test

all: ulx3s.bit

clean:
	rm -rf td4.json ulx3s_out.config ulx3s.bit

ulx3s.bit: ulx3s_out.config
	ecppack ulx3s_out.config ulx3s.bit

ulx3s_out.config: td4.json
	nextpnr-ecp5 --85k --json td4.json --lpf ulx3s_v20.lpf --textcfg ulx3s_out.config

td4.json: cpu.v ulx3s_top.sv
	yosys -p "hierarchy -top ulx3s_top" -p "proc; opt" -p "synth_ecp5 -noccu2 -nomux -nodram -json td4.json" cpu.v ulx3s_top.sv

prog: ulx3s.bit
	fujprog ulx3s.bit

test: cpu.v cpu_test.v
	iverilog -o cpu_test cpu.v cpu_test.v
	vvp cpu_test
	rm -f cpu_test
