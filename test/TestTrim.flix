// Test suite for Trim, Draft, and Equilibrium Solver

mod TestTrim {
    use Model.VesselProfile.{VesselParticulars, postPanamaxVessel};
    use Stability.Types.{LoadingItem, FreeSurfaceItem, HydrostaticEntry, defaultCriteria};
    use Stability.Trim.{trimmingMoment, computeTrimMeters, computeDrafts, solveEquilibrium};

    @Test
    def testTrimmingMomentAndTrim(): Unit \ Assert = {
        let disp = 100000.0;
        let lcg = 3.5;
        let lcb = 1.5;
        let mtc = 1800.0;

        let tm = trimmingMoment(disp, lcg, lcb);
        // TM = 100000 * (3.5 - 1.5) = 200000 tonne-m
        Assert.assertEq(expected = 200000.0, tm);

        let trim = computeTrimMeters(disp, lcg, lcb, mtc);
        // trimCm = 200000 / 1800 = 111.11 cm -> 1.111 meters
        Assert.assertTrue(trim > 1.10 and trim < 1.12);

        let (df, da) = computeDrafts(14.0, trim);
        // df = 14.0 - 0.5555 = 13.444m
        // da = 14.0 + 0.5555 = 14.555m
        Assert.assertTrue(df > 13.4 and df < 13.5);
        Assert.assertTrue(da > 14.5 and da < 14.6)
    }

    @Test
    def testSolveEquilibriumCompliant(): Unit \ Assert = {
        let vessel = postPanamaxVessel();
        let cargo: List[LoadingItem] = 
            { label = "General Hold Cargo", weightTonnes = 60000.0, lcgMeters = 5.0, tcgMeters = 0.0, kgMeters = 15.0 } :: Nil;
        let tanks: List[FreeSurfaceItem] = Nil;
        let table: List[HydrostaticEntry] = 
            { draftMeters = 12.0, displacementTonnes = 80000.0, tpcTonnesPerCm = 110.0, mtcTonnesMetersPerCm = 1600.0, lcbMeters = 1.0, kbMeters = 6.0, kmtMeters = 24.0, kmlMeters = 350.0 } ::
            { draftMeters = 15.0, displacementTonnes = 120000.0, tpcTonnesPerCm = 125.0, mtcTonnesMetersPerCm = 1900.0, lcbMeters = 1.0, kbMeters = 7.5, kmtMeters = 22.0, kmlMeters = 320.0 } :: Nil;
        
        let state = solveEquilibrium(vessel, cargo, tanks, table, defaultCriteria());
        // Displacement = 32500 (lightship) + 60000 = 92500.0
        Assert.assertEq(expected = 92500.0, state#displacementTonnes);
        Assert.assertTrue(state#gmtFluidMeters > 2.0);
        Assert.assertTrue(state#heelAngleDegrees == 0.0);
        Assert.assertTrue(state#isCompliant)
    }
}
