// Test suite for STS Quay Crane Dual-Cycling and Workload Scheduling

mod TestDualCycle {
    use Model.EquipmentTypes.MoveType;
    use Crane.DualCycle.{CycleMove, CraneTask, buildDualCycleSchedule};

    def makeDischarge(id: String, bay: Int32, row: Int32, tier: Int32): CraneTask = {
        containerId = id,
        moveType = MoveType.VesselDischarge,
        bay = bay,
        row = row,
        tier = tier
    }

    def makeLoad(id: String, bay: Int32, row: Int32, tier: Int32): CraneTask = {
        containerId = id,
        moveType = MoveType.VesselLoad,
        bay = bay,
        row = row,
        tier = tier
    }

    @Test
    def testSymmetricDualCycling(): Unit \ Assert = {
        let d1 = makeDischarge("D1", 1, 1, 86);
        let d2 = makeDischarge("D2", 1, 1, 84);
        let l1 = makeLoad("L1", 1, 3, 82);
        let l2 = makeLoad("L2", 1, 3, 84);

        let plan = buildDualCycleSchedule(d1 :: d2 :: Nil, l1 :: l2 :: Nil);
        Assert.assertEq(expected = 2, plan#numDischarges);
        Assert.assertEq(expected = 2, plan#numLoads);
        Assert.assertEq(expected = 2, plan#numDualCycles);
        // Total moves = 2 dual cycles = 2 * 145 = 290s vs baseline 4 * 110 = 440s
        Assert.assertTrue(plan#timeSavingsPercent > 30.0)
    }

    @Test
    def testAsymmetricDualCycling(): Unit \ Assert = {
        let d1 = makeDischarge("D1", 1, 1, 86);
        let d2 = makeDischarge("D2", 1, 1, 84);
        let d3 = makeDischarge("D3", 1, 1, 82);
        let l1 = makeLoad("L1", 1, 3, 82);

        let plan = buildDualCycleSchedule(d1 :: d2 :: d3 :: Nil, l1 :: Nil);
        Assert.assertEq(expected = 3, plan#numDischarges);
        Assert.assertEq(expected = 1, plan#numLoads);
        Assert.assertEq(expected = 1, plan#numDualCycles);
        Assert.assertEq(expected = 3, List.length(plan#cycles)); // 1 dual + 2 single discharges
        Assert.assertTrue(plan#timeSavingsPercent > 10.0)
    }
}
