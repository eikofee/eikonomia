module Database

    using Mongoc, Dates, JSON
    export printCharacters, loadCharacter, updateCharacter

    client = Mongoc.Client()
    Mongoc.ping(client)
    db = client["eikonomia"]
    characters = db["characters"]

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

    function printCharacters()
        for d in characters
            j = convertToJson(d)
            display(j)
        end
    end
end