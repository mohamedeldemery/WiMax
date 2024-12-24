## Generated SDC file "phase3.out.sdc"

## Copyright (C) 2024  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and any partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details, at
## https://fpgasoftware.intel.com/eula.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 23.1std.1 Build 993 05/14/2024 SC Standard Edition"

## DATE    "Thu Dec 12 21:37:04 2024"

##
## DEVICE  "5CEBA4F23C7"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {clk_ref} -period 20.000 -waveform { 0.000 10.000 } [get_ports {clk_ref}]


#**************************************************************
# Create Generated Clock
#**************************************************************
create_generated_clock -source [get_ports clk_ref] -multiply_by 1 -name clk_50MHZ
create_generated_clock -source [get_ports clk_ref] -multiply_by 2 -name clk_100MHZ


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {clk_ref}] -rise_to [get_clocks {clk_ref}] -setup 0.080  
set_clock_uncertainty -rise_from [get_clocks {clk_ref}] -rise_to [get_clocks {clk_ref}] -hold 0.060  
set_clock_uncertainty -rise_from [get_clocks {clk_ref}] -fall_to [get_clocks {clk_ref}] -setup 0.080  
set_clock_uncertainty -rise_from [get_clocks {clk_ref}] -fall_to [get_clocks {clk_ref}] -hold 0.060  
set_clock_uncertainty -fall_from [get_clocks {clk_ref}] -rise_to [get_clocks {clk_ref}] -setup 0.080  
set_clock_uncertainty -fall_from [get_clocks {clk_ref}] -rise_to [get_clocks {clk_ref}] -hold 0.060  
set_clock_uncertainty -fall_from [get_clocks {clk_ref}] -fall_to [get_clocks {clk_ref}] -setup 0.080  
set_clock_uncertainty -fall_from [get_clocks {clk_ref}] -fall_to [get_clocks {clk_ref}] -hold 0.060  


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

