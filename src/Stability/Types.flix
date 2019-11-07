// Spreader: Container Terminal Operating System
// Marine Hydrostatics and Naval Architecture Data Models

pub mod Stability.Types {

    /// Point mass representation for stability moment summations.
    pub type alias LoadingItem = {
        label = String,
        weightTonnes = Float64,
        lcgMeters = Float64,  // Longitudinal: positive forward of midships, negative aft
        tcgMeters = Float64,  // Transverse: positive starboard, negative port
        kgMeters = Float64    // Vertical: meters above keel baseline (K)
    }

    /// Hydrostatic tabular property entry for a specific vessel draft.
    pub type alias HydrostaticEntry = {
        draftMeters = Float64,
        displacementTonnes = Float64,
        tpcTonnesPerCm = Float64,       // Tonnes per centimeter immersion
        mtcTonnesMetersPerCm = Float64, // Moment to change trim by 1 cm
        lcbMeters = Float64,            // Longitudinal Center of Buoyancy
        kbMeters = Float64,             // Vertical Center of Buoyancy
        kmtMeters = Float64,            // Transverse Metacentric Height above baseline
        kmlMeters = Float64             // Longitudinal Metacentric Height above baseline
    }

    /// Free surface moment entry for liquid cargo and ballast tanks.
    pub type alias FreeSurfaceItem = {
        tankId = String,
        liquidDensityTonnesPerM3 = Float64,
        secondMomentOfAreaM4 = Float64, // I_t = l * b^3 / 12 for rectangular tanks
        isSlack = Bool                  // True if tank level is between 5% and 95%
    }

    /// Complete floating equilibrium stability state.
    pub type alias StabilityState = {
        displacementTonnes = Float64,
        totalDeadweightTonnes = Float64,
        kgSolidMeters = Float64,
        fseMeters = Float64,
        kgFluidMeters = Float64,
        lcgMeters = Float64,
        tcgMeters = Float64,
        kmtMeters = Float64,
        gmtFluidMeters = Float64,
        draftMidMeters = Float64,
        draftFwdMeters = Float64,
        draftAftMeters = Float64,
        trimMeters = Float64,           // Positive trim by stern, negative trim by head
        heelAngleDegrees = Float64,     // Positive heel to starboard, negative to port
        isCompliant = Bool
    }

    /// IMO Intact Stability Code Criteria (A.749(18) / 2008 IS Code).
    pub type alias IntactStabilityCriteria = {
        minGmtFluidMeters = Float64,    // Standard container vessel: >= 0.30m or 0.15m
        maxHeelDegrees = Float64,       // In-port operations: <= 1.5 degrees
        maxTrimSternMeters = Float64,   // Normal operating trim: <= 2.50m
        maxTrimHeadMeters = Float64     // Trim by head not allowed: <= 0.0m
    }

    /// Default IMO criteria for modern container vessels.
    pub def defaultCriteria(): IntactStabilityCriteria = {
        minGmtFluidMeters = 0.30,
        maxHeelDegrees = 1.50,
        maxTrimSternMeters = 2.50,
        maxTrimHeadMeters = 0.00
    }
}
