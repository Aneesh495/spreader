// Test suite for Stack Safety, Weight Limits, and Structural Constraints

mod TestStackSafety {
    use Model.Types.ContainerLength;
    use Datalog.StackSafety.StowedStackItem;
    use Datalog.StackSafety.StackViolation;
    use Datalog.StackSafety.checkStackSafety;

    @Test
    def testCompliantStack(): Unit \ Assert = {
        let items: List[StowedStackItem] = 
            { containerId = "MSCU1000001", cell = { bay = 1, row = 1, tier = 2 }, length = ContainerLength.FortyFoot, grossWeightTonnes = 28.0 } ::
            { containerId = "MSCU1000002", cell = { bay = 1, row = 1, tier = 4 }, length = ContainerLength.FortyFoot, grossWeightTonnes = 24.0 } ::
            { containerId = "MSCU1000003", cell = { bay = 1, row = 1, tier = 6 }, length = ContainerLength.FortyFoot, grossWeightTonnes = 18.0 } :: Nil;
        
        let viols = checkStackSafety(items, 100.0, 5.0);
        Assert.assertTrue(List.isEmpty(viols))
    }

    @Test
    def testHeavyOverLightViolation(): Unit \ Assert = {
        // Lower is 10.0 tonnes, upper is 28.0 tonnes (exceeds 10.0 + 5.0)
        let items: List[StowedStackItem] = 
            { containerId = "MSCU1000001", cell = { bay = 1, row = 1, tier = 2 }, length = ContainerLength.FortyFoot, grossWeightTonnes = 10.0 } ::
            { containerId = "MSCU1000002", cell = { bay = 1, row = 1, tier = 4 }, length = ContainerLength.FortyFoot, grossWeightTonnes = 28.0 } :: Nil;
        
        let viols = checkStackSafety(items, 100.0, 5.0);
        let found = match viols {
            case StackViolation.HeavyOverLight(up, low, _, _, _) :: Nil =>
                up == "MSCU1000002" and low == "MSCU1000001"
            case _ => false
        };
        Assert.assertTrue(found)
    }

    @Test
    def testTwentyOnFortyViolation(): Unit \ Assert = {
        // Lower is 40ft, upper is 20ft
        let items: List[StowedStackItem] = 
            { containerId = "MSCU1000001", cell = { bay = 3, row = 2, tier = 82 }, length = ContainerLength.FortyFoot, grossWeightTonnes = 20.0 } ::
            { containerId = "MSCU1000002", cell = { bay = 3, row = 2, tier = 84 }, length = ContainerLength.TwentyFoot, grossWeightTonnes = 15.0 } :: Nil;
        
        let viols = checkStackSafety(items, 100.0, 10.0);
        let found = match viols {
            case StackViolation.TwentyOnFortyIncompatible(up, low, _) :: Nil =>
                up == "MSCU1000002" and low == "MSCU1000001"
            case _ => false
        };
        Assert.assertTrue(found)
    }

    @Test
    def testStackWeightExceeded(): Unit \ Assert = {
        let items: List[StowedStackItem] = 
            { containerId = "MSCU1000001", cell = { bay = 5, row = 4, tier = 2 }, length = ContainerLength.FortyFoot, grossWeightTonnes = 30.0 } ::
            { containerId = "MSCU1000002", cell = { bay = 5, row = 4, tier = 4 }, length = ContainerLength.FortyFoot, grossWeightTonnes = 30.0 } ::
            { containerId = "MSCU1000003", cell = { bay = 5, row = 4, tier = 6 }, length = ContainerLength.FortyFoot, grossWeightTonnes = 30.0 } ::
            { containerId = "MSCU1000004", cell = { bay = 5, row = 4, tier = 8 }, length = ContainerLength.FortyFoot, grossWeightTonnes = 25.0 } :: Nil;
        
        // Total weight is 115.0 tonnes, max allowed is 100.0 tonnes
        let viols = checkStackSafety(items, 100.0, 5.0);
        let found = List.exists(v -> match v {
            case StackViolation.StackWeightExceeded(b, r, total, maxLim) =>
                b == 5 and r == 4 and total == 115.0 and maxLim == 100.0
            case _ => false
        }, viols);
        Assert.assertTrue(found)
    }

    @Test
    def testFloatingContainerGap(): Unit \ Assert = {
        // Lower is tier 2, upper is tier 6 (tier 4 is missing)
        let items: List[StowedStackItem] = 
            { containerId = "MSCU1000001", cell = { bay = 1, row = 1, tier = 2 }, length = ContainerLength.FortyFoot, grossWeightTonnes = 20.0 } ::
            { containerId = "MSCU1000002", cell = { bay = 1, row = 1, tier = 6 }, length = ContainerLength.FortyFoot, grossWeightTonnes = 18.0 } :: Nil;
        
        let viols = checkStackSafety(items, 100.0, 5.0);
        let found = List.exists(v -> match v {
            case StackViolation.FloatingContainer(cid, _, _, t) =>
                cid == "MSCU1000002" and t == 6
            case _ => false
        }, viols);
        Assert.assertTrue(found)
    }
}
