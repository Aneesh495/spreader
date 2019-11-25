// Spreader: Container Terminal Operating System
// Dual-Cycle Precedence DAG Verification and Productivity Analytics

pub mod Crane.Precedence {
    use Crane.DualCycle.CycleMove;

    /// Structural precedence conflict in crane sequence.
    pub enum PrecedenceViolation with Eq, Order, ToString {
        case LoadBeforeDischargeInSameColumn(Int32, Int32, Int32, Int32), // (bay, row, loadTier, dischargeTier)
        case UnderdeckLoadBeforeDeckDischarge(Int32, Int32)                // (bay, holdNumber)
    }

    /// Operational crane productivity metrics.
    pub type alias ProductivityMetrics = {
        totalContainerMoves = Int32,
        totalTrolleyTrips = Int32,
        efficiencyFactor = Float64, // Moves per round trip (1.0 = pure single cycle, 2.0 = pure dual cycle)
        grossMovesPerHour = Float64
    }

    /// Computes terminal quay crane productivity KPIs from a dual-cycle schedule.
    pub def computeProductivity(
        totalDischarges: Int32,
        totalLoads: Int32,
        dualCyclesCount: Int32,
        totalExecutionTimeSec: Float64
    ): ProductivityMetrics = {
        let totalMoves = totalDischarges + totalLoads;
        let singleMoves = (totalDischarges - dualCyclesCount) + (totalLoads - dualCyclesCount);
        let trolleyTrips = dualCyclesCount + singleMoves;

        let efficiency = if (trolleyTrips <= 0) 1.0
                         else Int32.toFloat64(totalMoves) / Int32.toFloat64(trolleyTrips);

        let gmph = if (totalExecutionTimeSec <= 0.0) 0.0
                   else (Int32.toFloat64(totalMoves) * 3600.0) / totalExecutionTimeSec;

        {
            totalContainerMoves = totalMoves,
            totalTrolleyTrips = trolleyTrips,
            efficiencyFactor = efficiency,
            grossMovesPerHour = gmph
        }
    }

    /// Verifies that in any dual-cycle pair, loading does not violate stack order relative to discharge.
    pub def checkCyclePairSafety(pair: CycleMove): Option[PrecedenceViolation] = {
        match pair {
            case CycleMove.DualCyclePair(_, dBay, dRow, dTier, _, lBay, lRow, lTier) => {
                // If in the exact same stack column, discharge tier must be strictly higher than load tier
                // (e.g. discharging top tier 86, loading into lower tier 82 is safe)
                if (dBay == lBay and dRow == lRow and lTier >= dTier)
                    Some(PrecedenceViolation.LoadBeforeDischargeInSameColumn(dBay, dRow, lTier, dTier))
                else None
            }
            case _ => None
        }
    }

    /// Validates an entire list of dual-cycle moves.
    pub def validateSchedulePrecedence(cycles: List[CycleMove]): List[PrecedenceViolation] = {
        List.filterMap(checkCyclePairSafety, cycles)
    }
}
