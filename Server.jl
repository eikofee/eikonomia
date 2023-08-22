module Server

    using HTTP, Sockets, JSON
    export runServer
    export setHandler

    host = ip"0.0.0.0"
    port = 8080

    router = HTTP.Router()

    global handlers = Dict(
        "UpdateCharacter" => x -> (),
        "LoadData" => () -> [],
        "LoadCharacters" => () -> [],
        "ClearDatabase" => () -> (),
        "SaveRatingRule" => x -> (),
        "RateCharacters" => () -> (),
        "RateCharacter" => x -> (),
        "GetRule" => x -> (),
    )
        

    function setHandler(fname, f)
        global handlers[fname] = f
    end

    function getHandler(fname)
        handlers[fname]
    end

    function registerRoute(path, f)
        HTTP.register!(router, "GET", path, f)
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
        resp(string(JSON.json(getHandler("LoadCharacter")(name))))
    end

    function queryAllCharacters(req)
        params = convertTargetToParams(req.target)
        if "rate" in keys(params) && params["rate"] == "true"
            getHandler("RateCharacters")()
        end

        resp(string(JSON.json(getHandler("LoadCharacters")())))
    end

    function clearDatabase(req)
        getHandler("ClearDatabase")()
        resp("Done")
    end

    function refreshData(req)
        data = getHandler("LoadData")()
        foreach(x -> getHandler("UpdateCharacter")(x), data)
        resp("Done")
    end

    function registerRatingRule(req)
        params = convertTargetToParams(req.target)
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
        getHandler("SaveRatingRule")(rule)
        resp("Rating rule saved for " * name * ".")
    end

    function getRule(req)
        params = convertTargetToParams(req.target)
        name = params["name"]
        resp(string(JSON.json(getHandler("GetRule")(name))))
    end

    function getRules(req)
        resp(string(JSON.json(getHandler("GetRules")())))
    end

    function rateBuilds(req)
        params = convertTargetToParams(req.target)
        if "name" in keys(params)
            getHandler("RateCharacter")(params["name"])
        else
            getHandler("RateCharacters")()
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
        registerRoute("/rule", getRule)
        registerRoute("/rules", getRules)
    end

    function startServer()
        HTTP.serve(router, host, port)
    end

    function runServer()
        initializeRoutes()
        println("Server is running.")
        startServer()
    end
end