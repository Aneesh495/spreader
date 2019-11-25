// Test suite for Twin ASC Dispatch and Rail Anti-Collision Interlocks

mod TestAscScheduler {
    use Yard.AscScheduler.{
        AscState, AscConflict, AscDispatchAction,
        checkStaticClearance, checkTrajectoryCrossing, dispatchTwinAscs
    };

    @Test
    def testStaticClearance(): Unit \ Assert = {
        let asc1: AscState = { craneId = "ASC_W1", currentBay = 10, targetBay = 10, isCarrying = false, carriedContainerId = None };
        let asc2Near: AscState = { craneId = "ASC_L1", currentBay = 11, targetBay = 11, isCarrying = false, carriedContainerId = None };
        let asc2Safe: AscState = { craneId = "ASC_L1", currentBay = 16, targetBay = 16, isCarrying = false, carriedContainerId = None };

        // Buffer is 3 bays
        match checkStaticClearance(asc1, asc2Near, 3) {
            case Some(AscConflict.StaticBufferViolation(c1, c2, b1, b2)) =>
                Assert.assertEq(expected = "ASC_W1", c1);
                Assert.assertEq(expected = "ASC_L1", c2);
                Assert.assertEq(expected = 10, b1);
                Assert.assertEq(expected = 11, b2)
            case _ => Assert.assertTrue(false)
        };

        match checkStaticClearance(asc1, asc2Safe, 3) {
            case None => Assert.assertTrue(true)
            case _ => Assert.assertTrue(false)
        }
    }

    @Test
    def testTrajectoryCrossing(): Unit \ Assert = {
        // ascW at bay 10 heading to bay 24; ascL at bay 22 heading to bay 8 -> CROSSING!
        let ascW: AscState = { craneId = "ASC_W1", currentBay = 10, targetBay = 24, isCarrying = true, carriedContainerId = Some("MSCU1") };
        let ascL: AscState = { craneId = "ASC_L1", currentBay = 22, targetBay = 8, isCarrying = false, carriedContainerId = None };

        match checkTrajectoryCrossing(ascW, ascL) {
            case Some(AscConflict.TrajectoryCrossingConflict(_, _, _, _)) =>
                Assert.assertTrue(true)
            case _ => Assert.assertTrue(false)
        }
    }

    @Test
    def testPriorityDispatchYielding(): Unit \ Assert = {
        // Both want to move towards bay 18 (contention within 2-bay buffer)
        // Waterside is carrying, landside is empty
        let ascW: AscState = { craneId = "ASC_W1", currentBay = 12, targetBay = 18, isCarrying = true, carriedContainerId = Some("MSCU1") };
        let ascL: AscState = { craneId = "ASC_L1", currentBay = 25, targetBay = 19, isCarrying = false, carriedContainerId = None };

        let (actionW, actionL) = dispatchTwinAscs(ascW, ascL, 3);
        // Waterside should proceed to 18; Landside should hold at safe position (18 + 3 = 21)
        match (actionW, actionL) {
            case (AscDispatchAction.ProceedToTarget(cw, tw), AscDispatchAction.HoldPosition(cl, hl, _)) =>
                Assert.assertEq(expected = "ASC_W1", cw);
                Assert.assertEq(expected = 18, tw);
                Assert.assertEq(expected = "ASC_L1", cl);
                Assert.assertEq(expected = 21, hl)
            case _ => Assert.assertTrue(false)
        }
    }
}
