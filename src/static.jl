const UIntOrChar = Union{Unsigned, AbstractChar}

struct StaticString{N, T<:Unsigned} <: AbstractString
    data::NTuple{N, T}
    function StaticString{N, T}(t::NTuple{M, <:UIntOrChar}) where {N, T, M}
        N == M || throw(DimensionMismatch(
            "cannot construct StaticString{$N, $T} from input of length $M"))
        new{N, T}(t)
    end
end


StaticString{N, T}(cs::UIntOrChar...) where {N, T} = StaticString{N, T}(cs)
StaticString{N, T}(fs::StaticString{N, T}) where {N, T} = fs
StaticString{N, T}(s) where {N, T} = StaticString{N, T}(String(s)...)

_units_to_type(n::Int) = ifelse(n == 1, UInt8, ifelse(n==2, UInt16, UInt32))

macro static_str(s)
    quote
        StaticString{
            length($(esc(s))),
            _units_to_type(maximum(ncodeunits, $(esc(s))))
        }($(esc(s)))
    end
end

convert(::Type{StaticString{N, T}}, s::AbstractString) where {N, T} = StaticString{N, T}(s)

ncodeunits(s::StaticString{N, T}) where {T,N} = N

sizeof(s::StaticString) = sizeof(s.data)

length(s::StaticString) = ncodeunits(s)
length(S::Type{StaticString{N, T}}) where {N, T} = N

lastindex(s::StaticString{N, T}) where {N, T} = N

function iterate(s::StaticString{N, T}, i::Int = 1) where {N, T}
    i > N && return nothing
    return Char(s[i]), i+1
end

codeunit(::StaticString{N, T}) where {N, T} = T
@propagate_inbounds codeunit(s::StaticString, i::Integer) = s.data[i]
@propagate_inbounds getindex(s::StaticString, i::Integer)::Char = s.data[i]

isvalid(s::StaticString, i::Integer) = checkbounds(Bool, s, i)
