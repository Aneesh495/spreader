#!/usr/bin/env python3
"""
Spreader: Container Terminal Operating System
Synthetic Ultra-Large Container Vessel BAPLIE Dataset Generator
"""

import argparse
import random
import sys
from typing import List, Tuple


def compute_iso_check_digit(owner_prefix: str, serial_6digit: int) -> int:
    """Computes ISO 6346 check digit for a 4-letter prefix and 6-digit serial."""
    s = f"{owner_prefix}{serial_6digit:06d}"
    weights = [1, 2, 4, 8, 16, 32, 64, 128, 256, 512]

    def char_val(c: str) -> int:
        if c.isdigit():
            return int(c)
        val = ord(c.upper()) - ord('A') + 10
        if val >= 11:
            val += 1
        if val >= 22:
            val += 1
        if val >= 33:
            val += 1
        return val

    total = sum(char_val(s[i]) * weights[i] for i in range(10))
    rem = total % 11
    return rem % 10


def generate_container_id(prefix: str, serial: int) -> str:
    """Generates an 11-character ISO 6346 container identifier."""
    cd = compute_iso_check_digit(prefix, serial)
    return f"{prefix}{serial:06d}{cd}"


def generate_synthetic_baplie(
    vessel_name: str = "MV SPREADER MAJESTY",
    call_sign: str = "VRSP8",
    voyage_number: str = "0125E",
    pol: str = "CNSHA",
    pod_list: List[str] = None,
    container_count: int = 120,
    baplie_version: str = "2.2",
    seed: int = 42,
) -> str:
    """Generates a complete, valid SMDG BAPLIE EDIFACT message text."""
    if pod_list is None:
        pod_list = ["SGSIN", "AEJEA", "MAPTM", "NLRTM", "DEHAM"]

    random.seed(seed)
    prefixes = ["MSKU", "CMAU", "HLCU", "ONEU", "COSU", "MAEU"]
    iso_types = [
        ("42G1", False, None, None),  # 40ft standard dry
        ("45G1", False, None, None),  # 40ft high cube dry
        ("22G1", False, None, None),  # 20ft standard dry
        ("45R1", True, -18.0, None),  # 40ft reefer frozen
        ("45R1", True, 4.0, None),    # 40ft reefer chilled
        ("42G1", False, None, "3"),   # 40ft flammable liquid
        ("22G1", False, None, "8"),   # 20ft corrosive substance
    ]

    segments = []
    # Service String Advice (UNA)
    segments.append("UNA:+.? '")

    # Interchange Header
    segments.append(f"UNB+UNOA:2+SPREADER+PORTTERMINAL+261118:1400+000101'")

    # Message Header
    version_id = "SMDG22" if baplie_version == "2.2" else "SMDG31"
    sub_ver = "95B" if baplie_version == "2.2" else "D00B"
    segments.append(f"UNH+1+BAPLIE:D:{sub_ver}:UN:{version_id}'")

    # Beginning of Message
    segments.append(f"BGM+BAY+{voyage_number}+9'")

    # Transport Details
    segments.append(f"TDT+20+{voyage_number}+1++MSK:172:20+++{call_sign}:103::{call_sign}+{vessel_name}'")

    # Port of Loading
    segments.append(f"LOC+5+{pol}:139:6'")

    # Generate container placements across bays
    bay_candidates = [1, 3, 5, 7, 9, 11, 13, 15]
    row_candidates = [6, 4, 2, 0, 1, 3, 5]
    deck_tiers = [86, 84, 82]
    hold_tiers = [6, 4, 2]

    serial_start = 100000
    containers_generated = 0

    for bay in bay_candidates:
        if containers_generated >= container_count:
            break
        for tier in hold_tiers + deck_tiers:
            if containers_generated >= container_count:
                break
            for row in row_candidates:
                if containers_generated >= container_count:
                    break

                cid = generate_container_id(random.choice(prefixes), serial_start + containers_generated)
                itype, is_ref, ref_temp, haz_class = random.choice(iso_types)
                pod = random.choice(pod_list)

                # Weight: in hold is heavier, on deck is lighter
                base_weight = 26.0 if tier <= 10 else 18.0
                weight_kg = int((base_weight + random.uniform(-4.0, 4.0)) * 1000)

                # EQD: Equipment Details (Element 5 is Full indicator '4')
                segments.append(f"EQD+CN+{cid}+{itype}:102:5++4'")

                # LOC 147: Stowage Cell (format: 7 characters BBB RR TT)
                cell_code = f"{bay:03d}{row:02d}{tier:02d}"
                segments.append(f"LOC+147+{cell_code}:139:125'")

                # MEA: Gross Weight in Kilograms
                segments.append(f"MEA+WT++KGM:{weight_kg}'")

                # LOC 11: Port of Discharge
                segments.append(f"LOC+11+{pod}:139:6'")

                # Optional Reefer Temperature
                if is_ref and ref_temp is not None:
                    t_val = int(ref_temp)
                    t_str = f"N{abs(t_val)}" if t_val < 0 else f"{t_val}"
                    segments.append(f"TMP+2+{t_str}:CEL'")

                # Optional Dangerous Goods
                if haz_class:
                    segments.append(f"DGS+IMD+{haz_class}+1993'")

                containers_generated += 1

    # Message Trailer (UNT: segment count includes UNH through UNT)
    # Total segments so far minus UNA and UNB (2 segments before UNH)
    unh_index = 2
    seg_count_in_msg = len(segments) - unh_index + 1
    segments.append(f"UNT+{seg_count_in_msg}+1'")

    # Interchange Trailer
    segments.append(f"UNZ+1+000101'")

    return "\n".join(segments) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description="Synthetic SMDG BAPLIE Generator")
    parser.add_argument("--vessel", type=str, default="MV SPREADER MAJESTY", help="Vessel Name")
    parser.add_argument("--voyage", type=str, default="0125E", help="Voyage Number")
    parser.add_argument("--count", type=int, default=150, help="Number of container positions to generate")
    parser.add_argument("--version", type=str, default="2.2", choices=["2.2", "3.1"], help="SMDG BAPLIE version")
    parser.add_argument("--output", type=str, default="", help="Path to write EDI file")
    args = parser.parse_args()

    edi_text = generate_synthetic_baplie(
        vessel_name=args.vessel,
        voyage_number=args.voyage,
        container_count=args.count,
        baplie_version=args.version,
    )

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(edi_text)
        print(f"Generated {args.count} containers into {args.output}")
    else:
        print(edi_text)


if __name__ == "__main__":
    main()
