// Test suite for STS Quay Crane Twin-Lift Pairing and Eccentricity Analysis

mod TestTwinLift {
    use Model.HazmatTypes.ImdgClass;
    use Crane.TwinLift.{
        TwinCandidate, TwinLiftIncompatibility,
        computeEccentricity, computeEccentricMomentKnm, computeHeadblockTiltDegrees,
        areAdjacentTwinCells, validateTwinPair, pairTwinContainers
    };

    @Test
    def testEccentricity(): Unit \ Assert = {
        // Equal weights: eccentricity = 0.0
        let eccZero = computeEccentricity(20.0, 20.0);
        Assert.assertEq(expected = 0.0, eccZero);

        // W1 = 10.0, W2 = 30.0 -> Total = 40.0, Diff = 20.0
        // ecc = 3.409 * (20.0 / 40.0) = 1.7045m
        let eccUnequal = computeEccentricity(10.0, 30.0);
        Assert.assertTrue(eccUnequal > 1.70 and eccUnequal < 1.71);

        // Moment = 40.0 * 9.80665 * 1.7045 approx 668.6 kNm
        let moment = computeEccentricMomentKnm(10.0, 30.0);
        Assert.assertTrue(moment > 660.0 and moment < 680.0);

        // Tilt with 500 kNm/deg stiffness = 668.6 / 500 = 1.337 deg
        let tilt = computeHeadblockTiltDegrees(moment, 500.0);
        Assert.assertTrue(tilt > 1.3 and tilt < 1.4)
    }

    @Test
    def testAdjacentTwinCells(): Unit \ Assert = {
        let c1 = { bay = 1, row = 2, tier = 82 };
        let c2 = { bay = 3, row = 2, tier = 82 };
        let cNonAdjacent = { bay = 5, row = 2, tier = 82 };
        let cDifferentRow = { bay = 3, row = 4, tier = 82 };

        Assert.assertTrue(areAdjacentTwinCells(c1, c2));
        Assert.assertTrue(not areAdjacentTwinCells(c1, cNonAdjacent));
        Assert.assertTrue(not areAdjacentTwinCells(c1, cDifferentRow))
    }

    @Test
    def testPairingSuccessAndHazmatRejection(): Unit \ Assert = {
        let tc1: TwinCandidate = {
            containerId = "MSCU1111111",
            cell = { bay = 1, row = 2, tier = 82 },
            grossWeightTonnes = 18.0,
            isReefer = false,
            hazmatClass = None
        };
        let tc2: TwinCandidate = {
            containerId = "MSCU2222222",
            cell = { bay = 3, row = 2, tier = 82 },
            grossWeightTonnes = 20.0,
            isReefer = false,
            hazmatClass = None
        };

        // Valid pair
        let viols = validateTwinPair(tc1, tc2, 10.0, 1.2);
        Assert.assertTrue(List.isEmpty(viols));

        // When tc2 carries Class 1.1 explosives -> rejected!
        let tc2Haz: TwinCandidate = { hazmatClass = Some(ImdgClass.Class1_1) | tc2 };
        let violsHaz = validateTwinPair(tc1, tc2Haz, 10.0, 1.2);
        let hasHazViol = List.exists(v -> match v {
            case TwinLiftIncompatibility.HazmatClassIncompatible(_, _) => true
            case _ => false
        }, violsHaz);
        Assert.assertTrue(hasHazViol)
    }

    @Test
    def testAutoPairingList(): Unit \ Assert = {
        let tc1: TwinCandidate = { containerId = "C1", cell = { bay = 1, row = 2, tier = 82 }, grossWeightTonnes = 18.0, isReefer = false, hazmatClass = None };
        let tc2: TwinCandidate = { containerId = "C2", cell = { bay = 3, row = 2, tier = 82 }, grossWeightTonnes = 20.0, isReefer = false, hazmatClass = None };
        let tc3Solo: TwinCandidate = { containerId = "C3", cell = { bay = 7, row = 4, tier = 82 }, grossWeightTonnes = 25.0, isReefer = false, hazmatClass = None };

        let candidates = tc1 :: tc3Solo :: tc2 :: Nil;
        let (pairs, singles) = pairTwinContainers(candidates, 10.0, 1.2);

        Assert.assertEq(expected = 1, List.length(pairs));
        Assert.assertEq(expected = 1, List.length(singles));
        match singles {
            case s :: Nil => Assert.assertEq(expected = "C3", s#containerId)
            case _ => Assert.assertTrue(false)
        }
    }
}
