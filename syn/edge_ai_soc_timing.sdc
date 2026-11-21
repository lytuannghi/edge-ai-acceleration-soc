# ==============================================================================
# Synopsys Design Constraints (SDC) for Aether-AI Edge SoC
# Target Foundry: High-Performance CMOS 130nm / Standard Cells
# Operating Conditions: Worst-Case Slow (WCS) Corner: SS / 0.90V / 125C
# Target Operating Frequency: 250.00 MHz (Clock Period = 4.00 ns)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Primary Clock Definition
# ------------------------------------------------------------------------------
set CLK_PERIOD 4.00
create_clock -name pad_clk -period $CLK_PERIOD [get_ports pad_clk]

# Clock Uncertainty (Jitter & Clock Tree Skew Margin)
set_clock_uncertainty -setup 0.080 [get_clocks pad_clk]
set_clock_uncertainty -hold  0.040 [get_clocks pad_clk]

# Clock Latency and Slew Transition
set_clock_latency -source 0.150 [get_clocks pad_clk]
set_clock_transition 0.100 [get_clocks pad_clk]

# ------------------------------------------------------------------------------
# 2. I/O Delay Constraints (External Pad Interfaces)
# ------------------------------------------------------------------------------
# UART, SPI, and GPIO Interface Constraints
set_input_delay  -clock pad_clk -max 1.200 [get_ports pad_uart_rx]
set_input_delay  -clock pad_clk -min 0.300 [get_ports pad_uart_rx]
set_output_delay -clock pad_clk -max 1.200 [get_ports pad_uart_tx]

set_input_delay  -clock pad_clk -max 1.200 [get_ports pad_spi_miso]
set_output_delay -clock pad_clk -max 1.000 [get_ports pad_spi_sck]
set_output_delay -clock pad_clk -max 1.000 [get_ports pad_spi_mosi]
set_output_delay -clock pad_clk -max 1.000 [get_ports pad_spi_cs_n]

set_input_delay  -clock pad_clk -max 1.500 [get_ports pad_gpio*]
set_output_delay -clock pad_clk -max 1.500 [get_ports pad_gpio*]

# ------------------------------------------------------------------------------
# 3. Design Rule Constraints (DRC)
# ------------------------------------------------------------------------------
set_max_fanout 16 [current_design]
set_max_transition 0.250 [current_design]
set_driving_cell -lib_cell BUF_X4 [all_inputs]
set_load -pin_load 0.030 [all_outputs]

# ------------------------------------------------------------------------------
# 4. Timing Exceptions (False Paths)
# ------------------------------------------------------------------------------
set_false_path -from [get_ports pad_rst_n]
