module Eikonomia

    include("EnkaParser.jl")
    include("Database.jl")
    include("Server.jl")
    using .EnkaParser, .Database, .Server

    function test()
        setFunctionLoadData(loadData)
        setFunctionLoadCharacters(loadCharacters)
        setFunctionUpdateCharacter(updateCharacter)
        runServer()
    end

    test()
end