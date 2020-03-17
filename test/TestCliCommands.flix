// Spreader: Container Terminal Operating System
// Test Suite for CLI Subcommand Handlers and Output Generation

mod TestCliCommands {

    use Cli.Args.SubCommand
    use Cli.Commands

    @Test
    def testVersionAndHelpCommands(): Unit \ Assert = {
        let vOut = Commands.execute(SubCommand.CmdVersion);
        Assert.assertTrue(String.contains(substr = "0.1.0", vOut));

        let hOut = Commands.execute(SubCommand.CmdHelp);
        Assert.assertTrue(String.contains(substr = "Usage: spreader", hOut))
    }

    @Test
    def testBenchmarkCommand(): Unit \ Assert = {
        let benchOut = Commands.execute(SubCommand.CmdBenchmark(Nil));
        Assert.assertTrue(String.contains(substr = "PORT CALL TURNAROUND BENCHMARK", benchOut));
        Assert.assertTrue(String.contains(substr = "14000 TEU", benchOut));
        Assert.assertTrue(String.contains(substr = "1200", benchOut));
        Assert.assertTrue(String.contains(substr = "GMPH", benchOut))
    }

    @Test
    def testStabilityCommand(): Unit \ Assert = {
        let stabOut = Commands.execute(SubCommand.CmdStability(Nil));
        Assert.assertTrue(String.contains(substr = "VESSEL HYDROSTATICS", stabOut));
        Assert.assertTrue(String.contains(substr = "Transverse GM_T", stabOut));
        Assert.assertTrue(String.contains(substr = "Draft Amidships", stabOut))
    }

    @Test
    def testCraneCommand(): Unit \ Assert = {
        let splitOut = Commands.execute(SubCommand.CmdCrane("split", Nil));
        Assert.assertTrue(String.contains(substr = "MULTI-CRANE BAY SPLIT", splitOut));

        let twinOut = Commands.execute(SubCommand.CmdCrane("twinlift", Nil));
        Assert.assertTrue(String.contains(substr = "TWIN-LIFT", twinOut))
    }

    @Test
    def testRenderCommand(): Unit \ Assert = {
        let bayOut = Commands.execute(SubCommand.CmdRender("bay", Nil));
        Assert.assertTrue(String.contains(substr = "BAY 01", bayOut));

        let yardOut = Commands.execute(SubCommand.CmdRender("yard", Nil));
        Assert.assertTrue(String.contains(substr = "YARD BLOCK B01", yardOut))
    }

    @Test
    def testUnknownCommand(): Unit \ Assert = {
        let unknownOut = Commands.execute(SubCommand.CmdUnknown("badcmd"));
        Assert.assertTrue(String.contains(substr = "Unknown command: 'badcmd'", unknownOut))
    }
}
