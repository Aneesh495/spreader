mod TestYardCoordinates {
    use Model.YardCoordinates.{
        YardSlot, defaultAscKinematics, slotDistanceMeters, estimateAscMoveDurationSec,
        isValidYardSlot, formatYardSlot
    };
    use Model.MathUtil.{sqrt, hypot3, clamp, sin, cos};

    @Test
    def testMathUtilFunctions(): Unit \ Assert = {
        Assert.assertEq(expected = 5.0, sqrt(25.0));
        Assert.assertEq(expected = 0.0, sqrt(0.0));
        Assert.assertEq(expected = 5.0, hypot3(3.0, 4.0, 0.0));
        Assert.assertEq(expected = 10.0, clamp(5.0, 10.0, 20.0));
        Assert.assertEq(expected = 20.0, clamp(25.0, 10.0, 20.0));
        Assert.assertEq(expected = 15.0, clamp(15.0, 10.0, 20.0));
        // Verify sin(0) and cos(0)
        Assert.assertEq(expected = 0.0, sin(0.0));
        Assert.assertEq(expected = 1.0, cos(0.0))
    }

    @Test
    def testYardSlotFormatting(): Unit \ Assert = {
        let s: YardSlot = { block = "B", bay = 8, row = 4, tier = 2 };
        Assert.assertEq(expected = "B-08-04-2", formatYardSlot(s));
        Assert.assertEq(expected = true, isValidYardSlot(s))
    }

    @Test
    def testYardSlotDistance(): Unit \ Assert = {
        let s1: YardSlot = { block = "A", bay = 1, row = 1, tier = 1 };
        let s2: YardSlot = { block = "A", bay = 1, row = 1, tier = 1 };
        Assert.assertEq(expected = 0.0, slotDistanceMeters(s1, s2));

        let sCrossBlock: YardSlot = { block = "C", bay = 1, row = 1, tier = 1 };
        Assert.assertEq(expected = 99999.0, slotDistanceMeters(s1, sCrossBlock))
    }

    @Test
    def testAscMoveDuration(): Unit \ Assert = {
        let k = defaultAscKinematics();
        let fromSlot: YardSlot = { block = "A", bay = 10, row = 1, tier = 1 };
        let toSlot: YardSlot = { block = "A", bay = 20, row = 5, tier = 3 };
        let duration = estimateAscMoveDurationSec(k, fromSlot, toSlot);
        // Duration should be positive and account for twistlock and travel
        Assert.assertEq(expected = true, duration > 20.0);
        Assert.assertEq(expected = true, duration < 120.0)
    }
}
