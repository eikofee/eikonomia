module Server
    include("Database.jl")
    include("EnkaParser.jl")
    using HTTP, Sockets, JSON
    export runServer
    export setFunctionLoadData, setFunctionUpdateCharacter, setFunctionLoadCharacters, setFunctionLoadCharacter, setFunctionClearDatabase
    export setFunctionSaveRatingRule, setFunctionRateCharacter, setFunctionRateCharacters

    host = ip"0.0.0.0"
    port = 8080

    router = HTTP.Router()

    global f_updateCharacter = x -> ()
    global f_loadData = () -> []
    global f_loadCharacters = () -> []
    global f_clearDatabase = () -> ()
    global f_saveRatingRule = x -> ()
    global f_rateCharacters = () -> ()
    global f_rateCharacter = x -> ()

    function setFunctionLoadData(f)
        global f_loadData = f
    end

    function setFunctionSaveRatingRule(f)
        global f_saveRatingRule = f
    end

    function setFunctionRateCharacter(f)
        global f_rateCharacter = f
    end

    function setFunctionRateCharacters(f)
        global f_rateCharacters = f
    end

    function setFunctionLoadCharacter(f)
        global f_loadCharacter = f
    end

    function setFunctionUpdateCharacter(f)
        global f_updateCharacter = f
    end

    function setFunctionLoadCharacters(f)
        global f_loadCharacters = f
    end

    function setFunctionClearDatabase(f)
        global f_clearDatabase = f
    end

    function registerRoute(path, f)
        HTTP.@register(router, "GET", path, f)
    end

    function resp(content)
        HTTP.Response(200, ["Content-Type" => "application/json"]; body=content)
    end

    function format(x)
        replace(x, "+" => " ")
    end

    function convertTargetToParams(target)
        res = Dict()
        paramString = split(target, "?")
        if length(paramString) > 1
            paramStrings = split(paramString[2], "&")
            res = Dict(map(x -> format(x[1]) => format(x[2]), map(x -> split(x, "="), paramStrings)))
        end
        res
    end

    function queryCharacter(req)
        params = convertTargetToParams(req.target)
        name = params["name"]
        resp(string(JSON.json(f_loadCharacter(name))))
    end

    function queryAllCharacters(req)
        params = convertTargetToParams(req.target)
        if "rate" in keys(params) && params["rate"] == "true"
            f_rateCharacters()
        end

        resp(string(JSON.json(f_loadCharacters())))
    end

    function clearDatabase(req)
        f_clearDatabase()
        resp("Done")
    end

    function refreshData(req)
        data = f_loadData()
        foreach(x -> f_updateCharacter(x), data)
        resp("Done")
    end

    function registerRatingRule(req)
        params = convertTargetToParams(req.target)
        display(params)
        name = params["name"]
        ratingRule = Dict(
            "HP" => 0,
            "HP%" => 0,
            "ATK" => 0,
            "ATK%" => 0,
            "DEF" => 0,
            "DEF%" => 0,
            "Crit Rate%" => 0,
            "Crit DMG%" => 0,
            "ER%" => 0,
            "EM" => 0,
        )
        paramsKeys = collect(keys(params))
        for k in collect(keys(ratingRule))
            if k in paramsKeys
                ratingRule[k] = parse(Int64,(params[k]))
            end
        end
        rule = Dict(
            "name" => name,
            "rule" => ratingRule
        )
        f_saveRatingRule(rule)
        resp("Rating rule saved for " * name * ".")
    end

    function rateBuilds(req)
        params = convertTargetToParams(req.target)
        if "name" in keys(params)
            f_rateCharacter(params["name"])
        else
            f_rateCharacters()
        end
        resp("Done.")
    end

    function initializeRoutes()
        registerRoute("/ping", req -> resp("Hello World !"))
        registerRoute("/char", queryCharacter)
        registerRoute("/chars", queryAllCharacters)
        registerRoute("/refresh", refreshData)
        registerRoute("/clear", clearDatabase)
        registerRoute("/ratingRule", registerRatingRule)
        registerRoute("/rate", rateBuilds)
    end

    function startServer()
        HTTP.serve(router, host, port)
    end

    function runServer()
        initializeRoutes()
        startServer()
    end
end