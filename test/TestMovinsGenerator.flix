// Test suite for SMDG MOVINS Message Generator

mod TestMovinsGenerator {
    use Edi.Tokenizer.parseEdifact;
    use Edi.SegmentNav.{findFirst, findAll, getComponent};
    use Edi.MovinsGenerator.{MovinsInstruction, generateMovins};

    @Test
    def testMovinsGeneration(): Unit \ Assert = {
        let inst1: MovinsInstruction = {
            sequenceIndex = 1,
            craneId = "QC_01",
            containerId = "MSKU1000001",
            isoType = "42G1",
            targetCell = { bay = 1, row = 2, tier = 82 },
            grossWeightTonnes = 26.0,
            isDischarge = true
        };
        let inst2: MovinsInstruction = {
            sequenceIndex = 2,
            craneId = "QC_01",
            containerId = "MSKU2000002",
            isoType = "22G1",
            targetCell = { bay = 1, row = 4, tier = 82 },
            grossWeightTonnes = 14.5,
            isDischarge = false
        };

        let ediText = generateMovins(inst1 :: inst2 :: Nil, "MV SPREADER", "VRSP9", "0124W", "MOV001");
        Assert.assertTrue(String.length(ediText) > 100);

        // Parse generated message with EDI tokenizer
        let segs = parseEdifact(ediText);
        match findFirst("UNH", segs) {
            case Some(unh) => {
                Assert.assertEq(expected = Some("MOVINS"), getComponent(2, 1, unh));
                Assert.assertEq(expected = Some("SMDG20"), getComponent(2, 5, unh))
            }
            case None => Assert.assertTrue(false)
        };

        let eqdSegs = findAll("EQD", segs);
        Assert.assertEq(expected = 2, List.length(eqdSegs));

        match eqdSegs {
            case e1 :: e2 :: Nil => {
                Assert.assertEq(expected = Some("MSKU1000001"), getComponent(2, 1, e1));
                Assert.assertEq(expected = Some("42G1"), getComponent(3, 1, e1));
                Assert.assertEq(expected = Some("6"), getComponent(5, 1, e1)); // Discharge

                Assert.assertEq(expected = Some("MSKU2000002"), getComponent(2, 1, e2));
                Assert.assertEq(expected = Some("22G1"), getComponent(3, 1, e2));
                Assert.assertEq(expected = Some("4"), getComponent(5, 1, e2))  // Load
            }
            case _ => Assert.assertTrue(false)
        }
    }
}
