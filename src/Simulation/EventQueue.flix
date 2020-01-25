// Spreader: Container Terminal Operating System
// Pure Priority Event Queue for Discrete-Event Simulation Engine

pub mod Simulation.EventQueue {

    /// Represents an individual discrete event scheduled at a specific simulation timestamp.
    pub type alias SimEvent = {
        eventId = String,
        eventType = String,
        scheduledTime = Float64,
        entityId = String,
        details = String
    }

    /// Initializes an empty priority event queue.
    pub def empty(): List[SimEvent] = Nil

    /// Returns true if the event queue contains zero scheduled events.
    pub def isEmpty(q: List[SimEvent]): Bool = List.isEmpty(q)

    /// Returns the number of events currently queued.
    pub def size(q: List[SimEvent]): Int32 = List.length(q)

    /// Retrieves the earliest chronological event without modifying the queue.
    pub def peek(q: List[SimEvent]): Option[SimEvent] = List.head(q)

    /// Inserts a new event in chronological order of scheduledTime (ascending).
    pub def insert(event: SimEvent, q: List[SimEvent]): List[SimEvent] = match q {
        case Nil => event :: Nil
        case x :: xs =>
            if (event#scheduledTime < x#scheduledTime) event :: x :: xs
            else x :: insert(event, xs)
    }

    /// Inserts multiple events into the priority event queue.
    pub def insertAll(events: List[SimEvent], q: List[SimEvent]): List[SimEvent] =
        List.foldLeft((acc, ev) -> insert(ev, acc), q, events)

    /// Removes and returns the earliest event together with the remaining queue.
    pub def pop(q: List[SimEvent]): Option[(SimEvent, List[SimEvent])] = match q {
        case Nil => None
        case x :: xs => Some((x, xs))
    }

    /// Filters queued events scheduled for a specific equipment entity (e.g. "STS-01", "AGV-04").
    pub def filterByEntity(targetEntity: String, q: List[SimEvent]): List[SimEvent] =
        List.filter(ev -> ev#entityId == targetEntity, q)
}
