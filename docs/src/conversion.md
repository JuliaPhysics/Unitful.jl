```@meta
DocTestSetup = quote
    using Unitful
end
```
# Conversion/promotion

## Converting between units

Since `convert` in Julia already means something specific (conversion between
Julia types), we define [`uconvert`](@ref) for conversion between units. Typically
this will also involve a conversion between types, but this function takes care
of figuring out which type is appropriate for representing the desired units.

Exact conversions between units are respected where possible. If rational
arithmetic would result in an overflow, then floating-point conversion should
proceed. Use of floating-point numbers inhibits exact conversion.

```@docs
uconvert
```

Since objects are callable, we can also make [`Unitful.Units`](@ref) callable
with a `Number` as an argument, for a unit conversion shorthand:

```jldoctest
julia> u"cm"(1u"m")
100 cm
```

This syntax is a little confusing, but becomes appealing with the function
chaining operator `|>`:

```jldoctest
julia> 1u"m" |> u"cm"
100 cm
```

Note that since [`Unitful.Units`](@ref) objects have no fields, we don't have
to worry about ambiguity with constructor calls. This way of converting units
results in behavior identical to calling [`uconvert`](@ref).

### Dimensionless quantities

For dimensionless quantities, `uconvert` can be used with the [`NoUnits`](@ref) unit to
strip the units without losing power-of-ten information:

```jldoctest
julia> uconvert(NoUnits, 1.0u"μm/m")
1.0e-6

julia> uconvert(NoUnits, 1.0u"m")
ERROR: DimensionError:  and m are not dimensionally compatible.
```

```@docs
Unitful.NoUnits
```

You can also directly convert to a subtype of `Real` or `Complex`:

```jldoctest
julia> convert(Float64, 1.0u"μm/m")
1.0e-6
```

## Basic promotion mechanisms

We decide the result units for addition and subtraction operations based on looking at the
types only. We can't take runtime values into account without compromising runtime
performance.

If two quantities with the same units are added or subtracted, then the result units
will be the same. If two quantities with differing units (but same dimension) are added
or subtracted, then the result units will be specified by promotion.

### Promotion rules for specific dimensions

You can specify the result units for promoting quantities of a specific dimension
once at the start of a Julia session. For example, you can specify that when promoting
two quantities with different energy units, the resulting quantities should be in
`g*cm^2/s^2`. This is accomplished by defining a `Unitful.promote_unit` method for the units
themselves. Here's an example.

```jldoctest
julia> using Unitful

julia> Unitful.promote_unit(::S, ::T) where {S<:Unitful.EnergyUnits, T<:Unitful.EnergyUnits} = u"g*cm^2/s^2"

julia> promote(2.0u"J", 1.0u"kg*m^2/s^2")
(2.0e7 g cm^2 s^-2, 1.0e7 g cm^2 s^-2)

julia> Unitful.promote_unit(::S, ::T) where {S<:Unitful.EnergyUnits, T<:Unitful.EnergyUnits} = u"J"

julia> promote(2.0u"J", 1.0u"kg*m^2/s^2")
(2.0 J, 1.0 J)
```

If you're wondering where `Unitful.EnergyUnits` comes from, it is defined in
`src/pkgdefaults.jl` by the [`@derived_dimension`](@ref) macro. Similarly,
the calls to the [`@dimension`](@ref) macro define `Unitful.LengthUnits`,
`Unitful.MassUnits`, etc. None of these are exported.

Existing users of Unitful may want to call [`Unitful.promote_to_derived`](@ref)
after Unitful loads to give similar behavior to Unitful 0.0.4 and below. It is
not called by default.

```@docs
Unitful.promote_to_derived
```

### Fallback promotion rules

The [`Unitful.preferunits`](@ref) function is used to designate fallback
preferred units for each pure dimension for promotion. Such a fallback is
required because you need some generic logic to take over when manipulating
quantities with arbitrary dimensions.

The default behavior is to promote to a combination of the base SI units, i.e.
a quantity of dimension `𝐌*𝐋^2/(𝐓^2*𝚯)` would be converted to `kg*m^2/(s^2*K)`:

```jldoctest
julia> promote(1.0u"J/K", 1.0u"g*cm^2/s^2/K")
(1.0 kg m^2 K^-1 s^-2, 1.0e-7 kg m^2 K^-1 s^-2)
```

You can however override this behavior by calling [`Unitful.preferunits`](@ref)
at the start of a Julia session, specifically *before* [`Unitful.upreferred`](@ref)
*has been called or quantities have been promoted*.

```@docs
Unitful.preferunits
Unitful.upreferred
```

### Array promotion

Arrays are typed with as much specificity as possible upon creation. consider
the following three cases:

```jldoctest
julia> [1.0u"m", 2.0u"m"]
2-element Vector{Quantity{Float64, 𝐋, Unitful.LengthFreeUnits{(m,), nothing}}}:
 1.0 m
 2.0 m

julia> [1.0u"m", 2.0u"cm"]
2-element Vector{Quantity{Float64, 𝐋, Unitful.LengthFreeUnits{(m,), nothing}}}:
 1.0 m
 0.02 m

julia> [1.0u"m", 2.0]
2-element Vector{Quantity{Float64}}:
 1.0 m
 2.0
```

In the first case, an array with a concrete type is created. Good
performance should be attainable. The second case invokes promotion so that an
array of concrete type can be created. The third case falls back to an abstract
type, which cannot be stored efficiently and will incur a performance penalty.
An additional benefit of having a concrete type is that we can dispatch on the
dimensions of the array's elements:

```jldoctest
julia> f(x::AbstractArray{T}) where {T<:Unitful.Length} = sum(x)
f (generic function with 1 method)

julia> f([1.0u"m", 2.0u"cm"])
1.02 m

julia> f([1.0u"g", 2.0u"cm"])
ERROR: MethodError: no method matching f(::Vector{Quantity{Float64}})
[...]
```

## Advanced promotion mechanisms

There are some new types as of Unitful.jl v0.2.0 that enable some fairly sophisticated
promotion logic. Three concrete subtypes of [`Unitful.Units{N,D,A}`](@ref) are defined:
[`Unitful.FreeUnits{N,D,A}`](@ref), [`Unitful.ContextUnits{N,D,P,A}`](@ref), and
[`Unitful.FixedUnits{N,D,A}`](@ref).

Units defined in the Unitful.jl package itself are all `Unitful.FreeUnits{N,D,A}` objects.
The "free" in `FreeUnits` indicates that the object carries no information on its own about
how it should respond during promotion. Other code in Unitful dictates that by default,
quantities should promote to SI units. `FreeUnits` use the promotion mechanisms described
in the above section, [Basic promotion mechanisms](@ref). They used to be called `Units`
in prior versions of Unitful.

### ContextUnits

Sometimes, a package may want to default to a particular behavior for promotion, in the
presence of other packages that may require differing default behaviors. An example would be
a CAD package for nanoscale device design: it makes more sense to promote to nanometers or
microns than to meters. For this purpose we define `Unitful.ContextUnits{N,D,P,A}`. The `P` in
this type signature should be some type `Unitful.FreeUnits{M,D,B}` (the dimensions must be the
same). We refer to this as the "context." `ContextUnits` may be easily instantiated by e.g.
`ContextUnits(nm, μm)` for a `nm` unit that will promote to `μm`. Here's an example:

```jldoctest
julia> μm = Unitful.ContextUnits(u"μm", u"μm")
μm

julia> nm = Unitful.ContextUnits(u"nm", u"μm")
nm

julia> 1.0μm + 1.0nm
1.001 μm
```

If the context does not agree, then we fall back to `FreeUnits`:

```jldoctest
julia> μm = Unitful.ContextUnits(u"μm", u"μm")
μm

julia> nm = Unitful.ContextUnits(u"nm", u"cm")
nm

julia> 1.0μm + 1.0nm
1.001e-6 m
```

Multiplying a `ContextUnits` by a `FreeUnits` yields a
`ContextUnits` object, with the preferred units for the additional dimensions being
determined by calling [`Unitful.upreferred`](@ref) on the `FreeUnits` object:

```jldoctest
julia> mm = Unitful.ContextUnits(u"mm", u"μm")
mm

julia> isa(u"g", Unitful.FreeUnits)
true

julia> upreferred(u"g")
kg

julia> mm*u"g"
g mm

julia> isa(mm*u"g", Unitful.ContextUnits)
true

julia> upreferred(mm*u"g")
kg μm
```

### FixedUnits

Sometimes, there may be times where it is required to disable automatic conversion between
quantities with different units. For this purpose there are `Unitful.FixedUnits{N,D,A}`.
Trying to add or compare two quantities with `FixedUnits` will throw an error, provided the
units are not the same. Note that you can still add/compare a quantity with `FixedUnits` to
a quantity with another kind of units; in that case, the result units (if applicable) are
determined by the `FixedUnits`, overriding the preferred units from `ContextUnits` or
`FreeUnits`. Multiplying `FixedUnits` with any other kind of units returns `FixedUnits`:

```jldoctest
julia> mm_fix = Unitful.FixedUnits(u"mm")
mm

julia> cm_fix = Unitful.FixedUnits(u"cm")
cm

julia> 1mm_fix+2mm_fix
3 mm

julia> 1mm_fix+2u"cm"  # u"cm" is a FreeUnits object.
21 mm

julia> 1mm_fix+2*Unitful.ContextUnits(u"cm", u"cm")
21 mm

julia> isa(mm_fix*u"cm", Unitful.FixedUnits)
true

julia> 1mm_fix+2cm_fix
ERROR: automatic conversion prohibited.
[...]

julia> 1mm_fix == 1mm_fix
true

julia> 1mm_fix == 0.1u"cm"
true

julia> 1mm_fix == 0.1cm_fix
ERROR: automatic conversion prohibited.
[...]
```

Much of this functionality is enabled by `promote_unit` definitions. These are not
readily extensible by the user at this point.

```@docs
    Unitful.promote_unit
```

## Unit cancellation

For multiplication and division, note that powers-of-ten prefixes are significant
in unit cancellation. For instance, `mV/V` is not simplified, although `V/V` is.
Also, `N*m/J` is not simplified: there is currently no logic to decide
whether or not units on a dimensionless quantity seem "intentional" or not.
It is however possible to cancel units manually, by converting the dimensionless
quantity to the [`NoUnits`](@ref) unit. This takes into account different SI-prefixes:
```jldoctest
julia> using Unitful

julia> 1u"kN*m"/4u"J" |> NoUnits
250.0
```
