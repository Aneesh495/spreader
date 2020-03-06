// Spreader: Container Terminal Operating System
// Top-Down ASCII Automated Stacking Crane (ASC) Yard Block Map Renderer

pub mod Visualizer.YardAsciiMap {

    use Visualizer.{colorize, fgCyan, fgYellow, fgGreen, fgWhite, bold, dim}

    /// Telemetry position of an ASC crane spanning across the yard block rail.
    pub type alias AscMapPosition = {
        craneId = String,
        bayPosition = Int32,
        isHoisting = Bool
    }

    /// Snapshot summary of an automated container yard block.
    pub type alias YardBlockMapData = {
        blockId = String,
        totalBays = Int32,
        maxTier = Int32,
        bayHeights = List[(Int32, Int32)], // (bayNumber, currentStackHeight)
        cranes = List[AscMapPosition],
        watersideVehicles = List[String],
        landsideVehicles = List[String]
    }

    /// Formats a vertical stack height indicator [0] to [5].
    pub def formatHeightBadge(height: Int32, maxTier: Int32): String = {
        if (height <= 0) dim() + "[ . ]" + Visualizer.reset()
        else if (height >= maxTier) colorize("[${height}]", fgYellow() + bold())
        else colorize("[${height}]", fgGreen())
    }

    /// Renders a top-down ASCII visualization of an automated yard block.
    pub def renderYardBlock(data: YardBlockMapData): String = {
        let border = "+-------------------------------------------------------------------------------+\n";
        let title = "| YARD BLOCK ${data#blockId} - AUTOMATED ASC STORAGE MATRIX                         |\n";

        // Waterside AGV exchange zone
        let wsVehicles = if (List.isEmpty(data#watersideVehicles)) "NONE" else String.intercalate(", ", data#watersideVehicles);
        let wsZone = "| [WATERSIDE AGV ZONE] Buffer Queue: ${wsVehicles}\n";

        // Bay header numbers
        let bays = List.map(fst, data#bayHeights);
        let bayHeaderRow = List.foldLeft((acc, b) -> {
            let bStr = if (b < 10) "0${b}" else "${b}";
            "${acc} ${bStr} "
        }, "| Bay:   ", bays) + "\n";

        // Waterside ASC crane track
        let wsCraneOpt = List.find(c -> String.contains(substr = "W", c#craneId), data#cranes);
        let wsCraneRow = List.foldLeft((acc, b) -> {
            match wsCraneOpt {
                case Some(c) => if (c#bayPosition == b) "${acc}[ASC]" else "${acc} === "
                case None => "${acc} === "
            }
        }, "| ASC-W: ", bays) + "\n";

        // Container stack heights
        let stackRow = List.foldLeft((acc, pair) -> {
            let (_, h) = pair;
            "${acc}${formatHeightBadge(h, data#maxTier)}"
        }, "| Stack: ", data#bayHeights) + "\n";

        // Landside ASC crane track
        let lsCraneOpt = List.find(c -> String.contains(substr = "L", c#craneId), data#cranes);
        let lsCraneRow = List.foldLeft((acc, b) -> {
            match lsCraneOpt {
                case Some(c) => if (c#bayPosition == b) "${acc}[ASC]" else "${acc} === "
                case None => "${acc} === "
            }
        }, "| ASC-L: ", bays) + "\n";

        // Landside external truck exchange zone
        let lsVehicles = if (List.isEmpty(data#landsideVehicles)) "NONE" else String.intercalate(", ", data#landsideVehicles);
        let lsZone = "| [LANDSIDE TRUCK ZONE] Gate Lane: ${lsVehicles}\n";

        border + title + border + wsZone + bayHeaderRow + wsCraneRow + stackRow + lsCraneRow + lsZone + border
    }
}
