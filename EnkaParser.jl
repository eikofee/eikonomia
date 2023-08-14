module EnkaParser

    using HTTP, JSON, DataFrames

    localizationCode = "en"
    uid = ENV["GENSHIN_UID"]

    export loadData

    function tof(txt)
        parse(Float64, string(txt))
    end

    function loadLocalizationTable()
        r = HTTP.get("https://raw.githubusercontent.com/EnkaNetwork/API-docs/master/store/loc.json")
        JSON.parse(String(r.body))[localizationCode]
    end

    localizationTable = loadLocalizationTable()

    function translate(id)
        id = string(id)
        localizationTable[id]
    end

    function getCharData(charId)
        r = HTTP.get("https://raw.githubusercontent.com/EnkaNetwork/API-docs/master/store/characters.json")
        j = JSON.parse(String(r.body))
        charId = string(charId)
        Dict(
        "id" => charId,
        "name" => translate(j[charId]["NameTextMapHash"]),
        "element" => j[charId]["Element"],
        "skillIdAA" => string(j[charId]["SkillOrder"][1]),
        "skillIdSkill" => string(j[charId]["SkillOrder"][2]),
        "skillIdUlt" => string(j[charId]["SkillOrder"][3])
        )
    end

    function loadPlayerData()
        r = HTTP.get("https://enka.network/api/uid/" * uid)
        JSON.parse(String(r.body))
    end

    function translateElement(elem)
        elems = Dict(
            "Fire" => "Pyro",
            "Electric" => "Electro",
            "Water" => "Hydro",
            "Grass" => "Dendro",
            "Rock" => "Geo",
            "Wind" => "Anemo",
            "Ice" => "Cryo"
        )

        elems[elem]
    end

    function translateEquipType(id)
        equipType = Dict(
            "EQUIP_BRACER" => "fleur",
            "EQUIP_NECKLACE" => "plume",
            "EQUIP_SHOES" => "sablier",
            "EQUIP_RING" => "coupe",
            "EQUIP_DRESS" => "couronne"
        )
        equipType[id]
    end

    function translateArtefactStatName(id)
        statType = Dict(
            "FIGHT_PROP_HP" => "HP",
            "FIGHT_PROP_ATTACK" => "ATK",
            "FIGHT_PROP_DEFENSE" => "DEF",
            "FIGHT_PROP_HP_PERCENT" => "HP%",
            "FIGHT_PROP_ATTACK_PERCENT" => "ATK%",
            "FIGHT_PROP_DEFENSE_PERCENT" => "DEF%",
            "FIGHT_PROP_CRITICAL" => "Crit Rate%",
            "FIGHT_PROP_CRITICAL_HURT" => "Crit DMG%",
            "FIGHT_PROP_CHARGE_EFFICIENCY" => "ER%",
            "FIGHT_PROP_HEAL_ADD" => "Heal%",
            "FIGHT_PROP_ELEMENT_MASTERY" => "EM",
            "FIGHT_PROP_PHYSICAL_ADD_HURT" => "Phys%",
            "FIGHT_PROP_FIRE_ADD_HURT" => "Elem%",
            "FIGHT_PROP_ELEC_ADD_HURT" => "Elem%",
            "FIGHT_PROP_WATER_ADD_HURT" => "Elem%",
            "FIGHT_PROP_WIND_ADD_HURT" => "Elem%",
            "FIGHT_PROP_ICE_ADD_HURT" => "Elem%",
            "FIGHT_PROP_ROCK_ADD_HURT" => "Elem%",
            "FIGHT_PROP_GRASS_ADD_HURT" => "Elem%",
            "FIGHT_PROP_BASE_ATTACK" => "ATK"
        )
        statType[id]
    end

    function artefactSetToBonus(set, count)
        setEffects2pc = Dict(
            "Blizzard Strayer" => ("Elem%", 0.15),
            "Tenacity of the Millelith" => ("HP%", 0.2),
            "Husk of Opulent Dreams" => ("DEF%", 0.3),
            "Thundering Fury" => ("Elem%", 0.15),
            "Archaic Petra" => ("Elem%", 0.15),
            "Echoes of an Offering" => ("ATK%", 0.18),
            "Bloodstained Chivalry" => ("Phys%", 0.25),
            "Heart of Depth" => ("Elem%", 0.15),
            "Wanderer's Troupe" => ("EM", 80),
            "Ocean-Hued Clam" => ("Heal%", 0.15),
            "Crimson Witch of Flames" => ("Elem%", 0.15),
            "Emblem of Severed Fate" => ("ER%", 0.2),
            "Viridescent Venerer" => ("Elem%", 0.16),
            "Pale Flame" => ("Phys%", 0.25),
            "Maiden Beloved" => ("Heal%", 0.15),
            "Gladiator's Finale" => ("ATK%", 0.18),
            "Vermillion Hereafter" => ("ATK%", 0.18),
            "Shimenawa's Reminiscence" => ("ATK%", 0.18),
            "Deepwood Memories" => ("Elem%", 0.15),
            "Gilded Dreams" => ("EM", 80),
            "Flower of Paradise Lost" => ("EM", 80),
            "Desert Pavilion Chronicle" => ("Elem%", 0.15),
            "Nymph's Dream" => ("Elem%", 0.15),
            "Vourukasha's Glow" => ("HP%", 0.2)
        )
        
        if count >= 2
            if set in collect(keys(setEffects2pc))
                return setEffects2pc[set]
            end
        end
        ("None", 0)
    end

    function loadEquipStats(elm)
        function parseEntry(e)
            k = collect(keys(e))
            if "reliquary" in k
                Dict(
                    "type" => "artefact",
                    "icon" => e["flat"]["icon"],
                    "set" => translate(e["flat"]["setNameTextMapHash"]),
                    "subtype" => translateEquipType(e["flat"]["equipType"]),
                    "mainStatName" => translateArtefactStatName(e["flat"]["reliquaryMainstat"]["mainPropId"]),
                    "mainStatValue" => e["flat"]["reliquaryMainstat"]["statValue"],
                    "subStatNames" => map(x -> translateArtefactStatName(e["flat"]["reliquarySubstats"][x]["appendPropId"]), 1:4),
                    "subStatValues" => map(x -> e["flat"]["reliquarySubstats"][x]["statValue"], 1:4)
                )
            else
                Dict(
                    "type" => "weapon",
                    "icon" => e["flat"]["icon"],
                    "level" => e["weapon"]["level"],
                    "mainStatName" => translateArtefactStatName(e["flat"]["weaponStats"][1]["appendPropId"]),
                    "mainStatValue" => e["flat"]["weaponStats"][1]["statValue"],
                    "subStatName" => translateArtefactStatName(e["flat"]["weaponStats"][2]["appendPropId"]),
                    "subStatValue" => e["flat"]["weaponStats"][2]["statValue"],
                )
            end
        end

        xs = map(x -> parseEntry(x), elm)
        Dict(
            "artefacts" => filter(x -> x["type"] == "artefact", xs),
            "weapon" => first(filter(x -> x["type"] == "weapon", xs))
        )
    end

    function getArtefactSetBonus(data)
        sets = DataFrame()
        sets.name = map(x -> x["set"], data)
        sets.count .= 1
        gdf = groupby(sets, :name)
        sets = combine(gdf, :count => sum)
        sets = sets[sets.count_sum .> 1, :]
        map(x -> artefactSetToBonus(x.name, x.count_sum), eachrow(sets))
    end

    function loadCharStat(data)
        charData = getCharData(data["avatarId"])
        fpmData = data["fightPropMap"]
        elmData = data["equipList"]
        function fpm(id)
            if string(id) in collect(keys(fpmData))
                tof(fpmData[string(id)])
            else
                0
            end
        end

        elm = loadEquipStats(elmData)

        artefactSetBonuses = getArtefactSetBonus(elm["artefacts"])

        Dict(
            "name" => charData["name"],
            "element" => translateElement(charData["element"]),
            "level" => tof(data["propMap"]["4001"]["val"]),
            "friendshipLevel" => tof(data["fetterInfo"]["expLevel"]),
            "skillLevelAA" => tof(data["skillLevelMap"][charData["skillIdAA"]]),
            "skillLevelSkill" => tof(data["skillLevelMap"][charData["skillIdSkill"]]),
            "skillLevelUlt" => tof(data["skillLevelMap"][charData["skillIdUlt"]]),

            "baseHP" => fpm(1), # base stats combine char stats and weapon main stat
            "baseATK" => fpm(4),
            "baseDEF" => fpm(7),

            "weapon" => elm["weapon"],
            "artefacts" => elm["artefacts"],
            "artefactSetBonus1" => get(artefactSetBonuses, 1, ("None", 0)),
            "artefactSetBonus2" => get(artefactSetBonuses, 2, ("None", 0)),

            "equipHP" => fpm(2),
            "equipHP%" => fpm(3),
            "equipATK" => fpm(5),
            "equipATK%" => fpm(6),
            "equipDEF" => fpm(8),
            "equipDEF%" => fpm(9),
            "equipCritRate%" => fpm(20),
            "equipCritDMG%" => fpm(22),
            "equipER%" => fpm(23),
            "equipHeal%" => fpm(26),
            "equipEM" => fpm(28),
            "equipPhys%" => fpm(30),
            "equipElem%" => reduce(+, map(x -> fpm(x), 40:46))
        )
    end

    function loadCharStats(data)
        collect(map(x -> loadCharStat(data["avatarInfoList"][x]), 1:length(data["avatarInfoList"])))
    end

    function loadData()
        data = loadPlayerData()
        loadCharStats(data)
    end

end