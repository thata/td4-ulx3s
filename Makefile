test: cpu.v cpu_test.v
	iverilog -o cpu_test cpu.v cpu_test.v
	vvp cpu_test
	rm -f cpu_test
