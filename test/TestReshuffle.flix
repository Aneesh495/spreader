// Test suite for Container Relocation Problem (CRP) Reshuffle Minimization

mod TestReshuffle {
    use Yard.YardBlock.YardContainer;
    use Yard.Reshuffle.{
        findBlockingContainers, countBlockingContainers,
        selectDestinationRow, planExtraction
    };

    @Test
    def testBlockingDetection(): Unit \ Assert = {
        // Vertical stack in Bay 5, Row 3 with 3 containers
        let c1: YardContainer = {
            containerId = "MSCU1000001",
            slot = { block = "B01", bay = 5, row = 3, tier = 1 },
            grossWeightTonnes = 20.0,
            pickupOrder = 1, // Target to extract first!
            isReefer = false,
            hazmatClass = None
        };
        let c2: YardContainer = {
            containerId = "MSCU1000002",
            slot = { block = "B01", bay = 5, row = 3, tier = 2 },
            grossWeightTonnes = 18.0,
            pickupOrder = 5,
            isReefer = false,
            hazmatClass = None
        };
        let c3: YardContainer = {
            containerId = "MSCU1000003",
            slot = { block = "B01", bay = 5, row = 3, tier = 3 },
            grossWeightTonnes = 16.0,
            pickupOrder = 8,
            isReefer = false,
            hazmatClass = None
        };

        let bay = c1 :: c2 :: c3 :: Nil;

        // C1 has 2 blocking containers above it (C2 at tier 2, C3 at tier 3)
        Assert.assertEq(expected = 2, countBlockingContainers("MSCU1000001", bay));

        let blocking = findBlockingContainers("MSCU1000001", bay);
        // Topmost first: C3 then C2
        match blocking {
            case top :: second :: Nil =>
                Assert.assertEq(expected = "MSCU1000003", top#containerId);
                Assert.assertEq(expected = "MSCU1000002", second#containerId)
            case _ => Assert.assertTrue(false)
        };

        // C3 is top of stack: 0 blocking containers
        Assert.assertEq(expected = 0, countBlockingContainers("MSCU1000003", bay))
    }

    @Test
    def testExtractionPlanning(): Unit \ Assert = {
        let c1: YardContainer = {
            containerId = "MSCU1000001",
            slot = { block = "B01", bay = 5, row = 3, tier = 1 },
            grossWeightTonnes = 20.0,
            pickupOrder = 1,
            isReefer = false,
            hazmatClass = None
        };
        let c2: YardContainer = {
            containerId = "MSCU1000002",
            slot = { block = "B01", bay = 5, row = 3, tier = 2 },
            grossWeightTonnes = 18.0,
            pickupOrder = 5,
            isReefer = false,
            hazmatClass = None
        };

        let bay = c1 :: c2 :: Nil;
        let plan = planExtraction("MSCU1000001", 6, 5, bay);

        Assert.assertEq(expected = 1, plan#totalReshuffleMoves);
        match plan#relocations {
            case move :: Nil =>
                Assert.assertEq(expected = "MSCU1000002", move#containerId);
                Assert.assertEq(expected = 3, move#fromRow);
                Assert.assertEq(expected = 2, move#fromTier);
                Assert.assertTrue(move#toRow != 3);
                Assert.assertEq(expected = 1, move#toTier) // Landed on ground in another row
            case _ => Assert.assertTrue(false)
        }
    }
}
