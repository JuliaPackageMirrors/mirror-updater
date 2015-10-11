#!/usr/bin/env julia

module MirrorUpdater

### Blacklisted Packages. ###

const BLACKLIST = [

]

### Constants. ###

const METADATA   = Pkg.dir("METADATA")
const ORG_NAME   = "JuliaPackageMirrors"
const PACKAGES   = readdir(METADATA)
const TOTAL      = length(PACKAGES)

### Functions. ###

function rename_url(url)
    url = replace(url, "git://", "https://")
    url = replace(url, ".git", "")
end

function print_header(name, number, width)
    println("[$(lpad(number, width)) / $(lpad(TOTAL, width))] $name")
    println("="^Base.tty_size()[2])
end

function update(name)
    dir = joinpath(METADATA, name)
    if isdir(dir)
        file = joinpath(dir, "url")
        if isfile(file)
            url = strip(readall(file))
            isdir(name) || run(`git clone --mirror $(url) $(name)`)
            cd(name) do
                update_local(url)
                update_mirror(name, rename_url(url))
            end
        end
    end
end

function update_local(url)
    try
        info("fetching from origin: '$url'")
        run(`git fetch -p origin`)
    catch
        warn("could not fetch from '$(url)'")
    end
end

function update_mirror(name, url)
    # Check if mirror exists already.
    if !success(`git ls-remote git@github.com:$(ORG_NAME)/$(name).jl.git`)
        info("creating new repo: '$name'")
        run(`hub create $(ORG_NAME)/$(name).jl -d 'Julia package mirror.' -h $url`)
    end
    success(`git remote add $(ORG_NAME) git@github.com:$(ORG_NAME)/$(name).jl.git`)
    # Update the mirrored repo.
    info("updating mirror: '$name'")
    success(`git push $(ORG_NAME) --mirror`)
end

### Main. ###

function main()
    # Update METADATA repo first to find newly added packages.
    Pkg.update()

    info("updating Julia package mirrors...")
    cd(joinpath(dirname(@__FILE__), "..")) do
        width = length(digits(length(PACKAGES)))
        for (number, name) in enumerate(PACKAGES)
            name in BLACKLIST && (warn("skipping $name"); continue)
            print_header(name, number, width)
            update(name)
            println()
        end
    end
end

end
