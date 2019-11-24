// Spreader: Container Terminal Operating System
// Container Relocation Problem (CRP): Reshuffle Minimization and Extraction Sequencing

pub mod Yard.Reshuffle {
    use Yard.YardBlock.YardContainer;

    /// A crane relocation move transferring a blocking container to a temporary stack.
    pub type alias RelocationMove = {
        containerId = String,
        fromRow = Int32,
        fromTier = Int32,
        toRow = Int32,
        toTier = Int32
    }

    /// Full extraction plan for retrieving a target container from a yard bay.
    pub type alias ExtractionPlan = {
        targetContainerId = String,
        relocations = List[RelocationMove],
        totalReshuffleMoves = Int32
    }

    /// Finds all containers in a column that are physically stacked above the target container.
    pub def findBlockingContainers(
        targetId: String,
        bayContainers: List[YardContainer]
    ): List[YardContainer] = {
        match List.find(c -> c#containerId == targetId, bayContainers) {
            case Some(target) => {
                let sameColumn = List.filter(c -> 
                    c#slot#block == target#slot#block and
                    c#slot#bay == target#slot#bay and
                    c#slot#row == target#slot#row and
                    c#slot#tier > target#slot#tier,
                    bayContainers
                );
                // Sort descending by tier (topmost first)
                List.sortBy(c -> -c#slot#tier, sameColumn)
            }
            case None => Nil
        }
    }

    /// Counts how many unproductive reshuffle moves are required to access a target container.
    pub def countBlockingContainers(targetId: String, bayContainers: List[YardContainer]): Int32 = {
        List.length(findBlockingContainers(targetId, bayContainers))
    }

    /// Selects the best candidate destination row in the same bay for a relocated container
    /// using the Min-Max heuristic (avoid placing on top of a container that must be retrieved earlier).
    pub def selectDestinationRow(
        item: YardContainer,
        sourceRow: Int32,
        availableRows: List[Int32],
        maxTier: Int32,
        bayContainers: List[YardContainer]
    ): Option[Int32] = {
        // Filter out source row
        let candidates = List.filter(r -> r != sourceRow, availableRows);

        // Find candidate rows that have remaining tier capacity (< maxTier)
        let viableRows = List.filter(r -> {
            let rowItems = List.filter(c -> c#slot#row == r, bayContainers);
            let topTier = List.foldLeft((acc, c) -> Int32.max(acc, c#slot#tier), 0, rowItems);
            topTier < maxTier
        }, candidates);

        // Rank viable rows: Prefer stack whose top container has pickupOrder > item#pickupOrder
        // (meaning the top container will be retrieved AFTER the relocated container, causing 0 new blocks)
        let scored = List.map(r -> {
            let rowItems = List.filter(c -> c#slot#row == r, bayContainers);
            let topTier = List.foldLeft((acc, c) -> Int32.max(acc, c#slot#tier), 0, rowItems);
            let topOrder = match List.find(c -> c#slot#tier == topTier, rowItems) {
                case Some(topC) => topC#pickupOrder
                case None => 999999 // Empty stack is great
            };
            // Score: higher is better
            let score = if (topOrder >= item#pickupOrder) 1000 + topOrder else topOrder;
            (r, score)
        }, viableRows);

        // Pick row with highest score
        let best = List.foldLeft((acc, pair) -> match (acc, pair) {
            case (None, (r, s)) => Some((r, s))
            case (Some((bestR, bestS)), (r, s)) =>
                if (s > bestS) Some((r, s)) else Some((bestR, bestS))
        }, None, scored);

        Option.map(pair -> match pair { case (r, _) => r }, best)
    }

    /// Computes full extraction plan for a buried container.
    pub def planExtraction(
        targetId: String,
        numRows: Int32,
        maxTier: Int32,
        bayContainers: List[YardContainer]
    ): ExtractionPlan = {
        let blocking = findBlockingContainers(targetId, bayContainers);
        let availableRows = List.range(1, numRows + 1);

        def relocateLoop(xs: List[YardContainer], curBayState: List[YardContainer], accMoves: List[RelocationMove]): List[RelocationMove] = {
            match xs {
                case Nil => List.reverse(accMoves)
                case c :: rest => {
                    let destRowOpt = selectDestinationRow(c, c#slot#row, availableRows, maxTier, curBayState);
                    match destRowOpt {
                        case Some(destRow) => {
                            let destRowItems = List.filter(it -> it#slot#row == destRow, curBayState);
                            let destTopTier = List.foldLeft((acc, it) -> Int32.max(acc, it#slot#tier), 0, destRowItems);
                            let newTier = destTopTier + 1;

                            let move: RelocationMove = {
                                containerId = c#containerId,
                                fromRow = c#slot#row,
                                fromTier = c#slot#tier,
                                toRow = destRow,
                                toTier = newTier
                            };

                            let updatedContainer = { slot = { block = c#slot#block, bay = c#slot#bay, row = destRow, tier = newTier } | c };
                            let updatedBayState = updatedContainer :: List.filter(it -> it#containerId != c#containerId, curBayState);

                            relocateLoop(rest, updatedBayState, move :: accMoves)
                        }
                        case None => List.reverse(accMoves) // Blocked by full bay
                    }
                }
            }
        };

        let moves = relocateLoop(blocking, bayContainers, Nil);
        {
            targetContainerId = targetId,
            relocations = moves,
            totalReshuffleMoves = List.length(moves)
        }
    }
}
