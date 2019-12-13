// Test suite for SMDG BAPLIE 2.2 Bayplan Parser

mod TestBaplieParser {
    use Model.HazmatTypes.ImdgClass;
    use Edi.BaplieParser.{parseBrtCell, parseBaplie};

    @Test
    def testBrtCoordinateParsing(): Unit \ Assert = {
        // 7-char format: "0010282" -> Bay 1, Row 2, Tier 82
        match parseBrtCell("0010282") {
            case Some(c) => {
                Assert.assertEq(expected = 1, c#bay);
                Assert.assertEq(expected = 2, c#row);
                Assert.assertEq(expected = 82, c#tier)
            }
            case None => Assert.assertTrue(false)
        };

        // 6-char format: "030412" -> Bay 3, Row 4, Tier 12
        match parseBrtCell("030412") {
            case Some(c) => {
                Assert.assertEq(expected = 3, c#bay);
                Assert.assertEq(expected = 4, c#row);
                Assert.assertEq(expected = 12, c#tier)
            }
            case None => Assert.assertTrue(false)
        }
    }

    @Test
    def testCompleteBaplieMessage(): Unit \ Assert = {
        let baplieEdi = 
            "UNB+UNOA:2+MAERSK+PORTROTT+261118:1200+1001'" +
            "UNH+1+BAPLIE:D:95B:UN:SMDG22'" +
            "BGM+BAY+MSG999+9'" +
            "TDT+20+0124W+1++MSK:172:20+++VRSP9:103::VRSP9+MV SPREADER'" +
            "LOC+5+NLRTM:139:6'" +
            "EQD+CN+MSKU1234567+42G1:102:5++4'" +
            "LOC+147+0010282:139:125'" +
            "MEA+WT++KGM:28400'" +
            "LOC+11+DEHAM:139:6'" +
            "EQD+CN+MAEU7654321+45R1:102:5++4'" +
            "LOC+147+0010482:139:125'" +
            "MEA+WT++KGM:21500'" +
            "LOC+11+SGSIN:139:6'" +
            "TMP+2+-18.5:CEL'" +
            "EQD+CN+TGHU3333333+22T1:102:5++4'" +
            "LOC+147+0030284:139:125'" +
            "MEA+WT++KGM:24000'" +
            "LOC+11+USNYC:139:6'" +
            "DGS+IMD+3+1993'" +
            "UNT+19+1'";

        match parseBaplie(baplieEdi) {
            case Some(plan) => {
                Assert.assertEq(expected = "0124W", plan#voyageNumber);
                Assert.assertEq(expected = "VRSP9", plan#callSign);
                Assert.assertEq(expected = "MV SPREADER", plan#vesselName);
                Assert.assertEq(expected = 3, List.length(plan#containers));

                // 1st container: General Dry 42G1 at 0010282
                match List.head(plan#containers) {
                    case Some(c1) => {
                        Assert.assertEq(expected = "MSKU1234567", c1#containerId);
                        Assert.assertEq(expected = 28.4, c1#grossWeightTonnes);
                        Assert.assertEq(expected = "DEHAM", c1#portOfDischarge);
                        Assert.assertEq(expected = false, c1#isReefer)
                    }
                    case None => Assert.assertTrue(false)
                };

                // Check reefer container
                let optReefer = List.find(c -> c#containerId == "MAEU7654321", plan#containers);
                match optReefer {
                    case Some(rf) => {
                        Assert.assertTrue(rf#isReefer);
                        Assert.assertEq(expected = Some(-18.5), rf#reeferTempCelsius)
                    }
                    case None => Assert.assertTrue(false)
                };

                // Check hazmat container
                let optHaz = List.find(c -> c#containerId == "TGHU3333333", plan#containers);
                match optHaz {
                    case Some(hz) => {
                        Assert.assertEq(expected = Some(ImdgClass.Class3), hz#hazmatClass);
                        Assert.assertEq(expected = Some(1993), hz#unNumber)
                    }
                    case None => Assert.assertTrue(false)
                }
            }
            case None => Assert.assertTrue(false)
        }
    }
}
