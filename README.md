# Spreader

```
  ____  ____  ____  _____     _     ____  _____ ____  
 / ___||  _ \|  _ \| ____|   / \   |  _ \| ____|  _ \ 
 \___ \| |_) | |_) |  _|    / _ \  | | | |  _| | |_) |
  ___) |  __/|  _ <| |___  / ___ \ | |_| | |___|  _ < 
 |____/|_|   |_| \_\_____|/_/   \_\|____/|_____|_| \_\
```

**High-Throughput Container Terminal Operating System (TOS) & Vessel Stowage Planning Engine in Flix**

Spreader is an automated maritime terminal operating system and vessel stowage planning engine. Built around first-class Datalog relational fixed-point reasoning, marine hydrostatics equilibrium solvers, twin Automated Stacking Crane (ASC) gantry kinematics, and UN/EDIFACT message interchange (SMDG BAPLIE, MOVINS, COPRAR), Spreader resolves the complex multi-physics and combinatorial constraints of modern container logistics.

```
+========================================================================================+
|                                     SPREADER TOS                                       |
+========================================================================================+
         |                        |                          |                   |
         v                        v                          v                   v
+------------------+    +--------------------+    +--------------------+  +--------------+
|   EDI SUBSYSTEM  |    |     STABILITY      |    |   YARD & CRANE     |  |  SIMULATION  |
| - BAPLIE 2.2/3.1 |    | - Transverse GM_T  |    | - Datalog IMDG 724 |  | - STS Crane  |
| - COPRAR Manifest|    | - Free Surface Eff |    | - Twin ASC Interloc|  |   Kinematics |
| - MOVINS Stowage |    | - Equilibrium Trim |    | - CRP Reshuffle    |  | - AGV Fleet  |
| - UN/LOCODE Hubs |    | - Girder SWSF/SWBM |    | - STS Dual Cycling |  |   Routing    |
| - ISO 9735 Lexer |    | - Ballast Anti-Heel|    | - Twin-Lift Pairing|  | - 14k TEU    |
+------------------+    +--------------------+    +--------------------+  |   Benchmark  |
         |                        |                          |            +--------------+
         +------------------------+--------------------------+                   |
                                  |                                              |
                                  v                                              v
               +--------------------------------------------------------------------+
               |                     FLIX PURE FUNCTIONAL CORE                      |
               |       Algebraic Data Types, Pattern Matching, Static Effects       |
               +--------------------------------------------------------------------+
                                  |                                  |
                                  v                                  v
               +------------------------------------+  +----------------------------+
               |         HIGH-SPEED C11 GLUE        |  |     PYTHON / TS TOOLING    |
               | - Zero-Allocation EDI Tokenizer    |  | - Interactive SVG Exporter |
               | - ISO 6346 Checksum Validator      |  | - Synthetic BAPLIE Gen     |
               | - SIMD String Scanning             |  | - Port Community Client    |
               +------------------------------------+  +----------------------------+
```

---

## Technical Highlights

### 1. IMO IMDG Code Table 7.2.4 Datalog Segregation
Maritime dangerous goods rules require non-trivial spatial separation between incompatible chemical hazard classes (e.g. mass-detonation explosives Class 1.1 versus organic peroxides Class 5.2 or flammable liquids Class 3). Spreader formalizes Table 7.2.4 as declarative Datalog Horn clauses in Flix, evaluating hold boundaries and deck clearances to a guaranteed relational fixed point.

### 2. Marine Hydrostatics & Longitudinal Hull Girder Strength
Stowage configurations directly dictate vessel seaworthiness:
- **Transverse Metacentric Height ($GM_T$)**: Solves solid $KG$, slack tank Free Surface Effect (FSE) virtual inertia loss ($\sum i \cdot \gamma / \Delta$), fluid metacentric height, and steady heel angle.
- **Longitudinal Equilibrium & Trim**: Balances trimming moment ($TM = \Delta \cdot (LCG - LCB)$) against $MTC$ to derive operating waterlines and forward/aft drafts.
- **21-Station Hull Girder Integration**: Integrates net load curves $q(x) = b(x) - w(x)$ across 21 equidistant stations to compute Still Water Shear Force ($SWSF$) and Still Water Bending Moment ($SWBM$), verifying hull girder stress limits.

### 3. Automated Equipment Kinematics & Reshuffle Minimization
- **Container Relocation Problem (CRP)**: Exact heuristic solver for minimizing secondary rehandles during yard stack retrieval.
- **Twin ASC Coordination**: Real-time trajectory conflict resolution preventing rail gantry collisions in automated blocks.
- **Ship-to-Shore (STS) Dual Cycling**: Combines discharge and load cycles into continuous round trips, achieving a +28.8% productivity boost in empirical benchmarks.
- **Twin-Lift Pairing**: Validates adjacent 20ft container pairings based on gross weight disparity ($< 10\text{t}$) and transverse eccentricity ($< 10\%$).

### 4. Zero-Copy Maritime EDIFACT Telemetry
Full support for maritime EDI standards:
- **SMDG BAPLIE 2.2 and 3.1**: Ingests and generates vessel bayplans with 7-character Bay-Row-Tier coordinate geometry, gross weights, reefer temperature setpoints, and IMDG codes.
- **COPRAR**: Handles carrier discharge orders and outbound loading manifests.
- **MOVINS**: Generates automated sequence instructions for crane PLCs.
- **UN/LOCODE**: Port registry, great-circle distances, and automated overstow detection.

---

## Repository Structure

```
spreader/
├── src/
│   ├── Model/                 # ISO 6346, ISO 9711 Bay-Row-Tier, IMDG classes, Vessel profiles
│   ├── Datalog/               # IMDG Table 7.2.4, Crane rail interlocks, Stack weight limits
│   ├── Stability/             # Hydrostatics, GM_T, Free surface effect, Trim, Hull girder SWBM
│   ├── Yard/                  # 3D block topologies, CRP reshuffle solver, Twin ASC handshake
│   ├── Crane/                 # Twin-lift pairing, STS dual-cycling, Multi-crane bay split
│   ├── Edi/                   # ISO 9735 lexer, SMDG BAPLIE 2.2/3.1, COPRAR, MOVINS, UN/LOCODE
│   ├── Simulation/            # Discrete-event engine, STS kinematics, AGV routing, Mega-vessel benchmark
│   ├── Visualizer/            # ANSI vessel bay cross-section and ASCII yard block renderer
│   ├── Cli/                   # Command-line parser, subcommand router, and execution dispatcher
│   ├── Main.flix              # Main system entrypoint and demonstration harness
│   ├── Model.flix             # Subsystem parent modules
│   ├── Stability.flix
│   ├── Yard.flix
│   ├── Crane.flix
│   ├── Edi.flix
│   ├── Simulation.flix
│   └── Visualizer.flix
├── test/                      # 124 automated unit, property, and integration test suites
├── tools/
│   ├── c/                     # High-speed C11 zero-allocation EDI tokenizer & ISO 6346 validator
│   ├── python/                # Interactive SVG bay exporter & synthetic ULCV BAPLIE generator
│   └── ts/                    # TypeScript Port Community System BAPLIE exchange client
├── data/
│   ├── baplie/                # SMDG BAPLIE 2.2 and 3.1 reference test bayplans
│   └── coprar/                # COPRAR discharge and loading manifests
├── docs/                      # Architectural specs, hydrostatics proofs, and benchmarks
├── Makefile                   # Unified compilation, test, and verification workflows
└── flix.toml                  # Flix package manifest
```

---

## Quick Start

### Prerequisites

- **Flix Compiler**: Flix 0.80.0 (requires Java 21+)
- **C Compiler**: Clang or GCC (C11 support)
- **Python**: Python 3.10+
- **Node.js**: Node v20+ (for TypeScript client)

### Building and Testing

```bash
# Run all 124 Flix test suites
flix test

# Execute C11 native performance tests
make test-c

# Execute Python visualizer and generator tests
make test-python

# Compile and test TypeScript PCS client
make test-ts

# Run unified test verification pass
make test-all
```

---

## Command-Line Interface

Spreader includes an execution CLI for terminal operations:

```bash
# Display general help and command options
flix run -- help

# Run the 14,000 TEU mega-vessel port turnaround benchmark
flix run -- benchmark

# Compute intact stability, GM_T, trim, and hull girder bending moment
flix run -- stability

# Optimize multi-crane bay split across STS cranes
flix run -- crane split

# Render ANSI colored vessel bay cross-section
flix run -- render bay

# Render top-down automated yard block ASC map
flix run -- render yard
```

### Sample Benchmark Output

```text
=== SPREADER PORT CALL TURNAROUND BENCHMARK ===
Vessel Name:            MV Spreader Pride
Nominal Capacity:       14000 TEU
Total Moves:            1200 (600 discharge, 600 load)
STS Quay Cranes:        4
AGV Fleet Size:         20
Dual Cycling Enabled:   true
Elapsed Seconds:        22788.0
Berth Turnaround Time:  6.33 hours
Average Crane GMPH:     47.4 moves/hr/crane
```

---

## Empirical Benchmarks

| Metric | Measurement | Description |
| :--- | :--- | :--- |
| **Flix Automated Tests** | 124 / 124 passing | Zero test regressions across all modules |
| **Test Suite Velocity** | 48.8 milliseconds | High-speed JVM execution of all unit & integration tests |
| **Datalog IMDG Convergence** | 3.2 milliseconds | Fixed-point resolution over 1,500 container pairs |
| **C11 Lexer Throughput** | 485 MB / second | Zero-allocation streaming tokenization of 50MB BAPLIE |
| **Dual Cycling Gain** | +28.8% throughput | 8.16 hours down to 6.33 hours berth turnaround |

---

## Documentation

Detailed architectural and mathematical specifications are located in the `docs/` directory:
- [System Architecture](docs/ARCHITECTURE.md): Subsystems, module boundaries, and data flows.
- [IMDG Table 7.2.4 Datalog Rules](docs/IMDG_SPEC.md): Horn clauses and segregation mechanics.
- [Marine Hydrostatics & Longitudinal Strength](docs/HYDROSTATICS.md): Intact stability, $GM_T$, trim, and shear force integration.
- [EDIFACT Message Specifications](docs/EDIFACT_SPEC.md): SMDG BAPLIE, MOVINS, and COPRAR layout.
- [Performance Benchmarks](docs/BENCHMARKS.md): Turnaround telemetry and empirical timings.

---

## License

MIT License. Copyright (c) 2026 Aneesh Krishna.
