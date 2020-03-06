// Spreader: Container Terminal Operating System
// Test Suite for ASCII Yard Block Map Renderer

mod TestYardAsciiMap {

    use Visualizer.stripAnsi
    use Visualizer.YardAsciiMap
    use Visualizer.YardAsciiMap.{AscMapPosition, YardBlockMapData}

    @Test
    def testHeightBadgeFormatting(): Unit \ Assert = {
        let emptyBadge = stripAnsi(YardAsciiMap.formatHeightBadge(0, 5));
        let partialBadge = stripAnsi(YardAsciiMap.formatHeightBadge(3, 5));
        let fullBadge = stripAnsi(YardAsciiMap.formatHeightBadge(5, 5));

        Assert.assertEq(expected = "[ . ]", emptyBadge);
        Assert.assertEq(expected = "[3]", partialBadge);
        Assert.assertEq(expected = "[5]", fullBadge)
    }

    @Test
    def testRenderYardBlockLayout(): Unit \ Assert = {
        let heights = (1, 3) :: (3, 5) :: (5, 0) :: (7, 4) :: (9, 2) :: Nil;
        let cranes = { craneId = "ASC-1W", bayPosition = 3, isHoisting = false } ::
                     { craneId = "ASC-1L", bayPosition = 7, isHoisting = true } :: Nil;
        let blockData = {
            blockId = "B01",
            totalBays = 5,
            maxTier = 5,
            bayHeights = heights,
            cranes = cranes,
            watersideVehicles = "AGV-04" :: "AGV-12" :: Nil,
            landsideVehicles = "TRK-901" :: Nil
        };

        let rendered = YardAsciiMap.renderYardBlock(blockData);
        let plain = stripAnsi(rendered);

        Assert.assertTrue(String.contains(substr = "YARD BLOCK B01", plain));
        Assert.assertTrue(String.contains(substr = "WATERSIDE AGV ZONE", plain));
        Assert.assertTrue(String.contains(substr = "AGV-04, AGV-12", plain));
        Assert.assertTrue(String.contains(substr = "ASC-W", plain));
        Assert.assertTrue(String.contains(substr = "ASC-L", plain));
        Assert.assertTrue(String.contains(substr = "LANDSIDE TRUCK ZONE", plain));
        Assert.assertTrue(String.contains(substr = "TRK-901", plain))
    }
}
