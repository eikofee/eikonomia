module Eikonomia

    include("EnkaParser.jl")
    include("Database.jl")
    include("Server.jl")
    include("Processing.jl")
    using .EnkaParser, .Database, .Server, .Processing

    function loadDataAndProcess()
        data = loadData()
        map(x -> processAdditionalData(x), data)
    end

    function rateCharacter(name)
        rule = loadRatingRule(name)
        if rule !== nothing
            data = loadCharacter(name)
            data["artefacts"] = rateArtefacts(data["artefacts"], rule["rule"])
            updateCharacter(data)
        end
    end

    function rateCharacters()
        names = loadCharacterNames()
        for n in names
            rateCharacter(n)
        end
    end

    function test()
        setHandler("GetRule", loadRatingRule)
        setHandler("GetRules", loadRatingRules)
        setHandler("SaveRatingRule", saveRatingRule)
        setHandler("RateCharacter", rateCharacter)
        setHandler("RateCharacters", rateCharacters)
        setHandler("LoadData", loadDataAndProcess)
        setHandler("LoadCharacters", loadCharacters)
        setHandler("UpdateCharacter", updateCharacter)
        setHandler("LoadCharacter", loadCharacter)
        setHandler("ClearDatabase", clearDatabase)
        runServer()
    end

    test()
end