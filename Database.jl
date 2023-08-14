module Database

    using Mongoc, Dates, JSON
    export saveCharacter, printCharacters

    client = Mongoc.Client()
    Mongoc.ping(client)
    db = client["eikonomia"]
    characters = db["characters"]

    function saveCharacter(char)
        char["lastUpdated"] = Dates.now()
        d = Mongoc.BSON(JSON.json(char))
        push!(characters, d)
    end

    function printCharacters()
        for d in characters
            j = JSON.parse(Mongoc.as_json(d))
            display(j)
        end
    end
end