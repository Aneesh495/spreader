# System Architecture and Module Design

Spreader is an automated Container Terminal Operating System (TOS) and Vessel Stowage Planning Engine written in Flix, featuring first-class Datalog fixed-point logic, marine hydrostatics, automated equipment scheduling, and UN/EDIFACT maritime message interchange.

```
+========================================================================================+
|                                     SPREADER CLI                                       |
|                (baplie, coprar, stability, yard, crane, sim, benchmark, render)        |
+========================================================================================+
         |                        |                          |                   |
         v                        v                          v                   v
+------------------+    +--------------------+    +--------------------+  +--------------+
|   EDI SUBSYSTEM  |    |     STABILITY      |    |   YARD & CRANE     |  |  SIMULATION  |
|                  |    |                    |    |                    |  |              |
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

## Architectural Tenets

1. **Relational Correctness via Datalog**: Stowage planning safety rules (hazardous segregation, crane rail clash prevention, and vertical stack strength) are expressed as declarative Horn clauses and evaluated to fixed-point using Flix first-class Datalog.
2. **Naval Architectural Rigor**: Intact stability calculations adhere to IMO International Code on Intact Stability (2008 IS Code), resolving transverse metacentric height ($GM_T$), heel angle, hydrostatic draft forward and aft, and 21-station hull girder longitudinal strength integration.
3. **Zero-Copy Streaming**: Telemetry parsing for high-volume EDIFACT manifests processes memory in a single streaming pass without allocating intermediate objects.
4. **Pure Functional State Machines**: Terminal equipment kinematics, ASC collision protocols, and quay crane cycles are modeled as deterministic pure functions with explicit effect typing.

---

## Subsystem Breakdown

### 1. Model Subsystem (`src/Model/`)

The model subsystem establishes domain primitives for automated maritime logistics:

- **ISO 6346 Container Identifiers (`Container.flix`)**: Validates 4-letter owner prefixes, equipment category identifiers (`U`, `J`, `Z`, `R`), 6-digit serial numbers, and modular check digits. Maps 4-character size/type codes (e.g. `22G1`, `45R1`) to dimensional geometries and tare/payload ratings.
- **ISO 9711 Bay-Row-Tier Coordinate Space (`Coordinates.flix`)**: Models 3-dimensional ship cell coordinates where odd bays represent 20ft slots, even bays represent 40ft slots, odd rows denote starboard positions, even rows denote port positions, and tier numbers distinguish hold cargo (02..18) from on-deck stacks (82..98).
- **IMO IMDG Code Classifications (`HazmatTypes.flix`)**: Models Classes 1.1 through 9, tracking thermal runaway risks, flash points, packing groups (I, II, III), and segregation codes.
- **Vessel Profile & Tank Topologies (`VesselProfile.flix`)**: Encapsulates vessel particulars for Post-Panamax and Neo-Panamax class container ships, defining hold bulkheads, tank top load limits, and ballast wing/double-bottom tanks.

---

### 2. Relational Datalog Subsystem (`src/Datalog/`)

Flix integrates first-class Datalog directly into its functional language, allowing relational constraints to be solved over immutable facts.

- **IMO IMDG Code Table 7.2.4 Segregation (`Imdg.flix`)**:
  Computes pairwise safety violations between hazardous cargo:
  - Code 1 (Away From): minimum 3.0m horizontal clearance or bulkhead separation.
  - Code 2 (Separated From): distinct hold compartments or 6.0m on deck.
  - Code 3 (Separated by a Complete Compartment): complete hold separation.
  - Code 4 (Separated Longitudinally by an Intervening Hold): longitudinal hold separation for Class 1 explosives and organic peroxides.
- **Crane Rail Collision Prevention (`CraneInterlock.flix`)**:
  Enforces dynamic safety margins along the gantry track:
  - Detects physical boom clashes between adjacent Ship-to-Shore (STS) cranes with less than 2 bays of rail separation.
  - Verifies Automated Stacking Crane (ASC) buffer interlocks within yard blocks to prevent dual-trolley collisions in the central handshake zone.
- **Stack Structural Integrity (`StackSafety.flix`)**:
  Enforces physical mechanics across container stacks:
  - Tier weight gradient verification (Heavy-over-Light prevention).
  - Maximum vertical column stack weight limits (e.g. 180 tonnes per 8-high stack).
  - 20-foot container on top of 40-foot container prohibition.
  - Floating container detection (ensuring all containers rest on hatch covers, tank top, or valid lower containers).

---

### 3. Stability & Hydrostatics Subsystem (`src/Stability/`)

Naval architecture hydrostatics engine for vessel intact stability:

- **Hydrostatic Interpolation (`Hydrostatics.flix`)**:
  Interpolates displacement ($\Delta$), vertical center of buoyancy ($KB$), transverse metacentric height ($KM_T$), longitudinal center of buoyancy ($LCB$), and moment to change trim one centimeter ($MTC$) across hydrostatic tables as a function of mean draft.
- **Transverse Stability & Heel Equilibrium (`Hydrostatics.flix`)**:
  Calculates solid $KG$, slack tank free surface inertia moments ($\sum i \cdot \gamma$), fluid metacentric height ($GM_T$), and steady heel angle resulting from transverse center of gravity ($TCG$) eccentricity.
- **Trim & Draft Forward/Aft Solver (`Trim.flix`)**:
  Resolves longitudinal equilibrium by balancing trimming moments ($TM = \Delta \cdot (LCG - LCB)$) against longitudinal moment of trim ($MTC \times 100$), determining trim ($t = df - da$) and operational waterlines.
- **Longitudinal Hull Girder Strength (`LongitudinalStrength.flix`)**:
  Computes Still Water Shear Force ($SWSF$) and Still Water Bending Moment ($SWBM$) across 21 equidistant hull stations ($0 \dots 20$) from Aft Perpendicular to Forward Perpendicular via trapezoidal numerical integration of the load curve ($q(x) = b(x) - w(x)$).
- **Automated Anti-Heeling & Ballast Optimizer (`BallastOptimizer.flix`)**:
  Calculates water ballast transfers between port and starboard wing tanks and fore/aft peak tanks to maintain neutral heel ($< 0.5^\circ$) and design trim ($0.5\text{m} \dots 1.5\text{m}$ by stern).

---

### 4. Automated Yard Subsystem (`src/Yard/`)

- **Yard Block Topology (`YardBlock.flix`)**: Models 3-dimensional storage matrices with bay, row, and tier constraints, ground slot assignments, and specialized reefer plug locations.
- **Container Relocation Problem Solver (`Reshuffle.flix`)**: Implements an exact heuristic solver for minimizing container reshuffles during extraction, identifying blocking containers and marshalling them to target rows with highest pickup priority.
- **Twin ASC Handshake Coordination (`AscScheduler.flix`)**: Schedules waterside and landside automated stacking cranes along shared block tracks, calculating gantry kinematics and enforcing dynamic no-go safety envelopes.
- **Exchange Zone Buffer Management (`ExchangeZoneScheduler.flix`)**: Allocates transfer lanes for waterside battery AGVs and landside over-the-road trucks, tracking lane occupancy and terminal gate throughput.

---

### 5. Crane Optimization Subsystem (`src/Crane/`)

- **Twin-Lift Spreader Pairing (`TwinLift.flix`)**: Evaluates adjacent 20ft container moves for concurrent lift, validating gross weight disparity ($< 10\text{t}$), longitudinal center-of-gravity eccentricity ($< 10\%$), and dangerous goods isolation.
- **Ship-to-Shore Dual Cycling (`DualCycle.flix`)**: Replaces single discharge or load round trips with dual cycles, eliminating empty spreader return legs and increasing effective cycle productivity by 25% to 40%.
- **Bay Split Workload Balancer (`CraneSplit.flix`)**: Solves the contiguous multi-crane workload assignment problem, splitting bays across 3 or 4 STS cranes to equalize crane moves and minimize berth turnaround makespan.

---

### 6. Maritime Telemetry & EDI Subsystem (`src/Edi/`)

- **ISO 9735 EDIFACT Lexer (`Tokenizer.flix`, `SegmentNav.flix`)**: High-throughput parser supporting custom service string advice (`UNA`), nested data elements, component separators, and release escape character handling.
- **SMDG BAPLIE 2.2 / 3.1 (`BaplieParser.flix`, `BaplieGenerator.flix`)**: Ingests and generates standard vessel bayplan interchange messages, preserving 7-character Bay-Row-Tier coordinates, container gross weights, reefer temperature setpoints, and hazardous cargo records.
- **COPRAR Manifest Parser (`CoprarParser.flix`)**: Ingests container discharge orders and outbound loading manifests.
- **MOVINS Stowage Instruction Generator (`MovinsGenerator.flix`)**: Generates operational stowage sequence instructions for crane drivers and automation PLCs.
- **UN/LOCODE Directory & Geodesics (`PortDirectory.flix`)**: Provides port coordinate registry, great-circle nautical distance estimation, voyage rotation tracking, and automatic overstow detection.

---

### 7. Simulation & Visualization Subsystem (`src/Simulation/`, `src/Visualizer/`)

- **Discrete-Event Simulation Engine (`EventQueue.flix`, `QuayGantrySim.flix`, `AgvDispatchSim.flix`)**: Priority event queue simulating crane kinematics, hoist acceleration, twistlock cycling, and battery AGV traffic.
- **Mega-Vessel Benchmark (`BenchmarkScenarios.flix`)**: Simulates 1,200 moves on a 14,000 TEU vessel with 4 STS cranes, 20 AGVs, and 8 yard blocks, reporting Gross Moves Per Hour (GMPH) and berth turnaround hours.
- **ANSI Console Visualizer (`AnsiBayCrossSection.flix`, `YardAsciiMap.flix`)**: Renders full-color 2D vessel bay cross-sections and top-down yard block layout matrices directly in terminal consoles.
