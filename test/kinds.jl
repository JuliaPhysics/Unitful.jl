# Tests for `Unitful.restrict_unit_kinds`.
#
# This file runs in its own Julia process, launched from runtests.jl. It cannot be
# `include`d like test/dates.jl is: `restrict_unit_kinds()` adds `unitkinds` methods
# globally and cannot be undone, so every later testset in the parent process would
# inherit the restriction.
#
# The testsets are deliberately left at top level rather than nested inside one outer
# `@testset`, and `restrict_unit_kinds()` is a top-level statement between them. A
# `@testset ... begin ... end` is a single top-level expression, so its whole body is
# compiled in the world age that precedes it — before the opt-in has added any
# `unitkinds` method. Since `unitkinds` returns a constant for singleton unit types, the
# kind check folds away at that point, and on Julia 1.6 the enclosing thunk is not
# recompiled once the methods appear; every "now forbidden" test then silently succeeds.
# Splitting on top-level statement boundaries advances the world age between them.

using Unitful
using Test
using Unitful: KindError, NoUnits, kindscompatible

@testset "Unit kinds: Unrestricted by default" begin
    # Nothing changes until `restrict_unit_kinds` is called.
    @test uconvert(u"percent", 1.0u"°") == 1.7453292519943295u"percent"
    @test uconvert(u"sr", 1.0u"rad") == 1.0u"sr"
    @test uconvert(NoUnits, 1.0u"°") ≈ 0.017453292519943295
    @test kindscompatible(u"rad", u"percent")
    @test kindscompatible(u"m", u"km")
    # Dimensionless addition still collapses to a bare number.
    @test 1.0u"rad" + 1.0u"°" === 1.0174532925199433
    @test 1.0u"rad" + 1.0u"percent" === 1.01
end

Unitful.restrict_unit_kinds()

@testset "Unit kinds: Conversions still permitted" begin
    @test uconvert(u"rad", 180.0u"°") ≈ 1.0π * u"rad"
    @test uconvert(u"°", 1.0u"rad") ≈ 57.29577951308232u"°"
    @test uconvert(u"sr", 1.0u"°"^2) ≈ 0.00030461741978670857u"sr"
    @test uconvert(u"°"^2, 1.0u"sr") ≈ 3282.806350011744 * u"°"^2
    @test uconvert(u"rad", 1000.0u"mrad") == 1.0u"rad"
    @test uconvert(u"sr", 1000.0u"msr") == 1.0u"sr"
    # Proportion units are left unclassified, so they remain plain numbers and
    # convert freely among themselves and with bare numbers.
    @test uconvert(u"ppm", 1.0u"percent") == 10000.0u"ppm"
    @test uconvert(u"permille", 1u"percent") == 10u"permille"
    @test uconvert(u"percent", 1u"permille") == 1//10 * u"percent"
    @test uconvert(NoUnits, 1.0u"μm/m") ≈ 1.0e-6
    @test uconvert(NoUnits, 50u"percent") == 1//2
    @test uconvert(u"percent", 0.5) == 50.0u"percent"
    @test convert(Float64, 1.0u"percent") == 0.01
    @test ustrip(NoUnits, 1.0u"percent") == 0.01
    @test (1.0u"percent" |> NoUnits) == 0.01
    # Angle over a dimensionful unit is still an angle.
    @test uconvert(u"°/s", 1.0u"rad/s") ≈ 57.29577951308232u"°/s"
end

@testset "Unit kinds: Conversions now forbidden" begin
    # Angle and solid angle differ, because solid angle is angle squared.
    @test_throws KindError uconvert(u"sr", 1.0u"rad")
    @test_throws KindError uconvert(u"rad", 1.0u"sr")
    # Angle and proportion are unrelated.
    @test_throws KindError uconvert(u"percent", 1.0u"rad")
    @test_throws KindError uconvert(u"rad", 50.0u"percent")
    @test_throws KindError uconvert(u"percent", 1.0u"sr")
    @test_throws KindError uconvert(u"percent", 1.0u"°"^2)
    # Neither converts to or from a bare number.
    @test_throws KindError uconvert(NoUnits, 1.0u"°")
    @test_throws KindError uconvert(u"rad", 1.0)
    @test_throws KindError convert(Float64, 1.0u"rad")
    @test_throws KindError convert(ComplexF64, 1.0u"rad")
end

@testset "Unit kinds: Compound units" begin
    # The kind check reads the whole unit tuple, so it applies to units whose
    # dimension is not NoDims.
    @test_throws KindError uconvert(u"percent/s", 1.0u"rad/s")
    @test_throws KindError uconvert(u"s^-1", 1.0u"rad/s")
    @test_throws KindError uconvert(u"m^2", 1.0u"sr*m^2")
    @test uconvert(u"°^2*m^2", 1.0u"sr*m^2") ≈ 3282.806350011744 * u"°^2*m^2"
end

@testset "Unit kinds: Numeric operations unaffected" begin
    # These need the numeric value of a dimensionless quantity for its own sake,
    # and go through the internal unchecked path.
    @test sin(1.0u"rad") ≈ 0.8414709848078965
    @test sin(90.0u"°") == 1.0
    @test cos(1.0u"rad") ≈ 0.5403023058681398
    @test mod2pi(7.0u"rad") ≈ 0.7168146928204135
    @test round(1.4u"rad") == 1.0
    @test isinteger(2.0u"rad")
    @test exp(1.0u"percent") ≈ 1.010050167084168
    @test deg2rad(180.0u"°") ≈ 1.0π * u"rad"
    @test rad2deg(1.0π * u"rad") ≈ 180.0u"°"
    # `ustrip` with no target unit just reads the field, so it never converts.
    @test ustrip(1.0u"°") == 1.0
    @test ustrip(u"rad", 2.0u"rad") == 2.0
end

@testset "Unit kinds: Promotion keeps the kind" begin
    # An angle must not promote to `NoUnits`, which would discard its kind; the
    # better-ranked operand is kept instead, so radians beat degrees.
    @test 1.0u"rad" + 1.0u"°" ≈ 1.0174532925199433u"rad"
    @test 1.0u"°" + 1.0u"rad" ≈ 1.0174532925199433u"rad"
    @test 1.0u"sr" + 1.0u"°"^2 ≈ 1.0003046174197867u"sr"
    @test 1.0u"°"^2 + 1.0u"sr" ≈ 1.0003046174197867u"sr"
    @test 1.0u"mrad" + 1.0u"rad" ≈ 1.001u"rad"      # unprefixed wins the tie
    @test 1.0u"rad" + 1.0u"rad" === 2.0u"rad"
    @test eltype([1.0u"rad", 1.0u"°"]) === typeof(1.0u"rad")

    # The choice must not depend on the order of the operands.
    for (a, b) in ((u"rad", u"°"), (u"sr", u"°"^2), (u"mrad", u"rad"), (u"m", u"cm"))
        A, B = typeof(1.0 * a), typeof(1.0 * b)
        @test promote_type(A, B) === promote_type(B, A)
    end

    # Mixing kinds in arithmetic is rejected, and says why.
    @test_throws KindError 1.0u"rad" + 1.0u"percent"
    @test_throws KindError 1.0u"rad" + 1.0u"sr"

    # Units without a kind promote exactly as they always did — proportions still
    # collapse to a bare number, and still mix with bare numbers.
    @test 1.0u"percent" + 1.0u"ppm" === 0.010001
    @test 1.0u"percent" + 1.0u"permille" === 0.011
    @test 1.0u"permille" + 1.0u"percent" === 0.011
    @test 1.0u"percent" + 0.5 === 0.51
    @test 0.5 + 1.0u"percent" === 0.51
    @test promote(1.0u"percent", 1.0u"permille") === (0.01, 0.001)
    @test [1.0u"percent", 1.0u"permille"] == [0.01, 0.001]
    @test 1.0u"percent" == 0.01
    @test !(1.0u"percent" < 1.0u"permille")
    @test 1.0u"m" + 1.0u"cm" === 1.01u"m"
    @test 1.0u"J" + 1.0u"kg*m^2/s^2" === 2.0u"kg*m^2/s^2"
end

@testset "Unit kinds: Dimensionful conversion unaffected" begin
    @test uconvert(u"km", 1.0u"m") == 0.001u"km"
    @test uconvert(u"s", 1.0u"hr") == 3600.0u"s"
    @test uconvert(u"ft", 1u"inch") == 1//12 * u"ft"
    @test uconvert(u"K", 20.0u"°C") == 293.15u"K"      # affine
    @test uconvert(u"mW", 20.0u"dBm") ≈ 100.0u"mW"     # logarithmic
end

@testset "Unit kinds: isapprox reports mismatch as false, not an error" begin
    # Consistent with how a dimension mismatch is already reported here.
    @test !isapprox([1.0u"°"], [0.017453292519943295])
    @test isapprox([1.0u"percent"], [0.01])
end

@testset "Unit kinds: KindError is distinct from DimensionError" begin
    err = try; uconvert(u"percent", 1.0u"rad"); catch e; e; end
    @test err isa KindError
    @test !(err isa Unitful.DimensionError)
    @test occursin("not compatible in kind", sprint(showerror, err))
end
