using Documenter, Unitful, Dates

DocMeta.setdocmeta!(Unitful, :DocTestSetup, :(using Unitful))

makedocs(
    sitename = "Unitful.jl",
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    warnonly = [:missing_docs],
    modules = [Unitful],
    workdir = joinpath(@__DIR__, ".."),
    pages = [
        "Home" => "index.md"
        "Highlighted features" => "highlights.md"
        "Types" => "types.md"
        "Defining new units" => "newunits.md"
        "Conversion/promotion" => "conversion.md"
        "Manipulating units" => "manipulations.md"
        "How units are displayed" => "display.md"
        "Logarithmic scales" => "logarithm.md"
        "Temperature scales" => "temperature.md"
        "Interoperability with `Dates`" => "dates.md"
        "Extending Unitful" => "extending.md"
        "Troubleshooting" => "trouble.md"
        "Pre-defined dimensions, units, and constants" => "defaultunits.md"
        "License" => "LICENSE.md"
    ]
)

deploydocs(repo = "github.com/JuliaPhysics/Unitful.jl.git")
