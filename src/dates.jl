# Conversion from and to types from the `Dates` stdlib

# Dates.FixedPeriod

for (period, unit) = ((Dates.Week, wk), (Dates.Day, d), (Dates.Hour, hr),
                      (Dates.Minute, minute), (Dates.Second, s), (Dates.Millisecond, ms),
                      (Dates.Microsecond, μs), (Dates.Nanosecond, ns))
    @eval unit(::Type{$period}) = $unit
    @eval (::Type{$period})(x::UnitfulBase.AbstractQuantity) = $period(ustrip(unit($period), x))
end

dimension(p::Dates.FixedPeriod) = dimension(typeof(p))
dimension(::Type{<:Dates.FixedPeriod}) = 𝐓

"""
    unit(x::Dates.FixedPeriod)
    unit(x::Type{<:Dates.FixedPeriod})

Return the units that correspond to a particular period.

# Examples

```julia
julia> unit(Second(15)) == u"s"
true

julia> unit(Hour) == u"hr"
true
```
"""
unit(p::Dates.FixedPeriod) = unit(typeof(p))

numtype(x::Dates.FixedPeriod) = numtype(typeof(x))
numtype(::Type{T}) where {T<:Dates.FixedPeriod} = Int64

quantitytype(::Type{T}) where {T<:Dates.FixedPeriod} =
    Quantity{numtype(T),dimension(T),typeof(unit(T))}

ustrip(p::Dates.FixedPeriod) = Dates.value(p)

"""
    Quantity(period::Dates.FixedPeriod)

Create a `Quantity` that corresponds to the given `period`. The numerical value of the
resulting `Quantity` is of type `Int64`.

# Example

```jldoctest
julia> using Dates: Second

julia> Quantity(Second(5))
5 s
```
"""
Quantity(period::Dates.FixedPeriod) = Quantity(ustrip(period), unit(period))

uconvert(u::UnitfulBase.Units, period::Dates.FixedPeriod) = uconvert(u, UnitfulBase.Quantity(period))

(T::Type{<:UnitfulBase.AbstractQuantity})(period::Dates.FixedPeriod) = T(UnitfulBase.Quantity(period))

convert(T::Type{<:UnitfulBase.AbstractQuantity}, period::Dates.FixedPeriod) = T(period)
convert(T::Type{<:Dates.FixedPeriod}, x::UnitfulBase.AbstractQuantity) = T(x)

round(T::Type{<:Dates.FixedPeriod}, x::UnitfulBase.AbstractQuantity, r::RoundingMode=RoundNearest) =
    T(round(numtype(T), ustrip(unit(T), x), r))
round(u::UnitfulBase.Units, period::Dates.FixedPeriod, r::RoundingMode=RoundNearest; kwargs...) =
    round(u, Quantity(period), r; kwargs...)
round(T::Type{<:Number}, u::UnitfulBase.Units, period::Dates.FixedPeriod, r::RoundingMode=RoundNearest;
      kwargs...) = round(T, u, UnitfulBase.Quantity(period), r; kwargs...)
round(T::Type{<:UnitfulBase.AbstractQuantity}, period::Dates.FixedPeriod, r::RoundingMode=RoundNearest;
      kwargs...) = round(T, Quantity(period), r; kwargs...)

for (f, r) in ((:floor,:RoundDown), (:ceil,:RoundUp), (:trunc,:RoundToZero))
    @eval $f(T::Type{<:Dates.FixedPeriod}, x::UnitfulBase.AbstractQuantity) = round(T, x, $r)
    @eval $f(u::UnitfulBase.Units, period::Dates.FixedPeriod; kwargs...) =
        round(u, period, $r; kwargs...)
    @eval $f(T::Type{<:Number}, u::UnitfulBase.Units, period::Dates.FixedPeriod; kwargs...) =
        round(T, u, period, $r; kwargs...)
    @eval $f(T::Type{<:UnitfulBase.AbstractQuantity}, period::Dates.FixedPeriod; kwargs...) =
        round(T, period, $r; kwargs...)
end

for op = (:+, :-, :*, :/, ://, :fld, :cld, :mod, :rem, :atan,
          :(==), :isequal, :<, :isless, :≤)
    @eval $op(x::Dates.FixedPeriod, y::UnitfulBase.AbstractQuantity) = $op(Quantity(x), y)
    @eval $op(x::UnitfulBase.AbstractQuantity, y::Dates.FixedPeriod) = $op(x, Quantity(y))
end
for op = (:*, :/, ://)
    @eval $op(x::Dates.FixedPeriod, y::UnitfulBase.Units) = $op(Quantity(x), y)
    @eval $op(x::UnitfulBase.Units, y::Dates.FixedPeriod) = $op(x, Quantity(y))
end
div(x::Dates.FixedPeriod, y::UnitfulBase.AbstractQuantity, r...) = div(Quantity(x), y, r...)
div(x::UnitfulBase.AbstractQuantity, y::Dates.FixedPeriod, r...) = div(x, Quantity(y), r...)

isapprox(x::Dates.FixedPeriod, y::UnitfulBase.AbstractQuantity; kwargs...) =
    isapprox(Quantity(x), y; kwargs...)
isapprox(x::UnitfulBase.AbstractQuantity, y::Dates.FixedPeriod; kwargs...) =
    isapprox(x, Quantity(y); kwargs...)

function isapprox(x::AbstractArray{<:UnitfulBase.AbstractQuantity}, y::AbstractArray{T};
                  kwargs...) where {T<:Dates.Period}
    if isconcretetype(T)
        y′ = reinterpret(quantitytype(T), y)
    else
        y′ = Quantity.(y)
    end
    isapprox(x, y′; kwargs...)
end
isapprox(x::AbstractArray{<:Dates.FixedPeriod}, y::AbstractArray{<:UnitfulBase.AbstractQuantity};
         kwargs...) = isapprox(y, x; kwargs...)

Base.promote_rule(::Type{Quantity{T,𝐓,U}}, ::Type{S}) where {T,U,S<:Dates.FixedPeriod} =
    promote_type(Quantity{T,𝐓,U}, quantitytype(S))

# Dates.CompoundPeriod

dimension(p::Dates.CompoundPeriod) = dimension(typeof(p))
dimension(::Type{<:Dates.CompoundPeriod}) = 𝐓

uconvert(u::UnitfulBase.Units, period::Dates.CompoundPeriod) =
    Quantity{promote_type(Int64,typeof(UnitfulBase.convfact(u,ns))),dimension(u),typeof(u)}(period)

try_uconvert(u::UnitfulBase.Units, period::Dates.CompoundPeriod) = nothing
function try_uconvert(u::TimeUnits, period::Dates.CompoundPeriod)
    T = Quantity{promote_type(Int64,typeof(UnitfulBase.convfact(u,ns))),dimension(u),typeof(u)}
    val = zero(T)
    for p in period.periods
        p isa Dates.FixedPeriod || return nothing
        val += T(p)
    end
    val
end

(T::Type{<:UnitfulBase.AbstractQuantity})(period::Dates.CompoundPeriod) =
    mapreduce(T, +, period.periods, init=zero(T))

convert(T::Type{<:UnitfulBase.AbstractQuantity}, period::Dates.CompoundPeriod) = T(period)

round(u::UnitfulBase.Units, period::Dates.CompoundPeriod, r::RoundingMode=RoundNearest; kwargs...) =
    round(u, uconvert(u, period), r; kwargs...)
round(T::Type{<:Number}, u::UnitfulBase.Units, period::Dates.CompoundPeriod,
      r::RoundingMode=RoundNearest; kwargs...) =
    round(T, u, uconvert(u, period), r; kwargs...)
round(T::Type{<:UnitfulBase.AbstractQuantity}, period::Dates.CompoundPeriod,
      r::RoundingMode=RoundNearest; kwargs...) =
    round(T, T(period), r; kwargs...)

for (f, r) in ((:floor,:RoundDown), (:ceil,:RoundUp), (:trunc,:RoundToZero))
    @eval $f(u::UnitfulBase.Units, period::Dates.CompoundPeriod; kwargs...) =
        round(u, period, $r; kwargs...)
    @eval $f(T::Type{<:Number}, u::UnitfulBase.Units, period::Dates.CompoundPeriod; kwargs...) =
        round(T, u, period, $r; kwargs...)
    @eval $f(T::Type{<:UnitfulBase.AbstractQuantity}, period::Dates.CompoundPeriod; kwargs...) =
        round(T, period, $r; kwargs...)
end

for op = (:fld, :cld, :atan, :<, :isless, :≤)
    @eval $op(x::Dates.CompoundPeriod, y::UnitfulBase.AbstractQuantity) = $op(uconvert(unit(y),x), y)
    @eval $op(x::UnitfulBase.AbstractQuantity, y::Dates.CompoundPeriod) = $op(x, uconvert(unit(x),y))
end
div(x::Dates.CompoundPeriod, y::UnitfulBase.AbstractQuantity, r...) = div(uconvert(unit(y),x), y, r...)
div(x::UnitfulBase.AbstractQuantity, y::Dates.CompoundPeriod, r...) = div(x, uconvert(unit(x),y), r...)
mod(x::Dates.CompoundPeriod, y::UnitfulBase.AbstractQuantity) = mod(uconvert(unit(y),x), y)
rem(x::Dates.CompoundPeriod, y::UnitfulBase.AbstractQuantity) = rem(uconvert(unit(y),x), y)
for op = (:(==), :isequal)
    @eval $op(x::Dates.CompoundPeriod, y::UnitfulBase.AbstractQuantity{T,𝐓,U}) where {T,U} =
        $op(try_uconvert(U(), x), y)
    @eval $op(x::UnitfulBase.AbstractQuantity{T,𝐓,U}, y::Dates.CompoundPeriod) where {T,U} =
        $op(x, try_uconvert(U(), y))
end

isapprox(x::Dates.CompoundPeriod, y::UnitfulBase.AbstractQuantity; kwargs...) =
    dimension(y) === 𝐓 ? isapprox(uconvert(unit(y), x), y; kwargs...) : false
isapprox(x::UnitfulBase.AbstractQuantity, y::Dates.CompoundPeriod; kwargs...) =
    dimension(x) === 𝐓 ? isapprox(x, uconvert(unit(x), y); kwargs...) : false

function isapprox(x::AbstractArray{<:UnitfulBase.AbstractQuantity},
                  y::AbstractArray{Dates.CompoundPeriod}; kwargs...)
    if dimension(eltype(x)) === 𝐓
        isapprox(x, uconvert.(unit(eltype(x)), y); kwargs...)
    else
        false
    end
end

isapprox(x::AbstractArray{Dates.CompoundPeriod}, y::AbstractArray{<:UnitfulBase.AbstractQuantity};
         kwargs...) = isapprox(y, x; kwargs...)
