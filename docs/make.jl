using Documenter
using SFTPClient

makedocs(
    modules=[SFTPClient],
    authors="Peter Bräuer <pb866.git@gmail.com> and contributors",
    sitename="Julia SFTPClient Documentation",
    format=Documenter.HTML(;
        canonical="https://LIM-AeroCloud.github.io/SFTP.jl",
        edit_link="dev",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ]
)

deploydocs(
    repo = "github.com/LIM-AeroCloud/SFTPClient.jl.git",
    devbranch="dev"
)
