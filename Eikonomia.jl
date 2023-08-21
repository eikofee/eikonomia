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
        setFunctionSaveRatingRule(saveRatingRule)
        setFunctionRateCharacter(rateCharacter)
        setFunctionRateCharacters(rateCharacters)
        setFunctionLoadData(loadDataAndProcess)
        setFunctionLoadCharacters(loadCharacters)
        setFunctionUpdateCharacter(updateCharacter)
        setFunctionLoadCharacter(loadCharacter)
        setFunctionClearDatabase(clearDatabase)
        runServer()
    end

    test()
end