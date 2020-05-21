# UN/EDIFACT & SMDG Maritime Telemetry Specification

This document details the maritime electronic data interchange (EDI) specifications implemented in Spreader across `src/Edi/`, covering the SMDG BAPLIE, MOVINS, and COPRAR standard messages.

---

## 1. ISO 9735 Syntax and Delimiter Architecture

All messages adhere to the United Nations Electronic Data Interchange for Administration, Commerce and Transport (UN/EDIFACT) ISO 9735 standard syntax.

### Default Delimiters

When no custom Service String Advice (`UNA`) header is present, standard service character delimiters apply:

| Symbol | ASCII Code | Description | Default Character |
| :--- | :--- | :--- | :--- |
| **Component Separator** | `0x3A` | Separates sub-components within a data element | `:` |
| **Data Element Separator** | `0x2B` | Separates composite or simple data elements | `+` |
| **Decimal Mark** | `0x2E` | Represents floating-point decimal point | `.` |
| **Release Indicator** | `0x3F` | Escape character preceding literal delimiter symbols | `?` |
| **Segment Terminator** | `0x27` | Terminates a segment record | `'` |

### Service String Advice Header (`UNA`)

When custom separators are required, the message commences with a 9-byte header:
```text
UNA:+.? '
```

---

## 2. SMDG BAPLIE Bayplan Message

The SMDG BAPLIE (Bayplan/Stowage Plan Occupied and Empty Locations) message transmits the complete cell-by-cell stowage plan of a container vessel before port arrival and following departure.

### Supported Versions

- **SMDG BAPLIE 2.2**: UN/EDIFACT directory `D:95B`, identified by `UNH+1+BAPLIE:D:95B:UN:SMDG22'`. Standard version used worldwide.
- **SMDG BAPLIE 3.1**: UN/EDIFACT directory `D:00B`, identified by `UNH+1+BAPLIE:D:D00B:UN:SMDG31'`. Enhanced for ultra-large container vessels (ULCVs) exceeding 18,000 TEU, supporting full SOLAS Verified Gross Mass (VGM) declarations.

### Segment Hierarchy

```
UNB (Interchange Header)
  └── UNH (Message Header: BAPLIE)
        ├── BGM (Beginning of Message)
        ├── TDT (Transport Details: Vessel Name, Call Sign, Voyage)
        ├── LOC+5 (Port of Loading: UN/LOCODE)
        ├── Loop (Per Container Stowage Position):
        │     ├── EQD (Equipment Details: Container ID, ISO Type, Status)
        │     ├── LOC+147 (Stowage Cell Location: ISO 9711 BBB RR TT)
        │     ├── MEA+WT (Gross Weight: KGM or TNE)
        │     ├── LOC+11 (Port of Discharge: UN/LOCODE)
        │     ├── TMP+2 (Reefer Temperature Setpoint, optional)
        │     ├── DGS+IMD (IMDG Dangerous Goods Classification, optional)
        │     └── FTX+AAI (Free Text Stowage Instructions, optional)
        └── UNT (Message Trailer)
UNZ (Interchange Trailer)
```

### Cell Coordinate Encoding (`LOC+147`)

The cell coordinate is encoded as a 7-character numeric string `BBBRRTT`:
- `BBB`: Bay number (001..105). Odd = 20ft bay, Even = 40ft bay.
- `RR`: Row number (00..26). Even = Port, Odd = Starboard, 00 = Centerline.
- `TT`: Tier number. Under-deck = 02..18, On-deck = 82..98.

Example:
```text
LOC+147+0010284:139:125'
```
Indicates: Bay 01, Row 02 (Port), Tier 84 (second tier on deck).

---

## 3. SMDG MOVINS Stowage Instruction Message

The SMDG MOVINS (Move Information Instructions) message transmits sequence-ordered container handling instructions from the stowage coordinator to terminal automation PLCs and crane operator consoles.

### Segment Encoding

```text
EQD+CN+MSKU1234567+42G1:102:5++6'
LOC+147+0010282:139:125'
MEA+WT++KGM:24500'
FTX+AAI+++SEQ:101 CRANE:QC_02'
```

- `EQD` Element 5 Move Code:
  - `6`: Discharge move (vessel cell to quay buffer / AGV).
  - `4`: Load move (quay apron to vessel cell).
  - `1`: Shift move within vessel (cell to cell).

---

## 4. EDIFACT COPRAR Container Manifest Message

The COPRAR (Container Discharge/Loading Order) message is transmitted by shipping lines to the terminal operator prior to vessel berthing.

- **Discharge Order (`BGM+45`)**: Enumerates every container scheduled to be discharged at the port, including bill of lading numbers, seal numbers, and inland on-carriage routing.
- **Loading Order (`BGM+43`)**: Enumerates outbound export containers cleared at the gate and scheduled for loading onto the departing vessel.
