create_clock -name clk -period 20.0 [get_ports clk]
set_clock_uncertainty 0.5 [get_clocks clk]

set_input_delay  3.0 -clock clk [get_ports {coin_in sel_item confirm cancel rst}]
set_output_delay 3.0 -clock clk [all_outputs]

set_load 0.05 [all_outputs]
set_driving_cell -lib_cell INVX1_RVT [get_ports {coin_in sel_item confirm cancel rst}]
