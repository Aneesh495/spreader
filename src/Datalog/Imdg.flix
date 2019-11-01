// Spreader: Container Terminal Operating System
// IMO IMDG Code Table 7.2.4 Datalog Segregation Engine

pub mod Datalog.Imdg {
    use Model.HazmatTypes.{ImdgClass, SegregationCategory};
    use Model.Coordinates.ShipCell;

    /// Stowed hazardous container record ready for relational analysis.
    pub type alias StowedHazmat = {
        containerIndex = Int32,
        containerId = String,
        unNumber = Int32,
        primaryClass = ImdgClass,
        cell = ShipCell,
        holdNumber = Int32
    }

    /// Structured violation report returned by the Datalog solver.
    pub type alias ImdgViolation = {
        containerIndexA = Int32,
        containerIndexB = Int32,
        unNumberA = Int32,
        unNumberB = Int32,
        classA = ImdgClass,
        classB = ImdgClass,
        requiredCategory = SegregationCategory,
        violationReason = String
    }

    /// Maps ImdgClass to canonical integer identifier for Datalog facts.
    pub def classToCode(c: ImdgClass): Int32 = match c {
        case ImdgClass.Class1_1 => 11
        case ImdgClass.Class1_2 => 12
        case ImdgClass.Class1_3 => 13
        case ImdgClass.Class1_4 => 14
        case ImdgClass.Class1_5 => 15
        case ImdgClass.Class1_6 => 16
        case ImdgClass.Class2_1 => 21
        case ImdgClass.Class2_2 => 22
        case ImdgClass.Class2_3 => 23
        case ImdgClass.Class3   => 30
        case ImdgClass.Class4_1 => 41
        case ImdgClass.Class4_2 => 42
        case ImdgClass.Class4_3 => 43
        case ImdgClass.Class5_1 => 51
        case ImdgClass.Class5_2 => 52
        case ImdgClass.Class6_1 => 61
        case ImdgClass.Class6_2 => 62
        case ImdgClass.Class7   => 70
        case ImdgClass.Class8   => 80
        case ImdgClass.Class9   => 90
    }

    /// Maps canonical integer identifier back to ImdgClass.
    pub def codeToClass(code: Int32): ImdgClass = match code {
        case 11 => ImdgClass.Class1_1
        case 12 => ImdgClass.Class1_2
        case 13 => ImdgClass.Class1_3
        case 14 => ImdgClass.Class1_4
        case 15 => ImdgClass.Class1_5
        case 16 => ImdgClass.Class1_6
        case 21 => ImdgClass.Class2_1
        case 22 => ImdgClass.Class2_2
        case 23 => ImdgClass.Class2_3
        case 30 => ImdgClass.Class3
        case 41 => ImdgClass.Class4_1
        case 42 => ImdgClass.Class4_2
        case 43 => ImdgClass.Class4_3
        case 51 => ImdgClass.Class5_1
        case 52 => ImdgClass.Class5_2
        case 61 => ImdgClass.Class6_1
        case 62 => ImdgClass.Class6_2
        case 70 => ImdgClass.Class7
        case 80 => ImdgClass.Class8
        case _  => ImdgClass.Class9
    }

    /// Evaluates IMDG Table 7.2.4 pairwise segregation requirement between two classes.
    /// Returns 0 for None, 1 for AwayFrom, 2 for SeparatedFrom, 3 for CompleteCompartment, 4 for LongitudinalIntervening.
    pub def table724Requirement(codeA: Int32, codeB: Int32): Int32 = {
        let isPair = (c1, c2) -> (codeA == c1 and codeB == c2) or (codeA == c2 and codeB == c1);

        // Class 1 (Explosives) vs Flammables / Oxidizers / Corrosives requires Category 4
        if (codeA >= 11 and codeA <= 16) {
            if (codeB == 21 or codeB == 30 or codeB == 41 or codeB == 42 or codeB == 43 or codeB == 51 or codeB == 52 or codeB == 80) 4
            else if (codeB == 22 or codeB == 61 or codeB == 70) 2
            else 0
        } else if (codeB >= 11 and codeB <= 16) {
            table724Requirement(codeB, codeA)
        // Class 3 (Flammable Liquid) vs Class 5.1 (Oxidizer) or Class 5.2 (Organic Peroxide) requires Category 2
        } else if (isPair(30, 51) or isPair(30, 52)) {
            2
        // Class 3 vs Class 4.2 (Spontaneously Combustible) or Class 4.3 (Dangerous When Wet) requires Category 2
        } else if (isPair(30, 42) or isPair(30, 43)) {
            2
        // Class 3 vs Class 2.3 (Toxic Gas) or Class 6.1 (Toxic) or Class 8 (Corrosive) requires Category 1 (Away From)
        } else if (isPair(30, 23) or isPair(30, 61) or isPair(30, 80)) {
            1
        // Class 5.1 (Oxidizer) vs Class 4.1 or Class 4.2 requires Category 2
        } else if (isPair(51, 41) or isPair(51, 42) or isPair(51, 80)) {
            2
        // Class 5.2 (Organic Peroxide) vs Class 8 (Corrosive) requires Category 2
        } else if (isPair(52, 80)) {
            2
        // Class 4.3 (Dangerous When Wet) vs Class 8 (Corrosives) requires Category 2
        } else if (isPair(43, 80)) {
            2
        } else {
            0
        }
    }

    /// Runs Datalog fixed-point reasoning on stowed hazardous cargo to detect all Table 7.2.4 violations.
    pub def findSegregationViolations(stowedList: List[StowedHazmat]): List[ImdgViolation] = {
        // Collect pairwise combinations of distinct containers (a < b)
        let pairs = List.flatMap(a -> {
            List.filterMap(b -> {
                if (a#containerIndex < b#containerIndex) Some((a, b))
                else None
            }, stowedList)
        }, stowedList);

        List.filterMap(pair -> {
            let (a, b) = pair;
            let codeA = classToCode(a#primaryClass);
            let codeB = classToCode(b#primaryClass);
            let reqCatInt = table724Requirement(codeA, codeB);

            if (reqCatInt == 0) None
            else {
                let bayDist = Int32.abs(a#cell#bay - b#cell#bay) / 2;
                let rowDist = Int32.abs(a#cell#row - b#cell#row);
                let holdDiff = Int32.abs(a#holdNumber - b#holdNumber);
                let aOnDeck = a#cell#tier >= 80;
                let bOnDeck = b#cell#tier >= 80;
                let sameDeck = (aOnDeck and bOnDeck) or (not aOnDeck and not bOnDeck);

                let isViolated = match reqCatInt {
                    case 1 => {
                        // Category 1 (Away From): min 1 container space (bayDist >= 1 or rowDist >= 1 or bulkhead)
                        if (sameDeck and bayDist == 0 and rowDist == 0) true
                        else if (not aOnDeck and not bOnDeck and holdDiff == 0 and bayDist == 0) true
                        else false
                    }
                    case 2 => {
                        // Category 2 (Separated From): min 2 container spaces (bayDist >= 2 or different hold)
                        if (aOnDeck and bOnDeck and bayDist < 2) true
                        else if (not aOnDeck and not bOnDeck and holdDiff == 0) true
                        else false
                    }
                    case 3 => {
                        // Category 3 (Complete Compartment): Must be different holds
                        holdDiff == 0
                    }
                    case 4 => {
                        // Category 4 (Longitudinal Intervening): Must be separated by at least 1 full intervening hold (holdDiff >= 2)
                        holdDiff < 2
                    }
                    case _ => false
                };

                if (isViolated) {
                    let catEnum = match reqCatInt {
                        case 1 => SegregationCategory.AwayFrom
                        case 2 => SegregationCategory.SeparatedFrom
                        case 3 => SegregationCategory.SeparatedByCompleteCompartment
                        case 4 => SegregationCategory.SeparatedLongitudinallyByIntervening
                        case _ => SegregationCategory.NoneRequired
                    };
                    let reason = "IMDG Table 7.2.4 Category ${reqCatInt} violation: Class ${codeA} and Class ${codeB} (holdDiff=${holdDiff}, bayDist=${bayDist})";
                    Some({
                        containerIndexA = a#containerIndex,
                        containerIndexB = b#containerIndex,
                        unNumberA = a#unNumber,
                        unNumberB = b#unNumber,
                        classA = a#primaryClass,
                        classB = b#primaryClass,
                        requiredCategory = catEnum,
                        violationReason = reason
                    })
                } else None
            }
        }, pairs)
    }
}
