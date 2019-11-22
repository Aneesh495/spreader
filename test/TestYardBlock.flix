// Test suite for Yard Block Topology and Stacking Geometry

mod TestYardBlock {
    use Model.YardCoordinates.YardSlot;
    use Yard.YardBlock.{
        standardAscBlock, isSlotWithinBounds, isOccupied,
        stackTopTier, stackTotalWeight, utilizationPercent,
        YardContainer, BlockState
    };

    @Test
    def testSlotBounds(): Unit \ Assert = {
        let block = standardAscBlock("B01");
        let validSlot: YardSlot = { block = "B01", bay = 10, row = 4, tier = 3 };
        let invalidBay: YardSlot = { block = "B01", bay = 45, row = 4, tier = 3 };
        let invalidBlock: YardSlot = { block = "B02", bay = 10, row = 4, tier = 3 };
        let invalidTier: YardSlot = { block = "B01", bay = 10, row = 4, tier = 7 };

        Assert.assertTrue(isSlotWithinBounds(validSlot, block));
        Assert.assertTrue(not isSlotWithinBounds(invalidBay, block));
        Assert.assertTrue(not isSlotWithinBounds(invalidBlock, block));
        Assert.assertTrue(not isSlotWithinBounds(invalidTier, block))
    }

    @Test
    def testOccupancyAndTopTier(): Unit \ Assert = {
        let block = standardAscBlock("B01");
        let c1: YardContainer = {
            containerId = "MSCU1111111",
            slot = { block = "B01", bay = 5, row = 2, tier = 1 },
            grossWeightTonnes = 24.0,
            pickupOrder = 1,
            isReefer = false,
            hazmatClass = None
        };
        let c2: YardContainer = {
            containerId = "MSCU2222222",
            slot = { block = "B01", bay = 5, row = 2, tier = 2 },
            grossWeightTonnes = 18.0,
            pickupOrder = 2,
            isReefer = false,
            hazmatClass = None
        };

        let containers = c1 :: c2 :: Nil;
        let slotOccupied: YardSlot = { block = "B01", bay = 5, row = 2, tier = 1 };
        let slotEmpty: YardSlot = { block = "B01", bay = 5, row = 2, tier = 3 };

        Assert.assertTrue(isOccupied(slotOccupied, containers));
        Assert.assertTrue(not isOccupied(slotEmpty, containers));

        Assert.assertEq(expected = 2, stackTopTier("B01", 5, 2, containers));
        Assert.assertEq(expected = 0, stackTopTier("B01", 5, 3, containers));

        let wt = stackTotalWeight("B01", 5, 2, containers);
        Assert.assertEq(expected = 42.0, wt);

        let state: BlockState = { profile = block, containers = containers };
        // Total slots = 40 * 8 * 5 = 1600 slots. 2 occupied -> (2 / 1600) * 100 = 0.125%
        let util = utilizationPercent(state);
        Assert.assertTrue(util > 0.12 and util < 0.13)
    }
}
