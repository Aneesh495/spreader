// Test suite for Multi-Crane Bay Split and Workload Balancing

mod TestCraneSplit {
    use Crane.CraneSplit.{BayWorkload, balanceCraneBays};

    @Test
    def testThreeCraneSplit(): Unit \ Assert = {
        let cranes = "QC_01" :: "QC_02" :: "QC_03" :: Nil;
        let workloads: List[BayWorkload] = 
            { bay = 1, movesCount = 120 } ::
            { bay = 3, movesCount = 150 } ::
            { bay = 5, movesCount = 130 } ::
            { bay = 7, movesCount = 140 } ::
            { bay = 9, movesCount = 160 } ::
            { bay = 11, movesCount = 110 } :: Nil;
        // Total moves = 810. Target per crane = 270 moves (approx 9 hours at 30 GMPH)

        let plan = balanceCraneBays(cranes, workloads);
        Assert.assertEq(expected = 3, List.length(plan#assignments));
        Assert.assertTrue(plan#makespanHours > 8.0 and plan#makespanHours < 15.0);

        // Verify non-crossing contiguous bay assignment
        match plan#assignments {
            case a1 :: a2 :: a3 :: Nil => {
                Assert.assertEq(expected = "QC_01", a1#craneId);
                Assert.assertEq(expected = "QC_02", a2#craneId);
                Assert.assertEq(expected = "QC_03", a3#craneId);
                Assert.assertTrue(a1#startBay <= a1#endBay);
                Assert.assertTrue(a1#endBay < a2#startBay);
                Assert.assertTrue(a2#endBay < a3#startBay);
                let sumMoves = a1#totalMoves + a2#totalMoves + a3#totalMoves;
                Assert.assertEq(expected = 810, sumMoves)
            }
            case _ => Assert.assertTrue(false)
        }
    }
}
