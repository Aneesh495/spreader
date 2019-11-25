// Spreader: Container Terminal Operating System
// Ship-to-Shore (STS) Quay Crane Dual-Cycling and Trolley Round-Trip Optimizer

pub mod Crane.DualCycle {
    use Model.EquipmentTypes.MoveType;

    /// Crane operational cycle mode with explicit coordinate primitives.
    pub enum CycleMove with Eq, Order, ToString {
        case SingleDischarge(String, Int32, Int32, Int32),               // (containerId, bay, row, tier)
        case SingleLoad(String, Int32, Int32, Int32),                    // (containerId, bay, row, tier)
        case DualCyclePair(String, Int32, Int32, Int32, String, Int32, Int32, Int32) // (dId, dBay, dRow, dTier, lId, lBay, lRow, lTier)
    }

    /// Input work task for crane scheduling.
    pub type alias CraneTask = {
        containerId = String,
        moveType = MoveType,
        bay = Int32,
        row = Int32,
        tier = Int32
    }

    /// Dual-cycle execution schedule summary.
    pub type alias DualCyclePlan = {
        cycles = List[CycleMove],
        numDischarges = Int32,
        numLoads = Int32,
        numDualCycles = Int32,
        estimatedTotalTimeSec = Float64,
        timeSavingsPercent = Float64
    }

    /// Single cycle average duration in seconds (hoist, trolley, lower, empty return).
    pub def singleCycleDurationSec(): Float64 = 110.0

    /// Dual cycle average duration in seconds (discharge + load on same round trip).
    pub def dualCycleDurationSec(): Float64 = 145.0

    /// Interleaves discharge and load tasks into dual-cycle pairs.
    pub def buildDualCycleSchedule(
        discharges: List[CraneTask],
        loads: List[CraneTask]
    ): DualCyclePlan = {
        let nDisch = List.length(discharges);
        let nLoad = List.length(loads);

        def pairUp(dRem: List[CraneTask], lRem: List[CraneTask], acc: List[CycleMove]): (List[CycleMove], Int32) = {
            match (dRem, lRem) {
                case (d :: dTail, l :: lTail) => {
                    let pair = CycleMove.DualCyclePair(
                        d#containerId, d#bay, d#row, d#tier,
                        l#containerId, l#bay, l#row, l#tier
                    );
                    pairUp(dTail, lTail, pair :: acc)
                }
                case (d :: dTail, Nil) => {
                    pairUp(dTail, Nil, CycleMove.SingleDischarge(d#containerId, d#bay, d#row, d#tier) :: acc)
                }
                case (Nil, l :: lTail) => {
                    pairUp(Nil, lTail, CycleMove.SingleLoad(l#containerId, l#bay, l#row, l#tier) :: acc)
                }
                case (Nil, Nil) => {
                    let dualCount = Int32.min(nDisch, nLoad);
                    (List.reverse(acc), dualCount)
                }
            }
        };

        let (cycles, numDual) = pairUp(discharges, loads, Nil);
        let numSingleDisch = nDisch - numDual;
        let numSingleLoad = nLoad - numDual;

        // Baseline single-cycle time (each move done independently with empty return)
        let baselineTimeSec = Int32.toFloat64(nDisch + nLoad) * singleCycleDurationSec();
        // Dual-cycle optimized time
        let optimizedTimeSec = 
            (Int32.toFloat64(numDual) * dualCycleDurationSec()) +
            (Int32.toFloat64(numSingleDisch + numSingleLoad) * singleCycleDurationSec());

        let timeSavings = if (baselineTimeSec <= 0.0) 0.0
                          else ((baselineTimeSec - optimizedTimeSec) / baselineTimeSec) * 100.0;

        {
            cycles = cycles,
            numDischarges = nDisch,
            numLoads = nLoad,
            numDualCycles = numDual,
            estimatedTotalTimeSec = optimizedTimeSec,
            timeSavingsPercent = timeSavings
        }
    }
}
