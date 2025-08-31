# Unitful.jl changelog

## v1.24.0 (2025-07-31)

* ![Feature:](https://img.shields.io/badge/-feature-green) The alias `deg` for `°` is added ([#764](https://github.com/JuliaPhysics/Unitful.jl/pull/764)).

## v1.23.1 (2025-06-10)

* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) Fix a world-age issue with the new mechanism to preserve the floating-point precision on unit conversion ([#790](https://github.com/JuliaPhysics/Unitful.jl/issues/790)).

## v1.23.0 (2025-06-08)

* ![Feature:](https://img.shields.io/badge/-feature-green) On Julia ≥ 1.9, dimensionless quantities can now be converted to `ForwardDiff.Dual`. This is important for compatibility with the SciML ecosystem and is provided via a package extension ([#765](https://github.com/JuliaPhysics/Unitful.jl/pull/765)).
* ![Feature:](https://img.shields.io/badge/-feature-green) On Julia ≥ 1.9, `@printf` and `@sprintf` can now be used with Unitful quantities. The specified format is applied to the numeric part of the quantity and the unit is appended to that. This is provided via a package extension ([#772](https://github.com/JuliaPhysics/Unitful.jl/pull/772)).
* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) Certain unit conversions involving units that are defined using non-integer exponents no longer error ([#783](https://github.com/JuliaPhysics/Unitful.jl/pull/783)).
* ![Enhancement:](https://img.shields.io/badge/-enhancement-blue) `uconvert` now preserves the floating-point precision of quantities in a non-breaking way ([#782](https://github.com/JuliaPhysics/Unitful.jl/pull/782)).

## v1.22.1 (2025-05-13)

* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) The behaviour to preserve the floating-point precision of quantities ([#754](https://github.com/JuliaPhysics/Unitful.jl/pull/754), added in v1.22.0) is reverted because it is not compatible with [IntervalArithmetic.jl](https://github.com/JuliaIntervals/IntervalArithmetic.jl) (see [#758](https://github.com/JuliaPhysics/Unitful.jl/issues/758)). The feature will be added in a non-breaking way in a future release.

## v1.22.0 (2025-01-02)

* ![Feature:](https://img.shields.io/badge/-feature-green) `Base.big` can now be used with quantities ([#755](https://github.com/JuliaPhysics/Unitful.jl/pull/755)).
* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) Using `Base.convert` to convert to a unitless quantity no longer errors ([#724](https://github.com/JuliaPhysics/Unitful.jl/pull/724)).
* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) Using `Base.convert` to convert to a mixed logarithmic quantity no longer returns wrong results. In cases that returned a result even though it was unknown whether the quantity was a power or root-power quantity, an error is thrown instead ([#724](https://github.com/JuliaPhysics/Unitful.jl/pull/724)).
* ![Enhancement:](https://img.shields.io/badge/-enhancement-blue) `uconvert` now preserves the floating-point precision of quantities ([#754](https://github.com/JuliaPhysics/Unitful.jl/pull/754)).
* ![Enhancement:](https://img.shields.io/badge/-enhancement-blue) When printing arrays, quantities are now aligned at the decimal point just like unitless numbers ([#752](https://github.com/JuliaPhysics/Unitful.jl/pull/752)).

## v1.21.1 (2024-11-29)

* ![Enhancement:](https://img.shields.io/badge/-enhancement-blue) `Base.cis` now returns more accurate results for arguments in degrees. This unfortunately is slower. If you prioritize speed over precision you can convert to `NoUnits` before calling `cis` or use `@fastmath` ([#745](https://github.com/JuliaPhysics/Unitful.jl/pull/745)).
* ![Enhancement:](https://img.shields.io/badge/-enhancement-blue) Trigonometric functions now return more accurate results for arguments in degrees when using `BigFloat` precision and `@fastmath` ([#750](https://github.com/JuliaPhysics/Unitful.jl/pull/750)).
* ![Enhancement:](https://img.shields.io/badge/-enhancement-blue) Performance of trigonometric functions with `@fastmath` is improved for some argument types ([#750](https://github.com/JuliaPhysics/Unitful.jl/pull/750)).
* The documentation now contains a list of all units and constants defined in this package ([#729](https://github.com/JuliaPhysics/Unitful.jl/pull/729)).

## v1.21.0 (2024-07-19)

* ![Feature:](https://img.shields.io/badge/-feature-green) Arithmetic between `Dates.TimeType` and `Unitful.Time` is added, e.g., `Dates.now() + 1u"hr"` now works ([#731](https://github.com/JuliaPhysics/Unitful.jl/pull/731)).

## v1.20.0 (2024-05-17)

* ![Feature:](https://img.shields.io/badge/-feature-green) `isapprox` with arrays of quantities now supports the `nans` keyword argument ([#719](https://github.com/JuliaPhysics/Unitful.jl/pull/719)).
* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) `isapprox` with arrays of quantities now calculates the default `rtol` correctly, i.e., `rtol` defaults to zero if a positive `atol` is specified, like in the scalar or unitless case ([#719](https://github.com/JuliaPhysics/Unitful.jl/pull/719)).
* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) `isapprox` with arrays of quantities now checks whether `norm(x-y) ≤ max(atol, rtol*max(norm(x), norm(y)))`, like in the scalar or unitless case, instead of `norm(x-y) ≤ atol + rtol*max(norm(x),
  norm(y))` ([#719](https://github.com/JuliaPhysics/Unitful.jl/pull/719)).

## v1.19.1 (2024-05-13)

* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) Broadcasting `upreferred`, `ustrip`, or a unit (when used as a conversion function) over ranges now works correctly again ([#711](https://github.com/JuliaPhysics/Unitful.jl/pull/711), [#715](https://github.com/JuliaPhysics/Unitful.jl/pull/715)).
* ![Enhancement:](https://img.shields.io/badge/-enhancement-blue) Broadcasting `upreferred`, `ustrip`, or a unit (when used as a conversion function) over a `StepRange` now returns a `StepRangeLen` when the conversion results in floating-point numbers ([#715](https://github.com/JuliaPhysics/Unitful.jl/pull/715)).

## v1.19.0 (2023-11-29)

* ![Feature:](https://img.shields.io/badge/-feature-green) The dimensionless units parts per cent mille (`pcm`, 10^-5), parts per million (`ppm`, 10^-6), parts per billion (`ppb`, 10^-9), parts per trillion (`ppt`, 10^-12), and parts per quadrillion (`ppq`, 10^-15) are added ([#699](https://github.com/JuliaPhysics/Unitful.jl/pull/699)).

## v1.18.0 (2023-11-13)

* ![Feature:](https://img.shields.io/badge/-feature-green) The two-argument versions of `nextfloat` and `prefloat` now allow quantities as their first argument ([#692](https://github.com/JuliaPhysics/Unitful.jl/pull/692)).

## v1.17.0 (2023-08-24)

* ![Feature:](https://img.shields.io/badge/-feature-green) The standard atmosphere (`atm`) now accepts SI prefixes, e.g., `μatm` is defined ([#664](https://github.com/JuliaPhysics/Unitful.jl/pull/664)).

## v1.16.3 (2023-08-14)

* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) Calling `min` and `max` with quantities of different units can no longer return wrong results due to floating-point overflow in the unit conversion ([#675](https://github.com/JuliaPhysics/Unitful.jl/pull/675)).
* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) `min` and `max` now handle quantities with `NaN` values correctly ([#675](https://github.com/JuliaPhysics/Unitful.jl/pull/675)).
* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) `Base.hastypemax` is now correctly implemented for quantity types ([#674](https://github.com/JuliaPhysics/Unitful.jl/pull/674)).

## v1.16.2 (2023-08-05)

* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) The conversion factors between units can no longer be wrongly calculated as `NaN`, `Inf`, or `0` (which could happen, e.g., in the case of large exponents). The conversion factor is now calculated correctly in more cases, and an error is thrown if it cannot be calculated due to floating-point over- or underflow ([#648](https://github.com/JuliaPhysics/Unitful.jl/pull/648)).

## v1.16.1 (2023-08-02)

* ![Enhancement:](https://img.shields.io/badge/-enhancement-blue) Replaced occurrences of single-argument `@doc` for duplicating docstrings, which could lead to errors when creating a Docker image with Julia 1.9 and Unitful ([#671](https://github.com/JuliaPhysics/Unitful.jl/pull/671)).

## v1.16.0 (2023-08-01)

* ![Feature:](https://img.shields.io/badge/-feature-green) The derived dimension `MolarMass` (`𝐌/𝐍`) is added ([#663](https://github.com/JuliaPhysics/Unitful.jl/pull/663)).
* ![Feature:](https://img.shields.io/badge/-feature-green) Dimensionless quantities now support the `tanpi` function added in Julia 1.10 ([#620](https://github.com/JuliaPhysics/Unitful.jl/pull/620)).

## v1.15.0 (2023-07-05)

* ![Feature:](https://img.shields.io/badge/-feature-green) Support for [InverseFunctions.jl](https://github.com/JuliaMath/InverseFunctions.jl) is extended to all supported Julia versions. On Julia < 1.9, InverseFunctions.jl is added as a regular dependency ([#652](https://github.com/JuliaPhysics/Unitful.jl/pull/652)).
* ![Enhancement:](https://img.shields.io/badge/-enhancement-blue) On Julia ≥ 1.9, [ConstructionBase.jl](https://github.com/JuliaObjects/ConstructionBase.jl) is now a weak dependency. On older versions, it is still a regular dependency. ([#658](https://github.com/JuliaPhysics/Unitful.jl/pull/658)).

## v1.14.0 (2023-05-11)

* ![Feature:](https://img.shields.io/badge/-feature-green) On Julia ≥ 1.9, [InverseFunctions.jl](https://github.com/JuliaMath/InverseFunctions.jl) can be used to get the inverse function of `Base.Fix1(ustrip, u::Units)` ([#622](https://github.com/JuliaPhysics/Unitful.jl/pull/622)).
* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) `<=` now works correctly for `AbstractQuantity{T}` when `T` is a type for which `<=(x::T,y::T)` is different than `x < y || x == y` ([#646](https://github.com/JuliaPhysics/Unitful.jl/pull/646)).

## v1.13.1 (2023-04-15)

* ![Maintenance:](https://img.shields.io/badge/-maintenance-grey) Adapt test suite for Julia 1.9 ([#643](https://github.com/JuliaPhysics/Unitful.jl/pull/643)).

## v1.13.0 (2023-04-11)

* ![Feature:](https://img.shields.io/badge/-feature-green) `Base.sleep` now accepts quantities of time as argument ([#628](https://github.com/JuliaPhysics/Unitful.jl/pull/628)).
* ![Feature:](https://img.shields.io/badge/-feature-green) `Base.copysign` and `Base.flipsign` can now be called with a plain number as first argument and a quantity as second argument ([#612](https://github.com/JuliaPhysics/Unitful.jl/pull/612)).
* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) All known method ambiguities of the package are resolved ([#606](https://github.com/JuliaPhysics/Unitful.jl/pull/606), [#626](https://github.com/JuliaPhysics/Unitful.jl/pull/626)).
* The package now has a logo. It was created by Leandro Martínez and shows the International Prototype of the Kilogram ([#567](https://github.com/JuliaPhysics/Unitful.jl/pull/567), [#634](https://github.com/JuliaPhysics/Unitful.jl/pull/634)).

## v1.12.4 (2023-02-27)

* ![Maintenance:](https://img.shields.io/badge/-maintenance-grey) `@fastmath` with quantities now uses functions from `Base.FastMath` instead of intrinsic functions, because the latter may be removed at any time ([#617](https://github.com/JuliaPhysics/Unitful.jl/pull/617)).

## v1.12.3 (2023-02-10)

* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) Multiplication is no longer assumed to be commutative, which is wrong for, e.g., quaternions ([#608](https://github.com/JuliaPhysics/Unitful.jl/pull/608)).
* ![Maintenance:](https://img.shields.io/badge/-maintenance-grey) Adapt the documentation on extending Unitful for Julia ≥ 1.9 ([#600](https://github.com/JuliaPhysics/Unitful.jl/pull/600)).

## v1.12.2 (2022-11-30)

* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) Broadcasting `upreferred` over floating-point ranges now works again ([#577](https://github.com/JuliaPhysics/Unitful.jl/pull/577)).

## v1.12.1 (2022-11-18)

* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) Fixed `istriu`/`istril` for affine quantities ([#572](https://github.com/JuliaPhysics/Unitful.jl/pull/572)).

## v1.12.0 (2022-09-17)

* ![Feature:](https://img.shields.io/badge/-feature-green) Dimensionless quantities now support `cispi`, `sincospi`, and `modf` ([#533](https://github.com/JuliaPhysics/Unitful.jl/pull/533), [#539](https://github.com/JuliaPhysics/Unitful.jl/pull/539)).
* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) Ranges of affine quantities are now printed correctly ([#551](https://github.com/JuliaPhysics/Unitful.jl/pull/551)).
* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) The non-existent functions `convertr` and `convertrp` are no longer exported ([#530](https://github.com/JuliaPhysics/Unitful.jl/pull/530)).

## v1.11.0 (2022-02-10)

* ![Feature:](https://img.shields.io/badge/-feature-green) `Base.zero` now works on heterogeneous arrays of quantities, e.g., `zero([1m, 1s]) == [0m, 0s]` ([#533](https://github.com/JuliaPhysics/Unitful.jl/pull/533), [#516](https://github.com/JuliaPhysics/Unitful.jl/pull/516)).
* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) `StepRangeLen`s of complex-valued quantities are now printed correctly ([#513](https://github.com/JuliaPhysics/Unitful.jl/pull/513)).
* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) Method ambiguities of `Base._range` are resolved ([#514](https://github.com/JuliaPhysics/Unitful.jl/pull/514)).
* ![Maintenance:](https://img.shields.io/badge/-maintenance-grey) Updated `range` implementation for Julia ≥ 1.8 ([#514](https://github.com/JuliaPhysics/Unitful.jl/pull/514)).

## v1.10.1 (2022-01-03)

* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) Fixed `isapprox` for arrays of complex-valued quantities ([#468](https://github.com/JuliaPhysics/Unitful.jl/pull/468)).

## v1.10.0 (2021-12-27)

* ![Feature:](https://img.shields.io/badge/-feature-green) Dimensions and units can now be documented by adding a docstring before the `@dimension`, `@refunit`, `@unit`, and `@affineunit` macro calls. The `@dimension`, `@derived_dimension`, `@refunit`, and `@unit` macros have an optional boolean argument `autodocs` to add autogenerated docstrings to some objects generated by these macros. All dimensions, units and constants defined in this package now have docstrings ([#476](https://github.com/JuliaPhysics/Unitful.jl/pull/476)).
* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) Calling `preferunits` with non-pure units (e.g., `preferunits(C/ms)`) no longer results in wrong behavior ([#478](https://github.com/JuliaPhysics/Unitful.jl/pull/478)).
* ![Enhancement:](https://img.shields.io/badge/-enhancement-blue) Fixed some invalidations to improve compile times ([#509](https://github.com/JuliaPhysics/Unitful.jl/pull/509)).
* ![Enhancement:](https://img.shields.io/badge/-enhancement-blue) Broadcasting `ustrip`, `upreferred`, and `*` over a range now returns another range instead of a `Vector` ([#501](https://github.com/JuliaPhysics/Unitful.jl/pull/501), [#503](https://github.com/JuliaPhysics/Unitful.jl/pull/503)).
* ![Enhancement:](https://img.shields.io/badge/-enhancement-blue) `LinearAlgebra.norm` now returns a floating-point quantity, which matches the behavior for `Base` numbers ([#500](https://github.com/JuliaPhysics/Unitful.jl/pull/500)).

## v1.9.2 (2021-11-12)

* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) The functions `Unitful.cos_fast`, `Unitful.sin_fast`, and `Unitful.tan_fast` are removed. Due to an implementation error, they always threw a `MethodError`, so removing them is not breaking. This fixes a warning during precompilation ([#497](https://github.com/JuliaPhysics/Unitful.jl/pull/497)).

## v1.9.1 (2021-10-27)

* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) Multiplying a `StepRangeLen` by `Units` now preserves the floating-point precision ([#485](https://github.com/JuliaPhysics/Unitful.jl/pull/485)).
* ![Enhancement:](https://img.shields.io/badge/-enhancement-blue) Make `^(::AbstractQuantity, ::Rational)` inferrable on Julia ≥ 1.8 ([#487](https://github.com/JuliaPhysics/Unitful.jl/pull/487)).
* ![Maintenance:](https://img.shields.io/badge/-maintenance-grey) Updated multiplication of range and quantity for Julia ≥ 1.8 compatibility ([#489](https://github.com/JuliaPhysics/Unitful.jl/pull/489), [#495](https://github.com/JuliaPhysics/Unitful.jl/pull/495)).

## v1.9.0 (2021-07-16)

* ![Feature:](https://img.shields.io/badge/-feature-green) `deg2rad` and `rad2deg` can now be used to convert between `°` and `rad` ([#459](https://github.com/JuliaPhysics/Unitful.jl/pull/459)).

## v1.8.0 (2021-05-31)

* ![Feature:](https://img.shields.io/badge/-feature-green) The `IOContext` property `:fancy_exponent` can be used to control the printing of exponents in units (i.e., `m²` or `m^2`). Previously, this could only be done by setting the environment variable `UNITFUL_FANCY_EXPONENTS`. The `:fancy_exponent` property overrides the environment variable ([#446](https://github.com/JuliaPhysics/Unitful.jl/pull/446)).

## v1.7.0 (2021-04-02)

* ![Feature:](https://img.shields.io/badge/-feature-green) The functions `dimension`, `unit`, `absoluteunit`, `upreferred`, and `numtype` now support `AbstractQuantity` (instead of just `Quantity`) arguments ([#431](https://github.com/JuliaPhysics/Unitful.jl/pull/431)).
* ![Feature:](https://img.shields.io/badge/-feature-green) Support for conversion between `Unitful.Time` and `Dates.FixedPeriod` types is added ([#331](https://github.com/JuliaPhysics/Unitful.jl/pull/331)).

## v1.6.0 (2021-02-14)

* ![Feature:](https://img.shields.io/badge/-feature-green) Support for the `Base.unordered` function is added ([#406](https://github.com/JuliaPhysics/Unitful.jl/pull/406)).
* ![Feature:](https://img.shields.io/badge/-feature-green) The CGS units Gauss (`Gauss`), Oersted (`Oe`), and Maxwell (`Mx`) are added ([#397](https://github.com/JuliaPhysics/Unitful.jl/pull/397)).
* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) Removed a wrong use of `@eval` that broke precompilation ([#417](https://github.com/JuliaPhysics/Unitful.jl/pull/417)).
* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) The traits `Base.ArithmeticStyle` and `Base.OrderStyle` are now implemented correctly to support number types that are not defined in `Base` ([#407](https://github.com/JuliaPhysics/Unitful.jl/pull/407)).
* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) `==` and `isequal` now work correctly for `Gain`s and `Level`s with bignums ([#404](https://github.com/JuliaPhysics/Unitful.jl/pull/404)).
* ![Enhancement:](https://img.shields.io/badge/-enhancement-blue) `range(start; step, length)` now always creates a functioning range when `start` and `step` have different units ([#411](https://github.com/JuliaPhysics/Unitful.jl/pull/411)).
* ![Enhancement:](https://img.shields.io/badge/-enhancement-blue) It is no longer possible to create a `Level` with non-real value or reference quantity ([#400](https://github.com/JuliaPhysics/Unitful.jl/pull/400), [#421](https://github.com/JuliaPhysics/Unitful.jl/pull/421)).
* ![Enhancement:](https://img.shields.io/badge/-enhancement-blue) Macro hygiene is improved ([#390](https://github.com/JuliaPhysics/Unitful.jl/pull/390)).

## v1.5.0 (2020-10-21)

* ![Feature:](https://img.shields.io/badge/-feature-green) Dimensionless quantities now support inverse and hyperbolic trig functions ([#387](https://github.com/JuliaPhysics/Unitful.jl/pull/387)).

## v1.4.1 (2020-09-17)

* ![Maintenance:](https://img.shields.io/badge/-maintenance-grey) Adapt test suite to Julia ≥ 1.6 type parameter printing ([#380](https://github.com/JuliaPhysics/Unitful.jl/pull/380)).

## v1.4.0 (2020-08-11)

* ![Feature:](https://img.shields.io/badge/-feature-green) It is now possible to divide an array by units ([#369](https://github.com/JuliaPhysics/Unitful.jl/pull/369)).
* ![Enhancement:](https://img.shields.io/badge/-enhancement-blue) Complex and mixed quantities are now printed with brackets ([#366](https://github.com/JuliaPhysics/Unitful.jl/pull/366)).

## v1.3.0 (2020-06-26)

* ![Feature:](https://img.shields.io/badge/-feature-green) `isless` is now defined for logarithmic quantities ([#315](https://github.com/JuliaPhysics/Unitful.jl/pull/315)).
* ![Enhancement:](https://img.shields.io/badge/-enhancement-blue) Calling `div`, `rem`, etc. with affine quantities now errors ([#354](https://github.com/JuliaPhysics/Unitful.jl/pull/354)).
* ![Enhancement:](https://img.shields.io/badge/-enhancement-blue) Custom printing of types was removed ([#322](https://github.com/JuliaPhysics/Unitful.jl/pull/322)).

## v1.2.1 (2020-05-26)

* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) Fix an error when converting units with fractional power ([#335](https://github.com/JuliaPhysics/Unitful.jl/pull/335)).

## v1.2.0 (2020-05-10)

* ![Feature:](https://img.shields.io/badge/-feature-green) The unit `Year` now allows SI prefixes ([#320](https://github.com/JuliaPhysics/Unitful.jl/pull/320)).
* ![Enhancement:](https://img.shields.io/badge/-enhancement-blue) Unit conversions can now return integer-valued quantities if the conversion factor is whole ([#323](https://github.com/JuliaPhysics/Unitful.jl/pull/323)).

## v1.1.0 (2020-04-09)

* ![Feature:](https://img.shields.io/badge/-feature-green) `div`, `fld`, `cld` now allow arguments of different dimensions as long as one of them is a plain number (i.e., not an `AbstractQuantity`), e.g., `div(10m, 3) == 3m` and `cld(10, 3m) == 4/m` ([#317](https://github.com/JuliaPhysics/Unitful.jl/pull/317)).
* ![Feature:](https://img.shields.io/badge/-feature-green) Unicode superscript can now be used to to display powers in units and dimensions (e.g., `m²` instead of `m^2`). The `UNITFUL_FANCY_EXPONENTS` environment variable can be used to control whether unicode powers are used or not ([#297](https://github.com/JuliaPhysics/Unitful.jl/pull/297)).
* ![Feature:](https://img.shields.io/badge/-feature-green) The unit `Year` (`yr`) is defined, equal to 365.25 days ([#288](https://github.com/JuliaPhysics/Unitful.jl/pull/288)).
* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) `round` with the `digits`/`sigdigits` keyword now works correctly for quantities that are not based on floating-point numbers. It returns a float-based quantity in those cases ([#308](https://github.com/JuliaPhysics/Unitful.jl/pull/308)).

## v1.0.0 (2020-01-27)

* ![Feature:](https://img.shields.io/badge/-feature-green) The `uparse` function can be used to parse units and quantities from a string ([#298](https://github.com/JuliaPhysics/Unitful.jl/pull/298)).
* ![Feature:](https://img.shields.io/badge/-feature-green) The constructors `Float16`, `Float32`, `Float64`, and `BigFloat` can be used to convert a quantity to one based on the specified floating-point type, e.g., `Float64(1m) === 1.0m`. The `float` function can be used to convert a quantity to an appropriate floating-point type ([#296](https://github.com/JuliaPhysics/Unitful.jl/pull/296)).
* ![Feature:](https://img.shields.io/badge/-feature-green) The unit `Pertenthousand` (`‱`) is added ([#294](https://github.com/JuliaPhysics/Unitful.jl/pull/294)).
* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) Calling the two-argument `atan` with quantities that have the same numeric type and dimension but different units no longer errors ([#293](https://github.com/JuliaPhysics/Unitful.jl/pull/293)).

## v0.18.0 (2019-11-27)

* ![Feature:](https://img.shields.io/badge/-feature-green) `Quantity` types now support the `constructorof` function from the [ConstructionBase.jl](https://github.com/JuliaObjects/ConstructionBase.jl) package ([#280](https://github.com/JuliaPhysics/Unitful.jl/pull/280)).
* ![Feature:](https://img.shields.io/badge/-feature-green) Using units as conversion functions now supports `missing` ([#278](https://github.com/JuliaPhysics/Unitful.jl/pull/278)).
* ![Feature:](https://img.shields.io/badge/-feature-green) The unit `Angstrom` (`Å` or `angstrom`) is added ([#271](https://github.com/JuliaPhysics/Unitful.jl/pull/271)).

## v0.17.0 (2019-09-08)

* ![BREAKING:](https://img.shields.io/badge/-BREAKING-red) The unit `rps` (revolutions per second) is now equal to `2π*rad/s` instead of `1/s` and the unit `rpm` (revolutions per minute) is now equal to `2π*rad/minute` instead of `1/minute` ([#268](https://github.com/JuliaPhysics/Unitful.jl/pull/268)).
* ![Feature:](https://img.shields.io/badge/-feature-green) The derived dimensions `MassFlow` (`𝐌/𝐓`), `MolarFlow` (`𝐍/𝐓`), and `VolumeFlow` (`𝐋^3/𝐓`) are added ([#269](https://github.com/JuliaPhysics/Unitful.jl/pull/269)).
* ![Feature:](https://img.shields.io/badge/-feature-green) The dimensions power density (`𝐌 𝐋^-1 𝐓^-3`) and work (`𝐋^2 𝐌 𝐓^-2`) are marked as power-like for use with logarithmic quantities ([#267](https://github.com/JuliaPhysics/Unitful.jl/pull/267)).
* ![Feature:](https://img.shields.io/badge/-feature-green) `zero(::Type{<:AbstractQuantity{T,D}}) where {T,D}` can be used to get an additive identity with numeric type `T` and dimension `D` ([#266](https://github.com/JuliaPhysics/Unitful.jl/pull/266)).
* ![Feature:](https://img.shields.io/badge/-feature-green) The unit `Molar` (`M`) is added ([#258](https://github.com/JuliaPhysics/Unitful.jl/pull/258)).
* ![Feature:](https://img.shields.io/badge/-feature-green) `Unitful.register` now extends `Unitful.basefactors`, so packages that define units don’t have to do it themselves ([#251](https://github.com/JuliaPhysics/Unitful.jl/pull/251)).
* ![Enhancement:](https://img.shields.io/badge/-enhancement-blue) Ranges of quantities are now printed in a more concise way ([#256](https://github.com/JuliaPhysics/Unitful.jl/pull/256)).
* ![Enhancement:](https://img.shields.io/badge/-enhancement-blue) Angular degrees are now printed without a space between the number and unit, in compliance with the SI standard ([#255](https://github.com/JuliaPhysics/Unitful.jl/pull/255)).
* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) `zero` now errors if the dimension of its argument is unspecified ([#266](https://github.com/JuliaPhysics/Unitful.jl/pull/266)).
* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) `Unitful.promote_to_derived` works again ([#252](https://github.com/JuliaPhysics/Unitful.jl/pull/252)).

## v0.16.0 (2019-07-01)

* ![BREAKING:](https://img.shields.io/badge/-BREAKING-red) The physical constants are updated to the CODATA 2018 recommended values ([#235](https://github.com/JuliaPhysics/Unitful.jl/pull/235)).
* ![Feature:](https://img.shields.io/badge/-feature-green) On Julia v1, the rounding functions `round`, `ceil`, `floor`, and `trunc` now accept all keyword arguments that are supported for plain numbers. In addition, the first argument to these functions can be a unit instead of a type ([#246](https://github.com/JuliaPhysics/Unitful.jl/pull/246), [#249](https://github.com/JuliaPhysics/Unitful.jl/pull/249), [#250](https://github.com/JuliaPhysics/Unitful.jl/pull/250)).
* ![Feature:](https://img.shields.io/badge/-feature-green) The functions `Base.complex`, `Base.reim`, and `Base.widen` can now be called with unitful quantities ([#227](https://github.com/JuliaPhysics/Unitful.jl/pull/227)).
* ![Feature:](https://img.shields.io/badge/-feature-green) The function `upreferred` now supports `missing` ([#224](https://github.com/JuliaPhysics/Unitful.jl/pull/224)).
* ![Feature:](https://img.shields.io/badge/-feature-green) Two-argument and three-argument `ustrip` now support dimensionless quantities and `missing` ([#212](https://github.com/JuliaPhysics/Unitful.jl/pull/212)).
* ![Enhancement:](https://img.shields.io/badge/-enhancement-blue) Better support for number types that customize their `MIME"text/plain"` printing ([#213](https://github.com/JuliaPhysics/Unitful.jl/pull/213)).
* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) Ranges which use `Base.TwicePrecision` internally now work correctly ([#245](https://github.com/JuliaPhysics/Unitful.jl/pull/245)).
* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) Fixed some issues around use of `@generated` functions that could lead to world-age errors or wrong behavior ([#233](https://github.com/JuliaPhysics/Unitful.jl/pull/233), [#243](https://github.com/JuliaPhysics/Unitful.jl/pull/243)).

## v0.15.0 (2019-03-05)

* ![Feature:](https://img.shields.io/badge/-feature-green) The functions `uconvert`, `ustrip`, `unit`, and `dimension` as well as arithmetic with units now support `missing` ([#208](https://github.com/JuliaPhysics/Unitful.jl/pull/208)).
* ![Feature:](https://img.shields.io/badge/-feature-green) Two-argument `ustrip(unit, x)` and three-argument `ustrip(T, unit, x)` methods are added ([#205](https://github.com/JuliaPhysics/Unitful.jl/pull/205)).
* ![Feature:](https://img.shields.io/badge/-feature-green) The `AbstractQuantity{T,D,U}` type is defined to support defining quantity types other than `Quantity{T,D,U}` ([#204](https://github.com/JuliaPhysics/Unitful.jl/pull/204)).
* ![Feature:](https://img.shields.io/badge/-feature-green) The derived dimensions `Molarity` (`𝐍/𝐋^3`) and `Molality` (`𝐍/𝐌`) are added ([#198](https://github.com/JuliaPhysics/Unitful.jl/pull/198)).
* ![Bugfix:](https://img.shields.io/badge/-bugfix-purple) Multiplying a range by units now works correctly ([#206](https://github.com/JuliaPhysics/Unitful.jl/pull/206)).

## Older changes

- v0.14.0
  - Support for `digits` kwarg (#196).
  - Try to support precompilation with `u_str` macro (#201).
- v0.13.0
  - Implement affine quantities for better temperature handling (#177, #182).
  - Rename `°Ra` to `Ra` to emphasize that it is an absolute scale.
  - Fix some precompilation issues (#161).
  - Add `Velocity`, `Acceleration`, `Density` derived dimensions (#187).
  - Days display as `d` now (#184).
  - Type signature of `Quantity`s has been simplified. Helps with reading error messages (#183).
  - Support `isequal` with `NaN` quantities (#172).
- v0.12.0
  - Bug fixes.
  - Support carrier-to-noise-density ratio (C/N0) in dB-Hz.
  - Added dimensions: `DField`, `EField`, `ElectricDipoleMoment`, `ElectricQuadrupoleMoment`, `MagneticDipoleMoment`.
  - Added unit: `barn`.
  - Some documentation improvements.
- v0.11.0--v0.9.0
  - Fixes for Julia 0.7 update, primarily.
  - Some new TwicePrecision functionality for quantities.
- v0.8.0
  - Add Rydberg constant, unified atomic mass unit, mils, rpm, rps, percent, permille.
  - Introduce/rename derived dimensions: ElectricalConductivity, ElectricalResistivity,
    ElectricalConductance, ElectricalResistance.
  - Fix some Julia 0.7 deprecations.
  - This will probably be the last release that supports Julia 0.6.
- v0.7.1
  - Bug fixes, mainly.
- v0.7.0
  - Implement `mod2pi` for degrees, cleanup display of degree units.
  - Tweak implementation of `Gain` types for usability.
  - Implement `zero` and `one` for `Level` and `Gain`.
  - Add a few more cgs units.
  - Tests pass on 32-bit systems, for the first time in a long time (ever?).
- v0.6.1
  - Permit symbols that are bound to `Number`s to be used in `u_str` macro, such that
    π and other non-literal numbers can be used.
  - Add some cgs units and a few dimensions [#115](https://github.com/JuliaPhysics/Unitful.jl/pull/115).
  - Fix a comparison / promotion bug introduced in v0.6.0.
- v0.6.0
  - Restore compatibility with 0.7.0-DEV.
- v0.5.1
  - Dimensionless quantities no longer lose their units when dividing by a real number.
  - Ranges constructed via `range` or `colon` should work more reliably (e.g., 0:10°:350° works now).
- v0.5.0
  - Add `dBΩ` and `dBS` to permit working with impedances and admittances in dB. These are
    used in the Touchstone format and in microwave measurements.
  - Implement `angle` for `Quantity{<:Complex}`.
  - Implement `float` for `Gain`, `Level`.
  - Replace `fieldratio` and `rootpowerratio` with `uconvertrp`.
    - Permits unit conversion between `NoUnits` and `dB`, etc. by presuming unitless ratios
      are of root-power quantities (hence the `rp` after `uconvert`).
    - `uconvertrp` has generic fallbacks and can be used as a drop-in replacement for
      `uconvert` otherwise.
  - Likewise, replace `powerratio` with `uconvertp` for ratios of power quantities.
  - Introduce `convertrp` and `convertp`. These are like `convert` but they make
    similar assumptions about unitless ratios being of power or root-power quantities,
    respectively.
  - Implement more division operations for `Gain`s (accidental omissions)
- v0.4.0
  - Introduce logarithmic quantities (experimental!)
  - Update syntax for Julia 0.6 and reorganize code for clarity.
  - Redefine `ustrip(x::Quantity) = ustrip(x.val)`. In most cases, this is unlikely to
    affect user code. The generic fallback `ustrip(x::Number)` remains unchanged.
  - `isapprox(1.0u"m",5)` returns `false` instead of throwing a `DimensionError`,
    in keeping with the behavior of an equality check (`==`).
  - Display of some units has changed to match their symbols [#104](https://github.com/JuliaPhysics/Unitful.jl/issues/104).
  - Don't export `cd` from Unitful.DefaultSymbols in order to avoid conflicts [#102](https://github.com/JuliaPhysics/Unitful.jl/issues/102).
  - Deprecated `dimension(x::AbstractArray{T}) where T<:Number`, use broadcasting instead.
  - Deprecated `dimension(x::AbstractArray{T}) where T<:Units`, use broadcasting instead.
  - Deprecated `ustrip(A::AbstractArray{T}) where T<:Number`, use broadcasting instead.
  - Deprecated `ustrip(A::AbstractArray{T}) where T<:Quantity`, use broadcasting instead.
- v0.3.0
  - Require Julia 0.6
  - Adds overloads for `rand` and `ones` [#96](https://github.com/JuliaPhysics/Unitful.jl/issues/96).
  - Improve symbol resolution in `u_str` macro [#98](https://github.com/JuliaPhysics/Unitful.jl/pull/98).
  - More work is done inside the `u_str` macro, such that the macro returns units, dimensions,
    numbers (quantities), or tuples rather than expressions.
- v0.2.6
  - Fix and close [#52](https://github.com/JuliaPhysics/Unitful.jl/issues/52).
  - Implement `Base.rtoldefault` for Quantity types
    (needed for AxisArrays [#52](https://github.com/JuliaArrays/AxisArrays.jl/pull/52)).
- v0.2.5
  - Fix and close [#79](https://github.com/JuliaPhysics/Unitful.jl/issues/79).
  - Add support for `round(T, ::DimensionlessQuantity)` where `T <: Integer`
    (also `floor`, `ceil`, `trunc`) [#90](https://github.com/JuliaPhysics/Unitful.jl/pull/90).
- v0.2.4
  - Bug fix: avoid four-argument `promote_type`
  - Bug fix: define method for `*(::Base.TwicePrecision, ::Quantity)`
  - Bug fix: definition of Bohr magneton had `e` instead of `q`
- v0.2.3
  - Dimensionful quantities are no longer accepted for `floor`, `ceil`, `trunc`, `round`,
    `isinteger`. The choice of units can yield physically different results.
    The functions are defined for dimensionless quantities, and return unitless numbers.
    Closes [#78](https://github.com/JuliaPhysics/Unitful.jl/issues/78).
  - Added `gn`, a constant quantity for the gravitational acceleration on earth
    [#75](https://github.com/JuliaPhysics/Unitful.jl/pull/75).
  - Added `ge`, the gravitational acceleration on earth as a unit
    [#75](https://github.com/JuliaPhysics/Unitful.jl/pull/75).
  - Added `lbf`, pounds-force unit
    [#75](https://github.com/JuliaPhysics/Unitful.jl/pull/75).
- v0.2.2
  - Fixed a bug in promotion involving `ContextUnits` where the promotion context might
    not be properly retained.
- v0.2.1
  - Fixed `isapprox` bug [#74](https://github.com/JuliaPhysics/Unitful.jl/pull/74).
  - Added `DimensionlessQuantity` methods for `exp`, `exp10`, `exp2`, `expm1`, `log1p`,
    `log2` [#71](https://github.com/JuliaPhysics/Unitful.jl/pull/71).
- v0.2.0
  - `Units{N,D}` is now an abstract type. Different concrete types for units give different
   behavior under conversion and promotion. The currently implemented concrete types are:
    - `FreeUnits{N,D}`: these give the typical behavior from prior versions of Unitful.
      Units defined in Unitful.jl and reachable by the `u_str` macro are all `FreeUnits`.
    - `ContextUnits{N,D,P}`, where P is some type `FreeUnits{M,D}`: these enable
      context-specific promotion rules, e.g. if units are defined in different packages.
    - `FixedUnits{N,D}`: these inhibit automatic conversion of quantities with different units.
  - `LengthUnit`, `EnergyUnit`, etc. are renamed to `LengthUnits`, `EnergyUnits`, etc. for
    consistency (they are related more to `Units` objects than `Unit` objects). You can
    still use the old names for now, but please switch over to using `...Units` instead
    of `...Unit` in this release as the old names will be removed in a future release.
  - `c` is now a unit, to permit converting mass into `MeV/c^2`, for example. `c0` is
    still a quantity equal to the speed of light in vacuum, in units of `m/s`
    [#67](https://github.com/JuliaPhysics/Unitful.jl/issues/67).
- v0.1.5
  - Patch for Julia PR [#20889](https://github.com/JuliaLang/julia/pull/20889), which
    changes how lowering is done for exponentiation of integer literals.
  - Bug fix to enable registering Main as a module for `u_str` (fixes
    [#61](https://github.com/JuliaPhysics/Unitful.jl/issues/61)).
  - Implement readable message for `DimensionError`
    [#62](https://github.com/JuliaPhysics/Unitful.jl/pull/62).
- v0.1.4
  - Critical bug fix owing to `mod_fast` changes.
- v0.1.3
  - Fix symmetry of `==` [#56](https://github.com/JuliaPhysics/Unitful.jl/issues/56).
  - Using `@refunit` will implicitly specify the ref. unit as the default for promotion.
    This will not change behavior for most people; it just ensures promotion won't
    fail for quantities with user-defined dimensions.
  - Remove `mod_fast` in anticipation of Julia PR [#20859](https://github.com/JuliaLang/julia/pull/20859).
  - Allow tolerance args for `isapprox` [#57](https://github.com/JuliaPhysics/Unitful.jl/pull/57)
- v0.1.2
  - On Julia 0.6, exponentiation by a literal is now type stable for integers.
- v0.1.1
  - Fixed a macro hygiene issue that prevented `@dimension` and `@derived_dimension`
   from working properly if Compat was not imported in the calling namespace.
- v0.1.0
  - Julia 0.6 compatibility.
  - On Julia 0.6, exponentiation by a literal is now type stable for
    common integer powers: -3, -2, -1, 0, 1, 2, 3.
  - Added missing methods for dot operators `.<` and `.<=` (Julia 0.5, fix
    [#55](https://github.com/JuliaPhysics/Unitful.jl/issues/55)).
  - Fix [#45](https://github.com/JuliaPhysics/Unitful.jl/issues/45). Ranges should
    work as expected on Julia 0.6. On Julia 0.5, [Ranges.jl](https://github.com/JuliaArrays/Ranges.jl)
    is used to make ranges work as well as possible given limitations in Base.
  - Fix [#33](https://github.com/JuliaPhysics/Unitful.jl/issues/33),
    [#42](https://github.com/JuliaPhysics/Unitful.jl/issues/42),
    and [#50](https://github.com/JuliaPhysics/Unitful.jl/issues/50).
    `deps/Defaults.jl` is dead. Long live `deps/Defaults.jl`. To define your own
    units, dimensions, and so on, you should now put them in a module, or ideally
    a package so that others can use the definitions too. You can override default
    promotion rules immediately after loading Unitful and dependent packages; this
    will generate method overwrite warnings on Julia 0.5 but not on 0.6.
  - `@u_str` macro has been improved. It can now traverse separate unit packages,
    as well as return tuples of `Units` objects.
  - `@preferunit` has been replaced with a function `preferunits`.
  - Added some methods for `ustrip`.
  - Implement `typemin`, `typemax`, `cbrt` for `Quantity`s.
  - Added matrix inversion for `StridedMatrix{T<:Quantity}`.
  - Added `istriu`, `istril` for `AbstractMatrix{T<:Quantity}`.
  - The `Unitful.SIUnits` module has been renamed to `Unitful.DefaultSymbols`.
  - Add `lb`, `oz`, `dr`, `gr` to Unitful (international Avoirdupois mass units).
- v0.0.4
  - Be aware, breaking changes to `deps/Defaults.jl` caused by some of the following!
  - Fix [#40](https://github.com/JuliaPhysics/Unitful.jl/issues/40).
  - Fix [#30](https://github.com/JuliaPhysics/Unitful.jl/issues/30).
  - Support relevant `@fastmath` operations for `Quantity`s.
  - Implement `fma`, `atan2` for `Quantity`s.
  - Implement `cis` for dimensionless `Quantity`s.
  - Removed `DimensionedUnits` and `DimensionedQuantity` abstract types.
    They were of dubious utility, and this change shortened the promotion code
    considerably. More importantly, this change has made it possible to write
    methods like the following, without method ambiguities:
    `uconvert(e::EnergyUnit, f::Frequency) = uconvert(e, u"h"*f)`.
  - Promotion wraps usual `Number` types in dimensionless, unitless `Quantity`
    types when promoted together with dimensionful `Quantity`s.
    With `Quantity`s it is not always possible to promote to a common
    concrete type, but this way we can at least ensure that the numeric backing
    types are all promoted: (`promote(1.0u"m", 1u"N"//2, 0x08) == (1.0 m,0.5 N,8.0)`,
    where `8.0` is actually a dimensionless, unitless `Quantity`).
    The usual outer constructor for `Quantity`s (`Quantity(val::T, unit)`)
    continues to return a number of type `T` if the unit is `NoUnits`,
    since most of the time the user would prefer a `Number` type from base rather
    than a dimensionless, unitless quantity.
  - Add more units to defaults: `bar` (bar), `Torr` (torr), `atm` (atmosphere),
    `l` or `L` (liter; both symbols accepted). You will need to delete
    `deps/Defaults.jl` in the Unitful package directory to get the new units.
  - Two character encodings for `μ` in SI prefixes are now generated automatically
    (some logic moved out of defaults).
  - Moved definition of `sin`, `cos`, `tan`, `sec`, `csc`, `cot` out of
    `deps/build.jl` and into `src/Unitful.jl`.
- v0.0.3
  - Bug fix: `uconvert(°C, 0x01°C)` no longer disturbs the numeric type
  - Allow μ-prefixed units to be typed with option-m on a Mac, in addition to
    using Unicode. Previously only `μm` could be typed this way.
  - Include a `baremodule` called `SIUnits` in the factory defaults. You can
    now do `using Unitful.SIUnits` to bring all of the SI units into the calling
    namespace.
  - Added remaining SI units to the factory defaults: `sr` (steradian), `lm`
    (luminous flux), `lx` (illuminance), `Bq` (becquerel), `Gy` (gray),
    `Sv` (sievert), `kat` (katal).
  - Simplify array creation, as in `[1, 2]u"km"` [#29](https://github.com/JuliaPhysics/Unitful.jl/pull/29)
  - Support multiplying ranges by units, as in `(1:3)*mm` [#28](https://github.com/JuliaPhysics/Unitful.jl/pull/28)
  - Bug fix [#26](https://github.com/JuliaPhysics/Unitful.jl/issues/26)
  - Promoting `Quantity`s with different dimensions now returns quantities with
    the same numeric backing type, e.g. `Quantity{Float64}`. Ideally, this would
    also be true if you mixed unitless and unitful numbers during promotion, but
    that is not yet the case. See [#24](https://github.com/JuliaPhysics/Unitful.jl/issues/24)
    for motivation.
- v0.0.2
  - Bug fixes (`[1.0m, 2.0m] ./ 3` would throw a `Unitful.DimensionError()`).
    Promotion still isn't perfect, but it is hard for me to see what `@inferred`
    errors are real until https://github.com/JuliaLang/julia/issues/18465 is resolved.
  - Made units callable for unit conversion: `u"cm"(1u"m") == 100u"cm"//1`.
    Note that `Units` objects have no fields, so this is totally unambiguous.
    Moreover, we have convenient syntax for unit conversion by function chaining:
    `1u"m" |> u"cm" == 100u"cm"//1`. Note that `uconvert` will remain supported.
- v0.0.1 - Initial release
