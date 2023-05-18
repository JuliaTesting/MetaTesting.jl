using MetaTesting
using Documenter

makedocs(;
    modules=[MetaTesting],
    repo="https://github.com/sethaxen/MetaTesting.jl/blob/{commit}{path}#{line}",
    sitename="MetaTesting.jl",
    format=Documenter.HTML(; prettyurls=get(ENV, "CI", "false") == "true", assets=String[]),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(; repo="github.com/sethaxen/MetaTesting.jl.git", devbranch="main")
