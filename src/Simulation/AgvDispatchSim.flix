// Spreader: Container Terminal Operating System
// Automated Guided Vehicle (AGV) Fleet Kinematics, Routing, and Quay Buffer Dispatch

pub mod Simulation.AgvDispatchSim {

    use Model.MathUtil

    /// State telemetry of an automated guided vehicle (AGV).
    pub type alias AgvState = {
        agvId = String,
        location = String,
        batteryPercent = Float64,
        isLoaded = Bool,
        assignedContainer = Option[String],
        availableAtTime = Float64
    }

    /// Routing path specification between terminal zones.
    pub type alias AgvRoute = {
        fromLocation = String,
        toLocation = String,
        distanceMeters = Float64,
        nominalSpeedMps = Float64,
        curvesCount = Int32
    }

    /// Default kinematic specification for battery-electric AGV.
    pub def defaultNominalSpeed(): Float64 = 5.5 // m/s (~20 km/h)

    /// Estimates transit time in seconds between quay apron and yard block exchange zone.
    pub def calculateTransitTime(route: AgvRoute): Float64 = {
        let speed = if (route#nominalSpeedMps <= 0.0) defaultNominalSpeed() else route#nominalSpeedMps;
        let straightDuration = route#distanceMeters / speed;
        // Each curved turnout introduces acceleration, steering alignment, and optical guidance penalty
        let curvePenalty = Int32.toFloat64(route#curvesCount) * 4.2;
        straightDuration + curvePenalty
    }

    /// Calculates battery energy consumption in percentage points for a route.
    pub def calculateBatteryDepletion(distanceMeters: Float64, isLoaded: Bool): Float64 = {
        let consumptionRatePerKm = if (isLoaded) 0.55 else 0.32; // % battery per km
        (distanceMeters / 1000.0) * consumptionRatePerKm
    }

    /// Selects the optimal AGV from available fleet for a dispatch request.
    /// Prefers AGVs that are already free (availableAtTime <= currentTime) with highest battery charge.
    pub def selectAgv(fleet: List[AgvState], currentTime: Float64): Option[AgvState] = {
        let readyAgvs = List.filter(a -> a#availableAtTime <= currentTime and a#batteryPercent >= 20.0, fleet);
        if (not List.isEmpty(readyAgvs)) {
            // Pick ready AGV with highest battery charge
            List.foldLeft((bestOpt: Option[AgvState], candidate: AgvState) -> match bestOpt {
                case None => Some(candidate)
                case Some(best) =>
                    if (candidate#batteryPercent > best#batteryPercent) Some(candidate)
                    else Some(best)
            }, None, readyAgvs)
        } else {
            // If none currently idle, find earliest available AGV with adequate battery
            let qualified = List.filter(a -> a#batteryPercent >= 20.0, fleet);
            List.foldLeft((bestOpt: Option[AgvState], candidate: AgvState) -> match bestOpt {
                case None => Some(candidate)
                case Some(best) =>
                    if (candidate#availableAtTime < best#availableAtTime) Some(candidate)
                    else Some(best)
            }, None, qualified)
        }
    }

    /// Calculates buffer queue congestion delay under STS crane apron lanes.
    pub def calculateQuayQueueDelay(waitingAgvs: Int32): Float64 = {
        if (waitingAgvs <= 0) 0.0
        else {
            // Non-linear queue clearance model: 18 seconds per queuing vehicle ahead
            Int32.toFloat64(waitingAgvs) * 18.0
        }
    }
}
