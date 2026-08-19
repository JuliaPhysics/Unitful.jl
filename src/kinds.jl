"""
    abstract type AbstractUnitKind end
Supertype of the *kinds* a unit may be tagged with.

A kind is a classification running parallel to dimension. Two units of the same
dimension are only interconvertible if they also agree on kind, which makes it possible
to distinguish dimensionless units that measure unrelated things, like `rad` and
`percent`.

Unlike dimensions, kinds are sparse: a unit carries no kind unless one has been assigned
with a [`Unitful.unitkinds`](@ref) method, and units without a kind are unrestricted. As
a result the default behaviour of Unitful is unaffected until kinds are assigned, e.g.
by calling [`Unitful.restrict_unit_kinds`](@ref).

Carrying no kind is itself meaningful: a proportion unit like `percent` genuinely is a
pure number, so leaving it unclassified is what keeps `uconvert(NoUnits, 50u"percent")`
working while still separating it from a unit that does carry a kind.

See also: [`Unitful.AngleKind`](@ref).
"""
abstract type AbstractUnitKind end

"""
    struct AngleKind <: AbstractUnitKind end
The kind of angular units such as `rad`, `°` and `sr`.

Solid angle is represented as this kind raised to the second power rather than as a kind
of its own, so that `sr` and `°^2` agree while `sr` and `rad` do not.
"""
struct AngleKind <: AbstractUnitKind end

"""
    struct KindError <: Exception
Units are of incompatible kinds for the attempted conversion.

This is distinct from a `Unitful.DimensionError`: the dimensions of the two
units agree, but their kinds do not.
"""
struct KindError <: Exception
    x
    y
end

Base.showerror(io::IO, e::KindError) =
    print(io, "KindError: $(e.x) and $(e.y) are not compatible in kind.")

"""
    unitkinds(x::Unit)
Return the kinds of a single [`Unitful.Unit`](@ref), as a tuple of
`AbstractUnitKind => Rational` pairs.

The default is an empty tuple, meaning the unit carries no kind and is therefore not
restricted in what it can be converted to. Assigning a kind is done by adding a method,
which is how [`Unitful.restrict_unit_kinds`](@ref) works and how a downstream package
may classify its own units:

```julia
Unitful.unitkinds(::Unitful.Unit{:Radian}) = (Unitful.AngleKind() => 1//1,)
```

The exponent is taken relative to the unit itself, so a unit that is inherently a square
of some kind — `sr`, which is an angle squared — is given an exponent of `2//1`.
"""
unitkinds(::Unit) = ()

# The tuple of `Unit` objects behind a `Units` object. Reading it through dispatch
# rather than from `typeof(u).parameters` keeps it a compile-time constant, which is
# what lets the kind check below fold away entirely.
@inline _unittuple(::Units{N}) where {N} = N

# The kinds of one `Unit`, with each exponent scaled by that unit's own power, so that
# `°^2` contributes `AngleKind() => 2//1` and matches `sr`.
@inline _scaledkinds(u::Unit) = map(p -> first(p) => last(p) * power(u), unitkinds(u))

# All (kind => exponent) contributions across a tuple of `Unit` objects, without
# collecting duplicates: `_kindexponent` sums them on demand instead. Written
# recursively over the tuple so it unrolls at compile time and never allocates.
_kindpairs(::Tuple{}) = ()
_kindpairs(us::Tuple) = (_scaledkinds(first(us))..., _kindpairs(Base.tail(us))...)

# Total exponent of kind `k` across a tuple of (kind => exponent) pairs.
_kindexponent(::Tuple{}, ::AbstractUnitKind) = 0//1
_kindexponent(ps::Tuple, k::AbstractUnitKind) =
    (first(first(ps)) === k ? last(first(ps)) : 0//1) + _kindexponent(Base.tail(ps), k)

# True when every kind mentioned in `ps` has the same total exponent in `qs`. Checking
# in both directions gives equality of the two kind signatures without having to sort
# them into a canonical order.
_kindsagree(::Tuple{}, ::Tuple) = true
_kindsagree(ps::Tuple, qs::Tuple) =
    _kindexponent(ps, first(first(ps))) == _kindexponent(qs, first(first(ps))) &&
    _kindsagree(Base.tail(ps), qs)

"""
    kindrank(x::Unit)
Return the promotion preference of a single [`Unitful.Unit`](@ref) within its kind,
lowest first.

When two units of the same kind are promoted, the better-ranked one wins, so ranking
`rad` above `°` is what makes `1u"rad" + 1u"°"` come out in radians. The default is
`typemax(Int)`, which leaves unranked units to be chosen between by SI prefix and name.
"""
kindrank(::Unit) = typemax(Int)

# Best (lowest) rank among the units making up a `Units` object.
_kindrank(u::Units) = minimum((kindrank(v) for v in _unittuple(u)), init = typemax(Int))

# Total, symmetric ordering used to choose between two kind-carrying units during
# promotion. Rank decides first; ties are settled by preferring the unprefixed unit and
# then by name, so that the choice never depends on the order of the operands.
_kindkey(u::Units) =
    (_kindrank(u), map(v -> (abs(tens(v)), tens(v), name(v)), _unittuple(u)))

# True if this unit carries any kind at all.
_haskind(u::Units) = !isempty(_kindpairs(_unittuple(u)))

# Choose the units that two same-dimension units should promote to. Units carrying no
# kind fall back to the dimension's preferred unit, exactly as before. Units that do
# carry one must not, since the preferred unit for `NoDims` is `NoUnits` and promoting
# an angle to a bare number is precisely what kinds forbid — that would make even
# `1u"rad" + 1u"°"` impossible. Keep the better-ranked operand instead.
_kindpromote(x::Units, y::Units) =
    _haskind(x) ? (_kindkey(x) <= _kindkey(y) ? x : y) : upreferred(dimension(x))

"""
    kindscompatible(a::Units, b::Units)
Return `true` if units `a` and `b` agree on kind and may therefore be converted between.

Units carrying no kind are compatible with each other, so this returns `true` for every
pair of units until kinds have been assigned.
"""
function kindscompatible(a::Units, b::Units)
    pa, pb = _kindpairs(_unittuple(a)), _kindpairs(_unittuple(b))
    return _kindsagree(pa, pb) && _kindsagree(pb, pa)
end

# Guard used by `uconvert`. When no kinds are assigned this folds away to nothing at
# compile time, leaving conversion exactly as fast as it was.
@inline function assert_kind_convertible(a::Units, b::Units)
    kindscompatible(a, b) || throw(KindError(a, b))
    return nothing
end

"""
    Unitful.restrict_unit_kinds()
Give Unitful's angular units a kind, so that they stop being interconvertible with the
other dimensionless units they happen to share the `NoDims` dimension with.

After calling this function:

- `rad` and `°` remain interconvertible with each other, as do `sr` and `°^2`;
- `rad` and `sr` do not, since solid angle is angle squared;
- an angle no longer converts to or from a proportion (`percent`, `ppm`, …) or a bare
  number, so `uconvert(u"percent", 1u"°")`, `uconvert(NoUnits, 1u"°")` and
  `convert(Float64, 1u"rad")` all throw a [`Unitful.KindError`](@ref).

Only the angular units are classified. Proportion units are left alone deliberately:
`percent` really is a pure number, so `uconvert(NoUnits, 50u"percent")` and
`uconvert(u"ppm", 1u"percent")` keep working exactly as before. It is the angular units
that are the odd ones out, and classifying them is enough to separate the two groups.

Functions that need the numeric value of a dimensionless quantity for their own sake,
such as `sin` and `round`, are unaffected and continue to accept angles.

The effect is global and cannot be undone, in the same way as
[`Unitful.promote_to_derived`](@ref). Consider calling it in your `startup.jl`, or at
load time in a package that wants the stricter behaviour. This function is not exported.

Because it works by defining methods, the usual world-age rule applies: code that was
already compiled when it is called only picks the restriction up once it is recompiled,
which does not happen for a function that is currently running. So call it as its own
top-level statement, not from inside the same function or `begin` block as the
conversions it is meant to restrict.
"""
function restrict_unit_kinds()
    eval(quote
         Unitful.unitkinds(::Unitful.Unit{:Radian}) = (Unitful.AngleKind() => 1//1,)
         Unitful.unitkinds(::Unitful.Unit{:Degree}) = (Unitful.AngleKind() => 1//1,)
         Unitful.unitkinds(::Unitful.Unit{:Steradian}) = (Unitful.AngleKind() => 2//1,)

         # Promotion preference within the angle kind: radians for angles and
         # steradians for solid angles, both being the SI choice.
         Unitful.kindrank(::Unitful.Unit{:Radian}) = 1
         Unitful.kindrank(::Unitful.Unit{:Steradian}) = 2
         Unitful.kindrank(::Unitful.Unit{:Degree}) = 3
        end)
    nothing
end
