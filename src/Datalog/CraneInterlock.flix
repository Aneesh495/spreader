// Spreader: Container Terminal Operating System
// Crane Collision Avoidance and Rail Safety Interlocks

pub mod Datalog.CraneInterlock {

    /// Quay Crane position and assigned operational envelope.
    pub type alias QuayCranePosition = {
        craneId = String,
        currentBay = Int32,
        boomDown = Bool
    }

    /// Automated Stacking Crane position on block rails.
    pub type alias AscPosition = {
        blockId = String,
        craneId = String,
        currentBay = Int32
    }

    /// Detected quay crane safety interlock violation.
    pub type alias QuayCraneViolation = {
        craneIdA = String,
        craneIdB = String,
        bayA = Int32,
        bayB = Int32,
        actualSeparationBays = Int32,
        requiredMinSeparationBays = Int32,
        reason = String
    }

    /// Detected yard crane safety interlock violation.
    pub type alias AscViolation = {
        blockId = String,
        craneIdA = String,
        craneIdB = String,
        bayA = Int32,
        bayB = Int32,
        actualSeparationBays = Int32,
        reason = String
    }

    /// Checks Quay Crane rail safety clearance along the wharf.
    /// QCs share a linear rail track. Cranes ordered by ID must maintain spatial ordering
    /// and a minimum clearance of at least minClearanceBays (typically 2 bays).
    pub def checkQuayCraneInterlocks(cranes: List[QuayCranePosition], minClearanceBays: Int32): List[QuayCraneViolation] = {
        let pairs = List.flatMap(c1 -> {
            List.filterMap(c2 -> {
                if (c1#craneId < c2#craneId) Some((c1, c2))
                else None
            }, cranes)
        }, cranes);

        List.filterMap(pair -> {
            let (c1, c2) = pair;
            let sep = Int32.abs(c1#currentBay - c2#currentBay);
            // Rail collision rule: If both booms are lowered and separation < minClearanceBays
            if (c1#boomDown and c2#boomDown and sep < minClearanceBays) {
                Some({
                    craneIdA = c1#craneId,
                    craneIdB = c2#craneId,
                    bayA = c1#currentBay,
                    bayB = c2#currentBay,
                    actualSeparationBays = sep,
                    requiredMinSeparationBays = minClearanceBays,
                    reason = "Quay cranes ${c1#craneId} and ${c2#craneId} violate rail clearance buffer (${sep} < ${minClearanceBays} bays)"
                })
            } else None
        }, pairs)
    }

    /// Checks Automated Stacking Crane safety buffers within yard blocks.
    /// Two ASCs sharing the same block rails must maintain at least minBufferBays (typically 3 bays).
    pub def checkAscInterlocks(ascs: List[AscPosition], minBufferBays: Int32): List[AscViolation] = {
        let pairs = List.flatMap(a1 -> {
            List.filterMap(a2 -> {
                if (a1#blockId == a2#blockId and a1#craneId < a2#craneId) Some((a1, a2))
                else None
            }, ascs)
        }, ascs);

        List.filterMap(pair -> {
            let (a1, a2) = pair;
            let sep = Int32.abs(a1#currentBay - a2#currentBay);
            if (sep < minBufferBays) {
                Some({
                    blockId = a1#blockId,
                    craneIdA = a1#craneId,
                    craneIdB = a2#craneId,
                    bayA = a1#currentBay,
                    bayB = a2#currentBay,
                    actualSeparationBays = sep,
                    reason = "ASC collision hazard in Block ${a1#blockId}: ${a1#craneId} (bay ${a1#currentBay}) and ${a2#craneId} (bay ${a2#currentBay}) buffer violation (${sep} < ${minBufferBays} bays)"
                })
            } else None
        }, pairs)
    }
}
