module Eikonomia

    include("EnkaParser.jl")
    include("Database.jl")
    include("Server.jl")
    using .EnkaParser, .Database, .Server

    function test()
        runServer()
    end

    test()
end