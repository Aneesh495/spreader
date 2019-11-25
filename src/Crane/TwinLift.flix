// Spreader: Container Terminal Operating System
// Ship-to-Shore (STS) Crane Twin-Lift Pairing and Spreader Eccentricity Engine

pub mod Crane.TwinLift {
    use Model.Coordinates.ShipCell;
    use Model.HazmatTypes.ImdgClass;

    /// Candidate container specification for twin-lift evaluation.
    pub type alias TwinCandidate = {
        containerId = String,
        cell = ShipCell,
        grossWeightTonnes = Float64,
        isReefer = Bool,
        hazmatClass = Option[ImdgClass]
    }

    /// Diagnostics when twin-lift pairing is rejected.
    pub enum TwinLiftIncompatibility with Eq, Order, ToString {
        case NotAdjacentTwentyFootBays(Int32, Int32),
        case RowOrTierMismatch(Int32, Int32, Int32, Int32), // (row1, tier1, row2, tier2)
        case WeightDisparityExceeded(Float64, Float64, Float64), // (wt1, wt2, maxDisparity)
        case EccentricityExceeded(Float64, Float64), // (calculatedEccentricity, maxAllowed)
        case HazmatClassIncompatible(Option[ImdgClass], Option[ImdgClass])
    }

    /// Half-distance between centers of two 20ft containers in a twin-lift spreader (meters).
    /// Standard 20ft container length = 6.058m + 0.76m spreader gap -> pitch = 6.818m, half = 3.409m.
    pub def twinPitchHalfMeters(): Float64 = 3.409

    /// Computes longitudinal center of gravity eccentricity from spreader center (meters).
    /// Resultant x_ecc = x_half * (W2 - W1) / (W1 + W2).
    pub def computeEccentricity(weight1Tonnes: Float64, weight2Tonnes: Float64): Float64 = {
        let total = weight1Tonnes + weight2Tonnes;
        if (total <= 0.0) 0.0
        else {
            let disparity = weight2Tonnes - weight1Tonnes;
            Float64.abs(twinPitchHalfMeters() * (disparity / total))
        }
    }

    /// Checks if two cells are forward-aft adjacent 20ft slots in the same row and tier.
    pub def areAdjacentTwinCells(c1: ShipCell, c2: ShipCell): Bool = {
        c1#row == c2#row and
        c1#tier == c2#tier and
        // One bay must be 2k-1 and the other 2k+1 (e.g. 1 and 3, or 5 and 7)
        Int32.abs(c1#bay - c2#bay) == 2 and
        Int32.modulo(c1#bay, 2) == 1 and
        Int32.modulo(c2#bay, 2) == 1
    }

    /// Evaluates whether two containers can be safely twin-lifted together.
    pub def validateTwinPair(
        c1: TwinCandidate,
        c2: TwinCandidate,
        maxWeightDisparityTonnes: Float64,
        maxEccentricityMeters: Float64
    ): List[TwinLiftIncompatibility] = {
        // 1. Spatial adjacency
        let adjViol = if (not areAdjacentTwinCells(c1#cell, c2#cell)) {
            if (c1#cell#row != c2#cell#row or c1#cell#tier != c2#cell#tier)
                TwinLiftIncompatibility.RowOrTierMismatch(c1#cell#row, c1#cell#tier, c2#cell#row, c2#cell#tier) :: Nil
            else
                TwinLiftIncompatibility.NotAdjacentTwentyFootBays(c1#cell#bay, c2#cell#bay) :: Nil
        } else Nil;

        // 2. Weight disparity
        let wtDiff = Float64.abs(c1#grossWeightTonnes - c2#grossWeightTonnes);
        let wtViol = if (wtDiff > maxWeightDisparityTonnes)
            TwinLiftIncompatibility.WeightDisparityExceeded(c1#grossWeightTonnes, c2#grossWeightTonnes, maxWeightDisparityTonnes) :: Nil
        else Nil;

        // 3. Eccentricity
        let ecc = computeEccentricity(c1#grossWeightTonnes, c2#grossWeightTonnes);
        let eccViol = if (ecc > maxEccentricityMeters)
            TwinLiftIncompatibility.EccentricityExceeded(ecc, maxEccentricityMeters) :: Nil
        else Nil;

        // 4. Hazmat check: Explosives and radioactives cannot be twin-lifted
        let hazViol = match (c1#hazmatClass, c2#hazmatClass) {
            case (Some(ImdgClass.Class1_1), _) => TwinLiftIncompatibility.HazmatClassIncompatible(c1#hazmatClass, c2#hazmatClass) :: Nil
            case (_, Some(ImdgClass.Class1_1)) => TwinLiftIncompatibility.HazmatClassIncompatible(c1#hazmatClass, c2#hazmatClass) :: Nil
            case (Some(ImdgClass.Class7), _) => TwinLiftIncompatibility.HazmatClassIncompatible(c1#hazmatClass, c2#hazmatClass) :: Nil
            case (_, Some(ImdgClass.Class7)) => TwinLiftIncompatibility.HazmatClassIncompatible(c1#hazmatClass, c2#hazmatClass) :: Nil
            case _ => Nil
        };

        List.flatten(adjViol :: wtViol :: eccViol :: hazViol :: Nil)
    }

    /// Automatically scans an unassigned list of containers and forms valid twin-lift pairs.
    pub def pairTwinContainers(
        candidates: List[TwinCandidate],
        maxWeightDisparityTonnes: Float64,
        maxEccentricityMeters: Float64
    ): (List[(TwinCandidate, TwinCandidate)], List[TwinCandidate]) = {
        def loop(rem: List[TwinCandidate], pairedAcc: List[(TwinCandidate, TwinCandidate)], singlesAcc: List[TwinCandidate]) = {
            match rem {
                case Nil => (List.reverse(pairedAcc), List.reverse(singlesAcc))
                case c1 :: rest => {
                    // Try to find a matching partner in rest
                    let optMatch = List.find(c2 -> 
                        List.isEmpty(validateTwinPair(c1, c2, maxWeightDisparityTonnes, maxEccentricityMeters)),
                        rest
                    );
                    match optMatch {
                        case Some(partner) => {
                            let remainingRest = List.filter(it -> it#containerId != partner#containerId, rest);
                            loop(remainingRest, (c1, partner) :: pairedAcc, singlesAcc)
                        }
                        case None => loop(rest, pairedAcc, c1 :: singlesAcc)
                    }
                }
            }
        };
        loop(candidates, Nil, Nil)
    }
}
