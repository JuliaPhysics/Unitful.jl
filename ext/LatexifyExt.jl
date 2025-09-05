#=========================================#
# Extension for Unitful.jl + Latexify.jl, #
# based on UnitfulLatexify.jl by          #
# David Gustavsson (@gustaphe)            #
#=========================================#
module LatexifyExt
using Unitful:
    Unitful,
    Unit,
    Units,
    AbstractQuantity,
    AffineUnits,
    AffineQuantity,
    power,
    abbr,
    name,
    tens,
    sortexp,
    unit,
    NoDims,
    ustrip,
    @u_str,
    genericunit,
    has_unit_spacing
using Latexify:
    Latexify,
    @latexrecipe,
    latexify,
    _latexarray,
    latexraw,
    FancyNumberFormatter,
    PlainNumberFormatter,
    StyledNumberFormatter,
    SiunitxNumberFormatter,
    AbstractNumberFormatter
using LaTeXStrings: LaTeXString

import Latexify: latexify

import Base.*

# utility functions ------------------

function get_formatter(kwargs)
    fmt = get(kwargs, :fmt, FancyNumberFormatter())
    if fmt isa String
        fmt = StyledNumberFormatter(fmt)
    end
    return fmt
end
get_format_env(fmt::SiunitxNumberFormatter) = :raw
get_format_env(fmt) = :inline


function getunitname(p::T, unitformat) where {T<:Unit}
    unitname = get(unitnames, (unitformat, name(p)), nothing)
    isnothing(unitname) || return unitname
    if unitformat === :siunitx
        return "\\$(lowercase(String(name(p))))"
    end
    return abbr(p)
end

function listunits(::T) where {T<:Units}
    return sortexp(T.parameters[1])
end

"""
```julia
intersperse(t, delim)
```
Create a vector whose elements alternate between the elements of `t` and `delim`, analogous
to `join` for strings.

# Example
```julia
julia> intersperse((1, 2, 3, 4), :a)
[1, :a, 2, :a, 3, :a, 4]
```
"""
function intersperse(t::T, delim::U) where {T,U}
    iszero(length(t)) && return ()
    L = length(t) * 2 - 1
    out = Vector{Union{typeof.(t)...,U}}(undef, L)
    out[1:2:L] .= t
    out[2:2:L] .= delim
    return out
end

# default ------------------------------

@latexrecipe function f(p::Unit)
    fmt = get_formatter(kwargs)
    env --> get_format_env(fmt)
    return _transform(p, fmt)
end

@latexrecipe function f(u::Units; permode=:power)
    fmt = get_formatter(kwargs)
    env --> get_format_env(fmt)
    return _transform(u, fmt)
end

@latexrecipe function f(q::AbstractQuantity)
    fmt = get_formatter(kwargs)
    env --> get_format_env(fmt)
    operation := :*

    return _transform(q, fmt)
end

struct NakedUnits
    u::Units
end
struct NakedNumber
    n::Number
end

@latexrecipe function f(u::NakedUnits; permode=:power)
    fmt = get_formatter(kwargs)
    unitlist = listunits(u.u)
    if fmt isa SiunitxNumberFormatter
        fmt.simple && return Expr(:latexifymerge, intersperse(unitlist, ".")...)
        return Expr(:latexifymerge, unitlist...)
    end
    if permode === :power
        return Expr(:latexifymerge, intersperse(unitlist, "\\,")...)
    end

    numunits = [x for x in unitlist if power(x) >= 0]
    denunits = [typeof(x)(tens(x), -power(x)) for x in unitlist if power(x) < 0]

    numerator = intersperse(numunits, "\\,")
    if isempty(denunits)
        return Expr(:latexifymerge, numerator...)
    end
    if isempty(numunits)
        numerator = [1]
    end
    denominator = intersperse(denunits, "\\,")

    if permode === :slash
        return Expr(:latexifymerge, numerator..., "\\,/\\,", denominator...)
    end
    if permode === :frac
        return Expr(:latexifymerge, "\\frac{", numerator..., "}{", denominator..., "}")
    end
    return error("permode $permode undefined.")
end

@latexrecipe function f(n::NakedNumber)
    fmt = get_formatter(kwargs)
    if fmt isa SiunitxNumberFormatter
        fmt := PlainNumberFormatter()
    end
    return n.n
end

function _transform(p::Unit, fmt::SiunitxNumberFormatter)
    unitformat = fmt.simple ? :siunitxsimple : :siunitx
    prefix = prefixes[(unitformat, tens(p))]
    pow = power(p)
    unitname = getunitname(p, unitformat)
    if fmt.simple
        per = ""
        expo = pow == 1//1 ? "" : "^{$(latexify(pow; fmt="%g", env=:raw))}"
    else
        per = pow < 0 ? "\\per" : ""
        pow = abs(pow)
        expo = pow == 1//1 ? "" : "\\tothe{$(latexify(pow; fmt="%g", env=:raw))}"
    end
    return LaTeXString("$per$prefix$unitname$expo")
end
function _transform(p::Unit, fmt::AbstractNumberFormatter)
    prefix = prefixes[(:mathrm, tens(p))]
    unitname = getunitname(p, :mathrm)
    pow = power(p)
    expo = pow == 1//1 ? "" : "^{$(latexify(pow; fmt="%g", env=:raw))}"
    return LaTeXString("\\mathrm{$prefix$unitname}$expo")
end

function _transform(u::Units, fmt::SiunitxNumberFormatter)
    opening = fmt.version < 3 ? "\\si{" : "\\unit{"
    return Expr(:latexifymerge, opening, NakedUnits(u), "}")
end
_transform(u::Units, ::AbstractNumberFormatter) = Expr(:latexifymerge, NakedUnits(u))

function _transform(q::AbstractQuantity, fmt::SiunitxNumberFormatter)
    opening = fmt.version < 3 ? "\\SI{" : "\\qty{"
    return Expr(:latexifymerge, opening, NakedNumber(q.val), "}{", NakedUnits(unit(q)), "}")
end
function _transform(q::AbstractQuantity, ::AbstractNumberFormatter)
    Expr(
        :latexifymerge,
        NakedNumber(q.val),
        has_unit_spacing(unit(q)) ? "\\," : nothing,
        NakedUnits(unit(q)),
    )
end
_transform(n::NakedNumber, ::SiunitxNumberFormatter) = PlainNumberFormatter(n.n)


# affine -------------------------------

@latexrecipe function f(u::AffineUnits)
    fmt = get_formatter(kwargs)
    if u == Unitful.°C
        unitname = :Celsius
    elseif u == Unitful.°F
        unitname = :Fahrenheit
    else
        # If it's not celsius or farenheit, let it do the default thing
        return genericunit(u)
    end
    if fmt isa SiunitxNumberFormatter
        env --> :raw
        return Expr(:latexifymerge, "\\unit{", unitnames[(:siunitx, unitname)], "}")
    end
    env --> :inline
    return LaTeXString(unitnames[(:mathrm, unitname)])
end

@latexrecipe function f(q::AffineQuantity)
    fmt = get_formatter(kwargs)
    u = unit(q)
    if u == Unitful.°C
        unitname = :Celsius
    elseif u == Unitful.°F
        unitname = :Fahrenheit
    else
        # If it's not celsius or farenheit, let it do the default thing
        return ustrip(q)*genericunit(u)
    end
    if fmt isa SiunitxNumberFormatter
        env --> :raw
        return Expr(
            :latexifymerge,
            "\\qty{",
            NakedNumber(q.val),
            "}{",
            unitnames[(:siunitx, unitname)],
            "}",
        )
    end
    env --> :inline
    return Expr(:latexifymerge, q.val, "\\,\\mathrm{", unitnames[(:mathrm, unitname)], "}")
end

# arrays ------------------------- 
@latexrecipe function f( # Array{Quantity{U}}
    a::AbstractArray{<:AbstractQuantity{N,D,U}};
) where {N<:Number,D,U}
    # Array of quantities with the same unit
    env --> :equation
    return Expr(
        :latexifymerge, ustrip.(a), has_unit_spacing(first(a)) ? "\\," : "", unit(first(a))
    )
end

@latexrecipe function f( # Tuple{Quantity{U}}
    l::Tuple{T,Vararg{T}},
) where {T<:AbstractQuantity{N,D,U}} where {N<:Number,D,U}
    fmt = get_formatter(kwargs)
    if fmt isa SiunitxNumberFormatter
        env --> :raw
        opening = fmt.version < 3 ? "\\SIlist{" : "\\qtylist{"
        return Expr(
            :latexifymerge,
            opening,
            intersperse(NakedNumber.(ustrip.(l)), ";")...,
            "}{",
            NakedUnits(unit(first(l))),
            "}",
        )
    end
    return collect(l)
end

# label (for plots) ------------------------------------

@latexrecipe function f(l::AbstractString, u::Units; labelformat=:slash)
    labelformat === :slash && return Expr(:latexifymerge, l, "\\;\\left/\\;", u, "\\right.")
    labelformat === :square && return Expr(:latexifymerge, l, "\\;\\left[", u, "\\right]")
    labelformat === :round && return Expr(:latexifymerge, l, "\\;\\left(", u, "\\right)")
    labelformat === :frac && return Expr(:latexifymerge, "\\frac{", l, "}{", u, "}")
    error("Unknown labelformat $labelformat")
end

# prefixes ------------------------------

"""
prefixes are listed in this dictionary
`(unitformat::Symbol, pow::Integer) => prefix::String`
"""
const prefixes = begin
    Dict(
        (:mathrm, -24) => "y",
        (:mathrm, -21) => "z",
        (:mathrm, -18) => "a",
        (:mathrm, -15) => "f",
        (:mathrm, -12) => "p",
        (:mathrm, -9) => "n",
        (:mathrm, -6) => "\\mu{}",
        (:mathrm, -3) => "m",
        (:mathrm, -2) => "c",
        (:mathrm, -1) => "d",
        (:mathrm, 0) => "",
        (:mathrm, 1) => "D",
        (:mathrm, 2) => "h",
        (:mathrm, 3) => "k",
        (:mathrm, 6) => "M",
        (:mathrm, 9) => "G",
        (:mathrm, 12) => "T",
        (:mathrm, 15) => "P",
        (:mathrm, 18) => "E",
        (:mathrm, 21) => "Z",
        (:mathrm, 24) => "Y",
        (:siunitx, -24) => "\\yocto",
        (:siunitx, -21) => "\\zepto",
        (:siunitx, -18) => "\\atto",
        (:siunitx, -15) => "\\femto",
        (:siunitx, -12) => "\\pico",
        (:siunitx, -9) => "\\nano",
        (:siunitx, -6) => "\\micro",
        (:siunitx, -3) => "\\milli",
        (:siunitx, -2) => "\\centi",
        (:siunitx, -1) => "\\deci",
        (:siunitx, 0) => "",
        (:siunitx, 1) => "\\deka",
        (:siunitx, 2) => "\\hecto",
        (:siunitx, 3) => "\\kilo",
        (:siunitx, 6) => "\\mega",
        (:siunitx, 9) => "\\giga",
        (:siunitx, 12) => "\\tera",
        (:siunitx, 15) => "\\peta",
        (:siunitx, 18) => "\\exa",
        (:siunitx, 21) => "\\zetta",
        (:siunitx, 24) => "\\yotta",
        (:siunitxsimple, -24) => "y",
        (:siunitxsimple, -21) => "z",
        (:siunitxsimple, -18) => "a",
        (:siunitxsimple, -15) => "f",
        (:siunitxsimple, -12) => "p",
        (:siunitxsimple, -9) => "n",
        (:siunitxsimple, -6) => "\\u",
        (:siunitxsimple, -3) => "m",
        (:siunitxsimple, -2) => "c",
        (:siunitxsimple, -1) => "d",
        (:siunitxsimple, 0) => "",
        (:siunitxsimple, 1) => "D",
        (:siunitxsimple, 2) => "h",
        (:siunitxsimple, 3) => "k",
        (:siunitxsimple, 6) => "M",
        (:siunitxsimple, 9) => "G",
        (:siunitxsimple, 12) => "T",
        (:siunitxsimple, 15) => "P",
        (:siunitxsimple, 18) => "E",
        (:siunitxsimple, 21) => "Z",
        (:siunitxsimple, 24) => "Y",
    )
end

# unit names ------------------------------

""""
`unitnames`

Unit names generally follow a simple scheme, but there are exceptions, listed in this
dictionary: `(unitformat::Symbol, name::Symbol) => unitname::String`
"""
const unitnames = begin
    Dict(
        (:mathrm, :Percent) => "\\%",
        (:siunitxsimple, :Percent) => "\\%",
        (:mathrm, :Degree) => "^{\\circ}",
        (:siunitxsimple, :Degree) => "\\degree",
        (:siunitx, :eV) => "\\electronvolt",
        (:mathrm, :Ohm) => "\\Omega",
        (:mathrm, :Celsius) => "^\\circ C",
        (:siunitx, :Celsius) => "\\celsius",
        (:siunitxsimple, :Celsius) => "\\celsius",
        (:mathrm, :Fahrenheit) => "^\\circ F",
        (:siunitx, :Fahrenheit) => "\\fahrenheit",
        (:siunitxsimple, :Fahrenheit) => "\\fahrenheit",
        (:siunitxsimple, :Angstrom) => "\\angstrom",
        (:mathrm, :Angstrom) => "\\AA",
        (:mathrm, :DoubleTurn) => "\\S",
        (:mathrm, :Turn) => "\\tau",
        (:mathrm, :HalfTurn) => "\\pi",
        (:mathrm, :Quadrant) => "\\frac{\\pi}{2}",
        (:mathrm, :Sextant) => "\\frac{\\pi}{3}",
        (:mathrm, :Octant) => "\\frac{\\pi}{4}",
        (:mathrm, :ClockPosition) => "\\frac{\\pi}{12}",
        (:mathrm, :HourAngle) => "\\frac{\\pi}{24}",
        (:mathrm, :CompassPoint) => "\\frac{\\pi}{32}",
        (:mathrm, :Hexacontade) => "\\frac{\\pi}{60}",
        (:mathrm, :BinaryRadian) => "\\frac{\\pi}{256}",
        (:mathrm, :DiameterPart) => "\\oslash", # This is slightly wrong
        (:mathrm, :Gradian) => "^g",
        (:mathrm, :Arcminute) => "'",
        (:mathrm, :Arcsecond) => "''",
        (:mathrm, :ArcsecondShort) => "''",
    )
end

end # LatexifyExt