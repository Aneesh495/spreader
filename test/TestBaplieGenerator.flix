// Test suite for SMDG BAPLIE Generator and Round-Trip Verification

mod TestBaplieGenerator {
    use Model.HazmatTypes.ImdgClass;
    use Edi.BaplieParser.{BaplieBayplan, BaplieContainer, parseBaplie};
    use Edi.BaplieGenerator.{formatBrt, generateBaplie};

    @Test
    def testBrtFormatting(): Unit \ Assert = {
        Assert.assertEq(expected = "0010282", formatBrt({ bay = 1, row = 2, tier = 82 }));
        Assert.assertEq(expected = "0450814", formatBrt({ bay = 45, row = 8, tier = 14 }));
        Assert.assertEq(expected = "1051286", formatBrt({ bay = 105, row = 12, tier = 86 }))
    }

    @Test
    def testRoundTripBaplie(): Unit \ Assert = {
        let c1: BaplieContainer = {
            containerId = "MSCU1111111",
            isoType = "42G1",
            cell = { bay = 1, row = 2, tier = 82 },
            grossWeightTonnes = 26.5,
            portOfLoading = "NLRTM",
            portOfDischarge = "SGSIN",
            isReefer = false,
            reeferTempCelsius = None,
            hazmatClass = None,
            unNumber = None
        };
        let c2Reefer: BaplieContainer = {
            containerId = "MAEU2222222",
            isoType = "45R1",
            cell = { bay = 1, row = 4, tier = 82 },
            grossWeightTonnes = 22.0,
            portOfLoading = "NLRTM",
            portOfDischarge = "HKHKG",
            isReefer = true,
            reeferTempCelsius = Some(-20.0),
            hazmatClass = None,
            unNumber = None
        };

        let originalPlan: BaplieBayplan = {
            vesselName = "MV SPREADER",
            callSign = "VRSP9",
            voyageNumber = "0420W",
            senderId = "TERMINAL_ONE",
            containers = c1 :: c2Reefer :: Nil
        };

        // Generate EDI text
        let ediText = generateBaplie(originalPlan, "REF9999");
        Assert.assertTrue(String.length(ediText) > 100);

        // Parse back generated EDI
        match parseBaplie(ediText) {
            case Some(parsedPlan) => {
                Assert.assertEq(expected = "MV SPREADER", parsedPlan#vesselName);
                Assert.assertEq(expected = "VRSP9", parsedPlan#callSign);
                Assert.assertEq(expected = "0420W", parsedPlan#voyageNumber);
                Assert.assertEq(expected = 2, List.length(parsedPlan#containers));

                let optC1 = List.find(c -> c#containerId == "MSCU1111111", parsedPlan#containers);
                match optC1 {
                    case Some(c) => {
                        Assert.assertEq(expected = 26.5, c#grossWeightTonnes);
                        Assert.assertEq(expected = 1, c#cell#bay);
                        Assert.assertEq(expected = 2, c#cell#row);
                        Assert.assertEq(expected = 82, c#cell#tier);
                        Assert.assertEq(expected = "SGSIN", c#portOfDischarge)
                    }
                    case None => Assert.assertTrue(false)
                };

                let optC2 = List.find(c -> c#containerId == "MAEU2222222", parsedPlan#containers);
                match optC2 {
                    case Some(c) => {
                        Assert.assertTrue(c#isReefer);
                        Assert.assertEq(expected = Some(-20.0), c#reeferTempCelsius)
                    }
                    case None => Assert.assertTrue(false)
                }
            }
            case None => Assert.assertTrue(false)
        }
    }
}
