// Spreader: Container Terminal Operating System
// Ship-to-Shore (STS) Quay Crane Kinematics, Hoist/Trolley Dynamics, and Cycle Time Engine

pub mod Simulation.QuayGantrySim {

    use Model.MathUtil

    /// Kinematic performance parameters of a modern Super Post-Panamax STS crane.
    pub type alias StsKinematicsConfig = {
        trolleyMaxSpeed = Float64,        // m/s (typically 4.0)
        hoistSpeedEmpty = Float64,        // m/s (typically 2.5)
        hoistSpeedLoaded = Float64,       // m/s (typically 1.8)
        twistlockLockDuration = Float64,  // seconds (position, landing, twistlock lock)
        twistlockUnlockDuration = Float64,// seconds (twistlock unlock, unseat)
        quayBufferHeight = Float64,       // meters above quay rail datum
        quayToShipCenterlineDist = Float64// meters from quay rail to ship centerline
    }

    /// Default kinematic specifications for an automated high-speed STS crane.
    pub def defaultKinematics(): StsKinematicsConfig = {
        trolleyMaxSpeed = 4.0,
        hoistSpeedEmpty = 2.5,
        hoistSpeedLoaded = 1.8,
        twistlockLockDuration = 12.0,
        twistlockUnlockDuration = 6.0,
        quayBufferHeight = 16.0,
        quayToShipCenterlineDist = 32.0
    }

    /// Estimates vertical hoist travel distance in meters based on tier coordinate and deck location.
    pub def estimateHoistDistance(tier: Int32, isDeck: Bool): Float64 = {
        if (isDeck) {
            // On deck: tier 82 (tier 1 on deck) up to tier 96 (tier 8 on deck). 2.6m per 8ft6 / 9ft6 container.
            let deckTierIdx = (tier - 82) / 2;
            let stackHeight = Int32.toFloat64(deckTierIdx) * 2.6;
            // Spreader must clear top of stack + 3.0m safety margin above quay buffer
            22.0 + stackHeight
        } else {
            // Below deck: tier 02 (hold bottom) up to tier 18 (top of hold).
            let holdDepth = Int32.toFloat64(18 - tier) * 1.3;
            // Lift from hold bottom up over hatch coaming (18.0m) + clearance
            24.0 + holdDepth
        }
    }

    /// Estimates horizontal trolley travel distance from quay buffer backreach to vessel row.
    pub def estimateTrolleyDistance(row: Int32, cfg: StsKinematicsConfig): Float64 = {
        // Transverse distance from centerline: each container row is 2.44m wide
        let rowDistFromCenter = Int32.toFloat64(row) * 1.25;
        cfg#quayToShipCenterlineDist + rowDistFromCenter
    }

    /// Computes duration in seconds for a single discharge or load cycle.
    /// Trajectory profile: Spreader hoist clear + concurrent trolley traversal + lower to target.
    pub def computeSingleCycleDuration(tier: Int32, row: Int32, isDeck: Bool, grossWeightTonnes: Float64, cfg: StsKinematicsConfig): Float64 = {
        let hoistDist = estimateHoistDistance(tier, isDeck);
        let trolleyDist = estimateTrolleyDistance(row, cfg);

        // Hoist speed depends on payload mass
        let loadedHoistSpeed = if (grossWeightTonnes > 25.0) cfg#hoistSpeedLoaded * 0.9 else cfg#hoistSpeedLoaded;

        // Outbound leg (empty spreader to cell):
        // 1. Hoist up over quay buffer: quayBufferHeight / hoistSpeedEmpty
        // 2. Trolley to vessel row concurrent with final cell positioning
        // 3. Lower spreader into cell guide: hoistDist / hoistSpeedEmpty
        let outboundTrolley = trolleyDist / cfg#trolleyMaxSpeed;
        let outboundHoist = (cfg#quayBufferHeight + hoistDist) / cfg#hoistSpeedEmpty;
        let outboundTime = Float64.max(outboundTrolley, outboundHoist * 0.6) + (outboundHoist * 0.4);

        // Inbound leg (loaded container to quay buffer / AGV):
        // 1. Hoist up out of cell guides: hoistDist / loadedHoistSpeed
        // 2. Trolley to quay concurrent with transit
        // 3. Lower onto AGV chassis: quayBufferHeight / loadedHoistSpeed
        let inboundTrolley = trolleyDist / cfg#trolleyMaxSpeed;
        let inboundHoist = (hoistDist + cfg#quayBufferHeight) / loadedHoistSpeed;
        let inboundTime = Float64.max(inboundTrolley, inboundHoist * 0.6) + (inboundHoist * 0.4);

        // Total cycle: outbound + lock twistlocks + inbound + unlock twistlocks
        outboundTime + cfg#twistlockLockDuration + inboundTime + cfg#twistlockUnlockDuration
    }

    /// Computes duration in seconds for an integrated dual cycle (simultaneous discharge + load).
    pub def computeDualCycleDuration(dischTier: Int32, dischRow: Int32, dischDeck: Bool,
                                     loadTier: Int32, loadRow: Int32, loadDeck: Bool,
                                     cfg: StsKinematicsConfig): Float64 = {
        let dischHoistDist = estimateHoistDistance(dischTier, dischDeck);
        let dischTrolleyDist = estimateTrolleyDistance(dischRow, cfg);
        let dischLiftTime = (dischHoistDist + cfg#quayBufferHeight) / cfg#hoistSpeedLoaded;
        let dischTrolleyTime = dischTrolleyDist / cfg#trolleyMaxSpeed;
        let dischLeg = Float64.max(dischTrolleyTime, dischLiftTime * 0.6) + (dischLiftTime * 0.4);

        let loadHoistDist = estimateHoistDistance(loadTier, loadDeck);
        let loadTrolleyDist = estimateTrolleyDistance(loadRow, cfg);
        let loadLiftTime = (loadHoistDist + cfg#quayBufferHeight) / cfg#hoistSpeedLoaded;
        let loadTrolleyTime = loadTrolleyDist / cfg#trolleyMaxSpeed;
        let loadLeg = Float64.max(loadTrolleyTime, loadLiftTime * 0.6) + (loadLiftTime * 0.4);

        // Repositioning between discharge cell and load cell
        let repositionTrolley = Float64.abs(dischTrolleyDist - loadTrolleyDist) / cfg#trolleyMaxSpeed;
        let repositionTime = Float64.max(repositionTrolley, 8.0);

        dischLeg + cfg#twistlockLockDuration + cfg#twistlockUnlockDuration +
        repositionTime +
        loadLeg + cfg#twistlockLockDuration + cfg#twistlockUnlockDuration
    }
}
