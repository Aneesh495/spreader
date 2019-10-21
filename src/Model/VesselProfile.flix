// Spreader: Container Terminal Operating System
// Container Vessel Particulars, Hydrostatic Tables, and Tank Geometries

pub mod Model.VesselProfile {

    /// Ballast tank identifier on container vessels.
    pub enum BallastTank with Eq, Order, ToString {
        case Forepeak,
        case Aftpeak,
        case DoubleBottomPort(Int32),   // DB tank 1..6 Port
        case DoubleBottomStarboard(Int32), // DB tank 1..6 Starboard
        case WingTankPort(Int32),       // Heeling anti-roll tank Port
        case WingTankStarboard(Int32)   // Heeling anti-roll tank Starboard
    }

    /// Ballast tank state record with capacity and free surface inertia.
    pub type alias TankState = {
        tankId = BallastTank,
        capacityTonnes = Float64,       // Max water capacity in metric tonnes
        currentWeightTonnes = Float64,  // Current water level in tonnes
        lcgMeters = Float64,            // Longitudinal center of gravity from midship (m)
        tcgMeters = Float64,            // Transverse center of gravity from centerline (m)
        vcgMeters = Float64,            // Vertical center of gravity from keel (m)
        freeSurfaceMoment = Float64     // Free surface moment of inertia (t*m) when slack
    }

    /// Cargo hold compartment boundary record.
    pub type alias CargoHold = {
        holdNumber = Int32,   // Hold index (1..8)
        startBay = Int32,     // Forward bay boundary
        endBay = Int32,       // Aft bay boundary
        lengthMeters = Float64,
        maxStackWeightTonnes = Float64
    }

    /// Full vessel particulars and naval architectural specification.
    pub type alias VesselParticulars = {
        name = String,
        imoNumber = Int32,
        callSign = String,
        loaMeters = Float64,            // Length overall
        lbpMeters = Float64,            // Length between perpendiculars
        beamMeters = Float64,           // Molded breadth
        depthMeters = Float64,          // Molded depth
        designDraftMeters = Float64,    // Summer load line draft
        lightshipTonnes = Float64,      // Empty ship displacement
        lightshipKgMeters = Float64,    // Lightship vertical center of gravity from keel
        lightshipLcgMeters = Float64,   // Lightship longitudinal center of gravity from midship
        teuCapacity = Int32,            // Nominal twenty-foot equivalent unit capacity
        maxPermissibleBendingMomentKnm = Float64, // Hull girder maximum permissible SWBM
        holds = List[CargoHold],
        ballastTanks = List[TankState]
    }

    /// Creates standard specification for an 8,500 TEU Post-Panamax container vessel.
    pub def postPanamaxVessel(): VesselParticulars = {
        let holds = { holdNumber = 1, startBay = 1, endBay = 6, lengthMeters = 38.0, maxStackWeightTonnes = 12000.0 } ::
                    { holdNumber = 2, startBay = 7, endBay = 14, lengthMeters = 42.0, maxStackWeightTonnes = 18000.0 } ::
                    { holdNumber = 3, startBay = 15, endBay = 22, lengthMeters = 42.0, maxStackWeightTonnes = 20000.0 } ::
                    { holdNumber = 4, startBay = 23, endBay = 30, lengthMeters = 42.0, maxStackWeightTonnes = 20000.0 } ::
                    { holdNumber = 5, startBay = 31, endBay = 38, lengthMeters = 42.0, maxStackWeightTonnes = 18000.0 } ::
                    { holdNumber = 6, startBay = 39, endBay = 46, lengthMeters = 38.0, maxStackWeightTonnes = 14000.0 } :: Nil;

        let tanks = { tankId = BallastTank.Forepeak, capacityTonnes = 1200.0, currentWeightTonnes = 400.0, lcgMeters = 140.0, tcgMeters = 0.0, vcgMeters = 4.5, freeSurfaceMoment = 180.0 } ::
                    { tankId = BallastTank.Aftpeak, capacityTonnes = 1500.0, currentWeightTonnes = 600.0, lcgMeters = -135.0, tcgMeters = 0.0, vcgMeters = 6.0, freeSurfaceMoment = 220.0 } ::
                    { tankId = BallastTank.DoubleBottomPort(1), capacityTonnes = 800.0, currentWeightTonnes = 200.0, lcgMeters = 80.0, tcgMeters = -12.0, vcgMeters = 1.2, freeSurfaceMoment = 95.0 } ::
                    { tankId = BallastTank.DoubleBottomStarboard(1), capacityTonnes = 800.0, currentWeightTonnes = 200.0, lcgMeters = 80.0, tcgMeters = 12.0, vcgMeters = 1.2, freeSurfaceMoment = 95.0 } ::
                    { tankId = BallastTank.WingTankPort(1), capacityTonnes = 500.0, currentWeightTonnes = 100.0, lcgMeters = 0.0, tcgMeters = -18.5, vcgMeters = 8.0, freeSurfaceMoment = 40.0 } ::
                    { tankId = BallastTank.WingTankStarboard(1), capacityTonnes = 500.0, currentWeightTonnes = 100.0, lcgMeters = 0.0, tcgMeters = 18.5, vcgMeters = 8.0, freeSurfaceMoment = 40.0 } :: Nil;

        {
            name = "MV Atlantic Spreader",
            imoNumber = 9876543,
            callSign = "VRSP9",
            loaMeters = 335.0,
            lbpMeters = 320.0,
            beamMeters = 42.8,
            depthMeters = 24.6,
            designDraftMeters = 14.5,
            lightshipTonnes = 32500.0,
            lightshipKgMeters = 13.8,
            lightshipLcgMeters = -4.2,
            teuCapacity = 8500,
            maxPermissibleBendingMomentKnm = 4500000.0, // 4.5 million kN*m
            holds = holds,
            ballastTanks = tanks
        }
    }

    /// Finds which cargo hold compartment encompasses a given bay index.
    pub def findHoldForBay(v: VesselParticulars, bay: Int32): Option[CargoHold] = {
        List.find(h -> bay >= h#startBay and bay <= h#endBay, v#holds)
    }

    /// Checks if two bays are separated by a transverse watertight steel bulkhead.
    /// Bulkheads divide adjacent cargo holds.
    pub def isBulkheadSeparated(v: VesselParticulars, bayA: Int32, bayB: Int32): Bool = {
        let holdA = findHoldForBay(v, bayA);
        let holdB = findHoldForBay(v, bayB);
        match (holdA, holdB) {
            case (Some(h1), Some(h2)) => h1#holdNumber != h2#holdNumber
            case _ => false
        }
    }

    /// Computes total ballast water currently onboard in metric tonnes.
    pub def totalBallastWeightTonnes(v: VesselParticulars): Float64 = {
        List.foldLeft((acc, t) -> acc + t#currentWeightTonnes, 0.0, v#ballastTanks)
    }
}
