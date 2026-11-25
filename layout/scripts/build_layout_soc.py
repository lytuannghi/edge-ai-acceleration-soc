#!/usr/bin/env python3
import os
from build_layout_engine import build_asic_layout

if __name__ == "__main__":
    lay_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    gds_out = os.path.join(lay_root, "gds", "edge_ai_soc_top.gds")
    rep_out = os.path.join(lay_root, "reports", "drc_report.txt")
    build_asic_layout(
        gds_path=gds_out,
        report_path=rep_out,
        top_name="edge_ai_soc_top",
        libname="EDGE_AI_SOC_TOP_LIB",
        die_w=720000,
        die_h=720000,
        macro_cols=4,
        macro_rows=4,
        pad_count_per_side=6,
    )
