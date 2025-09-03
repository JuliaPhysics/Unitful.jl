@testset "Dates stdlib" begin
    @testset "> dimension, numtype, unit" begin
        for (T,u) = ((Nanosecond, u"ns"), (Microsecond, u"μs"), (Millisecond, u"ms"),
                     (Second, u"s"), (Minute, u"minute"), (Hour, u"hr"), (Day, u"d"),
                     (Week, u"wk"))
            @test dimension(T) === dimension(T(1)) === 𝐓
            @test Unitful.numtype(T) === Unitful.numtype(T(1)) === typeof(Dates.value(T(1)))
            @test unit(T) === unit(T(1)) === u
        end
        for T = (Month, Year)
            @test_throws MethodError dimension(T)
            @test_throws MethodError dimension(T(1))
            @test_throws MethodError Unitful.numtype(T)
            @test_throws MethodError Unitful.numtype(T(1))
            @test_throws MethodError unit(T)
            @test_throws MethodError unit(T(1))
        end

        for p = (CompoundPeriod, CompoundPeriod(), CompoundPeriod(Day(1)), CompoundPeriod(Day(1), Hour(-1)))
            @test dimension(p) === 𝐓
            @test_throws MethodError Unitful.numtype(p)
            @test_throws MethodError unit(p)
        end
    end

    @testset "> Arithmetic" begin
        @testset ">> Addition/subtraction" begin
            @test Second(3) + 5u"ms" === Int64(3)u"s" + 5u"ms"
            @test Second(3) - 5u"ms" === Int64(3)u"s" - 5u"ms"
            @test 1.0u"wk" + Day(3) === 1.0u"wk" + Int64(3)u"d"
            @test 1.0u"wk" - Day(3) === 1.0u"wk" - Int64(3)u"d"
            @test_throws DimensionError 1u"m" + Second(1)
            @test_throws DimensionError 1u"m" - Second(1)

            @test Dates.Date(2000, 2, 3) + 24.0u"hr" == Dates.Date(2000, 2, 4)
            @test Dates.Date(2000, 2, 3) + 48.0u"hr" == Dates.Date(2000, 2, 5)
            @test_throws Exception Dates.Date(2000, 2, 3) + 1.0u"hr"

            @test Dates.DateTime(2000, 2, 3, 4, 5) + 1.0u"ns" == Dates.DateTime(2000, 2, 3, 4, 5)
            @test Dates.DateTime(2000, 2, 3, 4, 5) + 23.0u"hr" == Dates.DateTime(2000, 2, 4, 3, 5)
            @test Dates.DateTime(2000, 2, 3, 4, 5) + 100.0u"hr" == Dates.DateTime(2000, 2, 7, 8, 5)
            @test Dates.Time(4, 5) + 1.0u"ps" == Dates.Time(4, 5)
            @test Dates.Time(4, 5) + 1.0u"ms" == Dates.Time(4, 5, 0, 1)
            @test Dates.Time(4, 5) + 1.5u"hr" == Dates.Time(5, 35)
            @test Dates.Date(2000, 2, 5) - 48.0u"hr" == Dates.Date(2000, 2, 3)
            @test 24.0u"hr" + Dates.Date(2000, 2, 5) == Dates.Date(2000, 2, 6)
        end

        @testset ">> Multiplication" begin
            # Multiplication with quantity
            @test Int64(3)u"m" * Day(1) === Int64(3)u"m*d"
            @test 1.0f0u"m" * Microsecond(-2) === -2.0f0u"m*μs"
            @test Hour(4) * Int32(2)u"m" === Int64(8)u"hr*m"
            @test Second(5) * (3//2)u"Hz" === Rational{Int64}(15,2)u"s*Hz"
            @test Second(5) * 2u"1/s" === Int64(10)
            @test 2.5u"1/s^2" * Second(2) === 5.0u"1/s"
            @test_throws AffineError Second(1) * 1u"°C"
            @test_throws AffineError 1u"°C" * Second(1)
            # Multiplication with unit
            @test Week(5) * u"Hz" === Int64(5)u"wk*Hz"
            @test u"mm" * Millisecond(20) === Int64(20)u"mm*ms"
            @test u"ms^-1" * Millisecond(20) === Int64(20)
            @test_throws AffineError Second(1) * u"°C"
            @test_throws AffineError u"°C" * Second(1)
            # Multiple factors
            @test 3.0u"s" * Second(3) * (3//1)u"s" === 27.0u"s^3"
            @test 3.0u"s" * Second(3) * Minute(3) === 27.0u"s^2*minute"
            @test u"s" * Second(3) * u"minute" === Int64(3)u"s^2*minute"
            @test Second(3) * u"m" * u"m" === Int64(3)u"s*m^2"
        end

        @testset ">> Division" begin
            @testset ">>> /, //" begin
                @test Nanosecond(10) / 2u"m" === 5.0u"ns/m"
                @test Nanosecond(10) / 2.0f0u"m" === 5.0f0u"ns/m"
                @test 5u"m" / Hour(2) === 2.5u"m/hr"
                @test 5.0f0u"m" / Hour(2) === 2.5f0u"m/hr"

                @test Nanosecond(10) // 2u"m" === Rational{Int64}(5,1)u"ns/m"
                @test 5u"m" // Hour(2) === Rational{Int64}(5,2)u"m/hr"
            end

            @testset ">>> div, fld, cld" begin
                @test div(Second(1), 2u"ms") == div(1u"s", Millisecond(2)) == div(1000, 2)
                @test div(Second(11), 2u"s") == div(11u"s", Second(2)) == div(11, 2)
                @test div(Second(-5), 2u"s") == div(-5u"s", Second(2)) == div(-5, 2)
                @test_throws DimensionError div(Second(1), 1u"m")
                @test_throws DimensionError div(1u"m", Second(1))

                @test div(4u"minute", CompoundPeriod(Minute(1), Second(30))) == div(8, 3)
                @test div(CompoundPeriod(Minute(4)), 90u"s") == div(8, 3)
                @test_throws DimensionError div(4u"m", CompoundPeriod(Minute(1), Second(30)))
                @test_throws DimensionError div(CompoundPeriod(Minute(4)), 90u"m")

                for r = (RoundNearest, RoundNearestTiesAway, RoundNearestTiesUp, RoundToZero, RoundUp, RoundDown)
                    @test div(Second(11), 2u"s", r) == div(11u"s", Second(2), r) == div(11, 2, r)
                    @test div(Second(-5), 2u"s", r) == div(-5u"s", Second(2), r) == div(-5, 2, r)
                    @test_throws DimensionError div(Second(1), 1u"m", r)
                    @test_throws DimensionError div(1u"m", Second(1), r)

                    if Sys.WORD_SIZE == 32 && r in (RoundNearestTiesAway, RoundNearestTiesUp)
                        @test_broken div(4u"minute", CompoundPeriod(Minute(1), Second(30)), r) == div(8, 3, r)
                    else
                        @test div(4u"minute", CompoundPeriod(Minute(1), Second(30)), r) == div(8, 3, r)
                    end
                    @test div(CompoundPeriod(Minute(4)), 90u"s", r) == div(8, 3, r)
                    @test_throws DimensionError div(4u"m", CompoundPeriod(Minute(1), Second(30)), r)
                    @test_throws DimensionError div(CompoundPeriod(Minute(4)), 90u"m", r)
                end

                @test fld(Second(1), 2u"ms") == fld(1u"s", Millisecond(2)) == fld(1000, 2)
                @test fld(Second(11), 2u"s") == fld(11u"s", Second(2)) == fld(11, 2)
                @test fld(Second(-5), 2u"s") == fld(-5u"s", Second(2)) == fld(-5, 2)
                @test_throws DimensionError fld(Second(1), 1u"m")
                @test_throws DimensionError fld(1u"m", Second(1))

                @test fld(4u"minute", CompoundPeriod(Minute(1), Second(30))) == fld(8, 3)
                @test fld(CompoundPeriod(Minute(4)), 90u"s") == fld(8, 3)
                @test_throws DimensionError fld(4u"m", CompoundPeriod(Minute(1), Second(30)))
                @test_throws DimensionError fld(CompoundPeriod(Minute(4)), 90u"m")

                @test cld(Second(1), 2u"ms") == cld(1u"s", Millisecond(2)) == cld(1000, 2)
                @test cld(Second(11), 2u"s") == cld(11u"s", Second(2)) == cld(11, 2)
                @test cld(Second(-5), 2u"s") == cld(-5u"s", Second(2)) == cld(-5, 2)
                @test_throws DimensionError cld(Second(1), 1u"m")
                @test_throws DimensionError cld(1u"m", Second(1))

                @test cld(4u"minute", CompoundPeriod(Minute(1), Second(30))) == cld(8, 3)
                @test cld(CompoundPeriod(Minute(4)), 90u"s") == cld(8, 3)
                @test_throws DimensionError cld(4u"m", CompoundPeriod(Minute(1), Second(30)))
                @test_throws DimensionError cld(CompoundPeriod(Minute(4)), 90u"m")
            end

            @testset ">>> mod, rem" begin
                @test mod(Second(11), 3_000u"ms") == mod(11u"s", Millisecond(3_000)) == mod(11, 3)u"s"
                @test mod(Second(11), -3u"s") == mod(11u"s", Second(-3)) == mod(11, -3)u"s"
                @test_throws DimensionError mod(Second(1), 1u"m")
                @test_throws DimensionError mod(1u"m", Second(1))

                @test mod(CompoundPeriod(Minute(4)), 90u"s") == mod(240, 90)u"s"
                @test_throws MethodError mod(4u"minute", CompoundPeriod(Minute(1), Second(30)))
                @test_throws MethodError mod(4u"m", CompoundPeriod(Minute(1), Second(30)))
                @test_throws DimensionError mod(CompoundPeriod(Minute(4)), 90u"m")

                @test rem(Second(11), 3_000u"ms") == rem(11u"s", Millisecond(3_000)) == rem(11, 3)u"s"
                @test rem(Second(11), -3u"s") == rem(11u"s", Second(-3)) == rem(11, -3)u"s"
                @test_throws DimensionError rem(Second(1), 1u"m")
                @test_throws DimensionError rem(1u"m", Second(1))

                @test rem(CompoundPeriod(Minute(4)), 90u"s") == rem(240, 90)u"s"
                @test_throws MethodError rem(4u"minute", CompoundPeriod(Minute(1), Second(30)))
                @test_throws MethodError rem(4u"m", CompoundPeriod(Minute(1), Second(30)))
                @test_throws DimensionError rem(CompoundPeriod(Minute(4)), 90u"m")

                for r = (RoundToZero, RoundUp, RoundDown)
                    @test rem(Second(11), 2u"s", r) == rem(11u"s", Second(2), r) == rem(11, 2, r)u"s"
                    @test rem(Second(-5), 2u"s", r) == rem(-5u"s", Second(2), r) == rem(-5, 2, r)u"s"
                    @test_throws DimensionError rem(Second(1), 1u"m", r)
                    @test_throws DimensionError rem(1u"m", Second(1), r)
                end
            end
        end

        @testset ">> atan" begin
            @test atan(Minute(1), 30u"s") == atan(2,1)
            @test atan(1u"ms", Millisecond(5)) == atan(1,5)
            @test_throws DimensionError atan(Second(1), 1u"m")
            @test_throws DimensionError atan(1u"m", Second(1))

            @test atan(CompoundPeriod(Minute(1), Second(30)), 10u"s") == atan(9,1)
            @test atan(1u"yr", CompoundPeriod(Day(365), Hour(6))) == atan(1,1)
            @test_throws DimensionError atan(1u"m", CompoundPeriod(Day(365), Hour(6)))
            @test_throws DimensionError atan(CompoundPeriod(Day(365), Hour(6)), 1u"m")
            @test_throws MethodError atan(1u"s", CompoundPeriod(Year(1)))
            @test_throws MethodError atan(CompoundPeriod(Month(6)), 1u"s")
        end
    end

    @testset "> Conversion" begin
        @testset ">> uconvert" begin
            @test uconvert(u"s", Second(3)) === u"s"(Second(3)) === Int64(3)u"s"
            @test uconvert(u"hr", Minute(90)) === u"hr"(Minute(90)) === Rational{Int64}(3,2)u"hr"
            @test uconvert(u"ns", Millisecond(-2)) === u"ns"(Millisecond(-2)) === Int64(-2_000_000)u"ns"
            @test uconvert(u"wk", Hour(1)) === u"wk"(Hour(1)) === Rational{Int64}(1,168)u"wk"
            @test_throws DimensionError uconvert(u"m", Second(1))
            @test_throws DimensionError u"m"(Second(1))

            @static if Sys.WORD_SIZE == 32
                @test uconvert(u"yr", CompoundPeriod()) === u"yr"(CompoundPeriod()) === 0.0u"yr"
            else
                @test uconvert(u"yr", CompoundPeriod()) === u"yr"(CompoundPeriod()) === Rational{Int64}(0,1)u"yr"
            end
            @test uconvert(u"μs", CompoundPeriod()) === u"μs"(CompoundPeriod()) === Rational{Int64}(0,1)u"μs"
            @test uconvert(u"ns", CompoundPeriod()) === u"ns"(CompoundPeriod()) === Int64(0)u"ns"
            @test uconvert(u"ps", CompoundPeriod()) === u"ps"(CompoundPeriod()) === Int64(0)u"ps"
            @static if Sys.WORD_SIZE == 32
                @test uconvert(u"yr", CompoundPeriod(Day(365),Hour(6))) === 1.0u"yr"
                @test u"yr"(CompoundPeriod(Day(365),Hour(6))) === 1.0u"yr"
            else
                @test uconvert(u"yr", CompoundPeriod(Day(365),Hour(6))) === Rational{Int64}(1,1)u"yr"
                @test u"yr"(CompoundPeriod(Day(365),Hour(6))) === Rational{Int64}(1,1)u"yr"
            end
            @test uconvert(u"μs", CompoundPeriod(Day(365),Hour(6))) === Rational{Int64}(31_557_600_000_000,1)u"μs"
            @test u"μs"(CompoundPeriod(Day(365),Hour(6))) === Rational{Int64}(31_557_600_000_000,1)u"μs"
            @test uconvert(u"ns", CompoundPeriod(Day(365),Hour(6))) === Int64(31_557_600_000_000_000)u"ns"
            @test u"ns"(CompoundPeriod(Day(365),Hour(6))) === Int64(31_557_600_000_000_000)u"ns"
            @test uconvert(u"ps", CompoundPeriod(Week(1),Hour(-1))) === Int64(601_200_000_000_000_000)u"ps"
            @test u"ps"(CompoundPeriod(Week(1),Hour(-1))) === Int64(601_200_000_000_000_000)u"ps"
            @test_throws DimensionError uconvert(u"m", CompoundPeriod(Day(365),Hour(6)))
            @test_throws DimensionError u"m"(CompoundPeriod(Day(365),Hour(6)))
            @test_throws MethodError uconvert(u"yr", CompoundPeriod(Year(1),Day(1)))
            @test_throws MethodError u"yr"(CompoundPeriod(Year(1),Day(1)))
            @test_throws MethodError uconvert(u"s", CompoundPeriod(Month(1),Day(1)))
            @test_throws MethodError u"s"(CompoundPeriod(Month(1),Day(1)))
        end

        @testset ">> ustrip" begin
            for (T,u) = ((Nanosecond, u"ns"), (Microsecond, u"μs"), (Millisecond, u"ms"),
                         (Second, u"s"), (Minute, u"minute"), (Hour, u"hr"), (Day, u"d"),
                (Week, u"wk"))
                @test ustrip(T(5)) === ustrip(u, T(5)) === Int64(5)
            end
            @test ustrip(u"ms", Second(1)) === Int64(1000)
            @test ustrip(u"wk", Day(1)) === Rational{Int64}(1,7)
            @test_throws DimensionError ustrip(u"m", Nanosecond(1))
            @test_throws MethodError ustrip(Month(1))
            @test_throws MethodError ustrip(Year(1))
            @test_throws MethodError ustrip(u"s", Month(1))
            @test_throws MethodError ustrip(u"yr", Year(1))

            @static if Sys.WORD_SIZE == 32
                @test ustrip(u"yr", CompoundPeriod()) === 0.0
            else
                @test ustrip(u"yr", CompoundPeriod()) === Rational{Int64}(0,1)
            end
            @test ustrip(u"μs", CompoundPeriod()) === Rational{Int64}(0,1)
            @test ustrip(u"ns", CompoundPeriod()) === Int64(0)
            @test ustrip(u"ps", CompoundPeriod()) === Int64(0)
            @static if Sys.WORD_SIZE == 32
                @test ustrip(u"yr", CompoundPeriod(Day(365),Hour(6))) === 1.0
            else
                @test ustrip(u"yr", CompoundPeriod(Day(365),Hour(6))) === Rational{Int64}(1,1)
            end
            @test ustrip(u"μs", CompoundPeriod(Day(365),Hour(6))) === Rational{Int64}(31_557_600_000_000,1)
            @test ustrip(u"ns", CompoundPeriod(Day(365),Hour(6))) === Int64(31_557_600_000_000_000)
            @test ustrip(u"ps", CompoundPeriod(Week(1),Hour(-1))) === Int64(601_200_000_000_000_000)
            @test_throws DimensionError ustrip(u"m", CompoundPeriod(Day(365),Hour(6)))
            @test_throws MethodError ustrip(CompoundPeriod())
            @test_throws MethodError ustrip(CompoundPeriod(Second(1)))
            @test_throws MethodError ustrip(CompoundPeriod(Week(1), Hour(-1)))
            @test_throws MethodError ustrip(u"yr", CompoundPeriod(Year(1)))
            @test_throws MethodError ustrip(u"yr", CompoundPeriod(Month(1)))
        end

        @testset ">> Constructors/convert" begin
            for (T,u) = ((Nanosecond, u"ns"), (Microsecond, u"μs"), (Millisecond, u"ms"),
                         (Second, u"s"), (Minute, u"minute"), (Hour, u"hr"), (Day, u"d"),
                (Week, u"wk"))
                @test Quantity(T(1)) === convert(Quantity, T(1)) === Int64(1)*u
                @test Quantity{Float64,𝐓,typeof(u)}(T(2)) === convert(Quantity{Float64,𝐓,typeof(u)}, T(2)) === 2.0u
                @test Quantity{Rational{Int64},𝐓,typeof(u)}(T(3)) === convert(Quantity{Rational{Int64},𝐓,typeof(u)}, T(3)) === Rational{Int64}(3,1)u
            end
            @test Quantity{Float64,𝐓,typeof(u"d")}(Hour(6)) === convert(typeof(1.0u"d"), Hour(6)) === 0.25u"d"
            @test_throws InexactError Quantity{Int64,𝐓,typeof(u"d")}(Hour(6))
            @test_throws InexactError convert(typeof(1u"d"), Hour(6))
            @test_throws DimensionError Quantity{Float64,𝐋,typeof(u"m")}(Hour(6))
            @test_throws DimensionError convert(typeof(1.0u"m"), Week(1))
            @test_throws MethodError Quantity{Float64,𝐓,typeof(u"d")}(Month(1))
            @test_throws MethodError Quantity{Float64,𝐓,typeof(u"d")}(Year(1))
            @test_throws MethodError convert(typeof(1u"d"), Month(1))
            @test_throws MethodError convert(typeof(1u"d"), Year(1))

            @test Week(4u"wk") === convert(Week, 4u"wk") === Week(4)
            @test Microsecond((3//2)u"ms") === convert(Microsecond, (3//2)u"ms") === Microsecond(1500)
            @test Millisecond(1.0u"s") === convert(Millisecond, 1.0u"s") === Millisecond(1000)
            @test Second(1.0u"s") === convert(Second, 1.0u"s") === Second(1)
            @test Day(3u"wk") === convert(Day, 3u"wk") === Day(21)
            @test_throws InexactError Second(1.5u"s")
            @test_throws InexactError convert(Second, 1.5u"s")
            @test_throws InexactError Second(1u"ms")
            @test_throws InexactError convert(Second, 1u"ms")
            @test_throws DimensionError Second(1u"m")
            @test_throws DimensionError convert(Second, 1u"m")
            @test_throws DimensionError Month(1u"s") # Doesn't throw MethodError because Month(::Number) exists
            @test_throws DimensionError Year(1u"s") # Doesn't throw MethodError because Year(::Number) exists
            @test_throws MethodError convert(Month, 1u"s")
            @test_throws MethodError convert(Year, 1u"s")

            for T = (Quantity{Rational{Int64},𝐓,typeof(u"yr")},
                     Quantity{Float64,𝐓,typeof(u"s")},
                     Quantity{Int64,𝐓,typeof(u"ns")})
                @test T(CompoundPeriod()) === convert(T, CompoundPeriod()) === T(0u"s")
                @test T(CompoundPeriod(Day(365), Hour(6))) === convert(T, CompoundPeriod(Day(365), Hour(6))) === T(1u"yr")
                @test T(CompoundPeriod(Week(1), Hour(-1))) === convert(T, CompoundPeriod(Week(1), Hour(-1))) === T(167u"hr")
                @test_throws MethodError T(CompoundPeriod(Month(1)))
                @test_throws MethodError T(CompoundPeriod(Year(1)))
                @test_throws MethodError convert(T, CompoundPeriod(Month(1)))
                @test_throws MethodError convert(T, CompoundPeriod(Year(1)))
            end
            @test_throws InexactError Quantity{Int64,𝐓,typeof(u"d")}(CompoundPeriod(Day(1),Hour(6)))
            @test_throws InexactError convert(typeof(1u"d"), CompoundPeriod(Day(1),Hour(1)))
            @test_throws DimensionError Quantity{Float64,𝐋,typeof(u"m")}(CompoundPeriod(Day(365), Hour(6)))
            @test_throws DimensionError convert(typeof(1.0u"m"), CompoundPeriod(Day(365), Hour(6)))
        end
    end

    @testset "> Rounding" begin
        @test round(Second, -1.2u"s") === round(Second, -1.2u"s", RoundNearest) === Second(-1)
        @test round(Second, -1.5u"s") === round(Second, -1.5u"s", RoundNearest) === Second(-2)
        @test round(Second, -0.5u"s") === round(Second, -0.5u"s", RoundNearest) === Second(0)
        @test round(Minute,   45u"s") === round(Minute,   45u"s", RoundNearest) === Minute(1)
        @test round(Minute,   90u"s") === round(Minute,   90u"s", RoundNearest) === Minute(2)
        @test round(Minute,  150u"s") === round(Minute,  150u"s", RoundNearest) === Minute(2)
        @test round(Second, -1.2u"s", RoundNearestTiesAway) === Second(-1)
        @test round(Second, -1.5u"s", RoundNearestTiesAway) === Second(-2)
        @test round(Second, -0.5u"s", RoundNearestTiesAway) === Second(-1)
        @test round(Minute,   45u"s", RoundNearestTiesAway) === Minute(1)
        @test round(Minute,   90u"s", RoundNearestTiesAway) === Minute(2)
        @test round(Minute,  150u"s", RoundNearestTiesAway) === Minute(3)
        @test round(Second, -1.2u"s", RoundNearestTiesUp) === Second(-1)
        @test round(Second, -1.5u"s", RoundNearestTiesUp) === Second(-1)
        @test round(Second, -0.5u"s", RoundNearestTiesUp) === Second(0)
        @test round(Minute,   45u"s", RoundNearestTiesUp) === Minute(1)
        @test round(Minute,   90u"s", RoundNearestTiesUp) === Minute(2)
        @test round(Minute,  150u"s", RoundNearestTiesUp) === Minute(3)
        @test trunc(Second, -1.2u"s") === round(Second, -1.2u"s", RoundToZero) === Second(-1)
        @test trunc(Second, -1.5u"s") === round(Second, -1.5u"s", RoundToZero) === Second(-1)
        @test trunc(Second, -0.5u"s") === round(Second, -0.5u"s", RoundToZero) === Second(0)
        @test ceil(Second, -1.2u"s")  === round(Second, -1.2u"s", RoundUp) === Second(-1)
        @test ceil(Second, -1.5u"s")  === round(Second, -1.5u"s", RoundUp) === Second(-1)
        @test ceil(Second, -0.5u"s")  === round(Second, -0.5u"s", RoundUp) === Second(0)
        @test floor(Second, -1.2u"s") === round(Second, -1.2u"s", RoundDown) === Second(-2)
        @test floor(Second, -1.5u"s") === round(Second, -1.5u"s", RoundDown) === Second(-2)
        @test floor(Second, -0.5u"s") === round(Second, -0.5u"s", RoundDown) === Second(-1)
        @test trunc(Minute,  45u"s") === round(Minute,   45u"s", RoundToZero) === Minute(0)
        @test trunc(Minute,  90u"s") === round(Minute,   90u"s", RoundToZero) === Minute(1)
        @test trunc(Minute, 150u"s") === round(Minute,  150u"s", RoundToZero) === Minute(2)
        @test ceil(Minute,  45u"s")  === round(Minute,   45u"s", RoundUp) === Minute(1)
        @test ceil(Minute,  90u"s")  === round(Minute,   90u"s", RoundUp) === Minute(2)
        @test ceil(Minute, 150u"s")  === round(Minute,  150u"s", RoundUp) === Minute(3)
        @test floor(Minute,  45u"s") === round(Minute,   45u"s", RoundDown) === Minute(0)
        @test floor(Minute,  90u"s") === round(Minute,   90u"s", RoundDown) === Minute(1)
        @test floor(Minute, 150u"s") === round(Minute,  150u"s", RoundDown) === Minute(2)
        @test_throws DimensionError round(Second, 1u"m")
        @test_throws DimensionError round(Second, 1u"m", RoundNearestTiesUp)
        @test_throws DimensionError trunc(Second, 1u"m")
        @test_throws DimensionError ceil(Second, 1u"m")
        @test_throws DimensionError floor(Second, 1u"m")

        @test round(u"minute", Second(-50)) === Rational{Int64}(-1,1)u"minute"
        @test round(u"minute", Second(-90)) === Rational{Int64}(-2,1)u"minute"
        @test round(u"minute", Second(150)) === Rational{Int64}(2,1)u"minute"
        @test round(u"minute", Second(-50), RoundNearest) === Rational{Int64}(-1,1)u"minute"
        @test round(u"minute", Second(-90), RoundNearest) === Rational{Int64}(-2,1)u"minute"
        @test round(u"minute", Second(150), RoundNearest) === Rational{Int64}(2,1)u"minute"
        @test round(u"minute", Second(-50), RoundNearestTiesAway) === Rational{Int64}(-1,1)u"minute"
        @test round(u"minute", Second(-90), RoundNearestTiesAway) === Rational{Int64}(-2,1)u"minute"
        @test round(u"minute", Second(150), RoundNearestTiesAway) === Rational{Int64}(3,1)u"minute"
        @test round(u"minute", Second(-50), RoundNearestTiesUp) === Rational{Int64}(-1,1)u"minute"
        @test round(u"minute", Second(-90), RoundNearestTiesUp) === Rational{Int64}(-1,1)u"minute"
        @test round(u"minute", Second(150), RoundNearestTiesUp) === Rational{Int64}(3,1)u"minute"

        @test trunc(u"minute", Second(-50)) === round(u"minute", Second(-50), RoundToZero) === Rational{Int64}(0,1)u"minute"
        @test trunc(u"minute", Second(-90)) === round(u"minute", Second(-90), RoundToZero) === Rational{Int64}(-1,1)u"minute"
        @test trunc(u"minute", Second(150)) === round(u"minute", Second(150), RoundToZero) === Rational{Int64}(2,1)u"minute"

        @test ceil(u"minute", Second(-50))  === round(u"minute", Second(-50), RoundUp) === Rational{Int64}(0,1)u"minute"
        @test ceil(u"minute", Second(-90))  === round(u"minute", Second(-90), RoundUp) === Rational{Int64}(-1,1)u"minute"
        @test ceil(u"minute", Second(150))  === round(u"minute", Second(150), RoundUp) === Rational{Int64}(3,1)u"minute"

        @test floor(u"minute", Second(-50)) === round(u"minute", Second(-50), RoundDown) === Rational{Int64}(-1,1)u"minute"
        @test floor(u"minute", Second(-90)) === round(u"minute", Second(-90), RoundDown) === Rational{Int64}(-2,1)u"minute"
        @test floor(u"minute", Second(150)) === round(u"minute", Second(150), RoundDown) === Rational{Int64}(2,1)u"minute"

        @test_throws DimensionError round(u"m", Second(1))
        @test_throws DimensionError round(u"m", Second(1), RoundNearestTiesAway)
        @test_throws DimensionError trunc(u"m", Second(1))
        @test_throws DimensionError ceil(u"m", Second(1))
        @test_throws DimensionError floor(u"m", Second(1))

        T = @static Sys.WORD_SIZE == 32 ? Float64 : Rational{Int64}
        @test round(u"minute", CompoundPeriod(Minute(-1), Second(10))) === T(-1)u"minute"
        @test round(u"minute", CompoundPeriod(Minute(-2), Second(30))) === T(-2)u"minute"
        @test round(u"minute", CompoundPeriod(Minute(3), Second(-30))) === T(2)u"minute"
        @test round(u"minute", CompoundPeriod(Minute(-1), Second(10)), RoundNearest) === T(-1)u"minute"
        @test round(u"minute", CompoundPeriod(Minute(-2), Second(30)), RoundNearest) === T(-2)u"minute"
        @test round(u"minute", CompoundPeriod(Minute(3), Second(-30)), RoundNearest) === T(2)u"minute"
        @test round(u"minute", CompoundPeriod(Minute(-1), Second(10)), RoundNearestTiesAway) === T(-1)u"minute"
        @test round(u"minute", CompoundPeriod(Minute(-2), Second(30)), RoundNearestTiesAway) === T(-2)u"minute"
        @test round(u"minute", CompoundPeriod(Minute(3), Second(-30)), RoundNearestTiesAway) === T(3)u"minute"
        @test round(u"minute", CompoundPeriod(Minute(-1), Second(10)), RoundNearestTiesUp) === T(-1)u"minute"
        @test round(u"minute", CompoundPeriod(Minute(-2), Second(30)), RoundNearestTiesUp) === T(-1)u"minute"
        @test round(u"minute", CompoundPeriod(Minute(3), Second(-30)), RoundNearestTiesUp) === T(3)u"minute"
        @test trunc(u"minute", CompoundPeriod(Minute(-1), Second(10))) === -T(0)u"minute"
        @test trunc(u"minute", CompoundPeriod(Minute(-2), Second(30))) === T(-1)u"minute"
        @test trunc(u"minute", CompoundPeriod(Minute(3), Second(-30))) === T(2)u"minute"
        @test round(u"minute", CompoundPeriod(Minute(-1), Second(10)), RoundToZero) === -T(0)u"minute"
        @test round(u"minute", CompoundPeriod(Minute(-2), Second(30)), RoundToZero) === T(-1)u"minute"
        @test round(u"minute", CompoundPeriod(Minute(3), Second(-30)), RoundToZero) === T(2)u"minute"
        @test ceil(u"minute", CompoundPeriod(Minute(-1), Second(10)))  === -T(0)u"minute"
        @test ceil(u"minute", CompoundPeriod(Minute(-2), Second(30)))  === T(-1)u"minute"
        @test ceil(u"minute", CompoundPeriod(Minute(3), Second(-30)))  === T(3)u"minute"
        @test round(u"minute", CompoundPeriod(Minute(-1), Second(10)), RoundUp) === -T(0)u"minute"
        @test round(u"minute", CompoundPeriod(Minute(-2), Second(30)), RoundUp) === T(-1)u"minute"
        @test round(u"minute", CompoundPeriod(Minute(3), Second(-30)), RoundUp) === T(3)u"minute"
        @test floor(u"minute", CompoundPeriod(Minute(-1), Second(10))) === T(-1)u"minute"
        @test floor(u"minute", CompoundPeriod(Minute(-2), Second(30))) === T(-2)u"minute"
        @test floor(u"minute", CompoundPeriod(Minute(3), Second(-30))) === T(2)u"minute"
        @test round(u"minute", CompoundPeriod(Minute(-1), Second(10)), RoundDown) === T(-1)u"minute"
        @test round(u"minute", CompoundPeriod(Minute(-2), Second(30)), RoundDown) === T(-2)u"minute"
        @test round(u"minute", CompoundPeriod(Minute(3), Second(-30)), RoundDown) === T(2)u"minute"
        @test_throws MethodError round(u"s", CompoundPeriod(Year(1)))
        @test_throws MethodError round(u"s", CompoundPeriod(Year(1)), RoundNearestTiesAway)
        @test_throws MethodError trunc(u"s", CompoundPeriod(Year(1)))
        @test_throws MethodError ceil(u"s", CompoundPeriod(Year(1)))
        @test_throws MethodError floor(u"s", CompoundPeriod(Year(1)))
        @test_throws MethodError round(u"s", CompoundPeriod(Month(1)))
        @test_throws MethodError round(u"s", CompoundPeriod(Month(1)), RoundNearestTiesAway)
        @test_throws MethodError trunc(u"s", CompoundPeriod(Month(1)))
        @test_throws MethodError ceil(u"s", CompoundPeriod(Month(1)))
        @test_throws MethodError floor(u"s", CompoundPeriod(Month(1)))
        @test_throws DimensionError round(u"m", CompoundPeriod(Second(1)))
        @test_throws DimensionError round(u"m", CompoundPeriod(Second(1)), RoundNearestTiesAway)
        @test_throws DimensionError trunc(u"m", CompoundPeriod(Second(1)))
        @test_throws DimensionError ceil(u"m", CompoundPeriod(Second(1)))
        @test_throws DimensionError floor(u"m", CompoundPeriod(Second(1)))

        @test round(u"wk", Day(10), digits=1) === 1.4u"wk"
        @test round(u"wk", Day(10), sigdigits=3) === 1.43u"wk"
        @test round(u"wk", Day(10), RoundUp, digits=1) === 1.5u"wk"
        @test round(u"wk", Day(10), RoundDown, sigdigits=3) === 1.42u"wk"
        @test round(u"wk", Day(10), RoundUp, digits=2, base=2) === 1.5u"wk"
        @test round(u"wk", Day(10), RoundToZero, digits=2, base=2) === 1.25u"wk"
        @test floor(u"wk", Day(10), sigdigits=3) === 1.42u"wk"
        @test ceil(u"wk", Day(10), digits=2, base=2) === 1.5u"wk"
        @test trunc(u"wk", Day(10), digits=2, base=2) === 1.25u"wk"
        @test_throws DimensionError round(u"m", Day(10), digits=1)
        @test_throws DimensionError round(u"m", Day(10), sigdigits=3, base=2)
        @test_throws DimensionError round(u"m", Day(10), RoundUp, digits=1)
        @test_throws DimensionError trunc(u"m", Day(10), digits=1)
        @test_throws DimensionError ceil(u"m", Day(10), sigdigits=3)
        @test_throws DimensionError floor(u"m", Day(10), digits=1, base=2)

        @test round(u"wk", CompoundPeriod(Week(1), Day(3)), digits=1) === 1.4u"wk"
        @test round(u"wk", CompoundPeriod(Week(1), Day(3)), sigdigits=3) === 1.43u"wk"
        @test round(u"wk", CompoundPeriod(Week(1), Day(3)), RoundUp, digits=1) === 1.5u"wk"
        @test round(u"wk", CompoundPeriod(Week(1), Day(3)), RoundDown, sigdigits=3) === 1.42u"wk"
        @test round(u"wk", CompoundPeriod(Week(1), Day(3)), RoundUp, digits=2, base=2) === 1.5u"wk"
        @test round(u"wk", CompoundPeriod(Week(1), Day(3)), RoundToZero, digits=2, base=2) === 1.25u"wk"
        @test floor(u"wk", CompoundPeriod(Week(1), Day(3)), sigdigits=3) === 1.42u"wk"
        @test ceil(u"wk", CompoundPeriod(Week(1), Day(3)), digits=2, base=2) === 1.5u"wk"
        @test trunc(u"wk", CompoundPeriod(Week(1), Day(3)), digits=2, base=2) === 1.25u"wk"
        @test_throws MethodError round(u"wk", CompoundPeriod(Year(1)), digits=1)
        @test_throws MethodError floor(u"wk", CompoundPeriod(Year(1)), sigdigits=3)
        @test_throws MethodError ceil(u"wk", CompoundPeriod(Year(1)), digits=2, base=2)
        @test_throws MethodError trunc(u"wk", CompoundPeriod(Year(1)), digits=2, base=2)
        @test_throws MethodError round(u"wk", CompoundPeriod(Month(1)), digits=1)
        @test_throws MethodError floor(u"wk", CompoundPeriod(Month(1)), sigdigits=3)
        @test_throws MethodError ceil(u"wk", CompoundPeriod(Month(1)), digits=2, base=2)
        @test_throws MethodError trunc(u"wk", CompoundPeriod(Month(1)), digits=2, base=2)
        @test_throws DimensionError round(u"m", CompoundPeriod(Week(1), Day(3)), digits=1)
        @test_throws DimensionError round(u"m", CompoundPeriod(Week(1), Day(3)), sigdigits=3, base=2)
        @test_throws DimensionError round(u"m", CompoundPeriod(Week(1), Day(3)), RoundUp, digits=1)
        @test_throws DimensionError trunc(u"m", CompoundPeriod(Week(1), Day(3)), digits=1)
        @test_throws DimensionError ceil(u"m", CompoundPeriod(Week(1), Day(3)), sigdigits=3)
        @test_throws DimensionError floor(u"m", CompoundPeriod(Week(1), Day(3)), digits=1, base=2)

        @test round(Int, u"minute", Second(-50)) === -1u"minute"
        @test round(Float32, u"minute", Second(-50)) === -1.0f0u"minute"
        @test round(Int, u"minute", Second(50), RoundDown) === 0u"minute"
        @test round(Int, u"minute", Second(50), RoundUp) === 1u"minute"
        @test round(Int, u"minute", Second(50), RoundToZero) === 0u"minute"
        @test floor(Int, u"minute", Second(50)) === 0u"minute"
        @test ceil(Int, u"minute", Second(50)) === 1u"minute"
        @test trunc(Int, u"minute", Second(50)) === 0u"minute"
        @test round(Float32, u"minute", Second(50), RoundDown) === 0.0f0u"minute"
        @test round(Float32, u"minute", Second(50), RoundUp) === 1.0f0u"minute"
        @test round(Float32, u"minute", Second(50), RoundToZero) === 0.0f0u"minute"
        @test floor(Float32, u"minute", Second(50)) === 0.0f0u"minute"
        @test ceil(Float32, u"minute", Second(50)) === 1.0f0u"minute"
        @test trunc(Float32, u"minute", Second(50)) === 0.0f0u"minute"
        @test round(Float32, u"wk", Day(10), digits=1) === 1.4f0u"wk"
        @test round(Float32, u"wk", Day(10), sigdigits=3) === 1.43f0u"wk"
        @test round(Float32, u"wk", Day(10), RoundUp, digits=1) === 1.5f0u"wk"
        @test round(Float32, u"wk", Day(10), RoundDown, sigdigits=3) === 1.42f0u"wk"
        @test round(Float32, u"wk", Day(10), RoundUp, digits=2, base=2) === 1.5f0u"wk"
        @test round(Float32, u"wk", Day(10), RoundToZero, digits=2, base=2) === 1.25f0u"wk"
        @test floor(Float32, u"wk", Day(10), sigdigits=3) === 1.42f0u"wk"
        @test ceil(Float32, u"wk", Day(10), digits=2, base=2) === 1.5f0u"wk"
        @test trunc(Float32, u"wk", Day(10), digits=2, base=2) === 1.25f0u"wk"
        @test_throws DimensionError round(Float32, u"m", Second(-50))
        @test_throws DimensionError round(Float32, u"m", Second(-50), RoundDown)
        @test_throws DimensionError round(Float32, u"m", Second(-50), digits=1)
        @test_throws DimensionError round(Float32, u"m", Second(-50), RoundDown, sigdigits=3)
        @test_throws DimensionError floor(Float32, u"m", Second(-50))
        @test_throws DimensionError ceil(Float32, u"m", Second(-50), digits=1)
        @test_throws DimensionError trunc(Float32, u"m", Second(-50), sigdigits=3, base=2)

        @test round(Int, u"minute", CompoundPeriod(Minute(-1), Second(10))) === -1u"minute"
        @test round(Float32, u"minute", CompoundPeriod(Minute(-1), Second(10))) === -1.0f0u"minute"
        @test round(Int, u"minute", CompoundPeriod(Minute(1), Second(-10)), RoundDown) === 0u"minute"
        @test round(Int, u"minute", CompoundPeriod(Minute(1), Second(-10)), RoundUp) === 1u"minute"
        @test round(Int, u"minute", CompoundPeriod(Minute(1), Second(-10)), RoundToZero) === 0u"minute"
        @test floor(Int, u"minute", CompoundPeriod(Minute(1), Second(-10))) === 0u"minute"
        @test ceil(Int, u"minute", CompoundPeriod(Minute(1), Second(-10))) === 1u"minute"
        @test trunc(Int, u"minute", CompoundPeriod(Minute(1), Second(-10))) === 0u"minute"
        @test round(Float32, u"minute", CompoundPeriod(Minute(1), Second(-10)), RoundDown) === 0.0f0u"minute"
        @test round(Float32, u"minute", CompoundPeriod(Minute(1), Second(-10)), RoundUp) === 1.0f0u"minute"
        @test round(Float32, u"minute", CompoundPeriod(Minute(1), Second(-10)), RoundToZero) === 0.0f0u"minute"
        @test floor(Float32, u"minute", CompoundPeriod(Minute(1), Second(-10))) === 0.0f0u"minute"
        @test ceil(Float32, u"minute", CompoundPeriod(Minute(1), Second(-10))) === 1.0f0u"minute"
        @test trunc(Float32, u"minute", CompoundPeriod(Minute(1), Second(-10))) === 0.0f0u"minute"
        @test round(Float32, u"wk", CompoundPeriod(Week(1), Day(3)), digits=1) === 1.4f0u"wk"
        @test round(Float32, u"wk", CompoundPeriod(Week(1), Day(3)), sigdigits=3) === 1.43f0u"wk"
        @test round(Float32, u"wk", CompoundPeriod(Week(1), Day(3)), RoundUp, digits=1) === 1.5f0u"wk"
        @test round(Float32, u"wk", CompoundPeriod(Week(1), Day(3)), RoundDown, sigdigits=3) === 1.42f0u"wk"
        @test round(Float32, u"wk", CompoundPeriod(Week(1), Day(3)), RoundUp, digits=2, base=2) === 1.5f0u"wk"
        @test round(Float32, u"wk", CompoundPeriod(Week(1), Day(3)), RoundToZero, digits=2, base=2) === 1.25f0u"wk"
        @test floor(Float32, u"wk", CompoundPeriod(Week(1), Day(3)), sigdigits=3) === 1.42f0u"wk"
        @test ceil(Float32, u"wk", CompoundPeriod(Week(1), Day(3)), digits=2, base=2) === 1.5f0u"wk"
        @test trunc(Float32, u"wk", CompoundPeriod(Week(1), Day(3)), digits=2, base=2) === 1.25f0u"wk"
        @test_throws MethodError round(Float32, u"yr", CompoundPeriod(Year(1)))
        @test_throws MethodError round(Float32, u"yr", CompoundPeriod(Year(1)), RoundDown)
        @test_throws MethodError round(Float32, u"yr", CompoundPeriod(Year(1)), digits=1)
        @test_throws MethodError round(Float32, u"yr", CompoundPeriod(Year(1)), RoundDown, sigdigits=3)
        @test_throws MethodError floor(Float32, u"yr", CompoundPeriod(Year(1)))
        @test_throws MethodError  ceil(Float32, u"yr", CompoundPeriod(Year(1)), digits=1)
        @test_throws MethodError trunc(Float32, u"yr", CompoundPeriod(Year(1)), sigdigits=3, base=2)
        @test_throws MethodError round(Float32, u"yr", CompoundPeriod(Month(1)))
        @test_throws MethodError round(Float32, u"yr", CompoundPeriod(Month(1)), RoundDown)
        @test_throws MethodError round(Float32, u"yr", CompoundPeriod(Month(1)), digits=1)
        @test_throws MethodError round(Float32, u"yr", CompoundPeriod(Month(1)), RoundDown, sigdigits=3)
        @test_throws MethodError floor(Float32, u"yr", CompoundPeriod(Month(1)))
        @test_throws MethodError  ceil(Float32, u"yr", CompoundPeriod(Month(1)), digits=1)
        @test_throws MethodError trunc(Float32, u"yr", CompoundPeriod(Month(1)), sigdigits=3, base=2)
        @test_throws DimensionError round(Float32, u"m", CompoundPeriod(Minute(-1), Second(10)))
        @test_throws DimensionError round(Float32, u"m", CompoundPeriod(Minute(-1), Second(10)), RoundDown)
        @test_throws DimensionError round(Float32, u"m", CompoundPeriod(Minute(-1), Second(10)), digits=1)
        @test_throws DimensionError round(Float32, u"m", CompoundPeriod(Minute(-1), Second(10)), RoundDown, sigdigits=3)
        @test_throws DimensionError floor(Float32, u"m", CompoundPeriod(Minute(-1), Second(10)))
        @test_throws DimensionError  ceil(Float32, u"m", CompoundPeriod(Minute(-1), Second(10)), digits=1)
        @test_throws DimensionError trunc(Float32, u"m", CompoundPeriod(Minute(-1), Second(10)), sigdigits=3, base=2)

        @test round(typeof(1.0f0u"minute"), Second(-50)) === -1.0f0u"minute"
        @test round(typeof(1.0f0u"minute"), Second(50), RoundToZero) === 0.0f0u"minute"
        @test round(typeof(1.0f0u"wk"), Day(10), digits=1) === 1.4f0u"wk"
        @test round(typeof(1.0f0u"wk"), Day(10), sigdigits=3) === 1.43f0u"wk"
        @test round(typeof(1.0f0u"wk"), Day(10), RoundUp, digits=1) === 1.5f0u"wk"
        @test round(typeof(1.0f0u"wk"), Day(10), RoundDown, sigdigits=3) === 1.42f0u"wk"
        @test round(typeof(1.0f0u"wk"), Day(10), RoundUp, digits=2, base=2) === 1.5f0u"wk"
        @test round(typeof(1.0f0u"wk"), Day(10), RoundToZero, digits=2, base=2) === 1.25f0u"wk"
        @test floor(typeof(1.0f0u"wk"), Day(10), sigdigits=3) === 1.42f0u"wk"
        @test ceil(typeof(1.0f0u"wk"), Day(10), digits=2, base=2) === 1.5f0u"wk"
        @test trunc(typeof(1.0f0u"wk"), Day(10), digits=2, base=2) === 1.25f0u"wk"
        @test_throws DimensionError round(typeof(1.0u"m"), Second(1))
        @test_throws DimensionError round(typeof(1.0u"m"), Second(1), RoundToZero)
        @test_throws DimensionError round(typeof(1.0u"m"), Second(1), digits=1)
        @test_throws DimensionError round(typeof(1.0u"m"), Second(1), RoundToZero, sigdigits=2)
        @test_throws DimensionError floor(typeof(1.0u"m"), Second(1))
        @test_throws DimensionError ceil(typeof(1.0u"m"), Second(1), sigdigits=2, base=2)
        @test_throws DimensionError trunc(typeof(1.0u"m"), Second(1), digits=1)

        @test round(typeof(1.0f0u"minute"), CompoundPeriod(Minute(-1), Second(10))) === -1.0f0u"minute"
        @test round(typeof(1.0f0u"minute"), CompoundPeriod(Minute(1), Second(-10)), RoundToZero) === 0.0f0u"minute"
        @test round(typeof(1.0f0u"wk"), CompoundPeriod(Week(1), Day(3)), digits=1) === 1.4f0u"wk"
        @test round(typeof(1.0f0u"wk"), CompoundPeriod(Week(1), Day(3)), sigdigits=3) === 1.43f0u"wk"
        @test round(typeof(1.0f0u"wk"), CompoundPeriod(Week(1), Day(3)), RoundUp, digits=1) === 1.5f0u"wk"
        @test round(typeof(1.0f0u"wk"), CompoundPeriod(Week(1), Day(3)), RoundDown, sigdigits=3) === 1.42f0u"wk"
        @test round(typeof(1.0f0u"wk"), CompoundPeriod(Week(1), Day(3)), RoundUp, digits=2, base=2) === 1.5f0u"wk"
        @test round(typeof(1.0f0u"wk"), CompoundPeriod(Week(1), Day(3)), RoundToZero, digits=2, base=2) === 1.25f0u"wk"
        @test floor(typeof(1.0f0u"wk"), CompoundPeriod(Week(1), Day(3)), sigdigits=3) === 1.42f0u"wk"
        @test ceil(typeof(1.0f0u"wk"), CompoundPeriod(Week(1), Day(3)), digits=2, base=2) === 1.5f0u"wk"
        @test trunc(typeof(1.0f0u"wk"), CompoundPeriod(Week(1), Day(3)), digits=2, base=2) === 1.25f0u"wk"
        @test_throws MethodError round(typeof(1.0u"s"), CompoundPeriod(Year(1)))
        @test_throws MethodError round(typeof(1.0u"s"), CompoundPeriod(Year(1)), RoundToZero)
        @test_throws MethodError round(typeof(1.0u"s"), CompoundPeriod(Year(1)), digits=1)
        @test_throws MethodError round(typeof(1.0u"s"), CompoundPeriod(Year(1)), RoundToZero, sigdigits=2)
        @test_throws MethodError floor(typeof(1.0u"s"), CompoundPeriod(Year(1)))
        @test_throws MethodError ceil(typeof(1.0u"s"), CompoundPeriod(Year(1)), sigdigits=2, base=2)
        @test_throws MethodError trunc(typeof(1.0u"s"), CompoundPeriod(Year(1)), digits=1)
        @test_throws MethodError round(typeof(1.0u"s"), CompoundPeriod(Month(1)))
        @test_throws MethodError round(typeof(1.0u"s"), CompoundPeriod(Month(1)), RoundToZero)
        @test_throws MethodError round(typeof(1.0u"s"), CompoundPeriod(Month(1)), digits=1)
        @test_throws MethodError round(typeof(1.0u"s"), CompoundPeriod(Month(1)), RoundToZero, sigdigits=2)
        @test_throws MethodError floor(typeof(1.0u"s"), CompoundPeriod(Month(1)))
        @test_throws MethodError ceil(typeof(1.0u"s"), CompoundPeriod(Month(1)), sigdigits=2, base=2)
        @test_throws MethodError trunc(typeof(1.0u"s"), CompoundPeriod(Month(1)), digits=1)
        @test_throws DimensionError round(typeof(1.0u"m"), CompoundPeriod(Second(1)))
        @test_throws DimensionError round(typeof(1.0u"m"), CompoundPeriod(Second(1)), RoundToZero)
        @test_throws DimensionError round(typeof(1.0u"m"), CompoundPeriod(Second(1)), digits=1)
        @test_throws DimensionError round(typeof(1.0u"m"), CompoundPeriod(Second(1)), RoundToZero, sigdigits=2)
        @test_throws DimensionError floor(typeof(1.0u"m"), CompoundPeriod(Second(1)))
        @test_throws DimensionError  ceil(typeof(1.0u"m"), CompoundPeriod(Second(1)), sigdigits=2, base=2)
        @test_throws DimensionError trunc(typeof(1.0u"m"), CompoundPeriod(Second(1)), digits=1)
    end

    @testset "> Comparison" begin
        # ==
        @test Second(2) == 2.0u"s"
        @test 72u"hr" == Day(3)
        @test Millisecond(0) == -0.0u"ms"
        @test !(Day(4) == 4u"hr")
        @test !(4u"cm" == Day(4))

        @test CompoundPeriod(Day(365), Hour(6)) == 1u"yr"
        @test 1u"yr" == CompoundPeriod(Day(365), Hour(6))
        @test CompoundPeriod() == -0.0u"s"
        @test !(1u"m" == CompoundPeriod(Day(1)))
        @test !(CompoundPeriod(Day(1)) == 1u"m")
        @test !(1u"yr" == CompoundPeriod(Year(1)))
        @test !(1u"yr" == CompoundPeriod(Month(12)))
        @test !(CompoundPeriod(Year(1)) == 1u"yr")
        @test !(CompoundPeriod(Month(12)) == 1u"yr")

        # isequal
        @test isequal(Second(2), 2.0u"s")
        @test isequal(72u"hr", Day(3))
        @test !isequal(Millisecond(0), -0.0u"ms") # !isequal(0.0, -0.0)
        @test !isequal(Day(4), 4u"hr")
        @test !isequal(4u"cm", Day(4))

        @test isequal(CompoundPeriod(Day(365), Hour(6)), 1u"yr")
        @test isequal(1u"yr", CompoundPeriod(Day(365), Hour(6)))
        @test !isequal(CompoundPeriod(), -0.0u"s") # !isequal(0.0, -0.0)
        @test !isequal(1u"m", CompoundPeriod(Day(1)))
        @test !isequal(CompoundPeriod(Day(1)), 1u"m")
        @test !isequal(1u"yr", CompoundPeriod(Year(1)))
        @test !isequal(1u"yr", CompoundPeriod(Month(12)))
        @test !isequal(CompoundPeriod(Year(1)), 1u"yr")
        @test !isequal(CompoundPeriod(Month(12)), 1u"yr")

        # <
        @test Second(1) < 1001u"ms"
        @test 3u"minute" < Minute(4)
        @test !(Minute(3) < 3u"minute")
        @test !(7u"d" < Week(1))
        @test !(-0.0u"d" < Day(0))
        @test_throws DimensionError 7u"kg" < Day(1)
        @test_throws DimensionError Day(1) < 7u"kg"

        @test CompoundPeriod(Day(365)) < 1u"yr"
        @test 1u"s" < CompoundPeriod(Second(1), Nanosecond(1))
        @test !(CompoundPeriod(Day(365), Hour(6)) < 1u"yr")
        @test !(1u"s" < CompoundPeriod(Second(1)))
        @test !(-0.0u"s" < CompoundPeriod())
        @test_throws DimensionError 7u"kg" < CompoundPeriod(Day(1))
        @test_throws DimensionError CompoundPeriod() < 1u"m"
        @test_throws MethodError 1u"s" < CompoundPeriod(Year(1))
        @test_throws MethodError 1u"s" < CompoundPeriod(Month(1))
        @test_throws MethodError CompoundPeriod(Year(1)) < 2u"yr"
        @test_throws MethodError CompoundPeriod(Month(1)) < 1u"yr"

        # isless
        @test isless(Second(1), 1001u"ms")
        @test isless(3u"minute", Minute(4))
        @test !isless(Minute(3), 3u"minute")
        @test !isless(7u"d", Week(1))
        @test isless(-0.0u"d", Day(0))
        @test_throws DimensionError isless(7u"kg", Day(1))
        @test_throws DimensionError isless(Day(1), 7u"kg")

        @test isless(CompoundPeriod(Day(365)), 1u"yr")
        @test isless(1u"s", CompoundPeriod(Second(1), Nanosecond(1)))
        @test !isless(CompoundPeriod(Day(365), Hour(6)), 1u"yr")
        @test !isless(1u"s", CompoundPeriod(Second(1)))
        @test isless(-0.0u"s", CompoundPeriod())
        @test_throws DimensionError isless(7u"kg", CompoundPeriod(Day(1)))
        @test_throws DimensionError isless(CompoundPeriod(), 1u"m")
        @test_throws MethodError isless(1u"s", CompoundPeriod(Year(1)))
        @test_throws MethodError isless(1u"s", CompoundPeriod(Month(1)))
        @test_throws MethodError isless(CompoundPeriod(Year(1)), 2u"yr")
        @test_throws MethodError isless(CompoundPeriod(Month(1)), 1u"yr")

        # ≤
        @test Second(1) ≤ 1001u"ms"
        @test 7u"d" ≤ Week(1)
        @test !(Minute(4) ≤ 3u"minute")
        @test_throws DimensionError 7u"kg" ≤ Day(1)
        @test_throws DimensionError Day(1) ≤ 7u"kg"

        @test CompoundPeriod(Day(365), Hour(6)) ≤ 1u"yr"
        @test 1u"s" ≤ CompoundPeriod(Second(1), Nanosecond(1))
        @test !(1u"s" ≤ CompoundPeriod(Millisecond(999)))
        @test_throws DimensionError 7u"kg" ≤ CompoundPeriod(Day(1))
        @test_throws DimensionError CompoundPeriod() ≤ 1u"m"
        @test_throws MethodError 1u"s" ≤ CompoundPeriod(Year(1))
        @test_throws MethodError 1u"s" ≤ CompoundPeriod(Month(1))
        @test_throws MethodError CompoundPeriod(Year(1)) ≤ 2u"yr"
        @test_throws MethodError CompoundPeriod(Month(1)) ≤ 1u"yr"

        # min, max
        @test min(1u"s", Microsecond(100)) == Microsecond(100)
        @test min(Day(1), 1u"hr") == 1u"hr"
        @test_throws DimensionError min(1u"kg", Second(1))
        @test_throws DimensionError min(Second(1), 1u"kg")
        @test max(1u"s", Microsecond(100)) == 1u"s"
        @test max(Day(1), 1u"hr") == Day(1)
        @test_throws DimensionError max(1u"kg", Second(1))
        @test_throws DimensionError max(Second(1), 1u"kg")

        @test min(1u"s", CompoundPeriod()) == CompoundPeriod()
        @test min(1u"yr", CompoundPeriod(Day(365), Hour(7))) == 1u"yr"
        @test_throws DimensionError min(CompoundPeriod(), 1u"m")
        @test_throws DimensionError min(1u"m", CompoundPeriod())
        @test_throws MethodError min(1u"yr", CompoundPeriod(Year(1)))
        @test_throws MethodError min(CompoundPeriod(Month(1)), 1u"yr")
        @test max(1u"s", CompoundPeriod()) == 1u"s"
        @test max(1u"yr", CompoundPeriod(Day(365), Hour(7))) == CompoundPeriod(Day(365), Hour(7))
        @test_throws DimensionError max(CompoundPeriod(), 1u"m")
        @test_throws DimensionError max(1u"m", CompoundPeriod())
        @test_throws MethodError max(1u"yr", CompoundPeriod(Year(1)))
        @test_throws MethodError max(CompoundPeriod(Month(1)), 1u"yr")
    end

    @testset "> isapprox" begin
        # scalar arguments
        @test isapprox(nextfloat(1.0)u"s", Second(1))
        @test isapprox(1.0u"s", Second(1), rtol=0)
        @test isapprox(Second(2), 2500u"ms", atol=1u"s")
        @test isapprox(Second(2), 2500u"ms", atol=Second(1))
        @test isapprox(2500u"ms", Second(2), rtol=0.5)
        @test !isapprox(2500u"ms", Second(2), rtol=0.1)
        @test !isapprox(nextfloat(1.0)u"s", Second(1), rtol=0)
        @test !isapprox(Second(1), 1u"m")
        @test !isapprox(1u"m", Second(1))
        @test !isapprox(Second(1), 1u"m", atol=1u"kg")
        @test !isapprox(1u"m", Second(1), atol=Second(1))
        @test_throws DimensionError isapprox(Second(2), 2500u"ms", atol=0.5)
        @test_throws DimensionError isapprox(Second(2), 2500u"ms", atol=0.5u"m")

        @test isapprox(nextfloat(1.0)u"yr", CompoundPeriod(Day(365), Hour(6)))
        @test isapprox(1.0u"yr", CompoundPeriod(Day(365), Hour(6)), rtol=0)
        @test isapprox(2u"s", CompoundPeriod(Second(2), Millisecond(500)), atol=1u"s")
        @test isapprox(CompoundPeriod(Second(2), Millisecond(500)), 2u"s", atol=CompoundPeriod(Second(1)))
        @test isapprox(CompoundPeriod(Second(2), Millisecond(500)), 2u"s", rtol=0.5)
        @test !isapprox(CompoundPeriod(Second(2), Millisecond(500)), 2u"s", rtol=0.1)
        @test !isapprox(CompoundPeriod(Week(1), Nanosecond(1)), 1.0u"wk", rtol=0)
        @test !isapprox(CompoundPeriod(Second(1)), 1u"m")
        @test !isapprox(1u"m", CompoundPeriod(Second(1)))
        @test !isapprox(CompoundPeriod(Second(1)), 1u"m", atol=1u"kg")
        @test !isapprox(1u"m", CompoundPeriod(Second(1)), atol=CompoundPeriod(Second(1)))
        @test_throws MethodError isapprox(CompoundPeriod(Year(1)), 1u"s")
        @test_throws MethodError isapprox(1u"s", CompoundPeriod(Year(1)), rtol=1)
        @test_throws MethodError isapprox(1u"s", 1u"s", atol=CompoundPeriod(Year(1)))
        @test_throws MethodError isapprox(CompoundPeriod(Month(1)), 1u"s")
        @test_throws MethodError isapprox(1u"s", CompoundPeriod(Month(1)), rtol=1)
        @test_throws MethodError isapprox(1u"s", 1u"s", atol=CompoundPeriod(Month(1)))
        @test_throws DimensionError isapprox(CompoundPeriod(Day(1)), 1u"d", atol=0.1)
        @test_throws DimensionError isapprox(1u"d", CompoundPeriod(Day(1)), atol=0.1u"m")

        # array arguments
        @test isapprox([Second(-5), Second(5)], [-5.0u"s", 5.0u"s"])
        @test isapprox([Second(-5), Second(5)], [-4.99u"s", 5.01u"s"], rtol=1e-2)
        @test_broken isapprox([1u"s", 60u"s"], Period[Second(1), Minute(1)], rtol=0)
        @test !isapprox([1.0u"kg"], [Second(1)])

        @test isapprox([CompoundPeriod(Day(2), Hour(12)), CompoundPeriod(Day(-3), Hour(12))], [2.5u"d", -2.5u"d"])
        @test isapprox([2.51u"d", -2.49u"d"], [CompoundPeriod(Day(2), Hour(12)), CompoundPeriod(Day(-3), Hour(12))], rtol=1e-2)
        @test isapprox([1u"s", 60u"s"], CompoundPeriod[Second(1), Minute(1)], rtol=0)
        @test !isapprox([CompoundPeriod(Day(1))], [1.0u"kg"])
        @test_throws MethodError isapprox([CompoundPeriod(Year(1))], [1.0u"yr"])
        @test_throws MethodError isapprox([1.0u"yr"], [CompoundPeriod(Month(12))], rtol=1)
    end

    @testset "> promote" begin
        @test promote(1u"d", Minute(1)) === promote(1u"d", Int64(1)u"minute")
        @test promote(Second(10), 2.0u"fs") === promote(Int64(10)u"s", 2.0u"fs")
        @test_throws ErrorException promote(1u"m", Second(1))
        @test_throws ErrorException promote(Day(1), 3u"T")
    end

    sleep(10u"ms")    # not tested explicitly, because sleep doesn't come with guarantees
end
