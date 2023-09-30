module Database

    using Dates, JSON
    export printCharacters, loadCharacter, updateCharacter, loadCharacters, loadRatingRule, saveRatingRule, loadCharacterNames, loadRatingRules
    export initializeFolders

    charactersPath = "./data/characters/"
    ratingRulesPath = "./data/ratingRules/"

    function initializeFolders()
        if !isdir(charactersPath)
            mkdir(charactersPath)
        end
        if !isdir(ratingRulesPath)
            mkdir(ratingRulesPath)
        end
    end

    function findOne(path, name)
        res = nothing
        if isfile(path * name)
            f = open(path * name, "r")
            content = read(f, String)
            close(f)
            res = JSON.parse(content)
        end
        res
    end

    function deleteOne(path, name)
        if isfile(path * name)
            rm(path * name)
        end
    end

    function saveOne(path, obj)
        name = obj["name"]
        content = JSON.json(obj)
        f = open(path * name, "w")
        write(f, content)
        close(f)
    end

    function loadCharacter(name)
        findOne(charactersPath, name)
    end

    function updateCharacter(char)
        name = char["name"]
        d = findOne(charactersPath, name)
        if d !== nothing
            deleteOne(charactersPath, name)
        end
        saveCharacter(char)
    end

    function saveCharacter(char)
        saveOne(charactersPath, char)
    end

    function loadCharacterNames()
        readdir(charactersPath)
    end

    function loadCharacters()
        characterNames = loadCharacterNames()
        data = map(x -> loadCharacter(x), characterNames)
        Dict(map(x -> x["name"] => x, data))
    end

    function loadRatingRule(name)
        findOne(ratingRulesPath, name)
    end

    function loadRatingRules()
        ratingRules = readdir(ratingRulesPath)
        data = map(x -> findOne(ratingRulesPath, x), ratingRules)
        Dict(map(x -> x["name"] => x, data))
    end

    function saveRatingRule(rule)
        rule["lastUpdated"] = Dates.now()
        saveOne(ratingRulesPath, rule)
    end

    function printCharacters()
        d = loadCharacters()
        foreach(x -> display(x), d)
    end

    # function clearDatabase()
    #     Mongoc.empty!(characters)
    # end
end