do
    CustomMeleeSetup = {
        unitSpacing = 64.00,
        minTreeDist = 3.50,
        minWispDist = 1.75,
    }
    CustomMeleeSetup.minTreeDist = CustomMeleeSetup.minTreeDist * bj_CELLWIDTH
    CustomMeleeSetup.minWispDist = CustomMeleeSetup.minWispDist * bj_CELLWIDTH
    do
        --  Starting Base Layouts.
        local funcs         = CustomMeleeSetup

        funcs.human      = CustomMelee.add_faction(RACE_HUMAN, "Alliance")
        funcs.orc        = CustomMelee.add_faction(RACE_ORC, "Horde")
        funcs.undead     = CustomMelee.add_faction(RACE_UNDEAD, "Scourge")
        funcs.elf        = CustomMelee.add_faction(RACE_NIGHTELF, "Sentinel")
        funcs.demon      = CustomMelee.add_faction(RACE_DEMON, "Other")
        funcs.other      = CustomMelee.add_faction(RACE_OTHER, "Other")
        
        funcs.def       = function(whichplayer, startloc, hallId, peonId)
            if type(hallId) == 'string' then hallId = FourCC(hallId) end
            if type(peonId) == 'string' then peonId = FourCC(peonId) end
            
            local nearestMine = MeleeFindNearestMine(startloc, bj_MELEE_MINE_SEARCH_RADIUS)
            local peonX
            local peonY
            local heroLoc
            local townHall
            if (nearestMine ~= nil) then
            --   Spawn Town Hall at the start location.
                townHall            = CreateUnitAtLoc(whichplayer, hallId, startloc, bj_UNIT_FACING)
            
                -- Spawn Peasants near the mine.
                local mineLoc       = GetUnitLoc(nearestMine)
                local nearMineLoc   = MeleeGetProjectedLoc(mineLoc, startloc, 320, 0)
                peonX, peonY        = GetLocationX(nearMineLoc), GetLocationY(nearMineLoc)

                CreateUnit(whichplayer, peonId, peonX + 0.00 * funcs.unitSpacing, peonY + 1.00 * funcs.unitSpacing, bj_UNIT_FACING)
                CreateUnit(whichplayer, peonId, peonX + 1.00 * funcs.unitSpacing, peonY + 0.15 * funcs.unitSpacing, bj_UNIT_FACING)
                CreateUnit(whichplayer, peonId, peonX - 1.00 * funcs.unitSpacing, peonY + 0.15 * funcs.unitSpacing, bj_UNIT_FACING)
                CreateUnit(whichplayer, peonId, peonX + 0.60 * funcs.unitSpacing, peonY - 1.00 * funcs.unitSpacing, bj_UNIT_FACING)
                CreateUnit(whichplayer, peonId, peonX - 0.60 * funcs.unitSpacing, peonY - 1.00 * funcs.unitSpacing, bj_UNIT_FACING)

                -- Set random hero spawn point to be off to the side of the start location.
                heroLoc = MeleeGetProjectedLoc(mineLoc, startloc, 384, 45)
                RemoveLocation(mineLoc)
                RemoveLocation(nearMineLoc)
            else
                -- Spawn Town Hall at the start location.
                townHall = CreateUnitAtLoc(whichplayer, hallId, startloc, bj_UNIT_FACING)
            
                -- Spawn Peasants directly south of the town hall.
                peonX = GetLocationX(startloc)
                peonY = GetLocationY(startloc) - 224.00
                CreateUnit(whichplayer, peonId, peonX + 2.00 * funcs.unitSpacing, peonY + 0.00 * funcs.unitSpacing, bj_UNIT_FACING)
                CreateUnit(whichplayer, peonId, peonX + 1.00 * funcs.unitSpacing, peonY + 0.00 * funcs.unitSpacing, bj_UNIT_FACING)
                CreateUnit(whichplayer, peonId, peonX + 0.00 * funcs.unitSpacing, peonY + 0.00 * funcs.unitSpacing, bj_UNIT_FACING)
                CreateUnit(whichplayer, peonId, peonX - 1.00 * funcs.unitSpacing, peonY + 0.00 * funcs.unitSpacing, bj_UNIT_FACING)
                CreateUnit(whichplayer, peonId, peonX - 2.00 * funcs.unitSpacing, peonY + 0.00 * funcs.unitSpacing, bj_UNIT_FACING)

                -- Set random hero spawn point to be just south of the start location.
                heroLoc = Location(peonX, peonY - 2.00 * funcs.unitSpacing)
            end
            local heroX, heroY  = GetLocationX(heroLoc), GetLocationY(heroLoc)
            RemoveLocation(heroLoc)
            return peonX, peonY, heroX, heroY, townHall, nearestMine
        end
        funcs.def_human = function(whichplayer, startloc, doheroes, docamera, dopreload)
            if (dopreload) then
                Preloader("scripts\\HumanMelee.pld")
            end
            local peonX, peonY, heroX, heroY, townHall = funcs.def(whichplayer, startloc, 'htow', 'hpea')
            if (townHall ~= nil) then
                UnitAddAbility(townHall, FourCC('Amic'))
                UnitMakeAbilityPermanent(townHall, true, FourCC('Amic'))
            end
            return peonX, peonY, heroX, heroY
        end
        funcs.def_orc   = function(whichplayer, startloc, doheroes, docamera, dopreload)
            if (dopreload) then
                Preloader("scripts\\OrcMelee.pld")
            end
            local peonX, peonY, heroX, heroY = funcs.def(whichplayer, startloc, 'ogre', 'opeo')
            return peonX, peonY, heroX, heroY
        end
        funcs.def_nightelf  = function(whichplayer, startloc, doheroes, docamera, dopreload)
            if (dopreload) then
                Preloader( "scripts\\NightElfMelee.pld" )
            end
            local townhall, heroLoc, peonX, peonY
            local nearestMine = MeleeFindNearestMine(startloc, bj_MELEE_MINE_SEARCH_RADIUS)
            if nearestMine then
                -- Spawn Tree of Life near the mine and have it entangle the mine.
                -- Project the Tree's coordinates from the gold mine, and then snap
                -- the X and Y values to within minTreeDist of the Gold Mine.
                local mineLoc       = GetUnitLoc(nearestMine)
                local nearMineLoc   = MeleeGetProjectedLoc(mineLoc, startloc, 650, 0)
                nearMineLoc         = MeleeGetLocWithinRect(nearMineLoc, GetRectFromCircleBJ(mineLoc, funcs.minTreeDist))
                townhall            = CreateUnitAtLoc(whichplayer, FourCC('etol'), nearMineLoc, bj_UNIT_FACING)
                IssueTargetOrder(townhall, "entangleinstant", nearestMine)
        
                -- Spawn Wisps at the start location.
                local wispLoc   = MeleeGetProjectedLoc(mineLoc, startloc, 280, 0)
                wispLoc         = MeleeGetLocWithinRect(wispLoc, GetRectFromCircleBJ(mineLoc, funcs.minWispDist))
                peonX           = GetLocationX(wispLoc)
                peonY           = GetLocationY(wispLoc)
                CreateUnit(whichplayer, FourCC('ewsp'), peonX + 0.00 * funcs.unitSpacing, peonY + 1.00 * funcs.unitSpacing, bj_UNIT_FACING)
                CreateUnit(whichplayer, FourCC('ewsp'), peonX + 1.00 * funcs.unitSpacing, peonY + 0.15 * funcs.unitSpacing, bj_UNIT_FACING)
                CreateUnit(whichplayer, FourCC('ewsp'), peonX - 1.00 * funcs.unitSpacing, peonY + 0.15 * funcs.unitSpacing, bj_UNIT_FACING)
                CreateUnit(whichplayer, FourCC('ewsp'), peonX + 0.58 * funcs.unitSpacing, peonY - 1.00 * funcs.unitSpacing, bj_UNIT_FACING)
                CreateUnit(whichplayer, FourCC('ewsp'), peonX - 0.58 * funcs.unitSpacing, peonY - 1.00 * funcs.unitSpacing, bj_UNIT_FACING)
        
                -- Set random hero spawn point to be off to the side of the start location.
                heroLoc = MeleeGetProjectedLoc(GetUnitLoc(nearestMine), startloc, 384, 45)
            else
                -- Spawn Tree of Life at the start location.
                CreateUnitAtLoc(whichplayer, FourCC('etol'), startloc, bj_UNIT_FACING)
        
                -- Spawn Wisps directly south of the town hall.
                peonX = GetLocationX(startloc)
                peonY = GetLocationY(startloc) - 224.00
                CreateUnit(whichplayer, FourCC('ewsp'), peonX - 2.00 * funcs.unitSpacing, peonY + 0.00 * funcs.unitSpacing, bj_UNIT_FACING)
                CreateUnit(whichplayer, FourCC('ewsp'), peonX - 1.00 * funcs.unitSpacing, peonY + 0.00 * funcs.unitSpacing, bj_UNIT_FACING)
                CreateUnit(whichplayer, FourCC('ewsp'), peonX + 0.00 * funcs.unitSpacing, peonY + 0.00 * funcs.unitSpacing, bj_UNIT_FACING)
                CreateUnit(whichplayer, FourCC('ewsp'), peonX + 1.00 * funcs.unitSpacing, peonY + 0.00 * funcs.unitSpacing, bj_UNIT_FACING)
                CreateUnit(whichplayer, FourCC('ewsp'), peonX + 2.00 * funcs.unitSpacing, peonY + 0.00 * funcs.unitSpacing, bj_UNIT_FACING)
        
                -- Set random hero spawn point to be just south of the start location.
                heroLoc = Location(peonX, peonY - 2.00 * funcs.unitSpacing)
            end
            local heroX, heroY  = GetLocationX(heroLoc), GetLocationY(heroLoc)
            RemoveLocation(heroLoc)
            return peonX, peonY, heroLoc
        end
        funcs.def_undead    = function(whichplayer, startloc, doheroes, docamera, dopreload)
            if (dopreload) then
                Preloader("scripts\\UndeadMelee.pld")
            end
            local peonX, peonY, heroLoc
            local nearestMine = MeleeFindNearestMine(startloc, bj_MELEE_MINE_SEARCH_RADIUS)
            if (nearestMine ~= nil) then
                -- Spawn Necropolis at the start location.
                CreateUnitAtLoc(whichplayer, FourCC('unpl'), startloc, bj_UNIT_FACING)
                
                -- Replace the nearest gold mine with a blighted version.
                nearestMine     = BlightGoldMineForPlayerBJ(nearestMine, whichplayer)
                local mineLoc   = GetUnitLoc(nearestMine)
                -- Spawn Ghoul near the Necropolis.
                nearTownLoc = MeleeGetProjectedLoc(startloc, mineLoc, 288, 0)
                ghoulX      = GetLocationX(nearTownLoc)
                ghoulY      = GetLocationY(nearTownLoc)
                bj_ghoul[GetPlayerId(whichplayer)] = CreateUnit(whichplayer, FourCC('ugho'), ghoulX + 0.00 * funcs.unitSpacing, ghoulY + 0.00 * funcs.unitSpacing, bj_UNIT_FACING)

                -- Spawn Acolytes near the mine.
                nearMineLoc = MeleeGetProjectedLoc(mineLoc, startloc, 320, 0)
                peonX       = GetLocationX(nearMineLoc)
                peonY       = GetLocationY(nearMineLoc)
                CreateUnit(whichplayer, FourCC('uaco'), peonX + 0.00 * funcs.unitSpacing, peonY + 0.50 * funcs.unitSpacing, bj_UNIT_FACING)
                CreateUnit(whichplayer, FourCC('uaco'), peonX + 0.65 * funcs.unitSpacing, peonY - 0.50 * funcs.unitSpacing, bj_UNIT_FACING)
                CreateUnit(whichplayer, FourCC('uaco'), peonX - 0.65 * funcs.unitSpacing, peonY - 0.50 * funcs.unitSpacing, bj_UNIT_FACING)

                -- Create a patch of blight around the gold mine.
                SetBlightLoc(whichplayer,nearMineLoc, 768, true)

                -- Set random hero spawn point to be off to the side of the start location.
                heroLoc = MeleeGetProjectedLoc(mineLoc, startloc, 384, 45)
                RemoveLocation(mineLoc)
                RemoveLocation(nearTownLoc)
            else
                -- Spawn Necropolis at the start location.
                CreateUnitAtLoc(whichplayer, FourCC('unpl'), startloc, bj_UNIT_FACING)
                
                -- Spawn Acolytes and Ghoul directly south of the Necropolis.
                peonX = GetLocationX(startloc)
                peonY = GetLocationY(startloc) - 224.00
                CreateUnit(whichplayer, FourCC('uaco'), peonX - 1.50 * funcs.unitSpacing, peonY + 0.00 * funcs.unitSpacing, bj_UNIT_FACING)
                CreateUnit(whichplayer, FourCC('uaco'), peonX - 0.50 * funcs.unitSpacing, peonY + 0.00 * funcs.unitSpacing, bj_UNIT_FACING)
                CreateUnit(whichplayer, FourCC('uaco'), peonX + 0.50 * funcs.unitSpacing, peonY + 0.00 * funcs.unitSpacing, bj_UNIT_FACING)
                CreateUnit(whichplayer, FourCC('ugho'), peonX + 1.50 * funcs.unitSpacing, peonY + 0.00 * funcs.unitSpacing, bj_UNIT_FACING)

                -- Create a patch of blight around the start location.
                SetBlightLoc(whichplayer,startloc, 768, true)

                -- Set random hero spawn point to be just south of the start location.
                heroLoc = Location(peonX, peonY - 2.00 * funcs.unitSpacing)
            end
            local heroX, heroY  = GetLocationX(heroLoc), GetLocationY(heroLoc)
            RemoveLocation(heroLoc)
            return peonX, peonY, heroX, heroY
        end
        
        funcs.def_human     = funcs.human:generate_setup(funcs.def_human)
        funcs.def_orc       = funcs.orc:generate_setup(funcs.def_orc)
        funcs.def_undead    = funcs.undead:generate_setup(funcs.def_undead)
        funcs.def_nightelf  = funcs.elf:generate_setup(funcs.def_nightelf)
        funcs.def_demon     = MeleeStartingUnitsUnknownRace
        funcs.def_other     = MeleeStartingUnitsUnknownRace
        
        funcs.human:config_setup(funcs.def_human)
        funcs.orc:config_setup(funcs.def_orc)
        funcs.undead:config_setup(funcs.def_undead)
        funcs.elf:config_setup(funcs.def_nightelf)
        funcs.demon:config_setup(funcs.def_demon)
        funcs.other:config_setup(funcs.def_other)

        funcs.human:ai_setup("human.ai")
        funcs.orc:ai_setup("orc.ai")
        funcs.undead:ai_setup("undead.ai")
        funcs.elf:ai_setup("elf.ai")

        --  Registering Hero Ids.
        funcs.human:add_heroID('Hamg', 'Hmkg', 'Hpal', 'Hblm')
        funcs.orc:add_heroID('Obla', 'Ofar', 'Otch', 'Oshd')
        funcs.elf:add_heroID('Edem', 'Ekee', 'Emoo', 'Ewar')
        funcs.undead:add_heroID('Udea', 'Udre', 'Ulic', 'Ucrl')
        funcs.other:add_heroID('Npbm', 'Nbrn', 'Nngs', 'Nplh',
                            'Nbst', 'Nalc', 'Ntin', 'Nfir')

        funcs.human:add_hallID('htow', 'hkee', 'hcas')
        funcs.orc:add_hallID('ogre', 'ostr', 'ofrt')
        funcs.undead:add_hallID('unpl', 'unp1', 'unp2')
        funcs.elf:add_hallID('etol', 'etoa', 'etoe')
    end
end