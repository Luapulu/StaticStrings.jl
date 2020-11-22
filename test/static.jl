@testset "StaticString" begin
    test_strings = ["foo, bar, buzz!", "T = Σ(δτ)", "Cars: 🚗🚕🚙"]
    test_UInt = [UInt8, UInt16, UInt32]

    @testset "Construction, Conversion and Comparison" begin
        for (i, s) in enumerate(test_strings)

            N = length(s)
            T = test_UInt[i]

            @test String(StaticString{N, T}(s))                 == s  # basic
            @test String(StaticString{N, T}(NTuple{N, T}(s)))   == s  # tuple
            @test String(StaticString{N, T}(s...))              == s  # Vararg Chars
            @test String(StaticString{N, T}(Vector{UInt8}(s)))  == s  # Vector{UInt8}
            @test String(StaticString{N, T}(collect(T, s)...))  == s  # Vararg UInt
            @test String(StaticString{N, T}(Base.CodeUnits(s))) == s  # CodeUnits
            @test String(@static_str(s))                        == s  # macro
            @test String(StaticString{0, T}(""))                == "" # empty 1
            @test String(StaticString{0, T}())                  == "" # empty 2
            @test String(StaticString{N, UInt64}(s))            == s  # larger UInt type

            if T <: Union{UInt16, UInt32}
                @test_throws InexactError StaticString{N, test_UInt[i-1]}(s)  # smaller UInt type
            end

            @test_throws DimensionMismatch StaticString{N-1, T}(s)  # too small
            @test_throws DimensionMismatch StaticString{N+1, T}(s)  # too large

            @test String(StaticString{N, T}(StaticString{N, T}(s))) == s

            # Conversion
            @test convert(StaticString{N, T}, s)::StaticString{N, T} == StaticString{N, T}(s)
            @test convert(String, StaticString{N, T}(s))::String == s

            # Equality
            @test s == StaticString{N, T}(s)
            @test StaticString{N, T}(s)      == s
            @test StaticString{N, T}(s)      == StaticString{N, T}(s)
            @test StaticString{N, UInt64}(s) == StaticString{N, T}(s)

            s_prime = let v = collect(Char, s)
                v2 = shuffle(v)
                while v2 == v; shuffle!(v2); end
                String(v2)
            end

            @test StaticString{N, T}(s_prime) != StaticString{N, T}(s)
            @test StaticString{N, T}(s) != StaticString{N, T}(s_prime)
            @test StaticString{N, T}(s_prime) != s
            @test s != StaticString{N, T}(s_prime)
        end

        @test static"bar" == StaticString{3, UInt8}("bar")

        @test isless("abc", StaticString{3, UInt8}("acc"))
        @test isless(StaticString{3, UInt16}("αβγ"), "αβδ")
    end

    @testset "AbstractString Interface" begin
        for (i, s) in enumerate(test_strings)

            N = length(s)
            T = test_UInt[i]

            stat = StaticString{N, T}(s)

            @test ncodeunits(stat) == N

            @test codeunit(stat) == T

            @test isvalid(stat, rand(1:N)) == true
            @test isvalid(stat, N+1) == false
            @test isvalid(stat, 0) == false

            @test sizeof(stat) == N * sizeof(T)

            s0 = StaticString{0, T}()
            @test isempty(s0) == true
            @test isempty(stat) == false
        end
    end

    @testset "Iteration and Indexing" begin
        for (i, s) in enumerate(test_strings)

            N = length(s)
            T = test_UInt[i]

            ss = StaticString{N, T}(s)
            v = collect(Char, s)

            @test firstindex(ss) == 1
            @test lastindex(ss) == N

            # Not sure how to test that inbounds actually works
            inbound_codeunit(j) = (local s = ss; @inbounds codeunit(s, j))
            @test_broken inbound_codeunit(0) isa UInt8

            inbound_getindex(j) = (local s = ss; @inbounds s[j])
            @test_broken inbound_getindex(0) isa Char

            for j in 1:N
                @test codeunit(ss, j) === T(v[j])
                @test inbound_codeunit(j) === T(v[j])

                @test ss[j] === v[j]
                @test inbound_getindex(j) === v[j]

                @test ss[1:j] == String(v[1:j])
                @test ss[collect(j:N)] == String(v[collect(j:N)])
            end

            let v = collect(Char, s)
                for c in ss
                    @test c isa Char
                    @test c == popfirst!(v)
                end
                @test length(v) == 0
            end

            @test Base.IteratorSize(typeof(ss)) == Base.HasLength()
            @test length(ss) == length(typeof(ss)) == N

            @test Base.IteratorEltype(typeof(ss)) == Base.HasEltype()
            @test eltype(ss) == eltype(typeof(ss)) == Char
        end
    end
end
