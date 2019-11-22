// Test suite for Automated Ballast Water Optimization

mod TestBallast {
    use Model.VesselProfile.{BallastTank, TankState, postPanamaxVessel};
    use Stability.Types.StabilityState;
    use Stability.BallastOptimizer.{
        solveAntiHeeling, solveTrimAdjustment, generateBallastPlan
    };

    @Test
    def testAntiHeelingTransfer(): Unit \ Assert = {
        let portTank: TankState = {
            tankId = BallastTank.WingTankPort(1),
            capacityTonnes = 600.0,
            currentWeightTonnes = 200.0,
            lcgMeters = 0.0,
            tcgMeters = -18.0,
            vcgMeters = 8.0,
            freeSurfaceMoment = 50.0
        };
        let stbdTank: TankState = {
            tankId = BallastTank.WingTankStarboard(1),
            capacityTonnes = 600.0,
            currentWeightTonnes = 200.0,
            lcgMeters = 0.0,
            tcgMeters = 18.0,
            vcgMeters = 8.0,
            freeSurfaceMoment = 50.0
        };

        // Ship has TCG = +0.02m (listing starboard), displacement 90000 tonnes
        // Span = 36m. Required moment = -(90000 * 0.02) = -1800 tonne-m
        // Target transfer = -1800 / 36 = -50 tonnes (add 50 tonnes to port, discharge 50 from stbd)
        let (portDelta, stbdDelta) = solveAntiHeeling(portTank, stbdTank, 0.02, 90000.0);
        // Note: our solver convention sets positive for shifting moment
        Assert.assertTrue(Float64.abs(portDelta) > 0.0);
        Assert.assertTrue(Float64.abs(portDelta + stbdDelta) < 0.001)
    }

    @Test
    def testTrimAdjustment(): Unit \ Assert = {
        let fpt: TankState = {
            tankId = BallastTank.Forepeak,
            capacityTonnes = 1200.0,
            currentWeightTonnes = 300.0,
            lcgMeters = 140.0,
            tcgMeters = 0.0,
            vcgMeters = 4.0,
            freeSurfaceMoment = 100.0
        };
        let apt: TankState = {
            tankId = BallastTank.Aftpeak,
            capacityTonnes = 1500.0,
            currentWeightTonnes = 800.0,
            lcgMeters = -135.0,
            tcgMeters = 0.0,
            vcgMeters = 6.0,
            freeSurfaceMoment = 150.0
        };

        // Current trim = 2.20m by stern, target trim = 1.00m by stern
        // MTC = 1800 tonne-m / cm
        let (fptDelta, aptDelta) = solveTrimAdjustment(fpt, apt, 2.20, 1.00, 1800.0);
        // Should add weight to FPT to decrease stern trim
        Assert.assertTrue(fptDelta > 0.0);
        Assert.assertTrue(aptDelta < 0.0)
    }

    @Test
    def testBallastPlanGeneration(): Unit \ Assert = {
        let vessel = postPanamaxVessel();
        let state: StabilityState = {
            displacementTonnes = 92500.0,
            totalDeadweightTonnes = 60000.0,
            kgSolidMeters = 14.5,
            fseMeters = 0.2,
            kgFluidMeters = 14.7,
            lcgMeters = 2.0,
            tcgMeters = 0.03,
            kmtMeters = 23.0,
            gmtFluidMeters = 8.3,
            draftMidMeters = 13.5,
            draftFwdMeters = 12.8,
            draftAftMeters = 14.2,
            trimMeters = 1.4,
            heelAngleDegrees = 0.2,
            isCompliant = true
        };

        let plan = generateBallastPlan(vessel#ballastTanks, state, 0.8, 1800.0);
        Assert.assertTrue(List.length(plan#actions) > 0)
    }
}
