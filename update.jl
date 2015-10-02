#!/usr/bin/env julia

cd(joinpath(dirname(@__FILE__), ".."))

Pkg.update()

const METADATA = Pkg.dir("METADATA")
const ORG_NAME = "JuliaPackageMirrors"

for f in readdir(METADATA)
    f = joinpath(METADATA, f)
    if isdir(f)
        urlfile = joinpath(f, "url")
        name = splitdir(f)[end]
        if isfile(urlfile)
            url = strip(readall(urlfile))
            isdir(name) || run(`git clone $url $name`)
            cd(name) do
                try
                    run(`git pull origin`)
                catch
                    warn("Could not pull from origin.")
                end
                try
                    run(`git push $ORG_NAME`)
                catch err
                    run(`hub create $ORG_NAME/$name.jl`)
                    run(`git remote add $ORG_NAME git@github.com:$ORG_NAME/$name.jl.git`)
                    run(`git push $ORG_NAME`)
                end
            end
        end
    end
end

