// Spreader: Container Terminal Operating System
// Stack Structural Integrity, Weight Limits, and 20ft/40ft Stacking Constraints

pub mod Datalog.StackSafety {
    use Model.Types.ContainerLength;
    use Model.Coordinates.ShipCell;

    /// Stowed container cell with weight and dimension specifications.
    pub type alias StowedStackItem = {
        containerId = String,
        cell = ShipCell,
        length = ContainerLength,
        grossWeightTonnes = Float64
    }

    /// Structural stack violation report.
    pub enum StackViolation with Eq, Order, ToString {
        case HeavyOverLight(String, String, Float64, Float64, String), // (upperId, lowerId, upperWt, lowerWt, location)
        case TwentyOnFortyIncompatible(String, String, String),        // (upper20Id, lower40Id, location)
        case StackWeightExceeded(Int32, Int32, Float64, Float64),      // (bay, row, actualTotalWt, maxLimitWt)
        case FloatingContainer(String, Int32, Int32, Int32)            // (containerId, bay, row, tier)
    }

    /// Helper to verify adjacent vertical tiers in a single stack column.
    def checkAdjacentPairs(xs: List[StowedStackItem], maxWeightDisparityTonnes: Float64): List[StackViolation] = {
        match xs {
            case i1 :: i2 :: rest => {
                // A. Heavy-over-light check: Upper weight must not exceed lower weight + maxWeightDisparityTonnes
                let heavyViol = if (i2#grossWeightTonnes > (i1#grossWeightTonnes + maxWeightDisparityTonnes)) {
                    let loc = "Bay ${i1#cell#bay}, Row ${i1#cell#row}, Tiers ${i1#cell#tier}->${i2#cell#tier}";
                    StackViolation.HeavyOverLight(i2#containerId, i1#containerId, i2#grossWeightTonnes, i1#grossWeightTonnes, loc) :: Nil
                } else Nil;

                // B. Twenty-on-forty check: 20ft container on top of 40ft container
                let twentyOnFortyViol = if (i1#length == ContainerLength.FortyFoot and i2#length == ContainerLength.TwentyFoot) {
                    let loc = "Bay ${i1#cell#bay}, Row ${i1#cell#row}, Tiers ${i1#cell#tier}->${i2#cell#tier}";
                    StackViolation.TwentyOnFortyIncompatible(i2#containerId, i1#containerId, loc) :: Nil
                } else Nil;

                // C. Floating container check: Gap in tier indices (e.g. tier 06 placed above tier 02 without tier 04)
                let gapViol = if ((i2#cell#tier - i1#cell#tier) > 2) {
                    StackViolation.FloatingContainer(i2#containerId, i2#cell#bay, i2#cell#row, i2#cell#tier) :: Nil
                } else Nil;

                let currentViols = List.flatten(heavyViol :: twentyOnFortyViol :: gapViol :: Nil);
                currentViols ::: checkAdjacentPairs(i2 :: rest, maxWeightDisparityTonnes)
            }
            case _ => Nil
        }
    }

    /// Validates all vertical stacks across the vessel or yard block.
    pub def checkStackSafety(
        items: List[StowedStackItem],
        maxStackWeightTonnes: Float64,
        maxWeightDisparityTonnes: Float64
    ): List[StackViolation] = {
        // Group items by (bay, row) vertical stack column
        let grouped = List.groupBy(i -> (i#cell#bay, i#cell#row), items);

        List.flatMap(nel -> {
            let col = Nel.toList(nel);
            // Sort column ascending by tier (from bottom up)
            let sortedCol = List.sortBy(i -> i#cell#tier, col);

            // 1. Total stack weight check
            let totalColWeight = List.foldLeft((acc, i) -> acc + i#grossWeightTonnes, 0.0, sortedCol);
            let weightViolations = match List.head(sortedCol) {
                case Some(bottomItem) =>
                    if (totalColWeight > maxStackWeightTonnes)
                        StackViolation.StackWeightExceeded(bottomItem#cell#bay, bottomItem#cell#row, totalColWeight, maxStackWeightTonnes) :: Nil
                    else Nil
                case None => Nil
            };

            // 2. Pairwise adjacent tier checks (lower item, upper item)
            let pairViolations = checkAdjacentPairs(sortedCol, maxWeightDisparityTonnes);
            List.flatten(weightViolations :: pairViolations :: Nil)
        }, grouped)
    }
}
