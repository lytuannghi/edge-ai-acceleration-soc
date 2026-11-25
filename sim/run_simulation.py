# ==============================================================================
# Project: Aether-AI Edge SoC
# File:    run_simulation.py
# Description: Portable Compilation and Simulation Runner (Icarus Verilog -Wall)
# ==============================================================================

import os
import shutil
import subprocess
import sys


def resolve_tool(name, proj_root):
    found = shutil.which(name)
    if found:
        return found
    sibling = os.path.join(os.path.dirname(proj_root), "iverilog", "bin", name + ".exe")
    return sibling if os.path.exists(sibling) else name


def run_flow():
    proj_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    out_dir = os.path.join(proj_root, "sim", "output")
    os.makedirs(out_dir, exist_ok=True)

    vvp_file = os.path.join(out_dir, "edge_ai_soc_sim.vvp")
    iverilog_exe = resolve_tool("iverilog", proj_root)
    vvp_exe = resolve_tool("vvp", proj_root)

    print("=" * 74)
    print("  AETHER-AI EDGE SOC - AUTOMATED VERIFICATION REGRESSION")
    print("=" * 74)

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
        os.path.join(proj_root, "tb", "tb_edge_ai_soc.v"),
    ]

    inc_dirs = [
        f"-I{os.path.join(proj_root, 'rtl', 'cpu')}",
        f"-I{os.path.join(proj_root, 'rtl', 'bus')}",
    ]

    iverilog_cmd = [iverilog_exe, "-Wall", "-g2005"] + inc_dirs + ["-o", vvp_file] + sources
    print("[*] Compiling RTL and Verification Suite with iverilog (-Wall)...")
    res = subprocess.run(iverilog_cmd, cwd=proj_root, capture_output=True, text=True, encoding="utf-8", errors="replace")

    if res.returncode != 0 or res.stderr.strip():
        print("[!] Compilation Failed or Warnings Present:")
        print(res.stderr)
        sys.exit(1)
    print("    -> Compilation Clean (0 warnings)! Binary generated.")

    print("[*] Running Cycle-Accurate Simulation with vvp...")
    sim_res = subprocess.run([vvp_exe, vvp_file], cwd=proj_root, capture_output=True, text=True, encoding="utf-8", errors="replace")
    print(sim_res.stdout)
    if sim_res.stderr:
        print(sim_res.stderr)

    if sim_res.returncode == 0 and "ALL TESTS PASSED SUCCESSFULLY" in sim_res.stdout and "[FAIL]" not in sim_res.stdout:
        print("\n[SUCCESS] Edge-AI Acceleration SoC is 100% VERIFIED!")
    else:
        print("\n[ERROR] Simulation ended with failures.")
        sys.exit(1)


if __name__ == "__main__":
    run_flow()
