module Server
    include("Database.jl")
    include("EnkaParser.jl")
    using HTTP, Sockets, JSON
    export runServer
    export setFunctionLoadData, setFunctionUpdateCharacter, setFunctionLoadCharacters, setFunctionLoadCharacter, setFunctionClearDatabase

    host = ip"0.0.0.0"
    port = 8080

    router = HTTP.Router()

    global f_updateCharacter = x -> ()
    global f_loadData = () -> []
    global f_loadCharacters = () -> []
    global f_clearDatabase = () -> ()

    function setFunctionLoadData(f)
        global f_loadData = f
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

    function convertTargetToParams(target)
        paramString = split(target, "?")[2]
        paramStrings = split(paramString, "&")
        Dict(map(x -> x[1] => x[2], map(x -> split(x, "="), paramStrings)))
    end

    function queryCharacter(req)
        params = convertTargetToParams(req.target)
        name = params["name"]
        name = replace(name, "+"=>" ")
        resp(string(JSON.json(f_loadCharacter(name))))
    end

    function queryAllCharacters(req)
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

    function initializeRoutes()
        registerRoute("/ping", req -> resp("Hello World !"))
        registerRoute("/char", queryCharacter)
        registerRoute("/chars", queryAllCharacters)
        registerRoute("/refresh", refreshData)
        registerRoute("/clear", clearDatabase)
    end

    function startServer()
        HTTP.serve(router, host, port)
    end

    function runServer()
        initializeRoutes()
        startServer()
    end
end