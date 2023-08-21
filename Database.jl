module Database

    using Mongoc, Dates, JSON
    export printCharacters, loadCharacter, updateCharacter, loadCharacters, clearDatabase, loadRatingRule, saveRatingRule, loadCharacterNames, loadRatingRules

    client = Mongoc.Client()
    Mongoc.ping(client)
    db = client["eikonomia"]
    characters = db["characters"]
    ratingRules = db["ratingRules"]

    function findOne(collection, field, value)
        Mongoc.find_one(collection, Mongoc.BSON("{\"" * field * "\":\"" * value * "\"}"))
    end

    function deleteOne(collection, item)
        Mongoc.delete_one(collection, item)
    end

    function convertToJson(o)
        JSON.parse(Mongoc.as_json(o))
    end

    function loadCharacter(name)
        d = findOne(characters, "name", name)
        if d !== nothing
            convertToJson(d)
        end
    end

    function updateCharacter(char)
        name = char["name"]
        d = findOne(characters, "name", name)
        if d !== nothing
            deleteOne(characters, d)
        end
        saveCharacter(char)
    end

    function saveCharacter(char)
        char["lastUpdated"] = Dates.now()
        d = Mongoc.BSON(JSON.json(char))
        push!(characters, d)
    end

    function loadCharacters()
        data = map(x -> convertToJson(x), characters)
        Dict(map(x -> x["name"] => x, data))
    end

    function loadCharacterNames()
        map(x -> x["name"], characters)
    end

    function loadRatingRule(name)
        d = findOne(ratingRules, "name", name)
        if d !== nothing
            convertToJson(d)
        end
    end

    function loadRatingRules()
        data = map(x -> convertToJson(x), ratingRules)
        Dict(map(x -> x["name"] => x, data))
    end

    function saveRatingRule(rule)
        rule["lastUpdated"] = Dates.now()
        d = Mongoc.BSON(JSON.json(rule))
        push!(ratingRules, d)
    end

    function printCharacters()
        d = loadCharacters()
        foreach(x -> display(x), d)
    end

    function clearDatabase()
        Mongoc.empty!(characters)
    end
end