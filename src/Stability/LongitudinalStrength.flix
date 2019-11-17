// Spreader: Container Terminal Operating System
// Longitudinal Strength: 21-Station Hull Girder Shear Force and Bending Moment Integration

pub mod Stability.LongitudinalStrength {

    /// Hull girder station index (0 = Aft Perpendicular, 10 = Midships, 20 = Forward Perpendicular).
    pub type alias StationNumber = Int32

    /// Station evaluation point with buoyancy, weight, shear force, and bending moment.
    pub type alias StationStress = {
        station = StationNumber,
        xMeters = Float64,             // Distance from Aft Perpendicular (0.0 .. Lbp)
        buoyancyTonnesPerM = Float64,
        totalWeightTonnesPerM = Float64,
        netLoadTonnesPerM = Float64,
        shearForceKn = Float64,        // SWSF in kiloNewtons
        bendingMomentKnm = Float64     // SWBM in kiloNewton-meters
    }

    /// Structural integrity evaluation across all 21 hull stations.
    pub type alias LongitudinalStrengthReport = {
        stations = List[StationStress],
        maxShearForceKn = Float64,
        maxBendingMomentKnm = Float64,
        isSagging = Bool,              // True if midship bending moment is positive (sagging)
        isCompliant = Bool
    }

    /// Acceleration due to gravity (m/s^2).
    def gravity(): Float64 = 9.80665

    /// Computes station distance from Aft Perpendicular for a given station index (0..20).
    pub def stationPosition(st: StationNumber, lbpMeters: Float64): Float64 = {
        let step = lbpMeters / 20.0;
        Int32.toFloat64(st) * step
    }

    /// Generates ideal parabolic/prismatic buoyancy distribution curve scaled to match total displacement.
    pub def approximateBuoyancyAtStation(st: StationNumber, totalDispTonnes: Float64, lbpMeters: Float64): Float64 = {
        // Station 0 (AP) and 20 (FP) taper down, midship (Station 10) carries highest volume
        let relPos = Int32.toFloat64(st) / 20.0; // 0.0 to 1.0
        // Parabolic profile: 4 * x * (1 - x) peaks at 1.0 at midships
        let shape = 4.0 * relPos * (1.0 - relPos);
        // Average required buoyancy per meter = totalDisp / lbp
        let avgBuoyancy = totalDispTonnes / lbpMeters;
        // Scale shape so integral matches total displacement (parabola avg height is 2/3 peak height)
        let peakBuoyancy = avgBuoyancy * 1.5;
        shape * peakBuoyancy
    }

    /// Integrates 21 stations using trapezoidal rule to compute SWSF and SWBM profiles.
    pub def integrateHullGirder(
        lbpMeters: Float64,
        totalDispTonnes: Float64,
        weightDistribution: List[(StationNumber, Float64)], // (Station, WeightTonnesPerMeter)
        maxPermissibleBendingMomentKnm: Float64
    ): LongitudinalStrengthReport = {
        let dx = lbpMeters / 20.0;

        // Recursive integration across stations 0..20
        def step(st: Int32, prevV: Float64, prevM: Float64, prevNet: Float64, acc: List[StationStress]): List[StationStress] = {
            if (st > 20) List.reverse(acc)
            else {
                let x = stationPosition(st, lbpMeters);
                let b = approximateBuoyancyAtStation(st, totalDispTonnes, lbpMeters);
                let w = match List.find(p -> match p { case (s, _) => s == st }, weightDistribution) {
                    case Some((_, wt)) => wt
                    case None => totalDispTonnes / lbpMeters
                };
                let net = b - w;

                let curV = if (st == 0) 0.0 else prevV + (0.5 * (prevNet + net) * dx * gravity());
                let curM = if (st == 0) 0.0 else prevM + (0.5 * (prevV + curV) * dx);

                let item: StationStress = {
                    station = st,
                    xMeters = x,
                    buoyancyTonnesPerM = b,
                    totalWeightTonnesPerM = w,
                    netLoadTonnesPerM = net,
                    shearForceKn = curV,
                    bendingMomentKnm = curM
                };
                step(st + 1, curV, curM, net, item :: acc)
            }
        };

        let initialB = approximateBuoyancyAtStation(0, totalDispTonnes, lbpMeters);
        let initialW = match List.find(p -> match p { case (s, _) => s == 0 }, weightDistribution) {
            case Some((_, wt)) => wt
            case None => totalDispTonnes / lbpMeters
        };
        let initialNet = initialB - initialW;

        let stations = step(0, 0.0, 0.0, initialNet, Nil);

        let maxV = List.foldLeft((acc, s) -> Float64.max(acc, Float64.abs(s#shearForceKn)), 0.0, stations);
        let maxM = List.foldLeft((acc, s) -> Float64.max(acc, Float64.abs(s#bendingMomentKnm)), 0.0, stations);

        let midshipM = match List.find(s -> s#station == 10, stations) {
            case Some(st10) => st10#bendingMomentKnm
            case None => 0.0
        };

        {
            stations = stations,
            maxShearForceKn = maxV,
            maxBendingMomentKnm = maxM,
            isSagging = midshipM > 0.0,
            isCompliant = maxM <= maxPermissibleBendingMomentKnm
        }
    }
}
