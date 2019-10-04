mod TestHazmat {
    use Model.HazmatTypes.{
        ImdgClass, PackingGroup, SegregationCategory, HazmatDeclaration,
        isExplosive, isFlammable, isTemperatureSensitive, classLabel
    };

    @Test
    def testExplosiveIdentification(): Unit \ Assert = {
        Assert.assertEq(expected = true, isExplosive(ImdgClass.Class1_1));
        Assert.assertEq(expected = true, isExplosive(ImdgClass.Class1_4));
        Assert.assertEq(expected = false, isExplosive(ImdgClass.Class3));
        Assert.assertEq(expected = false, isExplosive(ImdgClass.Class8))
    }

    @Test
    def testFlammableIdentification(): Unit \ Assert = {
        Assert.assertEq(expected = true, isFlammable(ImdgClass.Class2_1));
        Assert.assertEq(expected = true, isFlammable(ImdgClass.Class3));
        Assert.assertEq(expected = true, isFlammable(ImdgClass.Class4_1));
        Assert.assertEq(expected = false, isFlammable(ImdgClass.Class2_2));
        Assert.assertEq(expected = false, isFlammable(ImdgClass.Class8))
    }

    @Test
    def testTemperatureSensitivity(): Unit \ Assert = {
        Assert.assertEq(expected = true, isTemperatureSensitive(ImdgClass.Class5_2)); // Organic Peroxides
        Assert.assertEq(expected = true, isTemperatureSensitive(ImdgClass.Class4_1)); // Self-reactive
        Assert.assertEq(expected = false, isTemperatureSensitive(ImdgClass.Class5_1));
        Assert.assertEq(expected = false, isTemperatureSensitive(ImdgClass.Class9))
    }

    @Test
    def testHazmatDeclarationRecord(): Unit \ Assert = {
        let dec: HazmatDeclaration = {
            unNumber = 1942, // Ammonium nitrate
            primaryClass = ImdgClass.Class5_1,
            subsidiaryClasses = Nil,
            packingGroup = Some(PackingGroup.PackingGroupIII),
            flashPointCelsius = None,
            marinePollutant = false,
            limitedQuantity = false
        };
        Assert.assertEq(expected = 1942, dec#unNumber);
        Assert.assertEq(expected = false, dec#limitedQuantity);
        Assert.assertEq(expected = "5.1 (Oxidizing Substance)", classLabel(dec#primaryClass))
    }
}
