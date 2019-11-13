// Test suite for Marine Hydrostatics and Statical Stability

mod TestHydrostatics {
    use Stability.Types.LoadingItem;
    use Stability.Types.FreeSurfaceItem;
    use Stability.Types.HydrostaticEntry;
    use Stability.Hydrostatics.{
        totalDisplacement, computeCenterOfGravity, totalFreeSurfaceMoment,
        computeFse, computeGmt, computeHeelAngleDegrees, interpolateHydrostatics
    };

    @Test
    def testDisplacementAndCog(): Unit \ Assert = {
        let lightship = 45000.0;
        let items: List[LoadingItem] = 
            { label = "Bay 01-07 Forward Hold Cargo", weightTonnes = 20000.0, lcgMeters = 80.0, tcgMeters = 0.0, kgMeters = 15.0 } ::
            { label = "Bay 30-40 Aft Hold Cargo", weightTonnes = 25000.0, lcgMeters = -70.0, tcgMeters = 0.0, kgMeters = 16.0 } ::
            { label = "Starboard Heavy Machinery", weightTonnes = 5000.0, lcgMeters = 10.0, tcgMeters = 12.0, kgMeters = 18.0 } :: Nil;
        
        let disp = totalDisplacement(lightship, items);
        Assert.assertEq(expected = 95000.0, disp);

        // Lightship: LCG = 0.0, TCG = 0.0, KG = 12.0
        let (_lcg, tcg, kg) = computeCenterOfGravity(lightship, 0.0, 0.0, 12.0, items);
        // TCG = (5000 * 12.0) / 95000 = 60000 / 95000 approx 0.63158m
        Assert.assertTrue(tcg > 0.63 and tcg < 0.64);
        // KG should be between 12.0 and 18.0
        Assert.assertTrue(kg > 13.0 and kg < 15.0)
    }

    @Test
    def testFreeSurfaceEffect(): Unit \ Assert = {
        let tanks: List[FreeSurfaceItem] =
            { tankId = "FPT", liquidDensityTonnesPerM3 = 1.025, secondMomentOfAreaM4 = 1200.0, isSlack = true } ::
            { tankId = "DBT1P", liquidDensityTonnesPerM3 = 1.025, secondMomentOfAreaM4 = 850.0, isSlack = true } ::
            { tankId = "DBT1S", liquidDensityTonnesPerM3 = 1.025, secondMomentOfAreaM4 = 850.0, isSlack = false } :: Nil; // Pressed full, no slack
        
        let fsm = totalFreeSurfaceMoment(tanks);
        // Slack tanks: 1.025 * 1200 + 1.025 * 850 = 1230 + 871.25 = 2101.25 tonne-m
        Assert.assertTrue(fsm > 2100.0 and fsm < 2102.0);

        let disp = 70000.0;
        let fse = computeFse(fsm, disp);
        // FSE = 2101.25 / 70000.0 approx 0.0300m
        Assert.assertTrue(fse > 0.029 and fse < 0.031)
    }

    @Test
    def testTransverseGmtAndHeel(): Unit \ Assert = {
        let kmt = 21.50;
        let kgSolid = 18.20;
        let fse = 0.35;
        let gmt = computeGmt(kmt, kgSolid, fse);
        // GMT = 21.50 - 18.20 - 0.35 = 2.95m
        Assert.assertTrue(Float64.abs(gmt - 2.95) < 0.001);

        // When TCG is 0.05m to starboard
        let heel = computeHeelAngleDegrees(0.05, gmt);
        // tan(phi) = 0.05 / 2.95 = 0.016949 rad -> approx 0.971 degrees
        Assert.assertTrue(heel > 0.9 and heel < 1.05)
    }

    @Test
    def testInterpolation(): Unit \ Assert = {
        let table: List[HydrostaticEntry] = 
            { draftMeters = 12.0, displacementTonnes = 80000.0, tpcTonnesPerCm = 110.0, mtcTonnesMetersPerCm = 1600.0, lcbMeters = 2.5, kbMeters = 6.2, kmtMeters = 22.0, kmlMeters = 320.0 } ::
            { draftMeters = 14.0, displacementTonnes = 100000.0, tpcTonnesPerCm = 120.0, mtcTonnesMetersPerCm = 1800.0, lcbMeters = 1.5, kbMeters = 7.3, kmtMeters = 21.0, kmlMeters = 300.0 } :: Nil;
        
        let interp = interpolateHydrostatics(90000.0, table);
        // Midpoint 90000 is halfway between 80000 and 100000
        Assert.assertTrue(Float64.abs(interp#draftMeters - 13.0) < 0.01);
        Assert.assertTrue(Float64.abs(interp#kmtMeters - 21.5) < 0.01);
        Assert.assertTrue(Float64.abs(interp#tpcTonnesPerCm - 115.0) < 0.01)
    }
}
