// Spreader: Container Terminal Operating System
// Test Suite for UN/LOCODE Directory, Geodesics, and Rotation Validation

mod TestPortDirectory {

    use Edi.PortDirectory
    use Edi.PortDirectory.PortRecord

    @Test
    def testLookupKnownPort(): Unit \ Assert = {
        let portOpt = PortDirectory.lookupPort("SGSIN");
        match portOpt {
            case None => Assert.assertTrue(false)
            case Some(p) => {
                Assert.assertEq(expected = "SGSIN", p#locode);
                Assert.assertEq(expected = "Singapore", p#portName);
                Assert.assertEq(expected = "SG", p#countryCode);
                Assert.assertEq(expected = 8, p#timeZoneOffset)
            }
        }
    }

    @Test
    def testLookupUnknownPort(): Unit \ Assert = {
        match PortDirectory.lookupPort("ZZZZZ") {
            case None => Assert.assertTrue(true)
            case Some(_) => Assert.assertTrue(false)
        }
    }

    @Test
    def testValidLocodeSyntax(): Unit \ Assert = {
        Assert.assertTrue(PortDirectory.isValidLocode("NLRTM"));
        Assert.assertTrue(PortDirectory.isValidLocode("USLAX"));
        Assert.assertTrue(not PortDirectory.isValidLocode("NL123"));
        Assert.assertTrue(not PortDirectory.isValidLocode("SINGAPORE"));
        Assert.assertTrue(not PortDirectory.isValidLocode("sgsin"))
    }

    @Test
    def testRotationSequenceAndOverstow(): Unit \ Assert = {
        let rotation = "CNSHA" :: "SGSIN" :: "AEJEA" :: "MAPTM" :: "NLRTM" :: "DEHAM" :: Nil;

        // Sequence indices
        let shaIdx = PortDirectory.callIndex(rotation, "CNSHA");
        let rtmIdx = PortDirectory.callIndex(rotation, "NLRTM");
        let validSeq = PortDirectory.isCallAfter(rotation, "CNSHA", "NLRTM");
        let invalidSeq = PortDirectory.isCallAfter(rotation, "NLRTM", "CNSHA");

        Assert.assertEq(expected = Some(0), shaIdx);
        Assert.assertEq(expected = Some(4), rtmIdx);
        Assert.assertTrue(validSeq);
        Assert.assertTrue(not invalidSeq);

        // Overstow detection:
        // Case 1: Lower container POD is SGSIN (index 1), Upper container POD is NLRTM (index 4).
        // Discharging at SGSIN requires shifting the upper container. This is an overstow!
        let isOverstow = PortDirectory.detectOverstow(rotation, "SGSIN", "NLRTM");
        Assert.assertTrue(isOverstow);

        // Case 2: Lower container POD is NLRTM (index 4), Upper container POD is SGSIN (index 1).
        // Discharging SGSIN first removes the top container safely; when arriving at NLRTM, lower container is reachable.
        // Not an overstow!
        let notOverstow = PortDirectory.detectOverstow(rotation, "NLRTM", "SGSIN");
        Assert.assertTrue(not notOverstow);

        // Case 3: Same POD
        let samePod = PortDirectory.detectOverstow(rotation, "SGSIN", "SGSIN");
        Assert.assertTrue(not samePod)
    }

    @Test
    def testPortDistanceCalculation(): Unit \ Assert = {
        // Distance between Rotterdam (NLRTM) and Hamburg (DEHAM)
        match PortDirectory.portDistanceNm("NLRTM", "DEHAM") {
            case None => Assert.assertTrue(false)
            case Some(dist) => {
                // Rotterdam to Hamburg straight-line distance is approximately 200 - 300 NM
                Assert.assertTrue(dist > 150.0);
                Assert.assertTrue(dist < 350.0)
            }
        }
    }
}
