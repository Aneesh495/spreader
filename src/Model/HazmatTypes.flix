// Spreader: Container Terminal Operating System
// IMO IMDG Code Classification and Segregation Definitions

pub mod Model.HazmatTypes {

    /// IMDG Code primary hazard class.
    pub enum ImdgClass with Eq, Order, ToString {
        case Class1_1, // Explosives with mass explosion hazard
        case Class1_2, // Explosives with projection hazard but not mass explosion
        case Class1_3, // Explosives with fire hazard and minor blast/projection
        case Class1_4, // Explosives with no significant blast hazard
        case Class1_5, // Very insensitive substances with mass explosion hazard
        case Class1_6, // Extremely insensitive articles without mass explosion
        case Class2_1, // Flammable gases
        case Class2_2, // Non-flammable, non-toxic gases
        case Class2_3, // Toxic gases
        case Class3,   // Flammable liquids
        case Class4_1, // Flammable solids, self-reactive substances
        case Class4_2, // Substances liable to spontaneous combustion
        case Class4_3, // Substances which in contact with water emit flammable gases
        case Class5_1, // Oxidizing substances
        case Class5_2, // Organic peroxides
        case Class6_1, // Toxic substances
        case Class6_2, // Infectious substances
        case Class7,   // Radioactive material
        case Class8,   // Corrosive substances
        case Class9    // Miscellaneous dangerous substances and lithium batteries
    }

    /// Packing group indicating degree of danger.
    pub enum PackingGroup with Eq, Order, ToString {
        case PackingGroupI,   // High danger
        case PackingGroupII,  // Medium danger
        case PackingGroupIII  // Low danger
    }

    /// Explosives compatibility group (IMDG 7.2.7.2).
    pub enum CompatibilityGroup with Eq, Order, ToString {
        case GroupA,
        case GroupB,
        case GroupC,
        case GroupD,
        case GroupE,
        case GroupF,
        case GroupG,
        case GroupH,
        case GroupJ,
        case GroupK,
        case GroupL,
        case GroupN,
        case GroupS
    }

    /// Segregation category requirement between two incompatible dangerous goods classes.
    /// Defined by IMDG Code Table 7.2.4.
    pub enum SegregationCategory with Eq, Order, ToString {
        case NoneRequired,
        case AwayFrom,                             // Category 1: Min 3m horizontal (1 container bay/row)
        case SeparatedFrom,                        // Category 2: Min 6m horizontal (2 container bays/rows)
        case SeparatedByCompleteCompartment,       // Category 3: Complete compartment or steel bulkhead
        case SeparatedLongitudinallyByIntervening  // Category 4: Longitudinal separation by intervening hold
    }

    /// Hazardous cargo declaration attached to a container.
    pub type alias HazmatDeclaration = {
        unNumber = Int32,                      // UN 4-digit code (e.g. 1942 for ammonium nitrate)
        primaryClass = ImdgClass,              // Primary hazard class
        subsidiaryClasses = List[ImdgClass],   // Secondary hazard risks
        packingGroup = Option[PackingGroup],   // Degree of danger
        flashPointCelsius = Option[Float64],   // Liquid flashpoint (relevant for Class 3)
        marinePollutant = Bool,                // Marine environmental toxin
        limitedQuantity = Bool                 // Exempt from certain segregation rules
    }

    /// Checks if the hazard class is any form of Class 1 explosive.
    pub def isExplosive(c: ImdgClass): Bool = match c {
        case ImdgClass.Class1_1 => true
        case ImdgClass.Class1_2 => true
        case ImdgClass.Class1_3 => true
        case ImdgClass.Class1_4 => true
        case ImdgClass.Class1_5 => true
        case ImdgClass.Class1_6 => true
        case _                  => false
    }

    /// Checks if the hazard class is a flammable gas or liquid.
    pub def isFlammable(c: ImdgClass): Bool = match c {
        case ImdgClass.Class2_1 => true
        case ImdgClass.Class3   => true
        case ImdgClass.Class4_1 => true
        case _                  => false
    }

    /// Checks if the hazard class is an organic peroxide or self-reactive substance.
    pub def isTemperatureSensitive(c: ImdgClass): Bool = match c {
        case ImdgClass.Class5_2 => true
        case ImdgClass.Class4_1 => true
        case _                  => false
    }

    /// Returns human-readable label for IMDG class.
    pub def classLabel(c: ImdgClass): String = match c {
        case ImdgClass.Class1_1 => "1.1 (Mass Explosion)"
        case ImdgClass.Class1_2 => "1.2 (Projection Hazard)"
        case ImdgClass.Class1_3 => "1.3 (Minor Blast)"
        case ImdgClass.Class1_4 => "1.4 (No Significant Hazard)"
        case ImdgClass.Class1_5 => "1.5 (Very Insensitive Explosive)"
        case ImdgClass.Class1_6 => "1.6 (Extremely Insensitive Article)"
        case ImdgClass.Class2_1 => "2.1 (Flammable Gas)"
        case ImdgClass.Class2_2 => "2.2 (Non-flammable Gas)"
        case ImdgClass.Class2_3 => "2.3 (Toxic Gas)"
        case ImdgClass.Class3   => "3 (Flammable Liquid)"
        case ImdgClass.Class4_1 => "4.1 (Flammable Solid)"
        case ImdgClass.Class4_2 => "4.2 (Spontaneously Combustible)"
        case ImdgClass.Class4_3 => "4.3 (Dangerous When Wet)"
        case ImdgClass.Class5_1 => "5.1 (Oxidizing Substance)"
        case ImdgClass.Class5_2 => "5.2 (Organic Peroxide)"
        case ImdgClass.Class6_1 => "6.1 (Toxic Substance)"
        case ImdgClass.Class6_2 => "6.2 (Infectious Substance)"
        case ImdgClass.Class7   => "7 (Radioactive Material)"
        case ImdgClass.Class8   => "8 (Corrosive Substance)"
        case ImdgClass.Class9   => "9 (Miscellaneous / Li-Ion)"
    }
}
