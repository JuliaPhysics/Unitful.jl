"""
    convfact(s::Units, t::Units)
Find the conversion factor from unit `t` to unit `s`, e.g., `convfact(m, cm) == 1//100`.
"""
@generated function convfact(s::Units, t::Units)
    # Check if conversion is possible in principle
    dimension(s()) != dimension(t()) && throw(DimensionError(s(), t()))

    # use absoluteunit because division is invalid for AffineUnits;
    # convert to FreeUnits first because absolute ContextUnits might still
    # promote to AffineUnits
    conv_units = absoluteunit(FreeUnits(t())) / absoluteunit(FreeUnits(s()))
    inex, ex = basefactor(conv_units)
    pow = tensfactor(conv_units)
    inex_orig = inex

    fpow = 10.0^pow
    if fpow > typemax(Int) || 1/fpow > typemax(Int)
        inex *= fpow
    else
        comp = (pow > 0 ? fpow * numerator(ex) : 1/fpow * denominator(ex))
        if comp > typemax(Int)
            inex *= fpow
        else
            ex *= (10//1)^pow
        end
    end

    if ex isa Rational && denominator(ex) == 1
        ex = numerator(ex)
    end

    result = (inex ≈ 1.0 ? 1 : inex) * ex
    if fp_overflow_underflow(inex_orig, result)
        throw(ArgumentError(
            "Floating point overflow/underflow, probably due to large " *
            "exponents and/or SI prefixes in units"
        ))
    end
    return :($result)
end

"""
    convfact{S}(s::Units{S}, t::Units{S})
Returns 1. (Avoids effort when unnecessary.)
"""
convfact(s::Units{S}, t::Units{S}) where {S} = 1

"""
    convfact(T::Type, s::Units, t::Units)
Returns the appropriate conversion factor from unit `t` to unit `s` for the number type `T`.
"""
function convfact(::Type{T}, s::Units, t::Units) where T
    cf = convfact(s, t)
    if cf isa AbstractFloat
        F = convfact_floattype(T)
        # Since conversion factors only have Float64 precision,
        # there is no point in converting to BigFloat
        convert(F == BigFloat ? Float64 : F, cf)
    else
        cf
    end
end

function convfact_floattype(::Type{T}) where T
    # Use try-catch instead of hasmethod because a
    # fallback method might exist but throw an error
    try
        _convfact_floattype(float(real(T)))
    catch
        Float64
    end
end

_convfact_floattype(::Type) = Float64
_convfact_floattype(::Type{Float16}) = Float16
_convfact_floattype(::Type{Float32}) = Float32

"""
    uconvert(a::Units, x::AbstractQuantity{T,D,U}) where {T,D,U}
Convert a [`Unitful.AbstractQuantity`](@ref) to a [`Unitful.Quantity`](@ref) with
different units. The conversion will fail if the target units `a` have a different
dimension than the dimension of the quantity `x`. You can use this method to switch
between equivalent representations of the same unit, like `N m` and `J`.

Example:

```jldoctest
julia> uconvert(u"hr",3602u"s")
1801//1800 hr

julia> uconvert(u"J",1.0u"N*m")
1.0 J
```
"""
function uconvert(a::Units, x::AbstractQuantity{T,D,U}) where {T,D,U}
    if typeof(a) == U
        return Quantity(x.val, a)    # preserves numeric type if convfact is 1
    elseif (a isa AffineUnits) || (x isa AffineQuantity)
        return uconvert_affine(a, x)
    else
        return Quantity(x.val * convfact(T, a, U()), a)
    end
end

function uconvert(a::Units, x::Number)
    if dimension(a) == NoDims
        Quantity(x * convfact(a, NoUnits), a)
    else
        throw(DimensionError(a,x))
    end
end

uconvert(a::Units, x::Missing) = missing

@generated function uconvert_affine(a::Units, x::AbstractQuantity{T,D,U}) where {T,D,U}
    # TODO: test, may be able to get bad things to happen here when T<:LogScaled
    auobj = a()
    xuobj = U()
    conv = convfact(auobj, xuobj)

    t0 = x <: AffineQuantity ? U.parameters[end].parameters[end] : :(zero($T))
    t1 = a <: AffineUnits ? a.parameters[end].parameters[end] : :(zero($T))
    quote
        dimension(a) != dimension(x) && throw(DimensionError(a, x))
        return Quantity(((x.val - $t0) * $conv) + $t1, a)
    end
end

function convert(::Type{Quantity{T,D,U}}, x::Number) where {T,D,U}
    (dimension(x) != D) && throw(DimensionError(U(), x))
    q = uconvert(U(), x)
    Quantity{T,D,U}(isa(q, AbstractQuantity) ? q.val : q)
end

# needed ever since julialang/julia#28216
convert(::Type{Quantity{T,D,U}}, x::Quantity{T,D,U}) where {T,D,U} = x

function convert(::Type{Quantity{T,D}}, x::AbstractQuantity) where {T,D}
    (dimension(x) !== D) && throw(DimensionError(D, x))
    return Quantity{T,D,typeof(unit(x))}(convert(T, x.val))
end
function convert(::Type{Quantity{T,D}}, x::Number) where {T,D}
    (D !== NoDims) && throw(DimensionError(D, NoDims))
    Quantity{T,NoDims,typeof(NoUnits)}(x)
end
function convert(::Type{Quantity{T}}, x::AbstractQuantity) where {T}
    Quantity{T,dimension(x),typeof(unit(x))}(convert(T, x.val))
end
function convert(::Type{Quantity{T}}, x::Number) where {T}
    Quantity{T,NoDims,typeof(NoUnits)}(x)
end

function convert(::Type{DimensionlessQuantity{T,U}}, x::Number) where {T,U}
    q = uconvert(U(), convert(T, x))
    _Quantity(T(q isa AbstractQuantity ? q.val : q), U())
end
function convert(::Type{DimensionlessQuantity{T,U}}, x::AbstractQuantity) where {T,U}
    if dimension(x) == NoDims
        _Quantity(T(ustrip(U(), x)), U())
    else
        throw(DimensionError(NoDims,x))
    end
end

# other AbstractQuantity subtypes are constructed from the bare numeric value
function convert(::Type{Q}, x::Number) where {D,U,Q<:AbstractQuantity{<:Any,D,U}}
    x isa Q && return x
    dimension(x) === D || throw(DimensionError(D, x))
    return Q(ustrip(U(), x))
end

convert(::Type{Number}, y::AbstractQuantity) = y
convert(::Type{T}, y::AbstractQuantity) where {T <: Real} =
    T(uconvert(NoUnits, y))
convert(::Type{T}, y::AbstractQuantity) where {T <: Complex} =
    T(uconvert(NoUnits, y))
