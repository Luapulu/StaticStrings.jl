using StaticStrings
using Test
using Random: shuffle, shuffle!

@testset "StaticStrings.jl" begin
    include("static.jl")

    include("padded.jl")
end
