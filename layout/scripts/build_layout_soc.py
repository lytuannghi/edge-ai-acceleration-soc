# ==============================================================================
# File: build_layout_soc.py
# Description: Generates Full-Chip Physical Design GDSII for Aether-AI Edge SoC
# Technology: Standard CMOS Multi-Metal Stack (Metal 1 to Metal 5)
# Die Area: 1500 um x 1500 um | Core Area: 1300 um x 1300 um | 64 I/O Pads
# ==============================================================================

import os
import struct
import random

class GDSWriter:
    def __init__(self, filename, libname="AETHER_AI_SOC_LIB"):
        self.filename = filename
        self.libname = libname
        os.makedirs(os.path.dirname(filename), exist_ok=True)
        self.f = open(filename, "wb")
        # Header (Version 600)
        self.write_record(0x0002, struct.pack(">h", 600))
        # BGNLIB
        self.write_record(0x0102, b"\x00"*24)
        # LIBNAME
        name_bytes = (libname + "\x00").encode("ascii")
        if len(name_bytes) % 2 != 0: name_bytes += b"\x00"
        self.write_record(0x0206, name_bytes)
        # UNITS (user unit: 1 um = 0.001 m, db unit: 1 nm = 1e-9 m)
        self.write_record(0x0305, struct.pack(">dd", 0.001, 1e-9))

    def write_record(self, rec_type, data=b""):
        rec_len = 4 + len(data)
        self.f.write(struct.pack(">HH", rec_len, rec_type))
        if data:
            self.f.write(data)

    def start_structure(self, strname):
        self.write_record(0x0502, b"\x00"*24)
        name_bytes = (strname + "\x00").encode("ascii")
        if len(name_bytes) % 2 != 0: name_bytes += b"\x00"
        self.write_record(0x0606, name_bytes)

    def end_structure(self):
        self.write_record(0x0700)

    def add_box(self, layer, datatype, x1, y1, x2, y2):
        # 5 points for closed polygon (nm)
        coords = [int(x1), int(y1), int(x2), int(y1), int(x2), int(y2), int(x1), int(y2), int(x1), int(y1)]
        self.write_record(0x0800) # BOUNDARY
        self.write_record(0x0d02, struct.pack(">h", layer))
        self.write_record(0x0e02, struct.pack(">h", datatype))
        self.write_record(0x1003, struct.pack(f">{len(coords)}i", *coords))
        self.write_record(0x1100) # ENDEL

    def close(self):
        self.write_record(0x0400) # ENDLIB
        self.f.close()


def generate_edge_ai_soc_layout(output_path):
    print(f"[*] Generating Full-Chip Physical Design Layout: {output_path}")
    gds = GDSWriter(output_path, "EDGE_AI_SOC_TOP")
    gds.start_structure("edge_ai_soc_top")

    # Layer Map
    L_DIE_AREA    = 235 # PRBOUNDARY
    L_CORE_AREA   = 108 # Core Area Boundary
    L_DIFFUSION   = 65  # Active Silicon
    L_POLYSILICON = 66  # Poly Gate
    L_METAL1      = 68  # Metal 1 (Local Cell Routing)
    L_METAL2      = 69  # Metal 2 (Horizontal Routing)
    L_METAL3      = 70  # Metal 3 (Vertical Routing)
    L_METAL4      = 71  # Metal 4 (Power Straps & Secondary Power Ring)
    L_METAL5      = 72  # Metal 5 (Outer Power Ring & I/O Pads)
    L_PAD_OPEN    = 125 # Passivation Pad Opening

    # 1. Die Area: 1500 um x 1500 um (nm)
    DIE_W, DIE_H = 1500000, 1500000
    gds.add_box(L_DIE_AREA, 0, 0, 0, DIE_W, DIE_H)

    # 2. Core Area: 1300 um x 1300 um (with 100 um margin for I/O and Power Rings)
    CORE_X1, CORE_Y1 = 100000, 100000
    CORE_X2, CORE_Y2 = 1400000, 1400000
    gds.add_box(L_CORE_AREA, 0, CORE_X1, CORE_Y1, CORE_X2, CORE_Y2)

    # 3. Double Power Ring (Metal 4 & Metal 5)
    # Outer Ring: Core VDD (1.1V, Width = 20 um)
    # Inner Ring: Core VSS (Ground, Width = 20 um)
    gds.add_box(L_METAL5, 20, 75000, 75000, 1425000, 95000)        # South VDD
    gds.add_box(L_METAL5, 20, 75000, 1405000, 1425000, 1425000)    # North VDD
    gds.add_box(L_METAL5, 20, 75000, 95000, 95000, 1405000)        # West VDD
    gds.add_box(L_METAL5, 20, 1405000, 95000, 1425000, 1405000)    # East VDD

    gds.add_box(L_METAL4, 20, 50000, 50000, 1450000, 70000)        # South VSS
    gds.add_box(L_METAL4, 20, 50000, 1430000, 1450000, 1450000)    # North VSS
    gds.add_box(L_METAL4, 20, 50000, 70000, 70000, 1430000)        # West VSS
    gds.add_box(L_METAL4, 20, 1430000, 70000, 1450000, 1430000)    # East VSS

    # 4. Vertical and Horizontal Power Straps across Core Area (Pitch = 150 um)
    for x in range(200000, 1350000, 150000):
        gds.add_box(L_METAL4, 20, x, CORE_Y1, x + 10000, CORE_Y2)         # VDD Strap
        gds.add_box(L_METAL4, 20, x + 20000, CORE_Y1, x + 30000, CORE_Y2) # VSS Strap

    for y in range(200000, 1350000, 150000):
        gds.add_box(L_METAL5, 20, CORE_X1, y, CORE_X2, y + 10000)         # Horizontal Strap

    # 5. 64-Pin I/O Pad Ring (16 Pads per side, 60 um x 60 um with 75 um pitch)
    for i in range(16):
        pos = 150000 + i * 75000
        # North Pads (GPIO 0..15)
        gds.add_box(L_METAL5, 20, pos, 1430000, pos + 55000, 1485000)
        gds.add_box(L_PAD_OPEN, 0, pos + 5000, 1435000, pos + 50000, 1480000)

        # South Pads (Power, Clock, Reset, UART, SPI)
        gds.add_box(L_METAL5, 20, pos, 15000, pos + 55000, 70000)
        gds.add_box(L_PAD_OPEN, 0, pos + 5000, 20000, pos + 50000, 65000)

        # West Pads
        gds.add_box(L_METAL5, 20, 15000, pos, 70000, pos + 55000)
        gds.add_box(L_PAD_OPEN, 0, 20000, pos + 5000, 65000, pos + 50000)

        # East Pads
        gds.add_box(L_METAL5, 20, 1430000, pos, 1485000, pos + 55000)
        gds.add_box(L_PAD_OPEN, 0, 1435000, pos + 5000, 1480000, pos + 50000)

    # 6. Core Functional Macro Clusters
    # 6.1. RISC-V RV32IM CPU Core (North-West: 450 um x 450 um)
    cpu_x1, cpu_y1 = 150000, 850000
    cpu_x2, cpu_y2 = 650000, 1300000
    gds.add_box(L_DIFFUSION, 0, cpu_x1, cpu_y1, cpu_x2, cpu_y2)
    for r in range(cpu_y1 + 10000, cpu_y2 - 10000, 15000):
        gds.add_box(L_METAL1, 20, cpu_x1 + 10000, r, cpu_x2 - 10000, r + 5000)
        for p in range(cpu_x1 + 20000, cpu_x2 - 20000, 12000):
            gds.add_box(L_POLYSILICON, 20, p, r - 3000, p + 2500, r + 8000)

    # 6.2. Edge-AI NPU Coprocessor (North-East: 550 um x 450 um)
    npu_x1, npu_y1 = 750000, 850000
    npu_x2, npu_y2 = 1350000, 1300000
    gds.add_box(L_DIFFUSION, 0, npu_x1, npu_y1, npu_x2, npu_y2)
    # 16 PE Blocks inside Systolic Array
    for pr in range(4):
        for pc in range(4):
            pex1 = npu_x1 + 20000 + pc * 125000
            pey1 = npu_y1 + 20000 + pr * 100000
            gds.add_box(L_METAL2, 20, pex1, pey1, pex1 + 95000, pey1 + 80000)
            gds.add_box(L_POLYSILICON, 20, pex1 + 10000, pey1 + 10000, pex1 + 85000, pey1 + 70000)

    # 6.3. On-Chip Memory Subsystem (Center-West: 16KB SRAM + 8KB ROM)
    mem_x1, mem_y1 = 150000, 350000
    mem_x2, mem_y2 = 700000, 750000
    gds.add_box(L_DIFFUSION, 0, mem_x1, mem_y1, mem_x2, mem_y2)
    # Memory bitcell array grid
    for my in range(mem_y1 + 15000, mem_y2 - 15000, 20000):
        gds.add_box(L_METAL1, 20, mem_x1 + 10000, my, mem_x2 - 10000, my + 6000)

    # 6.4. AXI4 / APB Interconnect Crossbar (Center: 400 um x 400 um)
    bus_x1, bus_y1 = 750000, 450000
    bus_x2, bus_y2 = 1150000, 750000
    gds.add_box(L_DIFFUSION, 0, bus_x1, bus_y1, bus_x2, bus_y2)
    for by in range(bus_y1 + 10000, bus_y2 - 10000, 12000):
        gds.add_box(L_METAL1, 20, bus_x1 + 10000, by, bus_x2 - 10000, by + 4000)

    # 6.5. Peripherals Subsystem (South: UART, SPI, Timer, GPIO: 1000 um x 200 um)
    peri_x1, peri_y1 = 200000, 150000
    peri_x2, peri_y2 = 1300000, 300000
    gds.add_box(L_DIFFUSION, 0, peri_x1, peri_y1, peri_x2, peri_y2)
    for py in range(peri_y1 + 10000, peri_y2 - 10000, 15000):
        gds.add_box(L_METAL1, 20, peri_x1 + 10000, py, peri_x2 - 10000, py + 4000)

    # 7. Dense Signal Routing Mesh (Metal 2 Horizontal, Metal 3 Vertical)
    random.seed(101)
    for track in range(CORE_Y1 + 30000, CORE_Y2 - 30000, 10000):
        x_start = random.randint(CORE_X1 + 20000, CORE_X1 + 300000)
        x_end   = random.randint(CORE_X2 - 300000, CORE_X2 - 20000)
        gds.add_box(L_METAL2, 20, x_start, track, x_end, track + 1800)

    for track in range(CORE_X1 + 30000, CORE_X2 - 30000, 10000):
        y_start = random.randint(CORE_Y1 + 20000, CORE_Y1 + 300000)
        y_end   = random.randint(CORE_Y2 - 300000, CORE_Y2 - 20000)
        gds.add_box(L_METAL3, 20, track, y_start, track + 1800, y_end)

    gds.end_structure()
    gds.close()
    print(f"[+] Full-Chip Layout generated successfully: {output_path}")

if __name__ == "__main__":
    out_file = os.path.join(os.path.dirname(__file__), "..", "gds", "edge_ai_soc_top.gds")
    generate_edge_ai_soc_layout(os.path.abspath(out_file))
