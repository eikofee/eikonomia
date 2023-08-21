module Eikonomia

    include("EnkaParser.jl")
    include("Database.jl")
    include("Server.jl")
    include("Processing.jl")
    using .EnkaParser, .Database, .Server, .Processing

    function loadDataAndProcess()
        data = loadData()
        map(x -> processAdditionalData(x), data)
    end
    function test()
        setFunctionLoadData(loadDataAndProcess)
        setFunctionLoadCharacters(loadCharacters)
        setFunctionUpdateCharacter(updateCharacter)
        setFunctionLoadCharacter(loadCharacter)
        setFunctionClearDatabase(clearDatabase)
        runServer()
    end

    test()
end