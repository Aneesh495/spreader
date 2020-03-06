// Spreader: Container Terminal Operating System
// Test Suite for Terminal Visualizer and ANSI Bay Cross-Section Renderer

mod TestVisualizer {

    use Visualizer.{colorize, stripAnsi, fgRed, bold}
    use Visualizer.AnsiBayCrossSection
    use Visualizer.AnsiBayCrossSection.RenderCell

    @Test
    def testStripAnsi(): Unit \ Assert = {
        let colored = colorize("VESSEL_BAY", fgRed() + bold());
        let plain = stripAnsi(colored);
        Assert.assertEq(expected = "VESSEL_BAY", plain)
    }

    @Test
    def testFormatCellTypes(): Unit \ Assert = {
        let emptyFormatted = AnsiBayCrossSection.formatCell(None);
        Assert.assertTrue(String.contains(substr = "[ . ]", emptyFormatted));

        let stdCell = {
            row = 2, tier = 82, containerId = "MSKU1234567", isoType = "42G1",
            grossWeightTonnes = 22.5, isReefer = false, isHazmat = false, hazmatClass = None
        };
        let stdFormatted = AnsiBayCrossSection.formatCell(Some(stdCell));
        Assert.assertTrue(String.contains(substr = "[STD]", stdFormatted));

        let refCell = {
            row = 4, tier = 84, containerId = "MSKU2345678", isoType = "45R1",
            grossWeightTonnes = 24.0, isReefer = true, isHazmat = false, hazmatClass = None
        };
        let refFormatted = AnsiBayCrossSection.formatCell(Some(refCell));
        Assert.assertTrue(String.contains(substr = "[REF]", refFormatted));

        let hazCell = {
            row = 6, tier = 86, containerId = "MSKU3456789", isoType = "22G1",
            grossWeightTonnes = 18.0, isReefer = false, isHazmat = true, hazmatClass = Some("3")
        };
        let hazFormatted = AnsiBayCrossSection.formatCell(Some(hazCell));
        Assert.assertTrue(String.contains(substr = "[HAZ]", hazFormatted))
    }

    @Test
    def testRenderBayCrossSection(): Unit \ Assert = {
        let rows = 6 :: 4 :: 2 :: 0 :: 1 :: 3 :: 5 :: Nil;
        let deckTiers = 86 :: 84 :: 82 :: Nil;
        let holdTiers = 6 :: 4 :: 2 :: Nil;

        let c1 = {
            row = 2, tier = 84, containerId = "MSKU1111111", isoType = "42G1",
            grossWeightTonnes = 20.0, isReefer = false, isHazmat = false, hazmatClass = None
        };
        let c2 = {
            row = 0, tier = 4, containerId = "MSKU2222222", isoType = "22R1",
            grossWeightTonnes = 15.0, isReefer = true, isHazmat = false, hazmatClass = None
        };

        let rendered = AnsiBayCrossSection.renderBay(1, rows, deckTiers, holdTiers, c1 :: c2 :: Nil);
        let plain = stripAnsi(rendered);

        Assert.assertTrue(String.contains(substr = "BAY 01", plain));
        Assert.assertTrue(String.contains(substr = "[DECK HATCH COVER]", plain));
        Assert.assertTrue(String.contains(substr = "[STD]", plain));
        Assert.assertTrue(String.contains(substr = "[REF]", plain));
        Assert.assertTrue(String.contains(substr = "[ . ]", plain))
    }
}
