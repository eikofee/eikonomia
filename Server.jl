module Server
    include("Database.jl")
    using HTTP, Sockets,.Database
    export runServer

    host = ip"0.0.0.0"
    port = 8080

    router = HTTP.Router()

    function registerRoute(path, f)
        HTTP.@register(router, "GET", path, f)
    end

    function resp(content)
        HTTP.Response(200, content)
    end

    function convertTargetToParams(target)
        paramString = split(target, "?")[2]
        paramStrings = split(paramString, "&")
        Dict(map(x -> x[1] => x[2], map(x -> split(x, "="), paramStrings)))
    end

    function queryCharacter(req)
        params = convertTargetToParams(req.target)
        name = params["name"]
        resp(string(loadCharacter(name)))
    end

    function refreshData(req)
        loadData()
        resp("Done")
    end

    function initializeRoutes()
        registerRoute("/ping", req -> resp("Hello World !"))
        registerRoute("/char", queryCharacter)
        registerRoute("/refresh", refreshData)
    end

    function startServer()
        HTTP.serve(router, host, port)
    end

    function runServer()
        initializeRoutes()
        startServer()
    end
end