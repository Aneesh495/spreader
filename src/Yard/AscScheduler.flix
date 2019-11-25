// Spreader: Container Terminal Operating System
// Automated Stacking Crane (ASC) Yard Dispatch, Trajectory Interlocks, and Handshake Zones

pub mod Yard.AscScheduler {
    use Model.YardCoordinates.AscKinematics;

    /// Real-time kinematic tracking state for an automated stacking crane.
    pub type alias AscState = {
        craneId = String,
        currentBay = Int32,
        targetBay = Int32,
        isCarrying = Bool,
        carriedContainerId = Option[String]
    }

    /// Dynamic rail trajectory conflict diagnostics.
    pub enum AscConflict with Eq, Order, ToString {
        case StaticBufferViolation(String, String, Int32, Int32), // (craneA, craneB, bayA, bayB)
        case TrajectoryCrossingConflict(String, String, Int32, Int32), // (craneA, craneB, targetA, targetB)
        case HandshakeZoneContention(String, String, Int32)
    }

    /// Action dispatched to an ASC.
    pub enum AscDispatchAction with Eq, Order, ToString {
        case ProceedToTarget(String, Int32),
        case HoldPosition(String, Int32, String) // (craneId, holdBay, reason)
    }

    /// Checks if two cranes violate minimum rail separation buffer (in bays).
    pub def checkStaticClearance(c1: AscState, c2: AscState, minBayBuffer: Int32): Option[AscConflict] = {
        let diff = Int32.abs(c1#currentBay - c2#currentBay);
        if (diff < minBayBuffer)
            Some(AscConflict.StaticBufferViolation(c1#craneId, c2#craneId, c1#currentBay, c2#currentBay))
        else None
    }

    /// Detects if planned crane trajectories will cross each other on the rail.
    pub def checkTrajectoryCrossing(c1: AscState, c2: AscState): Option[AscConflict] = {
        // Assume c1 starts to the left (smaller bay) of c2
        let (left, right) = if (c1#currentBay <= c2#currentBay) (c1, c2) else (c2, c1);
        // If left moves right past right's target, or right moves left past left's target
        if (left#targetBay >= right#targetBay or left#targetBay >= right#currentBay)
            Some(AscConflict.TrajectoryCrossingConflict(left#craneId, right#craneId, left#targetBay, right#targetBay))
        else None
    }

    /// Resolves crane dispatch with priority given to loaded crane or waterside vessel critical path.
    pub def dispatchTwinAscs(
        watersideAsc: AscState,
        landsideAsc: AscState,
        minBayBuffer: Int32
    ): (AscDispatchAction, AscDispatchAction) = {
        // Check if targets would violate buffer
        let targetDiff = landsideAsc#targetBay - watersideAsc#targetBay;
        if (targetDiff < minBayBuffer) {
            // Priority: Loaded crane over empty crane; if tied, waterside crane has priority
            if (landsideAsc#isCarrying and not watersideAsc#isCarrying) {
                // Landside proceeds, Waterside holds at safe clearance
                let safeHoldBay = Int32.max(1, landsideAsc#targetBay - minBayBuffer);
                (AscDispatchAction.HoldPosition(watersideAsc#craneId, safeHoldBay, "Yield to loaded Landside ASC"),
                 AscDispatchAction.ProceedToTarget(landsideAsc#craneId, landsideAsc#targetBay))
            } else {
                // Waterside proceeds, Landside holds
                let safeHoldBay = watersideAsc#targetBay + minBayBuffer;
                (AscDispatchAction.ProceedToTarget(watersideAsc#craneId, watersideAsc#targetBay),
                 AscDispatchAction.HoldPosition(landsideAsc#craneId, safeHoldBay, "Yield to Waterside vessel dispatch"))
            }
        } else {
            // Both can proceed safely
            (AscDispatchAction.ProceedToTarget(watersideAsc#craneId, watersideAsc#targetBay),
             AscDispatchAction.ProceedToTarget(landsideAsc#craneId, landsideAsc#targetBay))
        }
    }
}
