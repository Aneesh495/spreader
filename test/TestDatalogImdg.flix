mod TestDatalogImdg {
    use Model.HazmatTypes.{ImdgClass, SegregationCategory};
    use Model.Coordinates.ShipCell;
    use Datalog.Imdg.{
        StowedHazmat, ImdgViolation, table724Requirement, classToCode,
        codeToClass, findSegregationViolations
    };

    @Test
    def testTable724Codes(): Unit \ Assert = {
        // Class 1.1 and Class 3 require Category 4 (longitudinal intervening compartment)
        Assert.assertEq(expected = 4, table724Requirement(11, 30));
        Assert.assertEq(expected = 4, table724Requirement(30, 11));

        // Class 3 and Class 5.1 require Category 2 (Separated From)
        Assert.assertEq(expected = 2, table724Requirement(30, 51));
        Assert.assertEq(expected = 2, table724Requirement(51, 30));

        // Class 3 and Class 8 require Category 1 (Away From)
        Assert.assertEq(expected = 1, table724Requirement(30, 80));

        // Compatible goods require 0
        Assert.assertEq(expected = 0, table724Requirement(90, 90))
    }

    @Test
    def testCompliantStowage(): Unit \ Assert = {
        // Container 1: Class 3 in Hold 1, Bay 03, OnDeck (Tier 84)
        let c1: StowedHazmat = {
            containerIndex = 1,
            containerId = "FLAM001",
            unNumber = 1203, // Gasoline
            primaryClass = ImdgClass.Class3,
            cell = { bay = 3, row = 2, tier = 84 },
            holdNumber = 1
        };
        // Container 2: Class 5.1 in Hold 3, Bay 19, OnDeck (Tier 84) (bay dist = 8, hold diff = 2)
        let c2: StowedHazmat = {
            containerIndex = 2,
            containerId = "OXID002",
            unNumber = 1942, // Ammonium nitrate
            primaryClass = ImdgClass.Class5_1,
            cell = { bay = 19, row = 2, tier = 84 },
            holdNumber = 3
        };
        let violations = findSegregationViolations(c1 :: c2 :: Nil);
        Assert.assertEq(expected = 0, List.length(violations))
    }

    @Test
    def testSameHoldViolation(): Unit \ Assert = {
        // Class 3 and Class 5.1 stowed in the same hold underdeck (Tier 04 and 08)
        let c1: StowedHazmat = {
            containerIndex = 1,
            containerId = "FLAM001",
            unNumber = 1203,
            primaryClass = ImdgClass.Class3,
            cell = { bay = 3, row = 2, tier = 4 },
            holdNumber = 1
        };
        let c2: StowedHazmat = {
            containerIndex = 2,
            containerId = "OXID002",
            unNumber = 1942,
            primaryClass = ImdgClass.Class5_1,
            cell = { bay = 5, row = 4, tier = 8 },
            holdNumber = 1 // Same hold -> Category 2 violation!
        };
        let violations = findSegregationViolations(c1 :: c2 :: Nil);
        Assert.assertEq(expected = 1, List.length(violations));
        match List.head(violations) {
            case Some(v) => {
                Assert.assertEq(expected = 1, v#containerIndexA);
                Assert.assertEq(expected = 2, v#containerIndexB);
                Assert.assertEq(expected = SegregationCategory.SeparatedFrom, v#requiredCategory)
            }
            case None => Assert.assertEq(expected = true, false)
        }
    }

    @Test
    def testExplosivesLongitudinalViolation(): Unit \ Assert = {
        // Class 1.1 in Hold 1 and Class 3 in adjacent Hold 2 (holdDiff = 1 < 2)
        let cExplosive: StowedHazmat = {
            containerIndex = 1,
            containerId = "EXPL001",
            unNumber = 1005,
            primaryClass = ImdgClass.Class1_1,
            cell = { bay = 3, row = 0, tier = 82 },
            holdNumber = 1
        };
        let cFlammable: StowedHazmat = {
            containerIndex = 2,
            containerId = "FLAM002",
            unNumber = 1203,
            primaryClass = ImdgClass.Class3,
            cell = { bay = 9, row = 2, tier = 82 },
            holdNumber = 2 // Adjacent hold -> Category 4 requires holdDiff >= 2!
        };
        let violations = findSegregationViolations(cExplosive :: cFlammable :: Nil);
        Assert.assertEq(expected = 1, List.length(violations));
        match List.head(violations) {
            case Some(v) => Assert.assertEq(expected = SegregationCategory.SeparatedLongitudinallyByIntervening, v#requiredCategory)
            case None    => Assert.assertEq(expected = true, false)
        }
    }
}
