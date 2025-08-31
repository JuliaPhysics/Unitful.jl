```@meta
DocTestSetup = quote
    using Unitful
end
```
# Unitful.jl

A Julia package for physical units. Available
[here](https://github.com/JuliaPhysics/Unitful.jl). Inspired by:

- [SIUnits.jl](https://github.com/keno/SIUnits.jl)
- [EngUnits.jl](https://github.com/dhoegh/EngUnits.jl)
- [Units.jl](https://github.com/timholy/Units.jl)

We want to support not only SI units but also any other unit system. We also
want to minimize or in some cases eliminate the run-time penalty of units.
There should be facilities for dimensional analysis. All of this should
integrate easily with the usual mathematical operations and collections
that are defined in Julia.

## Quick start

- This package requires Julia 1.0. Older versions will not be supported.
- `] add Unitful`
- `using Unitful`

Unitful aims for generality, but has some useful functionality out of the box.
- Base dimensions like length, mass, time, etc. are defined.
- Derived dimensions like volume, energy, momentum, etc. are defined.
- Base and derived SI units with their power-of-ten prefixes are defined.
- Some other common units are defined, without power-of-ten prefixes.
- Sensible default promotion behavior is specified.

Take a look at `src/pkgdefaults.jl` for a complete list. Note that some unit
abbreviations conflict with other definitions or syntax:

- `inch` is used instead of `in`, since `in` conflicts with Julia syntax
- `minute` is used instead of `min`, since `min` is a commonly used function
- `hr` is used instead of `h`, since `h` is revered as the Planck constant
- `hbar` is hectobars in the SI system, so `ħ` is used for the reduced Plank
  constant

## Important note on namespaces

Units, dimensions, and fundamental constants are not exported from Unitful.
This is to avoid proliferating symbols in your namespace unnecessarily. You can
retrieve them from Unitful in one of three ways:

1. Use the [`@u_str`](@ref) string macro.
2. Explicitly import from the `Unitful` package to bring specific symbols
   into the calling namespace.
3. `using Unitful.DefaultSymbols` will bring the following symbols into the
   calling namespace:
     - Dimensions `𝐋,𝐌,𝐓,𝐈,𝚯,𝐉,𝐍` for length, mass, time, current, temperature,
       luminosity, and amount, respectively.
     - Base and derived SI units, with SI prefixes (except for `cd`, which conflicts
       with `Base.cd`)
     - `°` (degrees)
  If you have been using the [SIUnits.jl](https://github.com/keno/SIUnits.jl)
  package, this is not unlike typing `using SIUnits.ShortUnits` with that package.

## Usage examples

```@meta
DocTestSetup = quote
    using Unitful
    °C = Unitful.°C
    °F = Unitful.°F
    Ra = Unitful.Ra
    K = Unitful.K
    μm = Unitful.μm
    m = Unitful.m
    hr = Unitful.hr
    minute = Unitful.minute
    s = Unitful.s
    F = Unitful.F
end
```

```jldoctest
julia> 1u"kg" == 1000u"g"             # Equivalence implies unit conversion
true

julia> !(1u"kg" === 1000u"g")         # ...and yet we can distinguish these...
true

julia> 1u"kg" === 1u"kg"              # ...and these are indistinguishable.
true
```

In the next examples we assume we have brought some units into our namespace,
e.g. `const m = u"m"`, etc.

```jldoctest
julia> uconvert(°C, 212°F)
100//1 °C

julia> uconvert(μm/(m*Ra), 9μm/(m*K))
5//1 μm m^-1 Ra^-1

julia> mod(1hr+3minute+5s, 24s)
17 s
```

One useful interactive function is being able to convert to preferred (in this case SI) units. 

```jldoctest
julia> upreferred(F/m)
A^2 s^4 kg^-1 m^-3
```

!!! note
    Quantities in `°C` or `⁠°F` always unit-convert under an affine transformation that takes
    their relative scales into account. To avoid ambiguities that can lead to incorrect
    results, the units `°C` and `°F` cannot be used in Unitful to represent temperature
    differences. Fortunately, `1°C - 0°C == 1K` and `1°F - 0°F == 1Ra`, so the absolute
    temperature scales Kelvin (`K`) and Rankine (`Ra`) can be used easily to represent
    temperature differences.

See `test/runtests.jl` for more usage examples.

## About the logo

The logo is a pictorial representation of the [International Prototype of the Kilogram](https://en.wikipedia.org/wiki/International_Prototype_of_the_Kilogram), which was the standard definition of one kilogram from 1889 to 2019,
when it was replaced by a definition based on the Planck constant, the speed of light, and the ground-state hyperfine transition frequency of ¹³³Cs.
