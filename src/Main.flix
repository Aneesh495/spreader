// Spreader: Container Terminal Operating System & Vessel Stowage Planning Engine
// Main CLI Entry Point

def main(): Unit \ IO = {
    let banner =
        "  ____  ____  ____  _____     _     ____  _____ ____  \n" +
        " / ___||  _ \\|  _ \\| ____|   / \\   |  _ \\| ____|  _ \\ \n" +
        " \\___ \\| |_) | |_) |  _|    / _ \\  | | | |  _| | |_) |\n" +
        "  ___) |  __/|  _ <| |___  / ___ \\ | |_| | |___|  _ < \n" +
        " |____/|_|   |_| \\_\\_____|/_/   \\_\\|____/|_____|_| \\_\\\n" +
        " Container Terminal Operating System & Stowage Planning Engine\n\n";

    println(banner);
    let output = Cli.Commands.execute(Cli.Args.SubCommand.CmdBenchmark(Nil));
    println(output)
}

/// Programmatic entry point for command-line arguments.
pub def runCli(args: List[String]): Unit \ IO = {
    let parsed = Cli.Args.parse(args);
    let output = Cli.Commands.execute(parsed);
    println(output)
}
