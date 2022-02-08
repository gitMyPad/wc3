scope SentinelsOfEvolution

private struct S extends array
    private static race   FACTION_RACE          = RACE_NIGHTELF
    private static string FACTION_NAME          = "Sentinels of Evolution"
    private static string FACTION_DISPLAY       = "war3mapImported\\nightelfseal.blp"
    private static string FACTION_PLAYLIST      = "Custom\\Music\\World of Warcaft - Cataclysm OST - Nightsong Extended.mp3;Sound\\Music\\mp3Music\\NagaTheme.mp3;Sound\\Music\\mp3Music\\Comradeship.mp3;Sound\\Music\\mp3Music\\NightElfX1.mp3"

    private static integer FACTION_HALL         = 'e100'
    private static integer FACTION_WORKER       = 'e003'
    private static string FACTION_DESCRIPTION   = "A Multiversal faction of overseers, watching over half of all fictional worlds. " + /*
                                               */ "\nLed by Mal'furion from an alternate timeline in the 10,000 years hereafter, this " + /*
                                               */ "faction seeks to preserve the flow of history within each fictional world."
                                               
    private static method initTechtree takes CustomRace faction returns nothing
        call faction.addUnit('e003')
        call faction.addUnit('e000')
        call faction.addUnit('e001')
        call faction.addUnit('e002')
        call faction.addUnit('e004')
        call faction.addUnit('e005')
        call faction.addUnit('e006')
        
        call faction.addHall('e100')
        call faction.addHall('e106')
        call faction.addHall('e107')
        
        call faction.addHero('E007')

        call faction.addStructure('e100')
        call faction.addStructure('e101')
        call faction.addStructure('e102')
        call faction.addStructure('e103')
        call faction.addStructure('e104')
        call faction.addStructure('e106')
        call faction.addStructure('e107')
    endmethod
    
    implement CustomRaceTemplate
endstruct

endscope