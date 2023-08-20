module Server
    include("Database.jl")
    include("EnkaParser.jl")
    using HTTP, Sockets
    export runServer
    export setFunctionLoadData, setFunctionUpdateCharacter, setFunctionLoadCharacters

    host = ip"0.0.0.0"
    port = 8080

    router = HTTP.Router()

    f_updateCharacter = x -> ()
    f_loadData = () -> []
    f_loadCharacters = () -> []

    function setFunctionLoadData(f)
        global f_loadData = f
    end

    function setFunctionUpdateCharacter(f)
        global f_updateCharacter = f
    end

    function setFunctionLoadCharacters(f)
        global f_loadCharacters = f
    end

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
        resp(string(f_loadCharacter(name)))
    end

    function queryAllCharacters(req)
        resp(string(f_loadCharacters()))
    end

    function refreshData(req)
        data = f_loadData()
        foreach(x -> f_updateCharacter(x), data)
        resp("Done")
    end

    function initializeRoutes()
        registerRoute("/ping", req -> resp("Hello World !"))
        registerRoute("/char", queryCharacter)
        registerRoute("/chars", queryAllCharacters)
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