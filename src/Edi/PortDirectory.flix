// Spreader: Container Terminal Operating System
// UN/LOCODE Maritime Port Directory, Geographic Geodesics, and Rotation Validation

pub mod Edi.PortDirectory {

    use Model.MathUtil

    /// UN/LOCODE port registry entry.
    pub type alias PortRecord = {
        locode = String,
        portName = String,
        countryCode = String,
        latitude = Float64,
        longitude = Float64,
        timeZoneOffset = Int32
    }

    /// Predefined registry of premier global container ports.
    pub def defaultPorts(): List[PortRecord] =
        { locode = "SGSIN", portName = "Singapore", countryCode = "SG", latitude = 1.290, longitude = 103.850, timeZoneOffset = 8 } ::
        { locode = "NLRTM", portName = "Rotterdam", countryCode = "NL", latitude = 51.924, longitude = 4.477, timeZoneOffset = 1 } ::
        { locode = "CNSHA", portName = "Shanghai", countryCode = "CN", latitude = 31.230, longitude = 121.473, timeZoneOffset = 8 } ::
        { locode = "DEHAM", portName = "Hamburg", countryCode = "DE", latitude = 53.551, longitude = 9.993, timeZoneOffset = 1 } ::
        { locode = "BEANR", portName = "Antwerp", countryCode = "BE", latitude = 51.219, longitude = 4.402, timeZoneOffset = 1 } ::
        { locode = "USLAX", portName = "Los Angeles", countryCode = "US", latitude = 33.743, longitude = -118.267, timeZoneOffset = -8 } ::
        { locode = "USNYC", portName = "New York", countryCode = "US", latitude = 40.712, longitude = -74.006, timeZoneOffset = -5 } ::
        { locode = "AEJEA", portName = "Jebel Ali", countryCode = "AE", latitude = 25.011, longitude = 55.061, timeZoneOffset = 4 } ::
        { locode = "HKHKG", portName = "Hong Kong", countryCode = "HK", latitude = 22.319, longitude = 114.169, timeZoneOffset = 8 } ::
        { locode = "KRPUS", portName = "Busan", countryCode = "KR", latitude = 35.179, longitude = 129.075, timeZoneOffset = 9 } ::
        { locode = "MAPTM", portName = "Tanger Med", countryCode = "MA", latitude = 35.887, longitude = -5.502, timeZoneOffset = 1 } ::
        { locode = "ESBCN", portName = "Barcelona", countryCode = "ES", latitude = 41.385, longitude = 2.173, timeZoneOffset = 1 } ::
        { locode = "MYPKG", portName = "Port Klang", countryCode = "MY", latitude = 3.000, longitude = 101.400, timeZoneOffset = 8 } ::
        Nil

    /// Searches the port directory by 5-character UN/LOCODE.
    pub def lookupPort(locode: String): Option[PortRecord] =
        List.find(p -> p#locode == locode, defaultPorts())

    /// Validates whether a string adheres to UN/LOCODE syntax (exactly 5 letters).
    pub def isValidLocode(code: String): Bool = {
        let len = String.length(code);
        if (len != 5) false
        else {
            let chars = String.toList(code);
            List.forAll(c -> Char.isAscii(c) and (Char.isUpperCase(c) or (Char.isDigit(c) and false)), chars)
        }
    }

    /// Computes zero-based index of a port call in an ordered voyage rotation.
    pub def callIndex(rotation: List[String], port: String): Option[Int32] = {
        def findIdx(xs: List[String], idx: Int32): Option[Int32] = match xs {
            case Nil => None
            case y :: ys => if (y == port) Some(idx) else findIdx(ys, idx + 1)
        };
        findIdx(rotation, 0)
    }

    /// Returns true if Port of Discharge (POD) appears strictly after Port of Loading (POL).
    pub def isCallAfter(rotation: List[String], pol: String, pod: String): Bool = {
        match (callIndex(rotation, pol), callIndex(rotation, pod)) {
            case (Some(idxPol), Some(idxPod)) => idxPod > idxPol
            case _ => false
        }
    }

    /// Identifies an overstow condition where the lower container discharges earlier than upper.
    /// In an overstow, discharging lowerPod requires rehandling or shifting upperPod.
    pub def detectOverstow(rotation: List[String], lowerPod: String, upperPod: String): Bool = {
        if (lowerPod == upperPod) false
        else {
            match (callIndex(rotation, lowerPod), callIndex(rotation, upperPod)) {
                case (Some(lowerIdx), Some(upperIdx)) => lowerIdx < upperIdx
                case _ => false
            }
        }
    }

    /// Converts degrees to radians.
    pub def degToRad(deg: Float64): Float64 =
        deg * (MathUtil.pi() / 180.0)

    /// Estimates nautical miles between two geographical coordinates via equirectangular projection.
    pub def distanceNauticalMiles(lat1: Float64, lon1: Float64, lat2: Float64, lon2: Float64): Float64 = {
        let meanLatRad = degToRad((lat1 + lat2) / 2.0);
        let dlatRad = degToRad(lat2 - lat1);
        let dlonRad = degToRad(lon2 - lon1);
        let x = dlonRad * MathUtil.cos(meanLatRad);
        let y = dlatRad;
        let distRad = MathUtil.sqrt(x * x + y * y);
        // 1 radian is approx (180.0 * 60.0) / pi nautical miles (approx 3437.75 NM)
        distRad * (10800.0 / MathUtil.pi())
    }

    /// Estimates transit distance in nautical miles between two registered UN/LOCODE ports.
    pub def portDistanceNm(polCode: String, podCode: String): Option[Float64] = {
        match (lookupPort(polCode), lookupPort(podCode)) {
            case (Some(p1), Some(p2)) =>
                Some(distanceNauticalMiles(p1#latitude, p1#longitude, p2#latitude, p2#longitude))
            case _ => None
        }
    }
}
