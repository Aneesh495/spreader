// Spreader: Container Terminal Operating System
// SMDG BAPLIE 2.2 / 3.1 Electronic Bayplan Message Generator

pub mod Edi.BaplieGenerator {
    use Model.Coordinates.ShipCell;
    use Model.HazmatTypes.ImdgClass;
    use Edi.BaplieParser.{BaplieBayplan, BaplieContainer};

    /// Formats an ISO 9711 ShipCell into standard 7-digit zero-padded "BBBRRTT" string.
    pub def formatBrt(cell: ShipCell): String = {
        let bStr = if (cell#bay < 10) "00${cell#bay}" else if (cell#bay < 100) "0${cell#bay}" else "${cell#bay}";
        let rStr = if (cell#row < 10) "0${cell#row}" else "${cell#row}";
        let tStr = if (cell#tier < 10) "0${cell#tier}" else "${cell#tier}";
        "${bStr}${rStr}${tStr}"
    }

    /// Formats IMDG class to EDIFACT code string.
    def formatImdgClass(cls: ImdgClass): String = {
        match cls {
            case ImdgClass.Class1_1 => "1.1"
            case ImdgClass.Class1_2 => "1.2"
            case ImdgClass.Class1_3 => "1.3"
            case ImdgClass.Class1_4 => "1.4"
            case ImdgClass.Class1_5 => "1.5"
            case ImdgClass.Class1_6 => "1.6"
            case ImdgClass.Class2_1 => "2.1"
            case ImdgClass.Class2_2 => "2.2"
            case ImdgClass.Class2_3 => "2.3"
            case ImdgClass.Class3 => "3"
            case ImdgClass.Class4_1 => "4.1"
            case ImdgClass.Class4_2 => "4.2"
            case ImdgClass.Class4_3 => "4.3"
            case ImdgClass.Class5_1 => "5.1"
            case ImdgClass.Class5_2 => "5.2"
            case ImdgClass.Class6_1 => "6.1"
            case ImdgClass.Class6_2 => "6.2"
            case ImdgClass.Class7 => "7"
            case ImdgClass.Class8 => "8"
            case ImdgClass.Class9 => "9"
        }
    }

    /// Generates full SMDG BAPLIE EDIFACT message text from bayplan model.
    pub def generateBaplie(bayplan: BaplieBayplan, msgRef: String): String = {
        let una = "UNA:+.? '\n";
        let unb = "UNB+UNOA:2+SPREADER+${bayplan#senderId}+261118:1200+${msgRef}'\n";
        let unh = "UNH+1+BAPLIE:D:95B:UN:SMDG22'\n";
        let bgm = "BGM+BAY+${bayplan#voyageNumber}+9'\n";
        let tdt = "TDT+20+${bayplan#voyageNumber}+1++MSK:172:20+++${bayplan#callSign}:103::${bayplan#callSign}+${bayplan#vesselName}'\n";

        let headerSegs = unh :: bgm :: tdt :: Nil;

        // Container loops
        let containerSegs = List.flatMap(c -> {
            let eqd = "EQD+CN+${c#containerId}+${c#isoType}:102:5++4'\n";
            let locPos = "LOC+147+${formatBrt(c#cell)}:139:125'\n";
            let kg = Float64.round(c#grossWeightTonnes * 1000.0);
            let kgStr = "${kg}";
            let cleanKg = if (String.endsWith(suffix = ".0", kgStr))
                String.slice(start = 0, end = String.length(kgStr) - 2, kgStr)
            else kgStr;
            let mea = "MEA+WT++KGM:${cleanKg}'\n";
            let locPod = "LOC+11+${c#portOfDischarge}:139:6'\n";

            let optTmp = if (c#isReefer) {
                let tempStr = match c#reeferTempCelsius {
                    case Some(t) => "${t}"
                    case None => "-18.0"
                };
                ("TMP+2+${tempStr}:CEL'\n") :: Nil
            } else Nil;

            let optDgs = match (c#hazmatClass, c#unNumber) {
                case (Some(hz), Some(un)) => ("DGS+IMD+${formatImdgClass(hz)}+${un}'\n") :: Nil
                case (Some(hz), None) => ("DGS+IMD+${formatImdgClass(hz)}'\n") :: Nil
                case _ => Nil
            };

            List.flatten((eqd :: locPos :: mea :: locPod :: Nil) :: optTmp :: optDgs :: Nil)
        }, bayplan#containers);

        let totalSegCount = List.length(headerSegs) + List.length(containerSegs) + 1; // +1 for UNT
        let unt = "UNT+${totalSegCount}+1'\n";
        let unz = "UNZ+1+${msgRef}'\n";

        let allBody = List.flatten(headerSegs :: containerSegs :: (unt :: Nil) :: Nil);
        let bodyText = List.foldLeft((acc, s) -> "${acc}${s}", "", allBody);

        "${una}${unb}${bodyText}${unz}"
    }
}
