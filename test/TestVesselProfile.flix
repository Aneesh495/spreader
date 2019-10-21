mod TestVesselProfile {
    use Model.VesselProfile.{
        VesselParticulars, postPanamaxVessel, findHoldForBay, isBulkheadSeparated,
        totalBallastWeightTonnes
    };

    @Test
    def testVesselParticulars(): Unit \ Assert = {
        let v = postPanamaxVessel();
        Assert.assertEq(expected = 335.0, v#loaMeters);
        Assert.assertEq(expected = 8500, v#teuCapacity);
        Assert.assertEq(expected = 32500.0, v#lightshipTonnes)
    }

    @Test
    def testHoldLookup(): Unit \ Assert = {
        let v = postPanamaxVessel();
        match findHoldForBay(v, 3) {
            case Some(h) => Assert.assertEq(expected = 1, h#holdNumber)
            case None    => Assert.assertEq(expected = true, false)
        };
        match findHoldForBay(v, 25) {
            case Some(h) => Assert.assertEq(expected = 4, h#holdNumber)
            case None    => Assert.assertEq(expected = true, false)
        }
    }

    @Test
    def testBulkheadSeparation(): Unit \ Assert = {
        let v = postPanamaxVessel();
        // Bay 3 is Hold 1, Bay 10 is Hold 2 -> Bulkhead separated
        Assert.assertEq(expected = true, isBulkheadSeparated(v, 3, 10));
        // Bay 1 and Bay 5 are both Hold 1 -> NOT bulkhead separated
        Assert.assertEq(expected = false, isBulkheadSeparated(v, 1, 5))
    }

    @Test
    def testBallastWeight(): Unit \ Assert = {
        let v = postPanamaxVessel();
        let total = totalBallastWeightTonnes(v);
        // 400 + 600 + 200 + 200 + 100 + 100 = 1600.0
        Assert.assertEq(expected = 1600.0, total)
    }
}
