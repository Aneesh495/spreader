// Spreader: Container Terminal Operating System
// SMDG COPRAR Container Discharge and Loading Order EDIFACT Message Parser

pub mod Edi.CoprarParser {
    use Edi.Tokenizer.{EdiSegment, parseEdifact};
    use Edi.SegmentNav.{findFirst, findAll, getComponent, groupByTrigger};

    /// Nature of the terminal container work order.
    pub enum CoprarOrderType with Eq, Order, ToString {
        case DischargeOrder, // Inbound containers to be discharged from vessel
        case LoadingOrder    // Outbound containers to be loaded onto vessel
    }

    /// Single container entry within a COPRAR manifest.
    pub type alias CoprarItem = {
        containerId = String,
        isoType = String,
        isFull = Bool,
        grossWeightTonnes = Float64,
        portOfLoading = String,
        portOfDischarge = String,
        specialInstructions = Option[String]
    }

    /// Complete parsed COPRAR message manifest.
    pub type alias CoprarManifest = {
        orderType = CoprarOrderType,
        orderNumber = String,
        voyageNumber = String,
        vesselName = String,
        callSign = String,
        items = List[CoprarItem]
    }

    /// Parses a single container EQD loop from COPRAR message.
    pub def parseCoprarItem(loopSegs: List[EdiSegment]): Option[CoprarItem] = {
        match findFirst("EQD", loopSegs) {
            case Some(eqd) => {
                let cid = match getComponent(2, 1, eqd) { case Some(id) => id case None => "UNKNOWN" };
                let isoType = match getComponent(3, 1, eqd) {
                    case Some(t) => t
                    case None => match getComponent(2, 2, eqd) { case Some(t2) => t2 case None => "42G1" }
                };
                let fullEmpty = match getComponent(5, 1, eqd) {
                    case Some(fe) => Some(fe)
                    case None => match getComponent(4, 1, eqd) {
                        case Some(fe2) => Some(fe2)
                        case None => getComponent(3, 1, eqd)
                    }
                };
                let isFull = fullEmpty != Some("5"); // 5 is empty, 4 or unset is full/loaded

                let locSegs = findAll("LOC", loopSegs);
                let pod = List.foldLeft((acc, loc) -> {
                    if (getComponent(1, 1, loc) == Some("11") or getComponent(1, 1, loc) == Some("12")) {
                        match getComponent(2, 1, loc) { case Some(p) => p case None => acc }
                    } else acc
                }, "UNSET", locSegs);

                let pol = List.foldLeft((acc, loc) -> {
                    if (getComponent(1, 1, loc) == Some("9")) {
                        match getComponent(2, 1, loc) { case Some(p) => p case None => acc }
                    } else acc
                }, "UNSET", locSegs);

                let meaSegs = findAll("MEA", loopSegs);
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

                let optFtx = findFirst("FTX", loopSegs);
                let instructions = match optFtx {
                    case Some(ftx) => getComponent(4, 1, ftx)
                    case None => None
                };

                Some({
                    containerId = cid,
                    isoType = isoType,
                    isFull = isFull,
                    grossWeightTonnes = wtTonnes,
                    portOfLoading = pol,
                    portOfDischarge = pod,
                    specialInstructions = instructions
                })
            }
            case None => None
        }
    }

    /// Parses an entire COPRAR EDIFACT message text.
    pub def parseCoprar(rawEdi: String): Option[CoprarManifest] = {
        let segments = parseEdifact(rawEdi);

        let optBgm = findFirst("BGM", segments);
        let (orderType, orderNum) = match optBgm {
            case Some(bgm) => {
                let code = getComponent(1, 1, bgm);
                let num = match getComponent(2, 1, bgm) { case Some(n) => n case None => "ORDER001" };
                let oType = if (code == Some("44")) CoprarOrderType.LoadingOrder else CoprarOrderType.DischargeOrder;
                (oType, num)
            }
            case None => (CoprarOrderType.DischargeOrder, "ORDER001")
        };

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

        let loops = groupByTrigger("EQD", segments);
        let items = List.filterMap(parseCoprarItem, loops);

        Some({
            orderType = orderType,
            orderNumber = orderNum,
            voyageNumber = voyage,
            vesselName = vesselName,
            callSign = callSign,
            items = items
        })
    }
}
