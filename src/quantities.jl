# This is a generated function to avoid determining the dimensions of a given
# set of units each time a new quantity is made.
@generated function _Quantity(x::Number, y::Units)
    u = y()
    du = dimension(u)
    dx = dimension(x)
    d = du*dx
    :(Quantity{typeof(x), $d, typeof($u)}(x))
end

"""
    Quantity(x::Number, y::Units)

Create a `Quantity` with numerical value `x` and units `y`.

# Example

```jldoctest
julia> Quantity(5, u"m")
5 m
```
"""
Quantity(x::Number, y::Units) = _Quantity(x, y)
Quantity(x::Number, y::Units{()}) = x

"""
    withvalue(::Type{Q}, val) where {Q<:AbstractQuantity}
    withvalue(x::AbstractQuantity, val)

Return a quantity of the same kind as `Q` or `typeof(x)` with the numeric value `val` in the units of `Q`.

With a method for a subtype of `AbstractQuantity`, arithmetic such as `-x`, `2x` or `x + y` returns that
subtype instead of a `Quantity`. For a subtype `Q{T,D,U}` with a field `val`, the method is

    Unitful.withvalue(::Type{<:Q{<:Any,D,U}}, val) where {D,U} = Q{typeof(val),D,U}(val)

Unitful calls `withvalue` only for operations that keep both the units and the meaning of a quantity:
changing the sign, `abs`, scaling by a plain number, `+` and `-` of two quantities of the same type,
`muladd`, remainders, `zero`, `typemin`, `typemax`, `eps`, `conj`, and changing the numeric type,
e.g. with `float` or `big`. All other operations return a `Quantity`. A subtype should only add a method
if every one of these operations preserves its meaning. The numeric type of `val` may differ from that
of `Q`, and the method may return a `Quantity` for values that the subtype cannot store. `val` is a bare
number in the units of `Q`. To convert a quantity, use `convert` or `oftype`.

The default returns `Quantity(val, unit(Q))`:

```jldoctest
julia> Unitful.withvalue(1.5u"m", 2)
2 m

julia> Unitful.withvalue(typeof(1.0u"m/s"), 0.5f0)
0.5f0 m s^-1

julia> Unitful.withvalue(0u"°C", 21.5)
21.5 °C
```
"""
withvalue(::Type{Q}, val) where {Q<:AbstractQuantity} = Quantity(val, unit(Q))
withvalue(x::AbstractQuantity, val) = withvalue(typeof(x), val)

*(x::Number, y::Units, z::Units...) = Quantity(x,*(y,z...))
*(x::Units, y::Number) = *(y,x)

*(x::AbstractQuantity, y::Units, z::Units...) = Quantity(x.val, *(unit(x),y,z...))
*(x::AbstractQuantity, y::AbstractQuantity) = Quantity(x.val*y.val, unit(x)*unit(y))

function *(x::Number, y::AbstractQuantity)
    y isa AffineQuantity &&
        throw(AffineError("an invalid operation was attempted with affine quantities: $x*$y"))
    return withvalue(y, x*y.val)
end
function *(x::AbstractQuantity, y::Number)
    x isa AffineQuantity &&
        throw(AffineError("an invalid operation was attempted with affine quantities: $x*$y"))
    return withvalue(x, x.val*y)
end

*(A::Units, B::AbstractArray) = broadcast(*, A, B)
*(A::AbstractArray, B::Units) = broadcast(*, A, B)

/(A::AbstractArray, B::Units) = broadcast(/, A, B)

# Division (units)
/(x::AbstractQuantity, y::Units) = Quantity(x.val, unit(x) / y)
/(x::Units, y::AbstractQuantity) = Quantity(1/y.val, x / unit(y))
/(x::Number, y::Units) = Quantity(x,inv(y))
/(x::Units, y::Number) = (1/y) * x

//(x::AbstractQuantity, y::Units) = Quantity(x.val, unit(x) / y)
//(x::Units, y::AbstractQuantity) = Quantity(1//y.val, x / unit(y))
//(x::Number, y::Units) = Rational(x)/y
//(x::Units, y::Number) = (1//y) * x

/(x::AbstractQuantity, y::AbstractQuantity) = Quantity(/(x.val, y.val), unit(x) / unit(y))
function /(x::AbstractQuantity, y::Number)
    x isa AffineQuantity &&
        throw(AffineError("an invalid operation was attempted with affine quantities: $x/$y"))
    return withvalue(x, x.val / y)
end
/(x::Number, y::AbstractQuantity) = Quantity(/(x, y.val), unit(x) / unit(y))
//(x::AbstractQuantity, y::AbstractQuantity) = Quantity(//(x.val, y.val), unit(x) / unit(y))
function //(x::AbstractQuantity, y::Number)
    x isa AffineQuantity &&
        throw(AffineError("an invalid operation was attempted with affine quantities: $x//$y"))
    return withvalue(x, x.val // y)
end
//(x::Number, y::AbstractQuantity) = Quantity(//(x, y.val), unit(x) / unit(y))

# ambiguity resolution
//(x::AbstractQuantity, y::Complex) = withvalue(x, x.val // y)

for f in (:fld, :cld)
    @eval begin
        function ($f)(x::AbstractQuantity, y::AbstractQuantity)
            z = uconvert(unit(y), x)        # TODO: use promote?
            ($f)(z.val,y.val)
        end

        ($f)(x::Number, y::AbstractQuantity) = Quantity(($f)(x, ustrip(y)), unit(x) / unit(y))

        ($f)(x::AbstractQuantity, y::Number) = withvalue(x, ($f)(ustrip(x), y))
    end
end

function div(x::AbstractQuantity, y::AbstractQuantity, r...)
    z = uconvert(unit(y), x)        # TODO: use promote?
    div(z.val,y.val, r...)
end

function div(x::Number, y::AbstractQuantity, r...)
    Quantity(div(x, ustrip(y), r...), unit(x) / unit(y))
end

function div(x::AbstractQuantity, y::Number, r...)
    withvalue(x, div(ustrip(x), y, r...))
end

for f in (:mod, :rem)
    @eval function ($f)(x::AbstractQuantity, y::AbstractQuantity)
        z = uconvert(unit(y), x)        # TODO: use promote?
        v = ($f)(z.val, y.val)
        typeof(x) === typeof(y) ? withvalue(y, v) : Quantity(v, unit(y))
    end
end

_affineerror(f, args...) =
    throw(AffineError("an invalid operation was attempted with affine quantities: $f($(join(args, ", ")))"))

for f in (:div, :rem, :divrem)
    for r = (RoundNearest, RoundNearestTiesAway, RoundNearestTiesUp,
             RoundToZero, RoundUp, RoundDown)
        @eval begin
            $f(x::AffineQuantity, y::AffineQuantity, ::typeof($r)) = _affineerror($f, x, y, $r)
            $f(x::AffineQuantity, y::AbstractQuantity, ::typeof($r)) = _affineerror($f, x, y, $r)
            $f(x::AbstractQuantity, y::AffineQuantity, ::typeof($r)) = _affineerror($f, x, y, $r)
        end
    end
end
for f = (:div, :cld, :fld, :rem, :mod)
    @eval begin
        $f(x::AffineQuantity, y::AffineQuantity) = _affineerror($f, x, y)
        $f(x::AffineQuantity, y::AbstractQuantity) = _affineerror($f, x, y)
        $f(x::AbstractQuantity, y::AffineQuantity) = _affineerror($f, x, y)
    end
end

Base.mod2pi(x::DimensionlessQuantity) = mod2pi(uconvert(NoUnits, x))
Base.mod2pi(x::AbstractQuantity{S, NoDims, <:Units{(Unitful.Unit{:Degree, NoDims}(0, 1//1),),
    NoDims}}) where S = mod(x, 360°)
Base.modf(x::DimensionlessQuantity) = modf(uconvert(NoUnits, x))

# Addition / subtraction
for op in [:+, :-]
    @eval function ($op)(x::AbstractQuantity{S,D,U}, y::AbstractQuantity{T,D,U}) where {S,T,D,U}
        typeof(x) === typeof(y) && return withvalue(x, ($op)(x.val, y.val))
        x isa Quantity && y isa Quantity && return Quantity(($op)(x.val, y.val), U())
        return ($op)(promote(x, y)...)
    end

    @eval function ($op)(x::AbstractQuantity{S,D,SU}, y::AbstractQuantity{T,D,TU}) where {S,T,D,SU,TU}
        ($op)(promote(x,y)...)
    end

    @eval ($op)(x::AbstractQuantity, y::AbstractQuantity) = throw(DimensionError(x,y))
    @eval ($op)(x::AbstractQuantity) = withvalue(x, ($op)(x.val))
end

function +(x::AffineQuantity{S,D}, y::AbstractQuantity{T,D}) where {S,T,D}
    pu = promote_unit(unit(x), unit(y))     # units for the final result.

    # Get x on an absolute scale. FreeUnits in the line below prevents
    # promote(x′, y) from yielding affine quantities. If x had `ContextUnits` and
    # the promotion units were affine units, x′+y would error without this.
    x′ = Quantity(x.val - affinetranslation(unit(x)), FreeUnits(absoluteunit(x)))

    # Likewise if y were not affine but y had ContextUnits and the promotion units were
    # affine, x′+y could also fail.
    y′ = Quantity(y.val, FreeUnits(unit(y)))

    return uconvert(pu, x′+y′)  # we get back the promotion context in the end
end
+(x::AbstractQuantity, y::AffineQuantity) = +(y,x)

# Disallow addition of affine quantities
+(x::AffineQuantity, y::AffineQuantity) = throw(AffineError(
   "an invalid operation was attempted with affine quantities: $x + $y"))

# Specialize subtraction of affine quantities
-(x::AffineQuantity, y::AffineQuantity) = -(promote(x,y)...)
function -(x::T, y::T) where T <: AffineQuantity
    return Quantity(x.val - y.val, absoluteunit(unit(x)))
end

# Disallow subtracting an affine quantity from a quantity
-(x::AbstractQuantity, y::AffineQuantity) =
    throw(AffineError("an invalid operation was attempted with affine quantities: $x - $y"))

# Needed until LU factorization is made to work with unitful numbers
function inv(x::StridedMatrix{T}) where {T <: AbstractQuantity}
    m = inv(ustrip(x))
    iq = eltype(m)
    reinterpret(Quantity{iq, inv(dimension(T)), typeof(inv(unit(T)))}, m)
end

# Other mathematical functions

# `fma` and `muladd`
# The idea here is that if the numeric backing types are not the same, they
# will be promoted to be the same by the generic `fma(::Number, ::Number, ::Number)`
# method. We then catch the possible results and handle the units logic with one
# performant method.

for (_x,_y) in [(:fma, :_fma), (:muladd, :_muladd)]
    # Catch some signatures pre-promotion
    @eval @inline ($_x)(x::Number, y::AbstractQuantity, z::AbstractQuantity) =
        ($_y)(x, y, z, typeof(y) === typeof(z))
    @eval @inline ($_x)(x::AbstractQuantity, y::Number, z::AbstractQuantity) =
        ($_y)(x, y, z, typeof(x) === typeof(z))

    # Post-promotion
    @eval @inline ($_x)(x::AbstractQuantity, y::AbstractQuantity, z::AbstractQuantity) =
        ($_y)(x, y, z, false)

    # It seems like most of this is optimized out by the compiler, including the
    # apparent runtime check of dimensions, which does not appear in @code_llvm.
    @eval @inline function ($_y)(x, y, z, samekind)
        dimension(x) * dimension(y) != dimension(z) && throw(DimensionError(x*y,z))
        uI = unit(x)*unit(y)
        uF = promote_unit(uI, unit(z))
        c = ($_x)(ustrip(x), ustrip(y), ustrip(uconvert(uI, z)))
        return samekind ? withvalue(z, c) : uconvert(uF, Quantity(c, uI))
    end
end

sqrt(x::AbstractQuantity) = Quantity(sqrt(x.val), sqrt(unit(x)))
cbrt(x::AbstractQuantity) = Quantity(cbrt(x.val), cbrt(unit(x)))

for _y in (:sin, :cos, :tan, :asin, :acos, :atan, :sinh, :cosh, :tanh, :asinh, :acosh, :atanh,
           :sinpi, :cospi, :tanpi, :sinc, :cosc, :sincos, :sincospi)
    if isdefined(Base, _y)
        @eval Base.$(_y)(x::DimensionlessQuantity) = Base.$(_y)(uconvert(NoUnits, x))
    end
end
cis(x::DimensionlessQuantity{<:Real}) = Complex(reverse(sincos(x))...)
cis(x::DimensionlessQuantity{<:Complex}) = exp(-imag(x)) * cis(real(x))
cispi(x::DimensionlessQuantity{<:Real}) = Complex(reverse(sincospi(x))...)
cispi(x::DimensionlessQuantity{<:Complex}) = exp(-(π*imag(x))) * cispi(real(x))

atan(y::AbstractQuantity{T1,D,U1}, x::AbstractQuantity{T2,D,U2}) where {T1,T2,D,U1,U2} =
    atan(promote(y,x)...)
atan(y::AbstractQuantity{T,D,U}, x::AbstractQuantity{T,D,U}) where {T,D,U} = atan(y.val,x.val)
atan(y::AbstractQuantity, x::AbstractQuantity) = throw(DimensionError(x,y))

abs(x::AbstractQuantity) = withvalue(x, abs(x.val))
abs2(x::AbstractQuantity) = Quantity(abs2(x.val), unit(x)*unit(x))
angle(x::AbstractQuantity{<:Complex}) = angle(x.val)

copysign(x::AbstractQuantity, y::Number) = withvalue(x, copysign(x.val, y/unit(y)))
copysign(x::Number, y::AbstractQuantity) = copysign(x,y/unit(y))
copysign(x::AbstractQuantity, y::AbstractQuantity) = withvalue(x, copysign(x.val, y/unit(y)))

flipsign(x::AbstractQuantity, y::Number) = withvalue(x, flipsign(x.val, y/unit(y)))
flipsign(x::Number, y::AbstractQuantity) = flipsign(x,y/unit(y))
flipsign(x::AbstractQuantity, y::AbstractQuantity) = withvalue(x, flipsign(x.val, y/unit(y)))

for (i,j) in zip((:<, :<=, :isless), (:_lt, :_le, :_isless))
    @eval ($i)(x::AbstractQuantity, y::AbstractQuantity) = ($j)(x,y)
    @eval ($i)(x::AbstractQuantity, y::Number) = ($i)(promote(x,y)...)
    @eval ($i)(x::Number, y::AbstractQuantity) = ($i)(promote(x,y)...)

    # promotion might not yield Quantity types
    @eval @inline ($j)(x::AbstractQuantity{T1}, y::AbstractQuantity{T2}) where {T1,T2} = ($i)(promote(x,y)...)
    # If it does yield Quantity types, we'll get back here,
    # since at least the numeric part can be promoted.
    @eval @inline ($j)(x::AbstractQuantity{T,D,U}, y::AbstractQuantity{T,D,U}) where {T,D,U} = ($i)(x.val,y.val)
    @eval @inline ($j)(x::AbstractQuantity{T,D,U1}, y::AbstractQuantity{T,D,U2}) where {T,D,U1,U2} = ($i)(promote(x,y)...)
    @eval @inline ($j)(x::AbstractQuantity{T,D1,U1}, y::AbstractQuantity{T,D2,U2}) where {T,D1,D2,U1,U2} = throw(DimensionError(x,y))
end

Base.rtoldefault(::Type{<:AbstractQuantity{T,D,U}}) where {T,D,U} = Base.rtoldefault(T)

function isapprox(
    x::AbstractQuantity{T,D,U},
    y::AbstractQuantity{T,D,U};
    atol = zero(Quantity{real(T),D,U}),
    kwargs...,
) where {T,D,U}
    return isapprox(x.val, y.val; atol=ustrip(unit(y), atol), kwargs...)
end

function isapprox(x::AbstractQuantity, y::AbstractQuantity; kwargs...)
    dimension(x) != dimension(y) && return false
    return isapprox(promote(x,y)...; kwargs...)
end

function isapprox(x::AbstractQuantity, y::Number; atol=nothing, kwargs...)
    if atol === nothing
        return isapprox(promote(x, y)...; kwargs...)
    end
    xp, yp, atolp = promote(x, y, atol)
    return isapprox(xp, yp; atol=atolp, kwargs...)
end
isapprox(x::Number, y::AbstractQuantity; kwargs...) = isapprox(y, x; kwargs...)

function isapprox(
    x::AbstractArray{<:AbstractQuantity{T1,D,U1}},
    y::AbstractArray{<:AbstractQuantity{T2,D,U2}};
    atol=zero(Quantity{real(T1),D,U1}),
    rtol::Real=Base.rtoldefault(T1,T2,atol>zero(atol)),
    nans::Bool=false,
    norm::Function=norm,
) where {T1,D,U1,T2,U2}
    d = norm(x - y)
    if isfinite(d)
        return iszero(rtol) ? d <= atol : d <= max(atol, rtol*max(norm(x), norm(y)))
    else
        # Fall back to a component-wise approximate comparison
        return all(ab -> isapprox(ab[1], ab[2]; rtol=rtol, atol=atol, nans=nans), zip(x, y))
    end
end

isapprox(x::AbstractArray{S}, y::AbstractArray{T};
    kwargs...) where {S <: AbstractQuantity,T <: AbstractQuantity} = false

function isapprox(x::AbstractArray{S}, y::AbstractArray{N};
    atol=nothing, kwargs...) where {S <: AbstractQuantity,N <: Number}
    if dimension(N) == dimension(S)
        if atol === nothing
            isapprox(map(x->uconvert(NoUnits,x),x), y; kwargs...)
        else
            isapprox(map(x->uconvert(NoUnits,x),x), y; atol = ustrip(NoUnits, atol), kwargs...)
        end
    else
        false
    end
end

isapprox(y::AbstractArray{N}, x::AbstractArray{S};
    kwargs...) where {S <: AbstractQuantity,N <: Number} = isapprox(x,y; kwargs...)

for cmp in [:(==), :isequal]
    @eval $cmp(x::AbstractQuantity{S,D,U}, y::AbstractQuantity{T,D,U}) where {S,T,D,U} = $cmp(x.val, y.val)
    @eval function $cmp(x::AbstractQuantity, y::AbstractQuantity)
        dimension(x) != dimension(y) && return false
        $cmp(promote(x,y)...)
    end

    @eval function $cmp(x::AbstractQuantity, y::Number)
        $cmp(promote(x,y)...)
    end
    @eval $cmp(x::Number, y::AbstractQuantity) = $cmp(y,x)
end

# For now, hashes of quantities that are equal but have different units are not equal
function hash(x::AbstractQuantity, h::UInt)
    hash(x.val, hash(FreeUnits(unit(x)), h))
end

_dimerr(f) = error("$f can only be well-defined for dimensionless ",
        "numbers. For dimensionful numbers, different input units yield physically ",
        "different results.")
for f in [:isinteger, :iseven, :isodd]
    @eval $f(x::AbstractQuantity) = _dimerr($f)
    @eval $f(x::DimensionlessQuantity) = $f(uconvert(NoUnits, x))
end

_rounderr() = error("specify the type of the quantity to convert to ",
    "when rounding quantities. Example: round(typeof(1u\"m\"), 137u\"cm\").")

# convenience methods
round(u::Units, q::AbstractQuantity, r::RoundingMode=RoundNearest; kwargs...) =
    Quantity(round(ustrip(u, q), r; kwargs...), u)
round(::Type{T}, u::Units, q::AbstractQuantity, r::RoundingMode=RoundNearest;
        kwargs...) where {T<:Number} =
    round(Quantity{T, dimension(u), typeof(u)}, q, r; kwargs...)

# workhorse methods
round(x::AbstractQuantity, r::RoundingMode=RoundNearest; kwargs...) =
    _rounderr()
round(x::DimensionlessQuantity; kwargs...) = round(uconvert(NoUnits, x); kwargs...)
round(x::DimensionlessQuantity, r::RoundingMode; kwargs...) =
    round(uconvert(NoUnits, x), r; kwargs...)
round(::Type{T}, x::AbstractQuantity, r::RoundingMode=RoundNearest;
    kwargs...) where {T<:Number} = _dimerr(:round)
round(::Type{T}, x::DimensionlessQuantity, r::RoundingMode=RoundNearest;
    kwargs...) where {T<:Number} = round(T, uconvert(NoUnits, x), r; kwargs...)
function round(::Type{T}, x::AbstractQuantity;
        kwargs...) where {S, T <: AbstractQuantity{S}}
    u = unit(T)
    unitless = ustrip(u, x)
    return convert(T, Quantity{S, dimension(T), typeof(u)}(round(unitless; kwargs...)))
end
function round(::Type{T}, x::AbstractQuantity, r::RoundingMode;
        kwargs...) where {S, T <: AbstractQuantity{S}}
    u = unit(T)
    unitless = ustrip(u, x)
    return convert(T, Quantity{S, dimension(T), typeof(u)}(round(unitless, r; kwargs...)))
end
round(::Type{T}, x::DimensionlessQuantity; kwargs...) where {S, T <: AbstractQuantity{S}} =
    invoke(round, Tuple{Type{T},AbstractQuantity}, T, x; kwargs...) # for ambiguity resolution
round(::Type{T}, x::DimensionlessQuantity, r::RoundingMode; kwargs...) where {S, T <: AbstractQuantity{S}} =
    invoke(round, Tuple{Type{T},AbstractQuantity,RoundingMode}, T, x, r; kwargs...) # for ambiguity resolution

# that should actually be fixed in Base ↓
for (f,r) = ((:trunc, :RoundToZero), (:floor, :RoundDown), (:ceil, :RoundUp))
    @eval $f(x::AbstractQuantity; kwargs...) = round(x, $r; kwargs...)
    @eval $f(::Type{T}, x::AbstractQuantity; kwargs...) where {T<:Number} =
        round(T, x, $r; kwargs...)
    @eval $f(u::Units, x::AbstractQuantity; kwargs...) = round(u, x, $r; kwargs...)
end

zero(x::AbstractQuantity) = withvalue(x, zero(x.val))
zero(x::AffineQuantity) = Quantity(zero(x.val), absoluteunit(x))
zero(x::Type{<:AbstractQuantity{T}}) where {T} = throw(ArgumentError("zero($x) not defined."))
zero(x::Type{<:AbstractQuantity{T,D}}) where {T,D} = zero(T) * upreferred(D)
zero(x::Type{<:AbstractQuantity{T,D,U}}) where {T,D,U<:ScalarUnits} = withvalue(x, zero(T))
zero(x::Type{<:AbstractQuantity{T,D,U}}) where {T,D,U<:AffineUnits} = zero(T)*absoluteunit(U())

function zero(x::AbstractArray{T}) where T<:AbstractQuantity
    if isconcretetype(T)
        z = zero(T)
        fill!(similar(x, typeof(z)), z)
    else
        dest = similar(x)
        for i = eachindex(x)
            if isassigned(x, i...)
                dest[i] = zero(x[i])
            else
                dest[i] = zero(T)
            end
        end
        dest
    end
end
@static if VERSION < v"1.8.0-DEV.107"
    function zero(x::AbstractArray{Union{T,Missing}}) where T<:AbstractQuantity # only matches _concrete_ T ...
        @assert isconcretetype(T) # ... but check anyway
        z = zero(T)
        fill!(similar(x, typeof(z)), z)
    end
end

one(x::AbstractQuantity) = one(x.val)
one(x::AffineQuantity) =
    throw(AffineError("no multiplicative identity for affine quantity $x."))
oneunit(x::AffineQuantity) = Quantity(one(x.val), absoluteunit(x))
oneunit(x::Type{<:AbstractQuantity{T,D,U}}) where {T,D,U<:AffineUnits} = Quantity(one(T), absoluteunit(U()))
get_T(::Type{<:AbstractQuantity{T}}) where T = T
get_T(::Type{<:AbstractQuantity{T,D}}) where {T,D} = T
get_T(::Type{<:AbstractQuantity{T,D,U}}) where {T,D,U} = T
one(x::Type{<:AbstractQuantity}) = one(get_T(x))
one(x::Type{<:AffineQuantity}) =
    throw(AffineError("no multiplicative identity for affine quantity type $x."))

isreal(x::AbstractQuantity) = isreal(x.val)
isfinite(x::AbstractQuantity) = isfinite(x.val)
isinf(x::AbstractQuantity) = isinf(x.val)
isnan(x::AbstractQuantity) = isnan(x.val)
@static if VERSION ≥ v"1.7.0-DEV.119"
    isunordered(x::AbstractQuantity) = isunordered(x.val)
end

eps(x::Quantity) = typeof(x)(eps(x.val))
eps(x::AbstractQuantity) = withvalue(x, eps(x.val))
eps(x::Type{T}) where {T<:AbstractQuantity} = eps(Unitful.numtype(T))

unsigned(x::AbstractQuantity) = withvalue(x, unsigned(x.val))

for f in (:exp, :exp10, :exp2, :expm1, :log, :log10, :log1p, :log2)
    @eval ($f)(x::DimensionlessQuantity) = ($f)(uconvert(NoUnits, x))
end

real(x::AbstractQuantity) = Quantity(real(x.val), unit(x))
imag(x::AbstractQuantity) = Quantity(imag(x.val), unit(x))
conj(x::AbstractQuantity) = withvalue(x, conj(x.val))

@inline norm(x::AbstractQuantity, p::Real=2) = withvalue(x, norm(x.val, p))

"""
    sign(x::AbstractQuantity)
Returns the sign of `x`.
"""
sign(x::AbstractQuantity) = sign(x.val)

"""
    signbit(x::AbstractQuantity)
Returns the sign bit of the underlying numeric value of `x`.
"""
signbit(x::AbstractQuantity) = signbit(x.val)

prevfloat(x::AbstractQuantity{T}, d::Integer) where {T <: AbstractFloat} = withvalue(x, prevfloat(x.val, d))
prevfloat(x::AbstractQuantity{T}) where {T <: AbstractFloat} = prevfloat(x, 1)
nextfloat(x::AbstractQuantity{T}, d::Integer) where {T <: AbstractFloat} = withvalue(x, nextfloat(x.val, d))
nextfloat(x::AbstractQuantity{T}) where {T <: AbstractFloat} = nextfloat(x, 1)

function frexp(x::AbstractQuantity{T}) where {T <: AbstractFloat}
    a,b = frexp(x.val)
    a*unit(x), b
end

for f in (:float, :BigFloat, :Float64, :Float32, :Float16)
    @eval begin
    """
        $($f)(x::AbstractQuantity)
    Convert the numeric backing type of `x` to a floating-point representation.
    Returns a quantity with the same units, see [`Unitful.withvalue`](@ref).
    """
    (Base.$f)(x::AbstractQuantity) = withvalue(x, $f(x.val))
    end
end

"""
    Integer(x::AbstractQuantity)
Convert the numeric backing type of `x` to an integer representation.
Returns a quantity with the same units, see [`Unitful.withvalue`](@ref).
"""
Integer(x::AbstractQuantity) = withvalue(x, Integer(x.val))

"""
    Rational(x::AbstractQuantity)
Convert the numeric backing type of `x` to a rational number representation.
Returns a quantity with the same units, see [`Unitful.withvalue`](@ref).
"""
Rational(x::AbstractQuantity) = withvalue(x, Rational(x.val))

big(x::Quantity{T,D,U}) where {T,D,U} = Quantity{big(T),D,U}(big(x.val))
big(x::AbstractQuantity) = withvalue(x, big(x.val))
big(::Type{Quantity{T,D,U}}) where {T,D,U} = Quantity{big(T),D,U}
big(Q::Type{<:AbstractQuantity{T,D,U}}) where {T,D,U} = typeof(withvalue(Q, zero(big(T))))

Base.hastypemax(::Type{<:AbstractQuantity{T}}) where {T} = Base.hastypemax(T)

typemin(Q::Type{<:AbstractQuantity{T,D,U}}) where {T,D,U} = withvalue(Q, typemin(T))
typemin(x::AbstractQuantity{T}) where {T} = withvalue(x, typemin(T))

typemax(Q::Type{<:AbstractQuantity{T,D,U}}) where {T,D,U} = withvalue(Q, typemax(T))
typemax(x::AbstractQuantity{T}) where {T} = withvalue(x, typemax(T))

Base.literal_pow(::typeof(^), x::AbstractQuantity, ::Val{v}) where {v} =
    Quantity(Base.literal_pow(^, x.val, Val(v)),
             Base.literal_pow(^, unit(x), Val(v)))

# All of these are needed for ambiguity resolution
^(x::AbstractQuantity, y::Integer) = Quantity((x.val)^y, unit(x)^y)
@static if VERSION ≥ v"1.8.0-DEV.501"
    Base.@constprop(:aggressive, ^(x::AbstractQuantity, y::Rational) = Quantity((x.val)^y, unit(x)^y))
else
    ^(x::AbstractQuantity, y::Rational) = Quantity((x.val)^y, unit(x)^y)
end
^(x::AbstractQuantity, y::Real) = Quantity((x.val)^y, unit(x)^y)

Base.rand(r::Random.AbstractRNG, ::Random.SamplerType{Q}) where {T,D,U,Q<:AbstractQuantity{T,D,U}} =
    convert(Q, Quantity(rand(r, T), U()))
Base.ones(Q::Type{<:AbstractQuantity}, dims::NTuple{N,Integer}) where {N} =
    fill!(Array{Q,N}(undef, map(Base.to_dim, dims)), oneunit(Q))
Base.ones(Q::Type{<:AbstractQuantity}, dims::Tuple{}) = fill!(Array{Q}(undef), oneunit(Q))
Base.ones(a::AbstractArray, Q::Type{<:AbstractQuantity}) = fill!(similar(a,Q), oneunit(Q))
