// Spreader: Container Terminal Operating System
// ISO 6346 Container Model and Core Equipment Types

pub mod Model.Types {

    /// ISO 6346 equipment category identifier.
    /// 'U' for all freight containers, 'J' for detachable equipment,
    /// 'Z' for trailers and chassis.
    pub enum EquipmentCategory with Eq, Order, ToString {
        case FreightContainer,
        case DetachableEquipment,
        case TrailerOrChassis
    }

    /// Container nominal length.
    pub enum ContainerLength with Eq, Order, ToString {
        case TwentyFoot,
        case FortyFoot,
        case FortyFiveFoot
    }

    /// Container nominal height.
    pub enum ContainerHeight with Eq, Order, ToString {
        case StandardHeight, // 8ft 6in (2.59m)
        case HighCube,       // 9ft 6in (2.89m)
        case HalfHeight      // 4ft 3in (1.30m)
    }

    /// Container body and thermal specification type.
    pub enum ContainerType with Eq, Order, ToString {
        case GeneralDry,
        case HighCubeDry,
        case Refrigerated(Float64), // Setpoint temperature in Celsius
        case TankLiquid,
        case OpenTop,
        case FlatRack,
        case BulkDry
    }

    /// Logistics dispatch status of a container within the terminal.
    pub enum ContainerStatus with Eq, Order, ToString {
        case InboundVessel,
        case YardStacked,
        case OutboundVessel,
        case GateInPending,
        case GateOutLoaded
    }

    /// Fully specified ISO 6346 container descriptor.
    pub type alias Container = {
        id = String,
        length = ContainerLength,
        height = ContainerHeight,
        typeSpec = ContainerType,
        tareWeightKg = Float64,
        payloadWeightKg = Float64,
        status = ContainerStatus,
        sealNumber = Option[String]
    }

    /// Computes total gross weight in metric tonnes.
    pub def grossWeightTonnes(c: Container): Float64 =
        (c#tareWeightKg + c#payloadWeightKg) / 1000.0

    /// Computes total gross weight in kilograms.
    pub def grossWeightKg(c: Container): Float64 =
        c#tareWeightKg + c#payloadWeightKg

    /// Extracts container identification number.
    pub def containerId(c: Container): String =
        c#id

    /// Extracts container length.
    pub def length(c: Container): ContainerLength =
        c#length

    /// Extracts container type.
    pub def containerType(c: Container): ContainerType =
        c#typeSpec

    /// Checks if a container is a reefer requiring power plug connection.
    pub def isReefer(c: Container): Bool = match c#typeSpec {
        case ContainerType.Refrigerated(_) => true
        case _ => false
    }

    /// ISO 6346 letter-to-value conversion table for check digit verification.
    /// Letters A-Z map to integer values 10-38, skipping multiples of 11 (11, 22, 33).
    pub def letterValue(ch: Char): Int32 = match ch {
        case 'A' => 10
        case 'B' => 12
        case 'C' => 13
        case 'D' => 14
        case 'E' => 15
        case 'F' => 16
        case 'G' => 17
        case 'H' => 18
        case 'I' => 19
        case 'J' => 20
        case 'K' => 21
        case 'L' => 23
        case 'M' => 24
        case 'N' => 25
        case 'O' => 26
        case 'P' => 27
        case 'Q' => 28
        case 'R' => 29
        case 'S' => 30
        case 'T' => 31
        case 'U' => 32
        case 'V' => 34
        case 'W' => 35
        case 'X' => 36
        case 'Y' => 37
        case 'Z' => 38
        case '0' => 0
        case '1' => 1
        case '2' => 2
        case '3' => 3
        case '4' => 4
        case '5' => 5
        case '6' => 6
        case '7' => 7
        case '8' => 8
        case '9' => 9
        case _   => -1
    }

    /// Integer power function for 2^n.
    def pow2(n: Int32): Int32 = {
        if (n <= 0) 1
        else 2 * pow2(n - 1)
    }

    /// Calculates ISO 6346 check digit for the first 10 characters.
    /// Check digit is (sum_{i=0..9} value(char_i) * 2^i) mod 11 mod 10.
    pub def calculateIsoCheckDigit(firstTen: String): Option[Int32] = {
        let chars = String.toList(firstTen);
        if (List.length(chars) != 10) None
        else {
            let indexed = List.zip(chars, List.range(0, 10));
            let folder = (acc: Option[Int32], pair: (Char, Int32)) -> match acc {
                case None => None
                case Some(sum) => {
                    let (ch, idx) = pair;
                    let v = letterValue(ch);
                    if (v < 0) None
                    else Some(sum + v * pow2(idx))
                }
            };
            match List.foldLeft(folder, Some(0), indexed) {
                case None => None
                case Some(total) => {
                    let rem = Int32.modulo(total, 11);
                    Some(Int32.modulo(rem, 10))
                }
            }
        }
    }

    /// Verifies if an 11-character container number has a valid ISO 6346 check digit.
    pub def isValidIso6346(id: String): Bool = {
        let chars = String.toList(id);
        if (List.length(chars) != 11) false
        else {
            let prefix = String.slice(start = 0, end = 10, id);
            let checkChar = String.charAt(10, id);
            let expectedCheckDigit = match checkChar {
                case '0' => 0
                case '1' => 1
                case '2' => 2
                case '3' => 3
                case '4' => 4
                case '5' => 5
                case '6' => 6
                case '7' => 7
                case '8' => 8
                case '9' => 9
                case _   => -1
            };
            if (expectedCheckDigit < 0) false
            else match calculateIsoCheckDigit(prefix) {
                case Some(cd) => cd == expectedCheckDigit
                case None     => false
            }
        }
    }
}
