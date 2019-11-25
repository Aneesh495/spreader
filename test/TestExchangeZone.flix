// Test suite for Exchange Zone Scheduling and Vehicle Buffer Allocation

mod TestExchangeZone {
    use Model.YardCoordinates.ExchangeZone;
    use Yard.ExchangeZoneScheduler.{
        ExchangeLane, TransportMode, TransferBooking,
        findAvailableLane, assignLane
    };

    @Test
    def testFindAvailableLane(): Unit \ Assert = {
        let l1: ExchangeLane = { laneId = 1, zone = ExchangeZone.WatersideTransfer, isOccupied = true, occupantContainerId = Some("C1"), allocatedVehicle = None };
        let l2: ExchangeLane = { laneId = 2, zone = ExchangeZone.WatersideTransfer, isOccupied = false, occupantContainerId = None, allocatedVehicle = None };
        let l3: ExchangeLane = { laneId = 3, zone = ExchangeZone.LandsideGate, isOccupied = false, occupantContainerId = None, allocatedVehicle = None };

        let lanes = l1 :: l2 :: l3 :: Nil;

        // Lane 2 is first free waterside lane
        Assert.assertEq(expected = Some(2), findAvailableLane(ExchangeZone.WatersideTransfer, lanes));
        // Lane 3 is first free landside lane
        Assert.assertEq(expected = Some(3), findAvailableLane(ExchangeZone.LandsideGate, lanes));
        // No rail lane exists
        Assert.assertEq(expected = None, findAvailableLane(ExchangeZone.RailIntermodal, lanes))
    }

    @Test
    def testAssignLaneSuccess(): Unit \ Assert = {
        let l1: ExchangeLane = { laneId = 1, zone = ExchangeZone.WatersideTransfer, isOccupied = false, occupantContainerId = None, allocatedVehicle = None };
        let booking: TransferBooking = {
            bookingId = "BK001",
            containerId = "MSCU9999999",
            vehicle = TransportMode.AutomatedGuidedVehicle("AGV_08"),
            zone = ExchangeZone.WatersideTransfer,
            isDischargeToYard = true,
            scheduledTimeSec = 1000i64
        };

        match assignLane(booking, l1 :: Nil, 1000i64) {
            case Some((assign, updatedLanes)) => {
                Assert.assertEq(expected = "BK001", assign#bookingId);
                Assert.assertEq(expected = 1, assign#assignedLaneId);
                Assert.assertEq(expected = 1090i64, assign#estimatedServiceTimeSec);
                // Check lane is now marked occupied
                match updatedLanes {
                    case l :: Nil => Assert.assertTrue(l#isOccupied)
                    case _ => Assert.assertTrue(false)
                }
            }
            case None => Assert.assertTrue(false)
        }
    }
}
