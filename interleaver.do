# Quit any running simulation
quit -sim

# Create or map to library
vlib work

# Map the Intel FPGA library
vmap altera_mf "C:/intelFPGA_lite/22.1std/questa_fse/intel/verilog/altera_mf"

# Compile the design files
vlog interleaver.sv interleaver_tb.sv RAM4P.v +cover -covercells

# Start simulation
vsim -voptargs=+acc -L altera_mf work.tb_interleaver -coverage

# Global Signals
add wave -noupdate -divider "GLOBAL SIGNALS"
add wave -format Logic /tb_interleaver/clk
add wave -format Logic /tb_interleaver/reset

# Interface Signals
add wave -noupdate -divider "INTERFACE SIGNALS"
add wave -format Logic /tb_interleaver/input_data
add wave -format Logic /tb_interleaver/data_valid
add wave -format Logic /tb_interleaver/ready_in
add wave -format Logic /tb_interleaver/output_data
add wave -format Logic /tb_interleaver/valid_out
add wave -format Logic /tb_interleaver/ready_out

# Interleaver Internal Signals
add wave -noupdate -divider "=== INTERLEAVER INTERNAL SIGNALS ==="

# State Machine
add wave -noupdate -divider "STATE MACHINE"
add wave -format Literal /tb_interleaver/dut/current_state
add wave -format Literal /tb_interleaver/dut/next_state

# Counters
add wave -noupdate -divider "COUNTERS"
add wave -format Literal -radix unsigned /tb_interleaver/dut/bank_a_counter
add wave -format Literal -radix unsigned /tb_interleaver/dut/bank_b_counter
add wave -format Literal -radix unsigned /tb_interleaver/dut/read_a_counter
add wave -format Literal -radix unsigned /tb_interleaver/dut/read_b_counter

# Memory Interface
add wave -noupdate -divider "MEMORY INTERFACE"
add wave -format Literal -radix unsigned /tb_interleaver/dut/address_a
add wave -format Literal -radix unsigned /tb_interleaver/dut/address_b
add wave -format Logic /tb_interleaver/dut/data_a
add wave -format Logic /tb_interleaver/dut/ram_out_b
add wave -format Logic /tb_interleaver/dut/wren_a
add wave -format Logic /tb_interleaver/dut/rden_b

# Testbench Monitoring
add wave -noupdate -divider "=== TESTBENCH MONITORING ==="
add wave -format Literal -radix hexadecimal /tb_interleaver/test_data
add wave -format Literal -radix unsigned /tb_interleaver/bit_index
add wave -format Literal -radix unsigned /tb_interleaver/block_index
add wave -format Literal -radix unsigned /tb_interleaver/error_count

# Wave Formatting
configure wave -namecolwidth 300
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2

# Run Simulation
run -all

# Zoom full
wave zoom full