const colon = Base.:(:)

import Base: ArithmeticRounds
import Base: OrderStyle, Ordered, ArithmeticStyle, ArithmeticWraps
import Base.Broadcast: DefaultArrayStyle, broadcasted

*(y::Units, r::AbstractRange) = *(r,y)
*(r::AbstractRange, y::Units, z::Units...) = *(r, *(y,z...))

# start, stop, length
Base._range(start::Quantity, ::Nothing, stop, len::Integer) =
    _unitful_start_stop_length(start, stop, len)
Base._range(start, ::Nothing, stop::Quantity, len::Integer) =
    _unitful_start_stop_length(start, stop, len)
Base._range(start::Quantity, ::Nothing, stop::Quantity, len::Integer) =
    _unitful_start_stop_length(start, stop, len)
function _unitful_start_stop_length(start, stop, len)
    dimension(start) != dimension(stop) && throw(DimensionError(start, stop))
    a, b = promote(start, stop)
    Base._range(a, nothing, b, len)
end
Base._range(start::T, ::Nothing, stop::T, len::Integer) where {T<:Quantity} =
    LinRange{T}(start, stop, len)
Base._range(start::T, ::Nothing, stop::T, len::Integer) where {T<:Quantity{<:Integer}} =
    Base._linspace(Float64, ustrip(start), ustrip(stop), len, 1)*unit(T)
Base._range(start::T, ::Nothing, stop::T, len::Integer) where {T<:Quantity{<:Base.IEEEFloat}} =
    Base._range(ustrip(start), nothing, ustrip(stop), len) * unit(T)

# start, step, length
Base._range(a::T, step::T, ::Nothing, len::Integer) where {T<:Quantity{<:Base.IEEEFloat}} =
    Base._range(ustrip(a), ustrip(step), nothing, len) * unit(T)
Base._range(a::T, step::T, ::Nothing, len::Integer) where {T<:Quantity{<:AbstractFloat}} =
    StepRangeLen{typeof(step*len),typeof(a),typeof(step)}(a, step, len)
Base._range(a::T, step::T, ::Nothing, len::Integer) where {T<:Quantity} =
    @static if VERSION ≥ v"1.8.0-DEV"
        Base.range_start_step_length(a, step, len)
    else
        Base._rangestyle(OrderStyle(a), ArithmeticStyle(a), a, step, len)
    end
Base._range(a::Quantity{<:Real}, step::Quantity{<:AbstractFloat}, ::Nothing, len::Integer) =
    _unitful_start_step_length(float(a), step, len)
Base._range(a::Quantity{<:AbstractFloat}, step::Quantity{<:Real}, ::Nothing, len::Integer) =
    _unitful_start_step_length(a, float(step), len)
Base._range(a::Quantity{<:AbstractFloat}, step::Quantity{<:AbstractFloat}, ::Nothing, len::Integer) =
    _unitful_start_step_length(a, step, len)
Base._range(a, step::Quantity, ::Nothing, len::Integer) =
    _unitful_start_step_length(a, step, len)
Base._range(a::Quantity, step, ::Nothing, len::Integer) =
    _unitful_start_step_length(a, step, len)
Base._range(a::Quantity, step::Quantity, ::Nothing, len::Integer) =
    _unitful_start_step_length(a, step, len)
function _unitful_start_step_length(start, step, len)
    dimension(start) != dimension(step) && throw(DimensionError(start,step))
    Base._range(promote(start, uconvert(unit(start), step))..., nothing, len)
end

# start, length (step defaults to 1)
Base._range(a::Quantity, ::Nothing, ::Nothing, len::Integer) =
    Base._range(a, one(a), nothing, len)

# step, stop, length
@static if VERSION ≥ v"1.7"
    Base._range(::Nothing, step, stop::Quantity, len::Integer) =
        _unitful_step_stop_length(step, stop, len)
    Base._range(::Nothing, step::Quantity, stop, len::Integer) =
        _unitful_step_stop_length(step, stop, len)
    Base._range(::Nothing, step::Quantity, stop::Quantity, len::Integer) =
        _unitful_step_stop_length(step, stop, len)
    Base._range(::Nothing, step::Quantity, ::Nothing, len::Integer) =
        Base.range_error(nothing, step, nothing, len)
    function _unitful_step_stop_length(step, stop, len)
        dimension(stop) != dimension(step) && throw(DimensionError(stop,step))
        Base.range_step_stop_length(promote(uconvert(unit(stop), step), stop)..., len)
    end
end

# stop, length (step defaults to 1)
@static if VERSION ≥ v"1.7"
    Base._range(::Nothing, ::Nothing, stop::Quantity, len::Integer) =
        Base._range(nothing, one(stop), stop, len)
end

*(r::AbstractRange, y::Units) = range(first(r)*y, step=step(r)*y, length=length(r))

# first promote start and stop, leaving step alone
colon(start::A, step, stop::C) where {A<:Real,C<:Quantity} = colonstartstop(start,step,stop)
colon(start::A, step, stop::C) where {A<:Quantity,C<:Real} = colonstartstop(start,step,stop)
colon(a::T, b::Quantity, c::T) where {T<:Real} = colon(promote(a,b,c)...)
colon(start::Quantity{<:Real}, step, stop::Quantity{<:Real}) =
    colon(promote(start, step, stop)...)

# promotes start and stop
function colonstartstop(start::A, step, stop::C) where {A,C}
    dimension(start) != dimension(stop) && throw(DimensionError(start, stop))
    colon(convert(promote_type(A,C),start), step, convert(promote_type(A,C),stop))
end

function colon(start::A, step::B, stop::A) where A<:Quantity{<:Real} where B<:Quantity{<:Real}
    dimension(start) != dimension(step) && throw(DimensionError(start, step))
    colon(promote(start, step, stop)...)
end

OrderStyle(::Type{<:AbstractQuantity{T}}) where T = OrderStyle(T)
ArithmeticStyle(::Type{<:AbstractQuantity{T}}) where T = ArithmeticStyle(T)

colon(start::T, step::T, stop::T) where {T<:Quantity{<:Real}} =
    _colon(OrderStyle(T), ArithmeticStyle(T), start, step, stop)
_colon(::Ordered, ::Any, start::T, step, stop::T) where {T} = StepRange(start, step, stop)
_colon(::Ordered, ::ArithmeticRounds, start::T, step, stop::T) where {T} =
    StepRangeLen(start, step, floor(Int, (stop-start)/step)+1)
_colon(::Any, ::Any, start::T, step, stop::T) where {T} =
    StepRangeLen(start, step, floor(Int, (stop-start)/step)+1)

# Opt into TwicePrecision functionality
*(x::Base.TwicePrecision, y::Units) = Base.TwicePrecision(x.hi*y, x.lo*y)
*(x::Base.TwicePrecision, y::Quantity) = (x * ustrip(y)) * unit(y)
uconvert(y, x::Base.TwicePrecision) = Base.TwicePrecision(uconvert(y, x.hi), uconvert(y, x.lo))
ustrip(x::Base.TwicePrecision) = Base.TwicePrecision(ustrip(x.hi), ustrip(x.lo))
@inline upreferred(x::Base.TwicePrecision{T}) where T<:Number = x
@inline upreferred(x::Base.TwicePrecision{T}) where T<:AbstractQuantity =
    uconvert(upreferred(unit(x)), x)

colon(start::T, step::T, stop::T) where {T<:Quantity{<:Base.IEEEFloat}} =
    colon(ustrip(start), ustrip(step), ustrip(stop)) * unit(T) # This will always return a StepRangeLen

# two-argument colon
colon(start, stop::Quantity) = _unitful_start_stop(start, stop)
colon(start::Quantity, stop) = _unitful_start_stop(start, stop)
colon(start::Quantity, stop::Quantity) = _unitful_start_stop(start, stop)
function _unitful_start_stop(start, stop)
    dimension(start) != dimension(stop) && throw(DimensionError(start, stop))
    colon(promote(start, stop)...)
end
function colon(start::T, stop::T) where {T<:Quantity}
    step = uconvert(unit(start), one(start))
    colon(promote(start, step, stop)...)
end

# No need to confuse things by changing the type once units are on there,
# if we can help it.
*(r::StepRangeLen, y::Units) =
    StepRangeLen{typeof(zero(eltype(r))*y)}(r.ref*y, r.step*y, length(r), r.offset)
*(r::LinRange, y::Units) = LinRange(r.start*y, r.stop*y, length(r))
*(r::StepRange, y::Units) = StepRange(r.start*y, r.step*y, r.stop*y)
*(r::AbstractUnitRange, y::Units) = StepRange(first(r)*y, oneunit(first(r))*y, last(r)*y)
function /(x::Base.TwicePrecision, v::Quantity)
    x / Base.TwicePrecision(oftype(ustrip(x.hi)/ustrip(v)*unit(v), v))
end

# These can be removed (I think) if `range_start_step_length()` returns a `StepRangeLen` for
# non-floats, cf. https://github.com/JuliaLang/julia/issues/40672
broadcasted(::DefaultArrayStyle{1}, ::typeof(*), r::AbstractRange, x::AbstractQuantity) =
    broadcasted(DefaultArrayStyle{1}(), *, r, ustrip(x)) * unit(x)
broadcasted(::DefaultArrayStyle{1}, ::typeof(*), x::AbstractQuantity, r::AbstractRange) =
    broadcasted(DefaultArrayStyle{1}(), *, ustrip(x), r) * unit(x)

const BCAST_PROPAGATE_CALLS = Union{typeof(upreferred), Units}
broadcasted(::DefaultArrayStyle{1}, ::typeof(*), r::AbstractRange, x::Ref{<:Units}) = r * x[]
broadcasted(::DefaultArrayStyle{1}, ::typeof(*), x::Ref{<:Units}, r::AbstractRange) = x[] * r
function broadcasted(::DefaultArrayStyle{1}, x::BCAST_PROPAGATE_CALLS, r::StepRangeLen)
    T = typeof(x(zero(eltype(r))))
    if T <: AffineQuantity
        # Keep reference/step arithmetic on a linear scale; convert only the
        # final indexed value to the affine element type.
        return _affine_steprangelen(T, r.ref, r.step, r.len, r.offset)
    end
    return StepRangeLen{T}(x(r.ref), x(r.step), r.len, r.offset)
end

function _affine_steprangelen(::Type{T}, ref, step, len, offset) where {T}
    if ref isa Base.TwicePrecision || step isa Base.TwicePrecision
        # Mixed storage would use Base's component-wise TwicePrecision-to-T
        # conversion, which treats both components as affine points.
        ref = ref isa Base.TwicePrecision ? ref : Base.TwicePrecision(ref, zero(ref))
        step = step isa Base.TwicePrecision ? step : Base.TwicePrecision(step, zero(step))
    end
    return StepRangeLen{T}(ref, step, len, offset)
end

Base.step(r::StepRangeLen{T,R,S}) where {T<:AffineQuantity,R<:Base.TwicePrecision{<:ScalarQuantity},S<:Base.TwicePrecision{<:ScalarQuantity}} =
    r.step.hi + r.step.lo

function Base.getindex(r::StepRangeLen{T,R,S}, indices::Base.OrdinalRange{I}) where {T<:AffineQuantity,R<:Base.TwicePrecision{<:ScalarQuantity},S<:Base.TwicePrecision{<:ScalarQuantity},I<:Integer}
    # Slice with linear arithmetic as well, including empty/singleton slices
    # for which Base may replace the high-precision reference with a scalar.
    raw = StepRangeLen{typeof(r.ref.hi)}(r.ref, r.step, r.len, r.offset)[indices]
    return _affine_steprangelen(T, raw.ref, raw.step, raw.len, raw.offset)
end
function broadcasted(::DefaultArrayStyle{1}, x::BCAST_PROPAGATE_CALLS, r::StepRange)
    start = x(r.start)
    au_to = absoluteunit(unit(start))
    step = uconvert(au_to, r.step)
    if Base.ArithmeticStyle(start) == Base.ArithmeticRounds() || Base.ArithmeticStyle(step) == Base.ArithmeticRounds()
        au_from = absoluteunit(unit(r.start))
        astart = ustrip(au_from, r.start)
        astop = ustrip(au_from, r.stop)
        len = length(r)
        offset = _offset_for_steprangelen(astart, astop, len)
        nb = ndigits(max(offset-1, len-offset), base=2, pad=0)
        T = promote_type(typeof(start/unit(start)), typeof(step/unit(step)))
        unitless_range = Base.steprangelen_hp(T, ustrip(au_to, r[offset]), ustrip(au_to, step), nb, len, offset)
        return unitless_range * unit(start)
    else
        return StepRange(start, step, x(r.stop))
    end
end
broadcasted(::DefaultArrayStyle{1}, x::BCAST_PROPAGATE_CALLS, r::LinRange) = LinRange(x(r.start), x(r.stop), r.len)
broadcasted(::DefaultArrayStyle{1}, ::typeof(|>), r::AbstractRange, x::Ref{<:BCAST_PROPAGATE_CALLS}) = broadcasted(DefaultArrayStyle{1}(), x[], r)

function _offset_for_steprangelen(start, stop, len)
    if iszero(start)
        return oneunit(len)
    elseif iszero(stop)
        return len
    elseif signbit(start) == signbit(stop)
        return abs(start) < abs(stop) ? oneunit(len) : len
    else
        fstart = Float64(start)
        fstop = Float64(stop)
        return round(typeof(len), (fstop-len*fstart)/(fstop-fstart))
    end
end

_ustrip_range_ref(u::Units, x::Any) = ustrip(u, x)
_ustrip_range_ref(u::Units, x::Base.TwicePrecision) =
    Base.TwicePrecision(ustrip(u, x.hi), ustrip(absoluteunit(u), x.lo))
function broadcasted(::DefaultArrayStyle{1}, ::typeof(ustrip), r::StepRangeLen)
    u = unit(eltype(r))
    ref = _ustrip_range_ref(u, r.ref)
    step = ustrip(absoluteunit(u), r.step)
    return StepRangeLen{typeof(ustrip(zero(eltype(r))))}(ref, step, r.len, r.offset)
end
broadcasted(::DefaultArrayStyle{1}, ::typeof(ustrip), r::StepRange) =
    ustrip(unit(eltype(r)), r.start):ustrip(unit(eltype(r)), r.step):ustrip(unit(eltype(r)), r.stop)
broadcasted(::DefaultArrayStyle{1}, ::typeof(ustrip), r::LinRange) =
    LinRange(ustrip(unit(eltype(r)), r.start), ustrip(unit(eltype(r)), r.stop), r.len)
broadcasted(::DefaultArrayStyle{1}, ::typeof(|>), r::AbstractRange, ::Ref{typeof(ustrip)}) =
    broadcasted(DefaultArrayStyle{1}(), ustrip, r)

# for ambiguity resolution
broadcasted(::DefaultArrayStyle{1}, ::typeof(*), r::StepRangeLen{T}, x::AbstractQuantity) where T =
    broadcasted(DefaultArrayStyle{1}(), *, r, ustrip(x)) * unit(x)
broadcasted(::DefaultArrayStyle{1}, ::typeof(*), x::AbstractQuantity, r::StepRangeLen{T}) where T =
    broadcasted(DefaultArrayStyle{1}(), *, ustrip(x), r) * unit(x)
broadcasted(::DefaultArrayStyle{1}, ::typeof(*), r::LinRange, x::AbstractQuantity) =
    LinRange(r.start*x, r.stop*x, r.len)
broadcasted(::DefaultArrayStyle{1}, ::typeof(*), x::AbstractQuantity, r::LinRange) =
    LinRange(x*r.start, x*r.stop, r.len)
