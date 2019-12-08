// Spreader: Container Terminal Operating System
// Pure ISO 9735 UN/EDIFACT Lexical Stream Tokenizer and Escape Processor

pub mod Edi.Tokenizer {

    /// UN/EDIFACT Service String Advice delimiter configuration.
    pub type alias EdiDelimiters = {
        componentSeparator = Char,   // Default ':'
        elementSeparator = Char,     // Default '+'
        decimalNotation = Char,      // Default '.'
        releaseIndicator = Char,     // Default '?'
        segmentTerminator = Char     // Default '\''
    }

    /// Standard default EDIFACT delimiters.
    pub def defaultDelimiters(): EdiDelimiters = {
        componentSeparator = ':',
        elementSeparator = '+',
        decimalNotation = '.',
        releaseIndicator = '?',
        segmentTerminator = '\''
    }

    /// A parsed EDIFACT segment containing a 3-character tag and composite elements.
    pub type alias EdiSegment = {
        tag = String,
        elements = List[List[String]] // Each data element is a composite list of component values
    }

    /// Helper converting list of characters to string.
    def charListToString(chars: List[Char]): String = {
        List.foldLeft((acc, c) -> "${acc}${c}", "", chars)
    }

    /// Parses the optional UNA header if present, returning (delimiters, remainingText).
    pub def parseUna(input: String): (EdiDelimiters, String) = {
        let trimmed = String.trim(input);
        if (String.startsWith(prefix = "UNA", trimmed) and String.length(trimmed) >= 9) {
            let compSep = String.charAt(3, trimmed);
            let elemSep = String.charAt(4, trimmed);
            let decNot = String.charAt(5, trimmed);
            let relInd = String.charAt(6, trimmed);
            let segTerm = String.charAt(8, trimmed);
            let delims: EdiDelimiters = {
                componentSeparator = compSep,
                elementSeparator = elemSep,
                decimalNotation = decNot,
                releaseIndicator = relInd,
                segmentTerminator = segTerm
            };
            let rem = String.slice(start = 9, end = String.length(trimmed), trimmed);
            (delims, rem)
        } else {
            (defaultDelimiters(), trimmed)
        }
    }

    /// Pure recursive character-by-character scanner that respects release escape character '?'.
    pub def tokenizeSegments(rawText: String, delims: EdiDelimiters): List[EdiSegment] = {
        let chars = String.toList(rawText);

        def scan(
            cs: List[Char],
            isEscaped: Bool,
            curToken: List[Char],
            curElem: List[String],
            curElements: List[List[String]],
            segAcc: List[EdiSegment]
        ): List[EdiSegment] = {
            match cs {
                case Nil => {
                    let finalTok = charListToString(List.reverse(curToken));
                    let finalElem = if (String.isEmpty(finalTok) and List.isEmpty(curElem)) curElem else List.reverse(finalTok :: curElem);
                    let finalElements = if (List.isEmpty(finalElem) and List.isEmpty(curElements)) curElements else List.reverse(finalElem :: curElements);
                    match finalElements {
                        case tagElem :: rest => {
                            let tag = match List.head(tagElem) { case Some(t) => String.trim(t) case None => "" };
                            if (String.length(tag) > 0)
                                List.reverse({ tag = tag, elements = rest } :: segAcc)
                            else
                                List.reverse(segAcc)
                        }
                        case Nil => List.reverse(segAcc)
                    }
                }
                case c :: cRest => {
                    if (isEscaped) {
                        scan(cRest, false, c :: curToken, curElem, curElements, segAcc)
                    } else if (c == delims#releaseIndicator) {
                        scan(cRest, true, curToken, curElem, curElements, segAcc)
                    } else if (c == delims#componentSeparator) {
                        let tokStr = charListToString(List.reverse(curToken));
                        scan(cRest, false, Nil, tokStr :: curElem, curElements, segAcc)
                    } else if (c == delims#elementSeparator) {
                        let tokStr = charListToString(List.reverse(curToken));
                        let fullElem = List.reverse(tokStr :: curElem);
                        scan(cRest, false, Nil, Nil, fullElem :: curElements, segAcc)
                    } else if (c == delims#segmentTerminator) {
                        let tokStr = charListToString(List.reverse(curToken));
                        let fullElem = List.reverse(tokStr :: curElem);
                        let allElems = List.reverse(fullElem :: curElements);
                        match allElems {
                            case tagElem :: rest => {
                                let tag = match List.head(tagElem) { case Some(t) => String.trim(t) case None => "" };
                                if (String.length(tag) > 0) {
                                    let seg: EdiSegment = { tag = tag, elements = rest };
                                    scan(cRest, false, Nil, Nil, Nil, seg :: segAcc)
                                } else {
                                    scan(cRest, false, Nil, Nil, Nil, segAcc)
                                }
                            }
                            case Nil => scan(cRest, false, Nil, Nil, Nil, segAcc)
                        }
                    } else if (c == '\r' or c == '\n') {
                        scan(cRest, false, curToken, curElem, curElements, segAcc)
                    } else {
                        scan(cRest, false, c :: curToken, curElem, curElements, segAcc)
                    }
                }
            }
        };

        scan(chars, false, Nil, Nil, Nil, Nil)
    }

    /// Convenience high-level tokenizer handling optional UNA header.
    pub def parseEdifact(input: String): List[EdiSegment] = {
        let (delims, body) = parseUna(input);
        tokenizeSegments(body, delims)
    }
}
