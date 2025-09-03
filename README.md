[![CI](https://github.com/JuliaPhysics/Unitful.jl/workflows/CI/badge.svg)](https://github.com/JuliaPhysics/Unitful.jl/actions?query=workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/github/JuliaPhysics/Unitful.jl/badge.svg?branch=master)](https://coveralls.io/github/JuliaPhysics/Unitful.jl?branch=master)
[![codecov.io](https://codecov.io/github/JuliaPhysics/Unitful.jl/coverage.svg?branch=master)](https://codecov.io/github/JuliaPhysics/Unitful.jl?branch=master)



# Unitful.jl

Unitful is a Julia package for physical units. We want to support not only
SI units but also any other unit system. We also want to minimize or in some
cases eliminate the run-time penalty of units. There should be facilities
for dimensional analysis. All of this should integrate easily with the usual
mathematical operations and collections that are found in Julia base.

### Documentation: [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaPhysics.github.io/Unitful.jl/stable) [![](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaPhysics.github.io/Unitful.jl/dev)


## Other packages in the Unitful family

### Units packages

- [UnitfulUS.jl](https://github.com/PainterQubits/UnitfulUS.jl): U.S. customary units. Serves as an example for how to implement a units
  package.
- [UnitfulAstro.jl](https://github.com/mweastwood/UnitfulAstro.jl): Astronomical units.
- [UnitfulAngles.jl](https://github.com/yakir12/UnitfulAngles.jl): More angular units, additional trigonometric functionalities, and clock-angle conversion.
- [UnitfulAtomic.jl](https://github.com/sostock/UnitfulAtomic.jl): Easy conversion from and to atomic units.
- [PowerSystemsUnits.jl](https://github.com/invenia/PowerSystemsUnits.jl): Common units for dealing with power systems.
- [UnitfulMoles.jl](https://github.com/rafaqz/UnitfulMoles.jl) for defining mol units of chemical elements and compounds.

### Feature additions

- [UnitfulEquivalences.jl](https://github.com/sostock/UnitfulEquivalences.jl): Enables conversion between equivalent quantities of different dimensions, e.g. between energy and wavelength of a photon.
- [UnitfulParsableString.jl](https://github.com/michikawa07/UnitfulParsableString.jl): Add a `Base.string` method that converts quantities and units to parsable strings.
- [UnitfulBuckinghamPi.jl](https://github.com/rmsrosa/UnitfulBuckinghamPi.jl): Solves for the adimensional Pi groups in a list of Unitful parameters, according to the Buckingham-Pi Theorem.
- [NaturallyUnitful.jl](https://github.com/MasonProtter/NaturallyUnitful.jl): Convert to and from natural units in physics.
- [UnitfulChainRules.jl](https://github.com/SBuercklin/UnitfulChainRules.jl): Enables use of Unitful quantities with [ChainRules.jl](https://github.com/JuliaDiff/ChainRules.jl)-compatible autodifferentiation systems.
- [DimensionfulAngles.jl](https://github.com/cmichelenstrofer/DimensionfulAngles.jl): Adds angle as a dimension. This allows dispatching on angles and derived quantities.
- [Dimensionless.jl](https://github.com/martinkosch/Dimensionless.jl): Contains tools to switch between dimensional bases, conduct dimensional analysis and solve similitude problems.
- [UnitfulRecipes.jl](https://github.com/jw3126/UnitfulRecipes.jl) (deprecated): Adds automatic labels and supports plot axes with units for [Plots.jl](https://github.com/JuliaPlots/Plots.jl). (UnitfulRecipes.jl is now included in Plots.jl.)
- [UnitfulLatexify.jl](https://github.com/gustaphe/UnitfulLatexify.jl) (deprecated): Pretty print units and quantities in LaTeX format. (This package is now an extension to Unitful, so that loading both Unitful and [Latexify.jl](https://github.com/korsbo/Latexify.jl) loads this functionality.)


## Related packages

Unitful was inspired by:

- [SIUnits.jl](https://github.com/keno/SIUnits.jl)
- [EngUnits.jl](https://github.com/dhoegh/EngUnits.jl)
- [Units.jl](https://github.com/timholy/Units.jl)
