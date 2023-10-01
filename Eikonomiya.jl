module Eikonomiya

    include("EnkaParser.jl")
    include("Database.jl")
    include("Server.jl")
    include("Processing.jl")

    envCron = ENV["EIKONOMIYA_RUN_CRON"] == "1"

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

    function runCron()
        command = `/usr/sbin/crond -f -d 0`
        run(command)
    end

    function test()
        initializeFolders()
        setHandler("GetRule", loadRatingRule)
        setHandler("GetRules", loadRatingRules)
        setHandler("SaveRatingRule", saveRatingRule)
        setHandler("RateCharacter", rateCharacter)
        setHandler("RateCharacters", rateCharacters)
        setHandler("LoadData", loadDataAndProcess)
        setHandler("LoadCharacters", loadCharacters)
        setHandler("UpdateCharacter", updateCharacter)
        setHandler("LoadCharacter", loadCharacter)
        if (envCron)
            @async runCron()
        end
        # setHandler("ClearDatabase", clearDatabase)
        runServer()
    end

    test()
end