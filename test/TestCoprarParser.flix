// Test suite for SMDG COPRAR Container Discharge/Loading Order Parser

mod TestCoprarParser {
    use Edi.CoprarParser.{CoprarOrderType, parseCoprar};

    @Test
    def testDischargeManifest(): Unit \ Assert = {
        let coprarEdi = 
            "UNB+UNOA:2+LINE+TERMINAL+261118:1400+0001'" +
            "UNH+1+COPRAR:D:00B:UN:SMDG21'" +
            "BGM+45+DISCH_9988+9'" + // 45 = Discharge order
            "TDT+20+0124W+1++MSK:172:20+++VRSP9:103::VRSP9+MV SPREADER'" +
            "EQD+CN+MSKU9876543+42G1:102:5++4'" + // 4 = Full container
            "LOC+11+NLRTM:139:6'" +
            "MEA+WT++KGM:24500'" +
            "FTX+AAA+++FRAGILE ELECTRONICS'" +
            "EQD+CN+MSKU1122334+22G1:102:5++5'" + // 5 = Empty container
            "LOC+11+NLRTM:139:6'" +
            "MEA+WT++KGM:2300'" +
            "UNT+10+1'";

        match parseCoprar(coprarEdi) {
            case Some(manifest) => {
                Assert.assertEq(expected = CoprarOrderType.DischargeOrder, manifest#orderType);
                Assert.assertEq(expected = "DISCH_9988", manifest#orderNumber);
                Assert.assertEq(expected = "0124W", manifest#voyageNumber);
                Assert.assertEq(expected = 2, List.length(manifest#items));

                match manifest#items {
                    case item1 :: item2 :: Nil => {
                        Assert.assertEq(expected = "MSKU9876543", item1#containerId);
                        Assert.assertEq(expected = true, item1#isFull);
                        Assert.assertEq(expected = 24.5, item1#grossWeightTonnes);
                        Assert.assertEq(expected = Some("FRAGILE ELECTRONICS"), item1#specialInstructions);

                        Assert.assertEq(expected = "MSKU1122334", item2#containerId);
                        Assert.assertEq(expected = false, item2#isFull);
                        Assert.assertEq(expected = 2.3, item2#grossWeightTonnes)
                    }
                    case _ => Assert.assertTrue(false)
                }
            }
            case None => Assert.assertTrue(false)
        }
    }

    @Test
    def testLoadingManifest(): Unit \ Assert = {
        let coprarLoadEdi = 
            "UNH+1+COPRAR:D:00B:UN:SMDG21'" +
            "BGM+44+LOAD_7766+9'" + // 44 = Loading order
            "TDT+20+0124E+1++MSK:172:20+++VRSP9:103::VRSP9+MV SPREADER'" +
            "EQD+CN+TCLU5555555+45G1:102:5++4'" +
            "LOC+11+SGSIN:139:6'" +
            "MEA+WT++KGM:29000'" +
            "UNT+6+1'";

        match parseCoprar(coprarLoadEdi) {
            case Some(manifest) => {
                Assert.assertEq(expected = CoprarOrderType.LoadingOrder, manifest#orderType);
                Assert.assertEq(expected = "LOAD_7766", manifest#orderNumber);
                Assert.assertEq(expected = 1, List.length(manifest#items))
            }
            case None => Assert.assertTrue(false)
        }
    }
}
