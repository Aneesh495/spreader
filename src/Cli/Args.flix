// Spreader: Container Terminal Operating System
// Command-Line Argument Lexer and Subcommand Parser

pub mod Cli.Args {

    /// Enumeration of all supported CLI subcommands.
    pub enum SubCommand with Eq, ToString {
        case CmdBaplie(String, List[String])
        case CmdCoprar(String, List[String])
        case CmdStability(List[String])
        case CmdYard(String, List[String])
        case CmdCrane(String, List[String])
        case CmdSim(List[String])
        case CmdBenchmark(List[String])
        case CmdRender(String, List[String])
        case CmdHelp
        case CmdVersion
        case CmdUnknown(String)
    }

    /// Parses command-line arguments into a structured SubCommand.
    pub def parse(args: List[String]): SubCommand = match args {
        case Nil => SubCommand.CmdHelp
        case "--help" :: _ => SubCommand.CmdHelp
        case "-h" :: _ => SubCommand.CmdHelp
        case "help" :: _ => SubCommand.CmdHelp
        case "--version" :: _ => SubCommand.CmdVersion
        case "-v" :: _ => SubCommand.CmdVersion
        case "version" :: _ => SubCommand.CmdVersion

        case "baplie" :: action :: rest => SubCommand.CmdBaplie(action, rest)
        case "baplie" :: Nil => SubCommand.CmdBaplie("help", Nil)

        case "coprar" :: action :: rest => SubCommand.CmdCoprar(action, rest)
        case "coprar" :: Nil => SubCommand.CmdCoprar("help", Nil)

        case "stability" :: rest => SubCommand.CmdStability(rest)

        case "yard" :: action :: rest => SubCommand.CmdYard(action, rest)
        case "yard" :: Nil => SubCommand.CmdYard("help", Nil)

        case "crane" :: action :: rest => SubCommand.CmdCrane(action, rest)
        case "crane" :: Nil => SubCommand.CmdCrane("help", Nil)

        case "sim" :: rest => SubCommand.CmdSim(rest)

        case "benchmark" :: rest => SubCommand.CmdBenchmark(rest)

        case "render" :: target :: rest => SubCommand.CmdRender(target, rest)
        case "render" :: Nil => SubCommand.CmdRender("help", Nil)

        case cmd :: _ => SubCommand.CmdUnknown(cmd)
    }

    /// Formats formatted command-line help text and command reference.
    pub def usage(): String =
        "Usage: spreader <command> [options]\n" +
        "\n" +
        "Maritime Container Terminal & Vessel Stowage Planning Engine\n" +
        "\n" +
        "Available Commands:\n" +
        "  baplie <parse|summary|validate> <file>   Process SMDG BAPLIE 2.2 / 3.1 bayplans\n" +
        "  coprar <parse|discharge|load> <file>     Process EDIFACT COPRAR manifests\n" +
        "  stability [report]                       Calculate GM_T, trim, and shear force\n" +
        "  yard <block|reshuffle> [args]            Inspect yard blocks and reshuffle solver\n" +
        "  crane <twinlift|dualcycle|split> [args]  Optimize crane work queues and twin-lifts\n" +
        "  sim [options]                            Run discrete-event terminal simulation\n" +
        "  benchmark                                Run 14,000 TEU mega-vessel port turnaround\n" +
        "  render <bay|yard> [id]                   Render ANSI terminal visualizations\n" +
        "  version                                  Display version information\n" +
        "  help                                     Display this help guide\n"
}
