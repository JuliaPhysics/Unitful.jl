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

    sort!(b, by=power)
    sort!(b, by=name)

    c = Vector{Dimension}()
    if !isempty(b)
        next = iterate(b)
        p = 0//1
        oldvalue = next[1]
        while next !== nothing
            (value, state) = next
            if name(value) == name(oldvalue)
                p += power(value)
            else
                if p != 0
                    push!(c, Dimension{name(oldvalue)}(p))
                end
                p = power(value)
            end
            oldvalue = value
            next = iterate(b, state)
        end

        if p != 0
            push!(c, Dimension{name(oldvalue)}(p))
        end
    end

    d = (c...,)
    :(Dimensions{$d}())
end

/(x::Dimensions, y::Dimensions) = *(x,inv(y))
//(x::Dimensions, y::Dimensions)  = x/y

# Both methods needed for ambiguity resolution
^(x::Dimension{T}, y::Integer) where {T} = Dimension{T}(power(x)*y)
^(x::Dimension{T}, y::Number) where {T} = Dimension{T}(power(x)*y)

# A word of caution:
# Exponentiation is not type-stable for `Dimensions` objects in many cases
^(x::Dimensions{T}, y::Integer) where {T} = *(Dimensions{map(a->a^y, T)}())
^(x::Dimensions{T}, y::Number) where {T} = *(Dimensions{map(a->a^y, T)}())

# Raise each `Unit` or `Dimension` in the tuple `xs` to the power `p`. Used in generators,
# so it maps over a `Vector` with a single function type to avoid compiling the
# reduction machinery once per tuple of units and once per call site.
_powtuple(@nospecialize(xs::Tuple), p) = (map(Base.Fix2(^, p), Any[xs...])...,)

@generated function Base.literal_pow(::typeof(^), x::Dimensions{T}, ::Val{p}) where {T,p}
    z = *(Dimensions{_powtuple(T, p)}())
    :($z)
end

# Since exponentiation is not type stable, we define a special `inv` method to enable fast
# division. For julia 0.6.0, the appropriate methods for ^ and * need to be defined before
# this one!
for (fun,pow) in ((:inv, -1//1), (:sqrt, 1//2), (:cbrt, 1//3))
    # The following are generated functions to ensure type stability.
    @eval @generated function ($fun)(x::Dimensions)
        dimtuple = _powtuple(x.parameters[1], $pow)
        y = *(Dimensions{dimtuple}())    # sort appropriately
        :($y)
    end
end
