# How units are displayed

By default, exponents on units or dimensions are indicated using Unicode superscripts on
macOS and without superscripts on other operating systems. You can set the environment
variable `UNITFUL_FANCY_EXPONENTS` to either `true` or `false` to force using or not using
the exponents. You can also set the `:fancy_exponent` IO context property to either `true`
or `false` to force using or not using the exponents.

```@docs
Unitful.BracketStyle
Unitful.abbr
Unitful.prefix
Unitful.show(::IO, ::Unitful.AbstractQuantity)
Unitful.show(::IO, ::Unitful.Unitlike)
Unitful.showrep
Unitful.showval
Unitful.superscript
```
