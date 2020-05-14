# Marine Hydrostatics, Vessel Equilibrium, and Longitudinal Strength

This document presents the naval architecture mathematical formulations implemented in Spreader across `src/Stability/Hydrostatics.flix`, `src/Stability/Trim.flix`, and `src/Stability/LongitudinalStrength.flix`.

---

## 1. Coordinate System and Centers of Gravity

The vessel geometry follows the international naval architectural convention:
- **X-axis (Longitudinal)**: Origin at Midships ($\bigotimes$). Forward is positive ($+x$), Aft is negative ($-x$).
- **Y-axis (Transverse)**: Origin at Centerline ($CL$). Starboard is positive ($+y$), Port is negative ($-y$).
- **Z-axis (Vertical)**: Origin at Keel ($K$). Upward is positive ($+z$).

### Displacement and Center of Gravity Integration

Given a vessel with lightship displacement $\Delta_0$, lightship vertical center $KG_0$, and lightship longitudinal center $LCG_0$, loaded with $N$ discrete containers and ballast tanks each having mass $w_i$ at coordinates $(x_i, y_i, z_i)$:

$$\Delta_{\text{total}} = \Delta_0 + \sum_{i=1}^N w_i$$

$$KG_{\text{solid}} = \frac{\Delta_0 \cdot KG_0 + \sum_{i=1}^N w_i \cdot z_i}{\Delta_{\text{total}}}$$

$$LCG = \frac{\Delta_0 \cdot LCG_0 + \sum_{i=1}^N w_i \cdot x_i}{\Delta_{\text{total}}}$$

$$TCG = \frac{\sum_{i=1}^N w_i \cdot y_i}{\Delta_{\text{total}}}$$

---

## 2. Free Surface Effect (FSE) Correction

When ballast or fuel oil tanks are slack (neither 100% full nor 0% empty), the liquid shifts athwartships as the ship rolls, generating a virtual loss of metacentric height.

For a rectangular tank compartment of length $l$ and breadth $b$:
$$i_T = \frac{l \cdot b^3}{12}$$

The free surface moment of inertia with liquid density $\rho$:
$$\text{FSM} = i_T \cdot \rho$$

The virtual rise in the vertical center of gravity ($FSE$):
$$FSE = \frac{\sum_{j} \text{FSM}_j}{\Delta_{\text{total}}}$$

$$KG_{\text{fluid}} = KG_{\text{solid}} + FSE$$

---

## 3. Transverse Metacentric Height ($GM_T$) and Heel Angle

Transverse stability governs a vessel's ability to resist rolling and overturning moments:

$$GM_T = KM_T(\Delta) - KG_{\text{fluid}}$$

where $KM_T(\Delta)$ is interpolated from the vessel's hydrostatic particulars table.

### Steady Heel Angle Calculation

Any non-zero transverse center of gravity ($TCG \ne 0$) produces a static list or heel angle $\theta$:

$$\tan \theta = \frac{TCG}{GM_T} \implies \theta = \arctan\left(\frac{TCG}{GM_T}\right)$$

### Regulatory Compliance Criteria

Per IMO Resolution MSC.267(85) (2008 Intact Stability Code):
- Fluid $GM_T \ge 0.15 \text{ meters}$ across all seagoing loading conditions.
- Static heel angle $|\theta| \le 1.0^\circ$ for port departure, and $|\theta| \le 0.5^\circ$ during automated crane operations.

---

## 4. Longitudinal Equilibrium and Trim Solver

Longitudinal equilibrium is resolved by matching the longitudinal center of buoyancy ($LCB$) to the longitudinal center of gravity ($LCG$).

The trimming moment ($TM$) in tonne-meters:
$$TM = \Delta_{\text{total}} \cdot (LCG - LCB(\Delta))$$

The total trim ($t = d_A - d_F$) in meters:
$$t = \frac{TM}{MTC(\Delta) \times 100}$$

where $MTC(\Delta)$ is the moment to change trim one centimeter (tonne-m/cm).

### Forward and Aft Operational Drafts

Given mean hydrostatic draft amidships $d_{\text{mid}}$:
$$d_F = d_{\text{mid}} - \frac{t}{2}$$
$$d_A = d_{\text{mid}} + \frac{t}{2}$$

A vessel trims by the stern when $t > 0$ ($d_A > d_F$), which is standard operational practice for container vessels to ensure propeller immersion and directional steering stability.

---

## 5. Hull Girder Longitudinal Strength Integration

The container vessel hull is treated as a non-uniform continuous beam subjected to distributed upward buoyant forces and downward gravity loads along length between perpendiculars ($L_{BP}$).

The ship length is discretized into 21 equidistant stations:
$$x_k = k \cdot \frac{L_{BP}}{20}, \quad k \in [0, 20]$$

### Load Curve

At each station $x$:
$$q(x) = b(x) - w(x)$$
where:
- $b(x)$ is the local buoyancy force per unit length (proportional to submerged cross-sectional station area).
- $w(x)$ is the sum of local lightship steel weight, container stack weights, and ballast tank water.

### Still Water Shear Force (SWSF)

The vertical shear force $V(x)$ is the running integral of the net load curve:
$$V(x) = \int_0^x q(\xi) d\xi$$

### Still Water Bending Moment (SWBM)

The longitudinal bending moment $M(x)$ is the running integral of the shear force curve:
$$M(x) = \int_0^x V(\xi) d\xi = \int_0^x (x - \xi) q(\xi) d\xi$$

### Boundary Conditions

Since the ship floats freely in calm water without external vertical supports at bow or stern:
$$V(0) = 0, \quad V(L_{BP}) = 0$$
$$M(0) = 0, \quad M(L_{BP}) = 0$$

The maximum bending moment typically occurs near midships ($x_{10}$). Spreader validates that:
$$\max_{x} |M(x)| \le M_{\text{permissible}}$$
preventing catastrophic hull buckling (hogging or sagging).
