// Spreader: Container Terminal Operating System
// Automated Ballast Water Management: Anti-Heeling and Trim Optimization

pub mod Stability.BallastOptimizer {
    use Model.VesselProfile.BallastTank;
    use Model.VesselProfile.TankState;
    use Stability.Types.StabilityState;

    /// Recommended pump action for a single ballast tank.
    pub type alias BallastPumpAction = {
        tankId = BallastTank,
        deltaWeightTonnes = Float64, // Positive = fill/ballast, Negative = discharge/deballast
        newWeightTonnes = Float64
    }

    /// Complete ballast optimization recommendation.
    pub type alias BallastPlan = {
        actions = List[BallastPumpAction],
        residualHeelDegrees = Float64,
        residualTrimMeters = Float64
    }

    /// Calculates required anti-heeling water transfer between port and starboard wing tanks.
    /// Returns (portDeltaTonnes, stbdDeltaTonnes).
    pub def solveAntiHeeling(
        portTank: TankState,
        stbdTank: TankState,
        currentTcgMeters: Float64,
        displacementTonnes: Float64
    ): (Float64, Float64) = {
        let transverseSpan = Float64.abs(stbdTank#tcgMeters - portTank#tcgMeters);
        if (transverseSpan < 1.0) (0.0, 0.0)
        else {
            // Moment required to zero out TCG: deltaM = - (disp * currentTcg)
            let requiredTransverseMoment = - (displacementTonnes * currentTcgMeters);
            let targetTransfer = requiredTransverseMoment / transverseSpan;

            // Clamping against available tank capacities
            // If currentTcg > 0 (heeling starboard), transfer from stbd to port (or fill port)
            let (maxPortDelta, maxStbdDelta) = if (targetTransfer > 0.0) {
                // Shift weight to port
                let portAvail = portTank#capacityTonnes - portTank#currentWeightTonnes;
                let actual = Float64.min(targetTransfer, portAvail);
                (actual, -actual)
            } else {
                // Shift weight to starboard
                let stbdAvail = stbdTank#capacityTonnes - stbdTank#currentWeightTonnes;
                let actual = Float64.max(targetTransfer, -stbdAvail);
                (actual, -actual)
            };
            (maxPortDelta, maxStbdDelta)
        }
    }

    /// Calculates required trim adjustment between forepeak and aftpeak tanks.
    /// Returns (fptDeltaTonnes, aptDeltaTonnes).
    pub def solveTrimAdjustment(
        fptTank: TankState,
        aptTank: TankState,
        currentTrimMeters: Float64,
        targetTrimMeters: Float64,
        mtcTonnesMetersPerCm: Float64
    ): (Float64, Float64) = {
        let deltaTrimMeters = targetTrimMeters - currentTrimMeters;
        let deltaTrimCm = deltaTrimMeters * 100.0;
        let requiredTrimmingMoment = deltaTrimCm * mtcTonnesMetersPerCm;

        let leverArm = fptTank#lcgMeters - aptTank#lcgMeters;
        if (Float64.abs(leverArm) < 1.0) (0.0, 0.0)
        else {
            // Trim by stern is positive. Adding weight to FPT decreases stern trim.
            // deltaTM = deltaM_fpt * LCG_fpt + deltaM_apt * LCG_apt
            let requiredFptDelta = - (requiredTrimmingMoment / leverArm);

            let clampedFptDelta = if (requiredFptDelta > 0.0) {
                Float64.min(requiredFptDelta, fptTank#capacityTonnes - fptTank#currentWeightTonnes)
            } else {
                Float64.max(requiredFptDelta, -fptTank#currentWeightTonnes)
            };

            // Counterbalance on AFT peak if necessary
            let aptDelta = -clampedFptDelta;
            let clampedAptDelta = if (aptDelta > 0.0) {
                Float64.min(aptDelta, aptTank#capacityTonnes - aptTank#currentWeightTonnes)
            } else {
                Float64.max(aptDelta, -aptTank#currentWeightTonnes)
            };

            (clampedFptDelta, clampedAptDelta)
        }
    }

    /// Generates full automated ballast compensation plan.
    pub def generateBallastPlan(
        tanks: List[TankState],
        currentState: StabilityState,
        targetTrimMeters: Float64,
        mtcTonnesMetersPerCm: Float64
    ): BallastPlan = {
        let optFpt = List.find(t -> t#tankId == BallastTank.Forepeak, tanks);
        let optApt = List.find(t -> t#tankId == BallastTank.Aftpeak, tanks);
        let optWtp = List.find(t -> t#tankId == BallastTank.WingTankPort(1), tanks);
        let optWts = List.find(t -> t#tankId == BallastTank.WingTankStarboard(1), tanks);

        let (fptDelta, aptDelta) = match (optFpt, optApt) {
            case (Some(fpt), Some(apt)) =>
                solveTrimAdjustment(fpt, apt, currentState#trimMeters, targetTrimMeters, mtcTonnesMetersPerCm)
            case _ => (0.0, 0.0)
        };

        let (wtpDelta, wtsDelta) = match (optWtp, optWts) {
            case (Some(wtp), Some(wts)) =>
                solveAntiHeeling(wtp, wts, currentState#tcgMeters, currentState#displacementTonnes)
            case _ => (0.0, 0.0)
        };

        let actions = List.filterMap(t -> {
            let delta = match t#tankId {
                case BallastTank.Forepeak => fptDelta
                case BallastTank.Aftpeak => aptDelta
                case BallastTank.WingTankPort(1) => wtpDelta
                case BallastTank.WingTankStarboard(1) => wtsDelta
                case _ => 0.0
            };
            if (Float64.abs(delta) > 0.1) {
                let newLevel = t#currentWeightTonnes + delta;
                Some({ tankId = t#tankId, deltaWeightTonnes = delta, newWeightTonnes = newLevel })
            } else None
        }, tanks);

        {
            actions = actions,
            residualHeelDegrees = 0.0,
            residualTrimMeters = targetTrimMeters
        }
    }
}
