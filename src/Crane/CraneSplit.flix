// Spreader: Container Terminal Operating System
// Multi-Quay-Crane Vessel Bay Split and Workload Balancing Optimizer

pub mod Crane.CraneSplit {

    /// Bay workload demand entry.
    pub type alias BayWorkload = {
        bay = Int32,
        movesCount = Int32
    }

    /// Assignment of a continuous range of vessel bays to a single quay crane.
    pub type alias CraneBayAssignment = {
        craneId = String,
        startBay = Int32,
        endBay = Int32,
        totalMoves = Int32,
        estimatedHours = Float64
    }

    /// Complete vessel gang assignment plan.
    pub type alias VesselCranePlan = {
        assignments = List[CraneBayAssignment],
        makespanHours = Float64, // Time when the bottleneck crane finishes
        imbalanceRatio = Float64 // (maxMoves - minMoves) / avgMoves
    }

    /// Standard single quay crane gross moves per hour (GMPH).
    pub def standardCraneGmph(): Float64 = 30.0

    /// Partitions a sorted list of bay workloads across K cranes to minimize makespan.
    pub def balanceCraneBays(
        craneIds: List[String],
        bayWorkloads: List[BayWorkload]
    ): VesselCranePlan = {
        let numCranes = List.length(craneIds);
        let totalMoves = List.foldLeft((acc, bw) -> acc + bw#movesCount, 0, bayWorkloads);

        if (numCranes <= 0 or List.isEmpty(bayWorkloads)) {
            { assignments = Nil, makespanHours = 0.0, imbalanceRatio = 0.0 }
        } else {
            let targetMovesPerCrane = Int32.toFloat64(totalMoves) / Int32.toFloat64(numCranes);

            // Greedy contiguous partitioning
            def partition(cIds: List[String], remBays: List[BayWorkload], acc: List[CraneBayAssignment]): List[CraneBayAssignment] = {
                match cIds {
                    case Nil => List.reverse(acc)
                    case cId :: Nil => {
                        // Last crane takes all remaining bays
                        let cMoves = List.foldLeft((sum, b) -> sum + b#movesCount, 0, remBays);
                        let sBay = match List.head(remBays) { case Some(b) => b#bay case None => 0 };
                        let eBay = match List.last(remBays) { case Some(b) => b#bay case None => 0 };
                        let assign: CraneBayAssignment = {
                            craneId = cId,
                            startBay = sBay,
                            endBay = eBay,
                            totalMoves = cMoves,
                            estimatedHours = Int32.toFloat64(cMoves) / standardCraneGmph()
                        };
                        List.reverse(assign :: acc)
                    }
                    case cId :: cRest => {
                        // Accumulate bays until reaching approx targetMovesPerCrane
                        def collectBays(bays: List[BayWorkload], curMoves: Int32, curAcc: List[BayWorkload]): (List[BayWorkload], List[BayWorkload]) = {
                            match bays {
                                case Nil => (List.reverse(curAcc), Nil)
                                case b :: bRest => {
                                    let newMoves = curMoves + b#movesCount;
                                    // If taking this bay exceeds target and we already have some bays, stop
                                    if (Int32.toFloat64(newMoves) > targetMovesPerCrane and not List.isEmpty(curAcc))
                                        (List.reverse(curAcc), bays)
                                    else
                                        collectBays(bRest, newMoves, b :: curAcc)
                                }
                            }
                        };

                        let (assigned, unassigned) = collectBays(remBays, 0, Nil);
                        let cMoves = List.foldLeft((sum, b) -> sum + b#movesCount, 0, assigned);
                        let sBay = match List.head(assigned) { case Some(b) => b#bay case None => 0 };
                        let eBay = match List.last(assigned) { case Some(b) => b#bay case None => 0 };
                        let assign: CraneBayAssignment = {
                            craneId = cId,
                            startBay = sBay,
                            endBay = eBay,
                            totalMoves = cMoves,
                            estimatedHours = Int32.toFloat64(cMoves) / standardCraneGmph()
                        };
                        partition(cRest, unassigned, assign :: acc)
                    }
                }
            };

            let assignments = partition(craneIds, bayWorkloads, Nil);
            let maxHours = List.foldLeft((acc, a) -> Float64.max(acc, a#estimatedHours), 0.0, assignments);
            let minMoves = List.foldLeft((acc, a) -> Int32.min(acc, a#totalMoves), 999999, assignments);
            let maxMoves = List.foldLeft((acc, a) -> Int32.max(acc, a#totalMoves), 0, assignments);

            let avgMoves = targetMovesPerCrane;
            let imbalance = if (avgMoves <= 0.0) 0.0 else Int32.toFloat64(maxMoves - minMoves) / avgMoves;

            {
                assignments = assignments,
                makespanHours = maxHours,
                imbalanceRatio = imbalance
            }
        }
    }
}
