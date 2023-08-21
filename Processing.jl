module Processing
    using DataFrames, JSON

    export processAdditionalData, rateArtefacts

    # TODO: move in another repo and load them here
    function getArtefactSetBonus(set, count)
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
            "Viridescent Venerer" => ("Elem%", 0.15),
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
        
        bonus = ("None", 0)
        if count >= 2
            if set in collect(keys(setEffects2pc))
                bonus = setEffects2pc[set]
            else
                bonus = ("Unknown", 2)
            end
        end
        bonus
    end

    function weaponPassive(weapon)
        passives = Dict(
            "Aqua Simulacra" => ("HP%",0.16,0.04),
            "Aquila Favonia" => ("ATK%", 0.2, 0.05),
            "Calamity Queller" => ("Elem%", 0.12, 0.03),
            "Elegy for the End" => ("EM", 60, 15),
            # "Engulfing Lightning" =>
            "Everlasting Moonglow" => ("Heal%", 0.1, 0.02), #+ % of maxhp
            "Haran Geppaku Futsu" => ("Elem%", 0.12, 0.03),
            "Hunter's Path" => ("Elem%", 0.12, 0.03),
            "Key of Khaj-Nisut" => ("HP%", 0.2, 0.05), #+ %maxhp of em
            "Light of Foliar Incision" => ("Crit Rate%", 0.04, 0.01),
            "Mistsplitter Reforged" => ("Elem%", 0.12, 0.3),
            "Primordial Jade Cutter" => ("HP%", 0.2, 0.05),
            "Redhorn Stonethresher" => ("DEF%", 0.28, 0.07),
            "Skyward Atlas" => ("Elem%", 0.12, 0.3),
            "Skyward Blade" => ("Crit Rate%", 0.04, 0.01),
            "Skyward Harp" => ("Crit DMG%", 0.2, 0.05),
            "Skyward Spine" => ("Crit Rate%", 0.08, 0.02),
            "Song of Broken Pines" => ("ATK%", 0.16, 0.04),
            "Staff of Homa" => ("HP%", 0.2, 0.05), #+ %maxhp of atk%
            #"Staff of the Scarlet Sands" =>
            "Thundering Pulse" => ("ATK%", 0.2, 0.05),
            "Wolf's Gravestone" => ("ATK%", 0.2, 0.05),
        )
        res = []
        if weapon["name"] in keys(passives)
            (statName, statValueBase, statValueRef) = passives[weapon["name"]]
            statValue = statValueBase + statValueRef * (weapon["refinement"] - 1)
            push!(res, (statName, statValue))
        end
        (map(x -> x[1], res), map(x -> x[2], res))
    end

    function charPassive(data)
        nameToPassive = Dict(
            "Sangonomiya Kokomi" => ("Crit Rate%", -1)
        )

        name = data["name"]
        res = []
        if name in keys(nameToPassive)
            push!(res, nameToPassive[name])
        end

        (map(x -> x[1], res), map(x -> x[2], res))
    end

    function getArtefactSetBonuses(artefacts)
        sets = DataFrame()
        artefactTypes = collect(keys(artefacts))
        artefacts = map(x -> artefacts[x], artefactTypes)
        sets.name = map(x -> x["set"], artefacts)
        sets.count .= 1
        gdf = groupby(sets, :name)
        sets = combine(gdf, :count => sum)
        sets = sets[sets.count_sum .> 1, :]
        d = map(x -> getArtefactSetBonus(x.name, x.count_sum), eachrow(sets))
        (map(x -> x[1], d), map(x -> x[2], d))
    end

    function getAnormalStats(data)
        sumStats = mergeEquipData(data)
        keys = ["HP%","ATK%","DEF%","Crit Rate%","Crit DMG%","ER%","Heal%","EM","Phys%","Elem%"]
        for k in keys
            sumStats[k] -= data["equipStats"][k]
        end
        res = []
        for k in keys
            tr = 2
            if occursin("%", k)
                tr = 0.002
            end
            if abs(sumStats[k]) > tr
                push!(res, (k, -1 * sumStats[k]))
            end
        end
        res
    end

    function processAdditionalData(data)
        (setBonusStatNames, setBonusStatValues) = getArtefactSetBonuses(data["artefacts"])
        data["artefactSetBonuses"] = Dict(
            "statNames" => setBonusStatNames,
            "statValues" => setBonusStatValues
        )

        (weaponPassivesStatNames, weaponPassivesStatValues) = weaponPassive(data["weapon"])
        data["weaponPassives"] = Dict(
            "statNames" => weaponPassivesStatNames,
            "statValues" => weaponPassivesStatValues,
        )

        (charPassivesStatNames, charPassivesStatValues) = charPassive(data)
        data["charPassives"] = Dict(
            "statNames" => charPassivesStatNames,
            "statValues" => charPassivesStatValues,
        )

        anormalStats = getAnormalStats(data)
        asn = "None"
        asv = 0
        xsn = []
        xsv = []
        if length(anormalStats) == 1
            (asn, asv) = first(anormalStats)
        else
            (xsn, xsv) = (map(x -> x[1], anormalStats), map(x -> x[2], anormalStats))
        end
        data["ascension"] = Dict(
            "statNames" => asn,
            "statValues"=> asv
        )
        data["anormalStats"] = Dict(
            "statNames" => xsn,
            "statValues" => xsv
        )

        data["artefacts"] = getArtefactRollPercentages(data["artefacts"])
        data
    end

    function mergeEquipData(data)
        sumStats = Dict(
            "HP" => 0.0,
            "HP%" => 0.0,
            "ATK" => 0.0,
            "ATK%" => 0.0,
            "DEF" => 0.0,
            "DEF%" => 0.0,
            "Crit Rate%" => 0.0,
            "Crit DMG%" => 0.0,
            "ER%" => 0.0,
            "Heal%" => 0.0,
            "EM" => 0.0,
            "Phys%" => 0.0,
            "Elem%" => 0.0
        )

        w = data["weapon"]
        sumStats[w["mainStatName"]] += w["mainStatValue"]
        sumStats[w["subStatName"]] += w["subStatValue"]
        ak = collect(keys(data["artefacts"]))
        for k in ak
            a = data["artefacts"][k]
            sumStats[a["mainStatName"]] += a["mainStatValue"]
            for index in 1:4
                sumStats[a["subStatNames"][index]] += a["subStatValues"][index]
            end
        end

        if length(data["artefactSetBonuses"]["statNames"]) > 0
            for b in 1:length(data["artefactSetBonuses"]["statNames"])
                sumStats[data["artefactSetBonuses"]["statNames"][b]] += data["artefactSetBonuses"]["statValues"][b]
            end
        end

        if length(data["weaponPassives"]["statNames"]) > 0
            for p in 1:length(data["weaponPassives"]["statNames"])
                sumStats[data["weaponPassives"]["statNames"][p]] += data["weaponPassives"]["statValues"][p]
            end
        end

        sumStats["Crit Rate%"] += 0.05
        sumStats["Crit DMG%"] += 0.5
        sumStats["ER%"] += 1.0

        sumStats
    end

    function getArtefactRollPercentages(artefacts)
        factor = Dict(
            "HP" => 298.75,
            "HP%" => 0.058,
            "ATK" => 19.45,
            "ATK%" => 0.058,
            "DEF" => 23.15,
            "DEF%" => 0.073,
            "Crit Rate%" => 0.039,
            "Crit DMG%" => 0.078,
            "ER%" => 0.0648,
            "EM" => 23.31,
        )

        ks = collect(keys(artefacts))
        for k in ks
            names = artefacts[k]["subStatNames"]
            values = artefacts[k]["subStatValues"]
            xs = map(x -> (names[x], values[x]), 1:length(names))
            artefacts[k]["rolls"] = map(x -> x[2] / factor[x[1]], xs)
        end

        artefacts
    end

    function rateArtefacts(artefacts, ratingFactors)
        xs = collect(keys(artefacts))
        
        for k in xs
            subRolls = artefacts[k]["rolls"]
            subNames = artefacts[k]["subStatNames"]
            score = map(i -> subRolls[i] * ratingFactors[subNames[i]], 1:4)
            score = reduce(+, score)
            scoreFactor = 0
            ratingFactorsKeys = keys(ratingFactors)
            r = collect(filter(x -> x != artefacts[k]["mainStatName"], ratingFactorsKeys))
            rs = map(x -> ratingFactors[x], r)
            rs = sort(rs, rev=true)
            if length(rs) > 0
                scoreFactor += first(rs) * 6
                if length(rs) > 1
                    for i in 2:min(length(rs), 4)
                        scoreFactor += rs[i]
                    end
                end
            end
            artefacts[k]["rating"] = score/scoreFactor
        end

        artefacts
    end

end