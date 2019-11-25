// Spreader: Container Terminal Operating System
// Exchange Zone Buffer Scheduling: Waterside AGV vs Landside Truck Interfaces

pub mod Yard.ExchangeZoneScheduler {
    use Model.YardCoordinates.ExchangeZone;

    /// Terminal transport vehicle category.
    pub enum TransportMode with Eq, Order, ToString {
        case AutomatedGuidedVehicle(String), // AGV with telemetry ID
        case ExternalRoadTruck(String),      // Road haulier truck license
        case TerminalTractor(String)         // Internal transfer vehicle (ITV)
    }

    /// Status of a designated exchange lane buffer slot.
    pub type alias ExchangeLane = {
        laneId = Int32,
        zone = ExchangeZone,
        isOccupied = Bool,
        occupantContainerId = Option[String],
        allocatedVehicle = Option[TransportMode]
    }

    /// Booking request to drop or pick up a container in an exchange zone.
    pub type alias TransferBooking = {
        bookingId = String,
        containerId = String,
        vehicle = TransportMode,
        zone = ExchangeZone,
        isDischargeToYard = Bool, // True = drop off container, False = pick up container
        scheduledTimeSec = Int64
    }

    /// Allocation result mapping a booking to a specific buffer lane.
    pub type alias LaneAssignment = {
        bookingId = String,
        assignedLaneId = Int32,
        estimatedServiceTimeSec = Int64
    }

    /// Finds the first available lane in the specified exchange zone.
    pub def findAvailableLane(zone: ExchangeZone, lanes: List[ExchangeLane]): Option[Int32] = {
        let matching = List.filter(l -> l#zone == zone and not l#isOccupied and Option.isEmpty(l#allocatedVehicle), lanes);
        match List.head(matching) {
            case Some(l) => Some(l#laneId)
            case None => None
        }
    }

    /// Schedules an incoming transport vehicle to an exchange lane.
    pub def assignLane(
        booking: TransferBooking,
        lanes: List[ExchangeLane],
        currentTimeSec: Int64
    ): Option[(LaneAssignment, List[ExchangeLane])] = {
        match findAvailableLane(booking#zone, lanes) {
            case Some(laneId) => {
                let updatedLanes = List.map(l -> {
                    if (l#laneId == laneId) {
                        { isOccupied = booking#isDischargeToYard,
                          occupantContainerId = if (booking#isDischargeToYard) Some(booking#containerId) else None,
                          allocatedVehicle = Some(booking#vehicle) | l }
                    } else l
                }, lanes);

                let assignment: LaneAssignment = {
                    bookingId = booking#bookingId,
                    assignedLaneId = laneId,
                    estimatedServiceTimeSec = currentTimeSec + 90i64 // 90 seconds average gantry exchange duration
                };

                Some((assignment, updatedLanes))
            }
            case None => None
        }
    }
}
