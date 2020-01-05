// Spreader: Container Terminal Operating System
// SMDG MOVINS Electronic Stowage Instruction Message Generator

pub mod Edi.MovinsGenerator {
    use Model.Coordinates.ShipCell;
    use Edi.BaplieGenerator.formatBrt;

    /// Single crane operational move instruction within MOVINS.
    pub type alias MovinsInstruction = {
        sequenceIndex = Int32,
        craneId = String,
        containerId = String,
        isoType = String,
        targetCell = ShipCell,
        grossWeightTonnes = Float64,
        isDischarge = Bool
    }

    /// Generates standard SMDG MOVINS EDIFACT message text.
    pub def generateMovins(
        instructions: List[MovinsInstruction],
        vesselName: String,
        callSign: String,
        voyageNumber: String,
        msgRef: String
    ): String = {
        let una = "UNA:+.? '\n";
        let unb = "UNB+UNOA:2+SPREADER+CARRIER+261118:1500+${msgRef}'\n";
        let unh = "UNH+1+MOVINS:D:95B:UN:SMDG20'\n";
        let bgm = "BGM+1+MOV_${voyageNumber}+9'\n";
        let tdt = "TDT+20+${voyageNumber}+1++MSK:172:20+++${callSign}:103::${callSign}+${vesselName}'\n";

        let headerSegs = unh :: bgm :: tdt :: Nil;

        let moveSegs = List.flatMap(inst -> {
            let moveCode = if (inst#isDischarge) "6" else "4"; // 6 = Discharge, 4 = Load
            let eqd = "EQD+CN+${inst#containerId}+${inst#isoType}:102:5++${moveCode}'\n";
            let loc = "LOC+147+${formatBrt(inst#targetCell)}:139:125'\n";
            let kg = Float64.round(inst#grossWeightTonnes * 1000.0);
            let kgStr = "${kg}";
            let cleanKg = if (String.endsWith(suffix = ".0", kgStr))
                String.slice(start = 0, end = String.length(kgStr) - 2, kgStr)
            else kgStr;
            let mea = "MEA+WT++KGM:${cleanKg}'\n";
            let ftx = "FTX+AAI+++SEQ:${inst#sequenceIndex} CRANE:${inst#craneId}'\n";
            eqd :: loc :: mea :: ftx :: Nil
        }, instructions);

        let totalSegCount = List.length(headerSegs) + List.length(moveSegs) + 1; // +1 for UNT
        let unt = "UNT+${totalSegCount}+1'\n";
        let unz = "UNZ+1+${msgRef}'\n";

        let allBody = List.flatten(headerSegs :: moveSegs :: (unt :: Nil) :: Nil);
        let bodyText = List.foldLeft((acc, s) -> "${acc}${s}", "", allBody);

        "${una}${unb}${bodyText}${unz}"
    }
}
