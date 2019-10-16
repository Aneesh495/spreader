// Spreader: Container Terminal Operating System
// Container Yard Block-Bay-Row-Tier Topology and ASC Kinematics

pub mod Model.YardCoordinates {
    use Model.MathUtil.hypot3;

    /// Discrete 4D coordinate within container yard blocks.
    pub type alias YardSlot = {
        block = String, // Block identifier (e.g. "A", "B", "EAST_01")
        bay = Int32,    // Longitudinal yard bay (1..60)
        row = Int32,    // Transverse yard row (1..8)
        tier = Int32    // Vertical yard tier (1..6), where 1 = ground slot
    }

    /// Functional exchange zone at block boundaries.
    pub enum ExchangeZone with Eq, Order, ToString {
        case WatersideTransfer, // AGV / internal transfer vehicle interface
        case LandsideGate,      // External road truck exchange interface
        case RailIntermodal     // Direct on-dock rail transfer interface
    }

    /// Yard crane kinematic velocity and acceleration parameters.
    pub type alias AscKinematics = {
        gantrySpeedMps = Float64,   // Longitudinal rail travel speed (m/s)
        trolleySpeedMps = Float64,  // Transverse trolley cross-travel speed (m/s)
        hoistSpeedMps = Float64,    // Vertical hoist lift speed (m/s)
        twistlockCycleSec = Float64 // Twistlock lock/unlock and landing duration (s)
    }

    /// Default kinematic specifications for modern automated stacking cranes.
    pub def defaultAscKinematics(): AscKinematics = {
        gantrySpeedMps = 4.0,       // 240 m/min
        trolleySpeedMps = 1.2,      // 72 m/min
        hoistSpeedMps = 0.8,        // 48 m/min
        twistlockCycleSec = 8.0     // 8 seconds locking sequence
    }

    /// Standard physical dimensions of a yard slot in meters.
    pub def bayPitchMeters(): Float64 = 6.40   // 20ft container length + buffer
    pub def rowPitchMeters(): Float64 = 2.80   // 8ft container width + clearance
    pub def tierPitchMeters(): Float64 = 2.90  // High-cube container height + spreader clearance

    /// Computes spatial distance in meters between two yard slots within the same block.
    pub def slotDistanceMeters(s1: YardSlot, s2: YardSlot): Float64 = {
        if (s1#block != s2#block) 99999.0 // Cross-block moves require transfer vehicles
        else {
            let dx = Int32.toFloat64(Int32.abs(s1#bay - s2#bay)) * bayPitchMeters();
            let dy = Int32.toFloat64(Int32.abs(s1#row - s2#row)) * rowPitchMeters();
            let dz = Int32.toFloat64(Int32.abs(s1#tier - s2#tier)) * tierPitchMeters();
            hypot3(dx, dy, dz)
        }
    }

    /// Estimates ASC crane travel duration in seconds between two slots.
    /// Gantry and trolley operate simultaneously (Chebyshev concurrency);
    /// hoist travel occurs with safety lift clearance.
    pub def estimateAscMoveDurationSec(k: AscKinematics, fromSlot: YardSlot, toSlot: YardSlot): Float64 = {
        if (fromSlot#block != toSlot#block) 99999.0
        else {
            let dx = Int32.toFloat64(Int32.abs(fromSlot#bay - toSlot#bay)) * bayPitchMeters();
            let dy = Int32.toFloat64(Int32.abs(fromSlot#row - toSlot#row)) * rowPitchMeters();
            let dz = Int32.toFloat64(Int32.abs(fromSlot#tier - toSlot#tier)) * tierPitchMeters();

            let tGantry = dx / k#gantrySpeedMps;
            let tTrolley = dy / k#trolleySpeedMps;
            let tHoist = (dz + 2.0 * tierPitchMeters()) / k#hoistSpeedMps; // Lift above stack + lower

            let tTravel = Float64.max(tGantry, tTrolley) + tHoist;
            tTravel + 2.0 * k#twistlockCycleSec // Pick and place twistlock cycles
        }
    }

    /// Validates yard slot address consistency.
    pub def isValidYardSlot(s: YardSlot): Bool =
        String.length(s#block) > 0 and
        s#bay >= 1 and s#bay <= 80 and
        s#row >= 1 and s#row <= 12 and
        s#tier >= 1 and s#tier <= 6

    /// Formats a yard slot into human-readable string (e.g. "A-12-03-2").
    pub def formatYardSlot(s: YardSlot): String = {
        let pad2 = n -> if (n < 10) "0${n}" else "${n}";
        "${s#block}-${pad2(s#bay)}-${pad2(s#row)}-${s#tier}"
    }
}
