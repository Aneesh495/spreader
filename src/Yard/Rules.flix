// Spreader: Container Terminal Operating System
// Yard Stacking Safety Rules, Dynamic Wind Tier Derating, and Reefer Plug Interlocks

pub mod Yard.Rules {
    use Model.YardCoordinates.YardSlot;
    use Yard.YardBlock.{YardContainer, BlockState, isSlotWithinBounds, isOccupied, stackTotalWeight, stackTopTier};

    /// Stacking rule violation diagnostics.
    pub enum YardViolation with Eq, Order, ToString {
        case SlotOutOfBounds(String, Int32, Int32, Int32),            // (block, bay, row, tier)
        case SlotAlreadyOccupied(String, Int32, Int32, Int32),        // (block, bay, row, tier)
        case FloatingPlacement(String, Int32, Int32, Int32),          // (block, bay, row, tier)
        case StackWeightExceeded(Int32, Int32, Float64, Float64),     // (bay, row, actualWt, maxWt)
        case WindStackHeightExceeded(Int32, Int32, Int32, Int32),    // (bay, row, actualTier, maxAllowedTier)
        case ReeferPlugUnavailable(String, Int32, Int32, Int32)       // (block, bay, row, tier)
    }

    /// Computes maximum permissible stack tier given current wind speed (m/s).
    pub def maxPermissibleTierForWind(baseMaxTier: Int32, windSpeedMps: Float64): Int32 = {
        if (windSpeedMps >= 28.0) 2       // Typhoon / Storm condition
        else if (windSpeedMps >= 20.0) 3  // Beaufort 8 Gale
        else if (windSpeedMps >= 15.0) 4  // Beaufort 7 Strong Breeze
        else baseMaxTier                  // Normal operations
    }

    /// Checks if a reefer plug is available at the candidate slot.
    pub def isReeferPlugAvailable(slot: YardSlot, state: BlockState): Bool = {
        let isReeferBay = List.memberOf(slot#bay, state#profile#reeferBays);
        if (not isReeferBay) false
        else {
            // Count active reefers in this bay-row stack
            let activeReefers = List.count(c -> 
                c#slot#block == slot#block and
                c#slot#bay == slot#bay and
                c#slot#row == slot#row and
                c#isReefer,
                state#containers
            );
            // Standard reefer rack provides up to 4 plugs per vertical column
            activeReefers < 4
        }
    }

    /// Validates placement of an incoming container into the yard block.
    pub def validatePlacement(
        candidate: YardContainer,
        state: BlockState,
        windSpeedMps: Float64
    ): List[YardViolation] = {
        let slot = candidate#slot;

        // 1. Boundary check
        let boundsViol = if (not isSlotWithinBounds(slot, state#profile))
            YardViolation.SlotOutOfBounds(slot#block, slot#bay, slot#row, slot#tier) :: Nil
        else Nil;

        // 2. Occupancy check
        let occViol = if (isOccupied(slot, state#containers))
            YardViolation.SlotAlreadyOccupied(slot#block, slot#bay, slot#row, slot#tier) :: Nil
        else Nil;

        // 3. Floating check: Must either be ground slot (tier 1) or tier == topTier + 1
        let topTier = stackTopTier(slot#block, slot#bay, slot#row, state#containers);
        let floatingViol = if (slot#tier > 1 and slot#tier != (topTier + 1))
            YardViolation.FloatingPlacement(slot#block, slot#bay, slot#row, slot#tier) :: Nil
        else Nil;

        // 4. Weight limit check
        let currentWt = stackTotalWeight(slot#block, slot#bay, slot#row, state#containers);
        let newTotalWt = currentWt + candidate#grossWeightTonnes;
        let weightViol = if (newTotalWt > state#profile#maxStackWeightTonnes)
            YardViolation.StackWeightExceeded(slot#bay, slot#row, newTotalWt, state#profile#maxStackWeightTonnes) :: Nil
        else Nil;

        // 5. Wind derating check
        let maxWindTier = maxPermissibleTierForWind(state#profile#maxTier, windSpeedMps);
        let windViol = if (slot#tier > maxWindTier)
            YardViolation.WindStackHeightExceeded(slot#bay, slot#row, slot#tier, maxWindTier) :: Nil
        else Nil;

        // 6. Reefer plug check
        let reeferViol = if (candidate#isReefer and not isReeferPlugAvailable(slot, state))
            YardViolation.ReeferPlugUnavailable(slot#block, slot#bay, slot#row, slot#tier) :: Nil
        else Nil;

        List.flatten(boundsViol :: occViol :: floatingViol :: weightViol :: windViol :: reeferViol :: Nil)
    }
}
