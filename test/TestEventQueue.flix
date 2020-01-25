// Spreader: Container Terminal Operating System
// Test Suite for Discrete-Event Priority Queue

mod TestEventQueue {

    use Simulation.EventQueue
    use Simulation.EventQueue.SimEvent

    @Test
    def testEmptyQueue(): Unit \ Assert = {
        let q = EventQueue.empty();
        Assert.assertTrue(EventQueue.isEmpty(q));
        Assert.assertEq(expected = 0, EventQueue.size(q));
        match EventQueue.peek(q) {
            case None => Assert.assertTrue(true)
            case Some(_) => Assert.assertTrue(false)
        };
        match EventQueue.pop(q) {
            case None => Assert.assertTrue(true)
            case Some(_) => Assert.assertTrue(false)
        }
    }

    @Test
    def testPriorityOrdering(): Unit \ Assert = {
        let e1 = { eventId = "E1", eventType = "STS_HOIST", scheduledTime = 45.0, entityId = "STS-01", details = "Hoist container" };
        let e2 = { eventId = "E2", eventType = "AGV_ARRIVE", scheduledTime = 12.5, entityId = "AGV-03", details = "Arrive at quay" };
        let e3 = { eventId = "E3", eventType = "ASC_GANTRY", scheduledTime = 60.0, entityId = "ASC-1A", details = "Gantry position" };
        let e4 = { eventId = "E4", eventType = "GATE_IN", scheduledTime = 5.0, entityId = "TRUCK-99", details = "Gate arrival" };

        let q = EventQueue.empty()
            |> EventQueue.insert(e1)
            |> EventQueue.insert(e2)
            |> EventQueue.insert(e3)
            |> EventQueue.insert(e4);

        Assert.assertEq(expected = 4, EventQueue.size(q));

        // Pop #1: should be e4 at 5.0
        match EventQueue.pop(q) {
            case None => Assert.assertTrue(false)
            case Some((pop1, q1)) => {
                Assert.assertEq(expected = "E4", pop1#eventId);
                Assert.assertEq(expected = 3, EventQueue.size(q1));

                // Pop #2: should be e2 at 12.5
                match EventQueue.pop(q1) {
                    case None => Assert.assertTrue(false)
                    case Some((pop2, q2)) => {
                        Assert.assertEq(expected = "E2", pop2#eventId);

                        // Pop #3: should be e1 at 45.0
                        match EventQueue.pop(q2) {
                            case None => Assert.assertTrue(false)
                            case Some((pop3, q3)) => {
                                Assert.assertEq(expected = "E1", pop3#eventId);

                                // Pop #4: should be e3 at 60.0
                                match EventQueue.pop(q3) {
                                    case None => Assert.assertTrue(false)
                                    case Some((pop4, q4)) => {
                                        Assert.assertEq(expected = "E3", pop4#eventId);
                                        Assert.assertTrue(EventQueue.isEmpty(q4))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @Test
    def testFilterByEntity(): Unit \ Assert = {
        let e1 = { eventId = "E1", eventType = "A", scheduledTime = 10.0, entityId = "STS-01", details = "" };
        let e2 = { eventId = "E2", eventType = "B", scheduledTime = 20.0, entityId = "AGV-05", details = "" };
        let e3 = { eventId = "E3", eventType = "C", scheduledTime = 30.0, entityId = "STS-01", details = "" };

        let q = EventQueue.insertAll(e1 :: e2 :: e3 :: Nil, EventQueue.empty());
        let stsEvents = EventQueue.filterByEntity("STS-01", q);

        Assert.assertEq(expected = 2, List.length(stsEvents))
    }
}
