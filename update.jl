#!/usr/bin/env julia

### Constants. ###

const METADATA   = Pkg.dir("METADATA")
const ORG_NAME   = "JuliaPackageMirrors"
const PACKAGES   = readdir(METADATA)
const TOTAL      = length(PACKAGES)
const NO_UPDATES = "Already up-to-date.\n"

### Functions. ###

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
            isdir(name) || run(`git clone $(url) $(name)`)
            cd(name) do
                # Skip pushing to mirror if there aren't any updates.
                update_local(url) == NO_UPDATES || update_mirror(name)
            end
        end
    end
end

function update_local(url)
    try
        readall(`git pull`)
    catch
        warn("could not pull from '$(url)'.")
        # Assume no updates when pulling from origin fails.
        NO_UPDATES
    end
end

function update_mirror(name)
    try
        # `--mirror` will push all branches, remotes, and tags to mirror.
        run(`git push $(ORG_NAME) --mirror`)
    catch
        run(`hub create $(ORG_NAME)/$(name).jl`)
        run(`git remote add $(ORG_NAME) git@github.com:$(ORG_NAME)/$(name).jl.git`)
        run(`git push $(ORG_NAME) --mirror`)
    end
end

### Main. ###

# Update METADATA repo first to find newly added packages.
Pkg.update()

info("updating Julia package mirrors...")
cd(joinpath(dirname(@__FILE__), "..")) do
    width = length(digits(length(PACKAGES)))
    for (number, name) in enumerate(PACKAGES)
        print_header(name, number, width)
        update(name)
        println()
    end
end
