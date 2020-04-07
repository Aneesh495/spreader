#!/usr/bin/env python3
"""
Spreader: Container Terminal Operating System
Interactive Vessel Bay Cross-Section SVG & HTML Dashboard Exporter
"""

import argparse
import sys
from typing import Dict, List, Optional, Tuple


class ContainerCell:
    """Represents a container stowage cell in a transverse vessel bay."""

    def __init__(
        self,
        bay: int,
        row: int,
        tier: int,
        container_id: str,
        iso_type: str,
        weight_tonnes: float,
        is_reefer: bool = False,
        reefer_temp_c: Optional[float] = None,
        imdg_class: Optional[str] = None,
        pod: str = "NLRTM",
    ):
        self.bay = bay
        self.row = row
        self.tier = tier
        self.container_id = container_id
        self.iso_type = iso_type
        self.weight_tonnes = weight_tonnes
        self.is_reefer = is_reefer
        self.reefer_temp_c = reefer_temp_c
        self.imdg_class = imdg_class
        self.pod = pod

    @property
    def is_hazmat(self) -> bool:
        return self.imdg_class is not None

    @property
    def is_deck(self) -> bool:
        return self.tier >= 82

    def color(self) -> str:
        if self.is_hazmat:
            return "#e63946"  # Coral Red for IMDG
        if self.is_reefer:
            return "#00b4d8"  # Cyan/Teal for Reefers
        if self.weight_tonnes >= 26.0:
            return "#3a0ca3"  # Deep Indigo for Heavy
        return "#2a9d8f"  # Emerald Green for Standard


def generate_bay_svg(
    bay_number: int,
    rows: List[int],
    deck_tiers: List[int],
    hold_tiers: List[int],
    cells: List[ContainerCell],
    cell_w: int = 54,
    cell_h: int = 42,
) -> str:
    """Generates a standalone, standards-compliant SVG cross-section of a vessel bay."""
    margin_x = 70
    margin_y = 60
    deck_gap = 24

    total_cols = len(rows)
    total_deck_rows = len(deck_tiers)
    total_hold_rows = len(hold_tiers)

    width = margin_x * 2 + total_cols * cell_w
    height = margin_y * 2 + (total_deck_rows + total_hold_rows) * cell_h + deck_gap

    svg_parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" '
        f'width="{width}" height="{height}" style="background-color: #0d1117; font-family: monospace;">',
        f'<style>',
        f'  .cell-empty {{ fill: #161b22; stroke: #30363d; stroke-width: 1; }}',
        f'  .cell-box {{ stroke: #ffffff; stroke-width: 1.5; rx: 3; ry: 3; }}',
        f'  .axis-label {{ fill: #8b949e; font-size: 11px; text-anchor: middle; }}',
        f'  .title {{ fill: #58a6ff; font-size: 16px; font-weight: bold; text-anchor: middle; }}',
        f'  .deck-line {{ stroke: #f0883e; stroke-width: 3; stroke-dasharray: 6 3; }}',
        f'  .cell-text {{ fill: #ffffff; font-size: 9px; text-anchor: middle; font-weight: bold; }}',
        f'  .cell-sub {{ fill: #e6edf3; font-size: 8px; text-anchor: middle; }}',
        f'</style>',
        f'<text x="{width // 2}" y="32" class="title">VESSEL BAY {bay_number:02d} TRANSVERSE CROSS-SECTION</text>',
    ]

    cell_map: Dict[Tuple[int, int], ContainerCell] = {
        (c.row, c.tier): c for c in cells if c.bay == bay_number
    }

    # Render column headers (Row indices)
    for c_idx, r in enumerate(rows):
        cx = margin_x + c_idx * cell_w + cell_w // 2
        svg_parts.append(
            f'<text x="{cx}" y="{margin_y - 12}" class="axis-label">{r:02d}</text>'
        )
        svg_parts.append(
            f'<text x="{cx}" y="{height - margin_y + 24}" class="axis-label">{r:02d}</text>'
        )

    # Render On-Deck Tiers
    cur_y = margin_y
    for t_idx, tier in enumerate(deck_tiers):
        svg_parts.append(
            f'<text x="{margin_x - 18}" y="{cur_y + cell_h // 2 + 4}" class="axis-label">{tier:02d}</text>'
        )
        for c_idx, r in enumerate(rows):
            x = margin_x + c_idx * cell_w
            y = cur_y
            cell = cell_map.get((r, tier))
            if cell:
                svg_parts.append(
                    f'<rect x="{x+2}" y="{y+2}" width="{cell_w-4}" height="{cell_h-4}" '
                    f'fill="{cell.color()}" class="cell-box" />'
                )
                cid_abbr = cell.container_id[-4:]
                svg_parts.append(
                    f'<text x="{x + cell_w // 2}" y="{y + 16}" class="cell-text">{cid_abbr}</text>'
                )
                svg_parts.append(
                    f'<text x="{x + cell_w // 2}" y="{y + 28}" class="cell-sub">{cell.weight_tonnes:.1f}t</text>'
                )
            else:
                svg_parts.append(
                    f'<rect x="{x+2}" y="{y+2}" width="{cell_w-4}" height="{cell_h-4}" class="cell-empty" />'
                )
        cur_y += cell_h

    # Render Deck Hatch Cover Separation Line
    deck_line_y = cur_y + deck_gap // 2
    svg_parts.append(
        f'<line x1="{margin_x - 30}" y1="{deck_line_y}" x2="{width - margin_x + 30}" y2="{deck_line_y}" class="deck-line" />'
    )
    svg_parts.append(
        f'<text x="{width // 2}" y="{deck_line_y - 6}" fill="#f0883e" font-size="10px" font-weight="bold" text-anchor="middle">DECK HATCH COVER</text>'
    )
    cur_y += deck_gap

    # Render Under-Deck / Hold Tiers
    for t_idx, tier in enumerate(hold_tiers):
        svg_parts.append(
            f'<text x="{margin_x - 18}" y="{cur_y + cell_h // 2 + 4}" class="axis-label">{tier:02d}</text>'
        )
        for c_idx, r in enumerate(rows):
            x = margin_x + c_idx * cell_w
            y = cur_y
            cell = cell_map.get((r, tier))
            if cell:
                svg_parts.append(
                    f'<rect x="{x+2}" y="{y+2}" width="{cell_w-4}" height="{cell_h-4}" '
                    f'fill="{cell.color()}" class="cell-box" />'
                )
                cid_abbr = cell.container_id[-4:]
                svg_parts.append(
                    f'<text x="{x + cell_w // 2}" y="{y + 16}" class="cell-text">{cid_abbr}</text>'
                )
                svg_parts.append(
                    f'<text x="{x + cell_w // 2}" y="{y + 28}" class="cell-sub">{cell.weight_tonnes:.1f}t</text>'
                )
            else:
                svg_parts.append(
                    f'<rect x="{x+2}" y="{y+2}" width="{cell_w-4}" height="{cell_h-4}" class="cell-empty" />'
                )
        cur_y += cell_h

    svg_parts.append("</svg>")
    return "\n".join(svg_parts)


def generate_html_dashboard(bays_svgs: List[str]) -> str:
    """Generates an interactive HTML dashboard embedding vessel bay vector diagrams."""
    joined_svgs = "\n<hr style='border: 1px solid #30363d; margin: 30px 0;'>\n".join(
        bays_svgs
    )
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Spreader: Vessel Stowage Plan Dashboard</title>
  <style>
    body {{
      background-color: #010409;
      color: #e6edf3;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
      margin: 0;
      padding: 30px;
    }}
    .container {{
      max-width: 1100px;
      margin: 0 auto;
    }}
    h1 {{
      color: #58a6ff;
      border-bottom: 1px solid #30363d;
      padding-bottom: 12px;
    }}
    .legend {{
      display: flex;
      gap: 20px;
      background-color: #161b22;
      border: 1px solid #30363d;
      border-radius: 6px;
      padding: 12px 20px;
      margin-bottom: 24px;
    }}
    .legend-item {{
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 13px;
    }}
    .badge {{
      width: 16px;
      height: 16px;
      border-radius: 3px;
    }}
  </style>
</head>
<body>
  <div class="container">
    <h1>Spreader: Ultra-Large Container Vessel Stowage Dashboard</h1>
    <div class="legend">
      <div class="legend-item"><div class="badge" style="background-color: #2a9d8f;"></div> Standard Dry</div>
      <div class="legend-item"><div class="badge" style="background-color: #00b4d8;"></div> Reefer (Thermal)</div>
      <div class="legend-item"><div class="badge" style="background-color: #e63946;"></div> IMDG Hazardous</div>
      <div class="legend-item"><div class="badge" style="background-color: #3a0ca3;"></div> Heavy (>26t)</div>
      <div class="legend-item"><div class="badge" style="background-color: #161b22; border: 1px solid #30363d;"></div> Empty Slot</div>
    </div>
    {joined_svgs}
  </div>
</body>
</html>"""


def sample_vessel_cells() -> List[ContainerCell]:
    """Generates realistic sample stowage cells for demonstration."""
    return [
        ContainerCell(1, 2, 82, "MSKU1029384", "42G1", 21.5, pod="NLRTM"),
        ContainerCell(1, 0, 82, "MSKU2938475", "42G1", 22.0, pod="NLRTM"),
        ContainerCell(1, 1, 82, "MSKU3847561", "42G1", 20.8, pod="NLRTM"),
        ContainerCell(1, 2, 84, "MSKU4756192", "45R1", 24.2, is_reefer=True, reefer_temp_c=-18.0, pod="DEHAM"),
        ContainerCell(1, 0, 84, "MSKU5619283", "42G1", 27.5, pod="DEHAM"),
        ContainerCell(1, 1, 84, "MSKU6192834", "22G1", 16.0, imdg_class="3", pod="NLRTM"),
        ContainerCell(1, 2, 4, "MSKU7283940", "42G1", 28.0, pod="BEANR"),
        ContainerCell(1, 0, 4, "MSKU8394051", "42G1", 26.5, pod="BEANR"),
        ContainerCell(1, 1, 4, "MSKU9405162", "42G1", 27.0, pod="BEANR"),
        ContainerCell(1, 2, 2, "MSKU0516273", "42G1", 29.0, pod="SGSIN"),
        ContainerCell(1, 0, 2, "MSKU1627384", "42G1", 28.5, pod="SGSIN"),
        ContainerCell(1, 1, 2, "MSKU2738495", "42G1", 29.2, pod="SGSIN"),
    ]


def main() -> None:
    parser = argparse.ArgumentParser(description="Spreader Vessel Bay SVG and Dashboard Exporter")
    parser.add_argument("--bay", type=int, default=1, help="Bay number to render")
    parser.add_argument("--svg-output", type=str, default="", help="Path to write standalone SVG")
    parser.add_argument("--html-output", type=str, default="", help="Path to write HTML dashboard")
    args = parser.parse_args()

    rows = [6, 4, 2, 0, 1, 3, 5]
    deck_tiers = [86, 84, 82]
    hold_tiers = [6, 4, 2]
    cells = sample_vessel_cells()

    svg_content = generate_bay_svg(args.bay, rows, deck_tiers, hold_tiers, cells)

    if args.svg_output:
        with open(args.svg_output, "w", encoding="utf-8") as f:
            f.write(svg_content)
        print(f"Exported Bay {args.bay} SVG to: {args.svg_output}")

    if args.html_output:
        html_content = generate_html_dashboard([svg_content])
        with open(args.html_output, "w", encoding="utf-8") as f:
            f.write(html_content)
        print(f"Exported HTML dashboard to: {args.html_output}")

    if not args.svg_output and not args.html_output:
        print(svg_content)


if __name__ == "__main__":
    main()
