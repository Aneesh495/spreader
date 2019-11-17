// Test suite for Longitudinal Strength and Hull Girder Integration

mod TestLongitudinalStrength {
    use Stability.LongitudinalStrength.{
        stationPosition, approximateBuoyancyAtStation, integrateHullGirder
    };

    @Test
    def testStationPositions(): Unit \ Assert = {
        let lbp = 320.0;
        Assert.assertEq(expected = 0.0, stationPosition(0, lbp));
        Assert.assertEq(expected = 160.0, stationPosition(10, lbp));
        Assert.assertEq(expected = 320.0, stationPosition(20, lbp))
    }

    @Test
    def testBuoyancyCurve(): Unit \ Assert = {
        let lbp = 320.0;
        let disp = 100000.0;
        let b0 = approximateBuoyancyAtStation(0, disp, lbp);
        let b10 = approximateBuoyancyAtStation(10, disp, lbp);
        let b20 = approximateBuoyancyAtStation(20, disp, lbp);

        // Ends should have zero/tapered buoyancy
        Assert.assertTrue(b0 < 0.001);
        Assert.assertTrue(b20 < 0.001);
        // Midships should carry maximum buoyancy
        Assert.assertTrue(b10 > 400.0)
    }

    @Test
    def testGirderIntegration(): Unit \ Assert = {
        let lbp = 320.0;
        let disp = 90000.0;
        // Evenly distributed weight profile
        let avgWeight = disp / lbp;
        let weights = List.map(st -> (st, avgWeight), List.range(0, 21));

        let report = integrateHullGirder(lbp, disp, weights, 10000000.0);
        Assert.assertEq(expected = 21, List.length(report#stations));
        Assert.assertTrue(report#maxShearForceKn > 0.0);
        Assert.assertTrue(report#maxBendingMomentKnm > 0.0);
        Assert.assertTrue(report#isCompliant)
    }
}
