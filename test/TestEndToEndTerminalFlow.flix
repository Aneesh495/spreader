// Spreader: Container Terminal Operating System
// End-to-End Terminal Operating Flow Integration Test Suite

mod TestEndToEndTerminalFlow {

    use Edi.BaplieParser
    use Model.VesselProfile.{postPanamaxVessel}
    use Stability.Types.{LoadingItem, HydrostaticEntry, defaultCriteria}
    use Stability.Trim.solveEquilibrium
    use Stability.LongitudinalStrength.integrateHullGirder
    use Crane.CraneSplit.{BayWorkload, balanceCraneBays}
    use Crane.TwinLift.{validateTwinPair}
    use Simulation.BenchmarkScenarios
    use Visualizer.AnsiBayCrossSection
    use Visualizer.stripAnsi

    @Test
    def testCompleteTerminalLifecycle(): Unit \ Assert = {
        // Step 1: Parse incoming SMDG BAPLIE bayplan
        let baplieEdi =
            "UNB+UNOA:2+MAERSK+PORTROTT+261118:1200+1001'\n" +
            "UNH+1+BAPLIE:D:95B:UN:SMDG22'\n" +
            "BGM+BAY+0124W+9'\n" +
            "TDT+20+0124W+1++MSK:172:20+++VRSP9:103::VRSP9+MV SPREADER'\n" +
            "LOC+5+CNSHA:139:6'\n" +
            "EQD+CN+MSKU1234567+42G1:102:5++4'\n" +
            "LOC+147+0010282:139:125'\n" +
            "MEA+WT++KGM:24500'\n" +
            "LOC+11+NLRTM:139:6'\n" +
            "EQD+CN+MSKU2345678+45R1:102:5++4'\n" +
            "LOC+147+0010482:139:125'\n" +
            "MEA+WT++KGM:26200'\n" +
            "LOC+11+DEHAM:139:6'\n" +
            "TMP+2+N18:CEL'\n" +
            "UNT+14+1'\n" +
            "UNZ+1+1001'";

        let bayplanOpt = BaplieParser.parseBaplie(baplieEdi);
        match bayplanOpt {
            case Some(_) => Assert.assertTrue(true)
            case None => Assert.assertTrue(false)
        };

        // Step 2: Naval hydrostatics and intact stability verification
        let vessel = postPanamaxVessel();
        let cargo: List[LoadingItem] =
            { label = "General Hold Cargo", weightTonnes = 60000.0, lcgMeters = 5.0, tcgMeters = 0.0, kgMeters = 15.0 } :: Nil;
        let table: List[HydrostaticEntry] =
            { draftMeters = 12.0, displacementTonnes = 80000.0, tpcTonnesPerCm = 110.0, mtcTonnesMetersPerCm = 1600.0, lcbMeters = 1.0, kbMeters = 6.0, kmtMeters = 24.0, kmlMeters = 350.0 } ::
            { draftMeters = 15.0, displacementTonnes = 120000.0, tpcTonnesPerCm = 125.0, mtcTonnesMetersPerCm = 1900.0, lcbMeters = 1.0, kbMeters = 7.5, kmtMeters = 22.0, kmlMeters = 320.0 } :: Nil;

        let stabState = solveEquilibrium(vessel, cargo, Nil, table, defaultCriteria());
        Assert.assertTrue(stabState#isCompliant);
        Assert.assertTrue(stabState#gmtFluidMeters >= 0.15);

        // Step 3: Longitudinal strength analysis
        let avgWeight = stabState#displacementTonnes / vessel#lbpMeters;
        let weights = List.map(st -> (st, avgWeight), List.range(0, 21));
        let girderReport = integrateHullGirder(vessel#lbpMeters, stabState#displacementTonnes, weights, 10000000.0);
        Assert.assertTrue(girderReport#isCompliant);

        // Step 4: Multi-crane bay split optimization
        let cranes = "QC_01" :: "QC_02" :: "QC_03" :: Nil;
        let workloads: List[BayWorkload] =
            { bay = 1, movesCount = 100 } ::
            { bay = 3, movesCount = 150 } ::
            { bay = 5, movesCount = 120 } ::
            { bay = 7, movesCount = 130 } :: Nil;
        let cranePlan = balanceCraneBays(cranes, workloads);
        Assert.assertEq(expected = 3, List.length(cranePlan#assignments));
        Assert.assertTrue(cranePlan#makespanHours > 0.0);

        // Step 5: Discrete-event simulation turnaround benchmark
        let scenario = BenchmarkScenarios.neoPanamaxScenario();
        let simMetrics = BenchmarkScenarios.runBenchmark(scenario);
        Assert.assertEq(expected = 1200, simMetrics#totalMoves);
        Assert.assertTrue(simMetrics#quayCraneGrossMph >= 30.0);

        // Step 6: Visual cross-section generation
        let renderRows = 4 :: 2 :: 0 :: 1 :: 3 :: Nil;
        let renderDeckTiers = 84 :: 82 :: Nil;
        let renderHoldTiers = 4 :: 2 :: Nil;
        let renderedBay = AnsiBayCrossSection.renderBay(1, renderRows, renderDeckTiers, renderHoldTiers, Nil);
        let plainBay = stripAnsi(renderedBay);
        Assert.assertTrue(String.contains(substr = "BAY 01", plainBay));
        Assert.assertTrue(String.contains(substr = "[DECK HATCH COVER]", plainBay))
    }
}
