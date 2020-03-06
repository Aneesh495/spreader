// Spreader: Container Terminal Operating System
// Test Suite for CLI Argument Parsing and Subcommand Routing

mod TestCliArgs {

    use Cli.Args
    use Cli.Args.SubCommand

    @Test
    def testEmptyAndHelpArgs(): Unit \ Assert = {
        Assert.assertEq(expected = SubCommand.CmdHelp, Args.parse(Nil));
        Assert.assertEq(expected = SubCommand.CmdHelp, Args.parse("--help" :: Nil));
        Assert.assertEq(expected = SubCommand.CmdHelp, Args.parse("-h" :: Nil));
        Assert.assertEq(expected = SubCommand.CmdHelp, Args.parse("help" :: Nil))
    }

    @Test
    def testVersionArgs(): Unit \ Assert = {
        Assert.assertEq(expected = SubCommand.CmdVersion, Args.parse("--version" :: Nil));
        Assert.assertEq(expected = SubCommand.CmdVersion, Args.parse("-v" :: Nil));
        Assert.assertEq(expected = SubCommand.CmdVersion, Args.parse("version" :: Nil))
    }

    @Test
    def testSubcommands(): Unit \ Assert = {
        let cmdBaplie = Args.parse("baplie" :: "parse" :: "voyage1.edi" :: Nil);
        Assert.assertEq(expected = SubCommand.CmdBaplie("parse", "voyage1.edi" :: Nil), cmdBaplie);

        let cmdCoprar = Args.parse("coprar" :: "discharge" :: "coprar.edi" :: Nil);
        Assert.assertEq(expected = SubCommand.CmdCoprar("discharge", "coprar.edi" :: Nil), cmdCoprar);

        let cmdStab = Args.parse("stability" :: "--anti-heel" :: Nil);
        Assert.assertEq(expected = SubCommand.CmdStability("--anti-heel" :: Nil), cmdStab);

        let cmdYard = Args.parse("yard" :: "reshuffle" :: "MSKU1234567" :: Nil);
        Assert.assertEq(expected = SubCommand.CmdYard("reshuffle", "MSKU1234567" :: Nil), cmdYard);

        let cmdCrane = Args.parse("crane" :: "twinlift" :: Nil);
        Assert.assertEq(expected = SubCommand.CmdCrane("twinlift", Nil), cmdCrane);

        let cmdBench = Args.parse("benchmark" :: Nil);
        Assert.assertEq(expected = SubCommand.CmdBenchmark(Nil), cmdBench);

        let cmdRender = Args.parse("render" :: "bay" :: "3" :: Nil);
        Assert.assertEq(expected = SubCommand.CmdRender("bay", "3" :: Nil), cmdRender);

        let cmdUnknown = Args.parse("invalidCommand" :: Nil);
        Assert.assertEq(expected = SubCommand.CmdUnknown("invalidCommand"), cmdUnknown)
    }

    @Test
    def testUsageString(): Unit \ Assert = {
        let helpText = Args.usage();
        Assert.assertTrue(String.contains(substr = "spreader <command>", helpText));
        Assert.assertTrue(String.contains(substr = "baplie", helpText));
        Assert.assertTrue(String.contains(substr = "stability", helpText));
        Assert.assertTrue(String.contains(substr = "benchmark", helpText))
    }
}
