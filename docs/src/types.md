```@meta
DocTestSetup = quote
    using Unitful
end
```
# Types

## Overview
We define a [`Unitful.Unit{U,D}`](@ref) type to represent a unit (`U` is a symbol,
like `:Meter`, and `D` keeps track of dimensional information).
Fields of a `Unit` object keep track of a rational exponents and a power-of-ten
prefix. We don't allow arbitrary floating point exponents of units because they
probably aren't very useful. The prefixes on units (e.g. `nm` or `km`) may help
to avoid overflow issues and general ugliness.

Usually, the user interacts only with `Units` objects, not `Unit` objects.
This is because generically, more than one unit is needed to describe a quantity.
An abstract type [`Unitful.Units{N,D,A}`](@ref) is defined, where `N` is always a tuple
of `Unit` objects, `D` is a [`Unitful.Dimensions{N}`](@ref) object such as `𝐋`, the
object representing the length dimension, and `A` is a translation for affine quantities.

Subtypes of `Unitful.Units{N,D,A}` are used to implement different behaviors
for how to promote dimensioned quantities. The concrete subtypes have no fields and
are therefore immutable singletons. Currently implemented subtypes of `Unitful.Units{N,D,A}`
include [`Unitful.FreeUnits{N,D,A}`](@ref), [`Unitful.ContextUnits{N,D,P,A}`](@ref), and
[`Unitful.FixedUnits{N,D,A}`](@ref). Units defined in the Unitful.jl package itself are all
`Unitful.FreeUnits{N,D,A}` objects.

Finally, we define physical quantity types as [`Quantity{T<:Number, D, U}`](@ref), where
`D :: Dimensions` and `U <: Units`. By putting units in the type signature of a
quantity, staged functions can be used to offload as much of the unit
computation to compile-time as is possible. By also having the dimensions
explicitly in the type signature, dispatch can be done on dimensions:
`isa(1u"m", Unitful.Length) == true`. This works because `Length` is a type alias for
some subset of `Unitful.Quantity` subtypes.

## API

### Quantities

```@docs
    Unitful.AbstractQuantity
    Unitful.Quantity
    Unitful.DimensionlessQuantity
```

### Units and dimensions

```@docs
    Unitful.Unitlike
    Unitful.Units
    Unitful.FreeUnits
    Unitful.ContextUnits
    Unitful.FixedUnits
    Unitful.Dimensions
    Unitful.Unit
    Unitful.Dimension
	Unitful.NoDims
```
