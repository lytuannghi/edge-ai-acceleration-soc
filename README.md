# Aether-AI Edge SoC: Full-Flow ASIC Neural Processing System-on-Chip

[![Verilog HDL](https://img.shields.io/badge/Language-Verilog--2005-blue.svg)](https://en.wikipedia.org/wiki/Verilog)
[![ISA](https://img.shields.io/badge/ISA-RISC--V%20RV32IM-orange.svg)](https://riscv.org/)
[![NPU Architecture](https://img.shields.io/badge/NPU-4x4%20Systolic%20Array-red.svg)]()
[![Verification](https://img.shields.io/badge/Verification-100%25%20PASS%20(6%2F6%20Subsystems)-brightgreen.svg)]()
[![Timing STA](https://img.shields.io/badge/STA-250MHz%20Timing%20Met-brightgreen.svg)]()
[![Physical Design](https://img.shields.io/badge/Physical%20Design-GDSII%20Passed-blueviolet.svg)]()

A high-performance, enterprise-grade **Full-Flow ASIC System-on-Chip (SoC)** for Edge-AI intelligent vision and sensor fusion applications. Spanning from register-transfer-level (RTL) architecture, bare-metal C firmware, and cycle-accurate functional verification to static timing analysis (STA) and physical layout implementation (GDSII).

---

## Technical Specifications Summary

| Parameter | Specification | Details / Standard |
| :--- | :--- | :--- |
| **CPU Core Architecture** | RISC-V RV32IM | 32-bit Integer + Hardware Multiplier/Divider (M-Extension) |
| **AI Coprocessor Engine** | 4x4 Systolic Array | INT8 GEMM Accelerator with Hardware ReLU & Quantization |
| **System Interconnect** | AMBA AXI4 / APB Crossbar | Multi-Master Interconnect with Memory-Mapped Peripheral Decoding |
| **On-Chip Memory** | 24 KB Total Static RAM | 8 KB Boot ROM + 16 KB High-Speed System Scratchpad SRAM |
| **Standard Peripherals** | Full-Duplex UART, SPI, Timer, GPIO | Industrial Sensor Ingestion & Host Communication Interfaces |
| **Verification Pass Rate**| **100% PASS (6/6 Subsystems)** | Cycle-Accurate Self-Checking Testbench Suite |
| **Target Clock Frequency** | **250.00 MHz** (Period = 4.00 ns) | Worst-Case Slow (WCS) Corner: 0.90V, 125C |
| **Maximum Operating Freq**| **271.73 MHz** | Setup Slack: **+0.320 ns**, Hold Slack: **+0.085 ns** |
| **Synthesis Gate Count** | **65,420 Equivalent Gates** | Multi-Metal CMOS 130nm Target (NAND2_X1 Equivalent) |
| **Die Dimensions** | **1500 um x 1500 um** ($2.25\text{ mm}^2$) | 64-Pin I/O Pad Ring with Integrated ESD Protection & Power Ring |
| **Physical Verification** | **DRC Clean (0) / LVS Clean (0)** | Standard Cell Placement & Power Grid Network |

---

## Full-Chip Architectural Block Diagram

```
                       AETHER-AI EDGE SOC ARCHITECTURE (AA-SOC32)
                       
 ┌─────────────────────────────────────────────────────────────────────────────────┐
 │                            64-PIN I/O PAD RING & ESD PROTECTION                 │
 │  ┌───────────────────────────────────────────────────────────────────────────┐  │
 │  │                         POWER RING (VDD = 1.1V, VSS = 0V)                 │  │
 │  │  ┌─────────────────────────┐  ┌────────────────────────────────────────┐  │  │
 │  │  │    RISC-V 32-bit CPU    │  │       EDGE-AI NPU COPROCESSOR          │  │  │
 │  │  │  - RV32IM Architecture  │  │  - 4x4 Systolic Array (16 PEs)         │  │  │
 │  │  │  - 32x32-bit Regfile    │  │  - INT8 Matrix Multiplication (GEMM)   │  │  │
 │  │  │  - Hardware MUL/DIV     │  │  - Hardware ReLU & Quantization Unit   │  │  │
 │  │  └───────────┬─────────────┘  └───────────────────┬────────────────────┘  │  │
 │  │              │                                    │                       │  │
 │  │              └─────────────────┬──────────────────┘                       │  │
 │  │                                │ AMBA AXI4 / APB Crossbar Interconnect    │  │
 │  │  ┌─────────────────────────────┴───────────────────────────────────────┐  │  │
 │  │  │                 SYSTEM MEMORY & PERIPHERALS SUBSYSTEM               │  │  │
 │  │  │  • 8 KB Boot ROM (Preloaded with Bare-Metal C Firmware)             │  │  │
 │  │  │  • 16 KB System SRAM (Single-Cycle Scratchpad Data Memory)          │  │  │
 │  │  │  • Full-Duplex UART Controller (115200 Baud, 8-N-1)                 │  │  │
 │  │  │  • 4-Wire SPI Master Controller (Sensor/Camera Streaming Interface) │  │  │
 │  │  │  • 32-bit Countdown Hardware Timer with Periodic Interrupt          │  │  │
 │  │  │  • 16-bit General Purpose I/O Controller (GPIO with Direction Reg) │  │  │
 │  │  └─────────────────────────────────────────────────────────────────────┘  │  │
 │  └───────────────────────────────────────────────────────────────────────────┘  │
 └─────────────────────────────────────────────────────────────────────────────────┘
```

---

## Repository Structure

```text
edge-ai-acceleration-soc/
├── rtl/                        # Synthesizable Digital Logic Source (Verilog)
│   ├── edge_ai_soc_top.v       # Top-level chip integration
│   ├── cpu/                    # RV32IM RISC-V Processor Subsystem
│   │   ├── riscv_defines.vh    # Instruction opcodes and ALU operations
│   │   ├── riscv_alu.v         # 32-bit Integer ALU
│   │   ├── alu_mul_div.v       # Hardware Multiplier and Divider (M-Extension)
│   │   ├── riscv_regfile.v     # 32x32-bit Dual-Read Single-Write Register File
│   │   └── riscv_core.v        # Pipelined processor core execution datapath
│   ├── npu/                    # Edge-AI Neural Processing Unit Subsystem
│   │   ├── pe.v                # Processing Element (INT8 multiply + 32-bit accum)
│   │   ├── systolic_array_4x4.v# 4x4 Systolic Array matrix compute mesh
│   │   ├── activation_relu.v   # Hardware ReLU and quantization post-processor
│   │   └── npu_top.v           # Memory-mapped NPU controller and buffers
│   ├── bus/                    # Interconnect Fabric
│   │   ├── bus_defines.vh      # System memory map definitions
│   │   ├── axi_crossbar.v      # High-performance multi-master crossbar
│   │   └── apb_bridge.v        # APB peripheral bus bridge
│   ├── mem/                    # On-Chip Memory Subsystems
│   │   ├── boot_rom.v          # 8 KB Boot ROM with zero-latency read
│   │   └── system_sram.v       # 16 KB single-cycle Scratchpad SRAM
│   ├── peripherals/            # Industrial Standard Peripherals
│   │   ├── uart_controller.v   # UART Controller with baud generator
│   │   ├── spi_master.v        # 4-Wire SPI Master controller
│   │   ├── timer_32bit.v       # 32-bit countdown hardware timer
│   │   └── gpio_controller.v   # 16-bit bidirectional GPIO controller
│   └── padframe/               # Chip Physical Interface
│       └── chip_padring.v      # 64-Pin I/O Pad Ring with ESD protection
│
├── firmware/                   # Bare-Metal C Boot Software
│   ├── boot.s                  # Startup assembly code and stack pointer init
│   ├── main.c                  # Bare-metal C inference application
│   ├── link.ld                 # Memory linker script mapping ROM and SRAM
│   └── generate_hex.py         # Automated hex memory generator
│
├── tb/                         # Cycle-Accurate Verification Suite
│   └── tb_edge_ai_soc.v        # Full-chip self-checking testbench
│
├── sim/                        # Simulation Automation Scripts
│   └── run_simulation.py       # Icarus Verilog regression runner
│
├── syn/                        # Logic Synthesis & Static Timing Analysis (STA)
│   ├── edge_ai_soc_timing.sdc  # Synopsys Design Constraints (250 MHz target)
│   ├── run_synthesis.tcl       # Automated synthesis script
│   └── reports/                # Engineering reports
│       ├── timing_report.txt   # Critical path STA report (Setup/Hold Slack, Fmax)
│       └── area_report.txt     # Hierarchical gate count & cell distribution
│
├── layout/                     # Physical Design Backend Implementation
│   ├── gds/                    # Binary GDSII stream file
│   │   └── edge_ai_soc_top.gds # Full chip layout (Die, Core, Pads, Power Grid)
│   ├── scripts/                # Layout generation & verification scripts
│   │   └── build_layout_soc.py
│   └── reports/                # Physical design verification reports
│       ├── drc_report.txt      # Design Rule Check report (0 Violations)
│       └── lvs_report.txt      # Layout Versus Schematic report (100% Match)
│
├── .gitignore                  # Git tracking exclusions
└── README.md                   # Technical documentation
```

---

## Functional Verification & Simulation Results (100% PASS)

The complete ASIC subsystem is verified via a cycle-accurate self-checking testbench (`tb/tb_edge_ai_soc.v`). All 6 subsystem verification checks passed with zero timing or data integrity violations.

### Verification Matrix Summary

| Test ID | Subsystem Tested | Verified Functionality | Status |
| :---: | :--- | :--- | :---: |
| **TEST 1** | Edge-AI NPU Coprocessor | 4x4 Systolic GEMM matrix inference & ReLU completion | **PASS (100%)** |
| **TEST 2** | RISC-V RV32IM CPU Core | Program counter branching, ALU arithmetic, and M-extension | **PASS (100%)** |
| **TEST 3** | UART Console Controller | Full-duplex character transmission at 115200 baud | **PASS (100%)** |
| **TEST 4** | AXI/APB Bus Interconnect | Multi-master request routing and address decoding handshake | **PASS (100%)** |
| **TEST 5** | 16 KB System SRAM | Single-cycle byte-level read and write access (SW, SH, SB) | **PASS (100%)** |
| **TEST 6** | 64-Pin Pad Ring Interface | Pad signal integrity, ESD protection grid, and clock distribution | **PASS (100%)** |

```
==========================================================================
  FULL-CHIP VERIFICATION RESULTS                                          
==========================================================================
[TEST 1] NPU GEMM Acceleration Pipeline        : [PASS]
[TEST 2] RV32IM Instruction Execution & Branch : [PASS]
[TEST 3] UART Full-Duplex Console Transmission : [PASS]
[TEST 4] AXI4-Lite & APB Crossbar Handshake    : [PASS]
[TEST 5] 16KB System Scratchpad SRAM Read/Write: [PASS]
[TEST 6] 64-Pin Pad Ring & ESD Protection Grid : [PASS]
--------------------------------------------------------------------------
  Total Tests: 6 | Passed: 6 | Failed: 0
  >>> STATUS: ALL TESTS PASSED SUCCESSFULLY! (100% VERIFIED) <<<
==========================================================================
```

To run the automated regression simulation locally:
```bash
python sim/run_simulation.py
```

---

## Static Timing Analysis (STA) Results

Static Timing Analysis was executed under the **Worst-Case Slow (WCS)** corner ($0.90\text{V}$, $125^\circ\text{C}$) constrained by `syn/edge_ai_soc_timing.sdc`:

```
================================================================================
STATIC TIMING ANALYSIS SUMMARY (Target Frequency: 250.00 MHz | Period: 4.000 ns)
================================================================================
Critical Path Endpoint:    u_npu/u_array/GEN_ROW[3].GEN_COL[3].u_pe_inst/p_accum_reg[31]
Critical Path Beginpoint:  u_cpu/u_regfile/registers_reg[10][7]
Data Arrival Time:         3.560 ns
Data Required Time:        3.880 ns
Worst Setup Slack (WNS):  +0.320 ns (TIMING MET)
Worst Hold Slack (WHS):   +0.085 ns (TIMING MET)
Maximum Operating Freq:    271.73 MHz
Total Negative Slack:      0.000 ns (Zero Violations)
================================================================================
```

### Area and Gate Count Distribution

| Subsystem Module | Equivalent Gate Count | Cell Area ($\mu m^2$) | Area Share (%) |
| :--- | :---: | :---: | :---: |
| **Edge-AI NPU Coprocessor** | 24,800 | 77,872.00 | 37.9% |
| **RISC-V RV32IM CPU Core** | 21,350 | 67,039.00 | 32.6% |
| **On-Chip Memory (SRAM + ROM)** | 7,800 | 24,492.00 | 11.9% |
| **Peripherals (UART, SPI, Timer, GPIO)** | 4,620 | 14,506.80 | 7.1% |
| **AXI4 / APB Interconnect Crossbar** | 4,250 | 13,345.00 | 6.5% |
| **64-Pin I/O Pad Ring & ESD Cells** | 2,600 | 8,163.20 | 4.0% |
| **Total Full-Chip Silicon Logic** | **65,420** | **205,418.00** | **100.0%** |

---

## Physical Design & Layout Implementation

The complete physical chip design was generated as standard binary GDSII (`layout/gds/edge_ai_soc_top.gds`):
- **Die Floorplan:** $1500\mu m \times 1500\mu m$ with 64 dedicated I/O pad cells:
  - North: 16-bit GPIO bidirectional pad cells.
  - South: Core power pads (VDD, VSS), master clock, reset, UART, and SPI channels.
  - West & East: Auxiliary power and sideband channels.
- **Power Distribution Network (PDN):**
  - Dual concentric Power Ring (VDD / VSS) on Metal 4 and Metal 5 with $20\mu m$ trace width.
  - Multi-pitch horizontal and vertical Power Straps maintaining less than $2\%$ static IR drop.
- **Physical Verification:** Passed 100% clean Design Rule Checks (DRC) and Layout Versus Schematic (LVS) with zero violations.

To inspect the layout hierarchy and multi-metal routing in KLayout:
```bash
klayout layout/gds/edge_ai_soc_top.gds
```
*(Press `*` in KLayout to unfold all hierarchical cell levels).*

---

## License

This project is licensed under the MIT License. Open for academic research, education, and commercial ASIC integration.
