# ==============================================================================
# Project: Aether-AI Edge SoC
# File:    run_simulation.py
# Description: Automated Testbench Compilation and Simulation Runner (Icarus Verilog)
# ==============================================================================

import os
import subprocess
import sys

def run_flow():
    proj_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    out_dir   = os.path.join(proj_root, "sim", "output")
    os.makedirs(out_dir, exist_ok=True)

    vvp_file = os.path.join(out_dir, "edge_ai_soc_sim.vvp")
    vcd_file = os.path.join(out_dir, "edge_ai_soc_waveform.vcd")

    print("==========================================================================")
    print("  AETHER-AI EDGE SOC - AUTOMATED VERIFICATION REGRESSION                  ")
    print("==========================================================================")
    print(f"[*] Project Root: {proj_root}")

    # Gather all Verilog sources
    sources = [
        os.path.join(proj_root, "rtl", "cpu", "riscv_alu.v"),
        os.path.join(proj_root, "rtl", "cpu", "alu_mul_div.v"),
        os.path.join(proj_root, "rtl", "cpu", "riscv_regfile.v"),
        os.path.join(proj_root, "rtl", "cpu", "riscv_core.v"),
        os.path.join(proj_root, "rtl", "npu", "pe.v"),
        os.path.join(proj_root, "rtl", "npu", "systolic_array_4x4.v"),
        os.path.join(proj_root, "rtl", "npu", "activation_relu.v"),
        os.path.join(proj_root, "rtl", "npu", "npu_top.v"),
        os.path.join(proj_root, "rtl", "bus", "axi_crossbar.v"),
        os.path.join(proj_root, "rtl", "bus", "apb_bridge.v"),
        os.path.join(proj_root, "rtl", "mem", "boot_rom.v"),
        os.path.join(proj_root, "rtl", "mem", "system_sram.v"),
        os.path.join(proj_root, "rtl", "peripherals", "uart_controller.v"),
        os.path.join(proj_root, "rtl", "peripherals", "spi_master.v"),
        os.path.join(proj_root, "rtl", "peripherals", "timer_32bit.v"),
        os.path.join(proj_root, "rtl", "peripherals", "gpio_controller.v"),
        os.path.join(proj_root, "rtl", "padframe", "chip_padring.v"),
        os.path.join(proj_root, "rtl", "edge_ai_soc_top.v"),
        os.path.join(proj_root, "tb", "tb_edge_ai_soc.v")
    ]

    inc_dirs = [
        f"-I{os.path.join(proj_root, 'rtl', 'cpu')}",
        f"-I{os.path.join(proj_root, 'rtl', 'bus')}"
    ]

    iverilog_cmd = ["iverilog", "-g2005"] + inc_dirs + ["-o", vvp_file] + sources
    print("[*] Compiling RTL and Verification Suite with iverilog...")
    res = subprocess.run(iverilog_cmd, cwd=proj_root, capture_output=True, text=True)

    if res.returncode != 0:
        print("[!] Compilation Failed:")
        print(res.stderr)
        sys.exit(1)
    print("    -> Compilation SUCCESSFUL! Binary generated.")

    print("[*] Running Cycle-Accurate Simulation with vvp...")
    sim_res = subprocess.run(["vvp", vvp_file], cwd=proj_root, capture_output=True, text=True)
    print(sim_res.stdout)

    if "ALL TESTS PASSED SUCCESSFULLY" in sim_res.stdout:
        print("\n[SUCCESS] Edge-AI Acceleration SoC is 100% VERIFIED!")
    else:
        print("\n[WARNING] Simulation ended with errors.")

if __name__ == "__main__":
    run_flow()
