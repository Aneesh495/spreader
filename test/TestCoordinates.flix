mod TestCoordinates {
    use Model.Coordinates.{
        ShipCell, isUnderdeck, isOndeck, isTwentyFootBay, isFortyFootBay,
        constituentTwentyFootBays, baysOverlap, rowTransverseOffset, rowDistance,
        bayDistance, tierDistance, isValidCellAddress, formatCell
    };

    @Test
    def testBayParity(): Unit \ Assert = {
        Assert.assertEq(expected = true, isTwentyFootBay(1));
        Assert.assertEq(expected = true, isTwentyFootBay(3));
        Assert.assertEq(expected = false, isTwentyFootBay(2));
        Assert.assertEq(expected = true, isFortyFootBay(2));
        Assert.assertEq(expected = true, isFortyFootBay(6));
        Assert.assertEq(expected = false, isFortyFootBay(7))
    }

    @Test
    def testConstituentBays(): Unit \ Assert = {
        let (fwd, aft) = constituentTwentyFootBays(2);
        Assert.assertEq(expected = 1, fwd);
        Assert.assertEq(expected = 3, aft)
    }

    @Test
    def testBayOverlap(): Unit \ Assert = {
        // Bay 02 is 40ft spanning 01 and 03
        Assert.assertEq(expected = true, baysOverlap(2, 1));
        Assert.assertEq(expected = true, baysOverlap(2, 3));
        Assert.assertEq(expected = true, baysOverlap(1, 2));
        Assert.assertEq(expected = true, baysOverlap(2, 2));
        Assert.assertEq(expected = false, baysOverlap(2, 5));
        Assert.assertEq(expected = false, baysOverlap(1, 3))
    }

    @Test
    def testRowTransverseOffset(): Unit \ Assert = {
        Assert.assertEq(expected = 0.0, rowTransverseOffset(0));  // Centerline
        Assert.assertEq(expected = 1.0, rowTransverseOffset(1));  // Starboard 1
        Assert.assertEq(expected = 2.0, rowTransverseOffset(3));  // Starboard 2
        Assert.assertEq(expected = -1.0, rowTransverseOffset(2)); // Port 1
        Assert.assertEq(expected = -2.0, rowTransverseOffset(4))  // Port 2
    }

    @Test
    def testRowDistance(): Unit \ Assert = {
        // Distance between Row 01 (starboard +1) and Row 02 (port -1) is 2.0 units
        Assert.assertEq(expected = 2.0, rowDistance(1, 2));
        // Distance between Row 03 (+2) and Row 01 (+1) is 1.0 unit
        Assert.assertEq(expected = 1.0, rowDistance(3, 1))
    }

    @Test
    def testDeckLevelClassification(): Unit \ Assert = {
        let inHoldCell: ShipCell = { bay = 3, row = 2, tier = 12 };
        let onDeckCell: ShipCell = { bay = 3, row = 2, tier = 84 };
        Assert.assertEq(expected = true, isUnderdeck(inHoldCell));
        Assert.assertEq(expected = false, isOndeck(inHoldCell));
        Assert.assertEq(expected = false, isUnderdeck(onDeckCell));
        Assert.assertEq(expected = true, isOndeck(onDeckCell))
    }

    @Test
    def testCellFormattingAndValidation(): Unit \ Assert = {
        let cell: ShipCell = { bay = 3, row = 2, tier = 84 };
        Assert.assertEq(expected = "030284", formatCell(cell));
        Assert.assertEq(expected = true, isValidCellAddress(cell));

        let invalidCell: ShipCell = { bay = 3, row = 2, tier = 83 }; // Odd tier is invalid
        Assert.assertEq(expected = false, isValidCellAddress(invalidCell))
    }

    @Test
    def testTierDistance(): Unit \ Assert = {
        Assert.assertEq(expected = 2, tierDistance(88, 84));
        Assert.assertEq(expected = 1, tierDistance(4, 2))
    }
}
