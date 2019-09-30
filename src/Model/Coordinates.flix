// Spreader: Container Terminal Operating System
// ISO 9711 Bay-Row-Tier (B-R-T) Vessel Stowage Coordinate Mathematics

pub mod Model.Coordinates {

    /// Ship stowage location in standard ISO 9711 Bay-Row-Tier format.
    pub type alias ShipCell = {
        bay = Int32,   // Odd for 20ft, Even for 40ft
        row = Int32,   // 00=centerline, Odd=Starboard, Even=Port
        tier = Int32   // 02..78=In-hold, 82..98=On-deck
    }

    /// Deck placement location classification.
    pub enum DeckLevel with Eq, Order, ToString {
        case UnderdeckInHold(Int32), // Hold compartment index (1..N)
        case OndeckWeatherDeck
    }

    /// Checks if a cell is located below deck (in-hold).
    pub def isUnderdeck(cell: ShipCell): Bool =
        cell#tier < 80

    /// Checks if a cell is located on the weather deck.
    pub def isOndeck(cell: ShipCell): Bool =
        cell#tier >= 80

    /// Checks if the cell represents a 20ft container position (odd bay).
    pub def isTwentyFootBay(bay: Int32): Bool =
        Int32.modulo(bay, 2) == 1

    /// Checks if the cell represents a 40ft container position (even bay).
    pub def isFortyFootBay(bay: Int32): Bool =
        Int32.modulo(bay, 2) == 0

    /// Returns the constituent 20ft forward and aft bays for a 40ft bay.
    /// E.g. Bay 02 spans Bay 01 (fwd) and Bay 03 (aft).
    pub def constituentTwentyFootBays(bay40: Int32): (Int32, Int32) =
        (bay40 - 1, bay40 + 1)

    /// Returns the encompassing 40ft bay for an odd 20ft bay, assuming paired coupling.
    /// Forward odd bay (e.g. 01) maps to 02; aft odd bay (e.g. 03) maps to 02.
    pub def encompassingFortyFootBay(bay20: Int32): Int32 = {
        let rem4 = Int32.modulo(bay20, 4);
        if (rem4 == 1) bay20 + 1
        else bay20 - 1
    }

    /// Determines if two bay indices overlap longitudinally in space.
    /// A 40ft bay (even) overlaps with its two adjacent odd 20ft bays and itself.
    pub def baysOverlap(bayA: Int32, bayB: Int32): Bool = {
        if (bayA == bayB) true
        else if (isFortyFootBay(bayA) and isTwentyFootBay(bayB)) {
            let (fwd, aft) = constituentTwentyFootBays(bayA);
            bayB == fwd or bayB == aft
        } else if (isTwentyFootBay(bayA) and isFortyFootBay(bayB)) {
            let (fwd, aft) = constituentTwentyFootBays(bayB);
            bayA == fwd or bayA == aft
        } else false
    }

    /// Calculates transverse offset from centerline in row units.
    /// Row 00 = 0.0, Row 01 (starboard) = +1.0, Row 03 = +2.0, Row 05 = +3.0.
    /// Row 02 (port) = -1.0, Row 04 = -2.0, Row 06 = -3.0.
    pub def rowTransverseOffset(row: Int32): Float64 = {
        if (row == 0) 0.0
        else if (Int32.modulo(row, 2) == 1) {
            // Starboard: row 1 -> 1, row 3 -> 2, row 5 -> 3
            Int32.toFloat64((row + 1) / 2)
        } else {
            // Port: row 2 -> -1, row 4 -> -2, row 6 -> -3
            Int32.toFloat64(-(row / 2))
        }
    }

    /// Computes physical transverse distance between two rows in container-width units (approx 2.44m).
    pub def rowDistance(rowA: Int32, rowB: Int32): Float64 = {
        let offsetA = rowTransverseOffset(rowA);
        let offsetB = rowTransverseOffset(rowB);
        Float64.abs(offsetA - offsetB)
    }

    /// Computes longitudinal bay distance in 20ft-unit increments (approx 6.1m).
    pub def bayDistance(bayA: Int32, bayB: Int32): Int32 = {
        let normA = if (isFortyFootBay(bayA)) bayA else bayA;
        let normB = if (isFortyFootBay(bayB)) bayB else bayB;
        Int32.abs(normA - normB) / 2
    }

    /// Computes vertical tier distance in container tiers.
    pub def tierDistance(tierA: Int32, tierB: Int32): Int32 =
        Int32.abs(tierA - tierB) / 2

    /// Validates whether a cell address is structurally well-formed according to ISO 9711.
    pub def isValidCellAddress(cell: ShipCell): Bool = {
        let validBay = cell#bay >= 1 and cell#bay <= 99;
        let validRow = cell#row >= 0 and cell#row <= 32;
        let validTier = (cell#tier >= 2 and cell#tier <= 78 and Int32.modulo(cell#tier, 2) == 0) or
                        (cell#tier >= 82 and cell#tier <= 98 and Int32.modulo(cell#tier, 2) == 0);
        validBay and validRow and validTier
    }

    /// Formats a cell coordinate into standard 6-character or 7-character ISO 9711 string.
    /// E.g. bay 03, row 02, tier 84 -> "030284".
    pub def formatCell(cell: ShipCell): String = {
        let pad2 = n -> if (n < 10) "0${n}" else "${n}";
        "${pad2(cell#bay)}${pad2(cell#row)}${pad2(cell#tier)}"
    }
}
