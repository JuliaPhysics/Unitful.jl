# Tests for `Unitful.restrict_unit_kinds`.
#
# This file runs in its own Julia process, launched from runtests.jl. It cannot be
# `include`d like test/dates.jl is: `restrict_unit_kinds()` adds `unitkinds` methods
# globally and cannot be undone, so every later testset in the parent process would
# inherit the restriction.

using Unitful
using Test
using Unitful: KindError, NoUnits, kindscompatible

@testset "Unit kinds" begin
    @testset "> Unrestricted by default" begin
        # Nothing changes until `restrict_unit_kinds` is called.
        @test uconvert(u"percent", 1.0u"°") == 1.7453292519943295u"percent"
        @test uconvert(u"sr", 1.0u"rad") == 1.0u"sr"
        @test uconvert(NoUnits, 1.0u"°") ≈ 0.017453292519943295
        @test kindscompatible(u"rad", u"percent")
        @test kindscompatible(u"m", u"km")
    end

    Unitful.restrict_unit_kinds()

    @testset "> Conversions still permitted" begin
        @test uconvert(u"rad", 180.0u"°") ≈ 1.0π * u"rad"
        @test uconvert(u"°", 1.0u"rad") ≈ 57.29577951308232u"°"
        @test uconvert(u"sr", 1.0u"°"^2) ≈ 0.00030461741978670857u"sr"
        @test uconvert(u"°"^2, 1.0u"sr") ≈ 3282.806350011744 * u"°"^2
        @test uconvert(u"rad", 1000.0u"mrad") == 1.0u"rad"
        @test uconvert(u"sr", 1000.0u"msr") == 1.0u"sr"
        # Proportion units are left unclassified, so they remain plain numbers.
        @test uconvert(u"ppm", 1.0u"percent") == 10000.0u"ppm"
        @test uconvert(NoUnits, 1.0u"μm/m") ≈ 1.0e-6
        @test uconvert(NoUnits, 50.0u"percent") == 0.5
        @test uconvert(u"percent", 0.5) == 50.0u"percent"
        # Angle over a dimensionful unit is still an angle.
        @test uconvert(u"°/s", 1.0u"rad/s") ≈ 57.29577951308232u"°/s"
    end

    @testset "> Conversions now forbidden" begin
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

    @testset "> Compound units" begin
        # The kind check reads the whole unit tuple, so it applies to units whose
        # dimension is not NoDims.
        @test_throws KindError uconvert(u"percent/s", 1.0u"rad/s")
        @test_throws KindError uconvert(u"s^-1", 1.0u"rad/s")
        @test_throws KindError uconvert(u"m^2", 1.0u"sr*m^2")
        @test uconvert(u"°^2*m^2", 1.0u"sr*m^2") ≈ 3282.806350011744 * u"°^2*m^2"
    end

    @testset "> Numeric operations unaffected" begin
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

    @testset "> Dimensionful conversion unaffected" begin
        @test uconvert(u"km", 1.0u"m") == 0.001u"km"
        @test uconvert(u"s", 1.0u"hr") == 3600.0u"s"
        @test uconvert(u"ft", 1u"inch") == 1//12 * u"ft"
        @test uconvert(u"K", 20.0u"°C") == 293.15u"K"      # affine
        @test uconvert(u"mW", 20.0u"dBm") ≈ 100.0u"mW"     # logarithmic
    end

    @testset "> isapprox reports mismatch as false, not an error" begin
        # Consistent with how a dimension mismatch is already reported here.
        @test !isapprox([1.0u"°"], [0.017453292519943295])
        @test isapprox([1.0u"percent"], [0.01])
    end

    @testset "> KindError is distinct from DimensionError" begin
        err = try; uconvert(u"percent", 1.0u"rad"); catch e; e; end
        @test err isa KindError
        @test !(err isa Unitful.DimensionError)
        @test occursin("not compatible in kind", sprint(showerror, err))
    end
end
