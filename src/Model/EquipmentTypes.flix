// Spreader: Container Terminal Operating System
// Automated Equipment, Spreader Modes, and Work Instruction Precedence DAGs

pub mod Model.EquipmentTypes {

    /// Spreader mechanism configuration attached to crane hoist.
    pub enum SpreaderMode with Eq, Order, ToString {
        case SingleTwentyFoot,     // Locked to 20ft length
        case SingleFortyFoot,      // Telescoped to 40ft length
        case SingleFortyFiveFoot,  // Telescoped to 45ft length
        case TwinLiftTwentyFoot    // Lifting two 20ft containers end-to-end simultaneously
    }

    /// Physical operational state of a container crane spreader.
    pub enum TwistlockState with Eq, Order, ToString {
        case Unlocked,
        case LockedToContainer(String), // Single container ID
        case LockedTwinLift(String, String) // Two 20ft container IDs (fwd, aft)
    }

    /// Ship-to-Shore (STS) Quay Crane descriptor.
    pub type alias QuayCrane = {
        craneId = String,           // E.g. "QC_01"
        currentBay = Int32,         // Longitudinal ship bay position
        safeWorkingLoadTonnes = Float64, // E.g. 65.0 tonnes
        spreaderMode = SpreaderMode,
        twistlockState = TwistlockState,
        boomRaised = Bool           // Raised during ship mooring/departure
    }

    /// Automated Stacking Crane (ASC) operating on block rails.
    pub type alias StackingCrane = {
        craneId = String,           // E.g. "ASC_A1"
        assignedBlock = String,     // E.g. "A"
        currentBay = Int32,         // Rail bay coordinate (1..60)
        currentRow = Int32,         // Trolley row coordinate (1..8)
        currentTier = Int32,        // Hoist tier coordinate (1..6)
        twistlockState = TwistlockState
    }

    /// Automated Guided Vehicle (AGV) battery-electric transfer unit.
    pub type alias Agv = {
        vehicleId = String,         // E.g. "AGV_01"
        batteryPercent = Float64,   // 0.0 .. 100.0%
        carryingContainer = Option[String],
        currentLane = String        // Waypoint / lane ID
    }

    /// Discrete container movement instruction type.
    pub enum MoveType with Eq, Order, ToString {
        case VesselDischarge,       // Ship cell -> Yard slot / AGV
        case VesselLoad,            // Yard slot / AGV -> Ship cell
        case YardReshuffle,         // Yard slot -> Buffer yard slot (digging out buried container)
        case YardHousekeeping,      // Off-peak pre-marshaling optimization
        case GateInbound,           // Road truck gate -> Yard slot
        case GateOutbound           // Yard slot -> Road truck gate
    }

    /// Execution state of a work instruction.
    pub enum InstructionStatus with Eq, Order, ToString {
        case Pending,
        case Dispatched(String),    // Dispatched to specific equipment ID
        case InProgress,
        case Completed,
        case Aborted(String)        // Failure reason
    }

    /// Container terminal work instruction node within a precedence DAG.
    pub type alias WorkInstruction = {
        instructionId = Int32,
        containerId = String,
        moveType = MoveType,
        assignedEquipmentId = Option[String],
        predecessorIds = List[Int32], // Predecessor instruction IDs that must complete first
        status = InstructionStatus
    }

    /// Checks if a work instruction is ready for dispatch (all predecessors completed).
    pub def isInstructionReady(wi: WorkInstruction, completedIds: List[Int32]): Bool = {
        match wi#status {
            case InstructionStatus.Pending =>
                List.forAll(predId -> List.memberOf(predId, completedIds), wi#predecessorIds)
            case _ => false
        }
    }

    /// Verifies twin-lift spreader weight compatibility.
    /// In twin-lift mode, the weight differential between the two 20ft containers
    /// must not exceed the crane's maximum eccentricity tolerance (typically 10.0 tonnes).
    pub def isTwinLiftWeightCompatible(grossTonnesA: Float64, grossTonnesB: Float64, maxDiffTonnes: Float64): Bool = {
        let diff = Float64.abs(grossTonnesA - grossTonnesB);
        let total = grossTonnesA + grossTonnesB;
        diff <= maxDiffTonnes and total <= 65.0 // Twin-lift safe working load threshold
    }
}
