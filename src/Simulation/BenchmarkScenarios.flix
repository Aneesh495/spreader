// Spreader: Container Terminal Operating System
// Port Call Turnaround Benchmark: 14,000 TEU Neo-Panamax Mega-Vessel Workload

pub mod Simulation.BenchmarkScenarios {

    use Simulation.{SimulationConfig, SimulationMetrics, computeGmph}
    use Simulation.QuayGantrySim
    use Simulation.QuayGantrySim.StsKinematicsConfig
    use Simulation.AgvDispatchSim

    /// Discrete port call benchmark scenario specification.
    pub type alias BenchmarkWorkload = {
        vesselName = String,
        totalTeuCapacity = Int32,
        dischargeMoves = Int32,
        loadMoves = Int32,
        craneCount = Int32,
        agvFleetSize = Int32,
        enableDualCycling = Bool
    }

    /// Default 14,000 TEU mega-vessel port call scenario.
    pub def neoPanamaxScenario(): BenchmarkWorkload = {
        vesselName = "MV Spreader Pride",
        totalTeuCapacity = 14000,
        dischargeMoves = 600,
        loadMoves = 600,
        craneCount = 4,
        agvFleetSize = 20,
        enableDualCycling = true
    }

    /// Executes terminal simulation for the benchmark scenario and computes operational metrics.
    pub def runBenchmark(workload: BenchmarkWorkload): SimulationMetrics = {
        let totalMoves = workload#dischargeMoves + workload#loadMoves;
        let movesPerCrane = totalMoves / workload#craneCount;
        let kinCfg = QuayGantrySim.defaultKinematics();

        // Baseline single cycle duration in seconds (deck and hold mix)
        let singleCycleDuration = QuayGantrySim.computeSingleCycleDuration(86, 6, true, 22.0, kinCfg);

        // Dual cycle duration for paired discharge and load
        let dualCycleDuration = QuayGantrySim.computeDualCycleDuration(86, 6, true, 88, 6, true, kinCfg);

        // Effective seconds per crane based on dual-cycle ratio
        let craneElapsedSeconds = if (workload#enableDualCycling) {
            // 40% of moves can be dual-cycled into paired round-trips
            let dualCycledContainers = Int32.toFloat64(movesPerCrane) * 0.40;
            let singleContainers = Int32.toFloat64(movesPerCrane) - dualCycledContainers;
            let dualTrips = dualCycledContainers / 2.0;

            (dualTrips * dualCycleDuration) + (singleContainers * singleCycleDuration)
        } else {
            Int32.toFloat64(movesPerCrane) * singleCycleDuration
        };

        // Real-world operational factor: Hatch cover removal, lashing/unlashing, and crane lane clearance
        let operationalFactor = 1.45;

        // AGV fleet buffer delay factor: If AGV:Crane ratio < 5.0, add waiting penalty
        let agvRatio = Int32.toFloat64(workload#agvFleetSize) / Int32.toFloat64(workload#craneCount);
        let agvWaitFactor = if (agvRatio < 4.0) 1.15 else if (agvRatio < 5.0) 1.05 else 1.00;

        let totalElapsedSeconds = craneElapsedSeconds * operationalFactor * agvWaitFactor;
        let gmph = computeGmph(totalMoves, totalElapsedSeconds, workload#craneCount);
        let turnaroundHours = totalElapsedSeconds / 3600.0;

        {
            elapsedSeconds = totalElapsedSeconds,
            totalDischarged = workload#dischargeMoves,
            totalLoaded = workload#loadMoves,
            totalMoves = totalMoves,
            quayCraneGrossMph = gmph,
            berthTurnaroundHours = turnaroundHours
        }
    }
}
