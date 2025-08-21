```@meta
DocTestSetup = quote
    using Unitful
end
```
# Interoperability with the `Dates` standard library

[Julia's `Dates` standard library](https://docs.julialang.org/en/v1/stdlib/Dates/) provides data types for representing specific points in time `Date`/`DateTime` and differences between them, i.e., periods. Unitful provides methods for using period types from the `Dates` standard library together with `Quantity`s.

## Support for `Dates.FixedPeriod`s

The `Dates.FixedPeriod` union type includes all `Dates.Period`s that represent a fixed period of time, i.e., `Dates.Week`, `Dates.Day`, `Dates.Hour`, `Dates.Minute`, `Dates.Second`, `Dates.Millisecond`, `Dates.Microsecond`, and `Dates.Nanosecond`. These types can be converted to `Quantity`s or used in place of them.

!!! note
    `Dates.Year` does not represent a fixed period and cannot be converted to a `Quantity`. While Unitful's `yr` unit is exactly equal to 365.2425 days, a `Dates.Year` may contain 365 or 366 days (see [`Dates.days(::Year)`](@ref) and [`Dates.isleapyear`](@ref)).

Each `FixedPeriod` is considered equivalent to a `Quantity`. For example, `Dates.Millisecond(5)` corresponds to the quantity `Int64(5)*u"ms"`. A `FixedPeriod` can be converted to the equivalent `Quantity` with a constructor:

```@docs
Unitful.Quantity(::Dates.FixedPeriod)
```

In most respects, `FixedPeriod`s behave like their equivalent quantities. They can be converted to other units using `uconvert`, used in arithmetic operations with other quantities, and they have a `unit` and `dimension`:

```jldoctest
julia> using Dates: Hour

julia> p = Hour(3)
3 hours

julia> uconvert(u"s", p)
10800 s

julia> p == 180u"minute"
true

julia> p < 1u"d"
true

julia> 5u"s" + p
10805 s

julia> 210u"km" / p
70.0 km hr^-1

julia> unit(p) === u"hr"
true

julia> dimension(p)
𝐓
```

Conversely, a `FixedPeriod` can be created from a quantity using the appropriate constructor, `convert`, or `round` methods. This will fail (i.e., throw an `InexactError`) if the resulting value cannot be represented as an `Int64`:

```jldoctest
julia> using Dates: Day, Hour, Millisecond

julia> Millisecond(1.5u"s")
1500 milliseconds

julia> convert(Hour, 1u"yr")
8766 hours

julia> Day(1u"yr")
ERROR: InexactError: Int64(1461//4)
[...]

julia> round(Day, 1u"yr")
365 days
```

## Support for `Dates.CompoundPeriod`s

The `Dates` standard library provides the `Dates.CompoundPeriod` type to represent sums of periods of different types:

```@repl
using Dates: Day, Second
Day(5) + Second(1)
typeof(ans)
```

Unitful provides facilities to work with `CompoundPeriod`s as long as they consist only of `FixedPeriod`s. Such `CompoundPeriod`s can be converted to `Quantity`s using `convert`, `uconvert`, or `round`:

```@jldoctest
julia> using Dates: Day, Second

julia> p = Day(5) + Second(1)
5 days, 1 second

julia> uconvert(u"s", p)
432001//1 s

julia> convert(typeof(1.0u"yr"), p)
0.01368928562374832 yr

julia> round(u"d", p)
5//1 d

julia> q = Month(1) + Day(1)  # Month is not a fixed period
1 month, 1 day

julia> uconvert(u"s", q)
ERROR: MethodError: no method matching Quantity{Rational{Int64},𝐓,Unitful.FreeUnits{(s,),𝐓,nothing}}(::Month)
[...]
```

However, not all operations that are defined for `FixedPeriod`s support `CompoundPeriod`s as well.
The reason for that is that a `CompoundPeriod` does not correspond to a specific unit:

```@jldoctest
julia> p = Day(365) + Hour(5) + Minute(49) + Second(12)
365 days, 5 hours, 49 minutes, 12 seconds

julia> unit(p)  # A CompoundPeriod does not have a corresponding unit ...
ERROR: MethodError: no method matching unit(::Dates.CompoundPeriod)
[...]

julia> dimension(p)  # ... but it does have a dimension
𝐓

julia> Quantity(p)  # As a result, there is no Quantity type associated with it ...
ERROR: MethodError: no method matching Quantity(::Int64)
[...]

julia> T = typeof(1.0u"hr"); T(p)  # ... but it can be converted to a concrete time quantity
8765.82 hr
```

Consequently, any operation whose result would depend on the input unit is not supported by `CompoundPeriod`s. For example:

* `+(::Quantity, ::CompoundPeriod)` and `+(::CompoundPeriod, ::Quantity)` error, since the unit of the result depends on the units of both arguments.
* `div(::Quantity, ::CompoundPeriod)` and `div(::CompoundPeriod, ::Quantity)` work, since the result is a dimensionless number.
* `mod(::CompoundPeriod, ::Quantity)` works, but `mod(::Quantity, ::CompoundPeriod)` does not, since the second argument determines the unit of the returned quantity.
