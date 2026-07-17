```@meta
DocTestSetup = quote
    using Unitful
    using InverseFunctions
end
```
# Manipulating units

## Unitful string macro

```@docs
Unitful.@u_str
Unitful.register
```

## Dimension and unit inspection

We define a function [`dimension`](@ref) that turns, for example, `acre^2` or `1*acre^2`
into `𝐋^4`. We can usually add quantities with the same dimension, regardless of specific
units (`FixedUnits` cannot be automatically converted, however). Note that dimensions cannot
be determined by powers of the units: `ft^2` is an area, but so is `ac^1` (an acre).

There is also a function [`unit`](@ref) that turns, for example, `1*acre^2` into `acre^2`.
You can then query whether the units are `FreeUnits`, `FixedUnits`, etc.

```@docs
Unitful.unit
Unitful.dimension
```

## Unit stripping

```@docs
Unitful.ustrip
```

## Numeric type extraction

```@docs
Unitful.numtype
```

## Unit multiplication

```@docs
*(::Unitful.Units, ::Unitful.Units...)
*(::Unitful.Dimensions, ::Unitful.Dimensions...)
```
