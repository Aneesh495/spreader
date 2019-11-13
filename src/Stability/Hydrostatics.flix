// Spreader: Container Terminal Operating System
// Marine Hydrostatics: Center of Gravity, Free Surface Moments, and Metacentric Height

pub mod Stability.Hydrostatics {
    use Model.MathUtil;
    use Stability.Types.LoadingItem;
    use Stability.Types.FreeSurfaceItem;
    use Stability.Types.HydrostaticEntry;

    /// Computes total displacement (lightweight + deadweight items).
    pub def totalDisplacement(lightweightTonnes: Float64, items: List[LoadingItem]): Float64 = {
        let deadweight = List.foldLeft((acc, it) -> acc + it#weightTonnes, 0.0, items);
        lightweightTonnes + deadweight
    }

    /// Computes 3D Center of Gravity (LCG, TCG, KG) through principle of moments.
    pub def computeCenterOfGravity(
        lightweightTonnes: Float64,
        lightweightLcg: Float64,
        lightweightTcg: Float64,
        lightweightKg: Float64,
        items: List[LoadingItem]
    ): (Float64, Float64, Float64) = {
        let totalDisp = totalDisplacement(lightweightTonnes, items);
        if (totalDisp <= 0.0) (0.0, 0.0, 0.0)
        else {
            let lcgMoment = List.foldLeft((acc, it) -> acc + (it#weightTonnes * it#lcgMeters), lightweightTonnes * lightweightLcg, items);
            let tcgMoment = List.foldLeft((acc, it) -> acc + (it#weightTonnes * it#tcgMeters), lightweightTonnes * lightweightTcg, items);
            let kgMoment  = List.foldLeft((acc, it) -> acc + (it#weightTonnes * it#kgMeters),  lightweightTonnes * lightweightKg,  items);

            (lcgMoment / totalDisp, tcgMoment / totalDisp, kgMoment / totalDisp)
        }
    }

    /// Computes Free Surface Moment (FSM) summation across all slack tanks.
    /// FSM = sum(rho * I_t) in tonne-meters.
    pub def totalFreeSurfaceMoment(tanks: List[FreeSurfaceItem]): Float64 = {
        List.foldLeft((acc, t) -> {
            if (t#isSlack) acc + (t#liquidDensityTonnesPerM3 * t#secondMomentOfAreaM4)
            else acc
        }, 0.0, tanks)
    }

    /// Computes Free Surface Effect (FSE virtual rise in KG).
    /// FSE = FSM / Displacement.
    pub def computeFse(fsmTonnesM: Float64, displacementTonnes: Float64): Float64 = {
        if (displacementTonnes <= 0.0) 0.0
        else fsmTonnesM / displacementTonnes
    }

    /// Computes transverse metacentric height (GM_T fluid).
    /// GM_T = KM_T - (KG_solid + FSE).
    pub def computeGmt(kmtMeters: Float64, kgSolidMeters: Float64, fseMeters: Float64): Float64 = {
        kmtMeters - (kgSolidMeters + fseMeters)
    }

    /// Computes steady listing angle (heel) from transverse asymmetry (TCG != 0).
    /// tan(phi) = TCG / GM_T.
    /// Returns angle in degrees (positive = starboard heel, negative = port heel).
    pub def computeHeelAngleDegrees(tcgMeters: Float64, gmtFluidMeters: Float64): Float64 = {
        if (Float64.abs(gmtFluidMeters) < 0.001) 0.0
        else {
            let tanPhi = tcgMeters / gmtFluidMeters;
            let rad = MathUtil.atan(tanPhi);
            rad * 180.0 / MathUtil.pi()
        }
    }

    /// Linearly interpolates hydrostatic properties from tabular data based on displacement.
    pub def interpolateHydrostatics(
        targetDispTonnes: Float64,
        table: List[HydrostaticEntry]
    ): HydrostaticEntry = {
        match table {
            case Nil => {
                draftMeters = 0.0,
                displacementTonnes = targetDispTonnes,
                tpcTonnesPerCm = 100.0,
                mtcTonnesMetersPerCm = 1500.0,
                lcbMeters = 0.0,
                kbMeters = 0.0,
                kmtMeters = 20.0,
                kmlMeters = 300.0
            }
            case e1 :: Nil => e1
            case e1 :: e2 :: rest => {
                if (targetDispTonnes <= e1#displacementTonnes) e1
                else if (targetDispTonnes <= e2#displacementTonnes) {
                    let span = e2#displacementTonnes - e1#displacementTonnes;
                    let frac = if (span <= 0.0) 0.0 else (targetDispTonnes - e1#displacementTonnes) / span;
                    {
                        draftMeters = e1#draftMeters + frac * (e2#draftMeters - e1#draftMeters),
                        displacementTonnes = targetDispTonnes,
                        tpcTonnesPerCm = e1#tpcTonnesPerCm + frac * (e2#tpcTonnesPerCm - e1#tpcTonnesPerCm),
                        mtcTonnesMetersPerCm = e1#mtcTonnesMetersPerCm + frac * (e2#mtcTonnesMetersPerCm - e1#mtcTonnesMetersPerCm),
                        lcbMeters = e1#lcbMeters + frac * (e2#lcbMeters - e1#lcbMeters),
                        kbMeters = e1#kbMeters + frac * (e2#kbMeters - e1#kbMeters),
                        kmtMeters = e1#kmtMeters + frac * (e2#kmtMeters - e1#kmtMeters),
                        kmlMeters = e1#kmlMeters + frac * (e2#kmlMeters - e1#kmlMeters)
                    }
                } else {
                    interpolateHydrostatics(targetDispTonnes, e2 :: rest)
                }
            }
        }
    }
}
