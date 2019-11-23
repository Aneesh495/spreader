// Test suite for Yard Placement Rules, Wind Derating, and Reefer Management

mod TestYardRules {
    use Model.YardCoordinates.YardSlot;
    use Yard.YardBlock.{standardAscBlock, YardContainer, BlockState};
    use Yard.Rules.{maxPermissibleTierForWind, validatePlacement, YardViolation};

    @Test
    def testWindDerating(): Unit \ Assert = {
        let baseTier = 5;
        Assert.assertEq(expected = 5, maxPermissibleTierForWind(baseTier, 10.0)); // Light breeze
        Assert.assertEq(expected = 4, maxPermissibleTierForWind(baseTier, 16.0)); // Strong breeze
        Assert.assertEq(expected = 3, maxPermissibleTierForWind(baseTier, 22.0)); // Gale
        Assert.assertEq(expected = 2, maxPermissibleTierForWind(baseTier, 30.0))  // Typhoon
    }

    @Test
    def testValidGroundPlacement(): Unit \ Assert = {
        let block = standardAscBlock("B01");
        let state: BlockState = { profile = block, containers = Nil };
        let candidate: YardContainer = {
            containerId = "MSCU1234567",
            slot = { block = "B01", bay = 1, row = 1, tier = 1 },
            grossWeightTonnes = 25.0,
            pickupOrder = 10,
            isReefer = true,
            hazmatClass = None
        };

        // Bay 1 is a reefer bay in standardAscBlock
        let viols = validatePlacement(candidate, state, 10.0);
        Assert.assertTrue(List.isEmpty(viols))
    }

    @Test
    def testFloatingAndReeferViolations(): Unit \ Assert = {
        let block = standardAscBlock("B01");
        let state: BlockState = { profile = block, containers = Nil };

        // 1. Floating: Tier 3 on empty ground
        let floatingCandidate: YardContainer = {
            containerId = "MSCU9999999",
            slot = { block = "B01", bay = 1, row = 1, tier = 3 },
            grossWeightTonnes = 20.0,
            pickupOrder = 10,
            isReefer = false,
            hazmatClass = None
        };
        let violsFloating = validatePlacement(floatingCandidate, state, 10.0);
        let hasFloating = List.exists(v -> match v {
            case YardViolation.FloatingPlacement(_, _, _, _) => true
            case _ => false
        }, violsFloating);
        Assert.assertTrue(hasFloating);

        // 2. Reefer in non-reefer bay (Bay 10 is not in 1, 3, 5)
        let reeferInNonReeferBay: YardContainer = {
            containerId = "MSCU8888888",
            slot = { block = "B01", bay = 10, row = 1, tier = 1 },
            grossWeightTonnes = 20.0,
            pickupOrder = 10,
            isReefer = true,
            hazmatClass = None
        };
        let violsReefer = validatePlacement(reeferInNonReeferBay, state, 10.0);
        let hasReeferViol = List.exists(v -> match v {
            case YardViolation.ReeferPlugUnavailable(_, _, _, _) => true
            case _ => false
        }, violsReefer);
        Assert.assertTrue(hasReeferViol)
    }
}
