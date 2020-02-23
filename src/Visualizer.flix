// Spreader: Container Terminal Operating System
// Root Module for Visualizer and Terminal Cross-Section Subsystem

pub mod Visualizer {

    /// ANSI Terminal Escape Sequences for rich console telemetry.
    pub def reset(): String = "\u001b[0m"
    pub def bold(): String = "\u001b[1m"
    pub def dim(): String = "\u001b[2m"
    pub def underline(): String = "\u001b[4m"

    pub def fgRed(): String = "\u001b[31m"
    pub def fgGreen(): String = "\u001b[32m"
    pub def fgYellow(): String = "\u001b[33m"
    pub def fgBlue(): String = "\u001b[34m"
    pub def fgMagenta(): String = "\u001b[35m"
    pub def fgCyan(): String = "\u001b[36m"
    pub def fgWhite(): String = "\u001b[37m"

    pub def bgBlue(): String = "\u001b[44m"
    pub def bgDark(): String = "\u001b[40m"
    pub def bgYellow(): String = "\u001b[43m"
    pub def bgRed(): String = "\u001b[41m"

    /// Wraps text with ANSI color and resets style afterward.
    pub def colorize(text: String, ansiCode: String): String =
        "${ansiCode}${text}${reset()}"

    /// Strips ANSI escape codes from string to compute plain layout lengths.
    pub def stripAnsi(str: String): String = {
        // Pure parser: skip characters between ESC '\u001b' and 'm'
        let chars = String.toList(str);
        def loop(cs: List[Char], inEsc: Bool, acc: List[Char]): List[Char] = match cs {
            case Nil => List.reverse(acc)
            case '\u001b' :: rest => loop(rest, true, acc)
            case 'm' :: rest => if (inEsc) loop(rest, false, acc) else loop(rest, false, 'm' :: acc)
            case c :: rest => if (inEsc) loop(rest, true, acc) else loop(rest, false, c :: acc)
        };
        let cleaned = loop(chars, false, Nil);
        List.foldLeft((acc, c) -> "${acc}${c}", "", cleaned)
    }
}
