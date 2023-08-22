module EnkaParser

    using HTTP, JSON, DataFrames

    localizationCode = "en"
    uid = ENV["GENSHIN_UID"]
    if uid == "000000000"
        println("WARNING: UID has not been set !")
    end

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

    function transformArtefactStatValue(name, value)
        statMultiplier = Dict(
            "FIGHT_PROP_HP" => 1,
            "FIGHT_PROP_ATTACK" => 1,
            "FIGHT_PROP_DEFENSE" => 1,
            "FIGHT_PROP_HP_PERCENT" => 0.01,
            "FIGHT_PROP_ATTACK_PERCENT" => 0.01,
            "FIGHT_PROP_DEFENSE_PERCENT" => 0.01,
            "FIGHT_PROP_CRITICAL" => 0.01,
            "FIGHT_PROP_CRITICAL_HURT" => 0.01,
            "FIGHT_PROP_CHARGE_EFFICIENCY" => 0.01,
            "FIGHT_PROP_HEAL_ADD" => 0.01,
            "FIGHT_PROP_ELEMENT_MASTERY" => 1,
            "FIGHT_PROP_PHYSICAL_ADD_HURT" => 0.01,
            "FIGHT_PROP_FIRE_ADD_HURT" => 0.01,
            "FIGHT_PROP_ELEC_ADD_HURT" => 0.01,
            "FIGHT_PROP_WATER_ADD_HURT" => 0.01,
            "FIGHT_PROP_WIND_ADD_HURT" => 0.01,
            "FIGHT_PROP_ICE_ADD_HURT" => 0.01,
            "FIGHT_PROP_ROCK_ADD_HURT" => 0.01,
            "FIGHT_PROP_GRASS_ADD_HURT" => 0.01,
            "FIGHT_PROP_BASE_ATTACK" => 1
        )
        res = value * statMultiplier[name]
        res
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
                    "mainStatValue" => transformArtefactStatValue(e["flat"]["reliquaryMainstat"]["mainPropId"], e["flat"]["reliquaryMainstat"]["statValue"]),
                    "subStatNames" => map(x -> translateArtefactStatName(e["flat"]["reliquarySubstats"][x]["appendPropId"]), 1:4),
                    "subStatValues" => map(x -> transformArtefactStatValue(e["flat"]["reliquarySubstats"][x]["appendPropId"], e["flat"]["reliquarySubstats"][x]["statValue"]), 1:4)
                )
            else
                Dict(
                    "type" => "weapon",
                    "name" => translate(e["flat"]["nameTextMapHash"]),
                    "icon" => e["flat"]["icon"],
                    "level" => e["weapon"]["level"],
                    "refinement" => first(e["weapon"]["affixMap"]).second + 1,
                    "mainStatName" => translateArtefactStatName(e["flat"]["weaponStats"][1]["appendPropId"]),
                    "mainStatValue" => e["flat"]["weaponStats"][1]["statValue"],
                    "subStatName" => translateArtefactStatName(e["flat"]["weaponStats"][2]["appendPropId"]),
                    "subStatValue" => transformArtefactStatValue(e["flat"]["weaponStats"][2]["appendPropId"], e["flat"]["weaponStats"][2]["statValue"]),
                )
            end
        end

        xs = map(x -> parseEntry(x), elm)
        arts = filter(y -> y["type"] == "artefact", xs)
        artsDict = Dict(map(x -> x["subtype"] => x, arts))
        Dict(
            "artefacts" => artsDict,
            "weapon" => first(filter(x -> x["type"] == "weapon", xs))
        )
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

        #artefactSetBonuses = getArtefactSetBonus(elm["artefacts"])

        data = Dict(
            "name" => charData["name"],
            "element" => translateElement(charData["element"]),
            "level" => tof(data["propMap"]["4001"]["val"]),
            "friendshipLevel" => tof(data["fetterInfo"]["expLevel"]),
            "skills" => Dict(
                "levelAA" => tof(data["skillLevelMap"][charData["skillIdAA"]]),
                "levelevelSkill" => tof(data["skillLevelMap"][charData["skillIdSkill"]]),
                "levelUlt" => tof(data["skillLevelMap"][charData["skillIdUlt"]]),
            ),

            "baseHP" => fpm(1), # base stats combine char stats and weapon main stat
            "baseATK" => fpm(4),
            "baseDEF" => fpm(7),

            "weapon" => elm["weapon"],
            "artefacts" => elm["artefacts"],
            # "artefactSetBonusNames" => artefactSetBonuses[1],
            # "artefactSetBonusValues" => artefactSetBonuses[2],
            "equipStats" => Dict(
                "HP" => fpm(2),
                "HP%" => fpm(3),
                "ATK" => fpm(5),
                "ATK%" => fpm(6),
                "DEF" => fpm(8),
                "DEF%" => fpm(9),
                "Crit Rate%" => fpm(20),
                "Crit DMG%" => fpm(22),
                "ER%" => fpm(23),
                "Heal%" => fpm(26),
                "EM" => fpm(28),
                "Phys%" => fpm(30),
                "Elem%" => reduce(+, map(x -> fpm(x), 40:46))
            ),
        )

        # anormalStat = getAnormalStats(data)
        # if length(anormalStat) > 0
        #     data["anormalStatName"] = anormalStat[1]
        #     data["anormalStatValue"] = anormalStat[2]
        # end

        data
    end





    function loadCharStats(data)
        collect(map(x -> loadCharStat(data["avatarInfoList"][x]), 1:length(data["avatarInfoList"])))
    end

    function loadData()
        data = loadPlayerData()
        loadCharStats(data)
    end

end