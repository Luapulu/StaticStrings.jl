module StaticStrings

import Base:
    iterate, length, getindex, lastindex, sizeof,
    ncodeunits, codeunit, isvalid, read, write

using Base: @propagate_inbounds

export StaticString, @static_str

include("static.jl")

end
