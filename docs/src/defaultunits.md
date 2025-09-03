# Pre-defined units and сonstants

In the following, only non-prefixed units are listed. To get a more detailed information about a unit, and to get information about prefixed units, use `Julia` help, e.g.

```
help?> Unitful.kW
  Unitful.kW

  A prefixed unit, equal to 10^3 W.

  Dimension: 𝐋² 𝐌 𝐓⁻³

  See also: Unitful.W.
```

For prefixes, see [below](#Metric-(SI)-Prefixes).


## Base dimensions

### Amount

```@docs
Unitful.𝐍
Unitful.Amount
Unitful.mol
```

### Current

```@docs
Unitful.𝐈
Unitful.Current
Unitful.A
```

### Length

```@docs
Unitful.𝐋
Unitful.Length
Unitful.angstrom
Unitful.cm
Unitful.fm
Unitful.ft
Unitful.inch
Unitful.m
Unitful.mi
Unitful.mil
Unitful.nm
Unitful.yd
```

### Luminosity

```@docs
Unitful.𝐉
Unitful.Luminosity
Unitful.cd
Unitful.lm
```

### Mass

```@docs
Unitful.𝐌
Unitful.Mass
Unitful.dr
Unitful.g
Unitful.gr
Unitful.kg
Unitful.lb
Unitful.oz
Unitful.slug
Unitful.u
```

### Temperature

```@docs
Unitful.𝚯
Unitful.Temperature
Unitful.K
Unitful.Ra
Unitful.°C
Unitful.°F
```

### Time

```@docs
Unitful.𝐓
Unitful.Time
Unitful.d
Unitful.hr
Unitful.minute
Unitful.s
Unitful.wk
Unitful.yr
```

## Derived dimensions

### Acceleration

```@docs
Unitful.Acceleration
Unitful.Gal
Unitful.ge
```

### Area

```@docs
Unitful.Area
Unitful.a
Unitful.ac
Unitful.b
Unitful.ha
```

### BField

```@docs
Unitful.BField
Unitful.Gauss
Unitful.T
```

### Capacitance

```@docs
Unitful.Capacitance
Unitful.F
```

### Charge

```@docs
Unitful.Charge
Unitful.C
```

### DynamicViscosity

```@docs
Unitful.DynamicViscosity
Unitful.P
```

### ElectricalConductance

```@docs
Unitful.ElectricalConductance
Unitful.S
```

### ElectricalResistance

```@docs
Unitful.ElectricalResistance
Unitful.Ω
```

### Energy

```@docs
Unitful.Energy
Unitful.btu
Unitful.cal
Unitful.erg
Unitful.eV
Unitful.J
```

### Force

```@docs
Unitful.Force
Unitful.dyn
Unitful.lbf
Unitful.N
```

### Frequency

```@docs
Unitful.Frequency
Unitful.Bq
Unitful.Hz
Unitful.Hz2π
Unitful.rpm
Unitful.rps
```

### HField

```@docs
Unitful.HField
Unitful.Oe
```

### Inductance

```@docs
Unitful.Inductance
Unitful.H
```

### KinematicViscosity

```@docs
Unitful.KinematicViscosity
Unitful.St
```

### MagneticFlux

```@docs
Unitful.MagneticFlux
Unitful.Mx
Unitful.Wb
```

### MolarFlow

```@docs
Unitful.MolarFlow
Unitful.kat
```

### Molarity

```@docs
Unitful.Molarity
Unitful.M
```

### Power

```@docs
Unitful.Power
Unitful.W
```

### Pressure

```@docs
Unitful.Pressure
Unitful.atm
Unitful.Ba
Unitful.bar
Unitful.kPa
Unitful.Pa
Unitful.psi
Unitful.Torr
```

### Velocity

```@docs
Unitful.Velocity
Unitful.c
```

### Voltage

```@docs
Unitful.Voltage
Unitful.V
```

### Volume

```@docs
Unitful.Volume
Unitful.L
```

## Dimensionless units

```@docs
Unitful.°
Unitful.pcm
Unitful.percent
Unitful.permille
Unitful.pertenthousand
Unitful.ppb
Unitful.ppm
Unitful.ppq
Unitful.ppt
Unitful.rad
Unitful.sr
```

## Logarithmic units

| Unit           | Name                            |
|----------------|---------------------------------|
| `dB`       |        Decibel |
| `B`        |         Bel |
| `Np`       |        Neper |
| `cNp`      |       Centineper |

### Log units related to reference levels
| Unit           | Reference level                            |
|----------------|---------------------------------|
| `dBHz`       |         1Hz |
| `dBm`          |         1mW |
| `dBV`          |         1V |
| `dBu`          |         sqrt(0.6)V |
| `dBμV`        |         1μV |
| `dBSPL`      |         20μPa |
| `dBFS`        |         RootPowerRatio(1) |
| `dBΩ`          |         1Ω |
| `dBS`          |         1S |

## Physical constants

```@docs
Unitful.c0
Unitful.G
Unitful.gn
Unitful.h
Unitful.k
Unitful.me
Unitful.mn
Unitful.mp
Unitful.Na
Unitful.q
Unitful.R
Unitful.R∞
Unitful.Z0
Unitful.ħ
Unitful.ε0
Unitful.μ0
Unitful.μB
Unitful.σ
Unitful.Φ0
```

## Metric (SI) Prefixes

| Prefix | Name | Power of Ten |
|--------|--------|--------|
| y | yocto | -24 |
| z | zepto | -21 |
| a | atto | -18 |
| f | femto | -15 |
| p | pico | -12 |
| n | nano | -9 |
| μ | micro | -6 |
| m | milli | -3 |
| c | centi | -2 |
| d | deci | -1 |
| da | deca | 1 |
| h | hecto | 2 |
| k | kilo | 3 |
| M | mega | 6 |
| G | giga | 9 |
| T | tera | 12 |
| P | peta | 15 |
| E | exa | 18 |
| Z | zetta | 21 |
| Y | yotta | 24 |
