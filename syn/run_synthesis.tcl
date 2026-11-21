# ==============================================================================
# Synthesis Automation Script for Aether-AI Edge SoC
# Supported Tools: Synopsys Design Compiler (DC-Shell) / Yosys Open-Source EDA
# ==============================================================================

set DESIGN_NAME "edge_ai_soc_top"
set RTL_DIR     "../rtl"
set REPORT_DIR  "./reports"

file mkdir $REPORT_DIR

puts "========================================================="
puts " Starting Synthesis Run for $DESIGN_NAME"
puts "========================================================="

analyze -format verilog [list \
    "$RTL_DIR/cpu/riscv_defines.vh" \
    "$RTL_DIR/cpu/riscv_alu.v" \
    "$RTL_DIR/cpu/alu_mul_div.v" \
    "$RTL_DIR/cpu/riscv_regfile.v" \
    "$RTL_DIR/cpu/riscv_core.v" \
    "$RTL_DIR/npu/pe.v" \
    "$RTL_DIR/npu/systolic_array_4x4.v" \
    "$RTL_DIR/npu/activation_relu.v" \
    "$RTL_DIR/npu/npu_top.v" \
    "$RTL_DIR/bus/bus_defines.vh" \
    "$RTL_DIR/bus/axi_crossbar.v" \
    "$RTL_DIR/bus/apb_bridge.v" \
    "$RTL_DIR/mem/boot_rom.v" \
    "$RTL_DIR/mem/system_sram.v" \
    "$RTL_DIR/peripherals/uart_controller.v" \
    "$RTL_DIR/peripherals/spi_master.v" \
    "$RTL_DIR/peripherals/timer_32bit.v" \
    "$RTL_DIR/peripherals/gpio_controller.v" \
    "$RTL_DIR/padframe/chip_padring.v" \
    "$RTL_DIR/edge_ai_soc_top.v" \
]

elaborate $DESIGN_NAME
current_design $DESIGN_NAME

check_design > "$REPORT_DIR/check_design.rpt"

# Apply Timing Constraints
source -echo -verbose "./edge_ai_soc_timing.sdc"

# Optimization
compile_ultra -gate_clock -no_autoungroup

# Generate Reports
report_timing -delay_type max -max_paths 10 > "$REPORT_DIR/timing_report.txt"
report_timing -delay_type min -max_paths 5  >> "$REPORT_DIR/timing_report.txt"
report_area -hierarchy                      > "$REPORT_DIR/area_report.txt"
report_power -hierarchy                     > "$REPORT_DIR/power_report.txt"

puts "========================================================="
puts " Synthesis Run Completed Successfully!"
puts "========================================================="
