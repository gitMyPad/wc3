do
    local tb                = getmetatable(CustomRaceSystem)
    local setupTable        = {
        unitSpacing             = 64.00,

        mineOffset              = 320.00,
        mineDeltaAngle          = 0.00,
        heroOffset              = 384.00,
        heroDeltaAngle          = 45.00,

        defXOffset              = 0.00,
        defYOffset              = -224.00,
        defHeroXOffset          = 0.00,
        defHeroYOffset          = 2.00,

        peonOffsetX             = {0.00, 1.00, -1.00,  0.60, -0.60},
        peonOffsetY             = {1.00, 0.15,  0.15, -1.00, -1.00},

        defPeonOffsetX          = {-2.00, -1.00, 0.00, 1.00, 2.00},
        defPeonOffsetY          = { 0.00,  0.00, 0.00, 0.00, 0.00},
    }
    setupTable.defHeroXOffset   = setupTable.defHeroXOffset*setupTable.unitSpacing
    setupTable.defHeroYOffset   = setupTable.defHeroYOffset*setupTable.unitSpacing

    setupTable.__index      = function(t, k)
        if type(k) == 'string' and k:sub(1,1) == '_' and k:sub(1,2) ~= '__' then
            return nil
        end
        return setupTable[k]
    end
    setupTable.__newindex   = function(t, k, v)
        if setupTable[k] then
            return
        end
        rawset(t, k, v)
    end
    setupTable.__metatable  = true
    CustomRaceSetup         = setmetatable({}, setupTable)

    local function isFunction(func)
        return type(func) == 'function' or 
             ((type(func) == 'table') and isFunction(getmetatable(func).__call))
    end
    function setupTable._getRandomHero(whichPlayer, heroLoc, factionList)
        if #factionList <= 0 then
            return 0
        end
        return factionList[math.random(1, #factionList)]
    end

    function setupTable.createSetupHelper(func, hallID, peonID, peonCount, offsetX, offsetY)
        peonCount   = peonCount or 5
        hallID      = (type(hallID) == 'string' and FourCC(hallID)) or hallID
        peonID      = (type(peonID) == 'string' and FourCC(peonID)) or peonID
        offsetX     = offsetX or setupTable.peonOffsetX
        offsetY     = offsetY or setupTable.peonOffsetY
        return function(whichPlayer, startLoc, mine, peonX, peonY)
            local hall  = CreateUnitAtLoc(whichPlayer, hallID, startLoc, bj_UNIT_FACING)
            func(whichPlayer, hall, mine, peonX, peonY)

            local iter  = 1
            while iter <= peonCount do
                if mine then
                    CreateUnit(whichPlayer, peonID, 
                               peonX + (offsetX[iter] or 0)*setupTable.unitSpacing,
                               peonY + (offsetY[iter] or 0)*setupTable.unitSpacing,
                               bj_UNIT_FACING)
                else
                    CreateUnit(whichPlayer, peonID, 
                               peonX + (setupTable.defPeonOffsetX[iter] or 0)*setupTable.unitSpacing,
                               peonY + (setupTable.defPeonOffsetY[iter] or 0)*setupTable.unitSpacing,
                               bj_UNIT_FACING)
                end
                iter = iter + 1
            end
        end
    end
    function setupTable.createSetup(func, preloader, faction)
        if not isFunction(func) then
            return nil
        end
        preloader   = preloader or ""
        return function(whichPlayer, startLoc, doHeroes, doCamera, doPreload)
            if (doPreload) then
                Preloader(preloader)
            end
            local mine          = MeleeFindNearestMine(startLoc, bj_MELEE_MINE_SEARCH_RADIUS)
            local peon          = {}
            local heroLoc   
            local nearMineLoc
            if mine ~= nil then
                local mineLoc   = GetUnitLoc(mine)
                heroLoc         = MeleeGetProjectedLoc(mineLoc, startLoc,
                                                       setupTable.heroOffset, setupTable.heroDeltaAngle)
                nearMineLoc     = MeleeGetProjectedLoc(mineLoc, startLoc,
                                                       setupTable.mineOffset, setupTable.mineDeltaAngle)
                peon.x          = GetLocationX(nearMineLoc)
                peon.y          = GetLocationY(nearMineLoc)
                RemoveLocation(mineLoc)
                RemoveLocation(nearMineLoc)
            else
                peon.x          = GetLocationX(startLoc) + setupTable.defXOffset
                peon.y          = GetLocationY(startLoc) + setupTable.defYOffset
                heroLoc         = Location(peon.x + setupTable.defHeroXOffset,
                                           peon.y + setupTable.defHeroYOffset)
            end
            func(whichPlayer, startLoc, mine, peon.x, peon.y)

            if (doHeroes) then
                if IsMapFlagSet(MAP_RANDOM_HERO) then
                    setupTable._getRandomHero(whichPlayer, heroLoc, faction.hero)
                else
                    SetPlayerState(whichPlayer, PLAYER_STATE_RESOURCE_HERO_TOKENS, bj_MELEE_STARTING_HERO_TOKENS)
                end
            end
            RemoveLocation(heroLoc)
        
            if (doCamera) then
                SetCameraPositionForPlayer(whichPlayer, peon.x, peon.y)
                SetCameraQuickPositionForPlayer(whichPlayer, peon.x, peon.y)
            end
        end
    end

    local raceSetup         = {}
    raceSetup.human         = CustomRaceSystem.create(RACE_HUMAN, "The Alliance")
    raceSetup.human:addHall('htow', 'hkee', 'hcas')
    raceSetup.human:addHero('Hamg', 'Hmkg', 'Hpal', 'Hblm')
    raceSetup.human:defDescription("The Human Alliance is a conglomeration of Humans, Elves, and Dwarves."
                                .. "They are the most versatile army in Warcraft III, with good ground and "
                                .. "air troops, excellent siege capability, and powerful spellcasters.")
    raceSetup.human:defRacePic("war3mapImported\\humanseal.blp")
    raceSetup.human:defSetup(setupTable.createSetup(
        setupTable.createSetupHelper(function(whichPlayer, hall, mine)
            if (hall ~= nil) then
                UnitAddAbility(hall, FourCC('Amic'))
                UnitMakeAbilityPermanent(hall, true, FourCC('Amic'))
            end
        end, 'htow', 'hpea'),
        "scripts\\HumanMelee.pld", raceSetup.human))
    raceSetup.human:defAISetup(function(whichPlayer)
        PickMeleeAI(whichPlayer, "human.ai", nil, nil)
    end)

    raceSetup.orc           = CustomRaceSystem.create(RACE_ORC, "The Horde")
    raceSetup.orc:addHall('ogre', 'ostr', 'ofrt')
    raceSetup.orc:addHero('Obla', 'Ofar', 'Otch', 'Oshd')
    raceSetup.orc:defDescription("The Orcs, who once cultivated a quiet Shamanistic society upon the world"
                              .. "of Draenor, were corrupted by the chaos magics of the Burning Legion and"
                              .. " formed into a voracious, unstoppable Horde. Lured to the world of "
                              .. "Azeroth through a dimensional gateway, the Horde was manipulated into "
                              .. "waging war against the human nations of Azeroth and Lordaeron. Hoping that"
                              .. " the Horde would conquer the mortal armies of Azeroth, the Burning Legion "
                              .. "made ready for its final invasion of the unsuspecting world.")
    raceSetup.orc:defRacePic("war3mapImported\\orcseal.blp")
    raceSetup.orc:defSetup(setupTable.createSetup(
        setupTable.createSetupHelper(function(hall, mine)
        end, 'ogre', 'opeo'),
        "scripts\\OrcMelee.pld", raceSetup.orc))
    raceSetup.orc:defAISetup(function(whichPlayer)
        PickMeleeAI(whichPlayer, "orc.ai", nil, nil)
    end)

    raceSetup.undead         = CustomRaceSystem.create(RACE_UNDEAD, "The Scourge")
    raceSetup.undead:addHall('unpl', 'unp1', 'unp2')
    raceSetup.undead:addHero('Udea', 'Ulic', 'Udre', 'Ucrl')
    raceSetup.undead:defDescription("The horrifying Undead army, called the Scourge, consists of thousands of "
                                 .. "walking corpses, disembodied spirits, damned mortal men and insidious "
                                 .. "extra-dimensional entities. The Scourge was created by the Burning Legion "
                                 .. "for the sole purpose of sowing terror across the world in anticipation of "
                                 .. "the Legion's inevitable invasion. The Undead are ruled by Ner'zhul, the "
                                 .. "Lich King, who lords over the icy realm of Northrend from his frozen throne. "
                                 .. "Ner'zhul commands the terrible plague of undeath, which he sends ever "
                                 .. "southward into the human lands. As the plague encroaches on the southlands, "
                                 .. "more and more humans fall prey to Ner'zhul's mental control and life-draining "
                                 .. "sickness every day. In this way, Ner'zhul has swelled the ranks of the already "
                                 .. "considerable Scourge. The Undead employ necromantic magics and the elemental "
                                 .. "powers of the cold north against their enemies.")
    raceSetup.undead:defRacePic("war3mapImported\\undeadseal.blp")
    raceSetup.undead:defSetup(setupTable.createSetup(
        setupTable.createSetupHelper(function(whichPlayer, hall, mine, peonX, peonY)
            local cx    = peonX + 1.00*setupTable.unitSpacing
            local cy    = peonY + 0.00*setupTable.unitSpacing
            if mine and GetUnitTypeId(mine) == FourCC('ngol') then
                local mineX, mineY  = GetUnitX(mine), GetUnitY(mine)
                local mineGold      = GetResourceAmount(mine)
                local theta         = math.atan(GetUnitY(hall)-mineY, 
                                                GetUnitX(hall)-mineX)
                cx                  = mineX + 288*math.cos(theta)
                cy                  = mineY + 288*math.sin(theta)
                RemoveUnit(mine)

                --  Hide everyone first, then create the gold mine
                mine            = CreateBlightedGoldmine(whichPlayer, mineX, mineY, bj_UNIT_FACING)
                SetResourceAmount(mine, mineGold)

                ShowUnit(mine, false)
                SetUnitPosition(mine, mineX, mineY)
                ShowUnit(mine, true)
            end
            bj_ghoul[GetPlayerId(whichPlayer)]  = CreateUnit(whichPlayer, FourCC('ugho'),
                                                             cx, cy, bj_UNIT_FACING)
        end, 'unpl', 'uaco', 3, {0.00, 0.65, -0.65}, {0.50, -0.50, -0.50}),
        "scripts\\UndeadMelee.pld", raceSetup.undead))
    raceSetup.undead:defAISetup(function(whichPlayer)
        PickMeleeAI(whichPlayer, "undead.ai", nil, nil)
        RecycleGuardPosition(bj_ghoul[GetPlayerId(whichPlayer)])
    end)

    raceSetup.nightelf         = CustomRaceSystem.create(RACE_NIGHTELF, "The Sentinel")
    raceSetup.nightelf:addHall('etol', 'etoa', 'etoe')
    raceSetup.nightelf:addHero('Ekee', 'Emoo', 'Edem', 'Ewar')
    raceSetup.nightelf:defDescription("The reclusive Night Elves were the first race to awaken in the World "
                                   .. "of Warcraft. These shadowy, immortal beings were the first to study "
                                   .. "magic and let it loose throughout the world nearly ten thousand years "
                                   .. "before Warcraft I. The Night Elves' reckless use of magic drew the "
                                   .. "Burning Legion into the world and led to a catastrophic war between the "
                                   .. "two titanic races. The Night Elves barely managed to banish the Legion "
                                   .. "from the world, but their wondrous homeland was shattered and drowned by "
                                   .. "the sea. Ever since, the Night Elves refused to use magic for fear that "
                                   .. "the dreaded Legion would return. The Night Elves closed themselves off "
                                   .. "from the rest of the world and remained hidden atop their holy mountain "
                                   .. "of Hyjal for many thousands of years. As a race, Night Elves are typically "
                                   .. "honorable and just, but they are very distrusting of the 'lesser races' of "
                                   .. "the world. They are nocturnal by nature and their shadowy powers often elicit "
                                   .. "the same distrust that they have for their neighbors.")
    raceSetup.nightelf:defRacePic("war3mapImported\\nightelfseal.blp")
    raceSetup.nightelf:defSetup(setupTable.createSetup(
        setupTable.createSetupHelper(function(whichPlayer, hall, mine, peonX, peonY)
            if mine then
                local cx, cy    = GetUnitX(mine), GetUnitY(mine)
                local theta     = math.atan(GetUnitY(hall) - cy, GetUnitX(hall) - cx)
                ShowUnit(hall, false)
                SetUnitPosition(hall, cx + 600*math.cos(theta), cy + 600*math.sin(theta))
                ShowUnit(hall, true)

                IssueTargetOrder(hall, "entangleinstant", mine)
            end
        end, 'etol', 'ewsp', 5),
        "scripts\\NightElfMelee.pld", raceSetup.nightelf))
    raceSetup.nightelf:defAISetup(function(whichPlayer)
        PickMeleeAI(whichPlayer, "elf.ai", nil, nil)
    end)

    raceSetup.other         = CustomRaceSystem.create(RACE_OTHER, "Neutrals")
    raceSetup.other:addHero('Npbm','Nbrn','Nngs','Nplh','Nbst','Nalc','Ntin','Nfir')
end