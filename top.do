# Quit any running simulation
quit -sim

# Create or map to library
vlib work

# Map the Intel FPGA libraries
vmap altera_mf "C:/intelFPGA_lite/22.1std/questa_fse/intel/verilog/altera_mf"
vmap altera_lnsim "C:/intelFPGA_lite/22.1std/questa_fse/intel/verilog/altera_lnsim"

# Compile the design files
vlog prbs.sv new_FEC.sv top_module.sv top_module_tb.sv DPR.v RAM4P.v PLL.v PLL_0002.v modulator.sv +cover -covercells

# Start simulation with necessary libraries
vsim -voptargs="+acc" -L altera_mf -L altera_lnsim work.top_module_tb -coverage


# Global Signals
add wave -noupdate -divider "GLOBAL SIGNALS"
add wave -format Logic /top_module_tb/rst_n

# Top Module Interface
add wave -noupdate -divider "TOP MODULE INTERFACE"
add wave -format Logic /top_module_tb/data_in
add wave -format Logic /top_module_tb/clk_ref


# PRBS Module Section
add wave -noupdate -divider "=== PRBS MODULE ==="

# PRBS Control Signals
add wave -noupdate -divider "PRBS CONTROL SIGNALS"
add wave -format Logic /top_module_tb/dut/prbs_inst/ready_in
add wave -format Logic /top_module_tb/dut/prbs_inst/ready_out
add wave -format Logic /top_module_tb/dut/prbs_inst/valid_in
add wave -format Logic /top_module_tb/dut/prbs_inst/valid_out

# PRBS Data Path and Counter
add wave -noupdate -divider "PRBS DATA AND COUNTERS"
add wave -format Logic /top_module_tb/dut/prbs_inst/data_in
add wave -format Logic /top_module_tb/dut/prbs_inst/data_out
add wave -format Literal -radix binary /top_module_tb/dut/prbs_inst/LFSR
add wave -format Literal -radix unsigned /top_module_tb/dut/prbs_inst/bit_counter

# FEC Module Section
add wave -noupdate -divider "=== FEC MODULE ==="

# FEC Control Signals and States
add wave -noupdate -divider "FEC CONTROL AND STATES"
add wave -format Literal /top_module_tb/dut/fec_inst/current_state
add wave -format Literal /top_module_tb/dut/fec_inst/next_state
add wave -format Logic /top_module_tb/dut/fec_inst/wren_a
add wave -format Logic /top_module_tb/dut/fec_inst/rden_b
add wave -format Logic /top_module_tb/dut/fec_inst/data_out_dprB
add wave -format Logic /top_module_tb/dut/fec_inst/valid_in
add wave -format Logic /top_module_tb/dut/fec_inst/valid_out
add wave -format Logic /top_module_tb/dut/fec_inst/ready_out
add wave -format Logic /top_module_tb/dut/fec_inst/toggle_100MHz
add wave -format Logic /top_module_tb/dut/fec_inst/serial_out

# Grouped shift_reg and process_counter
add wave -noupdate -divider "FEC SHIFT REGISTER AND COUNTERS"
add wave -format Logic -radix unsigned /top_module_tb/dut/fec_inst/data_in
add wave -format Logic /top_module_tb/dut/fec_inst/data_a
add wave -format Literal -radix unsigned /top_module_tb/dut/fec_inst/address_a
add wave -format Literal -radix unsigned /top_module_tb/dut/fec_inst/address_b
add wave -format Literal -radix unsigned /top_module_tb/dut/fec_inst/bank_a_counter
add wave -format Literal -radix unsigned /top_module_tb/dut/fec_inst/bank_b_counter
add wave -format Literal -radix unsigned /top_module_tb/dut/fec_inst/bank_read_a_counter
add wave -format Literal -radix unsigned /top_module_tb/dut/fec_inst/bank_read_b_counter
add wave -format Literal -radix unsigned /top_module_tb/dut/fec_inst/serial_counter
add wave -format Literal -radix binary /top_module_tb/dut/fec_inst/last_six_bits
add wave -format Literal -radix binary /top_module_tb/dut/fec_inst/shift_reg

add wave -noupdate -divider "INTERLEAVER"
add wave -format Literal /top_module_tb/dut/interleaver_inst/current_state
add wave -format Literal /top_module_tb/dut/interleaver_inst/next_state
add wave -format Logic -radix unsigned /top_module_tb/dut/interleaver_inst/input_data
add wave -format Literal -radix unsigned /top_module_tb/dut/interleaver_inst/address_a
add wave -format Literal -radix unsigned /top_module_tb/dut/interleaver_inst/address_b
add wave -format Literal -radix unsigned /top_module_tb/dut/interleaver_inst/data_valid
add wave -format Literal -radix binary /top_module_tb/dut/interleaver_inst/ready_in
add wave -format Literal -radix binary /top_module_tb/dut/interleaver_inst/ready_out
add wave -format Literal -radix binary /top_module_tb/dut/interleaver_inst/valid_out
add wave -format Literal -radix binary /top_module_tb/dut/interleaver_inst/ram_out_b
add wave -format Literal -radix binary /top_module_tb/dut/interleaver_inst/rden_b
add wave -format Literal -radix binary /top_module_tb/dut/interleaver_inst/read_counter
add wave -format Literal -radix binary /top_module_tb/dut/interleaver_inst/valid_out
add wave -format Literal -radix binary /top_module_tb/dut/interleaver_inst/output_data
add wave -format Literal -radix binary /top_module_tb/dut/interleaver_inst/write_counter
add wave -format Literal -radix binary /top_module_tb/dut/interleaver_inst/wren_a


# Modulator Section
add wave -noupdate -divider "=== MODULATOR MODULE ==="
add wave -format Logic /top_module_tb/dut/modulator_inst/data_in
add wave -format Logic /top_module_tb/dut/modulator_inst/valid_in
add wave -format Logic /top_module_tb/dut/modulator_inst/ready_out
add wave -format Logic /top_module_tb/dut/modulator_inst/valid_out
add wave -format Literal -radix decimal /top_module_tb/dut/modulator_inst/i_out
add wave -format Literal -radix decimal /top_module_tb/dut/modulator_inst/q_out
add wave -format Logic /top_module_tb/dut/modulator_inst/bit_1
add wave -format Logic /top_module_tb/dut/modulator_inst/bit_2
add wave -format Logic /top_module_tb/dut/modulator_inst/bit_1_valid
add wave -format Logic /top_module_tb/dut/modulator_inst/bit_2_valid
add wave -format Logic /top_module_tb/dut/modulator_inst/modulate


# Testbench Monitoring
add wave -noupdate -divider "=== TESTBENCH MONITORING ==="
add wave -format Literal -radix hexadecimal /top_module_tb/input_data
add wave -format Literal -radix hexadecimal /top_module_tb/captured_serial_data
add wave -format Literal -radix unsigned /top_module_tb/bit_index
add wave -format Literal -radix unsigned /top_module_tb/block_index
add wave -format Literal -radix unsigned /top_module_tb/serial_counter

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