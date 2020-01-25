// Spreader: Container Terminal Operating System
// Root Module and Clock Types for Discrete-Event Terminal Simulation

pub mod Simulation {

    use Model.MathUtil

    /// Discrete simulation clock timestamp in elapsed seconds.
    pub type alias SimClock = Float64

    /// Configuration parameters for a terminal simulation run.
    pub type alias SimulationConfig = {
        stsCraneCount = Int32,
        agvFleetSize = Int32,
        ascBlockCount = Int32,
        maxDurationSeconds = Float64,
        randomSeed = Int64
    }

    /// Macro-level summary metrics produced at the conclusion of a simulation run.
    pub type alias SimulationMetrics = {
        elapsedSeconds = Float64,
        totalDischarged = Int32,
        totalLoaded = Int32,
        totalMoves = Int32,
        quayCraneGrossMph = Float64,
        berthTurnaroundHours = Float64
    }

    /// Default configuration for a high-capacity automated container terminal.
    pub def defaultConfig(): SimulationConfig = {
        stsCraneCount = 4,
        agvFleetSize = 24,
        ascBlockCount = 8,
        maxDurationSeconds = 86400.0, // 24 hours
        randomSeed = 1337i64
    }

    /// Formats elapsed simulation seconds into HH:MM:SS string.
    pub def formatSimClock(totalSec: Float64): String = {
        let clamped = MathUtil.clamp(totalSec, 0.0, 8640000.0);
        let secInt = match Float64.tryToInt32(clamped) {
            case Some(s) => s
            case None => 0
        };
        let hours = secInt / 3600;
        let rem = Int32.modulo(secInt, 3600);
        let minutes = rem / 60;
        let seconds = Int32.modulo(rem, 60);

        let hStr = if (hours < 10) "0${hours}" else "${hours}";
        let mStr = if (minutes < 10) "0${minutes}" else "${minutes}";
        let sStr = if (seconds < 10) "0${seconds}" else "${seconds}";
        "${hStr}:${mStr}:${sStr}"
    }

    /// Computes Gross Moves Per Hour (GMPH) across all active STS quay cranes.
    pub def computeGmph(totalMoves: Int32, elapsedSeconds: Float64, craneCount: Int32): Float64 = {
        if (elapsedSeconds <= 0.0 or craneCount <= 0) 0.0
        else {
            let hours = elapsedSeconds / 3600.0;
            let craneHours = hours * Int32.toFloat64(craneCount);
            Int32.toFloat64(totalMoves) / craneHours
        }
    }
}
