__precompile__(true)
module Unitful

using Compat

@static if VERSION < v"0.6.0-dev.2390"
    using Ranges
end

@static if VERSION < v"0.6.0-dev.1632" # Julia PR #17623
    import Base: .+, .-, .*, ./, .\, .<, .<=
end

import Base: ==, <, <=, +, -, *, /, //, ^
import Base: show, convert
import Base: abs, abs2, float, fma, muladd, inv, sqrt, cbrt
import Base: min, max, floor, ceil, real, imag, conj
import Base: exp, exp10, exp2, expm1, log, log10, log1p, log2
import Base: sin, cos, tan, cot, sec, csc, atan2, cis, vecnorm

import Base: mod, rem, div, fld, cld, trunc, round, sign, signbit
import Base: isless, isapprox, isinteger, isreal, isinf, isfinite, isnan
import Base: copysign, flipsign
import Base: prevfloat, nextfloat, maxintfloat, rat, step #, linspace
import Base: length, float, start, done, next, last, one, zero, colon#, range
import Base: getindex, eltype, step, last, first, frexp
import Base: Integer, Rational, typemin, typemax
import Base: steprange_last, unsigned

import Base.LinAlg: istril, istriu

export unit, dimension, uconvert, ustrip, upreferred
export @dimension, @derived_dimension, @refunit, @unit, @u_str
export Quantity
export DimensionlessQuantity
export NoUnits, NoDims

const unitmodules = Vector{Module}()
const basefactors = Dict{Symbol,Tuple{Float64,Rational{Int}}}()

include("Types.jl")
const promotion = Dict{Symbol,Unit}()

include("User.jl")
const NoUnits = FreeUnits{(), Dimensions{()}}()
const NoDims = Dimensions{()}()
@inline isunitless{N}(::Units{N}) = N == ()

(y::FreeUnits)(x::Number) = uconvert(y,x)
(y::ContextUnits)(x::Number) = uconvert(y,x)

"""
```
type DimensionError{T,S} <: Exception
  x::T
  y::S
end
```

Thrown when dimensions don't match in an operation that demands they do.
Display `x` and `y` in error message.
"""
type DimensionError{T,S} <: Exception
    x::T
    y::S
end
Base.showerror(io::IO, e::DimensionError) =
    print(io,"DimensionError: $(e.x) and $(e.y) are not dimensionally compatible.");

numtype{T}(::Quantity{T}) = T
numtype{T,D,U}(::Type{Quantity{T,D,U}}) = T

"""
```
ustrip(x::Number)
```

Returns the number out in front of any units. This may be different from the value
in the case of dimensionless quantities. See [`uconvert`](@ref) and the example
below. Because the units are removed, information may be lost and this should
be used with some care.

This function is just calling `x/unit(x)`, which is as fast as directly
accessing the `val` field of `x::Quantity`, but also works for any other kind
of number.

This function is mainly intended for compatibility with packages that don't know
how to handle quantities. This function may be deprecated in the future.

```jldoctest
julia> ustrip(2u"μm/m") == 2
true

julia> uconvert(NoUnits, 2u"μm/m") == 2//1000000
true
```
"""
@inline ustrip(x::Number) = x/unit(x)

"""
```
ustrip{Q<:Quantity}(x::Array{Q})
```

Strip units from an `Array` by reinterpreting to type `T`. The resulting
`Array` is a "unit free view" into array `x`. Because the units are
removed, information may be lost and this should be used with some care.

This function is provided primarily for compatibility purposes; you could pass
the result to PyPlot, for example. This function may be deprecated in the future.

```jldoctest
julia> a = [1u"m", 2u"m"]
2-element Array{Quantity{Int64, Dimensions:{𝐋}, Units:{m}},1}:
 1 m
 2 m

julia> b = ustrip(a)
2-element Array{Int64,1}:
 1
 2

julia> a[1] = 3u"m"; b
2-element Array{Int64,1}:
 3
 2
```
"""
@inline ustrip{Q<:Quantity}(x::Array{Q}) = reinterpret(numtype(Q), x)

"""
```
ustrip{Q<:Quantity}(A::AbstractArray{Q})
```

Strip units from an `AbstractArray` by making a new array without units using
array comprehensions.

This function is provided primarily for compatibility purposes; you could pass
the result to PyPlot, for example. This function may be deprecated in the future.
"""
ustrip{Q<:Quantity}(A::AbstractArray{Q}) = (numtype(Q))[ustrip(x) for x in A]

"""
```
ustrip{T<:Number}(x::AbstractArray{T})
```

Fall-back that returns `x`.
"""
@inline ustrip{T<:Number}(A::AbstractArray{T}) = A

ustrip{T<:Quantity}(A::Diagonal{T}) = Diagonal(ustrip(A.diag))
ustrip{T<:Quantity}(A::Bidiagonal{T}) =
    Bidiagonal(ustrip(A.dv), ustrip(A.ev), A.isupper)
ustrip{T<:Quantity}(A::Tridiagonal{T}) =
    Tridiagonal(ustrip(A.dl), ustrip(A.d), ustrip(A.du))
ustrip{T<:Quantity}(A::SymTridiagonal{T}) =
    SymTridiagonal(ustrip(A.dv), ustrip(A.ev))

"""
```
unit{T,D,U}(x::Quantity{T,D,U})
```

Returns the units associated with a quantity.

Examples:

```jldoctest
julia> unit(1.0u"m") == u"m"
true

julia> typeof(u"m")
Unitful.FreeUnits{(Unitful.Unit{:Meter,Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)}}(0, 1//1),),Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)}}
```
"""
@inline unit{T,D,U}(x::Quantity{T,D,U}) = U()

"""
```
unit{T,D,U}(x::Type{Quantity{T,D,U}})
```

Returns the units associated with a quantity type, `ContextUnits(U(),P())`.

Examples:

```jldoctest
julia> unit(typeof(1.0u"m")) == u"m"
true
```
"""
@inline unit{T,D,U}(::Type{Quantity{T,D,U}}) = U()


"""
```
unit(x::Number)
```

Returns a `Unitful.Units{(), Dimensions{()}}` object to indicate that ordinary
numbers have no units. This is a singleton, which we export as `NoUnits`.
The unit is displayed as an empty string.

Examples:

```jldoctest
julia> typeof(unit(1.0))
Unitful.FreeUnits{(),Unitful.Dimensions{()}}
julia> typeof(unit(Float64))
Unitful.FreeUnits{(),Unitful.Dimensions{()}}
julia> unit(1.0) == NoUnits
true
```
"""
@inline unit(x::Number) = NoUnits
@inline unit{T<:Number}(x::Type{T}) = NoUnits

"""
```
dimension(x::Number)
dimension{T<:Number}(x::Type{T})
```

Returns a `Unitful.Dimensions{()}` object to indicate that ordinary
numbers are dimensionless. This is a singleton, which we export as `NoDims`.
The dimension is displayed as an empty string.

Examples:

```jldoctest
julia> typeof(dimension(1.0))
Unitful.Dimensions{()}
julia> typeof(dimension(Float64))
Unitful.Dimensions{()}
julia> dimension(1.0) == NoDims
true
```
"""
@inline dimension(x::Number) = NoDims
@inline dimension{T<:Number}(x::Type{T}) = NoDims

"""
```
dimension{U,D}(u::Units{U,D})
```

Returns a [`Unitful.Dimensions`](@ref) object corresponding to the dimensions
of the units, `D()`. For a dimensionless combination of units, a
`Unitful.Dimensions{()}` object is returned.

Examples:

```jldoctest
julia> dimension(u"m")
𝐋

julia> typeof(dimension(u"m"))
Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)}

julia> typeof(dimension(u"m/km"))
Unitful.Dimensions{()}
```
"""
@inline dimension{U,D}(u::Units{U,D}) = D()

"""
```
dimension{T,D}(x::Quantity{T,D})
```

Returns a [`Unitful.Dimensions`](@ref) object `D()` corresponding to the
dimensions of quantity `x`. For a dimensionless [`Unitful.Quantity`](@ref), a
`Unitful.Dimensions{()}` object is returned.

Examples:

```jldoctest
julia> dimension(1.0u"m")
𝐋

julia> typeof(dimension(1.0u"m/μm"))
Unitful.Dimensions{()}
```
"""
@inline dimension{T,D}(x::Quantity{T,D}) = D()
@inline dimension{T,D,U}(::Type{Quantity{T,D,U}}) = D()

"""
```
dimension{T<:Number}(x::AbstractArray{T})
```

Just calls `map(dimension, x)`.
"""
dimension{T<:Number}(x::AbstractArray{T}) = map(dimension, x)

"""
```
dimension{T<:Units}(x::AbstractArray{T})
```

Just calls `map(dimension, x)`.
"""
dimension{T<:Units}(x::AbstractArray{T}) = map(dimension, x)

"""
```
@generated function Quantity(x::Number, y::Units)
```
Outer constructor for `Quantity`s. This is a generated function to avoid
determining the dimensions of a given set of units each time a new quantity is
made.
"""
@generated function Quantity(x::Number, y::Units)
    u = y()
    d = dimension(u)
    :(Quantity{typeof(x), typeof($d), typeof($u)}(x))
end
Quantity(x::Number, y::Units{()}) = x

"""
```
function promote_unit(::Units, ::Units...)
```

Given `Units` objects as arguments, this function returns a `Units` object appropriate
for the result of promoting quantities which have these units. This function is kind
of like `promote_rule`, except that it doesn't take types. It also does not return a tuple,
but rather just a [`Unitful.Units`](@ref) object (or it throws an error).

Although we had used `promote_rule` for `Units` objects in prior versions of Unitful,
this was always kind of a hack; it doesn't make sense to promote units directly for
a variety of reasons.
"""
function promote_unit end

# Generic methods
@inline promote_unit(x) = _promote_unit(x)
@inline _promote_unit(x::Units) = x

@inline promote_unit(x,y) = _promote_unit(x,y)

promote_unit(x::Units, y::Units, z::Units, t::Units...) =
    promote_unit(_promote_unit(x,y), z, t...)

# Use configurable fall-back mechanism for FreeUnits
@inline _promote_unit{T<:FreeUnits}(x::T, y::T) = T()
@inline _promote_unit{N1,N2,D}(x::FreeUnits{N1,D}, y::FreeUnits{N2,D}) =
    upreferred(dimension(x))

# same units, but promotion context disagrees
@inline _promote_unit{T<:ContextUnits}(x::T, y::T) = T()  #ambiguity reasons
@inline _promote_unit{N,D,P1,P2}(x::ContextUnits{N,D,P1}, y::ContextUnits{N,D,P2}) =
    ContextUnits{N,D,promote_unit(P1(), P2())}()
# different units, but promotion context agrees
@inline _promote_unit{N1,N2,D,P}(x::ContextUnits{N1,D,P}, y::ContextUnits{N2,D,P}) =
    ContextUnits(P(), P())
# different units, promotion context disagrees, fall back to FreeUnits
@inline _promote_unit{N1,N2,D}(x::ContextUnits{N1,D}, y::ContextUnits{N2,D}) =
    promote_unit(FreeUnits(x), FreeUnits(y))

# ContextUnits beat FreeUnits
@inline _promote_unit{N,D}(x::ContextUnits{N,D}, y::FreeUnits{N,D}) = x
@inline _promote_unit{N1,N2,D,P}(x::ContextUnits{N1,D,P}, y::FreeUnits{N2,D}) =
    ContextUnits(P(), P())
@inline _promote_unit(x::FreeUnits, y::ContextUnits) = promote_unit(y,x)

# FixedUnits beat everything
@inline _promote_unit{T<:FixedUnits}(x::T, y::T) = T()
@inline _promote_unit{M,N,D}(x::FixedUnits{M,D}, y::Units{N,D}) = x
@inline _promote_unit(x::Units, y::FixedUnits) = promote_unit(y,x)

# Different units but same dimension are not fungible for FixedUnits
@inline _promote_unit{M,N,D}(x::FixedUnits{M,D}, y::FixedUnits{N,D}) =
    error("automatic conversion prohibited.")

# If we didn't handle it above, the dimensions mismatched.
@inline _promote_unit(x::Units, y::Units) = throw(DimensionError(x,y))

@inline name{S,D}(x::Unit{S,D}) = S
@inline name{S}(x::Dimension{S}) = S
@inline tens(x::Unit) = x.tens
@inline power(x::Unit) = x.power
@inline power(x::Dimension) = x.power

# This is type unstable but
# a) this method is not called by the user
# b) ultimately the instability will only be present at compile time as it is
# hidden behind a "generated function barrier"
function basefactor(inex, ex, eq, tens, p)
    # Sometimes (x::Rational)^1 can fail for large rationals because the result
    # is of type x*x so we do a hack here
    function dpow(x,p)
        if p == 0
            1
        elseif p == 1
            x
        elseif p == -1
            1//x
        else
            x^p
        end
    end

    if isinteger(p)
        p = Integer(p)
    end

    eqisexact = false
    ex2 = (10.0^tens * float(ex))^p
    eq2 = float(eq)^p
    if isa(eq, Integer) || isa(eq, Rational)
        ex2 *= eq2
        eqisexact = true
    end

    can_exact = (ex2 < typemax(Int))
    can_exact &= (1/ex2 < typemax(Int))
    can_exact &= isinteger(p)

    can_exact2 = (eq2 < typemax(Int))
    can_exact2 &= (1/eq2 < typemax(Int))
    can_exact2 &= isinteger(p)

    if can_exact
        if eqisexact
            # If we got here then p is an integer.
            # Note that sometimes x^1 can cause an overflow error if
            # x is large because of how power_by_squaring is implemented
            x = dpow(eq*ex*(10//1)^tens, p)
            return (inex^p, isinteger(x) ? Int(x) : x)
        else
            x = dpow(ex*(10//1)^tens, p)
            return ((inex*eq)^p, isinteger(x) ? Int(x) : x)
        end
    else
        if eqisexact && can_exact2
            x = dpow(eq,p)
            return ((inex * ex * 10.0^tens)^p, isinteger(x) ? Int(x) : x)
        else
            return ((inex * ex * 10.0^tens * eq)^p, 1)
        end
    end
end

@inline basefactor{U}(x::Unit{U}) = basefactor(basefactors[U]..., 1, 0, power(x))

""" Only converts to given type if exact conversion is possible """
try_convert(T::Type, a::Integer) = typemax(T) >= a >= typemin(T) ? convert(T, a): a
try_convert{T <: Integer}(::Type{T}, a::T) = a
try_convert{T <: Integer}(::Type{Rational{T}}, a::Rational{T}) = a
try_convert{T <: Integer}(::Type{Rational{T}}, a::Integer) = Rational(try_convert(T, a))
function try_convert{T <: Integer}(::Type{Rational{T}}, a::Rational)
    cond = begin
        typemax(T) >= max(@compat(numerator(a)), @compat(denominator(a))) &&
        typemin(T) <= min(@compat(numerator(a)), @compat(denominator(a)))
    end
    cond ? convert(Rational{T}, a): a
end
function try_convert{T <: Integer}(::Type{T}, a::Rational)
    if @compat(denominator(a)) == 1
        try_convert(T, @compat(numerator(a)))
    else
        try_convert(Rational{T}, a)
    end
end

function basefactor{U}(x::Units{U})
    fact1 = map(basefactor, U)
    inex1 = mapreduce(x->getfield(x,1), *, 1.0, fact1)
    ex1   = mapreduce(x->getfield(x,2), *, Int128(1)//1, fact1)
    inex1, try_convert(length(fact1) > 0 ? typeof(fact1[1][2]): Int64, ex1)
end

# Addition / subtraction
for op in [:+, :-]
    @eval ($op){S,T,D,U}(x::Quantity{S,D,U}, y::Quantity{T,D,U}) =
        Quantity(($op)(x.val,y.val), U())

    # If not generated, there are run-time allocations
    @eval function ($op){S,T,D,SU,TU}(x::Quantity{S,D,SU}, y::Quantity{T,D,TU})
        ($op)(promote(x,y)...)
    end

    @eval ($op)(x::Quantity, y::Quantity) = throw(DimensionError(x,y))
    @eval function ($op)(x::Quantity, y::Number)
        if isa(x, DimensionlessQuantity)
            ($op)(promote(x,y)...)
        else
            throw(DimensionError(x,y))
        end
    end
    @eval function ($op)(x::Number, y::Quantity)
        if isa(y, DimensionlessQuantity)
            ($op)(promote(x,y)...)
        else
            throw(DimensionError(x,y))
        end
    end

    @eval ($op)(x::Quantity) = Quantity(($op)(x.val),unit(x))
end

*(x::Number, y::Units, z::Units...) = Quantity(x,*(y,z...))

# Kind of weird, but okay, no need to make things noncommutative.
*(x::Units, y::Number) = *(y,x)

function tensfactor(x::Unit)
    p = power(x)
    if isinteger(p)
        p = Integer(p)
    end
    tens(x)*p
end

@generated function tensfactor(x::Units)
    tunits = x.parameters[1]
    a = mapreduce(tensfactor, +, 0, tunits)
    :($a)
end

"""
```
*(a0::Dimensions, a::Dimensions...)
```

Given however many dimensions, multiply them together.

Collect [`Unitful.Dimension`](@ref) objects from the type parameter of the
[`Unitful.Dimensions`](@ref) objects. For identical dimensions, collect powers
and sort uniquely by the name of the `Dimension`.

Examples:

```jldoctest
julia> u"𝐌*𝐋/𝐓^2"
𝐋 𝐌 𝐓^-2

julia> u"𝐋*𝐌/𝐓^2"
𝐋 𝐌 𝐓^-2

julia> typeof(u"𝐋*𝐌/𝐓^2") == typeof(u"𝐌*𝐋/𝐓^2")
true
```
"""
@generated function *(a0::Dimensions, a::Dimensions...)
    # Implementation is very similar to *(::Units, ::Units...)
    b = Vector{Dimension}()
    a0p = a0.parameters[1]
    length(a0p) > 0 && append!(b, a0p)
    for x in a
        xp = x.parameters[1]
        length(xp) > 0 && append!(b, xp)
    end

    sort!(b, by=x->power(x))
    sort!(b, by=x->name(x))

    c = Vector{Dimension}()
    if !isempty(b)
        i = start(b)
        oldstate = b[i]
        p=0//1
        while !done(b, i)
            (state, i) = next(b, i)
            if name(state) == name(oldstate)
                p += power(state)
            else
                if p != 0
                    push!(c, Dimension{name(oldstate)}(p))
                end
                p = power(state)
            end
            oldstate = state
        end
        if p != 0
            push!(c, Dimension{name(oldstate)}(p))
        end
    end

    d = (c...)
    :(Dimensions{$d}())
end

# Both methods needed for ambiguity resolution
^{T}(x::Dimension{T}, y::Integer) = Dimension{T}(power(x)*y)
^{T}(x::Dimension{T}, y::Number) = Dimension{T}(power(x)*y)

# A word of caution:
# Exponentiation is not type-stable for `Dimensions` objects in many cases
^{T}(x::Dimensions{T}, y::Integer) = *(Dimensions{map(a->a^y, T)}())
^{T}(x::Dimensions{T}, y::Number) = *(Dimensions{map(a->a^y, T)}())
@static if VERSION >= v"0.6.0-pre.alpha.108"
    @generated function Base.literal_pow{T,p}(::typeof(^), x::Dimensions{T}, ::Type{Val{p}})
        z = *(Dimensions{map(a->a^p, T)}())
        :($z)
    end
elseif VERSION >= v"0.6.0-dev.2834"
    @generated function ^{T,p}(x::Dimensions{T}, ::Type{Val{p}})
        z = *(Dimensions{map(a->a^p, T)}())
        :($z)
    end
end

@inline dimension{U,D}(u::Unit{U,D}) = D()^u.power

*(x::Quantity, y::Units, z::Units...) = Quantity(x.val, *(unit(x),y,z...))
*(x::Quantity, y::Quantity) = Quantity(x.val*y.val, unit(x)*unit(y))

# Next two lines resolves some method ambiguity:
*{T<:Quantity}(x::Bool, y::T) =
    ifelse(x, y, ifelse(signbit(y), -zero(y), zero(y)))
*(x::Quantity, y::Bool) = Quantity(x.val*y, unit(x))

*(y::Number, x::Quantity) = *(x,y)
*(x::Quantity, y::Number) = Quantity(x.val*y, unit(x))

# See operators.jl
# Element-wise operations with units
@static if VERSION < v"0.6.0-dev.1632"  # Julia PR #17623
    for (f,F) in [(:./, :/), (:.*, :*), (:.+, :+), (:.-, :-)]
        @eval ($f)(x::Units, y::Units) = ($F)(x,y)
        @eval ($f)(x::Number, y::Units)   = ($F)(x,y)
        @eval ($f)(x::Units, y::Number)   = ($F)(x,y)
    end
    .\(x::Units, y::Units) = y./x               # NEW
    .\(x::Dimensions, y::Dimensions) = y./x     # NEW

    .\(x::Number, y::Units) = y./x
    .\(x::Units, y::Number) = y./x

    # See arraymath.jl
    ./(x::Units, Y::AbstractArray) =
        reshape([ x ./ y for y in Y ], size(Y))
    ./(X::AbstractArray, y::Units) =
        reshape([ x ./ y for x in X ], size(X))
    .\(x::Units, Y::AbstractArray) =
        reshape([ x .\ y for y in Y ], size(Y))
    .\(X::AbstractArray, y::Units) =
        reshape([ x .\ y for x in X ], size(X))
end

# looked in arraymath.jl for similar code
for f in @static if VERSION < v"0.6.0-dev.1632"; (:.*, :*); else (:*,) end
    @eval begin
        function ($f){T}(A::Units, B::AbstractArray{T})
            F = similar(B, Base.promote_op($f,typeof(A),T))
            for (iF, iB) in zip(eachindex(F), eachindex(B))
                @inbounds F[iF] = ($f)(A, B[iB])
            end
            return F
        end
        function ($f){T}(A::AbstractArray{T}, B::Units)
            F = similar(A, Base.promote_op($f,T,typeof(B)))
            for (iF, iA) in zip(eachindex(F), eachindex(A))
                @inbounds F[iF] = ($f)(A[iA], B)
            end
            return F
        end
    end
end

# Division (units)

/(x::Units, y::Units) = *(x,inv(y))
/(x::Dimensions, y::Dimensions) = *(x,inv(y))
/(x::Quantity, y::Units) = Quantity(x.val, unit(x) / y)
/(x::Units, y::Quantity) = Quantity(1/y.val, x / unit(y))
/(x::Number, y::Units) = Quantity(x,inv(y))
/(x::Units, y::Number) = (1/y) * x

//(x::Units, y::Units)  = x/y
//(x::Dimensions, y::Dimensions)  = x/y
//(x::Quantity, y::Units) = Quantity(x.val, unit(x) / y)
//(x::Units, y::Quantity) = Quantity(1//y.val, x / unit(y))
//(x::Number, y::Units) = Rational(x)/y
//(x::Units, y::Number) = (1//y) * x

# Division (quantities)

for op in (:/, ://)
    @eval begin
        ($op)(x::Quantity, y::Quantity) = Quantity(($op)(x.val, y.val), unit(x) / unit(y))
        ($op)(x::Quantity, y::Number) = Quantity(($op)(x.val, y), unit(x))
        ($op)(x::Number, y::Quantity) = Quantity(($op)(x, y.val), inv(unit(y)))
    end
end

# ambiguity resolution
//(x::Quantity, y::Complex) = Quantity(//(x.val, y), unit(x))

# Division (other functions)

for f in (:div, :fld, :cld)
    @eval function ($f)(x::Quantity, y::Quantity)
        z = uconvert(unit(y), x)        # TODO: use promote?
        ($f)(z.val,y.val)
    end
end

for f in (:mod, :rem)
    @eval function ($f)(x::Quantity, y::Quantity)
        z = uconvert(unit(y), x)        # TODO: use promote?
        Quantity(($f)(z.val,y.val), unit(y))
    end
end

# Needed until LU factorization is made to work with unitful numbers
function inv{T<:Quantity}(x::StridedMatrix{T})
    m = inv(ustrip(x))
    iq = eltype(m)
    reinterpret(Quantity{iq, typeof(inv(dimension(T))), typeof(inv(unit(T)))}, m)
end

for x in (:istriu, :istril)
    @eval ($x){T<:Quantity}(A::AbstractMatrix{T}) = ($x)(ustrip(A))
end

# Other mathematical functions

# `fma` and `muladd`
# The idea here is that if the numeric backing types are not the same, they
# will be promoted to be the same by the generic `fma(::Number, ::Number, ::Number)`
# method. We then catch the possible results and handle the units logic with one
# performant method.

for (_x,_y) in [(:fma, :_fma), (:muladd, :_muladd)]
    @static if VERSION >= v"0.6.0-" # work-around Julia issue 20103
        # Catch some signatures pre-promotion
        @eval @inline ($_x)(x::Number, y::Quantity, z::Quantity) = ($_y)(x,y,z)
        @eval @inline ($_x)(x::Quantity, y::Number, z::Quantity) = ($_y)(x,y,z)

        # Post-promotion
        @eval @inline ($_x){T<:Number}(x::Quantity{T}, y::Quantity{T}, z::Quantity{T}) = ($_y)(x,y,z)
    else
        @eval @inline ($_x){T<:Number}(x::Quantity{T}, y::T, z::T) = ($_y)(x,y,z)
        @eval @inline ($_x){T<:Number}(x::T, y::Quantity{T}, z::T) = ($_y)(x,y,z)
        @eval @inline ($_x){T<:Number}(x::T, y::T, z::Quantity{T}) = ($_y)(x,y,z)
        @eval @inline ($_x){T<:Number}(x::Quantity{T}, y::Quantity{T}, z::T) = ($_y)(x,y,z)
        @eval @inline ($_x){T<:Number}(x::T, y::Quantity{T}, z::Quantity{T}) = ($_y)(x,y,z)
        @eval @inline ($_x){T<:Number}(x::Quantity{T}, y::T, z::Quantity{T}) = ($_y)(x,y,z)
        @eval @inline ($_x){T<:Number}(x::Quantity{T}, y::Quantity{T}, z::Quantity{T}) = ($_y)(x,y,z)
    end

    # It seems like most of this is optimized out by the compiler, including the
    # apparent runtime check of dimensions, which does not appear in @code_llvm.
    @eval @inline function ($_y)(x,y,z)
        dimension(x) * dimension(y) != dimension(z) && throw(DimensionError(x*y,z))
        uI = unit(x)*unit(y)
        uF = promote_unit(uI, unit(z))
        c = ($_x)(ustrip(x), ustrip(y), ustrip(uconvert(uI, z)))
        uconvert(uF, Quantity(c, uI))
    end
end

sqrt(x::Quantity) = Quantity(sqrt(x.val), sqrt(unit(x)))
cbrt(x::Quantity) = Quantity(cbrt(x.val), cbrt(unit(x)))

for _y in (:sin, :cos, :tan, :cot, :sec, :csc, :cis)
    @eval ($_y)(x::DimensionlessQuantity) = ($_y)(uconvert(NoUnits, x))
end

atan2(y::Quantity, x::Quantity) = atan2(promote(y,x)...)
atan2{T,D,U}(y::Quantity{T,D,U}, x::Quantity{T,D,U}) = atan2(y.val,x.val)
atan2{T,D1,U1,D2,U2}(y::Quantity{T,D1,U1}, x::Quantity{T,D2,U2}) =
    throw(DimensionError(x,y))

for (f, F) in [(:min, :<), (:max, :>)]
    @eval @generated function ($f)(x::Quantity, y::Quantity)    #TODO
        xdim = x.parameters[2]()
        ydim = y.parameters[2]()
        if xdim != ydim
            return :(throw(DimensionError(x,y)))
        end

        isa(x.parameters[3](), FixedUnits) &&
            isa(y.parameters[3](), FixedUnits) &&
            x.parameters[3] !== y.parameters[3] &&
            error("automatic conversion prohibited.")

        xunits = x.parameters[3].parameters[1]
        yunits = y.parameters[3].parameters[1]

        factx = mapreduce((x,y)->broadcast(*,x,y), xunits) do x
            vcat(basefactor(x)...)
        end
        facty = mapreduce((x,y)->broadcast(*,x,y), yunits) do x
            vcat(basefactor(x)...)
        end

        tensx = mapreduce(tensfactor, +, xunits)
        tensy = mapreduce(tensfactor, +, yunits)

        convx = *(factx..., (10.0)^tensx)
        convy = *(facty..., (10.0)^tensy)

        :($($F)(x.val*$convx, y.val*$convy) ? x : y)
    end
end

@static if VERSION < v"0.6.0-dev.477"
    @vectorize_2arg Quantity max
    @vectorize_2arg Quantity min
end

abs(x::Quantity) = Quantity(abs(x.val), unit(x))
abs2(x::Quantity) = Quantity(abs2(x.val), unit(x)*unit(x))

trunc(x::Quantity) = Quantity(trunc(x.val), unit(x))
round(x::Quantity) = Quantity(round(x.val), unit(x))

copysign(x::Quantity, y::Number) = Quantity(copysign(x.val,y/unit(y)), unit(x))
flipsign(x::Quantity, y::Number) = Quantity(flipsign(x.val,y/unit(y)), unit(x))

@inline isless{T,D,U}(x::Quantity{T,D,U}, y::Quantity{T,D,U}) = _isless(x,y)
@inline _isless{T,D,U}(x::Quantity{T,D,U}, y::Quantity{T,D,U}) = isless(x.val, y.val)
@inline _isless{T,D1,D2,U1,U2}(x::Quantity{T,D1,U1}, y::Quantity{T,D2,U2}) = throw(DimensionError(x,y))
@inline _isless(x,y) = isless(x,y)

isless(x::Quantity, y::Quantity) = _isless(promote(x,y)...)
isless(x::Quantity, y::Number) = _isless(promote(x,y)...)
isless(x::Number, y::Quantity) = _isless(promote(x,y)...)

@inline <{T,D,U}(x::Quantity{T,D,U}, y::Quantity{T,D,U}) = _lt(x,y)
@inline _lt{T,D,U}(x::Quantity{T,D,U}, y::Quantity{T,D,U}) = <(x.val,y.val)
@inline _lt{T,D1,D2,U1,U2}(x::Quantity{T,D1,U1}, y::Quantity{T,D2,U2}) = throw(DimensionError(x,y))
@inline _lt(x,y) = <(x,y)

<(x::Quantity, y::Quantity) = _lt(promote(x,y)...)
<(x::Quantity, y::Number) = _lt(promote(x,y)...)
<(x::Number, y::Quantity) = _lt(promote(x,y)...)

@static if VERSION < v"0.6.0-dev.1632" # Julia PR #17623
    .<(x::Quantity, y::Quantity) = x < y
    .<(x::Quantity, y::Number) = x < y
    .<(x::Number, y::Quantity) = x < y
    .<=(x::Quantity, y::Quantity) = x <= y
    .<=(x::Quantity, y::Number) = x <= y
    .<=(x::Number, y::Quantity) = x <= y
end

isapprox{T,D,U}(x::Quantity{T,D,U}, y::Quantity{T,D,U}; atol=zero(Quantity{real(T),D,U}), kwargs...) =
    isapprox(x.val, y.val; atol=uconvert(unit(y), atol).val, kwargs...)
function isapprox(x::Quantity, y::Quantity; kwargs...)
    dimension(x) != dimension(y) && return false
    return isapprox(promote(x,y)...; kwargs...)
end
isapprox(x::Quantity, y::Number; kwargs...) = isapprox(uconvert(NoUnits, x), y; kwargs...)
isapprox(x::Number, y::Quantity; kwargs...) = isapprox(y, x; kwargs...)

function isapprox{T1,D,U1,T2,U2}(x::AbstractArray{Quantity{T1,D,U1}},
        y::AbstractArray{Quantity{T2,D,U2}}; rtol::Real=Base.rtoldefault(T1,T2),
        atol=zero(Quantity{T1,D,U1}), norm::Function=vecnorm)

    d = norm(x - y)
    if isfinite(d)
        return d <= atol + rtol*max(norm(x), norm(y))
    else
        # Fall back to a component-wise approximate comparison
        return all(ab -> isapprox(ab[1], ab[2]; rtol=rtol, atol=atol), zip(x, y))
    end
end
isapprox{S<:Quantity,T<:Quantity}(x::AbstractArray{S}, y::AbstractArray{T};
    kwargs...) = false
function isapprox{S<:Quantity,N<:Number}(x::AbstractArray{S}, y::AbstractArray{N};
    kwargs...)
    if dimension(N) == dimension(S)
        isapprox(map(x->uconvert(NoUnits,x),x),y; kwargs...)
    else
        false
    end
end
isapprox{S<:Quantity,N<:Number}(y::AbstractArray{N}, x::AbstractArray{S};
    kwargs...) = isapprox(x,y; kwargs...)

=={S,T,D,U}(x::Quantity{S,D,U}, y::Quantity{T,D,U}) = (x.val == y.val)
function ==(x::Quantity, y::Quantity)
    dimension(x) != dimension(y) && return false
    ==(promote(x,y)...)
end

function ==(x::Quantity, y::Number)
    if dimension(x) == NoDims
        uconvert(NoUnits, x) == y
    else
        false
    end
end
==(x::Number, y::Quantity) = ==(y,x)
<=(x::Quantity, y::Quantity) = <(x,y) || x==y

for f in (:zero, :floor, :ceil)
    @eval ($f)(x::Quantity) = Quantity(($f)(x.val), unit(x))
end
zero{T,D,U}(x::Type{Quantity{T,D,U}}) = zero(T)*U()

one(x::Quantity) = one(x.val)
one{T,D,U}(x::Type{Quantity{T,D,U}}) = one(T)

isinteger(x::Quantity) = isinteger(x.val)
isreal(x::Quantity) = isreal(x.val)
isfinite(x::Quantity) = isfinite(x.val)
isinf(x::Quantity) = isinf(x.val)
isnan(x::Quantity) = isnan(x.val)

unsigned(x::Quantity) = Quantity(unsigned(x.val), unit(x))

for f in (:exp, :exp10, :exp2, :expm1, :log, :log10, :log1p, :log2)
    @eval ($f)(x::DimensionlessQuantity) = ($f)(uconvert(NoUnits, x))
end

real(x::Quantity) = Quantity(real(x.val), unit(x))
imag(x::Quantity) = Quantity(imag(x.val), unit(x))
conj(x::Quantity) = Quantity(conj(x.val), unit(x))

@inline vecnorm(x::Quantity, p::Real=2) =
    p == 0 ? (x==zero(x) ? typeof(abs(x))(0) : typeof(abs(x))(1)) : abs(x)

"""
```
sign(x::Quantity)
```

Returns the sign of `x`.
"""
sign(x::Quantity) = sign(x.val)

"""
```
signbit(x::Quantity)
```

Returns the sign bit of the underlying numeric value of `x`.
"""
signbit(x::Quantity) = signbit(x.val)

prevfloat{T<:AbstractFloat}(x::Quantity{T}) = Quantity(prevfloat(x.val), unit(x))
nextfloat{T<:AbstractFloat}(x::Quantity{T}) = Quantity(nextfloat(x.val), unit(x))

function frexp{T<:AbstractFloat}(x::Quantity{T})
    a,b = frexp(x.val)
    a*unit(x), b
end

"""
```
float(x::Quantity)
```

Convert the numeric backing type of `x` to a floating-point representation.
Returns a `Quantity` with the same units.
"""
float(x::Quantity) = Quantity(float(x.val), unit(x))

"""
```
Integer(x::Quantity)
```

Convert the numeric backing type of `x` to an integer representation.
Returns a `Quantity` with the same units.
"""
Integer(x::Quantity) = Quantity(Integer(x.val), unit(x))

"""
```
Rational(x::Quantity)
```

Convert the numeric backing type of `x` to a rational number representation.
Returns a `Quantity` with the same units.
"""
Rational(x::Quantity) = Quantity(Rational(x.val), unit(x))

*(y::Units, r::Range) = *(r,y)
*(r::Range, y::Units) = range(first(r)*y, step(r)*y, length(r))
*(r::Range, y::Units, z::Units...) = *(x, *(y,z...))

# break out into separate files so julia 0.5 doesn't see 0.6 syntax
@static if VERSION < v"0.6.0-dev.2390"
    include("range_v05.jl")
else
    include("range.jl")
end

typemin{T,D,U}(::Type{Quantity{T,D,U}}) = typemin(T)*U()
typemin{T}(x::Quantity{T}) = typemin(T)*unit(x)

typemax{T,D,U}(::Type{Quantity{T,D,U}}) = typemax(T)*U()
typemax{T}(x::Quantity{T}) = typemax(T)*unit(x)

"""
```
offsettemp(::Unit)
```

For temperature units, this function is used to set the scale offset.
"""
offsettemp(::Unit) = 0

@inline dimtype{U,D}(u::Unit{U,D}) = D

@generated function *(a0::FreeUnits, a::FreeUnits...)

    # Sort the units uniquely. This is a generated function so that we
    # don't have to figure out the units each time.
    b = Vector{Unit}()
    a0p = a0.parameters[1]
    length(a0p) > 0 && append!(b, a0p)
    for x in a
        xp = x.parameters[1]
        length(xp) > 0 && append!(b, xp)
    end

    # b is an Array containing all of the Unit objects that were
    # found in the type parameters of the Units objects (a0, a...)
    sort!(b, by=x->power(x))
    sort!(b, by=x->tens(x))
    sort!(b, by=x->name(x))

    # Units[m,m,cm,cm^2,cm^3,nm,m^4,µs,µs^2,s]
    # reordered as:
    # Units[nm,cm,cm^2,cm^3,m,m,m^4,µs,µs^2,s]

    # Collect powers of a given unit
    c = Vector{Unit}()
    if !isempty(b)
        i = start(b)
        oldstate = b[i]
        p=0//1
        while !done(b, i)
            (state, i) = next(b, i)
            if tens(state) == tens(oldstate) && name(state) == name(oldstate)
                p += power(state)
            else
                if p != 0
                    push!(c, Unit{name(oldstate),dimtype(oldstate)}(tens(oldstate), p))
                end
                p = power(state)
            end
            oldstate = state
        end
        if p != 0
            push!(c, Unit{name(oldstate),dimtype(oldstate)}(tens(oldstate), p))
        end
    end
    # results in:
    # Units[nm,cm^6,m^6,µs^3,s]

    d = (c...)
    f = typeof(mapreduce(dimension, *, NoDims, c))
    :(FreeUnits{$d,$f}())
end
*(a0::ContextUnits, a::ContextUnits...) =
    ContextUnits(*(FreeUnits(a0), FreeUnits.(a)...),
                    *(FreeUnits(upreferred(a0)), FreeUnits.((upreferred).(a))...))
FreeOrContextUnits = Union{FreeUnits, ContextUnits}
*(a0::FreeOrContextUnits, a::FreeOrContextUnits...) =
    *(ContextUnits(a0), ContextUnits.(a)...)
*(a0::FixedUnits, a::FixedUnits...) =
    FixedUnits(*(FreeUnits(a0), FreeUnits.(a)...))

"""
```
*(a0::Units, a::Units...)
```

Given however many units, multiply them together. This is actually handled by
a few different methods, since we have `FreeUnits`, `ContextUnits`, and `FixedUnits`.

Collect [`Unitful.Unit`](@ref) objects from the type parameter of the
[`Unitful.Units`](@ref) objects. For identical units including SI prefixes
(i.e. cm ≠ m), collect powers and sort uniquely by the name of the `Unit`.
The unique sorting permits easy unit comparisons.

Examples:

```jldoctest
julia> u"kg*m/s^2"
kg m s^-2

julia> u"m/s*kg/s"
kg m s^-2

julia> typeof(u"m/s*kg/s") == typeof(u"kg*m/s^2")
true
```
"""
*(a0::Units, a::Units...) = FixedUnits(*(FreeUnits(a0), FreeUnits.(a)...))
# Logic above is that if we're not using FreeOrContextUnits, at least one is FixedUnits.

# Both methods needed for ambiguity resolution
^{U,D}(x::Unit{U,D}, y::Integer) = Unit{U,D}(tens(x), power(x)*y)
^{U,D}(x::Unit{U,D}, y::Number) = Unit{U,D}(tens(x), power(x)*y)

# A word of caution:
# Exponentiation is not type-stable for `Units` objects.
# Dimensions get reconstructed anyway so we pass () for the D type parameter...
^{N}(x::FreeUnits{N}, y::Integer) = *(FreeUnits{map(a->a^y, N), ()}())
^{N}(x::FreeUnits{N}, y::Number) = *(FreeUnits{map(a->a^y, N), ()}())

^{N,D,P}(x::ContextUnits{N,D,P}, y::Integer) =
    *(ContextUnits{map(a->a^y, N), (), typeof(P()^y)}())
^{N,D,P}(x::ContextUnits{N,D,P}, y::Number) =
    *(ContextUnits{map(a->a^y, N), (), typeof(P()^y)}())

^{N}(x::FixedUnits{N}, y::Integer) = *(FixedUnits{map(a->a^y, N), ()}())
^{N}(x::FixedUnits{N}, y::Number) = *(FixedUnits{map(a->a^y, N), ()}())

@static if VERSION >= v"0.6.0-pre.alpha.108"
    @generated function Base.literal_pow{N,p}(::typeof(^), x::FreeUnits{N}, ::Type{Val{p}})
        y = *(FreeUnits{map(a->a^p, N), ()}())
        :($y)
    end
    @generated function Base.literal_pow{N,D,P,p}(::typeof(^), x::ContextUnits{N,D,P}, ::Type{Val{p}})
        y = *(ContextUnits{map(a->a^p, N), (), typeof(P()^p)}())
        :($y)
    end
    @generated function Base.literal_pow{N,p}(::typeof(^), x::FixedUnits{N}, ::Type{Val{p}})
        y = *(FixedUnits{map(a->a^p, N), ()}())
        :($y)
    end
    Base.literal_pow{v}(::typeof(^), x::Quantity, ::Type{Val{v}}) =
        Quantity(Base.literal_pow(^, x.val, Val{v}),
                 Base.literal_pow(^, unit(x), Val{v}))
elseif VERSION >= v"0.6.0-dev.2834"
    @generated function ^{N,p}(x::FreeUnits{N}, ::Type{Val{p}})
        y = *(FreeUnits{map(a->a^p, N), ()}())
        :($y)
    end
    @generated function ^{N,D,P,p}(x::ContextUnits{N,D,P}, ::Type{Val{p}})
        y = *(ContextUnits{map(a->a^p, N), (), typeof(P()^p)}())
        :($y)
    end
    @generated function ^{N,p}(x::FixedUnits{N}, ::Type{Val{p}})
        y = *(FixedUnits{map(a->a^p, N), ()}())
        :($y)
    end
    ^{v}(x::Quantity, ::Type{Val{v}}) = Quantity((x.val)^Val{v}, unit(x)^Val{v})
end
# All of these are needed for ambiguity resolution
^(x::Quantity, y::Integer) = Quantity((x.val)^y, unit(x)^y)
^(x::Quantity, y::Rational) = Quantity((x.val)^y, unit(x)^y)
^(x::Quantity, y::Real) = Quantity((x.val)^y, unit(x)^y)

# Since exponentiation is not type stable, we define a special `inv` method to
# enable fast division. For julia 0.6.0-dev.1711, the appropriate methods for ^
# and * need to be defined before this one!
for (fun,pow) in ((:inv, -1//1), (:sqrt, 1//2), (:cbrt, 1//3))
    # The following are generated functions to ensure type stability.
    @eval @generated function ($fun)(x::Dimensions)
        dimtuple = map(x->x^($pow), x.parameters[1])
        y = *(Dimensions{dimtuple}())    # sort appropriately
        :($y)
    end

    @eval @generated function ($fun)(x::FreeUnits)
        unittuple = map(x->x^($pow), x.parameters[1])
        y = *(FreeUnits{unittuple,()}())    # sort appropriately
        :($y)
    end

    @eval @generated function ($fun)(x::ContextUnits)
        unittuple = map(x->x^($pow), x.parameters[1])
        promounit = ($fun)(x.parameters[3]())
        y = *(ContextUnits{unittuple,(),typeof(promounit)}())   # sort appropriately
        :($y)
    end

    @eval @generated function ($fun)(x::FixedUnits)
        unittuple = map(x->x^($pow), x.parameters[1])
        y = *(FixedUnits{unittuple,()}())   # sort appropriately
        :($y)
    end
end

include("Display.jl")
include("Promotion.jl")
include("Conversion.jl")
@static if VERSION >= v"0.6.0-dev.2218" # Julia PR 18754
    include("fastmath.jl")
else
    include("fastmath_v05.jl")
end
include("pkgdefaults.jl")
include("temperature.jl")

function __init__()
    # @u_str should be aware of units defined in module Unitful
    Unitful.register(Unitful)
end

end
