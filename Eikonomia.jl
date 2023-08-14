module Eikonomia

    include("EnkaParser.jl")
    include("Database.jl")
    using .EnkaParser, .Database

    function test()
        chars = loadData()
        for c in chars
            saveCharacter(c)
        end
        printCharacters()
    end

    test()
end