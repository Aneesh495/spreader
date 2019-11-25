// Test suite for Crane Precedence DAG Verification and Productivity Analytics

mod TestPrecedence {
    use Crane.DualCycle.CycleMove;
    use Crane.Precedence.{
        PrecedenceViolation, computeProductivity, checkCyclePairSafety, validateSchedulePrecedence
    };

    @Test
    def testProductivityMetrics(): Unit \ Assert = {
        // 10 discharges, 10 loads, all 10 done as dual cycles
        // Total moves = 20, Total trips = 10 -> Efficiency = 2.0
        // Duration: 10 * 145s = 1450s
        let metrics = computeProductivity(10, 10, 10, 1450.0);
        Assert.assertEq(expected = 20, metrics#totalContainerMoves);
        Assert.assertEq(expected = 10, metrics#totalTrolleyTrips);
        Assert.assertEq(expected = 2.0, metrics#efficiencyFactor);
        // GMPH = (20 * 3600) / 1450 = 72000 / 1450 approx 49.65
        Assert.assertTrue(metrics#grossMovesPerHour > 49.0 and metrics#grossMovesPerHour < 50.0)
    }

    @Test
    def testCyclePairSafety(): Unit \ Assert = {
        // 1. Safe pair: Discharge Bay 1 Row 1 Tier 86, Load Bay 1 Row 3 Tier 82 (different rows)
        let safePair = CycleMove.DualCyclePair("D1", 1, 1, 86, "L1", 1, 3, 82);
        Assert.assertEq(expected = None, checkCyclePairSafety(safePair));

        // 2. Unsafe pair: Same column (Bay 1 Row 1), but load tier 86 >= discharge tier 84
        let unsafePair = CycleMove.DualCyclePair("D1", 1, 1, 84, "L1", 1, 1, 86);
        match checkCyclePairSafety(unsafePair) {
            case Some(PrecedenceViolation.LoadBeforeDischargeInSameColumn(b, r, lt, dt)) => {
                Assert.assertEq(expected = 1, b);
                Assert.assertEq(expected = 1, r);
                Assert.assertEq(expected = 86, lt);
                Assert.assertEq(expected = 84, dt)
            }
            case _ => Assert.assertTrue(false)
        };

        let viols = validateSchedulePrecedence(safePair :: unsafePair :: Nil);
        Assert.assertEq(expected = 1, List.length(viols))
    }
}
