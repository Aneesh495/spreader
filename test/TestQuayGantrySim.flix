// Spreader: Container Terminal Operating System
// Test Suite for Ship-to-Shore Quay Crane Kinematics and Cycle Dynamics

mod TestQuayGantrySim {

    use Simulation.QuayGantrySim
    use Simulation.QuayGantrySim.StsKinematicsConfig

    @Test
    def testKinematicsDefaults(): Unit \ Assert = {
        let cfg = QuayGantrySim.defaultKinematics();
        Assert.assertTrue(cfg#trolleyMaxSpeed >= 3.5);
        Assert.assertTrue(cfg#hoistSpeedEmpty > cfg#hoistSpeedLoaded);
        Assert.assertTrue(cfg#twistlockLockDuration > 5.0)
    }

    @Test
    def testHoistDistanceEstimation(): Unit \ Assert = {
        // Deck tier 82 (bottom of deck stack) vs tier 96 (top of 8-tier deck stack)
        let deckDistLow = QuayGantrySim.estimateHoistDistance(82, true);
        let deckDistHigh = QuayGantrySim.estimateHoistDistance(96, true);
        Assert.assertTrue(deckDistHigh > deckDistLow);

        // Under deck tier 02 (bottom of hold) vs tier 16 (near deck)
        let holdDistDeep = QuayGantrySim.estimateHoistDistance(2, false);
        let holdDistShallow = QuayGantrySim.estimateHoistDistance(16, false);
        Assert.assertTrue(holdDistDeep > holdDistShallow)
    }

    @Test
    def testTrolleyDistanceEstimation(): Unit \ Assert = {
        let cfg = QuayGantrySim.defaultKinematics();
        let centerDist = QuayGantrySim.estimateTrolleyDistance(0, cfg);
        let outerDist = QuayGantrySim.estimateTrolleyDistance(16, cfg);
        Assert.assertTrue(outerDist > centerDist)
    }

    @Test
    def testSingleCycleDuration(): Unit \ Assert = {
        let cfg = QuayGantrySim.defaultKinematics();
        // Move container from row 4, tier 84 (deck), 22 tonnes
        let duration = QuayGantrySim.computeSingleCycleDuration(84, 4, true, 22.0, cfg);
        // Realistic STS single cycle should take between 50 and 120 seconds
        Assert.assertTrue(duration >= 50.0);
        Assert.assertTrue(duration <= 120.0)
    }

    @Test
    def testDualCycleEfficiency(): Unit \ Assert = {
        let cfg = QuayGantrySim.defaultKinematics();
        let single1 = QuayGantrySim.computeSingleCycleDuration(86, 6, true, 20.0, cfg);
        let single2 = QuayGantrySim.computeSingleCycleDuration(88, 6, true, 24.0, cfg);
        let twoSingles = single1 + single2;

        let dual = QuayGantrySim.computeDualCycleDuration(86, 6, true, 88, 6, true, cfg);
        // Dual cycling should be faster than two separate single cycles
        Assert.assertTrue(dual < twoSingles)
    }
}
