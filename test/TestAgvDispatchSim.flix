// Spreader: Container Terminal Operating System
// Test Suite for AGV Fleet Routing and Dispatch Simulation

mod TestAgvDispatchSim {

    use Simulation.AgvDispatchSim
    use Simulation.AgvDispatchSim.{AgvState, AgvRoute}

    @Test
    def testTransitTimeCalculation(): Unit \ Assert = {
        let route = {
            fromLocation = "QUAY_STS_02",
            toLocation = "BLOCK_B04_WATERSIDE",
            distanceMeters = 350.0,
            nominalSpeedMps = 5.0,
            curvesCount = 2
        };
        let duration = AgvDispatchSim.calculateTransitTime(route);
        // 350 / 5 = 70.0s + 2 * 4.2 = 8.4s -> 78.4s
        Assert.assertTrue(duration > 75.0);
        Assert.assertTrue(duration < 85.0)
    }

    @Test
    def testBatteryDepletion(): Unit \ Assert = {
        let loadedLoss = AgvDispatchSim.calculateBatteryDepletion(1000.0, true);
        let emptyLoss = AgvDispatchSim.calculateBatteryDepletion(1000.0, false);
        Assert.assertTrue(loadedLoss > emptyLoss);
        Assert.assertTrue(loadedLoss > 0.4 and loadedLoss < 0.7)
    }

    @Test
    def testSelectAgvReadyHighestBattery(): Unit \ Assert = {
        let a1 = { agvId = "AGV-01", location = "IDLE", batteryPercent = 65.0, isLoaded = false, assignedContainer = None, availableAtTime = 0.0 };
        let a2 = { agvId = "AGV-02", location = "IDLE", batteryPercent = 90.0, isLoaded = false, assignedContainer = None, availableAtTime = 10.0 };
        let a3 = { agvId = "AGV-03", location = "IDLE", batteryPercent = 80.0, isLoaded = false, assignedContainer = None, availableAtTime = 0.0 };

        // At currentTime = 20.0, all three are available. a2 has highest battery (90.0%)
        let chosen = AgvDispatchSim.selectAgv(a1 :: a2 :: a3 :: Nil, 20.0);
        match chosen {
            case None => Assert.assertTrue(false)
            case Some(agv) => Assert.assertEq(expected = "AGV-02", agv#agvId)
        }
    }

    @Test
    def testSelectAgvBusyEarliestFree(): Unit \ Assert = {
        // At currentTime = 50.0, both are currently busy in transit
        let a1 = { agvId = "AGV-01", location = "TRANSIT", batteryPercent = 85.0, isLoaded = true, assignedContainer = None, availableAtTime = 120.0 };
        let a2 = { agvId = "AGV-02", location = "TRANSIT", batteryPercent = 75.0, isLoaded = true, assignedContainer = None, availableAtTime = 80.0 };

        // Should select a2 because it becomes free at 80.0 (earlier than 120.0)
        let chosen = AgvDispatchSim.selectAgv(a1 :: a2 :: Nil, 50.0);
        match chosen {
            case None => Assert.assertTrue(false)
            case Some(agv) => Assert.assertEq(expected = "AGV-02", agv#agvId)
        }
    }

    @Test
    def testExcludeLowBatteryAgv(): Unit \ Assert = {
        // AGV with battery below 20.0% must not be dispatched
        let a1 = { agvId = "AGV-CRITICAL", location = "IDLE", batteryPercent = 15.0, isLoaded = false, assignedContainer = None, availableAtTime = 0.0 };
        let chosen = AgvDispatchSim.selectAgv(a1 :: Nil, 10.0);
        Assert.assertEq(expected = None, match chosen { case None => None case Some(a) => Some(a#agvId) })
    }

    @Test
    def testQuayQueueDelay(): Unit \ Assert = {
        let noQueue = AgvDispatchSim.calculateQuayQueueDelay(0);
        let queue3 = AgvDispatchSim.calculateQuayQueueDelay(3);
        Assert.assertEq(expected = 0.0, noQueue);
        Assert.assertEq(expected = 54.0, queue3)
    }
}
