using ApplicationBuilder
using Pkg

examples_blink = joinpath(@__DIR__, "..", "..", "examples", "sdl.jl")

# Allow this file to be called either as a standalone file to build the above
# example, or from runtests.jl using a globally-defined builddir.
@isdefined(builddir) || (builddir="builddir")

using SimpleDirectMediaLayer
SDL2 = SimpleDirectMediaLayer

sdlPkg = Pkg.dir("SimpleDirectMediaLayer")
homebrew = Pkg.dir("Homebrew")

# Copy and modify all of the required libraries for SDL2 to run. Only need
# to do this manual step once.
# Note: this step is required because the SDL libs are linked to reference
# eachother, so some manual modification must be done. Perhaps this could be
# automated by ApplicationBuilder as well in the future.
libs = joinpath(builddir, "sdl_libs")
mkpath(libs)
function cp_lib(l)
    name = basename(l)
    cp(l, joinpath(libs, name), follow_symlinks=true, force=true)
    l = joinpath(libs, name)
    run(`install_name_tool -id "$name" $l`)
    try
        external_deps = readlines(pipeline(`otool -L $l`,
                    `grep .julia`,  # filter julia lib deps
                    `sed 's/(.*)$//'`)) # remove trailing parens
        for line in external_deps
            path = strip(line)
            depname = basename(path)
            depname = "$(match(r"(\w+)", depname)[1]).dylib" # strip version
            cmd = `install_name_tool -change "$path" "@rpath/$depname" $l`
            println(cmd)
            run(cmd)
        end
    catch
    end
end
cp_lib(SDL2.libSDL2)
cp_lib(SDL2.libSDL2_ttf)
cp_lib(SDL2.libSDL2_mixer)
cp_lib(joinpath(homebrew, "deps/usr/lib/libmodplug.dylib"))
cp_lib(joinpath(homebrew, "deps/usr/lib/libvorbisfile.dylib"))
cp_lib(joinpath(homebrew, "deps/usr/lib/libvorbis.dylib"))
cp_lib(joinpath(homebrew, "deps/usr/lib/libfreetype.dylib"))
cp_lib(joinpath(homebrew, "deps/usr/lib/libogg.dylib"))
cp_lib(joinpath(homebrew, "deps/usr/lib/libpng16.dylib"))


build_app_bundle(examples_blink;
    verbose = true,
    resources = [joinpath(sdlPkg,
                         "assets","fonts","FiraCode","ttf","FiraCode-Regular.ttf"),
                ],
    libraries = ["$libs/*"],
    appname="HelloSDL2", builddir=builddir)
