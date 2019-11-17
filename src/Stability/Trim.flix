// Spreader: Container Terminal Operating System
// Longitudinal Trim, Forward and Aft Drafts, and Full Equilibrium Solver

pub mod Stability.Trim {
    use Model.VesselProfile.VesselParticulars;
    use Stability.Types.LoadingItem;
    use Stability.Types.FreeSurfaceItem;
    use Stability.Types.HydrostaticEntry;
    use Stability.Types.StabilityState;
    use Stability.Types.IntactStabilityCriteria;
    use Stability.Hydrostatics.{
        totalDisplacement, computeCenterOfGravity, totalFreeSurfaceMoment,
        computeFse, computeGmt, computeHeelAngleDegrees, interpolateHydrostatics
    };

    /// Computes trimming moment in tonne-meters.
    /// TM = Delta * (LCG - LCB).
    /// Positive TM produces trim by stern (aft draft increases).
    pub def trimmingMoment(displacementTonnes: Float64, lcgMeters: Float64, lcbMeters: Float64): Float64 = {
        displacementTonnes * (lcgMeters - lcbMeters)
    }

    /// Computes total vessel trim in meters.
    /// trimMeters = (Delta * (LCG - LCB)) / (100.0 * MTC).
    pub def computeTrimMeters(displacementTonnes: Float64, lcgMeters: Float64, lcbMeters: Float64, mtcTonnesMPerCm: Float64): Float64 = {
        if (mtcTonnesMPerCm <= 0.0) 0.0
        else {
            let tm = trimmingMoment(displacementTonnes, lcgMeters, lcbMeters);
            let trimCm = tm / mtcTonnesMPerCm;
            trimCm / 100.0
        }
    }

    /// Computes forward and aft drafts given midship draft, total trim, and length between perpendiculars.
    /// Assuming LCF is near amidships:
    /// draftAft = draftMid + (trimMeters / 2.0)
    /// draftFwd = draftMid - (trimMeters / 2.0)
    pub def computeDrafts(draftMidMeters: Float64, trimMeters: Float64): (Float64, Float64) = {
        let halfTrim = trimMeters / 2.0;
        let draftAft = draftMidMeters + halfTrim;
        let draftFwd = draftMidMeters - halfTrim;
        (draftFwd, draftAft)
    }

    /// Solves the full floating equilibrium and checks IMO intact stability compliance.
    pub def solveEquilibrium(
        vessel: VesselParticulars,
        cargoItems: List[LoadingItem],
        liquidTanks: List[FreeSurfaceItem],
        hydrostaticTable: List[HydrostaticEntry],
        criteria: IntactStabilityCriteria
    ): StabilityState = {
        let totalDisp = totalDisplacement(vessel#lightshipTonnes, cargoItems);
        let deadweight = totalDisp - vessel#lightshipTonnes;

        let (lcg, tcg, kgSolid) = computeCenterOfGravity(
            vessel#lightshipTonnes,
            vessel#lightshipLcgMeters,
            0.0, // Centerline lightweight TCG
            vessel#lightshipKgMeters,
            cargoItems
        );

        let fsm = totalFreeSurfaceMoment(liquidTanks);
        let fse = computeFse(fsm, totalDisp);
        let kgFluid = kgSolid + fse;

        let hydro = interpolateHydrostatics(totalDisp, hydrostaticTable);
        let gmtFluid = computeGmt(hydro#kmtMeters, kgSolid, fse);
        let heelAngle = computeHeelAngleDegrees(tcg, gmtFluid);

        let trim = computeTrimMeters(totalDisp, lcg, hydro#lcbMeters, hydro#mtcTonnesMetersPerCm);
        let (draftFwd, draftAft) = computeDrafts(hydro#draftMeters, trim);

        let isCompliant = 
            gmtFluid >= criteria#minGmtFluidMeters and
            Float64.abs(heelAngle) <= criteria#maxHeelDegrees and
            trim <= criteria#maxTrimSternMeters and
            trim >= criteria#minTrimMeters and
            draftAft <= vessel#designDraftMeters;

        {
            displacementTonnes = totalDisp,
            totalDeadweightTonnes = deadweight,
            kgSolidMeters = kgSolid,
            fseMeters = fse,
            kgFluidMeters = kgFluid,
            lcgMeters = lcg,
            tcgMeters = tcg,
            kmtMeters = hydro#kmtMeters,
            gmtFluidMeters = gmtFluid,
            draftMidMeters = hydro#draftMeters,
            draftFwdMeters = draftFwd,
            draftAftMeters = draftAft,
            trimMeters = trim,
            heelAngleDegrees = heelAngle,
            isCompliant = isCompliant
        }
    }
}
