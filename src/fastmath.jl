import Base.FastMath

import Base.FastMath: @fastmath,
    FloatTypes,
    ComplexTypes,
    add_fast,
    sub_fast,
    mul_fast,
    div_fast,
    rem_fast,
    cmp_fast,
    # mod_fast,
    eq_fast,
    ne_fast,
    lt_fast,
    le_fast,
    pow_fast,
    sqrt_fast,
    cos_fast,
    sin_fast,
    tan_fast,
    sincos_fast,
    atan_fast,
    hypot_fast,
    max_fast,
    min_fast,
    minmax_fast,
    cis_fast,
    angle_fast,
    fast_op

sub_fast(x::Quantity{T}) where {T <: FloatTypes} = typeof(x)(sub_fast(x.val))

add_fast(x::Quantity{T,D,U}, y::Quantity{T,D,U}) where {T <: FloatTypes,D,U} =
    Quantity{T,D,U}(add_fast(x.val, y.val))

sub_fast(x::Quantity{T,D,U}, y::Quantity{T,D,U}) where {T <: FloatTypes,D,U} =
    Quantity(sub_fast(x.val, y.val), absoluteunit(unit(x)))

function mul_fast(x::Quantity{T}, y::Quantity{T}) where {T <: FloatTypes}
    D = dimension(x) * dimension(y)
    U = typeof(unit(x) * unit(y))
    Quantity{T,D,U}(mul_fast(x.val, y.val))
end
function div_fast(x::Quantity{T}, y::Quantity{T}) where {T <: FloatTypes}
    D = dimension(x) / dimension(y)
    U = typeof(unit(x) / unit(y))
    Quantity{T,D,U}(div_fast(x.val, y.val))
end

rem_fast(x::Quantity{T,D,U}, y::Quantity{T,D,U}) where {T <: FloatTypes,D,U} =
    Quantity{T,D,U}(rem_fast(x.val, y.val))

add_fast(x::Quantity{T}, y::Quantity{T}, z::Quantity{T}, t::Quantity{T}...) where {T <: FloatTypes} =
    add_fast(add_fast(add_fast(x, y), z), t...)
mul_fast(x::Quantity{T}, y::Quantity{T}, z::Quantity{T}, t::Quantity{T}...) where {T <: FloatTypes} =
    mul_fast(mul_fast(mul_fast(x, y), z), t...)

@fastmath begin
    cmp_fast(x::Quantity{T,D,U}, y::Quantity{T,D,U}) where {T <: FloatTypes,D,U} =
        ifelse(x==y, 0, ifelse(x<y, -1, +1))
end

eq_fast(x::Quantity{T,D,U}, y::Quantity{T,D,U}) where {T <: FloatTypes,D,U} =
    eq_fast(x.val,y.val)
ne_fast(x::Quantity{T,D,U}, y::Quantity{T,D,U}) where {T <: FloatTypes,D,U} =
    ne_fast(x.val,y.val)
lt_fast(x::Quantity{T,D,U}, y::Quantity{T,D,U}) where {T <: FloatTypes,D,U} =
    lt_fast(x.val,y.val)
le_fast(x::Quantity{T,D,U}, y::Quantity{T,D,U}) where {T <: FloatTypes,D,U} =
    le_fast(x.val,y.val)

@fastmath begin
    abs_fast(x::Quantity{T}) where {T <: ComplexTypes} = hypot(real(x), imag(x))
    abs2_fast(x::Quantity{T}) where {T <: ComplexTypes} = real(x)*real(x) + imag(x)*imag(x)
    conj_fast(x::Quantity{T,D,U}) where {T <: ComplexTypes,D,U} =
        Quantity{T,D,U}(T(real(x.val), -imag(x.val)))
    inv_fast(x::Quantity{T,D,U}) where {T <: ComplexTypes,D,U} = conj(x) / abs2(x)
    sign_fast(x::Quantity{T,D,U}) where {T <: ComplexTypes,D,U} =
        x == Quantity(0, U()) ? float(zero(x)) : x/abs(x)

    add_fast(x::Quantity{T,D,U}, y::Quantity{T,D,U}) where {T <: ComplexTypes,D,U} =
        Quantity{T,D,U}(T(real(x.val)+real(y.val), imag(x.val)+imag(y.val)))
    add_fast(x::Quantity{Complex{T},D,U}, b::Quantity{T,D,U}) where {T <: FloatTypes,D,U} =
        Quantity{Complex{T},D,U}(Complex{T}(real(x.val)+b.val, imag(x.val)))
    add_fast(a::Quantity{T,D,U}, y::Quantity{Complex{T},D,U}) where {T <: FloatTypes,D,U} =
        Quantity{Complex{T},D,U}(Complex{T}(a.val+real(y.val), imag(y.val)))

    sub_fast(x::Quantity{T,D,U}, y::Quantity{T,D,U}) where {T <: ComplexTypes,D,U} =
        Quantity{T,D,U}(T(real(x.val)-real(y.val), imag(x.val)-imag(y.val)))
    sub_fast(x::Quantity{Complex{T},D,U}, b::Quantity{T,D,U}) where {T <: FloatTypes,D,U} =
        Quantity{Complex{T},D,U}(Complex{T}(real(x.val)-b.val, imag(x.val)))
    sub_fast(a::Quantity{T,D,U}, y::Quantity{Complex{T},D,U}) where {T <: FloatTypes,D,U} =
        Quantity{Complex{T},D,U}(Complex{T}(a.val-real(y.val), -imag(y.val)))

    function mul_fast(x::Quantity{T}, y::Quantity{T}) where {T <: ComplexTypes}
        D = dimension(x) * dimension(y)
        U = typeof(unit(x) * unit(y))
        Quantity{T,D,U}(T(real(x.val)*real(y.val) - imag(x.val)*imag(y.val),
          real(x.val)*imag(y.val) + imag(x.val)*real(y.val)))
    end
    function mul_fast(x::Quantity{Complex{T}}, b::Quantity{T}) where {T <: FloatTypes}
        D = dimension(x) * dimension(b)
        U = typeof(unit(x) * unit(b))
        Quantity{Complex{T},D,U}(Complex{T}(real(x.val)*b.val, imag(x.val)*b.val))
    end
    function mul_fast(a::Quantity{T}, y::Quantity{Complex{T}}) where {T <: FloatTypes}
        D = dimension(a) * dimension(y)
        U = typeof(unit(a) * unit(y))
        Quantity{Complex{T},D,U}(Complex{T}(a.val*real(y.val), a.val*imag(y.val)))
    end

    @inline function div_fast(x::Quantity{T}, y::Quantity{T}) where {T <: ComplexTypes}
        D = dimension(x) * dimension(y)
        U = typeof(unit(x) * unit(y))
        Quantity{T,D,U}(T(real(x.val)*real(y.val) + imag(x.val)*imag(y.val),
          imag(x.val)*real(y.val) - real(x.val)*imag(y.val))) / abs2(y)
    end
    function div_fast(x::Quantity{Complex{T}}, b::Quantity{T}) where {T <: FloatTypes}
        D = dimension(x) / dimension(b)
        U = typeof(unit(x) / unit(b))
        Quantity{Complex{T},D,U}(Complex{T}(real(x.val)/b.val, imag(x.val)/b.val))
    end
    function div_fast(a::Quantity{T}, y::Quantity{Complex{T}}) where {T <: FloatTypes}
        D = dimension(a) * dimension(y)
        U = typeof(unit(a) * unit(y))
        Quantity{Complex{T},D,U}(Complex{T}(a.val*real(y.val),
            -a.val*imag(y.val))) / abs2(y)
    end

    eq_fast(x::Quantity{T}, y::Quantity{T}) where {T <: ComplexTypes} =
        (real(x)==real(y)) & (imag(x)==imag(y))
    eq_fast(x::Quantity{Complex{T}}, b::Quantity{T}) where {T <: FloatTypes} =
        (real(x)==b) & (imag(x)==zero(b))
    eq_fast(a::Quantity{T}, y::Quantity{Complex{T}}) where {T <: FloatTypes} =
        (a==real(y)) & (zero(a)==imag(y))

    ne_fast(x::Quantity{T,D,U}, y::Quantity{T,D,U}) where {T <: ComplexTypes,D,U} = !(x==y)
end

for op in (:+, :-, :*, :/, :(==), :!=, :<, :<=, :cmp, :rem)
    op_fast = fast_op[op]
    @eval begin
        # Fallback method for Quantitys after promotion.
        $op_fast(x::Quantity{T},ys::Quantity{T}...) where {T <: Number} = $op(x,ys...)
    end
end

# exponentiation is not and cannot be type-stable for `Quantity`s,
# so we will not fastmathify it
pow_fast(x::Quantity, y::Integer) = x^y
pow_fast(x::Quantity, y::Rational) = x^y

sqrt_fast(x::Quantity{T}) where {T <: FloatTypes} =
    Quantity(sqrt_fast(x.val), sqrt(unit(x)))

for f in (:cos, :sin, :tan, :sincos, :cis)
    f_fast = fast_op[f]
    @eval $f_fast(x::DimensionlessQuantity) = $f_fast(ustrip(NoUnits, x))
end

atan_fast(x::Quantity{T,D,U}, y::Quantity{T,D,U}) where {T,D,U} =
    atan_fast(x.val, y.val)

@fastmath begin
    hypot_fast(x::Quantity{T,D,U}, y::Quantity{T,D,U}) where {T <: FloatTypes,D,U} =
        sqrt(x*x + y*y)

    # Note: we use the same comparison for min, max, and minmax, so
    # that the compiler can convert between them
    max_fast(x::Quantity{T,D,U}, y::Quantity{T,D,U}) where {T <: FloatTypes,D,U} =
        ifelse(y > x, y, x)
    min_fast(x::Quantity{T,D,U}, y::Quantity{T,D,U}) where {T <: FloatTypes,D,U} =
        ifelse(y > x, x, y)
    minmax_fast(x::Quantity{T,D,U}, y::Quantity{T,D,U}) where {T <: FloatTypes,D,U} =
        ifelse(y > x, (x,y), (y,x))

    # complex numbers

    angle_fast(x::Quantity{T}) where {T <: ComplexTypes} = atan(imag(x), real(x))
end
