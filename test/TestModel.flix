mod TestModel {
    use Model.Types.{
        Container, ContainerLength, ContainerHeight, ContainerType, ContainerStatus,
        grossWeightKg, grossWeightTonnes, isReefer, calculateIsoCheckDigit, isValidIso6346
    };

    @Test
    def testGrossWeight(): Unit \ Assert = {
        let c: Container = {
            id = "MSKU1234567",
            length = ContainerLength.FortyFoot,
            height = ContainerHeight.HighCube,
            typeSpec = ContainerType.GeneralDry,
            tareWeightKg = 3800.0,
            payloadWeightKg = 22500.0,
            status = ContainerStatus.InboundVessel,
            sealNumber = Some("SEAL98765")
        };
        Assert.assertEq(expected = 26300.0, grossWeightKg(c));
        Assert.assertEq(expected = 26.3, grossWeightTonnes(c))
    }

    @Test
    def testReeferDetection(): Unit \ Assert = {
        let dry: Container = {
            id = "MSKU1234567",
            length = ContainerLength.TwentyFoot,
            height = ContainerHeight.StandardHeight,
            typeSpec = ContainerType.GeneralDry,
            tareWeightKg = 2200.0,
            payloadWeightKg = 14000.0,
            status = ContainerStatus.YardStacked,
            sealNumber = None
        };
        let reefer: Container = {
            id = "MAEU9876543",
            length = ContainerLength.FortyFoot,
            height = ContainerHeight.HighCube,
            typeSpec = ContainerType.Refrigerated(-18.5),
            tareWeightKg = 4500.0,
            payloadWeightKg = 18000.0,
            status = ContainerStatus.InboundVessel,
            sealNumber = Some("RF0012")
        };
        Assert.assertEq(expected = false, isReefer(dry));
        Assert.assertEq(expected = true, isReefer(reefer))
    }

    @Test
    def testIsoCheckDigitKnown(): Unit \ Assert = {
        match calculateIsoCheckDigit("CSQU305438") {
            case Some(cd) => Assert.assertEq(expected = 3, cd)
            case None => Assert.assertEq(expected = true, false)
        }
    }

    @Test
    def testIsoValidation(): Unit \ Assert = {
        Assert.assertEq(expected = true, isValidIso6346("CSQU3054383"));
        Assert.assertEq(expected = false, isValidIso6346("CSQU3054389"));
        Assert.assertEq(expected = false, isValidIso6346("INVALID"));
        Assert.assertEq(expected = false, isValidIso6346("CSQU305438312"))
    }
}
