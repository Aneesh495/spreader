// Spreader: Container Terminal Operating System
// SMDG BAPLIE 2.2 / 3.1 Electronic Bayplan Parser

pub mod Edi.BaplieParser {
    use Model.Coordinates.ShipCell;
    use Model.HazmatTypes.ImdgClass;
    use Edi.Tokenizer.{EdiSegment, parseEdifact};
    use Edi.SegmentNav.{findFirst, findAll, getComponent, groupByTrigger};

    /// Individual container stowed in the bayplan.
    pub type alias BaplieContainer = {
        containerId = String,
        isoType = String,
        cell = ShipCell,
        grossWeightTonnes = Float64,
        portOfLoading = String,
        portOfDischarge = String,
        isReefer = Bool,
        reeferTempCelsius = Option[Float64],
        hazmatClass = Option[ImdgClass],
        unNumber = Option[Int32]
    }

    /// Complete parsed SMDG BAPLIE bayplan message.
    pub type alias BaplieBayplan = {
        vesselName = String,
        callSign = String,
        voyageNumber = String,
        senderId = String,
        containers = List[BaplieContainer]
    }

    /// Parses ISO 9711 Bay-Row-Tier string (e.g. "0010282" or "010282" -> Bay 1, Row 2, Tier 82).
    pub def parseBrtCell(brtStr: String): Option[ShipCell] = {
        let clean = String.trim(brtStr);
        let len = String.length(clean);
        if (len == 7) {
            // "BBBRRTT" format (e.g. "0010282")
            let bStr = String.slice(start = 0, end = 3, clean);
            let rStr = String.slice(start = 3, end = 5, clean);
            let tStr = String.slice(start = 5, end = 7, clean);
            match (Int32.fromString(bStr), Int32.fromString(rStr), Int32.fromString(tStr)) {
                case (Some(b), Some(r), Some(t)) => Some({ bay = b, row = r, tier = t })
                case _ => None
            }
        } else if (len == 6) {
            // "BBRRTT" format (e.g. "010282")
            let bStr = String.slice(start = 0, end = 2, clean);
            let rStr = String.slice(start = 2, end = 4, clean);
            let tStr = String.slice(start = 4, end = 6, clean);
            match (Int32.fromString(bStr), Int32.fromString(rStr), Int32.fromString(tStr)) {
                case (Some(b), Some(r), Some(t)) => Some({ bay = b, row = r, tier = t })
                case _ => None
            }
        } else None
    }

    /// Parses a single EQD container loop from BAPLIE segments.
    pub def parseContainerLoop(loopSegments: List[EdiSegment]): Option[BaplieContainer] = {
        match findFirst("EQD", loopSegments) {
            case Some(eqd) => {
                let cid = match getComponent(2, 1, eqd) { case Some(id) => id case None => "UNKNOWN" };
                let isoType = match getComponent(2, 2, eqd) { case Some(t) => t case None => "42G1" };

                // LOC+147 for stowage location
                let locSegs = findAll("LOC", loopSegments);
                let optCell = List.foldLeft((acc, loc) -> {
                    match acc {
                        case Some(_) => acc
                        case None => {
                            let locQual = getComponent(1, 1, loc);
                            if (locQual == Some("147")) {
                                match getComponent(2, 1, loc) {
                                    case Some(brt) => parseBrtCell(brt)
                                    case None => None
                                }
                            } else None
                        }
                    }
                }, None, locSegs);

                // MEA for gross weight
                let meaSegs = findAll("MEA", loopSegments);
                let wtTonnes = List.foldLeft((acc, mea) -> {
                    match getComponent(3, 2, mea) {
                        case Some(valStr) => {
                            let unit = getComponent(3, 1, mea);
                            let num = match Float64.fromString(valStr) { case Some(v) => v case None => 0.0 };
                            if (unit == Some("KGM")) num / 1000.0
                            else if (unit == Some("TNE") or unit == Some("TON")) num
                            else num
                        }
                        case None => acc
                    }
                }, 20.0, meaSegs);

                // Discharge port LOC+11
                let pod = List.foldLeft((acc, loc) -> {
                    if (getComponent(1, 1, loc) == Some("11")) {
                        match getComponent(2, 1, loc) { case Some(p) => p case None => acc }
                    } else acc
                }, "UNSET", locSegs);

                // Loading port LOC+9
                let pol = List.foldLeft((acc, loc) -> {
                    if (getComponent(1, 1, loc) == Some("9")) {
                        match getComponent(2, 1, loc) { case Some(p) => p case None => acc }
                    } else acc
                }, "UNSET", locSegs);

                // Reefer temperature TMP+2
                let optTmp = findFirst("TMP", loopSegments);
                let (isReefer, reeferTemp) = match optTmp {
                    case Some(tmp) => {
                        let tempVal = match getComponent(2, 1, tmp) {
                            case Some(ts) => Float64.fromString(ts)
                            case None => None
                        };
                        (true, tempVal)
                    }
                    case None => (false, None)
                };

                // Dangerous goods DGS
                let optDgs = findFirst("DGS", loopSegments);
                let (hazClass, unNum) = match optDgs {
                    case Some(dgs) => {
                        let cStr = getComponent(2, 1, dgs);
                        let uStr = getComponent(3, 1, dgs);
                        let hClass = match cStr {
                            case Some("3") => Some(ImdgClass.Class3)
                            case Some("8") => Some(ImdgClass.Class8)
                            case Some("2.1") => Some(ImdgClass.Class2_1)
                            case Some("1.1") => Some(ImdgClass.Class1_1)
                            case _ => Some(ImdgClass.Class9)
                        };
                        let uNum = match uStr { case Some(us) => Int32.fromString(us) case None => None };
                        (hClass, uNum)
                    }
                    case None => (None, None)
                };

                match optCell {
                    case Some(cell) => Some({
                        containerId = cid,
                        isoType = isoType,
                        cell = cell,
                        grossWeightTonnes = wtTonnes,
                        portOfLoading = pol,
                        portOfDischarge = pod,
                        isReefer = isReefer,
                        reeferTempCelsius = reeferTemp,
                        hazmatClass = hazClass,
                        unNumber = unNum
                    })
                    case None => None
                }
            }
            case None => None
        }
    }

    /// Parses an entire SMDG BAPLIE EDIFACT string into structured BaplieBayplan.
    pub def parseBaplie(rawEdi: String): Option[BaplieBayplan] = {
        let segments = parseEdifact(rawEdi);

        let optTdt = findFirst("TDT", segments);
        let voyage = match optTdt {
            case Some(tdt) => match getComponent(2, 1, tdt) { case Some(v) => v case None => "UNKNOWN" }
            case None => "UNKNOWN"
        };
        let callSign = match optTdt {
            case Some(tdt) => match getComponent(8, 1, tdt) { case Some(cs) => cs case None => "" }
            case None => ""
        };
        let vesselName = match optTdt {
            case Some(tdt) => match getComponent(9, 1, tdt) {
                case Some(vn) => vn
                case None => match getComponent(8, 5, tdt) {
                    case Some(vn2) => vn2
                    case None => "VESSEL"
                }
            }
            case None => "VESSEL"
        };

        let optUnb = findFirst("UNB", segments);
        let sender = match optUnb {
            case Some(unb) => match getComponent(2, 1, unb) { case Some(s) => s case None => "" }
            case None => ""
        };

        let containerLoops = groupByTrigger("EQD", segments);
        let parsedContainers = List.filterMap(parseContainerLoop, containerLoops);

        Some({
            vesselName = vesselName,
            callSign = callSign,
            voyageNumber = voyage,
            senderId = sender,
            containers = parsedContainers
        })
    }
}
