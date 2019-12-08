// Test suite for Pure ISO 9735 UN/EDIFACT Tokenizer and Escape Processor

mod TestEdiTokenizer {
    use Edi.Tokenizer.{parseUna, parseEdifact, EdiSegment, defaultDelimiters};

    @Test
    def testUnaParsing(): Unit \ Assert = {
        let unaText = "UNA:+.? 'BGM+BAY+001+9'";
        let (delims, body) = parseUna(unaText);
        Assert.assertEq(expected = ':', delims#componentSeparator);
        Assert.assertEq(expected = '+', delims#elementSeparator);
        Assert.assertEq(expected = '.', delims#decimalNotation);
        Assert.assertEq(expected = '?', delims#releaseIndicator);
        Assert.assertEq(expected = '\'', delims#segmentTerminator);
        Assert.assertEq(expected = "BGM+BAY+001+9'", body)
    }

    @Test
    def testStandardSegmentTokenization(): Unit \ Assert = {
        let text = "UNH+1+BAPLIE:D:95B:UN:SMDG22'BGM+BAY+V1234+9'UNT+2+1'";
        let segs = parseEdifact(text);
        Assert.assertEq(expected = 3, List.length(segs));

        match segs {
            case unh :: bgm :: unt :: Nil => {
                Assert.assertEq(expected = "UNH", unh#tag);
                Assert.assertEq(expected = "BGM", bgm#tag);
                Assert.assertEq(expected = "UNT", unt#tag);

                // Check UNH elements: element 1 is ["1"], element 2 is composite ["BAPLIE", "D", "95B", "UN", "SMDG22"]
                match unh#elements {
                    case e1 :: e2 :: Nil => {
                        Assert.assertEq(expected = "1" :: Nil, e1);
                        Assert.assertEq(expected = "BAPLIE" :: "D" :: "95B" :: "UN" :: "SMDG22" :: Nil, e2)
                    }
                    case _ => Assert.assertTrue(false)
                }
            }
            case _ => Assert.assertTrue(false)
        }
    }

    @Test
    def testReleaseEscapeCharacters(): Unit \ Assert = {
        // String has ?+ and ?' which should not split element or segment
        let text = "FTX+AAI+++TEXT WITH ?+ PLUS AND ?' QUOTE'EQD+CN+MSKU001'";
        let segs = parseEdifact(text);
        Assert.assertEq(expected = 2, List.length(segs));

        match segs {
            case ftx :: eqd :: Nil => {
                Assert.assertEq(expected = "FTX", ftx#tag);
                Assert.assertEq(expected = "EQD", eqd#tag);
                match ftx#elements {
                    case _ :: _ :: _ :: textElem :: Nil => {
                        match textElem {
                            case s :: Nil => Assert.assertEq(expected = "TEXT WITH + PLUS AND ' QUOTE", s)
                            case _ => Assert.assertTrue(false)
                        }
                    }
                    case _ => Assert.assertTrue(false)
                }
            }
            case _ => Assert.assertTrue(false)
        }
    }
}
