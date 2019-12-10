// Test suite for EDIFACT Segment Navigation and Loop Grouping

mod TestSegmentNav {
    use Edi.Tokenizer.parseEdifact;
    use Edi.SegmentNav.{findFirst, findAll, getElement, getComponent, groupByTrigger};

    @Test
    def testNavigationAndExtraction(): Unit \ Assert = {
        let text = "UNH+1+BAPLIE:D:95B:UN:SMDG22'BGM+BAY+MSG001+9'EQD+CN+MSKU1234567:22G1'LOC+147+0010282:139:125'MEA+WT++KGM:24500'";
        let segs = parseEdifact(text);

        match findFirst("BGM", segs) {
            case Some(bgm) => {
                Assert.assertEq(expected = Some("BAY" :: Nil), getElement(1, bgm));
                Assert.assertEq(expected = Some("MSG001"), getComponent(2, 1, bgm));
                Assert.assertEq(expected = Some("9"), getComponent(3, 1, bgm))
            }
            case None => Assert.assertTrue(false)
        };

        match findFirst("EQD", segs) {
            case Some(eqd) => {
                Assert.assertEq(expected = Some("CN"), getComponent(1, 1, eqd));
                Assert.assertEq(expected = Some("MSKU1234567"), getComponent(2, 1, eqd));
                Assert.assertEq(expected = Some("22G1"), getComponent(2, 2, eqd))
            }
            case None => Assert.assertTrue(false)
        }
    }

    @Test
    def testLoopGrouping(): Unit \ Assert = {
        let text = "UNH+1'BGM+BAY'EQD+CN+C1'LOC+147+01'MEA+WT+10'EQD+CN+C2'LOC+147+02'UNT+5+1'";
        let segs = parseEdifact(text);
        // Let's check seg tags
        let tags = List.map(s -> s#tag, segs);
        // Let's assert what tags are:
        Assert.assertEq(expected = "UNH" :: "BGM" :: "EQD" :: "LOC" :: "MEA" :: "EQD" :: "LOC" :: "UNT" :: Nil, tags);

        let loops = groupByTrigger("EQD", segs);
        let numLoops = List.length(loops);
        Assert.assertEq(expected = 2, numLoops)
    }
}
