// Spreader: Container Terminal Operating System
// EDIFACT Segment Navigation, Loop Grouping, and Composite Extraction Utilities

pub mod Edi.SegmentNav {
    use Edi.Tokenizer.EdiSegment;

    /// Finds the first segment matching a tag in a segment stream.
    pub def findFirst(tag: String, segments: List[EdiSegment]): Option[EdiSegment] = {
        List.find(s -> s#tag == tag, segments)
    }

    /// Filters all segments matching a tag.
    pub def findAll(tag: String, segments: List[EdiSegment]): List[EdiSegment] = {
        List.filter(s -> s#tag == tag, segments)
    }

    /// Extracts composite element at 1-based index (matching standard EDIFACT specification).
    pub def getElement(index1Based: Int32, seg: EdiSegment): Option[List[String]] = {
        let idx0 = index1Based - 1;
        if (idx0 < 0 or idx0 >= List.length(seg#elements)) None
        else match List.drop(idx0, seg#elements) {
            case elem :: _ => Some(elem)
            case Nil => None
        }
    }

    /// Extracts individual component at 1-based element and 1-based component index.
    pub def getComponent(elemIndex1Based: Int32, compIndex1Based: Int32, seg: EdiSegment): Option[String] = {
        match getElement(elemIndex1Based, seg) {
            case Some(elem) => {
                let compIdx0 = compIndex1Based - 1;
                if (compIdx0 < 0 or compIdx0 >= List.length(elem)) None
                else match List.drop(compIdx0, elem) {
                    case c :: _ => Some(c)
                    case Nil => None
                }
            }
            case None => None
        }
    }

    /// Groups a flat EDIFACT stream into hierarchical loops based on a triggering tag (e.g. "EQD").
    pub def groupByTrigger(triggerTag: String, segments: List[EdiSegment]): List[List[EdiSegment]] = {
        def loop(rem: List[EdiSegment], curGroup: List[EdiSegment], acc: List[List[EdiSegment]]): List[List[EdiSegment]] = {
            match rem {
                case Nil => {
                    if (List.isEmpty(curGroup)) List.reverse(acc)
                    else List.reverse(List.reverse(curGroup) :: acc)
                }
                case s :: rest => {
                    if (s#tag == triggerTag) {
                        if (List.isEmpty(curGroup))
                            loop(rest, s :: Nil, acc)
                        else
                            loop(rest, s :: Nil, List.reverse(curGroup) :: acc)
                    } else {
                        if (List.isEmpty(curGroup))
                            loop(rest, curGroup, acc) // Skip pre-trigger header segments
                        else
                            loop(rest, s :: curGroup, acc)
                    }
                }
            }
        };
        loop(segments, Nil, Nil)
    }
}
