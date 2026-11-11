module PublicMacroUnits
    using Unitful

    @dimension public_dim "D" PublicDimension false true
    @derived_dimension PublicArea public_dim^2 false true
    @refunit public_ref "pr" PublicReference public_dim true false true
    @unit public_unit "pu" PublicUnit 2public_ref true false true
    @refunit single_ref "sr" SingleReference public_dim false false true
    @unit single_unit "su" SingleUnit 2public_ref false false true
    @affineunit public_affine "pa" 3public_ref true
end

module DefaultMacroUnits
    using Unitful

    @dimension private_dim "P" PrivateDimension
    @derived_dimension PrivateArea private_dim^2
    @refunit private_ref "pr" PrivateReference private_dim true
    @unit private_unit "pu" PrivateUnit 2private_ref true
    @affineunit private_affine "pa" 3private_ref
    @dimension explicit_private_dim "E" ExplicitPrivateDimension false false
end

@testset "Declare Public" begin
    public_symbols = (
        :public_dim, :PublicDimension, :PublicDimensionUnits, :PublicDimensionFreeUnits,
        :PublicArea, :PublicAreaUnits, :PublicAreaFreeUnits,
        :public_ref, :kpublic_ref, :public_unit, :kpublic_unit,
        :single_ref, :single_unit, :public_affine,
    )
    private_symbols = (
        :private_dim, :PrivateDimension, :PrivateDimensionUnits, :PrivateDimensionFreeUnits,
        :PrivateArea, :PrivateAreaUnits, :PrivateAreaFreeUnits,
        :private_ref, :kprivate_ref, :private_unit, :kprivate_unit, :private_affine,
        :explicit_private_dim, :ExplicitPrivateDimension,
        :ExplicitPrivateDimensionUnits, :ExplicitPrivateDimensionFreeUnits,
    )
    for sym in public_symbols
        @test isdefined(PublicMacroUnits, sym)
        if VERSION >= v"1.11.0-DEV.469"
            @test Base.ispublic(PublicMacroUnits, sym)
            @test !Base.isexported(PublicMacroUnits, sym)
        end
    end
    for sym in private_symbols
        @test isdefined(DefaultMacroUnits, sym)
        if VERSION >= v"1.11.0-DEV.469"
            @test !Base.ispublic(DefaultMacroUnits, sym)
        end
    end
    @test !isdefined(PublicMacroUnits, :D)
    @test !isdefined(PublicMacroUnits, :ksingle_ref)
    @test !isdefined(PublicMacroUnits, :ksingle_unit)
    @test 1PublicMacroUnits.public_unit == 2PublicMacroUnits.public_ref
    @test 1PublicMacroUnits.kpublic_unit == 2000PublicMacroUnits.public_ref
    @test uconvert(PublicMacroUnits.public_ref, 0PublicMacroUnits.public_affine) ==
          3PublicMacroUnits.public_ref
    if VERSION >= v"1.11.0-DEV.469"
        @test !Base.ispublic(PublicMacroUnits, :D)
        for sym in (:m, :km, :W, :kW, :Length, :AreaFreeUnits, :c0,
                    :AbstractQuantity, :DefaultSymbols)
            @test Base.ispublic(Unitful, sym)
            @test !Base.isexported(Unitful, sym)
        end
    end
end
