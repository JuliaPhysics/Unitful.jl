@generated function *(a0::FreeUnits, a::FreeUnits...)

    # Sort the units uniquely. This is a generated function so that we
    # don't have to figure out the units each time.
    linunits = Vector{Unit}()

    nunits = length(a) + 1
    for x in (a0, a...)
        (x.parameters[3] !== nothing) && (nunits > 1) &&
            throw(AffineError("an invalid operation was attempted with affine units: $(x())"))
        xp = x.parameters[1]
        append!(linunits, xp[1:end])
    end

    # linunits is an Array containing all of the Unit objects that were
    # found in the type parameters of the FreeUnits objects (a0, a...)
    sort!(linunits, by=power)
    sort!(linunits, by=tens)
    sort!(linunits, by=name)

    # [m,m,cm,cm^2,cm^3,nm,m^4,μs,μs^2,s]
    # reordered as:
    # [nm,cm,cm^2,cm^3,m,m,m^4,μs,μs^2,s]

    # Collect powers of a given unit into `c`
    c = Vector{Unit}()
    if !isempty(linunits)
        next = iterate(linunits)
        p = 0//1
        oldvalue = next[1]
        while next !== nothing
            (value, state) = next
            if tens(value) == tens(oldvalue) && name(value) == name(oldvalue)
                p += power(value)
            else
                if p != 0
                    push!(c, Unit{name(oldvalue), dimtype(oldvalue)}(tens(oldvalue), p))
                end
                p = power(value)
            end
            oldvalue = value
            next = iterate(linunits, state)
        end
        if p != 0
            push!(c, Unit{name(oldvalue), dimtype(oldvalue)}(tens(oldvalue), p))
        end
    end
    # results in:
    # [nm,cm^6,m^6,μs^3,s]

    d = (c...,)
    f = mapreduce(dimension, *, d; init=NoDims)
    :(FreeUnits{$d,$f,$(a0.parameters[3])}())
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
(i.e. `cm` ≠ `m`), collect powers and sort uniquely by the name of the `Unit`.
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

*(a0::Units, a::Missing) = missing
*(a0::Missing, a::Units) = missing
*(a0::MixedUnits, a::Missing) = missing
*(a0::Missing, a::MixedUnits) = missing

/(x::Units, y::Units) = *(x,inv(y))

/(x::Units, y::Missing) = missing
/(x::Missing, y::Units) = missing
/(x::MixedUnits, y::Missing) = missing
/(x::Missing, y::MixedUnits) = missing

//(x::Units, y::Units)  = x/y

# Both methods needed for ambiguity resolution
^(x::Unit{U,D}, y::Integer) where {U,D} = Unit{U,D}(tens(x), power(x)*y)
^(x::Unit{U,D}, y::Number) where {U,D} = Unit{U,D}(tens(x), power(x)*y)

# A word of caution:
# Exponentiation is not type-stable for `Units` objects.
# Dimensions get reconstructed anyway so we pass () for the D type parameter...
^(x::AffineUnits, y::Integer) =
    throw(AffineError("an invalid operation was attempted with affine units: $x"))
^(x::AffineUnits, y::Number) =
    throw(AffineError("an invalid operation was attempted with affine units: $x"))

^(x::FreeUnits{N,D,nothing}, y::Integer) where {N,D} = *(FreeUnits{map(a->a^y, N), ()}())
^(x::FreeUnits{N,D,nothing}, y::Number) where {N,D} = *(FreeUnits{map(a->a^y, N), ()}())

^(x::ContextUnits{N,D,P,nothing}, y::Integer) where {N,D,P} =
    *(ContextUnits{map(a->a^y, N), (), typeof(P()^y)}())
^(x::ContextUnits{N,D,P,nothing}, y::Number) where {N,D,P} =
    *(ContextUnits{map(a->a^y, N), (), typeof(P()^y)}())

^(x::FixedUnits{N,D,nothing}, y::Integer) where {N,D} = *(FixedUnits{map(a->a^y, N), ()}())
^(x::FixedUnits{N,D,nothing}, y::Number) where {N,D} = *(FixedUnits{map(a->a^y, N), ()}())

^(x::Units, y::Missing) = missing
^(x::Missing, y::Units) = missing

Base.literal_pow(::typeof(^), x::AffineUnits, ::Val{p}) where p =
    throw(AffineError("an invalid operation was attempted with affine units: $x"))

@generated function Base.literal_pow(::typeof(^), x::FreeUnits{N,D,nothing}, ::Val{p}) where {N,D,p}
    y = *(FreeUnits{map(a->a^p, N), ()}())
    :($y)
end
@generated function Base.literal_pow(::typeof(^), x::ContextUnits{N,D,P,nothing}, ::Val{p}) where {N,D,P,p}
    y = *(ContextUnits{map(a->a^p, N), (), typeof(P()^p)}())
    :($y)
end
@generated function Base.literal_pow(::typeof(^), x::FixedUnits{N,D,nothing}, ::Val{p}) where {N,D,p}
    y = *(FixedUnits{map(a->a^p, N), ()}())
    :($y)
end

# Since exponentiation is not type stable, we define a special `inv` method to enable fast
# division. For julia 0.6.0, the appropriate methods for ^ and * need to be defined before
# this one!
for (fun,pow) in ((:inv, -1//1), (:sqrt, 1//2), (:cbrt, 1//3))
    # The following are generated functions to ensure type stability.
    @eval @generated function ($fun)(x::FreeUnits)
        (x <: AffineUnits) && throw(
            AffineError("an invalid operation was attempted with affine units: $(x())"))
        unittuple = map(x->x^($pow), x.parameters[1])
        y = *(FreeUnits{unittuple,()}())    # sort appropriately
        :($y)
    end

    @eval @generated function ($fun)(x::ContextUnits)
        (x <: AffineUnits) && throw(
            AffineError("an invalid operation was attempted with affine units: $(x())"))
        unittuple = map(x->x^($pow), x.parameters[1])
        promounit = ($fun)(x.parameters[3]())
        y = *(ContextUnits{unittuple,(),typeof(promounit)}())   # sort appropriately
        :($y)
    end

    @eval @generated function ($fun)(x::FixedUnits)
        (x <: AffineUnits) && throw(
            AffineError("an invalid operation was attempted with affine units: $(x())"))
        unittuple = map(x->x^($pow), x.parameters[1])
        y = *(FixedUnits{unittuple,()}())   # sort appropriately
        :($y)
    end
end

function tensfactor(x::Unit)
    p = power(x)
    if isinteger(p)
        p = Integer(p)
    end
    tens(x)*p
end

@generated function tensfactor(x::Units)
    tunits = x.parameters[1]
    a = mapreduce(tensfactor, +, tunits; init=0)
    :($a)
end

# This is type unstable but
# a) this method is not called by the user
# b) ultimately the instability will only be present at compile time as it is
# hidden behind a "generated function barrier"
function basefactor(inex, ex, eq, tens, p)
    # Sometimes (x::Rational)^1 can fail for large rationals because the result
    # is of type x*x so we do a hack here
    function dpow(x, p)
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
    if isinteger(tens)
        tens = Integer(tens)
    end

    eq_is_exact = false
    output_ex_float = (10.0^tens * float(ex))^p
    eq_raised = float(eq)^p
    if isa(eq, Integer) || isa(eq, Rational)
        output_ex_float *= eq_raised
        eq_is_exact = true
    end

    can_exact = (output_ex_float < typemax(Int))
    can_exact &= (1/output_ex_float < typemax(Int))
    can_exact &= isinteger(p)

    can_exact2 = (eq_raised < typemax(Int))
    can_exact2 &= (1/eq_raised < typemax(Int))
    can_exact2 &= isinteger(p)

    if can_exact && isinteger(tens)
        if eq_is_exact
            # If we got here then p is an integer.
            # Note that sometimes x^1 can cause an overflow error if x is large because
            # of how power_by_squaring is implemented for Rationals, so we use dpow.
            x = dpow(eq*ex*(10//1)^tens, p)
            result = (inex^p, isinteger(x) ? Int(x) : x)
        else
            x = dpow(ex*(10//1)^tens, p)
            result = ((inex * eq)^p, isinteger(x) ? Int(x) : x)
        end
    else
        if eq_is_exact && can_exact2
            x = dpow(eq, p)
            result = ((inex * ex * 10.0^tens)^p, isinteger(x) ? Int(x) : x)
        else
            result = ((inex * ex * 10.0^tens * eq)^p, 1)
        end
    end
    if fp_overflow_underflow(inex, first(result))
        throw(ArgumentError("Floating point overflow/underflow, probably due to large exponent ($p)"))
    end
    return result
end

"""
    basefactor(x::Unit)
Specifies conversion factors to reference units.
It returns a tuple. The first value is any irrational part of the conversion,
and the second value is a rational component. This segregation permits exact
conversions within unit systems that have no rational conversion to the
reference units.
"""
@inline basefactor(x::Unit{U}) where {U} = basefactor(basefactors[U]..., 1, 0, power(x))

function basefactor(::Units{U}) where {U}
    fact1 = map(basefactor, U)
    inex1 = mapreduce(first, *, fact1, init=1.0)
    float_num = mapreduce(x -> float(numerator(last(x))), *, fact1, init=1.0)
    float_den = mapreduce(x -> float(denominator(last(x))), *, fact1, init=1.0)
    can_exact = float_num < typemax(Int) && float_den < typemax(Int)
    if can_exact
        result = (inex1, mapreduce(last, *, fact1, init=1))
    else
        result = (inex1 * (float_num / float_den), 1)
    end
    if any(fp_overflow_underflow(first(x), first(result)) for x in fact1)
        throw(ArgumentError("Floating point overflow/underflow, probably due to a large exponent in some of the units"))
    end
    return result
end

Base.broadcastable(x::Units) = Ref(x)

Base.nbitslen(::Type{Q}, len, offset) where Q<:Quantity =
    Base.nbitslen(numtype(Q), len, offset)

ustrip(x::Base.TwicePrecision{Q}) where Q<:Quantity =
    Base.TwicePrecision(ustrip(x.hi), ustrip(x.lo))
unit(x::Base.TwicePrecision{Q}) where Q<:Quantity = unit(x.hi)

function Base.twiceprecision(x::Union{Q,Base.TwicePrecision{Q}}, nb::Integer) where Q<:Quantity
    xt = Base.twiceprecision(ustrip(x), nb)
    return Base.TwicePrecision(xt.hi*unit(x), xt.lo*unit(x))
end

function *(x::Base.TwicePrecision{Q}, v::Real) where Q<:Quantity
    v == 0 && return Base.TwicePrecision(x.hi*v, x.lo*v)
    (ustrip(x) * Base.TwicePrecision(oftype(ustrip(x.hi)*v, v))) * unit(x)
end

Base.mul12(x::Quantity, y::Quantity) = Base.mul12(ustrip(x), ustrip(y)) .* (unit(x) * unit(y))
Base.mul12(x::Quantity, y::Real)     = Base.mul12(ustrip(x), y) .* unit(x)
Base.mul12(x::Real, y::Quantity)     = Base.mul12(x, ustrip(y)) .* unit(y)

# The following method must not be defined before `*(a0::FreeUnits, a::FreeUnits...)`
"""
    upreferred(x::Dimensions)
Return units which are preferred for dimensions `x`. If you are using the
factory defaults, this function will return a product of powers of base SI units
(as [`Unitful.FreeUnits`](@ref)).
"""
@generated function upreferred(x::Dimensions{D}) where {D}
    u = prod((NoUnits, (promotion[name(z)]^z.power for z in D)...))
    :($u)
end
