#!/usr/bin/env python3
"""
Spreader: Container Terminal Operating System
Unit Test Suite for Synthetic BAPLIE Generator
"""

import unittest
from generate_synth_baplie import compute_iso_check_digit, generate_synthetic_baplie


class TestGenerateSynthBaplie(unittest.TestCase):

    def test_iso_check_digit_calculation(self):
        self.assertEqual(compute_iso_check_digit("CSQU", 305438), 3)
        self.assertEqual(compute_iso_check_digit("MSKU", 12345), 9)

    def test_baplie_generation_22(self):
        edi = generate_synthetic_baplie(container_count=25, baplie_version="2.2")

        self.assertTrue(edi.startswith("UNA:+.? '"))
        self.assertIn("UNH+1+BAPLIE:D:95B:UN:SMDG22'", edi)
        self.assertIn("BGM+BAY+0125E+9'", edi)
        self.assertIn("TDT+20+0125E+1", edi)
        self.assertIn("LOC+5+CNSHA:139:6'", edi)
        self.assertIn("UNT+", edi)
        self.assertIn("UNZ+1+000101'", edi)

        # Count EQD segments
        eqd_count = edi.count("EQD+CN+")
        self.assertEqual(eqd_count, 25)

    def test_baplie_generation_31(self):
        edi = generate_synthetic_baplie(container_count=10, baplie_version="3.1")
        self.assertIn("UNH+1+BAPLIE:D:D00B:UN:SMDG31'", edi)
        eqd_count = edi.count("EQD+CN+")
        self.assertEqual(eqd_count, 10)


if __name__ == "__main__":
    unittest.main()
