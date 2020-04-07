#!/usr/bin/env python3
"""
Spreader: Container Terminal Operating System
Unit Test Suite for Vessel Bay SVG and HTML Visualizer
"""

import os
import tempfile
import unittest
import xml.etree.ElementTree as ET
from spreader_viz import (
    ContainerCell,
    generate_bay_svg,
    generate_html_dashboard,
    sample_vessel_cells,
)


class TestSpreaderViz(unittest.TestCase):

    def test_cell_color_mapping(self):
        # Hazmat
        c_haz = ContainerCell(1, 0, 82, "MSKU1111111", "22G1", 15.0, imdg_class="3")
        self.assertEqual(c_haz.color(), "#e63946")

        # Reefer
        c_ref = ContainerCell(1, 2, 84, "MSKU2222222", "45R1", 20.0, is_reefer=True)
        self.assertEqual(c_ref.color(), "#00b4d8")

        # Heavy standard container (>26.0t)
        c_hvy = ContainerCell(1, 4, 82, "MSKU3333333", "42G1", 28.5)
        self.assertEqual(c_hvy.color(), "#3a0ca3")

        # Normal standard dry container
        c_std = ContainerCell(1, 6, 82, "MSKU4444444", "42G1", 18.0)
        self.assertEqual(c_std.color(), "#2a9d8f")

    def test_svg_generation_and_xml_validity(self):
        rows = [4, 2, 0, 1, 3]
        deck_tiers = [84, 82]
        hold_tiers = [4, 2]
        cells = sample_vessel_cells()

        svg = generate_bay_svg(1, rows, deck_tiers, hold_tiers, cells)

        self.assertTrue(svg.startswith("<svg"))
        self.assertTrue(svg.strip().endswith("</svg>"))
        self.assertIn("VESSEL BAY 01 TRANSVERSE CROSS-SECTION", svg)
        self.assertIn("DECK HATCH COVER", svg)

        # Verify XML structure parses without syntax error
        root = ET.fromstring(svg)
        self.assertEqual(root.tag, "{http://www.w3.org/2000/svg}svg")

    def test_html_dashboard(self):
        svg_mock = "<svg width='100' height='100'></svg>"
        html = generate_html_dashboard([svg_mock])

        self.assertIn("<!DOCTYPE html>", html)
        self.assertIn("Spreader: Ultra-Large Container Vessel Stowage Dashboard", html)
        self.assertIn("Standard Dry", html)
        self.assertIn("IMDG Hazardous", html)
        self.assertIn(svg_mock, html)


if __name__ == "__main__":
    unittest.main()
