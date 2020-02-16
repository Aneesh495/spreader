// Spreader: Container Terminal Operating System
// Test Suite for Simulation Metrics and 14,000 TEU Mega-Vessel Benchmark

mod TestSimulation {

    use Simulation.{formatSimClock, computeGmph, SimulationMetrics}
    use Simulation.BenchmarkScenarios
    use Simulation.BenchmarkScenarios.BenchmarkWorkload

    @Test
    def testClockFormatting(): Unit \ Assert = {
        Assert.assertEq(expected = "00:00:00", formatSimClock(0.0));
        Assert.assertEq(expected = "00:01:05", formatSimClock(65.0));
        Assert.assertEq(expected = "01:01:05", formatSimClock(3665.0));
        Assert.assertEq(expected = "24:00:00", formatSimClock(86400.0))
    }

    @Test
    def testGmphCalculation(): Unit \ Assert = {
        // 120 moves over 1 hour (3600s) on 4 cranes -> 120 / 4 = 30 moves/hr/crane
        let gmph = computeGmph(120, 3600.0, 4);
        Assert.assertTrue(gmph > 29.9 and gmph < 30.1)
    }

    @Test
    def testMegaVesselTurnaroundBenchmark(): Unit \ Assert = {
        let scenario = BenchmarkScenarios.neoPanamaxScenario();
        let metrics = BenchmarkScenarios.runBenchmark(scenario);

        Assert.assertEq(expected = 1200, metrics#totalMoves);
        Assert.assertEq(expected = 600, metrics#totalDischarged);
        Assert.assertEq(expected = 600, metrics#totalLoaded);

        // Turnaround of 1200 moves across 4 modern automated cranes should complete in 5 to 10 hours
        Assert.assertTrue(metrics#berthTurnaroundHours >= 4.0);
        Assert.assertTrue(metrics#berthTurnaroundHours <= 10.0);

        // Individual crane productivity should reach 30 to 55 GMPH
        Assert.assertTrue(metrics#quayCraneGrossMph >= 30.0);
        Assert.assertTrue(metrics#quayCraneGrossMph <= 55.0)
    }

    @Test
    def testDualCycleProductivityGain(): Unit \ Assert = {
        let baseScenario = BenchmarkScenarios.neoPanamaxScenario();
        let withDualCycling = BenchmarkScenarios.runBenchmark(baseScenario);
        let withoutDualCycling = BenchmarkScenarios.runBenchmark({ enableDualCycling = false | baseScenario });

        // Dual cycling must achieve higher gross moves per hour and shorter berth turnaround
        Assert.assertTrue(withDualCycling#quayCraneGrossMph > withoutDualCycling#quayCraneGrossMph);
        Assert.assertTrue(withDualCycling#berthTurnaroundHours < withoutDualCycling#berthTurnaroundHours)
    }
}
