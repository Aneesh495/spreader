// Spreader: Container Terminal Operating System
// ANSI Vessel Bay Cross-Section Console Renderer

pub mod Visualizer.AnsiBayCrossSection {

    use Visualizer.{colorize, fgRed, fgGreen, fgCyan, fgYellow, fgWhite, dim, bold}

    /// Renderable cell within a vessel bay cross-section.
    pub type alias RenderCell = {
        row = Int32,
        tier = Int32,
        containerId = String,
        isoType = String,
        grossWeightTonnes = Float64,
        isReefer = Bool,
        isHazmat = Bool,
        hazmatClass = Option[String]
    }

    /// Generates ANSI representation for an individual stowage cell.
    pub def formatCell(cellOpt: Option[RenderCell]): String = match cellOpt {
        case None => dim() + "[ . ]" + Visualizer.reset()
        case Some(c) =>
            if (c#isHazmat) colorize("[HAZ]", fgRed() + bold())
            else if (c#isReefer) colorize("[REF]", fgCyan() + bold())
            else colorize("[STD]", fgGreen())
    }

    /// Renders a horizontal row header listing transverse row indices.
    pub def formatRowHeader(rows: List[Int32]): String = {
        let cells = List.map(r -> {
            let rStr = if (r < 10) "0${r}" else "${r}";
            " ${rStr}  "
        }, rows);
        let header = List.foldLeft((acc, s) -> "${acc}${s}", "Tier ", cells);
        header + "\n"
    }

    /// Renders the hatch cover separation dividing on-deck from under-deck stowage.
    pub def formatDeckLine(rowCount: Int32): String = {
        let dashes = List.repeat(rowCount * 5 + 5, "=");
        let line = List.foldLeft((acc, s) -> "${acc}${s}", "", dashes);
        "--- " + line + " [DECK HATCH COVER]\n"
    }

    /// Renders a complete ANSI colored 2D cross-section for a given bay.
    pub def renderBay(bayNumber: Int32, rows: List[Int32], deckTiers: List[Int32], holdTiers: List[Int32], cells: List[RenderCell]): String = {
        let bStr = if (bayNumber < 10) "0${bayNumber}" else "${bayNumber}";
        let title = bold() + "=== VESSEL BAY ${bStr} TRANSVERSE CROSS-SECTION ===" + Visualizer.reset() + "\n";
        let rowHeader = formatRowHeader(rows);

        // Helper to render a tier row
        def renderTierRow(tier: Int32): String = {
            let tStr = if (tier < 10) "0${tier}" else "${tier}";
            let rowCells = List.map(r -> {
                let cellMatch = List.find(c -> c#row == r and c#tier == tier, cells);
                formatCell(cellMatch)
            }, rows);
            let rowContent = List.foldLeft((acc, s) -> "${acc}${s}", "${tStr}   ", rowCells);
            rowContent + "\n"
        };

        let deckRows = List.map(renderTierRow, deckTiers);
        let deckBlock = List.foldLeft((acc, s) -> "${acc}${s}", "", deckRows);

        let hatchCover = formatDeckLine(List.length(rows));

        let holdRows = List.map(renderTierRow, holdTiers);
        let holdBlock = List.foldLeft((acc, s) -> "${acc}${s}", "", holdRows);

        title + rowHeader + deckBlock + hatchCover + holdBlock + rowHeader
    }
}
