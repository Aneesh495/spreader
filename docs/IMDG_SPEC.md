# IMO IMDG Code Table 7.2.4 Relational Datalog Specification

This document details the mathematical and relational formalization of the International Maritime Organization (IMO) International Maritime Dangerous Goods (IMDG) Code Table 7.2.4 segregation matrix, as implemented in Flix first-class Datalog within `src/Datalog/Imdg.flix`.

---

## 1. Dangerous Goods Classification Schema

The IMDG Code partitions hazardous cargo into 9 primary hazard classes and subdivisions:

| Class | Subdivision | Description |
| :--- | :--- | :--- |
| **1** | 1.1 - 1.6 | Explosives (mass explosion, projection, minor blast) |
| **2** | 2.1 | Flammable Gases |
| | 2.2 | Non-Flammable, Non-Toxic Compressed Gases |
| | 2.3 | Toxic Gases |
| **3** | - | Flammable Liquids (flashpoint $< 60^\circ\text{C}$) |
| **4** | 4.1 | Flammable Solids, self-reactive substances |
| | 4.2 | Substances Liable to Spontaneous Combustion |
| | 4.3 | Substances Emitting Flammable Gases in Contact with Water |
| **5** | 5.1 | Oxidizing Substances |
| | 5.2 | Organic Peroxides |
| **6** | 6.1 | Toxic Substances |
| | 6.2 | Infectious Substances |
| **7** | - | Radioactive Material |
| **8** | - | Corrosive Substances |
| **9** | - | Miscellaneous Dangerous Substances and Environmentally Hazardous Cargo |

---

## 2. Mathematical Definition of Table 7.2.4 Segregation Codes

Let $\mathcal{C}$ denote the set of hazardous material classes:
$$\mathcal{C} = \{ 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 2.1, 2.2, 2.3, 3, 4.1, 4.2, 4.3, 5.1, 5.2, 6.1, 6.2, 7, 8, 9 \}$$

The segregation function $\sigma: \mathcal{C} \times \mathcal{C} \to \{0, 1, 2, 3, 4\}$ defines the minimum legal spatial isolation between two containerized dangerous goods shipments:

- **Code 0 ("No general restriction")**: May be stowed in adjacent cells or within the same hold, provided individual packing compatibility permits.
- **Code 1 ("Away from")**:
  - *On Deck*: Minimum 3.0 meters horizontal clearance between container envelopes (at least one container space).
  - *Under Deck*: Not permitted in the same vertical stack; must be separated by at least one bulkhead or adjacent hold space.
- **Code 2 ("Separated from")**:
  - *On Deck*: Minimum 6.0 meters horizontal clearance (at least two container spaces athwartships or longitudinally).
  - *Under Deck*: Prohibited in the same hold compartment. Must be stowed in distinct cargo holds separated by a gastight and watertight steel bulkhead.
- **Code 3 ("Separated by a complete compartment or hold from")**:
  - *On Deck*: Minimum 12.0 meters horizontal clearance (at least three container spaces).
  - *Under Deck*: Must be separated by a complete intervening cargo hold or machinery space.
- **Code 4 ("Separated longitudinally by an intervening complete compartment or hold from")**:
  - *On Deck*: Minimum 24.0 meters longitudinal clearance.
  - *Under Deck*: Prohibited in adjacent holds. At least one complete intervening hold compartment must lie between the two shipments. Required for mass-detonation explosives (Class 1.1, 1.2) adjacent to flammable liquids (Class 3) and organic peroxides (Class 5.2).

---

## 3. Relational Datalog Formulation in Flix

In Spreader, the stowage plan is projected into immutable Datalog relations, and safety violations are computed via stratified fixed-point deduction.

### Extensional Database (EDB Facts)

```flix
// Container hazard class declaration
rel ContainerClass(containerId: String, primaryClass: ImdgClass)

// Spatial location and hold compartment boundaries
rel CellPosition(containerId: String, bay: Int32, row: Int32, tier: Int32)
rel HoldAssignment(containerId: String, holdNumber: Int32)
rel DeckLevel(containerId: String, isDeck: Bool)
```

### Intensional Rules (IDB Deduction)

```flix
// Bay longitudinal separation metric (each 40ft bay ~ 14.5m)
rel BayDistance(c1: String, c2: String, distBays: Int32)
BayDistance(c1, c2, dist) :-
    CellPosition(c1, b1, _, _),
    CellPosition(c2, b2, _, _),
    dist = Int32.abs(b1 - b2).

// Hold compartment separation metric
rel HoldDistance(c1, c2, distHolds)
HoldDistance(c1, c2, dist) :-
    HoldAssignment(c1, h1),
    HoldAssignment(c2, h2),
    dist = Int32.abs(h1 - h2).

// Violation 1: Under-deck stowage in the same hold for Code >= 2
rel ImdgSegregationViolation(c1: String, c2: String, code: Int32, reason: String)

ImdgSegregationViolation(c1, c2, 2, "Code 2 violation: incompatible cargo in same cargo hold") :-
    ContainerClass(c1, classA),
    ContainerClass(c2, classB),
    Table724RequiredCode(classA, classB, 2),
    DeckLevel(c1, false),
    DeckLevel(c2, false),
    HoldAssignment(c1, h),
    HoldAssignment(c2, h).

// Violation 2: Adjacent hold stowage for Code 4 (intervening hold required)
ImdgSegregationViolation(c1, c2, 4, "Code 4 violation: adjacent holds without intervening compartment") :-
    ContainerClass(c1, classA),
    ContainerClass(c2, classB),
    Table724RequiredCode(classA, classB, 4),
    DeckLevel(c1, false),
    DeckLevel(c2, false),
    HoldDistance(c1, c2, d),
    d < 2.
```

---

## 4. Empirical Safety Verification

The Datalog solver executes before any vessel departure and prior to crane work instruction dispatch. If `query ImdgSegregationViolation` yields non-empty tuples, the stowage plan is rejected and work instructions for the affected cells are locked in the TOS database.
