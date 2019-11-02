mod TestCraneInterlock {
    use Datalog.CraneInterlock.{
        QuayCranePosition, AscPosition, checkQuayCraneInterlocks, checkAscInterlocks
    };

    @Test
    def testQuayCraneSafeClearance(): Unit \ Assert = {
        let qc1: QuayCranePosition = { craneId = "QC_01", currentBay = 10, boomDown = true };
        let qc2: QuayCranePosition = { craneId = "QC_02", currentBay = 16, boomDown = true };
        let violations = checkQuayCraneInterlocks(qc1 :: qc2 :: Nil, 2);
        Assert.assertEq(expected = 0, List.length(violations))
    }

    @Test
    def testQuayCraneClashViolation(): Unit \ Assert = {
        let qc1: QuayCranePosition = { craneId = "QC_01", currentBay = 10, boomDown = true };
        let qc2: QuayCranePosition = { craneId = "QC_02", currentBay = 11, boomDown = true };
        let violations = checkQuayCraneInterlocks(qc1 :: qc2 :: Nil, 2);
        Assert.assertEq(expected = 1, List.length(violations));
        match List.head(violations) {
            case Some(v) => {
                Assert.assertEq(expected = "QC_01", v#craneIdA);
                Assert.assertEq(expected = "QC_02", v#craneIdB);
                Assert.assertEq(expected = 1, v#actualSeparationBays)
            }
            case None => Assert.assertEq(expected = true, false)
        }
    }

    @Test
    def testQuayCraneBoomUpExemption(): Unit \ Assert = {
        let qc1: QuayCranePosition = { craneId = "QC_01", currentBay = 10, boomDown = true };
        let qc2: QuayCranePosition = { craneId = "QC_02", currentBay = 11, boomDown = false }; // Boom raised!
        let violations = checkQuayCraneInterlocks(qc1 :: qc2 :: Nil, 2);
        Assert.assertEq(expected = 0, List.length(violations))
    }

    @Test
    def testAscBufferViolation(): Unit \ Assert = {
        let a1: AscPosition = { blockId = "A", craneId = "ASC_A1", currentBay = 15 };
        let a2: AscPosition = { blockId = "A", craneId = "ASC_A2", currentBay = 17 }; // Sep = 2 < min buffer 3
        let violations = checkAscInterlocks(a1 :: a2 :: Nil, 3);
        Assert.assertEq(expected = 1, List.length(violations));

        // Different blocks should never conflict
        let aCrossBlock: AscPosition = { blockId = "B", craneId = "ASC_B1", currentBay = 15 };
        let crossViolations = checkAscInterlocks(a1 :: aCrossBlock :: Nil, 3);
        Assert.assertEq(expected = 0, List.length(crossViolations))
    }
}
