mod TestEquipment {
    use Model.EquipmentTypes.{
        SpreaderMode, TwistlockState, QuayCrane, StackingCrane, Agv,
        MoveType, InstructionStatus, WorkInstruction, isInstructionReady,
        isTwinLiftWeightCompatible
    };

    @Test
    def testTwinLiftCompatibility(): Unit \ Assert = {
        // Container A = 18.0 tonnes, Container B = 22.0 tonnes -> diff = 4.0 <= 10.0, total = 40.0 <= 65.0
        Assert.assertEq(expected = true, isTwinLiftWeightCompatible(18.0, 22.0, 10.0));

        // Excess weight disparity: A = 10.0 tonnes, B = 25.0 tonnes -> diff = 15.0 > 10.0
        Assert.assertEq(expected = false, isTwinLiftWeightCompatible(10.0, 25.0, 10.0));

        // Overweight sum: A = 34.0 tonnes, B = 33.0 tonnes -> total = 67.0 > 65.0
        Assert.assertEq(expected = false, isTwinLiftWeightCompatible(34.0, 33.0, 10.0))
    }

    @Test
    def testWorkInstructionPrecedence(): Unit \ Assert = {
        let wi: WorkInstruction = {
            instructionId = 201,
            containerId = "MSKU5551234",
            moveType = MoveType.VesselDischarge,
            assignedEquipmentId = Some("QC_01"),
            predecessorIds = 101 :: 102 :: Nil,
            status = InstructionStatus.Pending
        };

        // When neither predecessor is complete
        Assert.assertEq(expected = false, isInstructionReady(wi, Nil));

        // When only 101 is complete
        Assert.assertEq(expected = false, isInstructionReady(wi, 101 :: Nil));

        // When both 101 and 102 are complete
        Assert.assertEq(expected = true, isInstructionReady(wi, 101 :: 102 :: Nil));

        // When already completed or in progress, ready is false
        let wiDone = {
            instructionId = 201,
            containerId = "MSKU5551234",
            moveType = MoveType.VesselDischarge,
            assignedEquipmentId = Some("QC_01"),
            predecessorIds = 101 :: 102 :: Nil,
            status = InstructionStatus.Completed
        };
        Assert.assertEq(expected = false, isInstructionReady(wiDone, 101 :: 102 :: Nil))
    }
}
