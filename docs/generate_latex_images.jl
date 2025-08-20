using LaTeXStrings, Unitful, Latexify, tectonic_jll

commands = [
    :(latexify(612.2u"nm")),
    :(latexify(u"kg*m/s^2")),
    :(latexify(612.2u"nm"; fmt=SiunitxNumberFormatter())),
    :(latexify(u"kg*m/s^2"; fmt=SiunitxNumberFormatter())),
    :(latexify(612.2u"nm"; fmt=SiunitxNumberFormatter(; simple=true))),
    :(latexify(u"kg*m/s^2"; fmt=SiunitxNumberFormatter(; simple=true))),
    :(latexify((1, 2, 4) .* u"m"; fmt=SiunitxNumberFormatter())),
]
tab1 = map(commands) do command
    LaTeXString.([
        "\\verb+$(string(command))+",
        "\\verb+$(eval(command))+",
        "$(eval(command)) ",
    ])
end
ltab1 = latextabular(tab1, adjustment=:l, transpose=true, latex=false, booktabs=true, 
    head=["julia", "\\LaTeX", "Result"])
# Setting an explicit white background color results in transparent PDF, so go offwhite.
ltab1 = LaTeXString("\\definecolor{offwhite}{rgb}{0.999,0.999,0.999}\n\\pagecolor{offwhite}\n\\color{black}\n" * ltab1)

render(ltab1, MIME("image/png"); use_tectonic=true,
    name=(@__DIR__)*"/src/assets/latex-examples", 
    packages=["booktabs", "color", "siunitx"], 
    documentclass=("standalone"))

functions = [
    x -> "\\verb+$(string(x))+",
    x -> latexify(x),
    x -> latexify(x; fmt=SiunitxNumberFormatter()),
    x -> latexify(x; fmt=SiunitxNumberFormatter(; simple=true)),
]
allunits = begin
    uparse.([
        "nH*m/Hz",
        "m",
        "s",
        "A",
        "K",
        "cd",
        "g",
        "mol",
        "sr",
        "rad",
        "°",
        "Hz",
        "N",
        "Pa",
        "J",
        "W",
        "C",
        "V",
        "S",
        "F",
        "H",
        "T",
        "Wb",
        "lm",
        "lx",
        "Bq",
        "Gy",
        "Sv",
        "kat",
        #"percent", # Messes with comments
        # "permille", # Undefined in all formats
        # "pertenthousand", # Undefined in all formats (butchered)
        "°C",
        "°F", # No longer in siunitx
        "minute",
        "hr",
        "d",
        "wk", # Undefined in siunitx
        "yr", # Undefined in siunitx
        "rps", # Undefined in siunitx
        "rpm", # Undefined in siunitx
        "a", # Undefined in siunitx
        "b",
        "L",
        "M", # Undefined in siunitx
        "eV",
        "Hz2π", # Butchered by encoding
        "bar",
        "atm", # Undefined in siunitx
        "Torr", # Undefined in siunitx
        "c", # Undefined in siunitx
        "u", # Undefined in siunitx
        "ge", # Undefined in siunitx
        "Gal", # Undefined in siunitx
        "dyn", # Undefined in siunitx
        "erg", # Undefined in siunitx
        "Ba", # Undefined in siunitx
        "P", # Undefined in siunitx
        "St", # Undefined in siunitx
        #"Gauss", # errors in testing, maybe from Unitful.jl's dev branch?
        #"Oe", # errors in testing, maybe from Unitful.jl's dev branch?
        #"Mx", # errors in testing, maybe from Unitful.jl's dev branch?
        "inch", # Undefined in siunitx
        "mil", # Undefined in siunitx
        "ft", # Undefined in siunitx
        "yd", # Undefined in siunitx
        "mi", # Undefined in siunitx
        "angstrom", # Undefined in mathrm,siunitxsimple
        "ac", # Undefined in siunitx
        "Ra", # Undefined in siunitx
        "lb", # Undefined in siunitx
        "oz", # Undefined in siunitx
        "slug", # Undefined in siunitx
        "dr", # Undefined in siunitx
        "gr", # Undefined in siunitx
        "lbf", # Undefined in siunitx
        "cal", # Undefined in siunitx
        "btu", # Undefined in siunitx
        "psi", # Undefined in siunitx
        #"dBHz", # Cannot *yet* be latexified.
        #"dBm", # Cannot *yet* be latexified.
        #"dBV", # Cannot *yet* be latexified.
        #"dBu", # Cannot *yet* be latexified.
        #"dBμV", # Cannot *yet* be latexified.
        #"dBSPL", # Cannot *yet* be latexified.
        #"dBFS", # Cannot *yet* be latexified.
        #"dBΩ", # Cannot *yet* be latexified.
        #"dBS", # Cannot *yet* be latexified.
    ])
end

tab2 = map(allunits) do unit
    [LaTeXString(f(unit)) for f in functions]
end
ltab2 = latextabular(tab2, adjustment=:l, transpose=true, latex=false, booktabs=true, 
    head=["Name", "Default number formatter", "\\verb+SiunitxNumberFormatter()+", "\\verb+SiunitxNumberFormatter(;simple=true)+"])
# Set background to not-quite-white so it doesn't get treated as transparent
ltab2 = LaTeXString(
    """
    \\setmainfont{FreeSerif}
    \\setmonofont{FreeMono}
    \\definecolor{offwhite}{rgb}{0.999,0.999,0.999}
    \\pagecolor{offwhite}
    \\color{black}
    """ * ltab2)

render(ltab2, MIME("image/png"); use_tectonic=true, 
    tectonic_flags=`-Z continue-on-errors`,
    name=(@__DIR__)*"/src/assets/latex-allunits", 
    packages=["booktabs", "color", "siunitx", "fontspec"], 
    documentclass=("standalone"))
