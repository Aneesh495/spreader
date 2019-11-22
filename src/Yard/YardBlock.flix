// Spreader: Container Terminal Operating System
// 3D Container Yard Block Topology, Stacking Geometry, and Slot Occupancy

pub mod Yard.YardBlock {
    use Model.YardCoordinates.YardSlot;
    use Model.HazmatTypes.ImdgClass;

    /// Container parked in a yard slot.
    pub type alias YardContainer = {
        containerId = String,
        slot = YardSlot,
        grossWeightTonnes = Float64,
        pickupOrder = Int32, // Lower value indicates earlier scheduled retrieval
        isReefer = Bool,
        hazmatClass = Option[ImdgClass]
    }

    /// Block layout geometry and operational limits.
    pub type alias BlockProfile = {
        blockId = String,
        numBays = Int32,   // Number of 20ft bays (e.g. 60)
        numRows = Int32,   // Transverse width (e.g. 8 rows)
        maxTier = Int32,   // Maximum permissible stack height (e.g. 5 or 6)
        reeferBays = List[Int32], // Bays equipped with reefer power plugs
        maxStackWeightTonnes = Float64
    }

    /// Complete state of a yard block.
    pub type alias BlockState = {
        profile = BlockProfile,
        containers = List[YardContainer]
    }

    /// Standard layout for an automated stacking crane (ASC) block.
    pub def standardAscBlock(blockId: String): BlockProfile = {
        blockId = blockId,
        numBays = 40,
        numRows = 8,
        maxTier = 5,
        reeferBays = 1 :: 3 :: 5 :: Nil,
        maxStackWeightTonnes = 120.0
    }

    /// Checks if a yard slot is physically within block boundaries.
    pub def isSlotWithinBounds(slot: YardSlot, profile: BlockProfile): Bool = {
        slot#block == profile#blockId and
        slot#bay >= 1 and slot#bay <= profile#numBays and
        slot#row >= 1 and slot#row <= profile#numRows and
        slot#tier >= 1 and slot#tier <= profile#maxTier
    }

    /// Checks if a yard slot is currently occupied.
    pub def isOccupied(slot: YardSlot, containers: List[YardContainer]): Bool = {
        List.exists(c -> 
            c#slot#block == slot#block and
            c#slot#bay == slot#bay and
            c#slot#row == slot#row and
            c#slot#tier == slot#tier,
            containers
        )
    }

    /// Returns the top occupied tier in a given vertical yard column (block, bay, row).
    /// Returns 0 if the stack is completely empty.
    pub def stackTopTier(block: String, bay: Int32, row: Int32, containers: List[YardContainer]): Int32 = {
        let matching = List.filter(c -> c#slot#block == block and c#slot#bay == bay and c#slot#row == row, containers);
        List.foldLeft((acc, c) -> Int32.max(acc, c#slot#tier), 0, matching)
    }

    /// Computes the total weight in tonnes of a vertical yard column.
    pub def stackTotalWeight(block: String, bay: Int32, row: Int32, containers: List[YardContainer]): Float64 = {
        let matching = List.filter(c -> c#slot#block == block and c#slot#bay == bay and c#slot#row == row, containers);
        List.foldLeft((acc, c) -> acc + c#grossWeightTonnes, 0.0, matching)
    }

    /// Computes yard block capacity utilization percentage (0.0 to 100.0).
    pub def utilizationPercent(state: BlockState): Float64 = {
        let totalSlots = state#profile#numBays * state#profile#numRows * state#profile#maxTier;
        if (totalSlots == 0) 0.0
        else {
            let occupied = List.length(state#containers);
            (Int32.toFloat64(occupied) / Int32.toFloat64(totalSlots)) * 100.0
        }
    }
}
